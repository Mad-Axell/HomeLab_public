# proxmox_lxc

This role manages one Proxmox LXC through `community.proxmox.proxmox` instead
of replacing `/etc/pve/lxc/<vmid>.conf` wholesale.

Required inputs:

- `proxmox_lxc_target_host`: LXC inventory alias;
- `proxmox_lxc_api_user` and `proxmox_lxc_api_password`;
- `proxmox_lxc_ostemplate`.

The target inventory object must provide `proxmox.node`, `proxmox.type`,
`proxmox.vmid`, `ansible_host`, and the `network` object used by `hosts.yml`.
The role must run on the owning Proxmox node. The module is delegated to the
Ansible controller, where `proxmoxer >= 2.0` and `requests` must be installed.
When an inventory alias differs from the real Proxmox API node name, declare
that real name as `proxmox.api_node` on the hypervisor inventory object.

`proxmox_lxc_mount_volumes` is the complete desired Proxmox mount-point list.
Use `proxmox_lxc_extra_config_lines` only for settings the module cannot model.
The Proxmox module does not support check mode, so API tasks are skipped by
Ansible during `--check`; syntax and lint checks remain available.
