# ⚡ Mi homeserver
Este es mi servidor casero. El repositorio contiene la configuración de mi Raspberry Pi 4 💪

### Esquema ✏️
```mermaid
graph TD
    %% Estilos Profesionales - Slate & Azure
    classDef wan fill:#0f172a,stroke:#1e293b,stroke-width:2px,color:#f8fafc;
    classDef node fill:#ffffff,stroke:#cbd5e1,stroke-width:1px,color:#0f172a;
    classDef vpn fill:#f8fafc,stroke:#64748b,stroke-width:1px,stroke-dasharray: 5 5,color:#475569;
    classDef highlight fill:#f0f9ff,stroke:#0ea5e9,stroke-width:2px,color:#0c4a6e;

    %% 1. WAN (PROVEEDORES)
    subgraph WAN [ ]
        direction LR
        ISP[🌐 Internet / ISP]
        
        subgraph OCI_VM [☁️ Oracle Cloud VM]
            Ollama[🧠 Ollama Service]
        end
    end

    %% 2. CAPA LÓGICA (MESH VPN)
    Tailscale{{"🔐 Tailscale Mesh VPN"}}

    %% 3. INFRAESTRUCTURA LOCAL
    subgraph LAN [Red Local]
        Router[🖧 Router TP-Link]
        subgraph Pi [🍓 Raspberry Pi 4]
            subgraph Docker [🐋 Docker Engine]
                OpenClaw[🤖 OpenClaw]
                PiHole[🛡️ Pi-hole DNS]
                cAdvisor[📊 cAdvisor]
            end
        end
    end

    %% DISPOSITIVOS
    LocalDevices[📱 Dispositivos Hogar]
    RemoteNode[🌐 Dispositivos fuera del hogar]

    %% --- CONEXIONES FÍSICAS ---
    ISP === Router
    Router --- Pi
    Router --- LocalDevices

    %% --- FLUJOS DE RED (CONSOLIDADOS) ---
    %% Registro en la Mesh (Índices 3, 4, 5)
    Pi -.-> Tailscale
    OCI_VM -.-> Tailscale
    RemoteNode -.-> Tailscale
    
    %% Flujo IA: Azul (Índices 6, 7)
    OpenClaw -.->|Inferencia| Tailscale
    Tailscale -.-> OCI_VM
    
    %% Flujo DNS: Verde (Índices 8, 9, 10)
    LocalDevices ==>|Resolución de DNS| PiHole
    RemoteNode -.->|Resolución de DNS| Tailscale
    Tailscale -.->|Resolución de DNS| PiHole

    %% ASIGNACIÓN DE ESTILOS
    class WAN,ISP,OCI_VM wan;
    class Router,Pi,LocalDevices,RemoteNode node;
    class Tailscale vpn;
    class Docker,OpenClaw,PiHole,cAdvisor,Ollama highlight;

    %% COLORES POR FLUJO 
    linkStyle 6,7 stroke:#3b82f6,stroke-width:3px;
    linkStyle 8,9,10 stroke:#10b981,stroke-width:3px;
```

### Configuración de la Raspberry
- SO: Ubuntu 24.04.04 LTS
- Configurar IP estática en `/etc/netplan/`
```yaml
# ip estática
network:
  version: 2
  ethernets:
    eth0:
      dhcp4: no
      addresses:
        - [INTERNAL_IP/24]
      routes:
        - to: default
          via: [INTERNAL_IP]
      nameservers:
        addresses:
          - 1.1.1.1
          - 8.8.8.8
```
- Deshabilitar el uso del puerto 53 en `/etc/systemd/resolved.conf.d`:
```
[Resolve]
DNSStubListener=no
```

- Montar disco duro
  - Ver UUID:
```
lsblk -f
```

Crear carpeta:

```
sudo mkdir -p /mnt/nombre
```

Editar `/etc/fstab` y agregar:

```
UUID=tu-uuid  /mnt/nombre  ext4  defaults,nofail  0  2
```

### Configuración con Ansible

Navegar al directorio `ansible/` y ejecutar:

```bash
cd ansible/
cp .env.example .env  # Configurar credenciales y rutas
bash run.sh
```

El script instala: Docker, utilitarios del sistema y Pi-hole mediante roles de Ansible.

### Variables de entorno

Crear `.env` en el directorio `ansible/`:

```env
PIHOLE_PASS=tu_contraseña
PATH_DATA=/ruta/a/datos
TAILSCALE_AUTH_KEY=tskey-auth-xxxxx
TAILSCALE_HOSTNAME=homeserver
```

### Estructura de directorios

- **ansible/**: Aprovisionamiento de infraestructura mediante roles de Ansible (system-setup, docker, pihole, tailscale)
- **services/docker/**: Configuraciones de Docker Compose con perfiles (dns, dashboard, media-download, media-streaming, infra)
- **config/**: Configuraciones personalizadas (nginx, Sonarr)
- **security/**: Guías de hardening SSH
