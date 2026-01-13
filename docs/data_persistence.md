---
title: Data Persistence
---

# Data Persistence

**Available in: Basic and Extended firmware**

By default, Snapmaker firmware resets all system changes on reboot for stability.

## Enable System Persistence

To persist system-level changes to `/etc` (SSH passwords, authorized keys, etc.):

```bash
touch /oem/.debug
```

To restore pristine system state:

```bash
rm /oem/.debug
reboot
```

## Printer Data

The `/home/lava/printer_data` directory always persists, regardless of `/oem/.debug`.

## ⚠️ Important Warning

**Enabling data persistence may break firmware functionality when performing system upgrades.**

It is strongly advised to remove persistence before conducting any firmware upgrade to avoid compatibility issues. To do this:

```bash
rm /oem/.debug
reboot
```

After the firmware upgrade is complete, you can re-enable persistence if needed by recreating the file.
