#!/usr/bin/env bash

ROOT_DIR="$(realpath "$(dirname "$0")/..")"

source "$ROOT_DIR/vars.mk"

CODENAME="$1"
VERSION="$2"

if [[ -n "$VERSION" ]]; then
  echo "v$FIRMWARE_VERSION-$CODENAME-$VERSION"
  exit 0
fi

lastVer=$(git tag --sort version:refname --list "v$FIRMWARE_VERSION-$CODENAME-*" | tail -n1)

if [[ -n "$lastVer" ]]; then
  newVer=(${lastVer//-/ })
  newVer[-1]="$((${newVer[-1]}+1))"
  nextVer="${newVer[*]}"
  nextVer="${nextVer// /-}"
  echo "$nextVer"
else
  echo "v$FIRMWARE_VERSION-$CODENAME-1"
fi

