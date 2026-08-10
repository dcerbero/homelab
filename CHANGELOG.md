# Changelog

Todos los cambios relevantes de este proyecto se documentan en este archivo.

El formato está basado en [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [2026.08.6] - 2026-08-10

### Cambiado
- Renombrado completo de máquinas: `homeserver` (RPi) → `yoda`, `oracle` (VM OCI) → `talos`, `media` (x86_64) → `anton`. Afecta inventario Ansible (`inventory/{yoda,talos}.yml`), `host_vars/`, `playbook.yml` (plays y tags), `TAILSCALE_HOSTNAME` (MagicDNS: `yoda`, `talos`), targets y labels `instance` de `prometheus.yml`, tiles y categorías de Heimdall (`tiles.json`, `seed_tiles.py`) y toda la documentación.
- `tiles.json`: corregido el hostname obsoleto `ollama-server-2` (apuntaba a la VM OCI con un MagicDNS antiguo) → `talos`.
- Eliminado el término "homeserver" como descriptor de la Pi (`README.md`, `docs/HARDWARE.md`): ahora son 2 equipos locales (yoda + anton) + VM OCI (talos).

## [2026.08.5] - 2026-08-10

### Documentación
- Parque de 3 equipos reflejado en toda la documentación: Raspberry Pi 4 (local) + Oracle Cloud VM (Pi-hole failover) + Equipo x86_64 (pendiente de provisionar).
- Renombrado del alias de máquina `media` → `anton` (referencia al servidor de Gilfoyle en Silicon Valley) en `docs/HARDWARE.md`, `docs/ARCHITECTURE.md`, `README.md` raíz y `docs/ANSIBLE.md`. El término "PC antiguo" se sustituye por "Equipo x86_64".

## [2026.08.4] - 2026-08-09

### Agregado
- Nueva máquina: Equipo x86_64, Intel i5-3470S (4c/4t), 7.7 GiB RAM, 3×1TB (sda OS; sdb/sdc datos sin configurar), Intel HD 2500 (QSV H.264). Pendiente de provisionar.
- `docs/HARDWARE.md`: inventario del hardware (media, pi, oracle) con puntuación 0-10 por componente y promedios.

### Documentación
- `README.md` raíz y `docs/README.md`: incluida la máquina media.

## [2026.08.3] - 2026-08-09

### Agregado
- Rol Ansible `preflight`: verifica antes de desplegar que todos los tags de `image:` en los `compose.yaml` existen en su registry (y en homeserver, que tengan variante `arm64`), usando `docker manifest inspect` en paralelo. Evita que un tag inexistente falle el `compose up` a mitad del play (caso nginx 1.30.3). Solo valida existencia en oracle vía `preflight_require_arch`
- El rol `preflight` hereda la unión de las tags de los roles de servicio que despliegan compose, de modo que también se ejecuta en runs etiquetados (`--tags pihole,dns`, `--tags ia`, etc.) y se salta en los que no tocan compose (`--tags system-setup`, `--tags docker`, `--tags tailscale`). Convención de mantenimiento documentada en `CLAUDE.md` y `docs/ANSIBLE.md`
- `.gitignore`: `__pycache__/`

### Corregido
- `preflight`: clasifica los fallos de `docker manifest inspect` en `tag inexistente` / `rate limit del registry` / `verificación no concluyente`, y reintenta solo errores transitorios de red (timeout/EOF), no los 429. Un rate limit de Docker Hub ya no se reporta como "tag inexistente" (era un falso positivo que abortaba el deploy)
- `preflight`: `ansible_machine` → `ansible_facts['machine']` (evita el deprecation warning de `INJECT_FACTS_AS_VARS`, eliminado en ansible-core 2.24)

## [2026.08.2] - 2026-08-05

### Corregido
- Imagen de nginx `1.30.3-bookworm` no existía en Docker Hub → `1.29.1-bookworm` (el `compose up` fallaba al hacer pull y el contenedor quedaba stale)
- Rol `nginx`: `set -e` para que un fallo de `compose up` falle la task en vez de reportar `ok` silenciosamente (antes el `docker exec ... || true` enmascaraba el error)

## [2026.08.1] - 2026-08-05

### Cambiado
- `PATH_DATA` del homeserver definido: `pendiente/rutanueva` → `/server`. El SSD USB es el disco de arranque de la Pi (no hay disco de datos separado), así que los datos viven en el root del sistema
- Ansible garantiza la creación y ownership de los directorios de datos: `system-setup` crea el esqueleto `$PATH_DATA/persistence` + `$PATH_DATA/media/{downloads,movies,tvseries,watch}`, y el rol `pihole` asegura sus propios dirs
- Ownership determinista `1000:1000` (uid de usuario mapeado por las imágenes linuxserver.io vía `PUID`/`PGID`), sin depender del auto-create de Docker

### Verificado
- Oracle ya migrado: Pi-hole usa `/server/persistence/pihole` (sin acciones pendientes)

### Documentación
- `SETUP.md`: sección "Montar Disco Duro" reemplazada por "Datos Persistentes (`PATH_DATA`)"
- `DOCKER.md`: convención de ownership de directorios de datos documentada
- `run.sh` ahora usa `--ask-become-pass` (pide la contraseña de sudo una vez por pasada)

## [2026.08.0] - 2026-08-05

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

### Eliminado
- Headroom: removido del perfil `ia`. Eliminado rol Ansible, compose file, y referencia en include. El proxy de compresión no aportaba beneficio real.
- Heartbeat: eliminado del perfil `ia` de OpenClaw. Removido `heartbeat: { every: "6h" }` del gateway config. HEARTBEAT.md y secciones de AGENTS.md eliminados del workspace.

### Limpieza
- Consolidada la documentación: `docs/ANSIBLE.md` y `docs/DOCKER.md` como única fuente de verdad; `ansible/README.md` y `services/docker/README.md` quedan como índices cortos
- Corregido el flujo de actualización de servicios (ahora usa `docker compose --all-profiles`) — con todos los servicios tras profiles, el `up -d` sin flags no arrancaba nada
- Eliminado `sonarr/config/noTranscoding.json` (no estaba montado en ningún compose)
- Alineado el rol `cadvisor` con el resto de roles: pasa `PATH_DATA` y `--remove-orphans`
- Corregido `changed_when` del rol `pihole` para detectar contenedores recién creados
- Quitado el `-v` hardcodeado de `run.sh` (verbose opcional por CLI: `bash run.sh homeserver -v`)
- Borradas 5 ramas locales ya fusionadas (add/scripts, dcerbero-patch-1, fix/heimdall-pathdata, fix/heimdall-root-location, fix/plugin)

### Seguridad
- Eliminada exposición directa del puerto 18789 de OpenClaw
- Jellyfin sin privileged + host network
- Se agregaron `.env`, `*.ini`, `.claude/` al .gitignore
- Se sanitizó documentación (IPs y usuarios hardcodeados eliminados)
- Se habilitó Tailscale para acceso remoto seguro
