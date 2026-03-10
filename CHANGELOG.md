# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [Unreleased]

### Added
- Ansible automation with 4 roles (system-setup, docker, pihole, tailscale)
- Tailscale VPN role for secure remote access
- Ansible run script for simplified provisioning
- Ansible README documentation
- Docker Compose profiles for modular deployments (dns, dashboard, media-download, media-streaming, infra)
- Pi-hole healthcheck and dnsmasq volume persistence
- Explicit DNS configuration to prevent bootstrap loops

### Changed
- Updated pihole image to 2026.02.0 (stable LTS)
- Refactored playbook.yaml → playbook.yml (naming convention)
- Improved .gitignore (removed redundancy, better coverage)
- Simplified documentation (technical, English)
- Updated architecture diagram to include Tailscale VPN

### Security
- Added .env and *.ini to .gitignore
- Added .claude/ to .gitignore
- Removed binary assets from repo (installDocker.png)
- Sanitized documentation (removed hardcoded IPs/usernames)
- Enabled Tailscale for secure remote access
