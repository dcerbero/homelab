# 🔧 Solución de Problemas

Si algo se rompe, aquí está lo que ya nos ha pasado y cómo se arregla. No es magia: es el cuaderno de bitácora de los fallos que hemos ido resolviendo.

## Índice

- [Conflictos de Puertos](#conflictos-de-puertos)
- [Permisos de Volúmenes](#permisos-de-volúmenes)
- [Tailscale no autentica](#tailscale-no-autentica)
- [Ansible falla por conexión SSH](#ansible-falla-por-conexión-ssh)
- [DNS no resuelve desde dispositivos](#dns-no-resuelve-desde-dispositivos)
- [Tag de imagen inexistente o sin arquitectura](#tag-de-imagen-inexistente-o-sin-arquitectura)
- [Rate limit de Docker Hub en el preflight](#rate-limit-de-docker-hub-en-el-preflight)

## Conflictos de Puertos

**Síntoma:** Un servicio no arranca con error de puerto.

**Solución:**
```bash
sudo lsof -i :<PUERTO>
# Si otro proceso lo ocupa, detenerlo o cambiar el puerto del servicio
```

## Permisos de Volúmenes

**Síntoma:** Servicios LinuxServer.io no pueden escribir en volúmenes.

**Solución:**
```bash
sudo chown -R 1000:1000 ${PATH_DATA}
```

## Tailscale no autentica

**Síntoma:** `tailscale status` muestra el nodo como desconectado.

**Solución:**
```bash
# Regenerar auth key en https://login.tailscale.com/admin/settings/keys
# Actualizar TAILSCALE_AUTH_KEY en .env y re-ejecutar Ansible
```

## Ansible falla por conexión SSH

**Síntoma:** `fatal: [yoda]: UNREACHABLE!` con `Permission denied (publickey,password)` aunque la clave SSH tiene passphrase y parece no pedirla.

**Causa:** la clave privada está encriptada con passphrase pero ssh no puede usarla: no hay prompt disponible (sin TTY) y el ssh-agent está vacío. Sin la clave desbloqueada no puede firmar el challenge → `Permission denied`.

**Solución:**
```bash
# Cargar la clave en el agente y guardar la passphrase en el Keychain (macOS)
ssh-add --apple-use-keychain ~/.ssh/<clave_privada>

# En ~/.ssh/config, por cada host con clave con passphrase:
#     UseKeychain yes
#     AddKeysToAgent yes

# Verificar
ssh <host> true        # debe conectar sin pedir passphrase
ssh-add -l             # la clave debe aparecer en el agente
```

## DNS no resuelve desde dispositivos

**Síntoma:** Los dispositivos no navegan, Pi-hole está corriendo.

**Solución:**
```bash
# Verificar que Pi-hole está escuchando
sudo lsof -i :53

# Verificar que el router apunta a la IP del Pi-hole como DNS
# Verificar que el firewall del router permite DNS (puerto 53)
```

## Tag de imagen inexistente o sin arquitectura

**Síntoma:** `Preflight falló: tag inexistente o sin la arquitectura requerida` (o en versiones previas: `compose up` fallaba al hacer pull y el contenedor quedaba stale).

**Causa:** el tag versionado en el `compose.yaml` no existe en el registry o no tiene variante `arm64`.

**Solución:**
```bash
# Verificar manualmente un tag contra su registry
docker manifest inspect <imagen>:<tag>

# Corregir el tag en services/docker/<servicio>/compose.yaml
# y re-ejecutar
bash run.sh yoda --tags preflight
```

## Rate limit de Docker Hub en el preflight

**Síntoma:** `Preflight falló: rate limit del registry (quota agotada)` para imágenes de Docker Hub, con el aviso `toomanyrequests: You have reached your unauthenticated pull rate limit`.

**Causa:** Docker Hub limita a **100 pulls/6h por IP** para uso anónimo. `docker manifest inspect` consume esa quota, y la IP de casa (NAT) la comparte con el RPi, otras máquinas y los `docker compose up`. Al agotarse, el deploy no podría hacer pull de todas formas, así que el preflight falla antes con un mensaje claro.

> [!TIP]
> Si te pasa seguido, autentica el daemon con una cuenta de Docker Hub y se acabó el límite anónimo.

**Solución:**
```bash
# Esperar a que se renueve la ventana de 6 horas
# o autenticar el daemon con una cuenta de Docker Hub (sin límite anónimo)
docker login
```
