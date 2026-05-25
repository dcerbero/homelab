# 🤖 Ansible — Aprovisionamiento

Automatiza la configuración del servidor Ubuntu para el homeserver.

## Inicio Rápido

```bash
cd ansible/
cp .env.example .env
# Editar .env con tus credenciales y rutas
bash run.sh
```

## Roles

| Rol | Descripción |
|---|---|
| `system-setup` | Paquetes del SO, deshabilitar DNS stub, clonar repositorio |
| `docker` | Instalación de Docker Engine, Docker Compose, grupo docker |
| `pihole` | Despliegue del contenedor Pi-hole con Docker Compose |
| `tailscale` | Instalación y autenticación de Tailscale VPN |
| `cadvisor` | Despliegue del contenedor cAdvisor |
| `openclaw` | Despliegue del contenedor OpenClaw (IA local) |

## Playbook

**Archivo:** [`ansible/playbook.yml`](../ansible/playbook.yml)

Ejecuta todos los roles en secuencia en el inventario `homeserver` con `become: true` (sudo).

```yaml
roles:
  - system-setup
  - docker
  - pihole
  - tailscale
  - cadvisor
  - openclaw
```

## Inventario

**Archivo:** `ansible/inventoryHomeServer.ini` (en `.gitignore` por seguridad)

```ini
[homeserver]
192.168.1.100 ansible_user=ubuntu
```

> Reemplazar `192.168.1.100` con la IP real del servidor.

## Variables de Entorno

**Archivo:** [`ansible/.env.example`](../ansible/.env.example)

```env
PIHOLE_PASS=your_password_here
PATH_DATA=/mnt/data
TAILSCALE_AUTH_KEY=tskey-auth-xxxxx
TAILSCALE_HOSTNAME=homeserver
```

| Variable | Descripción |
|---|---|
| `PIHOLE_PASS` | Contraseña de la interfaz web de Pi-hole |
| `PATH_DATA` | Ruta al disco de datos persistentes |
| `TAILSCALE_AUTH_KEY` | Clave de autenticación desde [Tailscale Admin](https://login.tailscale.com/admin/settings/keys) |
| `TAILSCALE_HOSTNAME` | Nombre del dispositivo en la red Tailscale |

## Ejecución

El script [`run.sh`](../ansible/run.sh) carga las variables del `.env` y ejecuta:

```bash
ansible-playbook playbook.yml \
  -i inventoryHomeServer.ini \
  -e "PIHOLE_PASS=$PIHOLE_PASS" \
  -e "PATH_DATA=$PATH_DATA" \
  -e "TAILSCALE_AUTH_KEY=$TAILSCALE_AUTH_KEY" \
  -e "TAILSCALE_HOSTNAME=$TAILSCALE_HOSTNAME" \
  -k -K -v
```

- `-k`: solicita contraseña SSH
- `-K`: solicita contraseña de sudo (become)
- `-v`: modo verbose
