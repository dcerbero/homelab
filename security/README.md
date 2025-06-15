# 🛡️ Security basics

### 👮🏻‍♂️ Disabled password access, SSH key only
```bash
sudo nano /etc/ssh/sshd_config
PasswordAuthentication no
PermitRootLogin no
```