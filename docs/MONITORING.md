# 📊 Monitoreo — Prometheus + Grafana

Todo lo que pasa en el homelab termina en un dashboard: las métricas de ambas máquinas viajan por Tailscale hasta el monitor central, donde se ven de un vistazo. Así sabemos si todo respira bien o si algo empieza a cojear.

## Índice

- [Estado de implementación](#estado-de-implementación)
- [Arquitectura](#arquitectura)
- [Componentes](#componentes)
- [Acceso](#acceso)
- [Detalle operativo](#detalle-operativo)
- [Próximos pasos opcionales](#próximos-pasos-opcionales)

## Estado de implementación

- [x] **Paso 1 — [talos](HARDWARE.md#talos)**: stack completo (Prometheus, Grafana, node-exporter, cAdvisor) desplegado y funcional.
- [x] **Paso 2 — [yoda](HARDWARE.md#yoda)**: cAdvisor expuesto (`9101:8080`) y node-exporter (`9100`) desplegados y verificados.
- [x] **Paso 3 — [talos](HARDWARE.md#talos)**: targets de yoda añadidos a `prometheus.yml`; **5 targets up**; dashboard unificado con agrupación por instancia.
- [x] **Paso 4 — Docs finales**: `COMMANDS.md`, `ARCHITECTURE.md`, `README.md`, `SECURITY.md`.
- [x] **Paso 5 — [anton](HARDWARE.md#anton)**: node-exporter (`9100`), cAdvisor (`9101`) y **smartctl-exporter** (`9633`, SMART de los discos del RAID) desplegados; targets `anton` en `prometheus.yml`.

## Arquitectura

- **[talos](HARDWARE.md#talos)** = monitor centralizado: Prometheus + Grafana + node-exporter + cAdvisor.
- **[yoda](HARDWARE.md#yoda)** = solo exporters: cAdvisor (9101) + node-exporter (9100).
- **[anton](HARDWARE.md#anton)** = solo exporters: node-exporter (9100) + cAdvisor (9101) + smartctl-exporter (9633).
- Scraping de [talos](HARDWARE.md#talos)→[yoda](HARDWARE.md#yoda)/[anton](HARDWARE.md#anton) vía Tailscale (MagicDNS `yoda`/`anton`).

## Componentes

| Servicio | Máquina | Puerto | Perfil | Rol |
|---|---|---|---|---|
| Prometheus | [talos](HARDWARE.md#talos) | interno | metrics | Backend, retención 15d |
| Grafana | [talos](HARDWARE.md#talos) | 3000 | metrics | Dashboards |
| node-exporter | todas | 9100 | monitoring | Métricas del host |
| cAdvisor | todas | 9101 ([yoda](HARDWARE.md#yoda), [anton](HARDWARE.md#anton)) | monitoring | Métricas de contenedores |
| smartctl-exporter | [anton](HARDWARE.md#anton) | 9633 | smart | Salud SMART de los discos (RAID) |

## Acceso

- Grafana: `http://<ip-talos>:3000` — usuario `admin`, password en `GRAFANA_ADMIN_PASSWORD` (`ansible/.env`).
- En el dashboard, la variable **Host** (label `instance`) filtra por máquina: `talos` vs `yoda` vs `anton`. El renombrado lo hace `relabel_configs` en `prometheus.yml`, mapeando las direcciones reales de cada target.

## Detalle operativo

La configuración, targets, recarga y gestión de Prometheus/Grafana están documentadas en [`DOCKER.md`](DOCKER.md) (secciones "Prometheus" y "Grafana").

## Próximos pasos opcionales

> [!TIP]
> Ideas pendientes por si algún día sobra tiempo — ninguna es necesaria hoy, pero todas mejorarían el día a día.

- Alertas (Grafana alerting + notificaciones a ntfy/Telegram).
- Dashboard de Pi-hole en Grafana (`alantoch/pihole-exporter`).
- Recolecta de logs centralizados (Loki + Promtail).
