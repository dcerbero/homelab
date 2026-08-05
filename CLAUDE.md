# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Hybrid homelab infrastructure: Raspberry Pi 4 (local) + Oracle Cloud VM, provisioned with Ansible and running Docker services.

Two subsystems, each with its own lifecycle:
1. **Ansible provisioning** (`ansible/`) — bare-metal setup of Ubuntu, Docker, Tailscale, and initial service deployment
2. **Docker Compose profiles** (`services/docker/`) — day-to-day service management

---

## Architecture

```
homelab/
├── ansible/                        # Provisioning layer
│   ├── playbook.yml                # Entry point (two plays: homeserver + oracle)
│   ├── run.sh                      # Loads .env, invokes ansible-playbook
│   ├── inventory/                  # Inventory directory (host_vars per machine)
│   │   ├── homeserver.yml          # Host definition for Raspberry Pi
│   │   ├── oracle.yml              # Host definition for Oracle Cloud VM
│   │   ├── host_vars/
│   │   │   ├── homeserver.yml      # PATH_DATA, TAILSCALE_HOSTNAME
│   │   │   └── oracle.yml          # PATH_DATA, TAILSCALE_HOSTNAME
│   │   └── group_vars/
│   │       └── all.yml             # Global Ansible variables
│   └── roles/
│       ├── system-setup/           # apt upgrade (skip en Oracle), disable DNS stub, git clone
│       ├── docker/                 # Install Docker Engine + compose plugin
│       ├── pihole/                 # docker compose --profile dns up
│       ├── tailscale/              # Install + authenticate VPN
│       ├── cadvisor/               # docker compose --profile monitoring up
│       ├── openclaw/               # Create data dir + docker compose --profile ia up
│       ├── heimdall/               # docker compose --profile dashboard up
│       └── nginx/                  # docker compose --profile infra up
├── services/docker/
│   ├── compose.yaml                # Aggregator via `include:`
│   ├── pihole/compose.yaml         # Profile: dns
│   ├── nginx/compose.yaml          # Profile: infra
│   ├── nginx/config/conf.d/default.conf  # Reverse proxy config (mounted :ro from repo)
│   ├── cadvisor/compose.yaml       # Profile: monitoring
│   ├── openclaw/compose.yaml       # Profile: ia
│   ├── heimdall/compose.yaml       # Profile: dashboard
│   ├── jellyfin/compose.yaml       # Profile: media-streaming
│   ├── transmission/compose.yaml   # Profile: media-download
│   ├── prowlarr/compose.yaml       # Profile: media-download
│   ├── sonarr/compose.yaml         # Profile: media-download
│   └── sonarr/config/noTranscoding.json  # Custom format para Sonarr (x264 sin Remux)
├── config/
│   └── scripts/agente/costos.sh    # Auditoría costo-beneficio de modelos LLM
├── docs/                           # ARCHITECTURE, SETUP, DOCKER, TROUBLESHOOTING, SECURITY, ANSIBLE, COMMANDS, README
└── CLAUDE.md                       # This file
```

### Key Architecture Details

- **Ansible runs roles in strict order** (system → docker → pihole → tailscale → cadvisor → openclaw → heimdall → nginx). El orden completo aplica solo al play homeserver; oracle ejecuta system-setup → docker → pihole.
- **Docker Compose uses profiles** — root `compose.yaml` aggregates 9 independent files via `include:`. Each file declares its profile(s).
- **nginx is the single entry point** for web UIs — reverse-proxies to Heimdall, OpenClaw, etc. Web services expose real ports only to LAN.
- **OpenClaw inference path**: OpenClaw → OpenRouter API.
- **Pi-hole role**: usa `{{ PATH_DATA }}` directo, resuelto de `host_vars/<host>.yml` para cada máquina.
- **Config en el repo, datos en `$PATH_DATA`** — las configs versionadas viven en el repo (un `git pull` las restablece; montajes `:ro`); el estado runtime vive en `$PATH_DATA` con dos tiers: `persistence/<svc>/` (estado durable de cada servicio) y `media/` (biblioteca compartida entre servicios).
- **Persistent data at `$PATH_DATA`** — ruta de almacenamiento definida por máquina en `host_vars/`.
- **Secrets** (`TAILSCALE_AUTH_KEY`, `PIHOLE_PASS`) in `ansible/.env` — `.gitignore`d.

---

## Engineering Principles

### NUNCA SEAS COMPLACIENTE
- No aceptes requisitos malos sin cuestionar
- No hagas código inseguro
- No uses prácticas obsoletas
- No evites decir "esto está mal"

### ENSEÑA, NO SOLO RECOMIENDES
- Conceptos fundamentales
- Alternativas
- Hazme pensar
- Si me equivoco, lección en una línea

### ESCALERA DE EFICIENCIA (Ponytail Principle)
Antes de escribir código, subir esta escalera en orden:

1. **YAGNI** — ¿Realmente necesita existir? Si se resuelve con config, env vars, comando existente, o es one-shot, no se escribe.
2. **Ya existe en el codebase** — Reusar, extender, no duplicar.
3. **Stdlib lo hace** — Builtins del SO, módulos core, comandos base.
4. **Feature nativa de la plataforma** — Docker primitives, cloud APIs, Ansible modules.
5. **Dependencia ya instalada** — No instalar nueva si ya hay algo que cubre el caso.
6. **Una línea** — Si se puede en una línea, una línea.
7. **Solo entonces** — El mínimo que funcione. Sin sobrearquitectura.

Lazy, not negligent: validación, seguridad, errores nunca se recortan.

### STANDARDS
- Security First
- Best practices obligatorio
- No shortcuts
- Documenta lo hecho

---

## Common Operations

### Provision/Re-provision (Ansible)

```bash
cd ansible/
cp .env.example .env     # Edit with secrets
bash run.sh               # All machines

# Solo Oracle (Pi-hole failover)
bash run.sh oracle

# Solo homeserver (sin Oracle)
bash run.sh homeserver

# Por rol específico
bash run.sh homeserver --tags pihole,dns
```

### Manage Docker Services

```bash
cd services/docker/

# Start profiles:
docker compose --profile dns --profile infra up -d
docker compose --profile ia up -d

# All services:
docker compose up -d

# Status / logs:
docker compose ps
docker compose logs -f svcPihole

# Update a service:
docker compose pull svcPihole && docker compose up -d svcPihole
```

### Health Checks

```bash
dig google.com @127.0.0.1     # Pi-hole DNS
curl -s localhost:8085/healthz # cAdvisor
curl -s -o /dev/null -w "%{http_code}" http://localhost  # nginx
```

### Backup

```bash
tar -czf backup-homelab-$(date +%Y%m%d).tar.gz -C $(dirname $PATH_DATA) $(basename $PATH_DATA)
```

---

## Important Conventions

- **Ansible**: all roles run with `become: true`
- **Inventories** (`inventory/`) — `inventory/homeserver.yml` and `inventory/oracle.yml` define hosts
- **Compose service names** prefixed `svc` (e.g. `svcPihole`) excepto openclaw (compatibilidad con nginx proxy_pass)
- **No ports exposed to WAN** — LAN-only or via Tailscale VPN
- **Hardware transcoding** on Pi 4 uses `/dev/dri/renderD128` (Jellyfin only)
- **Pi-hole needs port 53 free** — `system-setup` role disables systemd-resolved DNS stub
- **Pi-hole failover**: Pi-hole secundario en Oracle Cloud VM. Mismas adlists, gravity independiente. Sin sync. Tailscale DNS con ambos nameservers.
- **UID/GID 1000** for all linuxserver.io containers
- **Pull request prefix**: `feat/`, `fix/`, `refactor/`, `docs/`
