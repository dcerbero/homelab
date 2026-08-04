# ⚡ Homelab

Infraestructura híbrida: servidor local (Raspberry Pi 4) + Oracle Cloud VM,
aprovisionada con Ansible y servicios Docker organizados por perfiles.

## Stack

| Componente | Tecnología |
|---|---|
| Servidores | Raspberry Pi 4 (Ubuntu 24.04) + Oracle Cloud VM |
| Orquestación | Ansible (8 roles, 2 plays) |
| Contenedores | Docker + Docker Compose (7 perfiles) |
| DNS | Pi-hole (activo + failover) |
| VPN | Tailscale |
| Proxy | nginx |
| Dashboard | Heimdall |
| Streaming | Jellyfin |
| Descargas | Sonarr + Prowlarr + Transmission |
| IA | OpenClaw → OpenRouter API |
| Monitorización | cAdvisor |

## Documentación

Toda la documentación está en [`docs/`](docs/README.md):

| Archivo | Contenido |
|---|---|
| [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) | Topología de red, flujos, puertos |
| [`docs/SETUP.md`](docs/SETUP.md) | Configuración inicial de la Raspberry Pi |
| [`docs/ANSIBLE.md`](docs/ANSIBLE.md) | Roles de Ansible, playbook, variables |
| [`docs/DOCKER.md`](docs/DOCKER.md) | Servicios Docker, perfiles, backup, actualización |
| [`docs/COMMANDS.md`](docs/COMMANDS.md) | Comandos de uso diario, monitorización |
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

# Solo homeserver:
bash run.sh homeserver

# Solo Oracle (failover Pi-hole):
bash run.sh oracle

# 3. Desplegar servicios Docker
cd services/docker/

# Por perfil:
docker compose --profile dns up -d              # Pi-hole
docker compose --profile dashboard up -d        # Heimdall
docker compose --profile infra up -d            # nginx
docker compose --profile ia up -d               # OpenClaw
docker compose --profile monitoring up -d       # cAdvisor
docker compose --profile media-streaming up -d  # Jellyfin
docker compose --profile media-download up -d   # Sonarr / Prowlarr / Transmission
```

## Recursos adicionales

- [`CHANGELOG.md`](CHANGELOG.md) — Historial de cambios del proyecto
- [`CLAUDE.md`](CLAUDE.md) — Guía de desarrollo para asistentes IA
