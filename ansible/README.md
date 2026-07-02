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
| `headroom` | `headroom`, `ia` | Directorio de datos Headroom |
| `nginx` | `nginx`, `proxy` | Contenedor nginx proxy reverso |

## Playbook

**Archivo:** `playbook.yml`

Ejecuta todos los roles en secuencia en el inventario `homeserver` con `become: true` (sudo).

Cada rol tiene un tag individual y otro de grupo para ejecución selectiva:

```bash
# Solo nginx
bash run.sh --tags nginx

# Stack IA completo
bash run.sh --tags ia

# Todo excepto system-setup
bash run.sh --skip-tags system
```

## Inventario

**Archivo:** `inventoryHomeServer.ini` (en .gitignore por seguridad)

```ini
[homeserver]
<IP_SERVIDOR> ansible_user=<USUARIO>
```

**Ejemplo:**
```ini
[homeserver]
192.168.x.x ansible_user=ubuntu
```

## Variables

**Archivo:** `.env` (cargado localmente por `run.sh`)

```env
PIHOLE_PASS=tu_contraseña_pihole
PATH_DATA=/mnt/data  # Punto de montaje del almacenamiento persistente
TAILSCALE_AUTH_KEY=tskey-auth-xxxxx  # Clave de autenticación desde la consola de Tailscale
TAILSCALE_HOSTNAME=homeserver  # Nombre del dispositivo en Tailscale
```

## Ejecución

```bash
bash run.sh
```

Solicita contraseña SSH (`-k`) y contraseña de sudo (`-K`). Corre en modo verbose (`-v`). Los argumentos extra (como `--tags`) se pasan directamente a `ansible-playbook`.
