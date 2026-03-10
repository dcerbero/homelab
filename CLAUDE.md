# Homeserver — RPi4, Ubuntu 24.04, Ansible + Docker

## Comportamiento
- Conciso y objetivo. Cuestionar si hay mejor alternativa.
- Explicar el por qué de cada decisión técnica.

## Estructura
- Docker env: generado por Ansible desde `ansible/.env`
- Entry point Ansible: `bash ansible/run.sh`

## Gotchas
- Port 53: deshabilitar `systemd-resolved` stub primero
- Usar imágenes ARM64 siempre
- Inventory y `.env` gitignored — crearlos localmente antes de provisionar