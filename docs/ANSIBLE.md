# 🤖 Ansible — Aprovisionamiento

Automatiza la configuración de la infraestructura: Raspberry Pi 4 (homeserver) + Oracle Cloud VM (Pi-hole failover DNS).

## Inicio Rápido

```bash
cd ansible/
cp .env.example .env
# Editar .env con tus credenciales (secretos)
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
| `openclaw` | `openclaw`, `ia` | Despliegue del contenedor OpenClaw (IA) |
| `heimdall` | `heimdall`, `dashboard` | Despliegue del panel de control Heimdall |
| `nginx` | `nginx`, `proxy` | Despliegue del proxy reverso nginx |

### Oracle Cloud VM

| Rol | Tags | Descripción |
|---|---|---|
| `system-setup` | `system-setup`, `system`, `oracle` | Paquetes del SO, DNS stub, clonar repo |
| `docker` | `docker`, `containers`, `oracle` | Instalación de Docker Engine + Compose |
| `pihole` | `pihole`, `dns`, `oracle` | Pi-hole secundario (failover DNS) |

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
```

## Inventario

**Directorio:** [`ansible/inventory/`](../ansible/inventory/)

Inventario en formato directorio con variables por host. Cada máquina define su propio `PATH_DATA`.

```text
inventory/
├── homeserver.yml              # Definición del host RPi
├── oracle.yml                  # Definición del host Oracle Cloud
├── host_vars/
│   ├── homeserver.yml          # PATH_DATA, TAILSCALE_HOSTNAME
│   └── oracle.yml              # PATH_DATA, TAILSCALE_HOSTNAME
```

### SSH

La conexión se resuelve via `~/.ssh/config` local (fuera del repo). Ansible solo usa el nombre del host del inventario.

```text
# ~/.ssh/config
Host pi
    HostName <ip_homeserver>
    User <username>
    IdentityFile ~/.ssh/<clave_privada>

Host oracle
    HostName <ip_oracle>
    User <username>
    IdentityFile ~/.ssh/<clave_privada>
```

Cada máquina puede tener su propio método de autenticación (password o llave SSH). No se necesitan `-k -K` ni credenciales en el repo.

## Variables de Entorno

**Archivo:** [`ansible/.env.example`](../ansible/.env.example)

```env
PIHOLE_PASS=your_password_here
TAILSCALE_AUTH_KEY=tskey-auth-xxxxx
```

| Variable | Descripción |
|---|---|
| `PIHOLE_PASS` | Contraseña de la interfaz web de Pi-hole |
| `TAILSCALE_AUTH_KEY` | Clave de autenticación desde [Tailscale Admin](https://login.tailscale.com/admin/settings/keys) |

Solo secretos viven en `.env` (gitignorado). Las variables de máquina (`PATH_DATA`, `TAILSCALE_HOSTNAME`) viven en `inventory/host_vars/<host>.yml`.

## Ejecución

El script [`run.sh`](../ansible/run.sh) carga los secretos del `.env`, usa `inventory/` como inventario y acepta la máquina como primer argumento.

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

- `bash run.sh <maquina>` → equivale a `--limit <maquina>`
- Los argumentos extra se pasan directamente a `ansible-playbook`
- No se usan `-k -K` (la conexión SSH se resuelve via `~/.ssh/config`)
