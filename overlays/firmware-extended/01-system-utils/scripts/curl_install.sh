#!/bin/bash

set -eo pipefail

ROOT_DIR="$(realpath "$(dirname "$0")/../../../..")"

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <rootfs-dir>"
  exit 1
fi

echo ">> Installing latest curl from precompiled tarball"

TARGET_DIR="$ROOT_DIR/tmp"

VERSION=8.17.0
FILENAME=curl-linux-aarch64-glibc-$VERSION.tar.xz
URL=https://github.com/stunnel/static-curl/releases/download/$VERSION/$FILENAME
BIN_SHA256=fa8d1db2f1651d94cdb061ede60f20b895edd31439d8e2eb25383606117c7316

if [[ ! -f "$TARGET_DIR/$FILENAME" ]]; then
  echo ">> Downloading $FILENAME..."
  wget -O "$TARGET_DIR/$FILENAME" "$URL"
fi

echo ">> Extracting $FILENAME..."
mkdir -p "$1/usr/local/bin"
if ! tar -xJvf "$TARGET_DIR/$FILENAME" -C "$1/usr/local/bin" curl; then
  echo "[!] Failed to extract curl from $FILENAME"
  exit 1
fi

echo ">> Verifying /usr/local/bin/curl checksum..."
echo "$BIN_SHA256  $1/usr/local/bin/curl" | sha256sum --check --status

echo ">> Verifying if curl is executable..."
if [[ ! -x "$1/usr/local/bin/curl" ]]; then
  echo "[!] /usr/local/bin/curl is not executable."
  exit 1
fi

echo ">> curl installed to $1/usr/local/bin"

