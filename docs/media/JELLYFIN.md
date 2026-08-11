# 🎬 Jellyfin en anton — configuración optimizada

Jellyfin corre como contenedor Docker (linuxserver, tags `amd64-`) en [anton](../HARDWARE.md#anton). Este documento registra **la configuración aplicada y el porqué de cada decisión**, verificada empíricamente sobre el hardware real (2026-08-11).

## Índice

- [Hardware y limitaciones](#hardware-y-limitaciones)
- [La decisión central: VA-API, no QSV](#la-decisión-central-va-api-no-qsv)
- [Decode por software + encode por hardware](#decode-por-software--encode-por-hardware)
- [Configuración aplicada](#configuración-aplicada)
  - [encoding.xml](#encodingxml)
  - [system.xml](#systemxml)
  - [network.xml](#networkxml)
  - [compose.yaml](#composeyaml)
- [Acceso a la red](#acceso-a-la-red)
- [Bibliotecas (wizard)](#bibliotecas-wizard)
- [Verificación realizada](#verificación-realizada)
- [Dónde vive cada cosa](#dónde-vive-cada-cosa)
- [Pendientes](#pendientes)

## Hardware y limitaciones

| Característica | Valor |
|---|---|
| CPU | Intel Core i5-3470S (Ivy Bridge, 4c/4t @ 2.9GHz) |
| iGPU | Intel HD 2500 (`/dev/dri/renderD128`) — QSV **H.264** solo, **sin HEVC/VP9/AV1** |
| RAM | 7.7 GiB + 4 GiB swap |
| Almacenamiento | RAID1 2× WD Green (5400rpm) en `/server` — lento para I/O aleatorio |

Consecuencias directas:
- **No** hay HEVC/VP9/AV1 ni en decode ni en encode → esa carga cae al software (inviable en este CPU) o al direct play del cliente.
- El **encode H.264** es la parte cara del transcode y **sí** se puede descargar a la GPU.
- El **decode H.264 por software** es barato en el i5 (1080p ≈ pocos % de CPU) → no penaliza.
- El disco es lento → el temp de transcode va a **tmpfs** (`/dev/shm`), no al RAID1.

## La decisión central: VA-API, no QSV

En gen7/Ivy Bridge lo correcto es **VA-API**. Verificado por prueba real en el contenedor:

- **QSV falla**: el ffmpeg bundled de Jellyfin (jellyfin-ffmpeg 7.x) trae su propia libva que tiene el driver **iHD hardcodeado** (iHD es para gen8+). Ignora `LIBVA_DRIVER_NAME`/`LIBVA_DRIVERS_PATH` y no hay fallback → `Failed to initialise VAAPI connection`.
- **VA-API funciona**: la misma libva prueba primero iHD, falla (inofensivo) y hace fallback a `i965_drv_video.so` (que montamos del host). `VAAPI driver: Intel i965 driver for Intel(R) Ivybridge Desktop`.

Jellyfin 10.11 tiene soporte explícito para esto: detecta el dispositivo como i965 (`VAAPI device "/dev/dri/renderD128" is Intel GPU (i965)`) y lanza ffmpeg con `-init_hw_device vaapi=va:/dev/dri/renderD128,driver=i965`.

El driver `i965` ya no existe en la base Ubuntu 26.04 de la imagen 10.11.11 (Mesa 25+ lo eliminó), por eso el rol `media` instala `i965-va-driver` en el host y el compose lo monta `:ro` en `/usr/lib/x86_64-linux-gnu/dri/`.

## Decode por software + encode por hardware

Probado en el contenedor con el ffmpeg real:

| Pipeline | Resultado |
|---|---|
| decode HW (`-hwaccel vaapi -hwaccel_output_format vaapi`) → `scale_vaapi` → `h264_vaapi` | ❌ **Falla**: `Impossible to convert` (-38/-22). El decoder cae a "native" y `scale_vaapi` no acepta los frames. |
| decode **software** → `format=nv12,hwupload` → `h264_vaapi` | ✅ Funciona (encode HW al 100%) |

Como Jellyfin intenta decode HW solo si los codecs están en `HardwareDecodingCodecs`, y ese pipeline falla en gen7, dejamos esa lista **vacía** → Jellyfin decodifica por software y codifica con `h264_vaapi`. Es el único camino fiable, y además es el óptimo: decode barato en CPU + encode caro en GPU.

> [!NOTE]
> El decode HW "funciona" aislado, pero el pipeline completo de Jellyfin (con `scale_vaapi`) revienta en gen7. Aunque Jellyfin hiciera fallback automático, el reintento usaría encode por software (libx264) — mucho peor. Por eso la decisión es explícita, no por defecto.

## Configuración aplicada

### encoding.xml

Ruta: `/server/persistence/jellyfin/library/encoding.xml` (config runtime, no versionada — ver [Dónde vive cada cosa](#dónde-vive-cada-cosa)).

| Campo | Valor | Por qué |
|---|---|---|
| `HardwareAccelerationType` | `vaapi` | Única vía HW funcional en gen7 (QSV roto por iHD hardcodeado) |
| `VaapiDevice` | `/dev/dri/renderD128` | Render node del iGPU |
| `EnableHardwareEncoding` | `true` | El encode H.264 va a la GPU (lo caro) |
| `HardwareDecodingCodecs` | *(vacío)* | El pipeline decode-HW falla en gen7; decode por software es barato |
| `EnableIntelLowPowerH264HwEncoder` | `false` | Low-power es para gen9+; en gen7 rompe |
| `EnableTonemapping` | `false` | Tone mapping HDR→SDR requiere HW moderno; en gen7 es CPU y no compensa |
| `AllowHevcEncoding` / `AllowAv1Encoding` | `false` | La iGPU no soporta HEVC/AV1 |
| `EnableThrottling` | `true` | Salta frames cuando el buffer del cliente está lleno; reduce carga en el i5 |
| `TranscodingTempPath` | `/dev/shm` | tmpfs del host (3.9G) — evita golpear el RAID1 de WD Green |
| `EncodingThreadCount` | `-1` | Auto (los 4 hilos) |

> [!IMPORTANT]
> En Jellyfin 10.11 `TranscodingTempPath` vive en **`encoding.xml`**, no en `system.xml` (en 10.10- era `ServerConfiguration`). Si se escribe en `system.xml`, Jellyfin lo descarta silenciosamente en el próximo arranque.

### system.xml

| Campo | Valor | Por qué |
|---|---|---|
| `EnableMetrics` | `true` | Expone `/metrics` para Prometheus (talos) — ver [Pendientes](#pendientes) |

### network.xml

| Campo | Valor | Por qué |
|---|---|---|
| `EnableRemoteAccess` | `false` | Sin acceso público a Jellyfin: solo LAN/Tailscale, sin port-forwarding ni proxy |
| `LocalNetworkSubnets` | `100.64.0.0/10`, `172.16.0.0/12`, `10.0.0.0/8`, `192.168.0.0/16` | Tailscale + **red Docker (172.18.x, necesaria para que Seerr/Sonarr/etc. hablen con Jellyfin)** + LAN clásica. Cuando `LocalNetworkSubnets` no está vacío, Jellyfin **usa solo esos rangos** (no suma los defaults) |

> [!IMPORTANT]
> `LocalNetworkSubnets` **reemplaza** los subnets por defecto: si solo se pone `100.64.0.0/10` (como se hizo al principio), los contenedores de la red Docker (172.18.x) quedan bloqueados (`RejectDueToRemoteAccessDisabled` → 503) y Seerr/Sonarr no pueden conectar con Jellyfin. Por eso el valor incluye explícitamente `172.16.0.0/12`.

> [!WARNING]
> Si se desmarca "Permitir conexiones remotas" en el wizard con `LocalNetworkSubnets` vacío, **te quedas fuera por Tailscale** (el `/Startup/Complete` se bloquea y no puedes terminar el setup). Workaround mientras tanto: túnel SSH (`ssh -N -L 8096:localhost:8096 anton` + abrir `http://localhost:8096`), porque `127.0.0.1` siempre es local.

### compose.yaml

Ruta: `services/docker/jellyfin/compose.yaml` (versionada).

- **Volumen** `/dev/shm:/dev/shm` — el `/dev/shm` del contenedor por defecto son 64 MB; el transcode temp en tmpfs lo necesita. Sin este mount, un transcode largo agota los 64 MB.
- **Dispositivo** `/dev/dri/renderD128` — iGPU.
- **Groups** `video` (44) + `render` (993, gid de anton) — permisos sobre `renderD128`.
- **Driver** `i965_drv_video.so` montado `:ro` — el que el libva de VA-API necesita y la imagen ya no trae.

## Acceso a la red

- **LAN** (`192.168.x.x`) y **Tailscale** (`100.x.x.x`) → funcionan directamente.
- **Internet público** → bloqueado (`EnableRemoteAccess=false`). Jellyfin no está detrás de nginx (que solo proxyya desde yoda).
- El resto de servicios del stack publican sus puertos solo a LAN/Tailscale; `8096` es solo de Jellyfin.

## Bibliotecas (wizard)

Creadas con el wizard de primer arranque (rutas del **contenedor**):

| Biblioteca | Tipo | Carpeta |
|---|---|---|
| Películas | Movies | `/data/movies` |
| Series | TV Shows | `/data/tvshows` |

Decisiones al crearlas (por el hardware):
- **Trickplay OFF** y **Imágenes de capítulos OFF**: extraer imágenes del vídeo es CPU + disco intensivo y ocupa varios GB; en WD Green no compensa.
- **Screen Grabber / Embedded Image Extractor OFF**: mismos motivos; solo proveedores de internet (TMDB/OMDb).
- **Metadatos**: `Nfo` + guardar imágenes junto al medio (portabilidad).
- **Monitorización en tiempo real ON** (inotify en ext4).
- Idioma metadatos: Español/Colombia; `UICulture en-US` de sistema sin tocar.

## Verificación realizada

1. **VA-API device**: log `VAAPI device "/dev/dri/renderD128" is Intel GPU (i965)`.
2. **Receta de pipeline**: decode sw + `format=nv12,hwupload` + `h264_vaapi` → output válido.
3. **Transcode end-to-end real** (cliente web forzando baja calidad): Jellyfin lanzó
   `ffmpeg ... -init_hw_device vaapi=va:/dev/dri/renderD128,driver=i965 -codec:v:0 h264_vaapi ... -vf "...format=nv12,hwupload_vaapi" ... -hls_segment_filename "/dev/shm/...mp4"` → **exit code 0**.
4. **`/dev/shm`** del contenedor pasa a 3.9G tras el mount del compose.
5. Librería detecta contenido nuevo (scan manual tras crear el archivo de prueba; el monitor en tiempo real no disparó con un archivo creado por root — ver Pendientes).

## Dónde vive cada cosa

- **Compose y rol**: `services/docker/jellyfin/compose.yaml` · `ansible/roles/media/` (instala `i965-va-driver`, crea `persistence/jellyfin/library` con uid 1000).
- **Config runtime de Jellyfin**: `/server/persistence/jellyfin/library/` (`encoding.xml`, `system.xml`, `network.xml`, `data/jellyfin.db`) — **no versionada**, es estado del servicio. Se incluye en el backup de configs de [`../DOCKER.md`](../DOCKER.md).
- **Media**: `/server/media/{movies,tvseries,downloads,watch}`.

Re-aplicar la config si se pierde: los XML se regeneran con defaults al primer arranque; la config óptima está documentada aquí para replicarla por UI o editando los XML + `docker restart jellyfin`.

## Pendientes

- [ ] **Prometheus (talos)**: añadir job de scrape para `jellyfin:8096/metrics` (`EnableMetrics=true` ya activado).
- [ ] Evaluar el monitor en tiempo real: no detectó el archivo de prueba creado por root en la biblioteca; confirmar comportamiento con archivos reales importados por Sonarr (uid 1000).
