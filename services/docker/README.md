# Servicios Docker Compose

Desplegar servicios del homeserver usando perfiles de Docker Compose.

## Perfiles

**5 perfiles de despliegue independientes:**

| Perfil | Servicios | Descripción |
|--------|-----------|-------------|
| `dns` | Pi-hole | Servidor DNS/bloqueador de anuncios |
| `dashboard` | Heimdall | Panel de control del homeserver |
| `media-streaming` | Jellyfin | Servidor de streaming multimedia |
| `media-download` | Transmission, Prowlarr, Sonarr | Descarga y gestión de contenido |
| `infra` | nginx, cAdvisor | Infraestructura (proxy reverso, monitorización) |

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
| dns | Pi-hole | 8081 | Web UI |
| dashboard | Heimdall | 80 | Dashboard (vía nginx) |
| media-streaming | Jellyfin | host | Host network |
| media-download | Transmission | 8082 | Interfaz |
| media-download | Transmission | 51413 | Torrent (TCP/UDP) |
| media-download | Prowlarr | 8083 | API del indexador |
| media-download | Sonarr | 8084 | Gestión de series |
| infra | nginx | 80, 443 | Proxy reverso |
| infra | cAdvisor | 8085 | Métricas de contenedores |

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
│  ├─ heimdall.yaml      (perfil dashboard)
│  └─ pihole.yaml        (perfil dns)
├─ media/
│  ├─ transmission.yaml  (perfil media-download)
│  ├─ prowlarr.yaml      (perfil media-download)
│  ├─ sonarr.yaml        (perfil media-download)
│  └─ jellyfin.yaml      (perfil media-streaming)
├─ infra/
│  ├─ cadvisor.yaml      (perfil infra)
│  └─ nginx.yaml         (perfil infra)
└─ README.md             (este archivo)
```

## Almacenamiento persistente

Todas las rutas de datos usan la variable `${PATH_DATA}` (establecida en `.env`):

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
