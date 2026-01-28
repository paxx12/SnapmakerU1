#!/bin/bash
# Quick verification script to check if SSH keys will be installed

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOCAL_KEYS_DIR="$SCRIPT_DIR/local-keys"

echo "SSH Authorized Keys Overlay - Verification"
echo "==========================================="
echo

if [ ! -d "$LOCAL_KEYS_DIR" ]; then
    echo "❌ local-keys directory not found"
    exit 1
fi

PUB_KEYS=$(find "$LOCAL_KEYS_DIR" -maxdepth 1 -name "*.pub" 2>/dev/null || true)

if [ -z "$PUB_KEYS" ]; then
    echo "⚠️  No .pub files found in local-keys/"
    echo "   SSH keys will NOT be installed in firmware"
    echo
    echo "To add your SSH key:"
    echo "  cp ~/.ssh/id_ed25519.pub $LOCAL_KEYS_DIR/"
    exit 0
fi

echo "✓ Found SSH public keys:"
while IFS= read -r pubkey; do
    if [ -f "$pubkey" ]; then
        echo "  - $(basename "$pubkey")"
        echo "    $(head -c 50 "$pubkey")..."
    fi
done <<< "$PUB_KEYS"

echo
echo "✓ These keys will be installed for:"
echo "  - lava user: /home/lava/.ssh/authorized_keys"
echo "  - root user: /root/.ssh/authorized_keys"
echo
echo "✓ Git status:"
git status --short "$LOCAL_KEYS_DIR" | head -3 || echo "  (not in git repository)"
