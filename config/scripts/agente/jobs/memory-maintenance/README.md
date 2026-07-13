# memory-maintenance

Consolidación diaria de memoria. No hace git push (lo cubre auto-sync-workspace).

## Configuración

| Campo | Valor |
|---|---|
| Schedule | `0 23 * * *` (Todos los días 23:00 COT) |
| Timezone | America/Bogota |
| SessionTarget | main (systemEvent) |
| WakeMode | now |
| Timeout | — |
| Fallbacks | — |

## Delivery

| Campo | Valor |
|---|---|
| Mode | none |
| Channel | — |
| To | — |

## Payload

```
Sistema: Consolidación de memoria general (Lun-Vie 23:00 COT)

1. Ruta base: /home/node/.openclaw/workspace

2. Validar existencia de "memory/$(date +'%Y-%m-%d').md".
   Si no existe o está vacío → responder únicamente:
   "Sin novedades para consolidar hoy." y terminar (Exit 0).

3. Cargar MEMORY.md. Si supera 800 líneas, agregar al FINAL del mensaje de
   Telegram del paso 8, no como comentario oculto en el archivo:
   "⚠️ MEMORY.md superó las 800 líneas (actual: N). Requiere revisión manual."

4. Procesar el daily note y clasificar cada dato nuevo en la sección REAL
   correspondiente de MEMORY.md (no crear headers nuevos — si ninguna de
   estas cuatro calza, detenerse y preguntar antes de inventar una sección):
   - Cambios de estado/contexto (versiones, stacks, config activa) → agregar
     como entrada fechada en "## Lecciones Aprendidas".
   - Decisiones y reglas adoptadas → agregar como bullet en "## Reglas Operativas".
   - Conocimiento y lecciones (soluciones, hallazgos) → agregar como entrada
     fechada en "## Lecciones Aprendidas".
   - Hitos y progreso de proyectos → agregar como entrada fechada en
     "## Hitos y Progreso" (crear esta sección si no existe todavía, una sola vez).

5. Reglas de inserción:
   - Formato de fecha: "YYYY-MM-DD — texto" (guión largo, sin corchetes —
     igual al resto del archivo, no un formato nuevo).
   - Si un dato contradice o actualiza uno anterior: ubicar el dato viejo,
     anteponerle "[HISTÓRICO]", moverlo al final de su sección. Insertar el
     dato nuevo en la parte activa. Nunca borrar información.
   - Si esta consolidación crea una sección o header que no existía en
     MEMORY.md antes de hoy, decirlo explícitamente en el mensaje de Telegram.

6. Guardar los cambios. Releer el archivo después de escribir y confirmar
   que los bloques de código y encabezados quedaron bien formados antes de
   continuar — no asumir que el write fue correcto.

7. NO ejecutar git commit/push acá — auto-sync-workspace ya hace commit+push
   de MEMORY.md y memory/*.md cada 30 min. Duplicarlo acá es un segundo
   escritor sobre el mismo archivo sin coordinación.

8. Responder en texto plano para Telegram, SOLO con lo que realmente pasó:
   "Memoria consolidada: [N] líneas nuevas, [M] marcadas [HISTÓRICO].
   MEMORY.md: [líneas antes]→[líneas después]. Sync a Git en <30 min vía
   auto-sync-workspace."
   Si el paso 3 disparó la alerta de longitud, agregarla al final de este
   mensaje, no omitirla.
```