# ⚡ Homelab

Bienvenido a mi pequeña red doméstica: dos equipos locales que trabajan en casa y una VM en la nube que vigila las espaldas, todo aprovisionado con Ansible y desplegado en contenedores Docker.

Nuestras tres máquinas tienen nombre y apellido —Raspberry Pi 4 [yoda](docs/HARDWARE.md#yoda), Equipo x86_64 [anton](docs/HARDWARE.md#anton) (pendiente de provisionar) y Oracle Cloud VM [talos](docs/HARDWARE.md#talos)—, cada una con su historia ([origen de los nombres](docs/HARDWARE.md#origen-de-los-nombres)).

## Índice

- [Stack](#stack)
- [Documentación](#documentación)
- [Inicio Rápido](#inicio-rápido)
- [Recursos adicionales](#recursos-adicionales)

## Stack

| Componente | Tecnología |
|---|---|
| Servidores | [yoda](docs/HARDWARE.md#yoda) (Raspberry Pi 4) + [talos](docs/HARDWARE.md#talos) (Oracle Cloud VM) + [anton](docs/HARDWARE.md#anton) (Equipo x86_64) |
| Orquestación | Ansible (10 roles, 2 plays) |
| Contenedores | Docker + Docker Compose (8 perfiles) |
| DNS | Pi-hole (activo + failover) |
| VPN | Tailscale |
| Proxy | nginx |
| Dashboard | Heimdall |
| Streaming | Jellyfin |
| Descargas | Sonarr + Prowlarr + Transmission |
| IA | OpenClaw → OpenRouter API |
| Monitorización | Prometheus + Grafana + cAdvisor + node-exporter |

## Documentación

Toda la documentación está en [`docs/`](docs/README.md):

| Archivo | Contenido |
|---|---|
| [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) | Topología de red, flujos, puertos |
| [`docs/HARDWARE.md`](docs/HARDWARE.md) | Inventario de hardware y puntuación por máquina |
| [`docs/SETUP.md`](docs/SETUP.md) | Configuración inicial de la Raspberry Pi |
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
> Si solo tienes encendida la Raspberry, `bash run.sh yoda` es suficiente —talos se aprovisiona aparte y anton aún no está listo.

## Recursos adicionales

- [`CHANGELOG.md`](CHANGELOG.md) — Historial de cambios del proyecto
- [`CLAUDE.md`](CLAUDE.md) — Guía de desarrollo para asistentes IA
