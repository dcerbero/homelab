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

> **H.264 estricto + español latino.** La iGPU de anton (Intel HD 2500, gen7) solo hace H.264. El audio debe ser **español latino** — si el título dice `latino`, `español latino`, `es-lat` o `doblaje`, se prefiere por +200 puntos sin importar el resto.

Reglas derivadas (en orden):
1. Si un archivo no lo reproduce el dispositivo **directo**, Jellyfin tiene que transcodificarlo → y anton solo transcodifica bien H.264.
2. El stack debe **bajar H.264 1080p SDR** y rechazar el resto.
3. **Audio: español latino (+200).** Sin más reglas — si existe release con marcador latino/español, se agarra.

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
| Audio | AAC, AC3, EAC3 (o el original) · **preferir dual ES-LAT + EN** | TrueHD, DTS-HD MA, Atmos | passthrough problemático en muchos clientes y sin beneficio en esta casa. Audio preferido: español latino → inglés |
| Subtítulos | texto embebido (SRT/ASS) | solo PGS/VobSub | los de imagen se queman por CPU en un transcode |

## Configuración en Sonarr

Sonarr v4 (4.0.19 desplegado) soporta **Custom Formats** de forma nativa. Estrategia de scoring:

**Custom formats a crear** (Settings → Custom Formats):

| Custom format | Condición | Score |
|---|---|---|
| `x264` | `Release Title` contiene `x264` | +100 |
| `x265` | `Release Title` contiene `x265` / códec `HEVC` | −100 |
| `10bit` | `Release Title` contiene `10bit` | −100 |
| `HDR` | `Release Title` contiene `HDR|HDR10|DV|Dolby` | −50 |
| `4K` | Resolución ≥ 2160p | −100 |
| `Remux` | `Release Title` contiene `Remux` | −25 (peso/espacio) |
| `Español (Latino) Audio` | `Release Title` contiene `latino\|español latino\|es-lat\|doblaje` | **+200** |

**En el Quality Profile** (serie → Perfil de calidad): asigna los scores de los custom formats. Un release x264 1080p suma, uno x265 pierde → Sonarr elige automáticamente el H.264 cuando hay opciones, y solo cae al x265 si no hay alternativa (score positivo neto mínimo). Con esto el límite del perfil (p. ej. `1080p`) se mantiene, pero el códec se decide por score.

**Requisitos del perfil (verificados en vivo):**
- **`language: Any`** en Radarr — sin esto, exige el idioma original y rechaza los dubs.
- **Calidades ≤1080p permitidas:** SDTV, DVD, Bluray-480p+, HDTV-720p/1080p, WEB/WEBRip/WEB-DL 720p/1080p, Bluray-1080p, Remux-1080p. **No permitidas:** CAM, TS, TELESYNC, DVD-R, BR-DISK, 4K/2160p (calidades basura o fuera del límite de hardware).

> [!TIP]
> No hace falta borrar releases x265: basta el scoring negativo. Si en algún momento solo existe un release HEVC, Sonarr lo puede tomar igual (si su score neto sigue siendo aceptable) y queda documentado que será solo direct-play.

## Radarr

La estrategia de custom formats y scores de la sección anterior **ya está aplicada** (2026-08): perfil "Homelab 1080p (H.264)" en ambas apps con `Español (Latino) Audio` (+200) como **única regla de audio**. `language: Any`, sin calidades basura (CAM/TS/DVD-R), sin CFs de idioma adicionales. En Sonarr, el language profile "Español (Latino) + English" filtra por idioma.

## Prowlarr y Transmission

- **Prowlarr**: sin impacto de formato — solo agrega indexadores para Sonarr. Nada que configurar aquí.
- **Transmission**: sin impacto de formato — solo descarga. Nota: los archivos llegan a `/downloads` y Sonarr los mueve a `tvseries`; la extensión `.part` durante la descarga no afecta al escaneo de Jellyfin porque Jellyfin solo mira `movies/` y `tvseries/`.

## Tradeoff: H.264 vs espacio

H.264 1080p ocupa **~2-3x** más que HEVC 1080p a calidad comparable. El RAID1 es de 916GB con discos de 2009 — el espacio es un recurso real.

**Decisión (2026-08):** compatibilidad total de transcode > espacio. Se penaliza HEVC.

**Vía de escape si el disco aprieta:** relajar a "HEVC tolerado" (score −25 en vez de −100) y garantizar que los clientes de la casa reproduzcan HEVC directo (la mayoría de TVs modernas lo hacen). El transcode de esos archivos seguirá siendo imposible en anton, pero se verían directo. No cambiar la config de Jellyfin, solo la del arr.

## Verificación

Tras configurar Sonarr, comprobar que lo que baja es H.264:

```bash
# En anton, sobre un archivo recién importado
docker exec jellyfin /usr/lib/jellyfin-ffmpeg/ffprobe -hide_banner /data/tvshows/<serie>/<archivo> \
  -show_entries stream=codec_name,profile,width,height,pix_fmt -of compact
# Esperado: codec_name=h264, pix_fmt sin 10bit, ≤1080p
```
