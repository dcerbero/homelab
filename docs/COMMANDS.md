# ⌨️ Comandos de Uso Diario

## Docker Compose

```bash
# Desplegar perfil específico
docker compose --profile dns up -d
docker compose --profile dashboard --profile infra up -d
docker compose --profile ia up -d
docker compose --profile monitoring up -d

# Múltiples perfiles
docker compose --profile dns --profile dashboard --profile ia up -d

# Todos los servicios
docker compose up -d

# Estado
docker compose ps

# Logs de un servicio
docker compose logs -f svcPihole

# Shell dentro de un contenedor
docker compose exec svcPihole bash

# Reiniciar servicio
docker compose restart svcPihole

# Detener todo
docker compose down

# Detener perfil específico
docker compose --profile dns down
```

## Red

```bash
# Escanear hosts activos en la red local
nmap 192.168.1.0/24

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
docker compose logs svccAdvisor

# Health check manual (dentro de la red Docker)
docker compose exec svccAdvisor wget -qO- http://localhost:8080/healthz
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
