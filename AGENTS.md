# AGENTS.md

Guía de trabajo para asistentes IA. El detalle completo vive en `docs/` (`docs/README.md` es el índice).

## Reglas no negociables

- **NUNCA SUPONGAS** — ningún dato se da por válido sin verificarlo (archivos del repo, comandos read-only, preguntar al usuario): arquitectura, specs, versiones de imágenes, rutas, puertos, estados o intenciones. Una suposición no confirmada se trata como un bug en potencial.
- **NUNCA SEAS COMPLACIENTE** — cuestiona requisitos malos, no hagas código inseguro ni uses prácticas obsoletas, y no evites decir "esto está mal".
- **ENSEÑA, NO SOLO RECOMIENDES** — explica fundamentos y alternativas, hazme pensar, y si me equivoco dame una lección en una línea.
- **ESCALERA DE EFICIENCIA (Ponytail Principle)** — antes de escribir código, en orden: YAGNI → ya existe en el codebase → stdlib → feature nativa de la plataforma → dependencia ya instalada → una línea → el mínimo que funcione. Perezoso, no negligente: validación, seguridad y errores nunca se recortan.
- **STANDARDS** — seguridad primero, best practices obligatorias, sin atajos, documenta lo hecho.

## Contexto mínimo

Infraestructura híbrida con 3 máquinas aprovisionadas por Ansible y servicios Docker organizados por perfiles:

| Máquina | Rol | Arch |
|---|---|---|
| `yoda` | Raspberry Pi 4 (local): Pi-hole, Heimdall, nginx, OpenClaw, cAdvisor, media | arm64 |
| `talos` | Oracle Cloud VM: Pi-hole failover + monitoreo (Prometheus, Grafana) | arm64 |
| `anton` | Equipo x86_64 — pendiente de provisionar | amd64 |

Dos subsistemas con ciclo de vida propio:
1. **Provisión Ansible** (`ansible/`) — setup bare-metal, Docker, Tailscale y despliegue inicial (`playbook.yml` con 2 plays, `run.sh`, `inventory/`, 10 roles).
2. **Perfiles Docker Compose** (`services/docker/`) — gestión del día a día (`compose.yaml` + uno por servicio).

```text
homelab/
├── ansible/          # playbook.yml (2 plays), run.sh, inventory/ (host_vars), 10 roles
├── services/docker/  # compose.yaml + compose.yaml por servicio (8 perfiles)
├── config/           # scripts auxiliares
└── docs/             # documentación detallada (índice en docs/README.md)
```

## Cómo se despliega de verdad

`system-setup` clona el repo a `~/services/homelab` en cada host; cada rol de servicio ejecuta `docker compose --profile <p> up` sobre ese checkout. La fuente de verdad es el repo: un `git pull` en el host + `bash run.sh` restablece el estado.

## Servicios por perfil y rol

| Perfil | Servicios | Rol que despliega | Máquina |
|---|---|---|---|
| `dns` | Pi-hole | `pihole` | yoda + talos |
| `dashboard` | Heimdall | `heimdall` | yoda |
| `infra` | nginx | `nginx` | yoda |
| `ia` | OpenClaw (→ OpenRouter) | `openclaw` | yoda |
| `monitoring` | cAdvisor, node-exporter | `cadvisor` (yoda, anton), `monitoring` (talos) | yoda + talos + anton |
| `smart` | smartctl-exporter | `smartctl` | anton |
| `metrics` | Prometheus, Grafana | `monitoring` | talos |
| `media-streaming` | Jellyfin | `media` | anton |
| `media-download` | Transmission, Prowlarr, Sonarr | `media` | anton |

## Hechos clave

- **nginx es la única entrada HTTP** (puerto 80) — reverse-proxy a Heimdall (`/`), Pi-hole (`/pihole`, `/admin/`) y OpenClaw (`/openclaw`). El resto de servicios publica sus puertos solo a LAN/Tailscale (grafana 3000, jellyfin 8096, pihole-web 8085, prowlarr 8083, sonarr 8084, transmission 8082/51413, cadvisor 9101, node-exporter 9100).
- **OpenClaw → OpenRouter API** para inferencia; sin puertos expuestos, solo detrás de nginx.
- **Config en el repo, datos en `$PATH_DATA`** — configs versionadas con montajes `:ro` (nginx `conf.d`, grafana provisioning, prometheus config); estado runtime en `$PATH_DATA`: `persistence/<svc>/` (durable) y `media/` (`downloads`, `movies`, `tvseries`, `watch`). `PATH_DATA` se define por máquina en `host_vars/<host>.yml`.
- **Pi-hole failover** — secundario en talos. Mismas adlists y gravity independiente, sin sync (estado runtime, no versionado). Los nameservers de Tailscale DNS (MagicDNS) se configuran en la consola de Tailscale, no en el repo.
- **Puerto 53** — el rol `systemd-resolved` (yoda, talos) desactiva el stub de systemd-resolved (`DNSStubListener=no`); anton no lo incluye (no corre Pi-hole).

## Convenciones

- **Ansible**: roles con `become: true`. Orden estricto en [yoda](docs/HARDWARE.md#yoda): `system-setup → docker → preflight → systemd-resolved → pihole → tailscale → cadvisor → openclaw → heimdall → nginx`; en [talos](docs/HARDWARE.md#talos): `system-setup → docker → preflight → systemd-resolved → pihole → monitoring`; en [anton](docs/HARDWARE.md#anton): `system-setup → docker → preflight → cadvisor → smartctl → tailscale → media`.
- **Sync del repo**: cada play sincroniza `~/services/homelab` en sus `pre_tasks` (tags `always`) — el repo del host == `origin/main` antes de cualquier deploy, incluso con `--tags <rol>`. `system-setup` ya no lo hace.
- **Preflight**: valida tags de imágenes (`preflight.py`) y declara como tags propias la unión de las tags de los roles de servicio que despliegan compose. Al añadir un rol de servicio nuevo, añade sus tags al rol `preflight` en `playbook.yml` (ambos plays), o un `--tags <nuevo>` se saltaría la validación en silencio. `preflight_require_arch: true` solo en yoda (exige variante arm64).
- **Compose**: nombre de servicio con prefijo `svc` (`svcPihole`); `container_name` sin prefijo (`pihole`, `openclaw`, `nginx_proxy`, `prometheus`, ...) — los roles usan `docker exec <container_name>`.
- **UID/GID 1000** para contenedores linuxserver.io (PUID/PGID). Excepciones: Grafana `472:0`, Prometheus `1000:1000`.
- **Transcodificación HW**: `/dev/dri/renderD128` solo en Jellyfin.
- **Imágenes arch-pinned**: los servicios media usan tags `amd64-` (corren solo en anton, x86_64); el rol `preflight` valida su existencia. En yoda/talos (arm64) no se despliegan.
- **Secretos** en `ansible/.env` (gitignored, ver `.env.example`): `TAILSCALE_AUTH_KEY`, `PIHOLE_PASS`, `GRAFANA_ADMIN_PASSWORD`.
- **Prefijos de PR**: `feat/`, `fix/`, `refactor/`, `docs/`.

## Operaciones Comunes

```bash
cd ansible/
cp .env.example .env       # editar con secretos
bash run.sh                # todas las máquinas
bash run.sh yoda           # solo RPi
bash run.sh talos          # solo Oracle
bash run.sh yoda --tags pihole,dns   # por rol
```

- La gestión del día a día (estado, logs, actualización, health checks) está en `docs/DOCKER.md` y `docs/COMMANDS.md`.
- **Backup**: `tar -czf backup-homelab-$(date +%Y%m%d).tar.gz -C $(dirname $PATH_DATA) $(basename $PATH_DATA)`
