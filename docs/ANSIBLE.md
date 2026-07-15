# 🤖 Ansible — Aprovisionamiento

Automatiza la configuración del servidor Ubuntu para el homeserver + Oracle Cloud VM.

## Inicio Rápido

```bash
cd ansible/
cp .env.example .env
# Editar .env con tus credenciales y rutas
bash run.sh
```

## Roles

### homeserver (RPi4)

| Rol | Tags | Descripción |
|---|---|---|
| `system-setup` | `system-setup`, `system` | Paquetes del SO, deshabilitar DNS stub, clonar repositorio |
| `docker` | `docker`, `containers` | Instalación de Docker Engine, Docker Compose, grupo docker |
| `pihole` | `pihole`, `dns` | Despliegue del contenedor Pi-hole con Docker Compose |
| `tailscale` | `tailscale`, `vpn` | Instalación y autenticación de Tailscale VPN |
| `cadvisor` | `cadvisor`, `monitoring` | Despliegue del contenedor cAdvisor |
| `openclaw` | `openclaw`, `ia` | Despliegue del contenedor OpenClaw (IA local) |
| `heimdall` | `heimdall`, `dashboard` | Despliegue del panel de control Heimdall |
| `nginx` | `nginx`, `proxy` | Despliegue del proxy reverso nginx |

### Oracle Cloud VM

| Rol | Tags | Descripción |
|---|---|---|
| `system-setup` | `system-setup`, `system`, `oracle` | Paquetes (sin upgrade), DNS stub, clonar repo |
| `docker` | `docker`, `containers`, `oracle` | Instalación de Docker Engine + Compose |
| `pihole` | `pihole`, `dns`, `oracle` | Pi-hole secundario (failover, `pihole_path_data: /opt/pihole`) |

## Playbook

**Archivo:** [`ansible/playbook.yml`](../ansible/playbook.yml)

Dos plays independientes:

1. **`homeserver`** — RPi4 local: todos los roles
2. **`oracle`** — Oracle Cloud VM: solo Pi-hole failover (system-setup, docker, pihole)

```yaml
# Play homeserver
roles:
  - role: system-setup
    tags: [system-setup, system]
  - role: docker
    tags: [docker, containers]
  - role: pihole
    tags: [pihole, dns]
  - role: tailscale
    tags: [tailscale, vpn]
  - role: cadvisor
    tags: [cadvisor, monitoring]
  - role: openclaw
    tags: [openclaw, ia]
  - role: heimdall
    tags: [heimdall, dashboard]
  - role: nginx
    tags: [nginx, proxy]

# Play oracle
roles:
  - role: system-setup
    tags: [system-setup, system, oracle]
  - role: docker
    tags: [docker, containers, oracle]
  - role: pihole
    tags: [pihole, dns, oracle]
    vars:
      pihole_path_data: /opt/pihole  # Hardcodeado para Oracle
```

### Tags

Cada rol tiene un tag individual y uno de grupo para ejecución selectiva:

```bash
# Solo nginx (ej: cambio de config)
bash run.sh --tags nginx

# Stack IA (openclaw)
bash run.sh --tags ia

# Todo Oracle
bash run.sh --limit oracle --tags oracle

# Solo Pi-hole en Oracle
bash run.sh --limit oracle --tags pihole

# Todo excepto system-setup (salta el apt upgrade)
bash run.sh --skip-tags system
```

Los argumentos extra se pasan directamente a `ansible-playbook` gracias a `$@` en `run.sh`.

## Inventario

**Archivo:** `ansible/inventoryHomeServer.ini` (en `.gitignore` por seguridad)

```ini
[homeserver]
192.168.1.100 ansible_user=pi

[oracle]
100.100.x.x ansible_user=ubuntu
```

> Reemplazar IPs con las reales. La de Oracle puede ser la IP de Tailscale.

## Variables de Entorno

**Archivo:** [`ansible/.env.example`](../ansible/.env.example)

```env
PIHOLE_PASS=your_password_here
PATH_DATA=/mnt/data
TAILSCALE_AUTH_KEY=tskey-auth-xxxxx
TAILSCALE_HOSTNAME=homeserver
ORACLE_HOSTNAME=oracle-box
```

| Variable | Descripción |
|---|---|
| `PIHOLE_PASS` | Contraseña de la interfaz web de Pi-hole |
| `PATH_DATA` | Ruta al disco de datos persistentes (homeserver) |
| `TAILSCALE_AUTH_KEY` | Clave de autenticación desde [Tailscale Admin](https://login.tailscale.com/admin/settings/keys) |
| `TAILSCALE_HOSTNAME` | Nombre del dispositivo en la red Tailscale (homeserver) |
| `ORACLE_HOSTNAME` | Hostname de Oracle VM en Tailscale |

## Ejecución

El script [`run.sh`](../ansible/run.sh) carga las variables del `.env` y ejecuta ambos plays:

```bash
ansible-playbook playbook.yml \
  -i inventoryHomeServer.ini \
  -e "PIHOLE_PASS=$PIHOLE_PASS" \
  -e "PATH_DATA=$PATH_DATA" \
  -e "TAILSCALE_AUTH_KEY=$TAILSCALE_AUTH_KEY" \
  -e "TAILSCALE_HOSTNAME=$TAILSCALE_HOSTNAME" \
  -e "oracle_hostname=$ORACLE_HOSTNAME" \
  -k -K -v
```

- `-k`: solicita contraseña SSH
- `-K`: solicita contraseña de sudo (become)
- `-v`: modo verbose
- `--limit oracle`: solo ejecuta el play de Oracle
- `--limit homeserver`: solo ejecuta el play de la Pi