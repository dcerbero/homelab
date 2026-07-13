# price-tokens

Auditoría de costo-beneficio de modelos de IA. Compara el modelo actual contra el mercado vía LiteLLM y OpenRouter.

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
- Razón técnica: [Si el Ganador es nominalmente más barato pero su tamaño de parámetros o calidad en benchmarks (como BenchLM) es inferior al BASELINE, escribe: "NO vale la pena: Aunque el modelo [Ganador] ofrece un ahorro del [N]%, no cuenta con las capacidades cognitivas ni el tamaño requerido para tareas agénticas complejas en comparación con el baseline". Si el Ganador es equivalente/superior y el ahorro real es mayor al 15%, justifica la migración. Si el BASELINE es el más barato, indica: "NO vale la pena: El modelo actual mantiene el liderazgo matemático"].
```