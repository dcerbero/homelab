# ⚡ Homelab

[![Lint](https://img.shields.io/github/actions/workflow/status/dcerbero/homelab/lint.yml?branch=main&label=lint)](https://github.com/dcerbero/homelab/actions/workflows/lint.yml)
[![License](https://img.shields.io/github/license/dcerbero/homelab)](LICENSE)

Bienvenido a mi pequeña red doméstica: dos equipos locales que trabajan en casa y una VM en la nube que vigila las espaldas, todo aprovisionado con Ansible y desplegado en contenedores Docker.

Nuestras tres máquinas tienen nombre y apellido —Raspberry Pi 4 [yoda](docs/HARDWARE.md#yoda), Equipo x86_64 [anton](docs/HARDWARE.md#anton) (servidor media) y Oracle Cloud VM [talos](docs/HARDWARE.md#talos)—, cada una con su historia ([origen de los nombres](docs/HARDWARE.md#origen-de-los-nombres)).

## Índice

- [Stack](#stack)
- [Documentación](#documentación)
- [Inicio Rápido](#inicio-rápido)
- [Recursos adicionales](#recursos-adicionales)

## Stack

| Componente | Tecnología |
|---|---|
| Servidores | [yoda](docs/HARDWARE.md#yoda) (Raspberry Pi 4) + [talos](docs/HARDWARE.md#talos) (Oracle Cloud VM) + [anton](docs/HARDWARE.md#anton) (Equipo x86_64) |
| Orquestación | Ansible (13 roles, 3 plays) |
| Contenedores | Docker + Docker Compose (9 perfiles) |
| DNS | Pi-hole (activo + failover) |
| VPN | Tailscale |
| Proxy | nginx |
| Dashboard | Heimdall |
| Streaming | Jellyfin |
| Descargas | Sonarr + Radarr + Prowlarr + Transmission + Bazarr + Seerr |
| IA | OpenClaw → OpenRouter API |
| Monitorización | Prometheus + Grafana + cAdvisor + node-exporter + smartctl-exporter |

## Documentación

Toda la documentación está en [`docs/`](docs/README.md):

| Archivo | Contenido |
|---|---|
| [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) | Topología de red, flujos, puertos |
| [`docs/HARDWARE.md`](docs/HARDWARE.md) | Inventario de hardware y puntuación por máquina |
| [`docs/SETUP.md`](docs/SETUP.md) | Configuración inicial de las máquinas (RPi y discos RAID1 de anton) |
| [`docs/media/`](docs/media/README.md) | Stack media (Jellyfin, Sonarr, Prowlarr, Transmission) — config en [`JELLYFIN.md`](docs/media/JELLYFIN.md), formato de archivos en [`FORMATOS.md`](docs/media/FORMATOS.md) |
| [`docs/ANSIBLE.md`](docs/ANSIBLE.md) | Roles de Ansible, playbook, variables |
| [`docs/DOCKER.md`](docs/DOCKER.md) | Servicios Docker, perfiles, backup, actualización |
| [`docs/COMMANDS.md`](docs/COMMANDS.md) | Comandos de uso diario, monitorización |
| [`docs/MONITORING.md`](docs/MONITORING.md) | Stack de métricas (Prometheus/Grafana), estado |
| [`docs/TROUBLESHOOTING.md`](docs/TROUBLESHOOTING.md) | Problemas comunes y soluciones |
| [`docs/SECURITY.md`](docs/SECURITY.md) | Hardening SSH, Tailscale, firewall |

## Inicio Rápido

```bash
# 1. Setup inicial de la Raspberry (IP estática, disco, DNS)
#    Ver docs/SETUP.md

# 2. Aprovisionar con Ansible
cd ansible/
cp .env.example .env
# Editar .env con credenciales y rutas

# Todas las máquinas:
bash run.sh

# Solo yoda:
bash run.sh yoda

# Solo talos:
bash run.sh talos
```

> [!TIP]
> El despliegue es idempotente y el repo se sincroniza solo en cada pasada: `bash run.sh <máquina>` equivale a `--limit <máquina>`.

## Recursos adicionales

- [`CHANGELOG.md`](CHANGELOG.md) — Historial de cambios del proyecto
- [`AGENTS.md`](AGENTS.md) — Guía de desarrollo para asistentes IA
- [`LICENSE`](LICENSE) — Licencia MIT
