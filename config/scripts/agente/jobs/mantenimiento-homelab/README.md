# mantenimiento-homelab

Auditoría semanal de versiones de imágenes Docker del repositorio Homelab.

## Configuración

| Campo | Valor |
|---|---|
| Schedule | `0 8 * * 5` (Vie 08:00 COT) |
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
| To | 5373909675 |

## Payload

```
Sistema: Auditoría semanal de versiones del repositorio Homelab (Viernes 08:00 COT):

1. Sincronización Estricta de la Rama Main (Garantía de Origen):
   WORKSPACE="/home/node/.openclaw/workspace/homelab"
   if [ ! -d "$WORKSPACE/.git" ]; then
     mkdir -p "$WORKSPACE" && git clone --branch main https://github.com/dcerbero/homelab.git "$WORKSPACE"
   fi
   cd "$WORKSPACE" && git checkout -B main && git fetch origin main && git reset --hard origin/main

2. Extracción y Limpieza de Imágenes (Tratamiento Agnóstico Total):
   - Extrae de forma única las imágenes del stack ejecutando estrictamente:
     grep -r "image:" services/docker/ | awk '{print $2}' | tr -d '"' | tr -d "'" | sort -u
   - Queda estrictamente prohibido omitir o saltarse imágenes por razones de entorno o procedencia. La auditoría debe incluir de forma obligatoria la imagen de OpenClaw y cualquier componente del sistema que sea detectado en los archivos YAML.
   - Regla Exclusiva para ':latest': Si una línea no define tag o usa ':latest', asígnala directamente a 🟡 IMPORTANTE con peso fijo de 50 (Riesgo: Alto. Razón: Versión no pinneada. Recomendación: Fijar tag específico). No realices búsqueda web para estas líneas.

3. Pipeline de Búsqueda Web Acotado:
   - Filtra un máximo de 5 imágenes con tags fijos (ej. postgres:15.2) que presenten cambios potenciales.
   - Usa `web_search` para encontrar los últimos releases de la misma rama principal: "[Nombre_Imagen] release notes stable 2026".
   - Queda prohibido saltar de Major version automáticamente (ej. si usas v15, busca el último parche v15.x, no v17.x a menos que la rama ya no tenga soporte).

4. Algoritmo Determinista de Pesos:
   - Asigna 90-100 (🔴 CRÍTICO) SÓLO si el release oficial menciona explícitamente la mitigación de una vulnerabilidad crítica con código CVE (año 2025 o 2026).
   - Asigna 70-89 (🔴 CRÍTICO) si el release declara un "Breaking Change", "Deprecation" que altere tu configuración, o si el cambio de tag implica un salto de versión mayor (Major bump, ej: v1.x.x a v2.x.x), incluso si ocurre en ramas 'nightly' o 'develop'.
   - Asigna 40-69 (🟡 IMPORTANTE) si es un cambio de versión menor (Minor version upgrade) que introduce nuevas características funcionales utilizables.
   - Asigna 10-39 (🔵 INFORMATIVO) si es un parche de errores menor (Patch / Bugfix) sin implicaciones de seguridad documentadas.

5. Formato de Salida en Texto Plano Estricto para Telegram (Calcula fecha en formato YYYY-MM-DD):

📋 Version Audit — [YYYY-MM-DD]

🔴 CRÍTICO (peso 80-100)
  [imagen] [versión actual] → [versión disponible]
  → Razón: [1 línea de datos duros sin adjetivos]
  → Riesgo: [bajo/medio/alto]
  → Recomendación: [1 línea de acción exacta]

🟡 IMPORTANTE (peso 40-79)
  ...

🔵 INFORMATIVO (peso 1-39)
  ...

✅ SIN CAMBIOS
  [imagen] [versión] — al día.

Salida directa en texto plano. Cero prosa introductoria.
```