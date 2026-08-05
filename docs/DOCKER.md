# 🐋 Docker Compose — Servicios

Todos los servicios del homeserver se despliegan con Docker Compose usando perfiles independientes.

## Estructura

```
services/docker/
├── compose.yaml              ← Archivo principal con includes
├── heimdall/compose.yaml     ← Perfil: dashboard
├── pihole/compose.yaml       ← Perfil: dns
├── openclaw/compose.yaml     ← Perfil: ia
├── nginx/compose.yaml        ← Perfil: infra
├── nginx/config/conf.d/default.conf  ← Config del proxy
├── jellyfin/compose.yaml     ← Perfil: media-streaming
├── prowlarr/compose.yaml     ← Perfil: media-download
├── sonarr/compose.yaml       ← Perfil: media-download
├── transmission/compose.yaml ← Perfil: media-download
└── cadvisor/compose.yaml     ← Perfil: monitoring
```

## Perfiles

| Perfil | Servicios | Descripción |
|---|---|---|
| `dns` | Pi-hole | DNS y bloqueo de anuncios |
| `dashboard` | Heimdall | Panel de control |
| `ia` | OpenClaw | Interfaz de IA local (OpenRouter API) |
| `infra` | nginx | Proxy reverso |
| `media-streaming` | Jellyfin | Streaming multimedia |
| `media-download` | Transmission, Prowlarr, Sonarr | Descarga y gestión |
| `monitoring` | cAdvisor | Métricas de contenedores |

## Despliegue

Todos los servicios se despliegan via **Ansible** (`bash run.sh homeserver`). No se ejecuta `docker compose` manualmente para el aprovisionamiento.

Para administración manual (logs, reinicios, estado):

```bash
cd services/docker/
docker compose ps
docker compose logs -f svcPihole
docker compose restart svcSonarr
```

## Variables de Entorno

`PATH_DATA` se resuelve desde `inventory/host_vars/<host>.yml` en Ansible. Para administración manual, crear `services/docker/.env`:

```env
PATH_DATA=<ruta_datos_persistentes>
```

## Servicios

### Pi-hole (dns)

DNS server con bloqueo de anuncios. Crítico para la infraestructura.

- **Puertos:** `53:53` (TCP/UDP) — DNS, `8085:80` — Web admin
- **Volúmenes:** `$PATH_DATA/persistence/pihole/etc-pihole-v2`, `$PATH_DATA/persistence/pihole/etc-dnsmasq.d`
- **Upstream DNS:** Quad9 (9.9.9.9) y Cloudflare Family (1.1.1.2)
- **Healthcheck:** `dig google.com @127.0.0.1` cada 30s
- **Web UI:** Acceso vía nginx proxy (puerto 80)
- **Cache:** 20,000 entradas, TTL máximo 30 min
- **Logs:** 7 días, máx 50MB

### Heimdall (dashboard)

Panel de control con acceso rápido a todos los servicios.

- **Volúmenes:** `$PATH_DATA/persistence/heimdall/config`
- **Detrás de nginx** como proxy reverso

### nginx (infra)

Proxy reverso para los servicios web.

- **Puertos:** `80:80`, `443:443`
- **Config:** `services/docker/nginx/config/conf.d/` (montada `:ro` desde el repo)
- Por defecto redirige todo a Heimdall

### Jellyfin (media-streaming)

Servidor de streaming multimedia.

- **Puertos:** `8096:8096`
- **Volúmenes:** `$PATH_DATA/persistence/jellyfin/library`, `$PATH_DATA/media/tvseries`, `$PATH_DATA/media/movies`
- **Hardware:** `/dev/dri/renderD128` (transcodificación GPU)

### Transmission (media-download)

Cliente Torrent.

- **Puertos:** `8082:9091` (Web UI), `51413` (Torrent TCP/UDP)
- **Volúmenes:** `$PATH_DATA/persistence/transmission/config`, `$PATH_DATA/media/downloads`, `$PATH_DATA/media/watch`

### Sonarr (media-download)

Gestión de series. Se integra con Transmission para descargas.

- **Puerto:** `8084:8989`
- **Volúmenes:** `$PATH_DATA/persistence/sonarr/data`, `$PATH_DATA/media/tvseries`, `$PATH_DATA/media/downloads`

### Prowlarr (media-download)

Indexador de torrents. Se integra con Sonarr.

- **Puerto:** `8083:9696`
- **Volúmenes:** `$PATH_DATA/persistence/prowlarr`

### OpenClaw (ia)

Interfaz de IA local. Usa la **API de OpenRouter** para inferencia.

- **Puerto:** Solo interno (detrás de nginx proxy)
- **Volúmenes:** `$PATH_DATA/persistence/openclaw`

### cAdvisor (monitoring)

Métricas de uso de recursos de todos los contenedores.

- **Puerto:** Solo acceso interno Docker (sin exposición al host)
- **Volúmenes:** monta `/`, `/var/run`, `/sys`, `/var/lib/docker`, `/dev/disk` (solo lectura)
- **Intervalos:** housekeeping 10s, max housekeeping 15s, global 1m

## Almacenamiento Persistente

```
$PATH_DATA/
├── persistence/            (estado durable de cada servicio)
│   ├── heimdall/config
│   ├── openclaw
│   ├── jellyfin/library
│   ├── pihole/
│   │   ├── etc-pihole-v2
│   │   └── etc-dnsmasq.d
│   ├── prowlarr/
│   ├── sonarr/data
│   └── transmission/config
└── media/                  (biblioteca compartida entre servicios)
    ├── downloads
    ├── movies
    ├── tvseries
    └── watch
```

## Backup

Los datos persistentes están en `$PATH_DATA`. Para respaldar:

```bash
# Backup completo
tar -czf backup-homelab-$(date +%Y%m%d).tar.gz -C $(dirname $PATH_DATA) $(basename $PATH_DATA)

# Backup solo de configuraciones (excluye media)
tar -czf backup-config-$(date +%Y%m%d).tar.gz \
  --exclude='media/downloads' \
  --exclude='media/movies' \
  --exclude='media/tvseries' \
  -C $(dirname $PATH_DATA) $(basename $PATH_DATA)
```

> Programar con cron si se desea automatización.

## Actualización de Servicios

```bash
cd services/docker/

# Actualizar todos los servicios (todos los perfiles)
docker compose --all-profiles pull
docker compose --all-profiles up -d

# Actualizar un servicio específico
docker compose pull svcPihole
docker compose up -d svcPihole

# Limpiar imágenes antiguas
docker image prune -a
```
