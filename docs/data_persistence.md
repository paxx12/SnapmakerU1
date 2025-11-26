# Data Persistence

**Available in: Basic and Extended firmware**

By default the Snapmaker firmware wipes all user changes on every reboot.
This makes it bulletproof.

## Persisting System Changes

To persist system-level changes to `/etc` (e.g., SSH passwords or authorized keys), create the file with:

```bash
touch /oem/.debug
```

To restore a pristine system, remove the file and reboot:

```bash
rm /oem/.debug
```

## Printer Data

The `/home/lava/printer_data` directory persists with and without `/oem/.debug`.
