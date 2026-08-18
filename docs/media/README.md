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

## Configuración runtime aplicada

Todo lo siguiente vive **dentro de cada servicio** (`$PATH_DATA/persistence/<svc>/`), no en el repo. Se replica si hace falta con las guías de [`FORMATOS.md`](FORMATOS.md).

- **Indexadores (Prowlarr, 8 activos):** 1337x, YTS, The Pirate Bay, LimeTorrents, Torrent9, World-torrent, EZTV, **TorrentDownload**. Con tag `flaresolverr` (proxy FlareSolverr): 1337x, EZTV y **LimeTorrents**.
- **Regla de FlareSolverr:** solo se añade el tag `flaresolverr` a indexers con **challenge Cloudflare activo** o fallo de anti-bot confirmado; el resto (YTS, TPB, Torrent9, World-torrent, TorrentDownload) responde 200 limpio y funciona con HTTP directo. Verificar siempre con: `curl -sD - https://<dominio> | grep -i cf-mitigated` (si responde `challenge`, necesita FS; un simple `server: cloudflare` no basta). Meter de más por FlareSolverr añade latencia (navegador headless por request) y puede disparar rate-limiting.
- **Sync por categorías (Prowlarr → apps), categorías reales por indexador:** **Radarr** — 1337x `[2000,8000,2070,2030,2010,2040,2060,2045]`, YTS `[2000,2040,2045,2060]`, TPB `[2000,8000,2020,2040,2060,2030,2045]`, LimeTorrents/Torrent9/TorrentDownload/World-torrent `[2000,8000]`. **Sonarr** — 1337x `[5000,5040,5030]`, TPB `[5000,5050,5040,5045]`, TorrentDownload/World-torrent `[5000,5050]`, EZTV/LimeTorrents/Torrent9 `[5000]`. El `8000 (Other)` de Radarr es **obligatorio** o LimeTorrents no se sincroniza. No hay categoría anime `[5070]` asignada actualmente. Efecto esperado: EZTV (solo TV) no aparece en Radarr, YTS (solo Movies) no aparece en Sonarr.
- **LimeTorrents `sort=seeds`** (Prowlarr, indexer): sort por seeds (`sort=1`) para que releases válidos pero antiguos no queden fuera de la página 1 del Cardigann.
- **Indexadores descartados:** Catorrent (tracker de juegos), torrent-pirat (adulto), MegaPeer (sin resultados). Comprobar siempre las **categorías** (`capabilities`) antes de añadir — el nombre no garantiza el contenido.
- **Apps (Prowlarr → Sonarr/Radarr):** sync `fullSync` con credenciales de auth. **`minimumSeeders=2`** por indexer (campo `fields.minimumSeeders` del Torznab, en cada app) — evita agarrar releases con seeds falsos/inflados que nunca descargan (ver [Torrents que nunca inician](#torrents-que-nunca-inician-swarm-muerto)). Ojo: el `fullSync` de Prowlarr puede pisar este valor en un resync; re-aplicar si vuelve a `1`.
- **Download clients:** Transmission en Sonarr y Radarr (`svcTransmission:9091`, creds de `ansible/.env`).
- **Transmission `settings.json`** (re-aplicar si se pierde la persistencia): `download-dir=/media/downloads/complete`, `incomplete-dir=/media/downloads/incomplete`, `watch-dir=/media/watch`, `ratio-limit-enabled=true` + `ratio-limit=0` (remoción de torrents tras import), `idle-seeding-limit-enabled=true` + `idle-seeding-limit=30`, `utp-enabled=true` + `preferred_transports=["tcp","utp"]` (uTP amplía los peers alcanzables, sobre todo seeders tras NAT).
- **Root folders:** Radarr `/media/movies`, Sonarr `/media/tvseries` (rutas del mount común `/media`).
- **Perfil de calidad:** "Homelab 1080p (H.264)" en Sonarr y Radarr — capa a ≤1080p, sin CAM/TS/BR-DISK/4K, con custom formats de [`FORMATOS.md`](FORMATOS.md). **Radarr:** CF `Español (Latino) Audio` **+1000** (`LanguageSpecification`), `x264` +100, `x265` −100, `10bit` −100, `HDR` −50, `4K` −100, `Remux` −25; `language: Any`; `items` en **orden canónico** (peor→mejor); `cutoff` = Bluray-1080p; `upgradeAllowed = false`. **Sonarr:** CFs `Language: Español (Latino)` +200 y `Español (Latino) Audio` +200, `x264` +100 y negativos iguales; `minFormatScore = 200`; `items` en **orden canónico**; `cutoff` = Bluray-1080p; `upgradeAllowed = false`.
- **Radarr `minFormatScore = 1000`:** el español latino es **obligatorio** — solo pasan releases con score ≥1000 (requiere el CF latino). Si no existe release latino, la película queda pendiente (no baja en otro idioma). El latino se exige por score y no por filtro de idioma del perfil, porque el comparador de Radarr ordena por calidad antes que por score.
- **Límite de tamaño (Radarr):** `maximumSize = 20000` MB (`config/indexer`) — red de seguridad global; frena remux gigantes (>20GB) sin bloquear remux compactos.
- **Idioma:** Radarr `language: Any` + CF + `minFormatScore=1000` (latino obligatorio). Sonarr: los *language profiles* están **deprecados** en v4 y no filtran; el latino se exige con los CFs de idioma (`Language: Español (Latino)` / `Español (Latino) Audio`, +200) + `minFormatScore=200`.
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

**Hardlinks:** dos nombres apuntan al mismo *inode* (misma metadata + mismos bloques de datos en disco). Borrar uno no afecta al otro: solo decrementa el contador de referencias (`links`). Por eso "eliminar el torrent" no rompe el archivo de la biblioteca.

**Requisito para hardlinks:** mismo filesystem *y mismo mount* dentro de los contenedores. Por eso transmission/sonarr/radarr comparten un único mount `$PATH_DATA/media:/media` (los mounts separados fallan con `Cross-device link`/EXDEV). Si algún día descargas y biblioteca quedan en filesystems distintos, Sonarr/Radarr hacen copia+borrado (mismo resultado, pero copia en el import).

**Remoción del torrent:** activada (`removeCompletedDownloads: true`). Además Transmission tiene `ratio-limit: 0` (`ratio-limit-enabled: true`): el torrent queda *Stopped* al completar, lo que hace que Radarr/Sonarr lo puedan remover justo tras el import (Radarr exige `CanBeRemoved` = torrent *Stopped* + límite de seed alcanzado). Con indexadores **públicos** no hay ratio que cuidar. Si algún día añades trackers **privados**, revisa esta decisión (remover al importar perjudica el ratio).

**Torrents no importados (import fallido):** Transmission tiene `idle-seeding-limit` (30 min) activado: dejan de sembrar, pero no se borran (para no perder datos) — se limpian a mano en Transmission.

**Torrents que nunca inician (swarm muerto):** síntoma típico de indexadores **públicos**: se agarra un release que en la búsqueda mostraba seeds, pero al llegar a Transmission queda a 0% (o se clava a mitad) con `peersConnected: 0`. Causa: el swarm real está muerto — los contadores de seeds de trackers/indexadores públicos son inflados o falsos (p. ej. `opentrackr` reporta miles de seeds para torrents con casi ningún peer alcanzable). No es un problema de red: verificar siempre con una prueba contra un torrent sano antes de culpar al firewall/ISP. Mitigaciones activadas en este stack: `minimumSeeders=2` (frena los que ya salen con 0-1 seeds) y uTP activo (más peers alcanzables). **Limpieza:** borrar en Transmission (torrent + datos) y quitar el item de la cola de Radarr/Sonarr (`removeFromClient=true`) — al volver a "missing" la app re-busca el mejor release. `TorrentDownload` es el indexador que más colgados genera (releases legacy tipo *DVDRip XviD* y magnets sin trackers); se mantiene por su volumen latino, pero si se vuelve recurrente conviene desactivarlo.

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
- **Disponibilidad por idioma:** el inglés se encuentra casi siempre; el **español (latino)** depende de que exista el sub para cada título — en contenido oscuro/poco mainstream puede no estar disponible (es disponibilidad, no config).
- **Flujo:** Bazarr sincroniza con Sonarr/Radarr → al importar contenido nuevo descarga los subtítulos de los idiomas del perfil → Jellyfin los lee automáticamente (mismo nombre base que el vídeo).
- **Por qué Bazarr y no el plugin de Jellyfin:** los subs de Bazarr son **archivos reales en la biblioteca** (portables, incluidos en el backup de `/media`, consistentes en todos los clientes); los del plugin de Jellyfin viven en su caché interna y se re-buscan por reproducción. Coste hardware de Bazarr: despreciable (~200-300MB RAM en anton).
- **Sincronización:** A/V sincronizado por diseño (timestamps del contenedor, se conservan en transcode). Para los subs descargados, la garantía principal es el **emparejamiento por hash** (Subdl devuelve el sub exacto del rip). **SubSync OFF** (no cargar la CPU de anton en cada import); si un sub puntual sale desfasado: re-buscar otro en Bazarr o ajustar offset en el reproductor de Jellyfin.

## Pendientes

- Documentar Sonarr/Prowlarr/Transmission cuando tengan configuración que merezca registro propio.
