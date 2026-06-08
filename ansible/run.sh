#!/bin/bash

source .env

ansible-playbook playbook.yml \
  -i inventoryHomeServer.ini \
  -e "PIHOLE_PASS=$PIHOLE_PASS" \
  -e "PATH_DATA=$PATH_DATA" \
  -e "TAILSCALE_AUTH_KEY=$TAILSCALE_AUTH_KEY" \
  -e "TAILSCALE_HOSTNAME=$TAILSCALE_HOSTNAME" \
  -k -K -v