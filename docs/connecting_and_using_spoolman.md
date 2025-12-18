# Spoolman

## A working Spoolman instance

Spoolman is just a webapp, you don't need to have it runing on your printer and occupy its resources.
You can find instruction on how to install standalone [Spoolman](https://github.com/Donkie/Spoolman) on its [wiki](https://github.com/Donkie/Spoolman/wiki/Filament-Usage-History).
You can choose 2 differtn paths:

- [docker](https://github.com/Donkie/Spoolman/wiki/Installation#docker-install): the easiets in my opinion
- or you can go nuts with pyton's delirium versions and dependencies and choose a [standalone](https://github.com/Donkie/Spoolman/wiki/Installation#standalone-install) install

## Connecting your printer

- Find the `spoolman` section in your `moonraker.conf`
- uncomment it
- fill in `<spoolman ip>` and `<port>` with the appropriate values.
  Example:

```
[spoolman]
server: http://10.6.9.248:8000
```

- find `/klipper/poolman.cfg` among your U1's config files
- uncomment the include line from `# [include spoolman/*.cfg]` to `[include spoolman/*.cfg]`

- restart moonraker and klipper (or just reboot your U1)

## Activate Spoolman Pannel

From Fluidd's main page, open the `3 dots menu`, and select `Adjust dashboard layout`
![access flluidd interface](images/3dots.png)
![access flluidd interface](images/layout.png)

find the spoolman pannel and verify it is active
![access flluidd interface](images/spoolman.png)

## Keeping your spool selections across reboots

If you wish your selected spools tobe remebered when you reboot your u1:

- Go to the end of `printer.cfg`
- uncomment `save_variables` from:

```
#[save_variables]
#filename: ~/printer_data/config/variables.cfg
```

to

```
[save_variables]
filename: ~/printer_data/config/variables.cfg
```

Verify the `variables.cfg` files is correctly created, or creat it your self if needed.
