# Configuración de Ansible

Automatiza el aprovisionamiento de la infraestructura del homeserver: Raspberry Pi 4 (local) + Oracle Cloud VM (Pi-hole failover).

## Inicio rápido

```bash
cp .env.example .env
# Editar .env con tus credenciales
bash run.sh
```

## Roles

| Rol | Tags | Descripción |
|---|---|---|
| `system-setup` | `system-setup`, `system` | Paquetes del SO, DNS stub, clonar repositorio |
| `docker` | `docker`, `containers` | Instalación de Docker Engine + Compose |
| `pihole` | `pihole`, `dns` | Contenedor Pi-hole DNS |
| `tailscale` | `tailscale`, `vpn` | Instalación y autenticación Tailscale VPN |
| `cadvisor` | `cadvisor`, `monitoring` | Contenedor cAdvisor |
| `openclaw` | `openclaw`, `ia` | Contenedor OpenClaw (IA) |
| `heimdall` | `heimdall`, `dashboard` | Contenedor Heimdall panel de control |
| `nginx` | `nginx`, `proxy` | Contenedor nginx proxy reverso |

## Playbook

**Archivo:** `playbook.yml`

Dos plays independientes:

1. **`homeserver`** — RPi4 local: todos los roles (system-setup, docker, pihole, tailscale, cadvisor, openclaw, heimdall, nginx)
2. **`oracle`** — Oracle Cloud VM: solo Pi-hole secundario como failover DNS (system-setup, docker, pihole)

## Inventario

**Directorio:** `inventory/`

```text
inventory/
├── homeserver.yml              # Definición del host RPi
├── oracle.yml                  # Definición del host Oracle Cloud
├── host_vars/
│   ├── homeserver.yml          # PATH_DATA, TAILSCALE_HOSTNAME
│   └── oracle.yml              # PATH_DATA, TAILSCALE_HOSTNAME
```

Cada host tiene su propio `PATH_DATA` (ruta de almacenamiento) resuelto desde `host_vars/<host>.yml`.

### SSH

La conexión se resuelve via `~/.ssh/config` local (fuera del repo). Ansible solo usa el nombre del host:

```text
Host pi
    HostName <ip_homeserver>
    User <username>
    IdentityFile ~/.ssh/<clave_privada>

Host oracle
    HostName <ip_oracle>
    User <username>
    IdentityFile ~/.ssh/<clave_privada>
```

## Variables

**Archivo:** `.env` (solo secretos, en `.gitignore`)

```env
PIHOLE_PASS=tu_contraseña_pihole
TAILSCALE_AUTH_KEY=tskey-auth-xxxxx  # Clave de autenticación desde la consola de Tailscale
```

## Ejecución

```bash
# Todas las máquinas
bash run.sh

# Solo homeserver (RPi)
bash run.sh homeserver

# Solo Oracle (Pi-hole failover)
bash run.sh oracle

# Solo un rol específico en una máquina
bash run.sh homeserver --tags pihole,dns
bash run.sh oracle --tags docker

# Stack IA completo en homeserver
bash run.sh homeserver --tags ia

# Todo Oracle (aprovecha las tags oracle)
bash run.sh oracle --tags oracle

# Todo excepto system-setup (salta el apt upgrade)
bash run.sh --skip-tags system
```

El primer argumento de `run.sh` es el `--limit` (máquina). Los argumentos extra (como `--tags`) se pasan directamente a `ansible-playbook`.
