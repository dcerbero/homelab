# 📊 Monitoreo — Prometheus + Grafana

## Estado de implementación

- [x] **Paso 1 — Oracle**: stack completo (Prometheus, Grafana, node-exporter, cAdvisor) desplegado y funcional.
- [x] **Paso 2 — Pi**: cAdvisor expuesto (`9101:8080`) y node-exporter (`9100`) desplegados y verificados.
- [x] **Paso 3 — Oracle**: targets del Pi añadidos a `prometheus.yml`; **5 targets up**; dashboard unificado con agrupación por instancia.
- [x] **Paso 4 — Docs finales**: `COMMANDS.md`, `ARCHITECTURE.md`, `README.md`, `SECURITY.md`.

## Arquitectura

- **Oracle** = monitor centralizado: Prometheus + Grafana + node-exporter + cAdvisor.
- **Pi** = solo exporters: cAdvisor (9101) + node-exporter (9100).
- Scraping de Oracle→Pi vía Tailscale (MagicDNS `raspberry-homeserver`).

## Componentes

| Servicio | Máquina | Puerto | Perfil | Rol |
|---|---|---|---|---|
| Prometheus | Oracle | interno | metrics | Backend, retención 15d |
| Grafana | Oracle | 3000 | metrics | Dashboards |
| node-exporter | ambas | 9100 | monitoring | Métricas del host |
| cAdvisor | ambas | 9101 (Pi) | monitoring | Métricas de contenedores |

## Acceso

- Grafana: `http://<ip-oracle>:3000` — usuario `admin`, password en `GRAFANA_ADMIN_PASSWORD` (`ansible/.env`).
- En el dashboard, la variable **Host** (label `instance`) filtra por máquina: `oracle` (node-exporter/cAdvisor de Oracle) vs `pi` (node-exporter/cAdvisor del Pi). El renombrado lo hace `relabel_configs` en `prometheus.yml`, mapeando las direcciones reales de cada target.

## Config en el repo

- `services/docker/prometheus/config/prometheus.yml` — montado como **directorio** `config/` (`--config.file=/etc/prometheus/config/prometheus.yml`).
- `services/docker/grafana/config/provisioning/` (datasource + provider)
- `services/docker/grafana/seed/homelab.json` → se copia a `$PATH_DATA/persistence/grafana/dashboards/` (editables desde la UI, `force: no`)

## Detalles de operación

- **Recarga de config de Prometheus**: el rol `monitoring` ejecuta `docker exec prometheus kill -HUP 1` (SIGHUP) tras cada deploy. Se usa mount de directorio (no de archivo) porque `git pull` reemplaza el inode y un mount de archivo único seguiría mostrando la versión vieja.
- **node-exporter en el Pi** no tiene rol propio: lo levanta el rol `cadvisor` vía el perfil `monitoring` (`docker compose --profile monitoring up`).
- **Verificación**: `docker exec prometheus wget -qO- http://localhost:9090/api/v1/targets` → 5 targets `up`.

## Próximos pasos opcionales

- Alertas (Grafana alerting + notificaciones a ntfy/Telegram).
- Dashboard de Pi-hole en Grafana (`alantoch/pihole-exporter`).
- Recolecta de logs centralizados (Loki + Promtail).
