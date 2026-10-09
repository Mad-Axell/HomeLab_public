# pve_comfort

The role prepares a Proxmox VE node for regular administration:

- disables PVE and Ceph enterprise repositories;
- removes legacy one-line repository files
  (`pve-no-subscription.list`, `pve-install-repo.list`), including the bookworm
  entry left behind by the installer;
- enables the official no-subscription repository as a deb822 source over HTTP
  signed through `Signed-By` (HTTPS to `download.proxmox.com` fails TLS
  verification on this uplink);
- refreshes package indexes and performs a distribution upgrade;
- installs common administration tools;
- creates a non-root administrator in the `sudo` and `adm` groups;
- optionally installs SSH public keys;
- reports, but never automatically performs, a required reboot.

Required inputs are `pve_comfort_admin_user` and
`pve_comfort_admin_password`. Password handling is protected with `no_log`.
Run the play serially across hypervisors because package upgrades can restart
Proxmox services.
