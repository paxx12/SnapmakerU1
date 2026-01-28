#!/bin/bash

if [[ $# -ne 2 ]]; then
  echo "usage: $0 <user@ip> <profile>"
  exit 1
fi

SSH_HOST="$1"
PROFILE="$2"
shift 2

set -xe

# this will remove any old host fingerprints for the host being updated
# and will quickly connect to it to allow the user to confirm the new fingerprint
# this avoids any ssh prompts during the build and upgrade process (if the user has an ssh key setup)
# this is inherently unsafe, so should only be used in controlled environments
ssh-keygen -f /root/.ssh/known_hosts -R $SSH_HOST
ssh $SSH_HOST exit

rm -rf "firmware/firmware_$PROFILE.bin" "tmp/firmware"
make build OUTPUT_FILE=firmware/firmware_$PROFILE.bin PROFILE="$PROFILE"
scp "tmp/firmware/update.img" "$SSH_HOST:/tmp/"
ssh "$SSH_HOST" /home/lava/bin/systemUpgrade.sh upgrade soc /tmp/update.img
