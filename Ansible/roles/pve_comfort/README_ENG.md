# pve_comfort

The role prepares a Proxmox VE node for regular administration:

- disables PVE and Ceph enterprise repositories;
- enables the official no-subscription repository;
- refreshes package indexes and performs a distribution upgrade;
- installs common administration tools;
- creates a non-root administrator in the `sudo` and `adm` groups;
- optionally installs SSH public keys;
- reports, but never automatically performs, a required reboot.

Required inputs are `pve_comfort_admin_user` and
`pve_comfort_admin_password`. Password handling is protected with `no_log`.
Run the play serially across hypervisors because package upgrades can restart
Proxmox services.
