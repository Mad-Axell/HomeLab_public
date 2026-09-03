# proxmox_lxc

This role manages one Proxmox LXC through `community.proxmox.proxmox` instead
of replacing `/etc/pve/lxc/<vmid>.conf` wholesale.

Required inputs:

- `proxmox_lxc_target_host`: LXC inventory alias;
- `proxmox_lxc_api_user` and `proxmox_lxc_api_password`;
- `proxmox_lxc_ostemplate`, unless the catalog template download is enabled.

## Appliance template download

With `proxmox_lxc_template_download: true` the role finds and downloads the
newest template of the requested OS, and `proxmox_lxc_ostemplate` may be left
unset: it is replaced by the resolved `<storage>:vztmpl/<file>` volid.

| Variable | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `proxmox_lxc_template_download` | boolean | no | `false` | Enables template lookup and download. |
| `proxmox_lxc_template_os` | string | when download is enabled | `null` | OS name prefix in the catalog, for example `debian-13`. |
| `proxmox_lxc_template_storage` | string | no | `"local"` | Storage that receives the template. |
| `proxmox_lxc_template_section` | string | no | `"system"` | Appliance catalog section. |
| `proxmox_lxc_template_arch` | string | no | `"amd64"` | Architecture used to filter catalog entries. |
| `proxmox_lxc_template_timeout` | integer | no | `600` | Seconds allowed for the download. |

The catalog is read with `pveam` on the Proxmox node itself (`pveam update`,
then `pveam available --section <section>`); both tasks change no state and are
marked `changed_when: false`. Entries are filtered by OS and architecture,
versions are ordered with the `community.general.version_sort` filter, and the
highest one wins. The download itself uses the idempotent
`community.proxmox.proxmox_template` module: when the template already exists on
the storage, the task reports `ok`.

If the catalog offers no entry for `proxmox_lxc_template_os`, the role stops at
the shared `assert` before the container is created.

## Dependencies

- `community.proxmox` for the `proxmox` and `proxmox_template` modules;
- `community.general` for the `version_sort` filter, needed only when the
  template download is enabled.

The target inventory object must provide `proxmox.node`, `proxmox.type`,
`proxmox.vmid`, `ansible_host`, and the `network` object used by `hosts.yml`.
The role must run on the owning Proxmox node. The module is delegated to the
Ansible controller, where `proxmoxer >= 2.0` and `requests` must be installed.
When an inventory alias differs from the real Proxmox API node name, declare
that real name as `proxmox.api_node` on the hypervisor inventory object.

> **`proxmox_lxc_cpus` is not the core count.** The
> `community.proxmox.proxmox` module passes it to Proxmox as `cpulimit`, so any
> value throttles the container to that many CPU-seconds per second. The core
> count is `proxmox_lxc_cores`. The default is `null`, which omits the parameter
> and leaves the container unlimited.

`proxmox_lxc_mount_volumes` is the complete desired Proxmox mount-point list.
Use `proxmox_lxc_extra_config_lines` only for settings the module cannot model.
The Proxmox module does not support check mode, so API tasks are skipped by
Ansible during `--check`; syntax and lint checks remain available.
