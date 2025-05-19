# ⚡ My small homelab 
This is my small homelab. The repository contains the configuration of my Raspberry Pi 4 server 💪

### Eschema ✏️
![Alt text](assets/homelab.drawio.png)

### configure environment file .env ⚙️
```
PIHOLE_PASS=yourpass
```

### 📁 Config Folder 
- 📁 noTranscodig: This folder contains a custom format for Sonarr that avoids downloading videos which would require transcoding on a Raspberry Pi 4.

### Config raspberry
- SO: Ubuntu 24.04.2 LTS
- Configure static ip in (/etc/netplan/), and desactivate dns service
```yaml
# static ip
network:
  version: 2
  ethernets:
    eth0:
      dhcp4: true
      addresses:
        - your-ip/24
      routes:
        - to: default
          via: your-gateway
      nameservers:
        addresses:
          - 1.1.1.1
          - 8.8.8.8
```
- Mount hdd
    - View uuid
```
lsblk -f
```

Create folder 

```
sudo mkdir -p /mnt/name
```

Edit file fstab in /etc/ and add:

```
UUID=your-uuid  /mnt/name  ext4  defaults,nofail  0  2
```