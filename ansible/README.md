# Ansible — Aprovisionamiento

Referencia completa: [`docs/ANSIBLE.md`](../docs/ANSIBLE.md)

## Inicio rápido

```bash
cp .env.example .env
# Editar .env con tus credenciales
bash run.sh
```

- **Roles, inventario, variables y ejecución** → [`docs/ANSIBLE.md`](../docs/ANSIBLE.md)
- **Secretos** (`PIHOLE_PASS`, `TAILSCALE_AUTH_KEY`): viven en `.env` (gitignored), no en el repo.
