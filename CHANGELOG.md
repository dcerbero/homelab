# Changelog

Todos los cambios relevantes de este proyecto se documentan en este archivo.

El formato está basado en [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [Sin publicar]

### Agregado
- Automatización con Ansible con 4 roles (system-setup, docker, pihole, tailscale)
- Rol de Tailscale VPN para acceso remoto seguro
- Script de ejecución de Ansible para aprovisionamiento simplificado
- Documentación del README de Ansible
- Perfiles de Docker Compose para despliegues modulares (dns, dashboard, media-download, media-streaming, infra)
- Healthcheck de Pi-hole y persistencia del volumen dnsmasq
- Configuración de DNS explícita para evitar bucles de bootstrap

### Modificado
- Actualización de la imagen de pihole a 2026.02.0 (LTS estable)
- Refactorización de playbook.yaml → playbook.yml (convención de nombres)
- Mejora del .gitignore (se eliminó redundancia, mejor cobertura)
- Documentación simplificada en español latinoamericano
- Diagrama de arquitectura actualizado para incluir Tailscale VPN

### Seguridad
- Se agregaron `.env` y `*.ini` al .gitignore
- Se agregó `.claude/` al .gitignore
- Se eliminaron recursos binarios del repositorio (installDocker.png)
- Se sanitizó la documentación (se eliminaron IPs y usuarios hardcodeados)
- Se habilitó Tailscale para acceso remoto seguro
