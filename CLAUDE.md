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
│   ├── playbook.yml                # Entry point (runs all roles in order)
│   ├── run.sh                      # Loads .env, invokes ansible-playbook
│   ├── inventoryHomeServer.ini     # .gitignore'd — target IP/user
│   ├── group_vars/all/main.yml     # Global Ansible variables
│   └── roles/
│       ├── system-setup/           # apt upgrade, disable DNS stub, git clone repo
│       ├── docker/                 # Install Docker Engine + compose plugin
│       ├── pihole/                 # docker compose --profile dns up
│       ├── tailscale/              # Install + authenticate VPN
│       ├── cadvisor/               # docker compose --profile monitoring up
│       ├── openclaw/               # Create data dir + docker compose --profile ia up
│       └── nginx/                  # docker compose --profile infra up
├── services/docker/
│   ├── compose.yaml                # Aggregator via `include:`
│   ├── dns/pihole.yaml             # Profile: dns
│   ├── infra/nginx.yaml            # Profile: infra
│   ├── monitoring/cadvisor.yaml    # Profile: monitoring
│   ├── ia/openclaw.yaml            # Profile: ia
│   ├── core/heimdall.yaml          # Profile: dashboard
│   ├── media/jellyfin.yaml         # Profile: media-streaming
│   ├── media/transmission.yaml     # Profile: media-download
│   ├── media/prowlarr.yaml         # Profile: media-download
│   └── media/sonarr.yaml           # Profile: media-download
├── config/
│   └── nginx/conf.d/default.conf   # Reverse proxy config (mounted into nginx)
├── docs/                           # ARCHITECTURE, SETUP, DOCKER, TROUBLESHOOTING, SECURITY
└── CLAUDE.md                       # This file
```

### Key Architecture Details

- **Ansible runs roles in strict order** (system → docker → pihole → tailscale → cadvisor → openclaw → nginx)
- **Docker Compose uses profiles** — root `compose.yaml` aggregates 10 independent files via `include:`. Each file declares its profile(s).
- **nginx is the single entry point** for web UIs — reverse-proxies to Heimdall, OpenClaw, etc. Web services expose real ports only to LAN.
- **OpenClaw inference path**: OpenClaw → DeepSeek API directa. Embeddings via Tailscale → Ollama on Oracle Cloud.
- **OpenClaw heartbeat**: No tiene heartbeat configurado. Sin polling periódico externo.
- **Persistent data at `$PATH_DATA`** on external disk. Compose files reference it via `${PATH_DATA}`.
- **Secrets** (`TAILSCALE_AUTH_KEY`, `PIHOLE_PASS`) in `ansible/.env` and `services/docker/.env` — both `.gitignore`d.

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
cp .env.example .env     # Edit with server IP, secrets, data path
bash run.sh               # Loads .env and runs ansible-playbook
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
- **Inventories** (`*.ini`) are gitignored — `inventoryHomeServer.ini.example` is the template
- **Compose service names** prefixed `svc` (e.g. `svcPihole`) to avoid collisions
- **No ports exposed to WAN** — LAN-only or via Tailscale VPN
- **Hardware transcoding** on Pi 4 uses `/dev/dri/renderD128` (Jellyfin only)
- **Pi-hole needs port 53 free** — `system-setup` role disables systemd-resolved DNS stub
- **UID/GID 1000** for all linuxserver.io containers
- **Pull request prefix**: `feat/`, `fix/`, `refactor/`, `docs/`
