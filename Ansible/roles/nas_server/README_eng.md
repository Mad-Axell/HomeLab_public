# nas_server

This role creates one NAS directory and exports it through Samba, NFS, or both protocols.

## What it does

- Creates the share directory.
- Installs and configures Samba when enabled.
- Installs and configures NFS when enabled.

## Requirements

- Debian or Ubuntu and `become: true`.

## Managed resources

- Packages: `samba`, `nfs-kernel-server` for enabled protocols.
- Files: share directory, `/etc/samba/smb.conf`, `/etc/exports.d/<share>.exports`.
- Services: `smbd`, `nfs-server`.
- Users/groups: none.
- Firewall/API objects: SMB and NFS must be allowed by separate firewall configuration.

## Variables

| Variable | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `nas_server_debug_mode` | boolean | no | `false` | Reports whether the role changed anything. |
| `nas_server_share_path` | string | yes | `null` | Exported directory path. |
| `nas_server_share_name` | string | no | `"data"` | Samba/NFS share name. |
| `nas_server_samba_enabled` | boolean | no | `true` | Enables Samba. |
| `nas_server_samba_guest_ok` | boolean | no | `false` | Allows Samba guest access. |
| `nas_server_nfs_enabled` | boolean | no | `false` | Enables NFS. |
| `nas_server_nfs_clients` | list | conditional | `[]` | Allowed clients; required when NFS is enabled. |

## Usage

```yaml
---
- name: Publish a NAS share
  hosts: nas
  become: true
  roles:
    - role: nas_server
      vars:
        nas_server_share_path: "/srv/data"
        nas_server_nfs_enabled: true
        nas_server_nfs_clients: ["192.168.1.0/24"]
```

## Check mode and diff mode

Configuration templates support `--check --diff`; the NFS handler runs `exportfs -ra` only after the export changes.

## Dependencies

- None
