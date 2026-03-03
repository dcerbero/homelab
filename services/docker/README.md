# Docker Compose Services Deployment

Este README explica cómo desplegar los servicios del homelab usando Docker Compose profiles.

## 📋 Profiles disponibles

El repositorio está organizado en **5 profiles independientes**:

| Profile | Servicios | Descripción |
|---------|-----------|-------------|
| `dns` | Pi-hole | Servidor DNS/bloqueador de anuncios |
| `dashboard` | Heimdall | Panel de control del homelab |
| `media-streaming` | Jellyfin | Servidor de streaming multimedia |
| `media-download` | Transmission, Prowlarr, Sonarr | Descarga y gestión de contenido |
| `infra` | nginx, cAdvisor | Infraestructura (proxy reverso, monitorización) |

---

## 🚀 Uso de profiles

### **Levantar un profile específico**
```bash
docker compose --profile dns up -d
```

### **Levantar múltiples profiles**
```bash
docker compose --profile dns --profile dashboard up -d
docker compose --profile media-streaming --profile media-download up -d
```

### **Levantar todos los servicios**
```bash
docker compose up -d
```

### **Detener servicios**
```bash
docker compose down
docker compose --profile dns down  # solo dns
```

---

## 📦 Configuración del entorno

Antes de desplegar, asegúrate de que existe un archivo `.env` en la raíz del repositorio con:

```env
PIHOLE_PASS=tu_contraseña_pihole
PATH_DATA=/ruta/a/tus/datos
```

---

## 🔧 Combinaciones de despliegue comunes

### **Mínimo (solo esenciales)**
```bash
docker compose --profile dns --profile dashboard --profile infra up -d
```
Levanta: Pi-hole + Heimdall + nginx + cAdvisor

### **Streaming únicamente**
```bash
docker compose --profile media-streaming up -d
```
Levanta: Jellyfin

### **Descarga y organización**
```bash
docker compose --profile media-download up -d
```
Levanta: Transmission + Prowlarr + Sonarr

### **Todo el homelab multimedia**
```bash
docker compose --profile media-streaming --profile media-download up -d
```
Levanta: Jellyfin + Transmission + Prowlarr + Sonarr

### **Instalación completa (producción)**
```bash
docker compose up -d
```
Levanta: todos los servicios

---

## 📝 Puertos por profile

| Profile | Servicio | Puerto | Descripción |
|---------|----------|--------|-------------|
| dns | Pi-hole | 53 | DNS (TCP/UDP) |
| dns | Pi-hole | 8081 | UI |
| dashboard | Heimdall | 80 | Interfaz (vía nginx) |
| media-streaming | Jellyfin | host | Red en host |
| media-download | Transmission | 8082 | UI |
| media-download | Transmission | 51413 | Torrent (TCP/UDP) |
| media-download | Prowlarr | 8083 | API de indexadores |
| media-download | Sonarr | 8084 | Gestión de series |
| infra | nginx | 80, 443 | Proxy reverso |
| infra | cAdvisor | 8085 | Monitorización |

---

## 🛑 Gestión de servicios

### **Ver logs**
```bash
docker compose logs -f svcPihole
docker compose logs -f --all  # todos
```

### **Ejecutar comando en contenedor**
```bash
docker compose exec svcPihole bash
```

### **Ver estado**
```bash
docker compose ps
```

### **Reiniciar un servicio**
```bash
docker compose restart svcSonarr
```

---

## 📁 Estructura de directorios

```
services/docker/
├─ compose.yaml           (principal con includes)
├─ core/
│  ├─ heimdall.yaml      (dashboard profile)
│  └─ pihole.yaml        (dns profile)
├─ media/
│  ├─ transmission.yaml  (media-download profile)
│  ├─ prowlarr.yaml      (media-download profile)
│  ├─ sonarr.yaml        (media-download profile)
│  └─ jellyfin.yaml      (media-streaming profile)
├─ infra/
│  ├─ cadvisor.yaml      (infra profile)
│  └─ nginx.yaml         (infra profile)
└─ README.md             (este archivo)
```

---

## ⚙️ Variables de entorno

Todas las rutas de datos se configuran a través de la variable `PATH_DATA` en `.env`:

```
${PATH_DATA}/
├─ heimdall/config
├─ pihole/etc-pihole-v2
├─ transmission/config
├─ media/
│  ├─ downloads
│  ├─ tvseries
│  ├─ movies
│  └─ watch
├─ sonarr/data
├─ prowlarr/
├─ jellyfin/library
└─ compose/homelab/config/nginx/conf.d
```

---

## 🐛 Troubleshooting

### **Puerto ya en uso**
```bash
sudo lsof -i :53  # ver qué ocupa el puerto DNS
```

### **Contenedor no se levanta**
```bash
docker compose logs svcPihole  # ver errores
```

### **Permisos de volúmenes**
```bash
sudo chown -R 1000:1000 ${PATH_DATA}
```

---

## 📚 Documentación adicional

- Ver [README.md](../../README.md) para la arquitectura general
- Ver [security/README.md](../../security/README.md) para configuración de seguridad
- Ver [utility-command.md](../../utility-command.md) para comandos útiles
