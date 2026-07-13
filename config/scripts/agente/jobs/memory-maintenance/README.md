# memory-maintenance

Consolidación diaria de memoria.

## Configuración

| Campo | Valor |
|---|---|
| Schedule | `0 23 * * 1-5` (Lun-Vie 23:00 COT) |
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
Sistema: Consolidación agnóstica de memoria general (Lun-Vie 23:00 COT):

1. Ruta base estricta: /home/node/.openclaw/workspace
2. Valida la existencia de "memory/$(date +'%Y-%m-%d').md" mediante la tool de lectura. Si no existe o está vacío → Salida limpia (Exit 0).
3. Carga "MEMORY.md". Si supera las 800 líneas, inserta "<!-- ALERT: >800 lines. Split required -->" en la línea 1 y continúa.
4. Procesa el daily note del día y clasifica la información estrictamente en estas secciones transversales de MEMORY.md:
   - ## Cambios de Estado y Contexto (Modificaciones en el entorno, herramientas en uso, versiones, stacks o configuraciones activas).
   - ## Decisiones y Reglas Adoptadas (Lógicas de trabajo acordadas, preferencias de desarrollo, criterios de diseño).
   - ## Conocimiento y Lecciones Aprendidas (Soluciones a errores complejos, hallazgos, conceptos clave descubiertos).
   - ## Hitos y Progreso (Estado de proyectos, tareas finalizadas, objetivos alcanzados).
5. Reglas de Inserción:
   - Toda línea nueva debe incluir la fecha al inicio en formato `[YYYY-MM-DD]`.
   - Si un dato contradice o actualiza uno anterior, busca el dato viejo, antepón la etiqueta `[HISTÓRICO]` y muévelo al final de su sección. Inserta la información nueva en la parte superior/activa. NO borres datos.
6. Guarda los cambios garantizando la validez de la sintaxis Markdown (bloques de código y tablas cerrados).
7. Ejecuta comandos Git de forma secuencial:
   cd /home/node/.openclaw/workspace && git add MEMORY.md memory/$(date +'%Y-%m-%d').md && git commit -m "chore: consolidate memory — $(date +'%Y-%m-%d')" && git push origin main
8. Retorna únicamente una línea de texto plano para Telegram: "Memoria diaria consolidada en Git exitosamente."
```