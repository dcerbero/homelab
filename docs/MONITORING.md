# 📊 Monitoreo — Prometheus + Grafana

## Estado de implementación

- [x] **Paso 1 — Oracle**: stack completo (Prometheus, Grafana, node-exporter, cAdvisor) desplegado y funcional. Dashboard "Homelab" OK, login OK.
- [ ] **Paso 2 — Pi**: exponer cAdvisor (`9101:8080`) y node-exporter (`9100`).
- [ ] **Paso 3 — Oracle**: añadir targets del Pi al `prometheus.yml` (dashboard unificado).
- [ ] **Paso 4 — Docs finales**: `COMMANDS.md`, `ARCHITECTURE.md`, `README.md`.

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

## Config en el repo

- `services/docker/prometheus/config/prometheus.yml`
- `services/docker/grafana/config/provisioning/` (datasource + provider)
- `services/docker/grafana/seed/homelab.json` → se copia a `$PATH_DATA/persistence/grafana/dashboards/` (editables desde la UI, `force: no`)

## Pendiente — detalle

1. **Paso 2**: en `services/docker/cadvisor/compose.yaml` añadir `ports: ["9101:8080"]`. Desplegar `bash run.sh homeserver --tags cadvisor,monitoring`. Verificar desde Oracle: `curl http://raspberry-homeserver:9101/metrics` y `:9100/metrics`.
2. **Paso 3**: añadir a `prometheus.yml` targets `raspberry-homeserver:9101` y `raspberry-homeserver:9100`; redesplegar `bash run.sh oracle --tags monitoring`; comprobar 5 targets up.
3. **Paso 4**: actualizar `COMMANDS.md`, `ARCHITECTURE.md`, `README.md`.
