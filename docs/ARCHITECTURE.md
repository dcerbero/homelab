# 🏗️ Arquitectura de Red

Cómo se conectan nuestras máquinas entre sí y con el mundo. La idea de fondo es simple: todo lo importante vive en casa, la nube cubre las espaldas y nada se expone a Internet sin pasar por Tailscale.

## Índice

- [Topología](#topología)
- [Flujos de Red](#flujos-de-red)
- [Puertos Expuestos](#puertos-expuestos)

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

        subgraph OCI_VM [☁️ talos — Oracle Cloud VM]
            OciPiHole[🛡️ Pi-hole failover]
        end
    end

    Tailscale{{"🔐 Tailscale Mesh VPN"}}

    subgraph LAN [Red Local]
        Router[🖧 Router]
        subgraph Pi [🍓 yoda — Raspberry Pi 4]
            subgraph DockerYoda [🐋 Docker Engine]
                PiHole[🛡️ Pi-hole DNS]
                Heimdall[📋 Heimdall]
                Nginx[🌐 nginx Proxy]
                YodaCAdvisor[📊 cAdvisor]
                YodaNodeExp[🖥️ node-exporter]
                Hermes[🤖 Hermes Agent]
            end
        end
        subgraph Media [🎬 anton — Equipo x86_64 (apagado)]
            subgraph DockerAnton [🐋 Docker Engine]
                Jellyfin[🎬 Jellyfin]
                Transmission[⬇️ Transmission]
                Prowlarr[🔍 Prowlarr]
                FlareSolverr[🧩 FlareSolverr]
                Sonarr[📺 Sonarr]
                Radarr[🎞️ Radarr]
                Bazarr[💬 Bazarr]
                Seerr[📨 Seerr]
                AntCAdvisor[📊 cAdvisor]
                AntNodeExp[🖥️ node-exporter]
                Smartctl[💾 smartctl-exporter]
            end
        end
    end

    LocalDevices[📱 Dispositivos Hogar]
    RemoteNode[🌐 Dispositivos fuera del hogar]

    ISP === Router
    Router --- Pi
    Router --- Media
    Router --- LocalDevices

    Pi -.-> Tailscale
    Media -.-> Tailscale
    OCI_VM -.-> Tailscale
    RemoteNode -.-> Tailscale

    LocalDevices ==>|DNS| PiHole
    RemoteNode -.->|DNS| Tailscale
    Tailscale -.->|DNS| PiHole

    Seerr -.->|peticiones| Sonarr
    Seerr -.->|peticiones| Radarr
    Sonarr -.->|grab| Transmission
    Radarr -.->|grab| Transmission
    Sonarr -.->|search| Prowlarr
    Radarr -.->|search| Prowlarr
    Prowlarr -.->|Cloudflare| FlareSolverr
    Bazarr -.->|subtítulos| Jellyfin

    class WAN,ISP,OCI_VM wan;
    class Router,Pi,Media,LocalDevices,RemoteNode node;
    class Tailscale vpn;
    class DockerYoda,DockerAnton,PiHole,Heimdall,Nginx,OciPiHole,Jellyfin,Transmission,Prowlarr,Sonarr,Radarr,Bazarr,Seerr,FlareSolverr,YodaCAdvisor,YodaNodeExp,AntCAdvisor,AntNodeExp,Smartctl,Hermes highlight;
```

> [!NOTE]
> [anton](HARDWARE.md#anton) está **apagado desde el 2026-11-24** (temporal): sus nodos siguen en el diagrama como estado deseado, pero no están en línea. Su IP `192.168.0.3` pasó a [yoda](HARDWARE.md#yoda).

## Flujos de Red

Resumen de cómo se mueve el tráfico entre los servicios.

### DNS (Verde)
- Todos los dispositivos locales resuelven DNS contra **Pi-hole de [yoda](HARDWARE.md#yoda)** (primario); [talos](HARDWARE.md#talos) es el **failover**.
- Dispositivos remotos via Tailscale → Pi-hole.
- Pi-hole upstream: Quad9 (9.9.9.9) y Cloudflare Family (1.1.1.2).

### HTTP / Web
- **nginx** ([yoda](HARDWARE.md#yoda)) es la única entrada HTTP (puerto 80): Heimdall (`/`) y Pi-hole (`/pihole`, `/admin/`).
- El resto de servicios publica sus puertos solo a **LAN/Tailscale** (ver [Puertos Expuestos](#puertos-expuestos)).

### IA (Hermes Agent)
- **Hermes** ([yoda](HARDWARE.md#yoda), puerto `9119`) no entra por nginx: se consume directo desde la LAN/Tailscale con basic auth.
- Sale a Internet hacia la API del proveedor de modelo (`opencode-go`). **No** tiene acceso al daemon de Docker ni al repo: no crea contenedores ni despliega nada.

### Media (descarga → biblioteca)
> Todo este flujo está **detenido** mientras [anton](HARDWARE.md#anton) siga apagado.

- **Seerr** recibe las peticiones → las envía a **Sonarr/Radarr**.
- Sonarr/Radarr buscan en los indexadores de **Prowlarr** (FlareSolverr solo para los protegidos por Cloudflare), eligen release y lo envían a **Transmission**.
- Al completar, Sonarr/Radarr importan con hardlink a la biblioteca; **Jellyfin** la sirve; **Bazarr** descarga los subtítulos. Detalle en [`media/README.md`](media/README.md).

### VPN
- Tailscale mesh VPN conecta: [yoda](HARDWARE.md#yoda), [talos](HARDWARE.md#talos), dispositivos remotos y [anton](HARDWARE.md#anton) cuando está encendido (apagado desde 2026-11-24).

### Métricas (en pausa)
- **No hay Prometheus ni Grafana desplegados.** El stack vivía en [talos](HARDWARE.md#talos) y se retiró de su play de Ansible: talos quedó solo con Pi-hole.
- Los **exporters siguen definidos**: node-exporter y cAdvisor en [yoda](HARDWARE.md#yoda) (y en [anton](HARDWARE.md#anton) cuando vuelva), más smartctl-exporter en anton. Están accesibles por LAN/Tailscale, pero **nadie los scrapea** y con anton apagado sus exporters no responden.
- El código y la configuración siguen en el repo (`ansible/roles/monitoring`, `services/docker/{prometheus,grafana}`) para reubicar el stack. Estado, consecuencias y pasos de reactivación en [`MONITORING.md`](MONITORING.md).

## Puertos Expuestos

| Puerto | Servicio | Máquina | Acceso |
|---|---|---|---|
| 22 | SSH | todas | Solo LAN o Tailscale |
| 53 (TCP/UDP) | Pi-hole DNS | [yoda](HARDWARE.md#yoda), [talos](HARDWARE.md#talos) | Local |
| 80 | nginx (Heimdall, Pi-hole) | [yoda](HARDWARE.md#yoda) | Local |
| 443 | nginx HTTPS | [yoda](HARDWARE.md#yoda) | Local |
| 8082 | Transmission Web UI | [anton](HARDWARE.md#anton) | LAN/Tailscale |
| 8083 | Prowlarr | [anton](HARDWARE.md#anton) | LAN/Tailscale |
| 8084 | Sonarr | [anton](HARDWARE.md#anton) | LAN/Tailscale |
| 8085 | Pi-hole Web admin | [yoda](HARDWARE.md#yoda), [talos](HARDWARE.md#talos) | LAN/Tailscale |
| 8085 | Radarr | [anton](HARDWARE.md#anton) | LAN/Tailscale |
| 8086 | Bazarr | [anton](HARDWARE.md#anton) | LAN/Tailscale |
| 8087 | Seerr | [anton](HARDWARE.md#anton) | LAN/Tailscale |
| 8096 | Jellyfin | [anton](HARDWARE.md#anton) | LAN/Tailscale |
| 51413 (TCP/UDP) | Transmission Torrent | [anton](HARDWARE.md#anton) | LAN/Tailscale |
| 9100 | node-exporter | [yoda](HARDWARE.md#yoda), [anton](HARDWARE.md#anton) | Solo LAN o Tailscale |
| 9101 | cAdvisor | [yoda](HARDWARE.md#yoda), [anton](HARDWARE.md#anton) | Solo LAN o Tailscale |
| 9119 | Hermes Agent (dashboard) | [yoda](HARDWARE.md#yoda) | Solo LAN o Tailscale (basic auth) |
| 9633 | smartctl-exporter | [anton](HARDWARE.md#anton) | Solo LAN o Tailscale |

> [!NOTE]
> Los puertos de [anton](HARDWARE.md#anton) (8082–8096, 51413, 9633) no están escuchando mientras el equipo esté apagado. Su IP `192.168.0.3` ahora pertenece a [yoda](HARDWARE.md#yoda).
