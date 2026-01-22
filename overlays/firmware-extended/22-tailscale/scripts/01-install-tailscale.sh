#!/bin/bash

ROOT_DIR="$(realpath "$(dirname "$0")/../../../..")"

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <rootfs-dir>"
  exit 1
fi

set -eo pipefail

TARGET_DIR="$ROOT_DIR/tmp"

# New versions can be found at:
# https://pkgs.tailscale.com/stable/#static
# Tailscale shares SHA at $ curl "${URL}.sha256"
VERSION=1.92.5
URL=https://pkgs.tailscale.com/stable/tailscale_${VERSION}_arm64.tgz
SHA256=13a59c3181337dfc9fdf9dea433b04c1fbf73f72ec059f64d87466b79a3a313c
FILENAME=tailscale-$VERSION.tgz

if [[ ! -f "$TARGET_DIR/$FILENAME" ]]; then
  echo ">> Downloading $FILENAME..."
  wget -O "$TARGET_DIR/$FILENAME" "$URL"
fi

echo ">> Verifying $FILENAME checksum..."
echo "$SHA256  $TARGET_DIR/$FILENAME" | sha256sum --check --status

echo ">> Extracting $FILENAME..."
rm -rf "$TARGET_DIR/tailscale*"
tar -xzf "$TARGET_DIR/$FILENAME" -C "$TARGET_DIR"

echo ">> Installing $FILENAME to target rootfs..."
install -m 0755 $TARGET_DIR/tailscale_${VERSION}_arm64/tailscale  "$1/usr/bin/tailscale"
install -m 0755 $TARGET_DIR/tailscale_${VERSION}_arm64/tailscaled "$1/usr/sbin/tailscaled"

echo ">> Validate binaries..."
stat "$1/usr/bin/tailscale" >/dev/null
stat "$1/usr/sbin/tailscaled" >/dev/null
