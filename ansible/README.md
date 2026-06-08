# Configuración de Ansible

Automatiza el aprovisionamiento del servidor Ubuntu para la infraestructura del homeserver.

## Inicio rápido

```bash
cp .env.example .env
# Editar .env con tus credenciales y rutas
bash run.sh
```

## Roles

| Rol | Descripción |
|-----|-------------|
| `system-setup` | Paquetes del SO, red, montaje de disco |
| `docker` | Instalación de Docker y Docker Compose |
| `pihole` | Configuración del contenedor Pi-hole DNS |
| `tailscale` | Configuración de Tailscale VPN |

## Playbook

**Archivo:** `playbook.yml`

Ejecuta todos los roles en secuencia en el inventario `homeserver` con `become: true` (sudo).

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

Solicita contraseña SSH (`-k`) y contraseña de sudo (`-K`). Corre en modo verbose (`-v`).
