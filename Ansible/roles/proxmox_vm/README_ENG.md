# proxmox_vm

Creates a KVM virtual machine on the Proxmox node the role runs on (`hosts:`
the node, e.g. `pve-main`). The VM is described by an inventory record — the
same shape `proxmox_lxc` uses, with `proxmox.type: vm`.

## What it does

- Resolves the inventory host named by `proxmox_vm_target_host` through
  `hostvars` and asserts it is a `type: vm` record on this node with an
  `ansible_host`, a `network.bridge` and a `network.mac`.
- Downloads `proxmox_vm_image_url` into `proxmox_vm_image_dir` (skips when the
  decompressed file already exists) and unpacks `.xz` archives via `xz -df`
  (idempotent through `creates`).
- Probes the VM with `qm status`; on a missing VM runs `qm create` with the
  configured cores/memory/balloon, `q35` machine, `ovmf` BIOS, an EFI disk,
  `virtio` NIC (with the inventory MAC, bridge and optional `vlan_tag`),
  a serial console socket and the QEMU guest agent.
- Imports the image with `qm importdisk`, attaches the resulting volume as
  `scsi0` (`discard=on,iothread=1,ssd=1`) and boots from it.
- Grows `scsi0` to `proxmox_vm_disk_size` only when the imported size is
  smaller; shrink never happens.
- On an existing VM reconciles only `cores`, `memory`, `balloon`, `sockets`,
  `onboot` and `agent` via a single `qm set`. Disk, NIC and firmware are
  creation-time choices and are not rewritten.
- Starts the VM when `proxmox_vm_start` is true.

## Requirements

- Run on the Proxmox node itself (the `qm`/`xz` tools live there); root
  privileges.
- The image URL must be reachable from the node.
- `community.general` for nothing — the role uses `ansible.builtin` only.

## Variables

| Variable | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `proxmox_vm_target_host` | string | yes | `null` | Inventory name of the VM record. |
| `proxmox_vm_cores` | int | no | `2` | vCPU cores. |
| `proxmox_vm_sockets` | int | no | `1` | CPU sockets. |
| `proxmox_vm_memory` | int | no | `2048` | Memory, MiB. |
| `proxmox_vm_balloon` | int | no | `0` | Balloon target, MiB; `0` disables. |
| `proxmox_vm_disk_size` | string | no | `"32G"` | Target scsi0 size; grow only. |
| `proxmox_vm_disk_storage` | string | no | `"local-lvm"` | Storage for the imported and EFI disks. |
| `proxmox_vm_image_url` | string | yes | `null` | `.qcow2`/`.qcow2.xz` image URL. |
| `proxmox_vm_image_dir` | string | no | `"/var/lib/vz/template/iso"` | Download directory on the node. |
| `proxmox_vm_bios` | string | no | `"ovmf"` | BIOS type. |
| `proxmox_vm_machine` | string | no | `"q35"` | Machine type. |
| `proxmox_vm_scsihw` | string | no | `"virtio-scsi-single"` | SCSI controller. |
| `proxmox_vm_ostype` | string | no | `"l26"` | Guest OS hint. |
| `proxmox_vm_efidisk` | bool | no | `true` | Create an EFI disk. |
| `proxmox_vm_serial_socket` | bool | no | `true` | Serial console socket. |
| `proxmox_vm_agent_enabled` | bool | no | `true` | QEMU guest agent channel. |
| `proxmox_vm_onboot` | bool | no | `true` | Start at node boot. |
| `proxmox_vm_start` | bool | no | `true` | Start after creation. |
| `proxmox_vm_description` | string | no | `""` | VM notes at creation time. |
| `proxmox_vm_debug_mode` | bool | no | `false` | Debug summary after changes. |

## Example

```yaml
- name: Provision the Home Assistant VM
  hosts: pve-main
  become: true
  roles:
    - role: proxmox_vm
      vars:
        proxmox_vm_target_host: homeassistant
        proxmox_vm_image_url: "https://example/haos_ova-18.4.qcow2.xz"
        proxmox_vm_disk_size: "64G"
```

## Handlers and tags

No handlers. The summary task carries the `debug` tag.

## Check mode

`qm` commands run through `ansible.builtin.command`, which skips them in check
mode; the role then behaves like a dry-run skeleton and reports `WOULD CHANGE`
in the summary. Read-only probes (`qm status`, `qm config`, `stat`) run
normally.
