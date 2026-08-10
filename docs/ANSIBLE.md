# 🤖 Ansible — Aprovisionamiento

Automatiza la configuración de la infraestructura: Raspberry Pi 4 (yoda) + Oracle Cloud VM (talos, Pi-hole failover DNS). El Equipo x86_64 (anton) está pendiente de provisionar, aún sin play ni inventario.

## Inicio Rápido

```bash
cd ansible/
cp .env.example .env
# Editar .env con tus credenciales (secretos)
bash run.sh
```

## Roles

### yoda (RPi4)

| Rol | Tags | Descripción |
|---|---|---|
| `system-setup` | `system-setup`, `system` | Paquetes del SO, deshabilitar DNS stub, clonar repositorio |
| `docker` | `docker`, `containers` | Instalación de Docker Engine, Docker Compose, grupo docker |
| `preflight` | `preflight`, `containers` + unión de tags de roles compose | Verifica que todos los tags de `image:` en el repo existan en su registry y tengan variante `arm64` antes de desplegar |
| `pihole` | `pihole`, `dns` | Despliegue del contenedor Pi-hole con Docker Compose |
| `tailscale` | `tailscale`, `vpn` | Instalación y autenticación de Tailscale VPN |
| `cadvisor` | `cadvisor`, `monitoring` | Despliegue de cAdvisor y node-exporter (perfil `monitoring`) |
| `openclaw` | `openclaw`, `ia` | Despliegue del contenedor OpenClaw (IA) |
| `heimdall` | `heimdall`, `dashboard` | Despliegue del panel de control Heimdall |
| `nginx` | `nginx`, `proxy` | Despliegue del proxy reverso nginx (recrea en drift de imagen/mount, recarga para cambios de `conf.d`) |

### talos (Oracle Cloud VM)

| Rol | Tags | Descripción |
|---|---|---|
| `system-setup` | `system-setup`, `system`, `talos` | Paquetes del SO, DNS stub, clonar repo |
| `docker` | `docker`, `containers`, `talos` | Instalación de Docker Engine + Compose |
| `preflight` | `preflight`, `containers`, `talos` + unión de tags de roles compose | Verifica existencia de los tags (solo existencia; no exige arquitectura) |
| `pihole` | `pihole`, `dns`, `talos` | Pi-hole secundario (failover DNS) |
| `monitoring` | `monitoring`, `metrics`, `talos` | Stack de métricas centralizado: Prometheus, Grafana, node-exporter y cAdvisor. Tras el `compose up` recarga la config de Prometheus (`docker exec prometheus kill -HUP 1`) |

## Preflight (validación de imágenes)

Rol `preflight` que corre **antes** de desplegar cualquier servicio (tras `docker`, antes de `pihole`). Evita el fallo del `compose up` a mitad de play cuando un tag no existe (p. ej. el incidente de `nginx:1.30.3-bookworm` del 2026-08-05, que dejaba el contenedor stale).

Qué hace ([`files/preflight.py`](../ansible/roles/preflight/files/preflight.py)):

1. Extrae todos los `image:` de los `compose.yaml` del repo clonado.
2. Verifica cada tag con `docker manifest inspect` en paralelo (sin descargar la imagen).
3. Con `preflight_require_arch: true` (yoda) exige además que el tag tenga variante `arm64`.

Si alguna imagen falla, el play aborta listando los tags problemáticos antes de tocar contenedores. En talos solo se valida existencia (la arquitectura se resuelve en runtime con el fact `ansible_machine`, pero talos no exige `preflight_require_arch` porque no despliega los servicios media con tags `arm64v8-`).

El rol `preflight` declara como tags propias la unión de las tags de los roles de servicio que despliegan compose (`pihole`, `dns`, `cadvisor`, `monitoring`, `ia`, `dashboard`, `proxy`, `metrics`…). Así se activa también en runs etiquetados que tocan compose y se salta en los que no (p. ej. `--tags system-setup`, `--tags docker`, `--tags tailscale`).

**Regla de mantenimiento:** al añadir un rol de servicio que despliegue compose, hay que añadir sus tags a la lista del rol `preflight` en `playbook.yml` (ambos plays), o un `--tags <nuevo>` reabriría el hueco en silencio. Efecto colateral conocido: `--skip-tags <tag_compartida>` también se salta preflight.

```bash
# Probar solo el preflight
bash run.sh yoda --tags preflight
```

## Playbook

**Archivo:** [`ansible/playbook.yml`](../ansible/playbook.yml)

Dos plays independientes:

1. **`yoda`** — RPi4 local: todos los roles
2. **`talos`** — Oracle Cloud VM: Pi-hole failover + stack de monitoreo (system-setup, docker, pihole, monitoring)

> Pendiente: el Equipo x86_64 (anton) se incorporará como un tercer play cuando se provisione.

La definición exacta de roles y tags está en [`ansible/playbook.yml`](../ansible/playbook.yml).

## Inventario

**Directorio:** [`ansible/inventory/`](../ansible/inventory/)

Inventario en formato directorio con variables por host. Cada máquina define su propio `PATH_DATA`.

```text
inventory/
├── yoda.yml                      # Definición del host RPi
├── talos.yml                     # Definición del host Oracle Cloud
├── host_vars/
│   ├── yoda.yml                  # PATH_DATA, TAILSCALE_HOSTNAME, preflight_require_arch
│   └── talos.yml                 # PATH_DATA, TAILSCALE_HOSTNAME
```

> El Equipo x86_64 (anton) aún no tiene entrada en el inventario; se añadirá al provisionar.

### SSH

La conexión se resuelve via `~/.ssh/config` local (fuera del repo). Ansible solo usa el nombre del host del inventario.

```text
# ~/.ssh/config
Host yoda
    HostName <ip_yoda>
    User <username>
    IdentityFile ~/.ssh/<clave_privada>

Host talos
    HostName <ip_talos>
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
| `GRAFANA_ADMIN_PASSWORD` | Contraseña del usuario admin de Grafana (stack de métricas en talos) |

Solo secretos viven en `.env` (gitignorado). Las variables de máquina (`PATH_DATA`, `TAILSCALE_HOSTNAME`) viven en `inventory/host_vars/<host>.yml`.

## Ejecución

El script [`run.sh`](../ansible/run.sh) carga los secretos del `.env`, usa `inventory/` como inventario y acepta la máquina como primer argumento.

```bash
# Todas las máquinas
bash run.sh

# Solo yoda (RPi)
bash run.sh yoda

# Solo talos
bash run.sh talos

# Solo un rol específico en una máquina
bash run.sh yoda --tags pihole,dns
bash run.sh talos --tags docker

# Stack IA completo en yoda
bash run.sh yoda --tags ia

# Todo talos (aprovecha las tags talos)
bash run.sh talos --tags talos

# Todo excepto system-setup (salta el apt upgrade)
bash run.sh --skip-tags system
```

- `bash run.sh <maquina>` → equivale a `--limit <maquina>`
- Los argumentos extra se pasan directamente a `ansible-playbook`
- `run.sh` usa `--ask-become-pass`: pide la contraseña de sudo una vez al inicio de cada pasada
- No se usa `-k` (la conexión SSH se resuelve via `~/.ssh/config`); solo se pide el become password
