# 🎬 Stack Media

Documentación de los servicios de streaming y descarga, que corren en [anton](../HARDWARE.md#anton) (perfiles `media-streaming` y `media-download`, rol `media`).

## Servicios

| Servicio | Perfil | Doc | Estado |
|---|---|---|---|
| Jellyfin | `media-streaming` | [`JELLYFIN.md`](JELLYFIN.md) | En producción |
| Sonarr | `media-download` | — *(ver [`DOCKER.md`](../DOCKER.md#sonarr-media-download))* | En producción |
| Prowlarr | `media-download` | — *(ver [`DOCKER.md`](../DOCKER.md#prowlarr-media-download))* | En producción |
| Transmission | `media-download` | — *(ver [`DOCKER.md`](../DOCKER.md#transmission-media-download))* | En producción |
| Radarr | — | — *(pendiente de añadir al stack)* | No desplegado |

## Notas transversales

- **Transcodificación**: Jellyfin usa **VA-API** (no QSV) con decode por software + encode por hardware. Ver [`JELLYFIN.md`](JELLYFIN.md#la-decisión-central-va-api-no-qsv).
- **Archivos media**: `$PATH_DATA/media/` (`movies`, `tvseries`, `downloads`, `watch`). Config en el repo; estado runtime en `$PATH_DATA/persistence/<svc>/`.
- **Usuarios**: contenedores linuxserver.io con UID/GID 1000 (PUID/PGID).
- **Imágenes arch-pinned**: los servicios media usan tags `amd64-` (solo anton, x86_64).

## Pendientes

- Añadir Radarr al stack (compose + perfil + rol + tags de preflight).
- Documentar Sonarr/Prowlarr/Transmission cuando tengan configuración que merezca registro propio.
