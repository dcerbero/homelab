#!/bin/bash

source .env

LIMIT="${1:-all}"

ansible-playbook playbook.yml \
  -i inventory/ \
  --limit "$LIMIT" \
  -e "PIHOLE_PASS=$PIHOLE_PASS" \
  -e "TAILSCALE_AUTH_KEY=$TAILSCALE_AUTH_KEY" \
  -v
