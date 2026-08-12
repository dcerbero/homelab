# 🎬 Sugerencias de formato para el stack media

Guía de qué formato de archivos debe bajar y almacenar el stack media de [anton](../HARDWARE.md#anton) (Sonarr → Prowlarr → Transmission → Jellyfin), y el porqué de cada regla. Se complementa con [`JELLYFIN.md`](JELLYFIN.md) (config de transcodificación).

## Índice

- [Regla de oro](#regla-de-oro)
- [Por qué: el hardware manda](#por-qué-el-hardware-manda)
- [Formato objetivo por archivo](#formato-objetivo-por-archivo)
- [Configuración en Sonarr](#configuración-en-sonarr)
- [Radarr](#radarr)
- [Prowlarr y Transmission](#prowlarr-y-transmission)
- [Tradeoff: H.264 vs espacio](#tradeoff-h264-vs-espacio)
- [Verificación](#verificación)

## Regla de oro

> **H.264 estricto + español latino obligatorio.** La iGPU de anton (Intel HD 2500, gen7) solo hace H.264. El audio debe ser **español latino**, y eso es un **requisito duro** en ambas apps: el perfil exige un score mínimo de Custom Formats que solo alcanzan los releases con audio latino. Si no existe release latino, **no se agarra nada** — la película queda pendiente en vez de bajar una copia en otro idioma.

Reglas derivadas (en orden):
1. Si un archivo no lo reproduce el dispositivo **directo**, Jellyfin tiene que transcodificarlo → y anton solo transcodifica bien H.264.
2. El stack debe **bajar H.264 1080p SDR** y rechazar el resto.
3. **Audio: español latino obligatorio** (vía `minFormatScore`, ver [Sonarr](#configuración-en-sonarr) y [Radarr](#radarr)). Los CFs negativos (x265 −100, 10bit −100, HDR −50, 4K −100, Remux −25) refuerzan el rechazo por hardware y por peso.

## Por qué: el hardware manda

| Límite de anton | Consecuencia |
|---|---|
| iGPU gen7: solo decode/encode H.264 | HEVC/VP9/AV1 y 10-bit: ni decode ni encode HW (ver [`JELLYFIN.md`](JELLYFIN.md)) |
| Transcode = decode por software + encode HW | El decode por CPU es barato en H.264 1080p; en HEVC por software es inviable |
| Tone mapping desactivado | HDR (HDR10/HLG/DV) en pantalla SDR se ve lavado |
| RAID1 de 916GB, WD Green viejos | Espacio limitado y disco lento → penaliza 4K (peso) y remux gigantes |

## Formato objetivo por archivo

| Característica | Recomendado | Evitar | Por qué |
|---|---|---|---|
| Códec vídeo | **H.264 / AVC (x264)** | x265/HEVC, AV1, VP9 | único códec con HW en gen7 |
| Profundidad | 8-bit | 10-bit | 10-bit requiere decode SW pesado |
| Resolución | hasta **1080p** | 4K/2160p | 4K casi siempre HEVC y muy pesado |
| Rango | **SDR** | HDR10, HLG, DV | tonemapping off → HDR lavado en SDR |
| Contenedor | MKV / MP4 | — | indistinto para Jellyfin |
| Tamaño | **2–6 GB** (1080p x264); 1–2 GB (720p) | Remux >20 GB, remux 4K | el **límite global `maximumSize` = 20 GB** en Radarr (`config/indexer`) frena los monstruos sin bloquear remux compactos. Sweet spot del stack: 2–6 GB |
| Audio | AAC, AC3, EAC3 (o el original) · **preferir dual ES-LAT + EN** | TrueHD, DTS-HD MA, Atmos | passthrough problemático en muchos clientes y sin beneficio en esta casa. Audio preferido: español latino → inglés |
| Subtítulos | texto embebido (SRT/ASS) | solo PGS/VobSub | los de imagen se queman por CPU en un transcode |

## Configuración en Sonarr

Sonarr v4 soporta **Custom Formats** de forma nativa. Estrategia de scoring.

**Custom formats configurados** (Settings → Custom Formats):

| Custom format | Condición | Score |
|---|---|---|
| `Language: Español (Latino)` | `LanguageSpecification` (idioma Spanish Latino) | +200 |
| `Español (Latino) Audio` | `Release Title` contiene `latino\|español latino\|es-lat\|doblaje` | +200 |
| `x264` | `Release Title` contiene `x264` | +100 |
| `x265` | `Release Title` contiene `x265` / códec `HEVC` | −100 |
| `10bit` | `Release Title` contiene `10bit` | −100 |
| `HDR` | `Release Title` contiene `HDR\|HDR10\|DV\|Dolby` | −50 |
| `4K` | Resolución ≥ 2160p | −100 |
| `Remux` | `Release Title` contiene `Remux` | −25 |

**Quality Profile "Homelab 1080p (H.264)"** (series): `minFormatScore = 200`, `upgradeAllowed = false`, `items` en **orden canónico** (peor→mejor) y `cutoff` = Bluray-1080p (id de calidad 7). Solo pasan releases con score ≥200, que exige el latino (los CFs de idioma suman +200/+200; un release en otro idioma se queda en ≤+100 por x264 y no alcanza). Sonarr v4 **no aplica *language profiles*** (están deprecados y no filtran por idioma): el idioma se controla con los CFs de idioma + `minFormatScore`.

## Radarr

Perfil "Homelab 1080p (H.264)" (mismo nombre que en Sonarr), con reglas propias de Radarr v6:

- **Custom formats reales:** `Español (Latino) Audio` **+1000** (implementación `LanguageSpecification`, idioma Spanish Latino id 37), `x264` +100, `x265` −100, `10bit` −100, `HDR` −50, `4K` −100, `Remux` −25. No hay CF "Dual Audio".
- **Idioma:** `language: Any` + **`minFormatScore = 1000`** → el español latino es **obligatorio**: solo pasan releases con el CF +1000. El latino se exige por score, **no** por filtro de idioma del perfil: el comparador de Radarr ordena por calidad antes que por score, así que sin `minFormatScore` un BluRay-1080p inglés (score 100) le ganaría a un `1080p (Esp.Latino)` que parsea como HDTV-1080p (score 1000).
- **Orden de `items`:** el array `items` del perfil debe estar en **orden canónico** (peor→mejor: `Unknown, WORKPRINT, CAM, …, SDTV, DVD, DVD-R, …, Bluray-1080p, Remux-1080p, …, Remux-2160p`), porque Radarr usa el índice del array como prioridad de calidad (índice alto = mejor). Un array invertido hace agarrar la peor calidad primero. `cutoff` = Bluray-1080p (id de calidad 7). El mismo requisito de orden canónico aplica al perfil de **Sonarr** (con su propia schema de calidades).
- **Calidades ≤1080p permitidas:** SDTV, DVD, Bluray-480p+, HDTV-720p/1080p, WEB/WEBRip/WEB-DL 720p/1080p, Bluray-1080p, Remux-1080p. **No permitidas:** CAM, TS, TELESYNC, DVD-R, BR-DISK, 4K/2160p.
- **Tamaño:** límite global `maximumSize = 20000` MB (`config/indexer`) como red de seguridad — frena remux gigantes (>20GB) sin bloquear remux compactos.

> [!TIP]
> No hace falta borrar releases x265: basta el scoring negativo (se rechazan solos por score).

## Prowlarr y Transmission

- **Prowlarr**: sin impacto de formato — solo agrega indexadores para Sonarr. Nada que configurar aquí.
- **Transmission**: sin impacto de formato — solo descarga. Nota: los archivos llegan a `/downloads` y Sonarr los mueve a `tvseries`; la extensión `.part` durante la descarga no afecta al escaneo de Jellyfin porque Jellyfin solo mira `movies/` y `tvseries/`.

## Tradeoff: H.264 vs espacio

H.264 1080p ocupa **~2-3x** más que HEVC 1080p a calidad comparable. El RAID1 es de 916GB con discos de 2009 — el espacio es un recurso real.

**Decisión:** compatibilidad total de transcode > espacio. Se penaliza HEVC.

**Vía de escape si el disco aprieta:** relajar a "HEVC tolerado" (score −25 en vez de −100) y garantizar que los clientes de la casa reproduzcan HEVC directo (la mayoría de TVs modernas lo hacen). El transcode de esos archivos seguirá siendo imposible en anton, pero se verían directo. No cambiar la config de Jellyfin, solo la del arr.

## Verificación

Comprobar que lo que baja es H.264 y que la pista de audio latino existe:

```bash
# En anton, sobre un archivo recién importado
docker exec jellyfin /usr/lib/jellyfin-ffmpeg/ffprobe -hide_banner /data/movies/<película>/<archivo> \
  -show_entries stream=codec_name,profile,width,height,pix_fmt -of compact
# Esperado: codec_name=h264, pix_fmt sin 10bit, ≤1080p

# Pistas de audio (debe existir una en español latino: TAG:language=spa y título "Latino"/"Español")
docker exec jellyfin /usr/lib/jellyfin-ffmpeg/ffprobe -hide_banner /data/movies/<película>/<archivo> \
  -show_entries stream=codec_type,codec_name:stream_tags=language,title -of default=noprint_wrappers=1
```
