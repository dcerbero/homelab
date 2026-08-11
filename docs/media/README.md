# 🎬 Stack Media

Documentación de los servicios de streaming y descarga, que corren en [anton](../HARDWARE.md#anton) (perfiles `media-streaming` y `media-download`, rol `media`).

## Servicios

| Servicio | Perfil | Doc | Estado |
|---|---|---|---|
| Jellyfin | `media-streaming` | [`JELLYFIN.md`](JELLYFIN.md) | En producción |
| Sonarr | `media-download` | — *(ver [`DOCKER.md`](../DOCKER.md#sonarr-media-download))* | En producción |
| Prowlarr | `media-download` | — *(ver [`DOCKER.md`](../DOCKER.md#prowlarr-media-download))* | En producción |
| Transmission | `media-download` | — *(ver [`DOCKER.md`](../DOCKER.md#transmission-media-download))* | En producción |
| FlareSolverr | `media-download` | — *(helper de Prowlarr para indexadores Cloudflare)* | En producción |
| Radarr | `media-download` | — *(ver [`DOCKER.md`](../DOCKER.md#radarr-media-download))* | En producción |

## Guías

| Guía | Contenido |
|---|---|
| [`FORMATOS.md`](FORMATOS.md) | Formato de archivos recomendado para el stack (H.264 estricto, por hardware) |

## Notas transversales

- **Transcodificación**: Jellyfin usa **VA-API** (no QSV) con decode por software + encode por hardware. Ver [`JELLYFIN.md`](JELLYFIN.md#la-decisión-central-va-api-no-qsv).
- **Archivos media**: `$PATH_DATA/media/` (`movies`, `tvseries`, `downloads`, `watch`). Config en el repo; estado runtime en `$PATH_DATA/persistence/<svc>/`.
- **Usuarios**: contenedores linuxserver.io con UID/GID 1000 (PUID/PGID).
- **Imágenes arch-pinned**: los servicios media usan tags `amd64-` (solo anton, x86_64).

## Configuración runtime aplicada (2026-08)

Todo lo siguiente vive **dentro de cada servicio** (`$PATH_DATA/persistence/<svc>/`), no en el repo. Se replica si hace falta con las guías de [`FORMATOS.md`](FORMATOS.md).

- **Indexadores (Prowlarr, 7 activos):** 1337x, YTS, The Pirate Bay, LimeTorrents, Torrent9, World-torrent, EZTV. 1337x y EZTV usan el proxy **FlareSolverr** (tag `flaresolverr` en Prowlarr) por Cloudflare.
- **Apps (Prowlarr → Sonarr/Radarr):** sync `fullSync` con credenciales de auth.
- **Download clients:** Transmission en Sonarr y Radarr (`svcTransmission:9091`, creds de `ansible/.env`).
- **Root folders:** Radarr `/movies`, Sonarr `/tv`.
- **Perfil de calidad:** "Homelab 1080p (H.264)" (renombrado el "Any") en Sonarr y Radarr — capa a ≤1080p, sin CAM/TS/BR-DISK/4K, con custom formats de [`FORMATOS.md`](FORMATOS.md) aplicados. En Radarr además CF de idioma (Español Latino +100, English +50).
- **Idioma:** Sonarr language profile "Español (Latino) + English" (cutoff latino); Radarr vía custom formats de idioma.
- **Auth:** login **Forms** en Prowlarr/Sonarr/Radarr (usuario `baldo`, contraseña `baldo<servicio>` — p. ej. `baldoradarr`). Guarda estas credenciales en tu gestor de contraseñas.

## Pendientes

- Documentar Sonarr/Prowlarr/Transmission cuando tengan configuración que merezca registro propio.
