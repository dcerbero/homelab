# 🏗️ Arquitectura de Red

## Topología

```mermaid
graph TD
    classDef wan fill:#0f172a,stroke:#1e293b,stroke-width:2px,color:#f8fafc;
    classDef node fill:#ffffff,stroke:#cbd5e1,stroke-width:1px,color:#0f172a;
    classDef vpn fill:#f8fafc,stroke:#64748b,stroke-width:1px,stroke-dasharray: 5 5,color:#475569;
    classDef highlight fill:#f0f9ff,stroke:#0ea5e9,stroke-width:2px,color:#0c4a6e;

    subgraph WAN [ ]
        direction LR
        ISP[🌐 Internet / ISP]
        
        subgraph OCI_VM [☁️ Oracle Cloud VM]
            Ollama[🧠 Ollama Service\nEmbeddings: nomic-embed-text]
        end
    end

    Tailscale{{"🔐 Tailscale Mesh VPN"}}

    subgraph LAN [Red Local]
        Router[🖧 Router]
        subgraph Pi [🍓 Raspberry Pi 4]
            subgraph Docker [🐋 Docker Engine]
                OpenClaw[🤖 OpenClaw]
                Headroom[🗜️ Headroom Proxy]
                PiHole[🛡️ Pi-hole DNS]
                cAdvisor[📊 cAdvisor]
                Heimdall[📋 Heimdall]
                Jellyfin[🎬 Jellyfin]
                Nginx[🌐 nginx Proxy]
                Transmission[⬇️ Transmission]
                Sonarr[📺 Sonarr]
                Prowlarr[🔍 Prowlarr]
            end
        end
    end

    LocalDevices[📱 Dispositivos Hogar]
    RemoteNode[🌐 Dispositivos fuera del hogar]

    ISP === Router
    Router --- Pi
    Router --- LocalDevices

    Pi -.-> Tailscale
    OCI_VM -.-> Tailscale
    RemoteNode -.-> Tailscale
    
    OpenClaw -.->|Embeddings| Tailscale
    Tailscale -.-> OCI_VM
    
    LocalDevices ==>|DNS| PiHole
    RemoteNode -.->|DNS| Tailscale
    Tailscale -.->|DNS| PiHole

    class WAN,ISP,OCI_VM wan;
    class Router,Pi,LocalDevices,RemoteNode node;
    class Tailscale vpn;
    class Docker,OpenClaw,Headroom,PiHole,cAdvisor,Ollama,Heimdall,Jellyfin,Nginx,Transmission,Sonarr,Prowlarr highlight;

    linkStyle 6,7 stroke:#3b82f6,stroke-width:3px;
    linkStyle 8,9,10 stroke:#10b981,stroke-width:3px;
```

## Flujos de Red

### DNS (Verde)
- Todos los dispositivos locales resuelven DNS contra Pi-hole
- Dispositivos remotos via Tailscale → Pi-hole
- Pi-hole upstream: Cloudflare (1.1.1.1) y Google (8.8.8.8)

### IA (Azul)
- **Chat:** OpenClaw → Headroom (proxy :8787, comprime contexto) → DeepSeek API
- **Embeddings:** OpenClaw vía Tailscale → Ollama (nomic-embed-text) en Oracle Cloud
- Procesamiento local, modelos remotos

### VPN (Discontinuo)
- Tailscale mesh VPN conecta: Raspberry Pi, Oracle Cloud VM, dispositivos remotos
- Subnet routing para acceso a red local desde fuera

## Puertos Expuestos

| Puerto | Servicio | Acceso |
|---|---|---|
| 53 (TCP/UDP) | Pi-hole DNS | Local |
| 80 | nginx (Heimdall, OpenClaw) | Local |
| 443 | nginx HTTPS | Local |
| 8096 | Jellyfin | Local |
| 8082 | Transmission Web UI | Local |
| 8083 | Prowlarr | Local |
| 8084 | Sonarr | Local |
| 51413 (TCP/UDP) | Transmission Torrent | Local |
