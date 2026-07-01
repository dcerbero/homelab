# Changelog

Todos los cambios relevantes de este proyecto se documentan en este archivo.

El formato está basado en [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [Sin publicar]

### Agregado
- Automatización con Ansible con 7 roles (system-setup, docker, pihole, tailscale, cadvisor, openclaw, headroom)
- Proxy reverso nginx para servicios web (Heimdall, OpenClaw)
- Perfiles de Docker Compose: dns, dashboard, ia, infra, media-streaming, media-download, monitoring
- Headroom: proxy de compresión de contexto para LLMs (0.27.0-code-slim, perfil ia)
- Healthcheck de Pi-hole y persistencia del volumen dnsmasq
- Rol Ansible para crear directorio de datos de Headroom
- Configuración de DNS explícita para evitar bucles de bootstrap
- Diagrama de arquitectura completo con mermaid

### Modificado
- OpenClaw: detrás de nginx proxy (puerto 18789 ya no expuesto directamente)
- OpenClaw: inferencia via Headroom proxy → DeepSeek API (compresión de contexto)
- Jellyfin: de network host a port mapping 8096:8096
- nginx config movido a $PATH_DATA/compose/homelab/config/nginx/conf.d/
- Actualización de imagen pihole a 2026.02.0 (LTS estable)
- Refactorización playbook.yaml → playbook.yml
- Mejora del .gitignore

### Seguridad
- Eliminada exposición directa del puerto 18789 de OpenClaw
- Jellyfin sin privileged + host network
- Se agregaron `.env`, `*.ini`, `.claude/` al .gitignore
- Se sanitizó documentación (IPs y usuarios hardcodeados eliminados)
- Se habilitó Tailscale para acceso remoto seguro
