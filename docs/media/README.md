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
| Bazarr | `media-download` | — *(subtítulos ES-LAT/EN para la biblioteca)* | En producción |
| Seerr | `media-download` | — *(peticiones de contenido, ex-Jellyseerr)* | En producción |
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
- **Transmission `settings.json`** (re-aplicar si se pierde la persistencia): `download-dir=/media/downloads/complete`, `incomplete-dir=/media/downloads/incomplete`, `watch-dir=/media/watch`, `ratio-limit-enabled=true` + `ratio-limit=0` (remoción de torrents tras import), `idle-seeding-limit-enabled=true`.
- **Root folders:** Radarr `/media/movies`, Sonarr `/media/tvseries` (rutas del mount común `/media`).
- **Perfil de calidad:** "Homelab 1080p (H.264)" (renombrado el "Any") en Sonarr y Radarr — capa a ≤1080p, sin CAM/TS/BR-DISK/4K, con custom formats de [`FORMATOS.md`](FORMATOS.md) aplicados. Audio: `Español (Latino) Audio` +100 y `Dual Audio` +50 (español latino > inglés). En Radarr además CF de idioma (Español Latino +100, English +50).
- **Idioma:** Sonarr language profile "Español (Latino) + English" (cutoff latino); Radarr vía custom formats de idioma.
- **Bazarr default profiles:** `movie_default_profile=1` y `serie_default_profile=1` — **obligatorio** para que el contenido nuevo reciba el perfil "Español + English" y Bazarr busque subs automáticamente. Si queda vacío, el contenido se sincroniza con `profileId: None` y no busca nada.
- **Auth:** login **Forms** en Prowlarr/Sonarr/Radarr (usuario `baldo`, contraseña `baldo<servicio>` — p. ej. `baldoradarr`). Guarda estas credenciales en tu gestor de contraseñas.
- **Seerr (ex-Jellyseerr):** frontend de peticiones conectado a Jellyfin (auth por usuarios Jellyfin, admin `baldo`/`baldojellyfin`), Sonarr y Radarr — ambos con el perfil "Homelab 1080p (H.264)" y root folders `/media/tvseries` y `/media/movies`. UI en `http://anton:8087`.

## Flujo de descarga → biblioteca

Cómo viaja el contenido de la descarga hasta la biblioteca, y por qué no quedan archivos duplicados:

```
1. Sonarr/Radarr eligen un release (perfil "Homelab 1080p (H.264)")
   → lo envían a Transmission (categoría sonarr/radarr)
2. Transmission descarga a  /media/downloads/complete/{sonarr,radarr}/<torrent>/
3. Al completar, Sonarr/Radarr importan:  HARDLINK + rename
   /media/downloads/complete/.../<file>.mkv  ──►  /media/tvseries|movies/.../<nombre limpio>.mkv
   ↑ mismo inode → NO duplica datos en disco (0 bytes extra en el import)
4. Sonarr/Radarr eliminan el torrent (Remove Completed) → Transmission borra
   la copia de /media/downloads → solo queda el archivo de la biblioteca
5. Jellyfin detecta el archivo nuevo → aparece en la biblioteca
```

**Hardlinks:** dos nombres apuntan al mismo *inode* (misma metadata + mismos bloques de datos en disco). Borrar uno no afecta al otro: solo decrementa el contador de referencias (`links`). Por eso "eliminar el torrent" no rompe el archivo de la biblioteca — verificado: `inode=22020106 links=2` → borrar la copia de downloads → `links=1`, contenido intacto.

**Requisito para hardlinks:** mismo filesystem *y mismo mount* dentro de los contenedores. Por eso transmission/sonarr/radarr comparten un único mount `$PATH_DATA/media:/media` (los mounts separados fallan con `Cross-device link`/EXDEV). Si algún día descargas y biblioteca quedan en filesystems distintos, Sonarr/Radarr hacen copia+borrado (mismo resultado, pero copia en el import).

**Remoción del torrent:** activada (`removeCompletedDownloads: true`). Además Transmission tiene `ratio-limit: 0` (`ratio-limit-enabled: true`): el torrent queda *Stopped* al completar, lo que hace que Radarr/Sonarr lo puedan remover justo tras el import (Radarr exige `CanBeRemoved` = torrent *Stopped* + límite de seed alcanzado). Con indexadores **públicos** no hay ratio que cuidar. Si algún día añades trackers **privados**, revisa esta decisión (remover al importar perjudica el ratio).

**Torrents no importados (import fallido):** Transmission tiene `idle-seeding-limit` (30 min) activado: dejan de sembrar, pero no se borran (para no perder datos) — se limpian a mano en Transmission.

**Copia de la biblioteca (backup):**
- **Contenido:** `$PATH_DATA/media/movies/` + `$PATH_DATA/media/tvseries/` (los archivos finales, ya organizados). `downloads/` y `watch/` son transitorios — no se copian.
- **Config y estado de las apps:** `$PATH_DATA/persistence/` (Jellyfin, Sonarr, Radarr, Prowlarr, Transmission). Comandos en [`../DOCKER.md`](../DOCKER.md#backup).
- Los archivos de la biblioteca son reales e independientes (el hardlink de descarga desaparece al remover el torrent) → copiar desde `movies/`/`tvseries/` siempre es correcto.

> [!NOTE]
> **Uso personal y legal:** este stack está configurado para contenido propio y **libre de derechos restrictivos** (contenido sin copyright, de dominio público, con licencia libre, o creado por ti). Este homelab es de uso privado y no distribuye contenido. No está destinado a descargar ni compartir obras con derechos de autor.

## Subtítulos (Bazarr)

Sonarr v4 y Radarr v6 **no descargan subtítulos** (feature eliminada de la plataforma). La gestión de subtítulos la hace **Bazarr**, que se conecta a ambos y escribe los `.srt` **al lado del vídeo** (sidecar) en las bibliotecas.

- **Idiomas:** English (`en`) + Spanish (Latino `ea`), perfil de idiomas "Español + English". **Default profiles** (`movie_default_profile`/`serie_default_profile` = 1) — sin ellos el contenido queda sin perfil y no busca subs.
- **Proveedores:** Subdl (API key personal en `subdl.com`) + gratuitos sin cuenta (subf2m, subs4free, wizdom, xsubs, tvsubtitles, napiprojekt, yifysubtitles, thesubdb). *(OpenSubtitles.com ahora es de pago — no se usa.)*
- **Disponibilidad por idioma:** el inglés se encuentra casi siempre (verificado: score 165 en Subdl); el **español (latino)** depende de que exista el sub para cada título — en contenido oscuro/poco mainstream puede no estar disponible (es disponibilidad, no config).
- **Flujo:** Bazarr sincroniza con Sonarr/Radarr → al importar contenido nuevo descarga los subtítulos de los idiomas del perfil → Jellyfin los lee automáticamente (mismo nombre base que el vídeo).
- **Por qué Bazarr y no el plugin de Jellyfin:** los subs de Bazarr son **archivos reales en la biblioteca** (portables, incluidos en el backup de `/media`, consistentes en todos los clientes); los del plugin de Jellyfin viven en su caché interna y se re-buscan por reproducción. Coste hardware de Bazarr: despreciable (~200-300MB RAM en anton).
- **Sincronización:** A/V sincronizado por diseño (timestamps del contenedor, se conservan en transcode). Para los subs descargados, la garantía principal es el **emparejamiento por hash** (Subdl devuelve el sub exacto del rip). **SubSync OFF** (no cargar la CPU de anton en cada import); si un sub puntual sale desfasado: re-buscar otro en Bazarr o ajustar offset en el reproductor de Jellyfin.

## Pendientes

- Documentar Sonarr/Prowlarr/Transmission cuando tengan configuración que merezca registro propio.
