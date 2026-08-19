# base_update_debian

This role refreshes the APT index and installed Debian packages separately from application package installation.

## What it does

- Refreshes the APT index using the configured cache lifetime.
- Upgrades installed packages with the selected APT mode.

## Requirements

- Debian/Ubuntu with gathered Ansible facts.
- `become: true`.

## Managed resources

- Packages: any installed package can be upgraded.
- Files: the APT index in `/var/lib/apt/lists`.
- Services, users/groups, firewall/API objects: not managed.

## Variables

| Variable | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `base_update_debian_debug_mode` | boolean | no | `false` | Reports whether the role changed anything. |
| `base_update_debian_cache_valid_time` | integer | no | `86400` | APT index cache lifetime in seconds. |
| `base_update_debian_upgrade_mode` | string | no | `"dist"` | APT mode: `safe`, `full`, or `dist`. |

## Usage

```yaml
---
- name: Update Debian host
  hosts: debian_hosts_group
  become: true
  roles:
    - role: base_update_debian
```

## Check mode and diff mode

`ansible.builtin.apt` supports `--check`; package upgrades do not provide a meaningful content diff.

## Dependencies

- None.
