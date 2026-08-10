# 📚 Documentación del Homelab

Índice central de toda la documentación del proyecto.

## Stack

| Componente | Tecnología |
|---|---|
| Servidor | yoda — Raspberry Pi 4 (Ubuntu 24.04) + anton — Equipo x86_64 (pendiente provisionar) |
| Nube | talos — Oracle Cloud VM (failover DNS) |
| Orquestación | Ansible |
| Contenedores | Docker + Docker Compose |
| DNS | Pi-hole |
| VPN | Tailscale |
| Proxy | nginx |
| Dashboard | Heimdall |
| Streaming | Jellyfin |
| Descargas | Sonarr + Prowlarr + Transmission |
| IA | OpenClaw → OpenRouter API |
| Monitorización | Prometheus + Grafana + cAdvisor + node-exporter |

## Documentación

| Archivo | Contenido |
|---|---|
| [`ARCHITECTURE.md`](ARCHITECTURE.md) | Topología de red, flujos, diagrama de infraestructura |
| [`HARDWARE.md`](HARDWARE.md) | Inventario de hardware y puntuación por máquina |
| [`SETUP.md`](SETUP.md) | Configuración inicial de la Raspberry Pi |
| [`ANSIBLE.md`](ANSIBLE.md) | Roles de Ansible, playbook, variables de entorno |
| [`DOCKER.md`](DOCKER.md) | Servicios Docker Compose, perfiles, volúmenes, backup, actualización |
| [`COMMANDS.md`](COMMANDS.md) | Comandos de uso diario, monitorización, health checks |
| [`MONITORING.md`](MONITORING.md) | Stack de métricas (Prometheus/Grafana), estado y pendientes |
| [`TROUBLESHOOTING.md`](TROUBLESHOOTING.md) | Problemas comunes y soluciones |
| [`SECURITY.md`](SECURITY.md) | Hardening SSH, Tailscale ACLs, firewall |
