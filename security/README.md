# 🛡️ Principios de seguridad

### 👮🏻‍♂️ Acceso SSH deshabilitado por contraseña, solo con clave
```bash
sudo nano /etc/ssh/sshd_config
PasswordAuthentication no
PermitRootLogin no
```
