# ⚡ Homelab

Infraestructura híbrida: servidor local (Raspberry Pi 4) + recursos en la nube (Oracle Cloud).

## Stack

| Componente | Tecnología |
|---|---|
| Servidor | Raspberry Pi 4 — Ubuntu 24.04 |
| Orquestación | Ansible |
| Contenedores | Docker + Docker Compose |
| DNS | Pi-hole |
| VPN | Tailscale |
| Proxy | nginx |
| Dashboard | Heimdall |
| Streaming | Jellyfin |
| Descargas | Sonarr + Prowlarr + Transmission |
| IA Local | OpenClaw + Headroom (chat: DeepSeek API, compresión de contexto / embeddings: Ollama en Oracle Cloud) |
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
bash run.sh

# 3. Desplegar servicios Docker
cd services/docker/
docker compose --profile dns --profile dashboard --profile infra up -d
```
