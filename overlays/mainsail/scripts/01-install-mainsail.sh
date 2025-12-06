#!/bin/bash
#
# Mainsail Installation Script
# Downloads and installs Mainsail web UI to the target rootfs
#

ROOT_DIR="$(realpath "$(dirname "$0")/../../..")"

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <rootfs-dir>"
  exit 1
fi

set -eo pipefail

TARGET_DIR="$ROOT_DIR/tmp"

VERSION=v2.15.0
URL=https://github.com/mainsail-crew/mainsail/releases/download/$VERSION/mainsail.zip
SHA256=ac8cde4d1d5c818454c9567e548f1ec5ce75e5e331fa878aaded7235e7e0da32
FILENAME=mainsail-$VERSION.zip

if [[ ! -f "$TARGET_DIR/$FILENAME" ]]; then
  echo ">> Downloading $FILENAME..."
  wget -O "$TARGET_DIR/$FILENAME" "$URL"
fi

echo ">> Verifying $FILENAME checksum..."
echo "$SHA256  $TARGET_DIR/$FILENAME" | sha256sum --check --status

echo ">> Extracting $FILENAME..."
rm -rf "$TARGET_DIR/mainsail-$VERSION"
unzip -o "$TARGET_DIR/$FILENAME" -d "$TARGET_DIR/mainsail-$VERSION"

echo ">> Installing $FILENAME to target rootfs..."
rm -rf "$1/home/lava/mainsail"
cp -r "$TARGET_DIR/mainsail-$VERSION" "$1/home/lava/mainsail"

echo ">> Setting ownership..."
chown -R 1000:1000 "$1/home/lava/mainsail"

echo ">> Mainsail $VERSION installed successfully."
