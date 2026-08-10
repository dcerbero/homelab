# ⌨️ Comandos de Uso Diario

> El despliegue de servicios se hace vía **Ansible** (`bash run.sh yoda`). Estos comandos son solo para administración manual (estado, logs, reinicios).

## Docker Compose

```bash
# Estado
docker compose --all-profiles ps

# Logs de un servicio
docker compose --all-profiles logs -f svcPihole

# Shell dentro de un contenedor
docker compose --all-profiles exec svcPihole bash

# Reiniciar servicio
docker compose --all-profiles restart svcPihole
```

> Actualización de servicios (pull/up de todos o uno específico) en [`DOCKER.md`](DOCKER.md) (sección "Actualización de Servicios").

## Red

```bash
# Escanear hosts activos en la red local
nmap <tu_subred>

# Qué proceso usa un puerto
sudo lsof -i :53

# Ver IP de Tailscale
tailscale ip -4

# Ver estado de Tailscale
tailscale status
```

## Sistema

```bash
# Ver discos montados
lsblk -f

# Ver uso de disco
df -h

# Ver espacio usado por Docker
docker system df

# Limpiar Docker (contenedores, imágenes, volúmenes no usados)
docker system prune -a --volumes
```

## Monitorización (Prometheus + Grafana)

El stack vive en **talos** (Prometheus, Grafana, node-exporter, cAdvisor). En **yoda** solo corren los exporters (cAdvisor `9101`, node-exporter `9100`).

```bash
# Acceso a Grafana (usuario admin, password en GRAFANA_ADMIN_PASSWORD)
# http://<ip-talos>:3000

# Estado de los contenedores de monitoreo (en cada máquina)
docker compose --all-profiles ps

# Logs de un servicio de monitoreo (en talos)
docker compose --all-profiles logs -f svcPrometheus
docker compose --all-profiles logs -f svcGrafana
docker compose --all-profiles logs -f svcNodeExporter
docker compose --all-profiles logs -f svccAdvisor

# Ver targets de Prometheus (en talos; 5 targets: self, talos + yoda)
docker exec prometheus wget -qO- http://localhost:9090/api/v1/targets

# Recargar config de Prometheus sin reiniciar (Ansible ya lo hace en el rol)
docker exec prometheus kill -HUP 1

# Verificar los exporters de yoda desde talos (vía Tailscale)
curl http://yoda:9101/metrics   # cAdvisor de yoda
curl http://yoda:9100/metrics   # node-exporter de yoda
```

## Health Checks por Servicio

```bash
# Solo contenedores unhealthy
docker ps --filter health=unhealthy

# Estado de salud de un contenedor
docker inspect --format '{{.State.Health.Status}}' sonarr

# Ver el probe definido en un contenedor
docker inspect --format '{{json .Config.Healthcheck}}' pihole
```

> Las sondas de cada servicio están documentadas en [`DOCKER.md`](DOCKER.md) (sección Healthchecks).
