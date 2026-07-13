# discovery-scan

Escaneo semanal de nuevas herramientas y recursos AI/Dev/Infra.

## Configuración

| Campo | Valor |
|---|---|
| Schedule | `0 8 * * 6` (Sáb 08:00 COT) |
| Timezone | America/Bogota |
| SessionTarget | isolated (agentTurn) |
| WakeMode | now |
| Timeout | 180s |
| Fallbacks | gemini/gemini-2.0-flash, gpt-4o-mini |

## Delivery

| Campo | Valor |
|---|---|
| Mode | announce |
| Channel | telegram |
| To | 5373909675 |

## Payload

```
Sistema: Escaneo semanal de nuevas herramientas y recursos AI/Dev/Infra (Sábados 11:00 COT):

1. Configuración de Filtros de Viabilidad Estrictos:
   - Eficiencia: Herramientas open-source, self-hosted o APIs con excelente relación costo-beneficio.
   - Entorno: Compatibilidad con despliegues modernos (Docker, Kubernetes o entornos de desarrollo estándar).
   - Enfoque: Soluciones ligeras y optimizadas (evitar software corporativo sobredimensionado que requiera infraestructura masiva).

2. Ejecución de Búsquedas Web:
   Ejecuta exactamente 3 consultas en `web_search` utilizando filtros temporales del año actual (2026):
   - "new open source AI developer tools 2026"
   - "selfhosted productivity dev infra tools 2026"
   - "innovative AI coding agent tools plugins"

3. Matriz de Evaluación Estricta (Escala 1-10):
   - Impacto: Grado de automatización, optimización o mejora en flujos de desarrollo o infraestructura.
   - Relevancia: Aplicabilidad real en entornos de desarrollo ágiles o laboratorios personales (homelabs generalistas).
   - Madurez: Estado del proyecto (10 = Estable/Listo para producción/Imagen Docker oficial, 1 = Repositorio experimental/Hype de Twitter).

4. Algoritmo de Puntuación Conciso:
   - Calcula el puntaje final sumando las tres variables y aplicando una escala lineal ponderada:
     Puntaje = ((Impacto + Relevancia + Madurez) / 3) * 10
   - Establece un umbral de corte estricto: Sólo califica al reporte si el Puntaje es igual o mayor a 60.0/100.
   - Ordena los hallazgos de forma descendente y limita la salida a un máximo de las 5 mejores herramientas que superen el umbral. Si hay menos de 5 que cumplan el criterio, reporta únicamente las válidas.

5. Genera el reporte final para Telegram en texto plano exacto (Calcula la fecha actual en formato YYYY-MM-DD):

📡 Discovery Scan — [YYYY-MM-DD]
Filtro: Cost-Effective / Dev & AI Agnostic

🥇 [Nombre Herramienta] (Puntaje: [X.X]/100)
   → Qué hace: [1 línea técnica exacta]
   → Requerimientos/Arquitectura: [Especifica si soporta Multi-arch (x86_64/ARM64) y su footprint estimado]
   → Tags: #[Categoría] #[Tecnología]

💡 Componente de Optimización: [Si una de las herramientas evaluadas puede sustituir, agilizar o mejorar significativamente algún componente de tu flujo general de desarrollo, agentes o sincronización, detalla cuál es y la ventaja técnica concreta. Si no detectas ninguna disruptiva, escribe "Ninguno esta semana"].

Salida directa en texto plano, sin saludos ni cierres decorativos.
```