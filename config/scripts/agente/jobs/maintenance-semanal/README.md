# maintenance-semanal

Mantenimiento semanal de infraestructura: limpieza de /tmp y sincronización del repositorio homelab.

## Configuración

| Campo | Valor |
|---|---|
| Schedule | `0 2 * * 0` (Dom 02:00 COT) |
| Timezone | America/Bogota |
| SessionTarget | isolated (agentTurn) |
| WakeMode | now |
| Timeout | 120s |
| Fallbacks | — |

## Delivery

| Campo | Valor |
|---|---|
| Mode | announce, bestEffort |
| Channel | telegram |
| To | {{TELEGRAM_CHAT_ID}} |

## Payload

```
Sistema: Mantenimiento semanal de infraestructura (Domingos 02:00 COT):

1. Define las rutas de trabajo:
   WORKSPACE="/home/node/.openclaw/workspace"
   REPO_DIR="$WORKSPACE/homelab"

2. Ejecuta el cálculo y limpieza de /tmp de forma estricta:
   - Calcula el espacio ocupado por archivos modificados hace más de 24 horas antes de borrarlos:
     SPACE_BEFORE=$(find /tmp -type f -mtime +1 -exec du -cb {} + | grep total$ | awk '{print $1}')
   - Si SPACE_BEFORE está vacío, define SPACE_BEFORE=0.
   - Ejecuta la eliminación segura basada en tiempo de modificación (-mtime):
     find /tmp -type f -mtime +1 -delete 2>/dev/null
   - ConVIERTE el valor de SPACE_BEFORE a megabytes (MB) para el reporte de forma matemática simple.

3. Sincroniza el repositorio 'homelab' de forma agnóstica:
   - Si el directorio "$REPO_DIR/.git" existe:
     cd "$REPO_DIR" && git remote set-url origin https://github.com/dcerbero/homelab.git && git fetch origin && REPO_STATUS=$(git pull origin main 2>&1)
   - Si "$REPO_DIR/.git" NO existe:
     mkdir -p "$REPO_DIR" && git clone https://github.com/dcerbero/homelab.git "$REPO_DIR" && REPO_STATUS="Clonado por primera vez con éxito"

4. Estructura el reporte de salida estrictamente en texto plano para el canal de Telegram:
   Mantenimiento Semanal Ejecutado:
   - Espacio liberado en /tmp: [Cálculo en MB] MB.
   - Estado del repositorio homelab: [Inserta aquí el resumen de REPO_STATUS].

No agregues prosa introductoria ni conclusiones decorativas.
```