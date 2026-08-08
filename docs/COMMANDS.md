# ⌨️ Comandos de Uso Diario

> El despliegue de servicios se hace vía **Ansible** (`bash run.sh homeserver`). Estos comandos son solo para administración manual (estado, logs, reinicios).

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

# Actualizar todos los servicios
docker compose --all-profiles pull
docker compose --all-profiles up -d

# Actualizar un servicio específico
docker compose --all-profiles pull svcPihole
docker compose --all-profiles up -d svcPihole
```

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

El stack vive en **Oracle** (Prometheus, Grafana, node-exporter, cAdvisor). En el **Pi** solo corren los exporters (cAdvisor `9101`, node-exporter `9100`).

```bash
# Acceso a Grafana (usuario admin, password en GRAFANA_ADMIN_PASSWORD)
# http://<ip-oracle>:3000

# Estado de los contenedores de monitoreo (en cada máquina)
docker compose --all-profiles ps

# Logs de un servicio de monitoreo (en Oracle)
docker compose --all-profiles logs -f svcPrometheus
docker compose --all-profiles logs -f svcGrafana
docker compose --all-profiles logs -f svcNodeExporter
docker compose --all-profiles logs -f svccAdvisor

# Ver targets de Prometheus (en Oracle; 5 targets: self, Oracle + Pi)
docker exec prometheus wget -qO- http://localhost:9090/api/v1/targets

# Recargar config de Prometheus sin reiniciar (Ansible ya lo hace en el rol)
docker exec prometheus kill -HUP 1

# Verificar los exporters del Pi desde Oracle (vía Tailscale)
curl http://raspberry-homeserver:9101/metrics   # cAdvisor del Pi
curl http://raspberry-homeserver:9100/metrics   # node-exporter del Pi
```

## Health Checks por Servicio

```bash
# Ver todos los contenedores (columna STATUS muestra healthy/unhealthy)
docker compose --all-profiles ps

# Solo contenedores unhealthy
docker ps --filter health=unhealthy

# Estado de salud de un contenedor
docker inspect --format '{{.State.Health.Status}}' sonarr

# Ver el probe definido en un contenedor
docker inspect --format '{{json .Config.Healthcheck}}' pihole

# Verificación manual del probe de cada servicio (dentro del contenedor)
docker compose --all-profiles exec nginx_proxy curl -sS -o /dev/null http://localhost/
docker compose --all-profiles exec heimdall curl -fsS http://localhost/
docker compose --all-profiles exec sonarr curl -fsS http://localhost:8989/ping
docker compose --all-profiles exec prowlarr curl -fsS http://localhost:9696/ping
docker compose --all-profiles exec transmission curl -fsS http://localhost:9091/transmission/web/
docker compose --all-profiles exec jellyfin curl -fsS http://localhost:8096/health
```
