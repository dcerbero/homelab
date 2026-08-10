# 🖥️ Hardware del Laboratorio

Cada máquina de esta casa tiene un nombre, un papel y una historia. Aquí está el inventario de las tres —dos equipos físicos y una VM en la nube— con una puntuación de aptitud que no mira para qué se usa cada una, sino cuánto puede dar de sí.

## Índice

- [Especificaciones](#especificaciones)
- [Origen de los nombres](#origen-de-los-nombres)
- [Rúbrica de puntuación (agnóstica al rol)](#rúbrica-de-puntuación-agnóstica-al-rol)
- [Puntuaciones (0–10)](#puntuaciones-010)
- [Promedios](#promedios)

## Especificaciones

| Máquina | Alias SSH | SO | Arquitectura | CPU | RAM | Almacenamiento | GPU / transcode | Consumo energético | Rol |
|---|---|---|---|---|---|---|---|---|---|
| [**anton**](#anton) | `anton` | Ubuntu 24.04.4 LTS | x86_64 | Intel Core i5-3470S (4c/4t @ 2.9GHz, Ivy Bridge) | 7.7 GiB + 4 GiB swap | sda Seagate ST1000LM035 (OS+Docker, **descartable**) · **sdb+sdc WD10EADS-00P → RAID1** (mdadm, 916G, `/server` = persistence+media) | Intel HD 2500 (`/dev/dri/renderD128`) — QSV H.264, sin HEVC | ~30–40W *(estimado)* | Servidor media (Jellyfin + arr stack) |
| [**yoda**](#yoda) | `yoda` | Ubuntu 24.04.4 LTS | aarch64 | Raspberry Pi 4 Model B Rev 1.2 (BCM2711 Cortex-A72, 4c) | 3.7 GiB (4GB, parte reservada a GPU) | KINGSTON SA400S37240G 240GB SSD | VideoCore VI (Broadcom) — sin QSV | ~3–7W (documentado) | Pi-hole, Heimdall, nginx, OpenClaw, cAdvisor, media (hoy) |
| [**talos**](#talos) | `talos` | Ubuntu 24.04.4 LTS | aarch64 | Ampere A1 Flex (ARM Neoverse-N1, 4c) | 23 GiB | BlockVolume OCI 150G | n/a (cloud) | n/a (nube, 0W local) | VM OCI: Pi-hole failover + monitoreo (Prometheus, Grafana) |

## Origen de los nombres

Ponerle nombre a las máquinas no es un capricho: es la forma de que cada una tenga identidad propia y de saber de qué hablamos cuando se cae una. Todos son homenajes a historias que ya existían.

### anton
Equipo x86_64 destinado a media. Es el servidor armado de Gilfoyle en *Silicon Valley*: un PC veterano que rescaté de la jubilación y que pronto se encargará de la biblioteca media de la casa. Como el original, lo nuestro es armarlo pieza a pieza.

### yoda
Raspberry Pi 4. El maestro Jedi pequeño, sabio y veterano que guía a todos sin moverse de su sitio: así es la Pi, el corazón del homelab que da DNS a toda la red (Pi-hole) y mantiene los servicios esenciales siempre encendidos.

### talos
Oracle Cloud VM. En la mitología griega, el autómata de bronce que patrullaba las costas de Creta sin descanso, vigilando que nada se le escapara. Igual que él, esta VM monitorea toda la infraestructura y cubre las espaldas con el failover de Pi-hole.

## Rúbrica de puntuación (agnóstica al rol)

Puntajes de aptitud de hardware pura (capacidad y eficiencia), sin considerar para qué se usa cada máquina. Escala 0–10.

| Componente | Criterio | Referencias |
|---|---|---|
| **CPU** | Cómputo absoluto (generación, núcleos, IPC) | i5-3470S ≈ 6 · Cortex-A72 ≈ 4 · Neoverse-N1 ≈ 7 |
| **RAM** | Capacidad | 3.7 GiB→3 · 8 GiB→5 · 24 GiB→8 |
| **Almacenamiento** | Capacidad + tipo (SSD/HDD) + antigüedad | 3TB HDD viejos→5 · 240GB SSD→4 · 150G block→3 |
| **GPU / transcode** | Capacidad de decode/transcode HW | HD 2500 (H.264)→4 · VideoCore VI→2 · ninguna→0 |
| **Red** | Velocidad de conexión | Gigabit LAN→7 · nube pública→6 |
| **Energía** | Eficiencia (menor consumo = mayor puntaje) | <5W→10 · 5-20W→7-9 · 20-60W→4-6 · >60W→0-3 · nube (0W local)→10 |

## Puntuaciones (0–10)

| Componente | [anton](#anton) | [yoda](#yoda) | [talos](#talos) |
|---|---|---|---|
| CPU | 6 | 4 | 7 |
| RAM | 5 | 3 | 8 |
| Almacenamiento | 5 | 4 | 3 |
| GPU / transcode | 4 | 2 | 0 |
| Red | 7 | 7 | 6 |
| Energía | 5 | 10 | 10 |

## Promedios

| Máquina | Promedio |
|---|---|
| [talos](#talos) | 5.7 |
| [anton](#anton) | 5.3 |
| [yoda](#yoda) | 5.0 |

> [!NOTE]
> Datos verificados por SSH (2026-08-09). Puntajes subjetivos basados en la rúbrica anterior. [`anton`](#anton) es el alias SSH de un Equipo x86_64 destinado a media; el RAID1 de sus discos de datos (`/server`) se configuró el 2026-08-10 (ver [`SETUP.md`](SETUP.md#5-discos-de-anton--raid1-media)).
