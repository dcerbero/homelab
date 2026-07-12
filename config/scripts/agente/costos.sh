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
# El script siempre busca MODELO_ACTUAL en dos fuentes en paralelo:
#   - "directo": la entrada de LiteLLM con esa clave exacta (litellm_provider = el proveedor
#     que la publica, ej. "deepseek" — este es el precio de la API directa del proveedor).
#   - "openrouter": la API en vivo de OpenRouter (openrouter.ai/api/v1/models) con el mismo slug.
# MODELO_ACTUAL debe ser el slug "proveedor/modelo" tal como lo usa OpenRouter (ej.
# "deepseek/deepseek-v4-flash"), que además coincide con la clave directa en LiteLLM.
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

OR_TMP_JSON="$CACHE_DIR/openrouter_models.json"
if [ ! -f "$OR_TMP_JSON" ] || [ -z "$(find "$OR_TMP_JSON" -mmin -720 2>/dev/null)" ]; then
  curl -sf "https://openrouter.ai/api/v1/models" -o "$OR_TMP_JSON.tmp"
  mv "$OR_TMP_JSON.tmp" "$OR_TMP_JSON"
fi
if [ ! -s "$OR_TMP_JSON" ] || ! jq -e . "$OR_TMP_JSON" >/dev/null 2>&1; then
  echo "⚠️ No se pudo obtener la API de OpenRouter — se continúa solo con datos de LiteLLM."
  echo '{"data": []}' > "$OR_TMP_JSON"
fi

# ---- Resolución del modelo actual en AMBAS fuentes, en simultáneo ----

# Precio directo del proveedor, según LiteLLM (clave exacta, sin prefijo openrouter/)
ACTUAL_DIRECTO_JSON=$(jq \
  --arg model "$MODELO_ACTUAL" '
  def to_entry($k; $v):
    ($v.max_input_tokens // $v.max_tokens // 0) as $ctx
    | if ($v.input_cost_per_token == null or ($v.input_cost_per_token|tonumber) <= 0
          or $v.output_cost_per_token == null or ($v.output_cost_per_token|tonumber) <= 0)
      then null
      else {
        id: $k,
        proveedor: ($v.litellm_provider // "desconocido"),
        in: ($v.input_cost_per_token|tonumber * 1000000),
        out: ($v.output_cost_per_token|tonumber * 1000000),
        ctx: $ctx,
        reasoning: ($v.supports_reasoning == true),
        function_calling: ($v.supports_function_calling == true),
        mode: ($v.mode // "desconocido")
      }
      end;
  [to_entries[] | to_entry(.key; .value) | select(. != null)] as $all_entries
  | ([$all_entries[] | select(.id == $model)] | .[0])
' "$TMP_JSON")

# Precio vía OpenRouter, consultado en vivo contra su propia API (mismo slug)
ACTUAL_OPENROUTER_JSON=$(jq \
  --arg model "$MODELO_ACTUAL" '
  [.data[] | select(.id == $model)] | .[0] as $m
  | if $m == null then null
    else {
      id: $m.id,
      proveedor: "openrouter",
      in: ($m.pricing.prompt | tonumber * 1000000),
      out: ($m.pricing.completion | tonumber * 1000000),
      ctx: ($m.context_length // 0),
      reasoning: ((($m.supported_parameters // []) | index("reasoning")) != null),
      function_calling: ((($m.supported_parameters // []) | index("tools")) != null),
      mode: "chat"
    }
    end
' "$OR_TMP_JSON")

# ---- Ranking de alternativas (desde LiteLLM: es el único con cobertura multi-proveedor) ----
jq \
  --argjson actual_directo "$ACTUAL_DIRECTO_JSON" \
  --argjson actual_openrouter "$ACTUAL_OPENROUTER_JSON" \
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

  | {
      ranking: $ranking,
      min_cost: $min_cost,
      actual_directo: (if $actual_directo == null then null else ($actual_directo | score_entry($ctx_cap; $w_costo; $w_ctx; $w_razon; $min_cost)) end),
      actual_openrouter: (if $actual_openrouter == null then null else ($actual_openrouter | score_entry($ctx_cap; $w_costo; $w_ctx; $w_razon; $min_cost)) end)
    }
' "$TMP_JSON" > "$RESULT_JSON"

# ---- Formateo de salida para Telegram ----
FECHA_HOY=$(date +%Y-%m-%d)

echo "⚖️ Auditoría de Costo-Beneficio — Directo vs OpenRouter — $FECHA_HOY"
echo ""
echo "Modelo consultado: $MODELO_ACTUAL"

DIRECTO_ENCONTRADO=$(jq -r '.actual_directo != null' "$RESULT_JSON")
OPENROUTER_ENCONTRADO=$(jq -r '.actual_openrouter != null' "$RESULT_JSON")

if [ "$DIRECTO_ENCONTRADO" = "true" ]; then
  jq -r '
    .actual_directo as $a |
    "",
    "🔹 Directo (\($a.proveedor)):",
    "   Costo In/M: \($a.in) USD | Costo Out/M: \($a.out) USD",
    "   Contexto: \($a.ctx) tokens | Razonamiento: \(if $a.reasoning then "sí" else "no" end) | Function calling: \(if $a.function_calling then "sí" else "no" end)",
    "   IEO: \(($a.ieo*100|round)/100) / 100"
  ' "$RESULT_JSON"
else
  echo ""
  echo "🔹 Directo: no encontrado en LiteLLM con la clave '$MODELO_ACTUAL'."
fi

if [ "$OPENROUTER_ENCONTRADO" = "true" ]; then
  jq -r '
    .actual_openrouter as $a |
    "",
    "🔸 OpenRouter (API en vivo):",
    "   Costo In/M: \($a.in) USD | Costo Out/M: \($a.out) USD",
    "   Contexto: \($a.ctx) tokens | Razonamiento: \(if $a.reasoning then "sí" else "no" end) | Function calling: \(if $a.function_calling then "sí" else "no" end)",
    "   IEO: \(($a.ieo*100|round)/100) / 100"
  ' "$RESULT_JSON"
else
  echo ""
  echo "🔸 OpenRouter: no encontrado en el catálogo en vivo con el slug '$MODELO_ACTUAL'."
fi

echo ""
echo "Top 3 alternativas del mercado (filtro: chat + function calling + contexto ≥ $MIN_CTX$( [ "$REQUIRE_REASONING" = "true" ] && echo " + razonamiento" )):"
jq -r '
  .ranking[0:3] | to_entries[] |
  "\(.key+1). \(.value.id)  [IEO \((.value.ieo*100|round)/100)]",
  "   In/Out por M: \(.value.in)/\(.value.out) USD | Contexto: \(.value.ctx) | Razonamiento: \(if .value.reasoning then "sí" else "no" end)"
' "$RESULT_JSON"

echo ""
if [ "$DIRECTO_ENCONTRADO" = "true" ] || [ "$OPENROUTER_ENCONTRADO" = "true" ]; then
  jq -r '
    . as $doc |
    ([
      (if .actual_directo != null then {canal: "directo", ieo: .actual_directo.ieo} else empty end),
      (if .actual_openrouter != null then {canal: "OpenRouter", ieo: .actual_openrouter.ieo} else empty end)
    ] | sort_by(-.ieo) | .[0]) as $mejor_canal |
    ($doc.ranking[0]) as $top |
    "Entre tus canales disponibles, \($mejor_canal.canal) es el más barato hoy (IEO \(($mejor_canal.ieo*100|round)/100)).",
    (if $top != null and $top.ieo > $mejor_canal.ieo then
      "Dictamen: CAMBIAR DE MODELO A \($top.id) — mejora el IEO de \(($mejor_canal.ieo*100|round)/100) a \(($top.ieo*100|round)/100)."
    else
      "Dictamen: MANTENER el modelo actual, usando el canal \($mejor_canal.canal)."
    end)
  ' "$RESULT_JSON"
else
  echo "Dictamen: no disponible — '$MODELO_ACTUAL' no se encontró en ninguna de las dos fuentes. Revisá el slug."
fi