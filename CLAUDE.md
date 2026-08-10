# CLAUDE.md

Guía de trabajo para asistentes IA en este repositorio. El detalle completo vive en `docs/` (`docs/README.md` es el índice).

## Resumen

Infraestructura híbrida: Raspberry Pi 4 (local) + Oracle Cloud VM (Pi-hole failover) + máquina media x86_64 (pendiente de provisionar), aprovisionada con Ansible y servicios Docker organizados por perfiles.

Dos subsistemas, cada uno con su ciclo de vida:

1. **Provisión Ansible** (`ansible/`) — setup bare-metal de Ubuntu, Docker, Tailscale y despliegue inicial de servicios
2. **Perfiles Docker Compose** (`services/docker/`) — gestión del día a día

## Arquitectura

```
homelab/
├── ansible/          # playbook.yml (2 plays), run.sh, inventory/ (host_vars), 8 roles
├── services/docker/  # compose.yaml + compose.yaml por servicio (perfiles: dns, dashboard, infra, ia, monitoring, media-streaming, media-download)
├── config/           # scripts auxiliares
└── docs/             # documentación detallada (índice en docs/README.md)
```

### Detalles clave

- **nginx es la única entrada web** — reverse-proxy a Heimdall, OpenClaw, Pi-hole y cAdvisor. Sin puertos expuestos a WAN; solo LAN o Tailscale.
- **OpenClaw → OpenRouter API** (inferencia). Solo puerto interno, detrás de nginx.
- **Config en el repo, datos en `$PATH_DATA`** — las configs versionadas viven en el repo (un `git pull` las restablece; montajes `:ro`); el estado runtime vive en `$PATH_DATA` con dos tiers: `persistence/<svc>/` (estado durable) y `media/` (biblioteca compartida). La ruta se define por máquina en `host_vars/<host>.yml`.
- **Pi-hole failover** — Pi-hole secundario en Oracle Cloud. Mismas adlists, gravity independiente, sin sync. Tailscale DNS con ambos nameservers.
- **Puerto 53** — `system-setup` desactiva el stub de systemd-resolved para liberarlo para Pi-hole.

## Principios de Ingeniería

- **REGLA NO NEGOCIABLE: NUNCA SUPONGAS** — el modelo y el agente en ningún caso deben suponer datos no verificados: arquitectura o specs de máquinas, versiones de imágenes, rutas, puertos, estados del sistema o intenciones del usuario. Toda afirmación o implementación debe basarse en algo verificado (archivos del repo, comandos read-only, preguntar al usuario). Una suposición no confirmada se trata como un bug en potencial.
- **NUNCA SEAS COMPLACIENTE** — cuestiona requisitos malos, no hagas código inseguro ni uses prácticas obsoletas, y no evites decir "esto está mal".
- **ENSEÑA, NO SOLO RECOMIENDES** — explica fundamentos y alternativas, hazme pensar, y si me equivoco dame una lección en una línea.
- **ESCALERA DE EFICIENCIA (Ponytail Principle)** — antes de escribir código, en orden: YAGNI → ya existe en el codebase → stdlib → feature nativa de la plataforma → dependencia ya instalada → una línea → el mínimo que funcione. Perezoso, no negligente: validación, seguridad y errores nunca se recortan.
- **STANDARDS** — seguridad primero, best practices obligatorias, sin atajos, documenta lo hecho.

## Operaciones Comunes

```bash
# Provisionar / reprovisionar
cd ansible/
cp .env.example .env     # editar con secretos
bash run.sh              # todas las máquinas
bash run.sh homeserver   # solo RPi
bash run.sh oracle       # solo Oracle (failover Pi-hole)
bash run.sh homeserver --tags pihole,dns   # por rol
```

- Los servicios se despliegan vía **Ansible**, no con `docker compose` manual. La gestión manual (estado, logs, actualización) y los health checks están en `docs/DOCKER.md` y `docs/COMMANDS.md`.
- **Backup**: `tar -czf backup-homelab-$(date +%Y%m%d).tar.gz -C $(dirname $PATH_DATA) $(basename $PATH_DATA)`

## Convenciones

- **Ansible**: todos los roles corren con `become: true`. Orden estricto en homeserver: `system-setup → docker → preflight → pihole → tailscale → cadvisor → openclaw → heimdall → nginx`. El play oracle solo ejecuta `system-setup → docker → preflight → pihole → monitoring`.
- **Preflight**: el rol `preflight` (validación de tags de imágenes antes de desplegar) declara como tags propias la unión de las tags de todos los roles de servicio que despliegan compose. Al añadir un rol de servicio nuevo, añade sus tags a la lista de tags del rol `preflight` en `playbook.yml` (ambos plays), o un `--tags <nuevo>` se saltaría la validación en silencio.
- **Inventario**: `ansible/inventory/{homeserver,oracle}.yml` definen los hosts; `host_vars/` las variables por máquina (`PATH_DATA`, `TAILSCALE_HOSTNAME`). Conexión vía `~/.ssh/config`, sin credenciales en el repo.
- **Nombres de servicios Compose**: prefijo `svc` (p. ej. `svcPihole`), excepto `openclaw` (compatibilidad con `proxy_pass` de nginx).
- **UID/GID 1000** para contenedores linuxserver.io.
- **Transcodificación HW** en Pi 4: `/dev/dri/renderD128` (solo Jellyfin).
- **Secretos** (`TAILSCALE_AUTH_KEY`, `PIHOLE_PASS`) en `ansible/.env` — gitignored.
- **Prefijos de PR**: `feat/`, `fix/`, `refactor/`, `docs/`.
