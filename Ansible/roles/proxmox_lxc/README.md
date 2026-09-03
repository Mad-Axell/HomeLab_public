# proxmox_lxc

## Русский

Роль создаёт или обновляет один LXC через `community.proxmox.proxmox`.
VMID, узел и сеть берутся из inventory для `proxmox_lxc_target_host`.
По запросу сама находит и загружает новейший шаблон указанной ОС из каталога
appliance.

Документация: [README_rus.md](README_rus.md)

## English

The role creates or updates one LXC with `community.proxmox.proxmox`.
VMID, node, and network data come from inventory for `proxmox_lxc_target_host`.
On request it also finds and downloads the newest appliance-catalog template for
the requested OS.

Documentation: [README_eng.md](README_eng.md)
