# 🛡️ Seguridad

La regla de oro de este homelab: **nada sale a Internet sin pasar por Tailscale**. Aquí está el resumen de lo que cerramos para que las cosas sigan funcionando en casa sin invitar a curiosos.

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

> [!WARNING]
> Asegurarse de tener una clave SSH configurada **antes** de aplicar estos cambios, o te quedas fuera de tu propia máquina.

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

> [!NOTE]
> Para un homelab personal, permitir todo entre nodos es aceptable. Para entornos con más usuarios, restringir por tags.

### Subnet Routing (opcional)

Si se necesita acceder a dispositivos de la red local desde fuera:

```bash
sudo tailscale up --advertise-routes=<tu_subred>
```

Luego habilitar la ruta en [Tailscale Admin → Subnets](https://login.tailscale.com/admin/machines).

## Hermes Agent

Hermes es el único servicio del stack que procesa texto no confiable (páginas web, mensajes) y actúa sobre él. Su diseño limita el daño por construcción:

- **Sin `docker.sock`.** El contenedor no puede crear, borrar ni inspeccionar contenedores. El socket de Docker es **root equivalente** en el host ([doc oficial](https://docs.docker.com/engine/security/protect-access/)): si algún día se monta, esta sección deja de ser válida.
- **Sin acceso al repo ni al host.** Sólo escribe en `$PATH_DATA/persistence/hermes`.
- **Dashboard en `9119` con basic auth obligatorio.** La imagen falla cerrado si el bind no es loopback y no hay proveedor de auth; `HERMES_DASHBOARD_INSECURE` ya es un no-op. No se publica a Internet: sólo LAN/Tailscale.
- **Límite de memoria de 2 GB** para que no pueda asfixiar a Pi-hole en yoda.

Riesgo residual aceptado: el puerto `9119` es **HTTP en claro**. El password del dashboard viaja legible dentro de la LAN. Si eso importa, ponerlo detrás de TLS (certificado propio en nginx) o acceder sólo por Tailscale.

Nota sobre prompt injection: el agente no distingue una instrucción tuya de un texto malicioso en una web. Por eso no tiene root ni socket: en el peor caso, lo que puede tocar es su propio volumen y sus conversaciones.

## Firewall

### UFW (si se prefiere)

```bash
sudo ufw allow OpenSSH
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable
```

### Puertos a considerar

La tabla de puertos expuestos y su alcance de acceso está en [`ARCHITECTURE.md`](ARCHITECTURE.md) (sección "Puertos Expuestos"). Regla general: no exponer puertos directamente a Internet; usar Tailscale para acceso remoto.
