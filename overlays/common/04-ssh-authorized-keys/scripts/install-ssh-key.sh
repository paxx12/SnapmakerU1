#!/bin/bash
set -e

# This script installs SSH authorized keys from a local-only directory
# The keys directory is git-ignored, so personal keys won't be committed

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OVERLAY_DIR="$(dirname "$SCRIPT_DIR")"
LOCAL_KEYS_DIR="$OVERLAY_DIR/local-keys"
ROOTFS_DIR="${1:-}"

if [ -z "$ROOTFS_DIR" ]; then
    echo "Error: ROOTFS_DIR not provided"
    exit 1
fi

# Check if local-keys directory exists with a public key
if [ ! -d "$LOCAL_KEYS_DIR" ]; then
    echo "Info: No local-keys directory found, skipping SSH key installation"
    exit 0
fi

# Find any .pub files
PUB_KEYS=$(find "$LOCAL_KEYS_DIR" -maxdepth 1 -name "*.pub" 2>/dev/null || true)

if [ -z "$PUB_KEYS" ]; then
    echo "Info: No .pub files found in local-keys, skipping SSH key installation"
    exit 0
fi

# Function to install keys for a user
install_keys_for_user() {
    local ssh_dir="$1"
    local uid="$2"
    local gid="$3"
    local username="$4"

    mkdir -p "$ssh_dir"
    chmod 700 "$ssh_dir"

    local auth_keys="$ssh_dir/authorized_keys"
    > "$auth_keys"

    while IFS= read -r pubkey; do
        if [ -f "$pubkey" ]; then
            cat "$pubkey" >> "$auth_keys"
        fi
    done <<< "$PUB_KEYS"

    chmod 600 "$auth_keys"
    chown -R "$uid:$gid" "$ssh_dir"

    echo "  ✓ $username"
}

# Install keys for both lava and root users
echo "Installing SSH authorized keys for:"
while IFS= read -r pubkey; do
    if [ -f "$pubkey" ]; then
        echo "  - $(basename "$pubkey")"
    fi
done <<< "$PUB_KEYS"

echo ""
echo "Installing for users:"

# Install for lava user (UID 1000, GID 1000)
install_keys_for_user "$ROOTFS_DIR/home/lava/.ssh" 1000 1000 "lava"

# Install for root user (UID 0, GID 0)
install_keys_for_user "$ROOTFS_DIR/root/.ssh" 0 0 "root"

echo ""
echo "SSH authorized keys installed successfully"
