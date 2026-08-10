# 🛠️ Setup Inicial de las Máquinas

Configuración bare-metal de una sola vez, previa al aprovisionamiento con Ansible. Cubre la Raspberry Pi ([yoda](HARDWARE.md#yoda)) y los discos del servidor media ([anton](HARDWARE.md#anton)).

## Índice

- [Setup de la Raspberry Pi](#setup-de-la-raspberry-pi)
- [Discos de anton — RAID1 media](#5-discos-de-anton--raid1-media)

---

# Setup de la Raspberry Pi

La primera vez que la Pi llega a casa hay que dejarla con IP fija, DNS libre y el sistema listo para que Ansible haga lo suyo. Es un trabajo de una sola vez, pero bien hecho evita sorpresas después.

- [Requisitos](#requisitos)
- [1. Configurar IP Estática](#1-configurar-ip-estática)
- [2. Deshabilitar DNS Stub Listener](#2-deshabilitar-dns-stub-listener)
- [3. Datos Persistentes (`PATH_DATA`)](#3-datos-persistentes-path_data)
- [4. Siguiente Paso](#4-siguiente-paso)

## Requisitos

- Raspberry Pi 4 con Ubuntu 24.04 LTS instalado
- Acceso SSH o físico a la terminal
- SSD USB como disco de arranque (datos persistentes en `$PATH_DATA`)

## 1. Configurar IP Estática

Queremos que la Pi siempre tenga la misma IP en la red local, para que el resto de servicios la encuentren sin sorpresas.

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

> [!NOTE]
> Reemplazar `192.168.1.100` con la IP deseada y `192.168.1.1` con tu gateway.

Aplicar:

```bash
sudo netplan apply
```

## 2. Deshabilitar DNS Stub Listener

Pi-hole necesita el puerto 53 libre. systemd-resolved lo ocupa por defecto, así que hay que apartarlo para dejarle el sitio.

> [!NOTE]
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

> [!TIP]
> `nofail` evita que el sistema no arranque si el disco no está presente — importante cuando el disco de datos no es el de arranque.

## 4. Siguiente Paso

Una vez lista la Raspberry, aprovisionar con Ansible:

```bash
cd ansible/
cp .env.example .env
# Editar .env con tus valores
bash run.sh
```

Ver [`ANSIBLE.md`](ANSIBLE.md) para detalles.

---

# 5. Discos de anton — RAID1 media

anton es el servidor media. El disco de sistema (**sda**, Seagate 2.5" con 221k load/unload cycles) se trata como **descartable**: solo SO, Docker y swap. Todos los datos de servicios viven en el **RAID1** de los dos WD Green, montado en `/server` (que es `PATH_DATA`). Si sda muere o se cambia: reinstalar + `bash run.sh`, y el array se re-ensambla solo — cero pérdida de datos.

## Layout

```text
/dev/md0 RAID1 (sdb1 + sdc1, ext4)  →  /server/   (persistence/ + media/*)
sda (Seagate ST1000LM035)           →  SO + Docker + swap  (descartable)
```

`PATH_DATA=/server` (igual que [yoda](HARDWARE.md#yoda) y [talos](HARDWARE.md#talos)), así que los `compose.yaml` no cambian: `${PATH_DATA}/media/*` cae dentro del mount del array.

## Configuración aplicada (2026-08-10)

| Aspecto | Valor |
|---|---|
| RAID | `mdadm` nivel 1, metadata 1.2, array `media:media` (`/dev/md127`, symlink `/dev/md/media`) |
| Miembros | `/dev/sdb1` + `/dev/sdc1` (GPT, 1 partición tipo `fd00` cada uno, alineación 2048 sectores) |
| Filesystem | ext4, `-m 0` (sin bloques reservados → **916G útiles**) |
| fstab | `UUID=<del array>  /server  ext4  defaults,noatime,commit=600,nofail  0  2` |
| Auto-ensamblaje | `ARRAY /dev/md/media ...` por UUID en `/etc/mdadm/mdadm.conf` + `update-initramfs -u` |
| Resync inicial | doble burn-in de superficie (~3–4h en background, retomable por bitmap tras reboot) |
| Head-park WD Green | `idle3ctl -d /dev/sdb /dev/sdc` (desactiva el timer idle3 en el **firmware**; los EADS no soportan APM, por eso no vale `hdparm -B`) |
| Ownership | `/server` completo con `1000:1000` (esqueleto que crea Ansible `system-setup`) |

> [!NOTE]
> `idle3ctl -d` queda grabado en el firmware del disco, pero solo se activa tras un **apagado/encendido real** (power cycle) del equipo, no con un simple reboot.

## Comandos de mantenimiento

```bash
cat /proc/mdstat                                   # estado del array / progreso
mdadm --detail /dev/md127                          # salud de los miembros
echo check > /sys/block/md127/md/sync_action       # verifica integridad de ambos espejos (read-only)
smartctl -a /dev/sdb                               # salud SMART
smartctl -t long /dev/sdb                          # burn-in de superficie (~4.5h, en background)
```

## Qué NO hacer

- No particionar/formatear sdb o sdc fuera de este layout: romperías el array.
- No quitar `nofail` de la línea fstab: si el array no ensambla, el sistema debe arrancar igualmente.
- Si algún día se reemplaza un WD Green: repetir `idle3ctl -d` en el disco nuevo, verificar el rebuild con `mdadm --detail` y confirmar estado `clean` al terminar.
