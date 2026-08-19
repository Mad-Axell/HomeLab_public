# cockpit

This role installs Cockpit and `cockpit-storaged`, then enables socket activation for the web interface. Samba/NFS exports remain the responsibility of `nas_server`.

## What it does

- Installs Cockpit and the disk-management interface from configured Debian repositories.
- Enables and starts `cockpit.socket`.

## Requirements

- Debian/Ubuntu with gathered Ansible facts.
- `become: true`.
- Available, trusted APT repositories that provide the declared packages.

## Managed resources

- Packages: `cockpit`, `cockpit-storaged`, and packages in `cockpit_packages`.
- Files: the APT index in `/var/lib/apt/lists`.
- Services: `cockpit.socket`.
- Users/groups, firewall/API objects: not managed. TCP 9090 must be allowed by a separate firewall role.

## Variables

| Variable | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `cockpit_debug_mode` | boolean | no | `false` | Reports whether the role changed anything. |
| `cockpit_packages` | list | no | `['cockpit', 'cockpit-storaged']` | Cockpit packages from configured APT repositories. |
| `cockpit_cache_valid_time` | integer | no | `3600` | APT index cache lifetime in seconds. |
| `cockpit_socket_name` | string | no | `"cockpit.socket"` | Managed systemd socket unit. |

## Usage

```yaml
---
- name: Configure Cockpit storage management
  hosts: samba
  become: true
  roles:
    - role: cockpit
```

## Check mode and diff mode

Package installation and socket management support `--check`; no meaningful content diff is available. The role does not make HTTP health requests or open a firewall port.

## Dependencies

- None.

45Drives packages are not added because the former removed scenario used an unverified `curl | bash`. If they are needed, first configure a trusted APT repository in a separate role, then explicitly extend `cockpit_packages`.
