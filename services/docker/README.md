# Servicios Docker Compose

Despliegue de servicios del homeserver, provisionados via Ansible. No se ejecuta `docker compose` manualmente.

## Perfiles

**7 perfiles de despliegue independientes:**

| Perfil | Servicios | Descripción |
|--------|-----------|-------------|
| `dns` | Pi-hole | Servidor DNS/bloqueador de anuncios |
| `dashboard` | Heimdall | Panel de control del homeserver |
| `ia` | OpenClaw | Interfaz de IA local (OpenRouter API) |
| `infra` | nginx | Proxy reverso |
| `monitoring` | cAdvisor | Métricas de contenedores |
| `media-streaming` | Jellyfin | Servidor de streaming multimedia |
| `media-download` | Transmission, Prowlarr, Sonarr | Descarga y gestión de contenido |

## Puertos por perfil

| Perfil | Servicio | Puerto | Descripción |
|--------|----------|--------|-------------|
| dns | Pi-hole | 53 | DNS (TCP/UDP) |
| dashboard | Heimdall | — | Tras nginx proxy |
| ia | OpenClaw | — | Tras nginx proxy |
| infra | nginx | 80, 443 | Proxy reverso |
| monitoring | cAdvisor | — | Solo red Docker |
| media-streaming | Jellyfin | 8096 | Streaming multimedia |
| media-download | Transmission | 8082, 51413 | Interfaz web + Torrent |
| media-download | Prowlarr | 8083 | Indexador |
| media-download | Sonarr | 8084 | Gestión de series |

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

Todas las rutas de datos usan la variable `${PATH_DATA}`, resuelta desde `inventory/host_vars/<host>.yml` en Ansible:

```
${PATH_DATA}/
├─ compose/homelab/config/nginx/conf.d
├─ heimdall/config
├─ ia/openclaw
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