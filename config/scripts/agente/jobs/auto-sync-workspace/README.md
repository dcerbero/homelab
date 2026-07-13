# auto-sync-workspace

Exportación y respaldo del workspace hacia GitHub. Cada 30 minutos.

## Configuración

| Campo | Valor |
|---|---|
| Schedule | Cada 30 minutos (`everyMs: 1800000`) |
| SessionTarget | isolated (agentTurn) |
| WakeMode | now |
| Timeout | — |
| Fallbacks | — |

## Delivery

| Campo | Valor |
|---|---|
| Mode | none |
| Channel | telegram |
| To | {{TELEGRAM_CHAT_ID}} |

## Payload

```
Sistema: Exportación y respaldo absoluto del Workspace hacia la nube (Local -> GitHub):

1. Configuración de Entorno Estricto:
   WORKSPACE="/home/node/.openclaw/workspace"
   BACKUP_DIR="/tmp/openclaw_export_git"
   REPO_URL="https://github.com/duckdodgers-agente/duckdodgers-workspace.git"

2. Preparación del Aislamiento de Git:
   rm -rf "$BACKUP_DIR" && mkdir -p "$BACKUP_DIR"
   git clone --branch main "$REPO_URL" "$BACKUP_DIR"

3. Clonación del Estado del Workspace (Respaldo Completo):
   rsync -av "$WORKSPACE/" "$BACKUP_DIR/" --exclude='*.log' --exclude='.env' --exclude='*.tmp' --exclude='.DS_Store'

4. Commit y Push Automático a la Rama Main:
   cd "$BACKUP_DIR"
   if [ -n "$(git status --porcelain)" ]; then
     git add .
     git commit -m "chore(workspace): auto-export workspace state, memory logs and assets [$(date +'%Y-%m-%d %H:%M:%S')]"
     git push origin main
     SYNC_CHANGED=true
   else
     SYNC_CHANGED=false
   fi

5. Salida de Estado Estricta para Telegram (Calcula fecha actual en formato YYYY-MM-DD):
   - Si SYNC_CHANGED es false: Salida silenciosa (exit 0).
   - Si SYNC_CHANGED es true, genera exactamente el siguiente bloque de texto plano:

🔄 Workspace Export — [YYYY-MM-DD]
Estado: Sincronización unidireccional completada con éxito.
Destino: Cambios locales, archivos de infraestructura y Core del agente (Memory logs, Soul, User) respaldados en la nube (GitHub: main).

Salida directa en texto plano.
```