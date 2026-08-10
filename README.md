# ⚡ Homelab

Infraestructura híbrida: 2 equipos locales (Raspberry Pi 4 yoda + Equipo x86_64 anton, pendiente de provisionar) + Oracle Cloud VM talos,
aprovisionada con Ansible y servicios Docker organizados por perfiles.

## Stack

| Componente | Tecnología |
|---|---|
| Servidores | Raspberry Pi 4 + Oracle Cloud VM + Equipo x86_64 |
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

# Solo talos (failover Pi-hole):
bash run.sh talos
```

## Recursos adicionales

- [`CHANGELOG.md`](CHANGELOG.md) — Historial de cambios del proyecto
- [`CLAUDE.md`](CLAUDE.md) — Guía de desarrollo para asistentes IA
