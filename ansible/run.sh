#!/bin/bash

source .env

ansible-playbook playbook.yml \
  -i inventoryHomeServer.ini \
  -e "PIHOLE_PASS=$PIHOLE_PASS" \
  -e "PATH_DATA=$PATH_DATA" \
  -k -K -v