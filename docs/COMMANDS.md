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

## Monitorización (cAdvisor)

cAdvisor corre con acceso solo a red Docker (sin puerto expuesto al host).

```bash
# Ver logs de cAdvisor
docker compose --all-profiles logs svccAdvisor

# Health check manual (dentro de la red Docker)
docker compose --all-profiles exec svccAdvisor wget -qO- http://localhost:8080/healthz
```

## Health Checks por Servicio

```bash
# Pi-hole
dig google.com @127.0.0.1

# nginx
curl -s -o /dev/null -w "%{http_code}" http://localhost

# Todos los contenedores
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
```
