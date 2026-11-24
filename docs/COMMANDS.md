# ⌨️ Comandos de Uso Diario

Las recetas que uso cuando hay que meter mano a mano: ver el estado, revisar logs, reiniciar un servicio. Nada de provisionar aquí.

> [!NOTE]
> El despliegue de servicios se hace vía **Ansible** (`bash run.sh yoda`). Estos comandos son solo para administración manual (estado, logs, reinicios).

## Índice

- [Docker Compose](#docker-compose)
- [Red](#red)
- [Sistema](#sistema)
- [Métricas (exporters)](#métricas-exporters)
- [Health Checks por Servicio](#health-checks-por-servicio)

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

## Métricas (exporters)

El stack **Prometheus + Grafana está en pausa** (sin desplegar desde que talos dejó de alojarlo). Solo siguen corriendo los exporters: cAdvisor `9101` y node-exporter `9100` en [yoda](HARDWARE.md#yoda) y [anton](HARDWARE.md#anton), más smartctl-exporter `9633` en anton. Nadie los scrapea, pero siguen disponibles para cuando se reactive el stack. Detalle en [`MONITORING.md`](MONITORING.md).

```bash
# Estado de los contenedores de métricas (en cada máquina)
docker compose --all-profiles ps

# Logs de un exporter (en yoda o anton)
docker compose --all-profiles logs -f svcNodeExporter
docker compose --all-profiles logs -f svccAdvisor
docker compose --all-profiles logs -f svcSmartctlExporter   # solo anton

# Verificar los exporters por Tailscale
curl http://yoda:9101/metrics   # cAdvisor de yoda
curl http://yoda:9100/metrics   # node-exporter de yoda
curl http://anton:9101/metrics  # cAdvisor de anton
curl http://anton:9100/metrics  # node-exporter de anton
curl http://anton:9633/metrics  # smartctl-exporter de anton (SMART del RAID)
```

Comandos de Prometheus/Grafana (`docker exec prometheus kill -HUP 1`, dashboard en `:3000`) quedan documentados en [`MONITORING.md`](MONITORING.md) para cuando el stack vuelva a desplegarse.

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
