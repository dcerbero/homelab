# 🛠️ Setup Inicial de la Raspberry Pi

## Requisitos

- Raspberry Pi 4 con Ubuntu 24.04 LTS instalado
- Acceso SSH o físico a la terminal
- SSD USB como disco de arranque (datos persistentes en `$PATH_DATA`)

## 1. Configurar IP Estática

Editar `/etc/netplan/`:

```yaml
network:
  version: 2
  ethernets:
    eth0:
      dhcp4: no
      addresses:
        - 192.168.1.100/24
      routes:
        - to: default
          via: 192.168.1.1
      nameservers:
        addresses:
          - 1.1.1.1
          - 8.8.8.8
```

> Reemplazar `192.168.1.100` con la IP deseada y `192.168.1.1` con tu gateway.

Aplicar:

```bash
sudo netplan apply
```

## 2. Deshabilitar DNS Stub Listener

Pi-hole necesita el puerto 53 libre. systemd-resolved lo ocupa por defecto.

> El rol Ansible `system-setup` automatiza este paso. El procedimiento manual de abajo solo aplica si provisionas sin Ansible.

Crear `/etc/systemd/resolved.conf.d/dns.conf`:

```ini
[Resolve]
DNSStubListener=no
```

Reiniciar:

```bash
sudo systemctl restart systemd-resolved
```

Verificar que el puerto 53 esté libre:

```bash
sudo lsof -i :53
```

## 3. Datos Persistentes (`PATH_DATA`)

Los datos de servicios viven en `$PATH_DATA`, variable definida por máquina en `ansible/inventory/host_vars/<host>.yml`.

> En la Pi no hay un disco de datos separado: el SSD USB es el disco de arranque (root + boot), así que `$PATH_DATA` es una carpeta dentro del root del sistema. Con suficiente espacio libre en el root, no hace falta particionar ni montar nada.

El esqueleto (`$PATH_DATA/persistence` y `$PATH_DATA/media/{downloads,movies,tvseries,watch}`) lo crea Ansible automáticamente (rol `system-setup`) con ownership `1000:1000`.

Si más adelante quieres mover los datos a un disco dedicado: formatea, monta el disco en `/mnt/data`, agrega la línea al `/etc/fstab` y cambia `PATH_DATA` en `host_vars`:

```text
UUID=tu-uuid-aqui  /mnt/data  ext4  defaults,nofail  0  2
```

> `nofail` evita que el sistema no arranque si el disco no está presente.

## 4. Siguiente Paso

Una vez lista la Raspberry, aprovisionar con Ansible:

```bash
cd ansible/
cp .env.example .env
# Editar .env con tus valores
bash run.sh
```

Ver [`ANSIBLE.md`](ANSIBLE.md) para detalles.
