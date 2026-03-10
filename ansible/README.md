# Ansible Configuration

Automates Ubuntu server provisioning for the homelab infrastructure.

## Quick Start

```bash
cp .env.example .env
# Edit .env with your credentials and paths
bash run.sh
```

## Roles

| Role | Purpose |
|------|---------|
| `system-setup` | OS packages, networking, disk mounting |
| `docker` | Docker & Docker Compose installation |
| `pihole` | Pi-hole DNS container setup |
| `tailscale` | Tailscale VPN configuration and setup |

## Playbook

**File:** `playbook.yml`

Executes all roles in sequence on the `homeserver` inventory with `become: true` (sudo).

## Inventory

**File:** `inventoryHomeServer.ini` (gitignored for security)

```ini
[homeserver]
<SERVER_IP> ansible_user=<USERNAME>
```

**Example:**
```ini
[homeserver]
192.168.x.x ansible_user=ubuntu
```

## Variables

**File:** `.env` (locally sourced by `run.sh`)

```env
PIHOLE_PASS=your_pihole_password
PATH_DATA=/mnt/data  # Persistent storage mount point
TAILSCALE_AUTH_KEY=tskey-auth-xxxxx  # Auth key from Tailscale admin console
TAILSCALE_HOSTNAME=homelab-server  # Custom hostname for the device in Tailscale
```

## Execution

```bash
bash run.sh
```

Prompts for SSH password (`-k`) and sudo password (`-K`). Runs in verbose mode (`-v`).
