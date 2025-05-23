# ⚡ My small homelab 
This is my small homelab. The repository contains the configuration of my Raspberry Pi 4 server 💪

### Eschema ✏️
![Alt text](assets/homelab.drawio.png)

### Config raspberry
- SO: Ubuntu 24.04.2 LTS
- Configure static ip in (/etc/netplan/)
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
- Disable the use of port 53:
In /etc/systemd/resolved.conf.d
```
[Resolve]
DNSStubListener=no
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

### Install docker with Ansible
![Alt text](assets/installDocker.png)

```bash
ansible-playbook playbook.yaml -i inventoryHomeServer.ini -K
```
Flag -K: Request sudo password from the user via terminal

### configure environment file .env ⚙️
```
PIHOLE_PASS=yourpass
```

### 📁 Config Folder 
- 📁 noTranscodig: This folder contains a custom format for Sonarr that avoids downloading videos which would require transcoding on a Raspberry Pi 4.