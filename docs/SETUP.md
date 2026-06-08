# 🛠️ Setup Inicial de la Raspberry Pi

## Requisitos

- Raspberry Pi 4 con Ubuntu 24.04 LTS instalado
- Acceso SSH o físico a la terminal
- Disco duro externo para datos persistentes

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

## 3. Montar Disco Duro

Listar discos y obtener UUID:

```bash
lsblk -f
```

Crear punto de montaje:

```bash
sudo mkdir -p /mnt/data
```

Agregar a `/etc/fstab`:

```
UUID=tu-uuid-aqui  /mnt/data  ext4  defaults,nofail  0  2
```

Montar:

```bash
sudo mount -a
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
