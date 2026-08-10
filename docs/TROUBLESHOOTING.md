# 🔧 Solución de Problemas

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

**Síntoma:** `fatal: [yoda]: UNREACHABLE!`

**Solución:**
```bash
# Verificar conectividad
ssh <username>@<ip_yoda>

# Verificar inventario
cat ansible/inventory/yoda.yml

# Verificar que la IP y usuario sean correctos
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

**Solución:**
```bash
# Esperar a que se renueve la ventana de 6 horas
# o autenticar el daemon con una cuenta de Docker Hub (sin límite anónimo)
docker login
```
