# 📚 Documentación del Homelab

Índice central de toda la documentación del proyecto.

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
| IA Local | OpenClaw |
| Monitorización | cAdvisor |

## Documentación

| Archivo | Contenido |
|---|---|
| [`ARCHITECTURE.md`](ARCHITECTURE.md) | Topología de red, flujos, diagrama de infraestructura |
| [`SETUP.md`](SETUP.md) | Configuración inicial de la Raspberry Pi |
| [`ANSIBLE.md`](ANSIBLE.md) | Roles de Ansible, playbook, variables de entorno |
| [`DOCKER.md`](DOCKER.md) | Servicios Docker Compose, perfiles, volúmenes, backup, actualización |
| [`COMMANDS.md`](COMMANDS.md) | Comandos de uso diario, monitorización, health checks |
| [`TROUBLESHOOTING.md`](TROUBLESHOOTING.md) | Problemas comunes y soluciones |
| [`SECURITY.md`](SECURITY.md) | Hardening SSH, Tailscale ACLs, firewall |
