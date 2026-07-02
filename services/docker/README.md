# Servicios Docker Compose

Desplegar servicios del homeserver usando perfiles de Docker Compose.

## Perfiles

**7 perfiles de despliegue independientes:**

| Perfil | Servicios | Descripción |
|--------|-----------|-------------|
| `dns` | Pi-hole | Servidor DNS/bloqueador de anuncios |
| `dashboard` | Heimdall | Panel de control del homeserver |
| `ia` | OpenClaw, Headroom | Interfaz de IA local + compresión de contexto |
| `infra` | nginx | Proxy reverso |
| `monitoring` | cAdvisor | Métricas de contenedores |
| `media-streaming` | Jellyfin | Servidor de streaming multimedia |
| `media-download` | Transmission, Prowlarr, Sonarr | Descarga y gestión de contenido |

## Configuración

Crear `.env` en `services/docker/`:

```env
PIHOLE_PASS=tu_contraseña
PATH_DATA=/ruta/a/datos/persistentes
```

## Despliegue

**Un único perfil:**
```bash
docker compose --profile dns up -d
```

**Múltiples perfiles:**
```bash
docker compose --profile dns --profile dashboard --profile infra up -d
```

**Todos los servicios:**
```bash
docker compose up -d
```

**Detener:**
```bash
docker compose down
docker compose --profile dns down  # perfil específico
```

## Puertos por perfil

| Perfil | Servicio | Puerto | Descripción |
|--------|----------|--------|-------------|
| dns | Pi-hole | 53 | DNS (TCP/UDP) |
| dashboard | Heimdall | — | Tras nginx proxy |
| ia | OpenClaw | — | Tras nginx proxy |
| ia | Headroom | 8787 | Solo red Docker |
| infra | nginx | 80, 443 | Proxy reverso |
| monitoring | cAdvisor | — | Solo red Docker |
| media-streaming | Jellyfin | 8096 | Streaming multimedia |
| media-download | Transmission | 8082, 51413 | Interfaz web + Torrent |
| media-download | Prowlarr | 8083 | Indexador |
| media-download | Sonarr | 8084 | Gestión de series |

## Administración

**Registros:**
```bash
docker compose logs -f svcPihole
```

**Shell del contenedor:**
```bash
docker compose exec svcPihole bash
```

**Estado:**
```bash
docker compose ps
```

**Reiniciar servicio:**
```bash
docker compose restart svcSonarr
```

## Estructura de directorios

```
services/docker/
├─ compose.yaml           (principal con includes)
├─ core/
│  └─ heimdall.yaml      (perfil dashboard)
├─ dns/
│  └─ pihole.yaml        (perfil dns)
├─ ia/
│  ├─ openclaw.yaml      (perfil ia)
│  └─ headroom.yaml      (perfil ia)
├─ infra/
│  └─ nginx.yaml         (perfil infra)
├─ media/
│  ├─ transmission.yaml  (perfil media-download)
│  ├─ prowlarr.yaml      (perfil media-download)
│  ├─ sonarr.yaml        (perfil media-download)
│  └─ jellyfin.yaml      (perfil media-streaming)
├─ monitoring/
│  └─ cadvisor.yaml      (perfil monitoring)
└─ README.md             (este archivo)
```

## Almacenamiento persistente

Todas las rutas de datos usan la variable `${PATH_DATA}` (establecida en `.env`):

```
${PATH_DATA}/
├─ compose/homelab/config/nginx/conf.d
├─ heimdall/config
├─ ia/openclaw
├─ ia/headroom
├─ jellyfin/library
├─ media/
│  ├─ downloads
│  ├─ movies
│  ├─ tvseries
│  └─ watch
├─ pihole/
│  ├─ etc-pihole-v2
│  └─ etc-dnsmasq.d
├─ prowlarr/
├─ sonarr/data
└─ transmission/config
```

## Solución de problemas

**Conflictos de puertos:**
```bash
sudo lsof -i :53
```

**Registros del contenedor:**
```bash
docker compose logs svcPihole
```

**Permisos del volumen:**
```bash
sudo chown -R 1000:1000 ${PATH_DATA}
```
