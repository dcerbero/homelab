# Configuración de Ansible

Automatiza el aprovisionamiento del servidor Ubuntu para la infraestructura del homeserver.

## Inicio rápido

```bash
cp .env.example .env
# Editar .env con tus credenciales y rutas
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
| `openclaw` | `openclaw`, `ia` | Contenedor OpenClaw (IA local) |
| `heimdall` | `heimdall`, `dashboard` | Contenedor Heimdall panel de control |
| `nginx` | `nginx`, `proxy` | Contenedor nginx proxy reverso |

## Playbook

**Archivo:** `playbook.yml`

Dos plays independientes en un mismo archivo:

1. **`homeserver`** — RPi4 local: todos los roles (sistema, Docker, Pi-hole, Tailscale, monitoreo, IA, proxy)
2. **`oracle`** — Oracle Cloud VM: solo Pi-hole secundario como failover DNS (system-setup, docker, pihole)

Cada rol tiene un tag individual y otro de grupo para ejecución selectiva:

```bash
# Solo nginx en homeserver
bash run.sh --tags nginx

# Stack IA completo en homeserver
bash run.sh --tags ia

# Solo Pi-hole en Oracle
bash run.sh --limit oracle --tags pihole

# Todo Oracle (aprovecha las tags oracle)
bash run.sh --limit oracle --tags oracle
```

## Inventario

**Archivo:** `inventoryHomeServer.ini` (en .gitignore por seguridad)

```ini
[homeserver]
<IP_SERVIDOR> ansible_user=<USUARIO>

[oracle]
<IP_ORACLE> ansible_user=<USUARIO_ORACLE>
```

**Ejemplo:**
```ini
[homeserver]
192.168.1.100 ansible_user=pi

[oracle]
100.100.x.x ansible_user=ubuntu
```

## Variables

**Archivo:** `.env` (cargado localmente por `run.sh`)

```env
PIHOLE_PASS=tu_contraseña_pihole
PATH_DATA=/mnt/data  # Punto de montaje del almacenamiento persistente
TAILSCALE_AUTH_KEY=tskey-auth-xxxxx  # Clave de autenticación desde la consola de Tailscale
TAILSCALE_HOSTNAME=homeserver  # Nombre del dispositivo en Tailscale
ORACLE_HOSTNAME=oracle-box    # Hostname del Oracle VM en Tailscale
```

## Ejecución

```bash
bash run.sh
```

Solicita contraseña SSH (`-k`) y contraseña de sudo (`-K`). Corre en modo verbose (`-v`). Los argumentos extra (como `--tags` o `--limit`) se pasan directamente a `ansible-playbook`.