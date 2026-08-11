# 📚 Documentación del Homelab

Todo lo que necesitas saber sobre nuestro homelab, organizado por tema. Este es el punto de partida para entender qué tenemos, cómo se montó y cómo se mantiene día a día.

## Stack

| Componente | Tecnología |
|---|---|
| Servidor | [yoda](HARDWARE.md#yoda) — Raspberry Pi 4 (Ubuntu 24.04) + [anton](HARDWARE.md#anton) — Equipo x86_64 (servidor media) |
| Nube | [talos](HARDWARE.md#talos) — Oracle Cloud VM (failover DNS) |
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
| [`SETUP.md`](SETUP.md) | Configuración inicial de las máquinas (RPi y discos RAID1 de anton) |
| [`ANSIBLE.md`](ANSIBLE.md) | Roles de Ansible, playbook, variables de entorno |
| [`DOCKER.md`](DOCKER.md) | Servicios Docker Compose, perfiles, volúmenes, backup, actualización |
| [`media/`](media/README.md) | Stack media (Jellyfin, Sonarr, Prowlarr, Transmission) — ver [`JELLYFIN.md`](media/JELLYFIN.md) |
| [`COMMANDS.md`](COMMANDS.md) | Comandos de uso diario, monitorización, health checks |
| [`MONITORING.md`](MONITORING.md) | Stack de métricas (Prometheus/Grafana), estado y pendientes |
| [`TROUBLESHOOTING.md`](TROUBLESHOOTING.md) | Problemas comunes y soluciones |
| [`SECURITY.md`](SECURITY.md) | Hardening SSH, Tailscale ACLs, firewall |
