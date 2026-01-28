# SSH Authorized Keys Overlay

This overlay installs SSH public keys to enable passwordless SSH authentication to the printer.

## Usage

1. Copy your SSH public key to the `local-keys/` directory:

```bash
cp ~/.ssh/id_rsa.pub overlays/common/04-ssh-authorized-keys/local-keys/
# or
cp ~/.ssh/id_ed25519.pub overlays/common/04-ssh-authorized-keys/local-keys/
```

2. Build the firmware normally:

```bash
./dev.sh make build PROFILE=extended
```

3. Flash the firmware to your printer

4. SSH without password:

```bash
ssh lava@<printer-ip>
# or
ssh root@<printer-ip>
```

## How It Works

- The `scripts/install-ssh-key.sh` script runs during the build process
- It finds all `.pub` files in `local-keys/` and adds them to both:
  - `/home/lava/.ssh/authorized_keys` (lava user)
  - `/root/.ssh/authorized_keys` (root user)
- The `local-keys/` directory is git-ignored, so your personal keys won't be committed
- If no keys are found, the overlay gracefully skips (no errors)

## Multiple Keys

You can add multiple public keys - all `.pub` files in `local-keys/` will be installed.

## Security Notes

- Only public keys (`.pub` files) should be placed here
- Never commit your private keys
- The `.gitignore` ensures `.pub` files in this directory won't be committed
- Keys are installed with proper permissions (600) and ownership for both users:
  - `/home/lava/.ssh/` owned by lava (UID 1000)
  - `/root/.ssh/` owned by root (UID 0)
