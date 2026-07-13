# price-tokens

Auditoría de costo-beneficio de modelos de IA. Ejecuta `costos.sh` desde el repo homelab y hace verificación cruzada contra OpenRouter API.

## Configuración

| Campo | Valor |
|---|---|
| Schedule | `0 8 * * 0` (Dom 08:00 COT) |
| Timezone | America/Bogota |
| SessionTarget | isolated (agentTurn) |
| WakeMode | now |
| Timeout | 300s |
| Fallbacks | — |

## Delivery

| Campo | Valor |
|---|---|
| Mode | announce |
| Channel | telegram |
| To | {{TELEGRAM_CHAT_ID}} |

## Payload

```
Tarea: auditoría semanal de costo-beneficio del modelo LLM configurado en OpenClaw.
Compara el precio directo del proveedor contra el precio vía OpenRouter para el
modelo actual, y contra el resto del mercado.

Fuente del script (siempre la versión más reciente commiteada):
https://raw.githubusercontent.com/dcerbero/homelab/main/config/scripts/agente/costos.sh

Pasos a ejecutar con exec, en orden:

1. Descargar el script y validar que no vino vacío ni es una página de error:
   curl -sf "https://raw.githubusercontent.com/dcerbero/homelab/main/config/scripts/agente/costos.sh" -o /tmp/costos.sh
   test -s /tmp/costos.sh
   Si curl falla o el archivo queda vacío: reportar el error y detenerte ahí —
   no reconstruyas el script desde memoria ni improvises uno nuevo.

2. Ejecutarlo:
   MODELO_ACTUAL="deepseek/deepseek-v4-flash" bash /tmp/costos.sh

3. El script ya compara el canal directo y el canal OpenRouter internamente y elige
   el mejor de los dos — no hace falta que verifiques eso vos.
   Solo si el "Dictamen" final dice CAMBIAR DE MODELO A un modelo distinto al actual:
   verificá el precio real de ese modelo contra la API pública de OpenRouter antes
   de confiar en la recomendación:
   curl -s "https://openrouter.ai/api/v1/models" | jq '.data[] | select(.id == "<id de la alternativa recomendada>") | .pricing'
   - Si el precio coincide (diferencia menor a 15%) con lo que reportó el script: confirmar.
   - Si difiere más de 15%, o el modelo no aparece en esa API: no recomendar el cambio,
     reportar "recomendación no confirmada — revisar manualmente".

4. Si el "Dictamen" dice MANTENER, no hace falta el paso 3.

5. Reportar el resultado del script tal cual (ya viene formateado para Telegram, incluye
   ambos canales y el top de alternativas), agregando al final una línea con el resultado
   de la verificación cruzada del paso 3 cuando haya aplicado.

6. Borrar el temporal al terminar: rm -f /tmp/costos.sh

Reglas:
- Si exec devuelve error en cualquier paso, reportá el error exacto y no generes
  ningún dictamen inventado.
- No modifiques el script ni cambies MODELO_ACTUAL ni los pesos
  (W_COSTO/W_CTX/W_RAZON) salvo que se te indique explícitamente en este prompt.
```