#!/bin/bash
#
# Remove fluidd nginx site to be replaced by mainsail
# Fails if fluidd symlink doesn't exist (to catch firmware changes)
#

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <rootfs-dir>"
  exit 1
fi

ROOTFS="$1"
FLUIDD_SITE="$ROOTFS/etc/nginx/sites-enabled/fluidd"

if [[ ! -L "$FLUIDD_SITE" ]]; then
  echo "!! ERROR: $FLUIDD_SITE is not a symlink"
  echo ">> Firmware structure may have changed"
  exit 1
fi

echo ">> Removing fluidd site symlink"
rm "$FLUIDD_SITE"
