#!/usr/bin/env bash
# Auditoría de Costo-Beneficio de Modelos (v2)
# Fix respecto a v1:
#   - Usa max_input_tokens (ventana real) en vez de max_tokens (que es max_output_tokens)
#   - Agrega eje de razonamiento (supports_reasoning) con peso propio
#   - Fallback honesto: si el modelo actual no existe en la base, lo dice, no inventa ceros
#   - Sin regex frágil sobre IDs de modelo (todo el matching se hace en jq, no en grep/awk)
#   - Todo configurable por variables de entorno, no hardcodeado

set -euo pipefail

# ---- Configuración (override por variable de entorno) ----
MODELO_ACTUAL="${MODELO_ACTUAL:-deepseek/deepseek-v4-flash}"
REQUIRE_REASONING="${REQUIRE_REASONING:-false}"   # true = solo considerar modelos con razonamiento
MIN_CTX="${MIN_CTX:-32768}"                       # ventana mínima aceptable (tokens de entrada)
CTX_CAP="${CTX_CAP:-200000}"                      # tope práctico para no dejar que un modelo de 2M contexto rompa la escala
W_COSTO="${W_COSTO:-0.45}"
W_CTX="${W_CTX:-0.25}"
W_RAZON="${W_RAZON:-0.30}"

API_URL="https://raw.githubusercontent.com/BerriAI/litellm/main/model_prices_and_context_window.json"
CACHE_DIR="/tmp/audit_costos"
TMP_JSON="$CACHE_DIR/litellm_prices.json"
RESULT_JSON="$CACHE_DIR/resultado.json"
mkdir -p "$CACHE_DIR"

# ---- Descarga con cache de 12h (evita golpear GitHub en cada corrida del job en el Pi) ----
if [ ! -f "$TMP_JSON" ] || [ -z "$(find "$TMP_JSON" -mmin -720 2>/dev/null)" ]; then
  curl -sf "$API_URL" -o "$TMP_JSON.tmp"
  mv "$TMP_JSON.tmp" "$TMP_JSON"
fi

if [ ! -s "$TMP_JSON" ] || ! jq -e . "$TMP_JSON" >/dev/null 2>&1; then
  echo "❌ Error: no se pudo obtener o parsear la base de precios de LiteLLM."
  exit 1
fi

# ---- Todo el cálculo en un solo jq: filtrado, normalización, scoring, ranking, y resolución del modelo actual ----
jq \
  --arg model "$MODELO_ACTUAL" \
  --argjson require_reasoning "$REQUIRE_REASONING" \
  --argjson min_ctx "$MIN_CTX" \
  --argjson ctx_cap "$CTX_CAP" \
  --argjson w_costo "$W_COSTO" \
  --argjson w_ctx "$W_CTX" \
  --argjson w_razon "$W_RAZON" \
'
  def score_entry($ctx_cap; $w_costo; $w_ctx; $w_razon; $min_cost):
    . + {
      total: (.in + .out),
      ctx_util: ([.ctx, $ctx_cap] | min),
      score_razon: (if .reasoning then 100 else 0 end)
    } | . + {
      score_costo: (($min_cost / .total) * 100),
      score_ctx: ((.ctx_util / $ctx_cap) * 100)
    } | . + {
      ieo: ((.score_costo * $w_costo) + (.score_ctx * $w_ctx) + (.score_razon * $w_razon))
    };

  # Extrae de una entrada cruda el registro normalizado (o null si le faltan precios)
  def to_entry($k; $v):
    ($v.max_input_tokens // $v.max_tokens // 0) as $ctx
    | if ($v.input_cost_per_token == null or ($v.input_cost_per_token|tonumber) <= 0
          or $v.output_cost_per_token == null or ($v.output_cost_per_token|tonumber) <= 0)
      then null
      else {
        id: $k,
        in: ($v.input_cost_per_token|tonumber * 1000000),
        out: ($v.output_cost_per_token|tonumber * 1000000),
        ctx: $ctx,
        reasoning: ($v.supports_reasoning == true),
        function_calling: ($v.supports_function_calling == true),
        mode: ($v.mode // "desconocido")
      }
      end;

  . as $data
  | [ $data | to_entries[] | to_entry(.key; .value) | select(. != null) ] as $all_entries

  # Universo de candidatos para el ranking (con filtros duros)
  | [ $all_entries[]
      | select(.mode == "chat")
      | select(.function_calling == true)
      | select(.ctx >= $min_ctx)
      | select(($require_reasoning|not) or .reasoning)
    ] as $pool

  | ($pool | map(.in + .out) | min) as $min_cost
  | ($pool | map(score_entry($ctx_cap; $w_costo; $w_ctx; $w_razon; $min_cost)) | sort_by(-.ieo)) as $ranking

  # Resolución honesta del modelo actual: probamos el id tal cual y con prefijo openrouter/
  | ([$model, ("openrouter/" + $model)] | map(. as $cand | $all_entries[] | select(.id == $cand)) | .[0]) as $actual_raw

  | {
      ranking: $ranking,
      min_cost: $min_cost,
      actual_encontrado: ($actual_raw != null),
      actual: (
        if $actual_raw == null then null
        else ($actual_raw | score_entry($ctx_cap; $w_costo; $w_ctx; $w_razon; $min_cost))
        end
      )
    }
' "$TMP_JSON" > "$RESULT_JSON"

# ---- Formateo de salida para Telegram ----
FECHA_HOY=$(date +%Y-%m-%d)

echo "⚖️ Auditoría de Costo-Beneficio (con eje de razonamiento) — $FECHA_HOY"
echo ""

ACTUAL_ENCONTRADO=$(jq -r '.actual_encontrado' "$RESULT_JSON")

if [ "$ACTUAL_ENCONTRADO" = "true" ]; then
  jq -r '
    .actual as $a |
    "Modelo actual: \($a.id)",
    "- Costo In/M: \($a.in) USD | Costo Out/M: \($a.out) USD",
    "- Ventana de contexto real: \($a.ctx) tokens",
    "- Razonamiento: \(if $a.reasoning then "sí" else "no" end) | Function calling: \(if $a.function_calling then "sí" else "no" end)",
    "- Índice de Eficiencia (IEO): \($a.ieo | (.*100|round)/100) / 100"
  ' "$RESULT_JSON"
else
  echo "⚠️ El modelo '$MODELO_ACTUAL' no existe en la base de LiteLLM (ni directo ni como openrouter/$MODELO_ACTUAL)."
  echo "   No se puede comparar de forma confiable — probable typo, modelo deprecado, o proveedor sin mapear aún."
fi

echo ""
echo "Top 3 alternativas (filtro: chat + function calling + contexto ≥ $MIN_CTX$( [ "$REQUIRE_REASONING" = "true" ] && echo " + razonamiento" )):"
jq -r '
  .ranking[0:3] | to_entries[] |
  "\(.key+1). \(.value.id)  [IEO \((.value.ieo*100|round)/100)]",
  "   In/Out por M: \(.value.in)/\(.value.out) USD | Contexto: \(.value.ctx) | Razonamiento: \(if .value.reasoning then "sí" else "no" end)"
' "$RESULT_JSON"

echo ""
if [ "$ACTUAL_ENCONTRADO" = "true" ]; then
  jq -r \
    --argjson w_costo "$W_COSTO" --argjson w_ctx "$W_CTX" --argjson w_razon "$W_RAZON" '
    .actual.ieo as $ieo_actual |
    .actual.id as $id_actual |
    .ranking[0] as $top |
    if $top != null and $top.ieo > $ieo_actual and $top.id != $id_actual then
      "Dictamen: CAMBIAR A \($top.id) — mejora el IEO de \(($ieo_actual*100|round)/100) a \(($top.ieo*100|round)/100)."
    else
      "Dictamen: MANTENER \($id_actual) — sigue siendo la opción más eficiente bajo los pesos actuales (costo \($w_costo*100)% / contexto \($w_ctx*100)% / razonamiento \($w_razon*100)%)."
    end
  ' "$RESULT_JSON"
else
  echo "Dictamen: no disponible — corregí MODELO_ACTUAL antes de confiar en la recomendación."
fi