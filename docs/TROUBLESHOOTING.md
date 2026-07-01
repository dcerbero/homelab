# 🔧 Solución de Problemas

## Puerto 53 en uso

**Síntoma:** Pi-hole no arranca, error `port already in use`.

**Causa:** systemd-resolved está usando el puerto 53.

**Solución:**
```bash
# Verificar qué proceso usa el puerto
sudo lsof -i :53

# Deshabilitar DNS stub listener
echo "[Resolve]
DNSStubListener=no" | sudo tee /etc/systemd/resolved.conf.d/dns.conf
sudo systemctl restart systemd-resolved
```

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

**Síntoma:** `fatal: [homeserver]: UNREACHABLE!`

**Solución:**
```bash
# Verificar conectividad
ssh ubuntu@<IP_SERVIDOR>

# Verificar inventario
cat ansible/inventoryHomeServer.ini

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
