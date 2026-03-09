# Docker Compose Services

Deploy homelab services using Docker Compose profiles.

## Profiles

**5 independent deployment profiles:**

| Profile | Servicios | Descripción |
|---------|-----------|-------------|
| `dns` | Pi-hole | Servidor DNS/bloqueador de anuncios |
| `dashboard` | Heimdall | Panel de control del homelab |
| `media-streaming` | Jellyfin | Servidor de streaming multimedia |
| `media-download` | Transmission, Prowlarr, Sonarr | Descarga y gestión de contenido |
| `infra` | nginx, cAdvisor | Infraestructura (proxy reverso, monitorización) |

## Setup

Create `.env` in `services/docker/`:

```env
PIHOLE_PASS=your_password
PATH_DATA=/path/to/persistent/data
```

## Deployment

**Single profile:**
```bash
docker compose --profile dns up -d
```

**Multiple profiles:**
```bash
docker compose --profile dns --profile dashboard --profile infra up -d
```

**All services:**
```bash
docker compose up -d
```

**Teardown:**
```bash
docker compose down
docker compose --profile dns down  # specific profile
```

## Ports by Profile

| Profile | Servicio | Puerto | Descripción |
|---------|----------|--------|-------------|
| dns | Pi-hole | 53 | DNS (TCP/UDP) |
| dns | Pi-hole | 8081 | Web UI |
| dashboard | Heimdall | 80 | Dashboard (via nginx) |
| media-streaming | Jellyfin | host | Host network |
| media-download | Transmission | 8082 | UI |
| media-download | Transmission | 51413 | Torrent (TCP/UDP) |
| media-download | Prowlarr | 8083 | Indexer API |
| media-download | Sonarr | 8084 | Series management |
| infra | nginx | 80, 443 | Reverse proxy |
| infra | cAdvisor | 8085 | Container metrics |

## Management

**Logs:**
```bash
docker compose logs -f svcPihole
```

**Container shell:**
```bash
docker compose exec svcPihole bash
```

**Status:**
```bash
docker compose ps
```

**Restart service:**
```bash
docker compose restart svcSonarr
```

## Directory Structure

```
services/docker/
├─ compose.yaml           (principal con includes)
├─ core/
│  ├─ heimdall.yaml      (dashboard profile)
│  └─ pihole.yaml        (dns profile)
├─ media/
│  ├─ transmission.yaml  (media-download profile)
│  ├─ prowlarr.yaml      (media-download profile)
│  ├─ sonarr.yaml        (media-download profile)
│  └─ jellyfin.yaml      (media-streaming profile)
├─ infra/
│  ├─ cadvisor.yaml      (infra profile)
│  └─ nginx.yaml         (infra profile)
└─ README.md             (este archivo)
```

## Persistent Storage

All data paths use `${PATH_DATA}` variable (set in `.env`):

```
${PATH_DATA}/
├─ heimdall/config
├─ pihole/etc-pihole-v2
├─ pihole/etc-dnsmasq.d
├─ transmission/config
├─ sonarr/data
├─ prowlarr/
├─ jellyfin/library
└─ media/
   ├─ downloads
   ├─ tvseries
   ├─ movies
   └─ watch
```

## Troubleshooting

**Port conflicts:**
```bash
sudo lsof -i :53
```

**Container logs:**
```bash
docker compose logs svcPihole
```

**Volume permissions:**
```bash
sudo chown -R 1000:1000 ${PATH_DATA}
```
