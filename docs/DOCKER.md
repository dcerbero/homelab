# 🐋 Docker Compose — Servicios

Todos los servicios del homeserver se despliegan con Docker Compose usando perfiles independientes.

## Estructura

```
services/docker/
├── compose.yaml              ← Archivo principal con includes
├── core/
│   └── heimdall.yaml         ← Perfil: dashboard
├── dns/
│   └── pihole.yaml           ← Perfil: dns
├── ia/
│   └── openclaw.yaml         ← Perfil: ia
├── infra/
│   └── nginx.yaml            ← Perfil: infra
├── media/
│   ├── jellyfin.yaml         ← Perfil: media-streaming
│   ├── prowlarr.yaml         ← Perfil: media-download
│   ├── sonarr.yaml           ← Perfil: media-download
│   └── transmission.yaml     ← Perfil: media-download
└── monitoring/
    └── cadvisor.yaml         ← Perfil: monitoring
```

## Perfiles

| Perfil | Servicios | Descripción |
|---|---|---|
| `dns` | Pi-hole | DNS y bloqueo de anuncios |
| `dashboard` | Heimdall | Panel de control |
| `ia` | OpenClaw | Interfaz de IA local |
| `infra` | nginx | Proxy reverso |
| `media-streaming` | Jellyfin | Streaming multimedia |
| `media-download` | Transmission, Prowlarr, Sonarr | Descarga y gestión |
| `monitoring` | cAdvisor | Métricas de contenedores |

## Despliegue

```bash
cd services/docker/

# Perfil único
docker compose --profile dns up -d

# Múltiples perfiles
docker compose --profile dns --profile dashboard --profile infra up -d

# Todos los servicios
docker compose up -d

# Detener
docker compose down
docker compose --profile dns down
```

## Variables de Entorno

Crear `services/docker/.env`:

```env
PIHOLE_PASS=your_password_here
PATH_DATA=/mnt/data
```

## Servicios

### Pi-hole (dns)

DNS server con bloqueo de anuncios. Crítico para la infraestructura.

- **Puertos:** `53:53` (TCP/UDP), `8081:80`
- **Volúmenes:** `$PATH_DATA/pihole/etc-pihole-v2`, `$PATH_DATA/pihole/etc-dnsmasq.d`
- **Upstream DNS:** Cloudflare (1.1.1.1), Google (8.8.8.8)
- **Healthcheck:** `dig google.com @127.0.0.1` cada 30s
- **Cache:** 20,000 entradas, TTL máximo 30 min
- **Logs:** 7 días, máx 50MB

### Heimdall (dashboard)

Panel de control con acceso rápido a todos los servicios.

- **Volúmenes:** `$PATH_DATA/heimdall/config`
- **Detrás de nginx** como proxy reverso

### nginx (infra)

Proxy reverso para los servicios web.

- **Puertos:** `80:80`, `443:443`
- **Config:** `$PATH_DATA/compose/homelab/config/nginx/conf.d/`
- Por defecto redirige todo a Heimdall

### Jellyfin (media-streaming)

Servidor de streaming multimedia.

- **Red:** `host` (acceso directo a hardware)
- **Volúmenes:** `$PATH_DATA/jellyfin/library`, `$PATH_DATA/media/tvseries`, `$PATH_DATA/media/movies`
- **Hardware:** `/dev/dri/renderD128` (transcodificación GPU)

### Transmission (media-download)

Cliente Torrent.

- **Puertos:** `8082:9091` (Web UI), `51413` (Torrent TCP/UDP)
- **Volúmenes:** `$PATH_DATA/transmission/config`, `$PATH_DATA/media/downloads`, `$PATH_DATA/media/watch`

### Sonarr (media-download)

Gestión de series. Se integra con Transmission para descargas.

- **Puerto:** `8084:8989`
- **Volúmenes:** `$PATH_DATA/sonarr/data`, `$PATH_DATA/media/tvseries`, `$PATH_DATA/media/downloads`

### Prowlarr (media-download)

Indexador de torrents. Se integra con Sonarr.

- **Puerto:** `8083:9696`
- **Volúmenes:** `$PATH_DATA/prowlarr`

### OpenClaw (ia)

Interfaz de IA local. Usa **DeepSeek API** para chat/inferencia y **Ollama (nomic-embed-text)** en Oracle Cloud vía Tailscale para embeddings y búsqueda semántica en memoria.

- **Puerto:** `18789:18789`
- **Volúmenes:** `$PATH_DATA/ia/openclaw`
- **Acceso a Docker socket** para ejecutar contenedores

### cAdvisor (monitoring)

Métricas de uso de recursos de todos los contenedores.

- **Puerto:** `8085:8080`
- **Volúmenes:** monta `/`, `/var/run`, `/sys`, `/var/lib/docker`, `/dev/disk` (solo lectura)
- **Intervalos:** housekeeping 10s, global 1m

## Almacenamiento Persistente

```
$PATH_DATA/
├── heimdall/config
├── ia/openclaw
├── jellyfin/library
├── media/
│   ├── downloads
│   ├── movies
│   ├── tvseries
│   └── watch
├── pihole/
│   ├── etc-pihole-v2
│   └── etc-dnsmasq.d
├── prowlarr/
├── sonarr/data
└── transmission/config
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

# Actualizar todos los servicios
docker compose pull
docker compose up -d

# Actualizar un servicio específico
docker compose pull svcPihole
docker compose up -d svcPihole

# Limpiar imágenes antiguas
docker image prune -a
```
