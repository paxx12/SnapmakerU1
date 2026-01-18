#!/bin/bash

set -e

IMAGE_NAME="snapmaker-u1-dev"
BUILD_CONTEXT=".github/dev"
SSH_FOLDER="$HOME/.ssh"

if ! docker build -t "$IMAGE_NAME" "$BUILD_CONTEXT"; then
    echo "[!] Docker build failed."
    exit 1
fi

TTY_FLAG=""
[[ -t 0 ]] && TTY_FLAG="-it"

ENV_FLAGS="-e GIT_VERSION"

exec docker run --rm $TTY_FLAG $ENV_FLAGS -w "$PWD" -v "$PWD:$PWD" -v "$SSH_FOLDER:/root/.ssh" "$IMAGE_NAME" "$@"
