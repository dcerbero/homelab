# 📊 Monitoreo — Prometheus + Grafana

## Estado de implementación

- [x] **Paso 1 — talos**: stack completo (Prometheus, Grafana, node-exporter, cAdvisor) desplegado y funcional.
- [x] **Paso 2 — yoda**: cAdvisor expuesto (`9101:8080`) y node-exporter (`9100`) desplegados y verificados.
- [x] **Paso 3 — talos**: targets de yoda añadidos a `prometheus.yml`; **5 targets up**; dashboard unificado con agrupación por instancia.
- [x] **Paso 4 — Docs finales**: `COMMANDS.md`, `ARCHITECTURE.md`, `README.md`, `SECURITY.md`.

## Arquitectura

- **talos** = monitor centralizado: Prometheus + Grafana + node-exporter + cAdvisor.
- **yoda** = solo exporters: cAdvisor (9101) + node-exporter (9100).
- Scraping de talos→yoda vía Tailscale (MagicDNS `yoda`).

## Componentes

| Servicio | Máquina | Puerto | Perfil | Rol |
|---|---|---|---|---|
| Prometheus | talos | interno | metrics | Backend, retención 15d |
| Grafana | talos | 3000 | metrics | Dashboards |
| node-exporter | ambas | 9100 | monitoring | Métricas del host |
| cAdvisor | ambas | 9101 (yoda) | monitoring | Métricas de contenedores |

## Acceso

- Grafana: `http://<ip-talos>:3000` — usuario `admin`, password en `GRAFANA_ADMIN_PASSWORD` (`ansible/.env`).
- En el dashboard, la variable **Host** (label `instance`) filtra por máquina: `talos` (node-exporter/cAdvisor de talos) vs `yoda` (node-exporter/cAdvisor de yoda). El renombrado lo hace `relabel_configs` en `prometheus.yml`, mapeando las direcciones reales de cada target.

## Detalle operativo

La configuración, targets, recarga y gestión de Prometheus/Grafana están documentadas en [`DOCKER.md`](DOCKER.md) (secciones "Prometheus" y "Grafana").

## Próximos pasos opcionales

- Alertas (Grafana alerting + notificaciones a ntfy/Telegram).
- Dashboard de Pi-hole en Grafana (`alantoch/pihole-exporter`).
- Recolecta de logs centralizados (Loki + Promtail).
