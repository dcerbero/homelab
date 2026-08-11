# 🐋 Docker Compose — Servicios

Todos los servicios se despliegan con Docker Compose usando perfiles independientes. Cada servicio vive en su propia carpeta con su `compose.yaml`, y el archivo principal los incluye a todos — así un servicio se puede arrancar solo o con todo el stack. La máquina destino depende del perfil: DNS/dashboard/IA/infra en [yoda](HARDWARE.md#yoda), media en [anton](HARDWARE.md#anton), métricas en [talos](HARDWARE.md#talos).

## Índice

- [Estructura](#estructura)
- [Perfiles](#perfiles)
- [Despliegue](#despliegue)
- [Healthchecks](#healthchecks)
- [Variables de Entorno](#variables-de-entorno)
- [Servicios](#servicios)
- [Almacenamiento Persistente](#almacenamiento-persistente)
- [Backup](#backup)
- [Actualización de Servicios](#actualización-de-servicios)

## Estructura

```text
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
├── cadvisor/compose.yaml     ← Perfil: monitoring
├── node-exporter/compose.yaml← Perfil: monitoring
├── smartctl-exporter/compose.yaml ← Perfil: smart (SMART de discos, solo anton)
├── prometheus/compose.yaml   ← Perfil: metrics
├── prometheus/config/prometheus.yml  ← Config de scrape
├── grafana/compose.yaml      ← Perfil: metrics
└── grafana/config/           ← Provisioning (datasource + dashboards)
```

## Perfiles

| Perfil | Servicios | Descripción |
|---|---|---|
| `dns` | Pi-hole | DNS y bloqueo de anuncios |
| `dashboard` | Heimdall | Panel de control |
| `ia` | OpenClaw | Interfaz de IA local (OpenRouter API) |
| `infra` | nginx | Proxy reverso |
| `media-streaming` | Jellyfin | Streaming multimedia (rol `media`, [anton](HARDWARE.md#anton)) |
| `media-download` | Transmission, Prowlarr, Sonarr | Descarga y gestión (rol `media`, [anton](HARDWARE.md#anton)) |
| `monitoring` | cAdvisor, node-exporter | Exporters de métricas (todas las máquinas) |
| `smart` | smartctl-exporter | Salud SMART de discos (solo [anton](HARDWARE.md#anton)) |
| `metrics` | Prometheus, Grafana | Backend y dashboards (solo [talos](HARDWARE.md#talos)) |

## Despliegue

Todos los servicios se despliegan via **Ansible** (`bash run.sh yoda`). No se ejecuta `docker compose` manualmente para el aprovisionamiento — así el estado del repo es siempre la fuente de verdad y un `git pull` + `run.sh` devuelve todo a como debe estar.

Para administración manual (logs, reinicios, estado):

```bash
cd services/docker/
docker compose --all-profiles ps
docker compose --all-profiles logs -f svcPihole
docker compose --all-profiles restart svcSonarr
```

## Healthchecks

Todos los servicios exponen estado `healthy`/`unhealthy` en `docker ps` y en cAdvisor (métrica `container_health_state`). Un healthcheck es una sonda que el daemon de Docker ejecuta **dentro** del contenedor contra el endpoint HTTP de la propia app; no expone ningún puerto ni endpoint extra.

| Servicio | Origen del healthcheck | Sonda |
|---|---|---|
| Pi-hole | embebido en la imagen | `dig pi.hole @127.0.0.1` |
| nginx | compose | `curl -sS http://localhost/` (sin `-f`: 502 por backend caído ≠ unhealthy) |
| Heimdall | compose | `curl -fsS http://localhost/` |
| OpenClaw | embebido en la imagen | `node dist/docker-healthcheck.js` |
| Transmission | compose | `curl -fsS http://localhost:9091/transmission/web/` |
| Prowlarr | compose | `curl -fsS http://localhost:9696/ping` |
| Sonarr | compose | `curl -fsS http://localhost:8989/ping` |
| Jellyfin | compose | `curl -fsS http://localhost:8096/health` |
| cAdvisor | embebido en la imagen | `wget .../healthz` |
| node-exporter | compose | `wget http://localhost:9100/metrics` |
| Prometheus | compose | `wget http://localhost:9090/-/healthy` |
| Grafana | compose | `curl -fsS http://localhost:3000/api/health` |

> [!NOTE]
> Pi-hole, OpenClaw y cAdvisor traen su `HEALTHCHECK` definido en la imagen: no se define en el compose, porque definir uno lo sobreescribiría. El healthcheck no reinicia contenedores `unhealthy` (el `restart` solo actúa si el proceso muere); su valor es reporte de estado.

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
- **Healthcheck:** embebido en la imagen — `dig pi.hole @127.0.0.1` (consulta local, sin depender de internet)
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
- El rol Ansible hace `compose up` (recrea el contenedor cuando cambia imagen o mounts) y luego un `nginx -s reload` (aplica cambios de contenido en `conf.d/` sin recrear)

### Jellyfin (media-streaming)

Servidor de streaming multimedia. Solo en [anton](HARDWARE.md#anton) (tags `amd64-`). Config detallada y decisiones en [`media/JELLYFIN.md`](media/JELLYFIN.md).

- **Puertos:** `8096:8096`
- **Volúmenes:** `$PATH_DATA/persistence/jellyfin/library`, `$PATH_DATA/media/tvseries`, `$PATH_DATA/media/movies`, `/dev/shm` (transcode temp tmpfs — el default del contenedor son 64MB)
- **Hardware:** `/dev/dri/renderD128` + driver `i965` (VA-API, H.264/MPEG2/VC1). **No QSV**: el ffmpeg bundled trae libva con iHD hardcodeado (gen8+) y no hace fallback; VA-API sí (ver `media/JELLYFIN.md`)
- **Groups:** `video` (44) + `render` (gid 993 de anton) — necesarios para acceder a `renderD128`
- **Config aplicada:** HW accel VA-API, HW encode on, HW decode **off** (el pipeline decode-HW→`scale_vaapi` falla en gen7; el decode por software es barato en el i5), transcode temp `/dev/shm`, HDR tone mapping off, throttling on, HEVC/VP9/AV1 off
- **Red:** acceso remoto bloqueado (`EnableRemoteAccess=false`) con `LocalNetworkSubnets=100.64.0.0/10` para que Tailscale siga funcionando

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

- **Puerto:** `9101:8080` en [yoda](HARDWARE.md#yoda) (acceso de scraping vía Tailscale); en [talos](HARDWARE.md#talos) sin bind al host (scrape interno por nombre de servicio)
- **Volúmenes:** monta `/`, `/var/run`, `/sys`, `/var/lib/docker`, `/dev/disk` (solo lectura)
- **Intervalos:** housekeeping 10s, max housekeeping 15s, global 1m

### node-exporter (monitoring)

Métricas del host (CPU, RAM, disco, red, temperatura) para Prometheus.

- **Puerto:** `9100:9100`
- **Volúmenes:** monta `/proc`, `/sys`, `/` (solo lectura)
- **Colectores:** por defecto (incluye `node_hwmon` para temperatura del RPi)
- **Despliegue:** en [yoda](HARDWARE.md#yoda) no tiene rol propio; lo levanta el rol `cadvisor` vía el perfil `monitoring` (`docker compose --profile monitoring up`)

### Prometheus (metrics — solo [talos](HARDWARE.md#talos))

Backend de métricas. Scrapea a los exporters de ambas máquinas.

- **Puerto:** sin bind al host (interno)
- **Config:** directorio `services/docker/prometheus/config/` (montado `:ro`; `--config.file=/etc/prometheus/config/prometheus.yml`) — se monta el directorio, no el archivo, para que el reload SIGHUP del rol lea los cambios que aplica `git pull` (el mount de archivo único se queda con el inode viejo)
- **Volúmenes:** `$PATH_DATA/persistence/prometheus` (TSDB)
- **Retención:** 15 días
- **Targets:** self, node-exporter y cAdvisor de [talos](HARDWARE.md#talos) (internos) + [yoda](HARDWARE.md#yoda) vía Tailscale (`yoda:9100`, `yoda:9101`). El label `instance` se renombra vía `relabel_configs` a `talos`/`yoda` para el dashboard.
- **Recarga de config:** el rol `monitoring` ejecuta `docker exec prometheus kill -HUP 1` (SIGHUP) tras cada deploy

### Grafana (metrics — solo [talos](HARDWARE.md#talos))

Dashboards y visualización. Acceso por Tailscale (`http://<ip-talos>:3000`).

- **Puerto:** `3000:3000`
- **Admin:** usuario `admin`, password en `GRAFANA_ADMIN_PASSWORD` (secreto de `ansible/.env`)
- **Provisioning:** datasource + provider en `services/docker/grafana/config/provisioning/` (montado `:ro`)
- **Dashboards:** gestionados desde el repo (`seed/homelab.json` es la fuente de verdad; el rol `monitoring` lo copia a `$PATH_DATA/persistence/grafana/dashboards/` con `force: yes` y reinicia el contenedor en cada deploy para aplicar el provisioning). No editables desde la UI (`allowUiUpdates: false` en el provisioning): cualquier cambio se hace en el seed y se despliega con `git pull` + `run.sh talos`.
- **Volúmenes:** `$PATH_DATA/persistence/grafana`

## Almacenamiento Persistente

```text
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
│   ├── transmission/config
│   ├── prometheus/            (TSDB)
│   └── grafana/
│       ├── (estado de Grafana)
│       └── dashboards/        (editables desde la UI)
└── media/                  (biblioteca compartida entre servicios)
    ├── downloads
    ├── movies
    ├── tvseries
    └── watch
```

### Ownership de los directorios de datos

Ansible garantiza la creación y propiedad de los directorios de datos (no se depende del auto-create de Docker, que los crearía como `root` y rompería los permisos):

- `system-setup` crea el esqueleto `$PATH_DATA/persistence` y el árbol `$PATH_DATA/media/*`
- Cada rol de servicio asegura su propio directorio de persistencia (`heimdall`, `openclaw`, `pihole`)
- Todos con owner/group `1000:1000` (uid del primer usuario del sistema), que es el uid que usan las imágenes linuxserver.io vía `PUID`/`PGID`

> [!NOTE]
> `pihole` corre como root en su imagen oficial, así que no le importa el owner; se fija `1000:1000` solo por uniformidad.
>
> Excepción: Grafana corre con uid `472` (su imagen oficial), por eso sus directorios y el seed de dashboards se crean con `472:0`.

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
