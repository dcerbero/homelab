# 🤖 Hermes Agent

Agente de IA de [Nous Research](https://hermes-agent.nousresearch.com/) corriendo en [yoda](HARDWARE.md#yoda) bajo el perfil Docker `ai`. Corre el *gateway* supervisado por `s6-overlay` (si el proceso muere, se reinicia solo) y sirve un dashboard web con basic auth en el puerto `9119`.

## Índice

- [Qué es y qué no](#qué-es-y-qué-no)
- [Acceso](#acceso)
- [Configuración](#configuración)
- [Secretos](#secretos)
- [Modelo](#modelo)
- [Operación](#operación)
- [Logs](#logs)
- [Actualizar](#actualizar)
- [Límites de seguridad](#límites-de-seguridad)
- [Backup](#backup)

## Qué es y qué no

**Es** un agente conversacional con memoria, sesiones y dashboard propio, que sale a Internet hacia la API del proveedor de modelo.

**No es** un administrador de la infraestructura. Deliberadamente no monta `docker.sock`, no tiene el repo montado y no puede desplegar nada. Tampoco entra por nginx: se consume directo en LAN/Tailscale.

## Acceso

```
http://yoda:9119        (o http://<ip-de-yoda>:9119)
```

Pide usuario y password (los `HERMES_DASHBOARD_BASIC_AUTH_*` de `ansible/.env`). El puerto no se publica a Internet.

## Configuración

Dos capas que no hay que confundir:

| Archivo | Quién manda |
|---|---|
| `services/docker/hermes/config/config.yaml` (repo) | **Seed**: el rol lo copia a `$PATH_DATA/persistence/hermes/config.yaml` con `force: false` — nunca sobreescribe |
| `$PATH_DATA/persistence/hermes/config.yaml` (runtime) | Fuente de verdad real. El dashboard y `hermes config set` lo reescriben |

Consecuencia práctica: cambiar el seed en el repo **no** afecta a un Hermes ya desplegado. Para cambiarlo de verdad:

```bash
docker exec hermes hermes config set model opencode-go/<modelo>
docker restart hermes
```

Todo el estado mutable vive en `$PATH_DATA/persistence/hermes`: `config.yaml`, `.env`, `SOUL.md`, `sessions/`, `memories/`, `skills/`, `logs/`.

## Secretos

En `ansible/.env` (gitignored):

| Variable | Uso |
|---|---|
| `OPENCODE_GO_API_KEY` | Key del plan OpenCode Go; se inyecta como variable de entorno del contenedor |
| `HERMES_DASHBOARD_USER` / `_PASSWORD` | Credenciales del dashboard |
| `HERMES_DASHBOARD_SECRET` | Firma de sesiones; generar con `openssl rand -hex 32` |

`run.sh` las pasa al playbook con `-e`; el rol las exporta al ejecutar `docker compose`. Nada de esto se escribe en el repo.

## Modelo

Valor inicial del seed:

```yaml
model: opencode-go/deepseek-v4.1-flash
```

Formato `<proveedor>/<modelo>`. `opencode-go` usa **namespace plano** (el id es `deepseek-v4.1-flash`, no `vendor/modelo`) y se autentica con `OPENCODE_GO_API_KEY`. La lista de modelos disponibles depende del plan contratado.

Para cambiarlo en un despliegue existente (el seed no se reaplica):

```bash
docker exec hermes hermes config set model opencode-go/<modelo>
docker restart hermes
```

## Operación

```bash
cd ~/services/homelab/services/docker

# estado
PATH_DATA=/server docker compose --profile ai ps
docker stats --no-stream hermes

# arrancar / parar / reiniciar
PATH_DATA=/server docker compose --profile ai up -d
PATH_DATA=/server docker compose --profile ai stop
docker restart hermes

# consola del agente dentro del contenedor
docker exec -it hermes /opt/hermes/.venv/bin/hermes

# estado del gateway y del dashboard (supervisados por s6)
docker exec hermes hermes gateway status
```

El contenedor tiene `restart: unless-stopped` y el gateway está supervisado: un crash se recupera en segundos sin reiniciar el contenedor.

## Logs

```bash
docker logs -f hermes                          # gateway + dashboard en vivo
tail -F /server/persistence/hermes/logs/gateways/default/current   # rotado, sobrevive reinicios
docker exec hermes hermes logs --follow        # logs internos del agente
```

## Actualizar

La imagen está pinneada (`nousresearch/hermes-agent:v0.23.4`). Actualizar = cambiar el tag en `services/docker/hermes/compose.yaml`, commit y `bash run.sh yoda --tags hermes`. `preflight` valida que el tag exista y tenga variante `arm64`.

> [!NOTE]
> `hermes update` **no** sirve para actualizar la aplicación dentro del contenedor: la imagen es inmutable (`/opt/hermes` es de sólo lectura). La única vía es cambiar el tag y recrear.

## Límites de seguridad

- Sin `docker.sock`: no crea, borra ni inspecciona contenedores.
- Sin repo montado: no despliega.
- `memory: 1.5g`: si se desboca, el cgroup mata a Hermes — no a yoda.
- Dashboard con basic auth obligatorio y sólo en LAN/Tailscale.

Riesgo aceptado: el dashboard es HTTP en claro dentro de la LAN. Ver [`SECURITY.md`](SECURITY.md#hermes-agent).

Si en algún momento se necesita que el agente *vea* contenedores, la vía es darle acceso de lectura por una API intermedia y **no** montar el socket directo; montar el socket convierte al agente en root del host y con ello al DNS de la casa en material fungible.

## Backup

Entra en el backup general (`$PATH_DATA`):

```bash
tar -czf backup-homelab-$(date +%Y%m%d).tar.gz -C $(dirname $PATH_DATA) $(basename $PATH_DATA)
```

Restaurar = reponer `persistence/hermes` y volver a levantar el perfil `ai`.
