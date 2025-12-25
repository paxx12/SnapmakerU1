#!/bin/bash

if [[ $# -lt 2 ]]; then
  echo "usage: $0 <user@ip> <profile> [DEVEL=0|1]"
  exit 1
fi

SSH_HOST="$1"
PROFILE="$2"
case "${3,,}" in
  devel|devel=1|devel=true) DEVEL=1 ;;
  *) DEVEL=0 ;;
esac
shift 2

set -xe

rm -rf "firmware/firmware_$PROFILE.bin" "tmp/firmware"
make build OUTPUT_FILE=firmware/firmware_$PROFILE.bin PROFILE="$PROFILE" DEVEL="$DEVEL"
scp "tmp/firmware/update.img" "$SSH_HOST:/tmp/"
ssh "$SSH_HOST" /home/lava/bin/systemUpgrade.sh upgrade soc /tmp/update.img