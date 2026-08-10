#!/bin/bash

source .env

LIMIT="${1:-all}"

EXTRA=()
[ -n "$TAILSCALE_AUTH_KEY_ANTON" ] && EXTRA+=(-e "TAILSCALE_AUTH_KEY_ANTON=$TAILSCALE_AUTH_KEY_ANTON")

ansible-playbook playbook.yml \
  -i inventory/ \
  --limit "$LIMIT" \
  --ask-become-pass \
  "${@:2}" \
  -e "PIHOLE_PASS=$PIHOLE_PASS" \
  -e "TAILSCALE_AUTH_KEY=$TAILSCALE_AUTH_KEY" \
  -e "GRAFANA_ADMIN_PASSWORD=$GRAFANA_ADMIN_PASSWORD" \
  "${EXTRA[@]}"
