# Changelog

Todos los cambios relevantes de este proyecto se documentan en este archivo.

El formato está basado en [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [Sin publicar]

### Eliminado
- Headroom: removido del perfil `ia`. Eliminado rol Ansible, compose file, y referencia en include. El proxy de compresión no aportaba beneficio real.
- Heartbeat: eliminado del perfil `ia` de OpenClaw. Removido `heartbeat: { every: "6h" }` del gateway config. HEARTBEAT.md y secciones de AGENTS.md eliminados del workspace.

### Agregado
- Automatización con Ansible con 8 roles (system-setup, docker, pihole, tailscale, cadvisor, openclaw, heimdall, nginx)
- Proxy reverso nginx para servicios web (Heimdall, OpenClaw)
- Perfiles de Docker Compose: dns, dashboard, ia, infra, media-streaming, media-download, monitoring
- Healthcheck de Pi-hole y persistencia del volumen dnsmasq
- Configuración de DNS explícita para evitar bucles de bootstrap
- Diagrama de arquitectura completo con mermaid

### Modificado
- Refactor de rutas: servicios organizados por carpeta (`services/docker/<svc>/compose.yaml`), configs versionadas en el repo (carpeta `config/`, montajes `:ro`), datos en `$PATH_DATA` con tiers `persistence/` (estado durable) + `media/` (biblioteca compartida)
- nginx: config montada desde el repo (`./config/conf.d`) en vez de `$PATH_DATA/homelab/config/nginx/conf.d`
- OpenClaw: detrás de nginx proxy (puerto 18789 ya no expuesto directamente)
- OpenClaw: inferencia via OpenRouter API
- Jellyfin: de network host a port mapping 8096:8096
- Actualización de imagen pihole a 2026.02.0 (LTS estable)
- Refactorización playbook.yaml → playbook.yml
- Mejora del .gitignore

### Pendiente
- **Migración de datos en hosts** antes del próximo provisioning: mover estado a `$PATH_DATA/persistence/<svc>/`. Oracle: `PATH_DATA` ya renombrado, migrar data de pihole a `$PATH_DATA/persistence/pihole`. Homeserver: definir `PATH_DATA` real (hoy placeholder).

### Seguridad
- Eliminada exposición directa del puerto 18789 de OpenClaw
- Jellyfin sin privileged + host network
- Se agregaron `.env`, `*.ini`, `.claude/` al .gitignore
- Se sanitizó documentación (IPs y usuarios hardcodeados eliminados)
- Se habilitó Tailscale para acceso remoto seguro
