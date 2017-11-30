#!/bin/bash

set -e

get_private_ip () {
  PRIVATE_IP="$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)"
  if [ $? != 0 ]; then
    # hostname -I returns all IP addresses available in the server, grep will return the first private IP found
    PRIVATE_IP="$(hostname -I | tr ' ' '\n' | grep -m 1 -E '^(192\.168|10\.|172\.1[6789]\.|172\.2[0-9]\.|172\.3[01]\.)')"
  fi

  echo $PRIVATE_IP
  return 0
}

# Config /etc/teleport

## Get private IP for advertise_ip
export ADVERTISE_IP=$(get_private_ip)

## Get instance ID (if possible)
${include_instance_id == "true" ? "export INSTANCE_ID=-$(curl -s http://169.254.169.254/latest/meta-data/instance-id)" : ""}

## Set the rest of the config
export AUTH_TOKEN=${auth_token}
export AUTH_SERVER=${auth_server}
export NODENAME=${function}${project}${environment}$INSTANCE_ID

envsubst < "/etc/teleport.yaml" > "/etc/teleport_new.yaml"
mv /etc/teleport_new.yaml /etc/teleport.yaml

# Enable teleport service
sudo systemctl enable teleport.service

# Start teleport service
sudo systemctl start teleport.service
