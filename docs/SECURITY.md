# 🛡️ Seguridad

## Hardening SSH

Deshabilitar autenticación por contraseña y acceso root.

Editar `/etc/ssh/sshd_config`:

```ini
PasswordAuthentication no
PermitRootLogin no
```

Reiniciar SSH:

```bash
sudo systemctl restart sshd
```

> Asegurarse de tener una clave SSH configurada **antes** de aplicar estos cambios.

## Tailscale

### Autenticación

Usar auth keys desde [Tailscale Admin](https://login.tailscale.com/admin/settings/keys):

- Crear key con `--reusable=false` (una sola autenticación)
- Configurar en `TAILSCALE_AUTH_KEY` en el `.env` de Ansible

### ACLs Recomendadas

En [Tailscale Admin → ACLs](https://login.tailscale.com/admin/acls):

```json
{
  "acls": [
    {"action": "accept", "src": ["*"], "dst": ["*:*"]}
  ]
}
```

> Para un homelab personal, permitir todo entre nodos es aceptable. Para entornos con más usuarios, restringir por tags.

### Subnet Routing (opcional)

Si se necesita acceder a dispositivos de la red local desde fuera:

```bash
sudo tailscale up --advertise-routes=192.168.1.0/24
```

Luego habilitar la ruta en [Tailscale Admin → Subnets](https://login.tailscale.com/admin/machines).

## Firewall

### UFW (si se prefiere)

```bash
sudo ufw allow OpenSSH
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable
```

### Puertos a considerar

| Puerto | Servicio | ¿Exponer? |
|---|---|---|
| 22 | SSH | Solo LAN o Tailscale |
| 53 | DNS | Solo LAN |
| 80, 443 | HTTP/HTTPS | Solo LAN |
| 8096 | Jellyfin | Solo LAN |
| 8082 | Transmission Web UI | Solo LAN |
| 8083 | Prowlarr | Solo LAN |
| 8084 | Sonarr | Solo LAN |
| 51413 | Torrent | Requerido para descargas |

> Recomendación: no exponer puertos directamente a Internet. Usar Tailscale para acceso remoto.
