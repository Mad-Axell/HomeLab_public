# coral_edge_tpu

This role adds the Coral repository, installs the runtime, and writes the supplied device-forwarding lines to an existing Proxmox LXC configuration file.

## What it does

- Adds the Coral signing key and APT repository.
- Installs `libedgetpu1-std` on the Proxmox host.
- Adds only explicitly supplied lines to `/etc/pve/lxc/<vmid>.conf`.

## Requirements

- Debian-based Proxmox VE host.
- `become: true`.
- An existing LXC container.

## Managed resources

- Packages: `libedgetpu1-std`.
- Files: `/etc/apt/keyrings/coral-edge-tpu.gpg`, the APT repository file, and `/etc/pve/lxc/<vmid>.conf`.
- Services: none.
- Users/groups: none.
- Firewall/API objects: none.

## Variables

| Variable | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `coral_edge_tpu_debug_mode` | boolean | no | `false` | Reports whether the role changed anything. |
| `coral_edge_tpu_repository_url` | string | no | Google URL | Coral repository URL. |
| `coral_edge_tpu_repository_key_url` | string | no | Google URL | Signing-key URL. |
| `coral_edge_tpu_package_name` | string | no | `"libedgetpu1-std"` | Runtime package. |
| `coral_edge_tpu_lxc_vmid` | integer | yes | `null` | Existing LXC VMID. |
| `coral_edge_tpu_lxc_device_lines` | list | yes | `null` | Exact LXC device-forwarding lines. |

## Usage

```yaml
---
- name: Configure Coral USB pass-through
  hosts: proxmox
  become: true
  roles:
    - role: coral_edge_tpu
      vars:
        coral_edge_tpu_lxc_vmid: 101
        coral_edge_tpu_lxc_device_lines:
          - "lxc.cgroup2.devices.allow: c 189:* rwm"
          - "lxc.mount.entry: /dev/bus/usb/001 dev/bus/usb/001 none bind,optional,create=dir 0 0"
```

## Check mode and diff mode

Key download, repository, and package tasks support `--check --diff` within Ansible-module capabilities. The LXC configuration is changed predictably with `lineinfile`; the role does not restart the container.

## Dependencies

- None

## Notes

- Declare only exact lines for the intended devices. `lxc.cgroup2.devices.allow: a` is deliberately not a default.
