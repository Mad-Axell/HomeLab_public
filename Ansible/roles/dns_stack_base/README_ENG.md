# dns_stack_base

This role prepares Debian/Ubuntu for a local DNS service without configuring the resolver itself.

## What it does

- Installs a base package list.
- Optionally stops, disables, and masks `systemd-resolved`.

## Requirements

- Debian or Ubuntu.
- `become: true`.

## Managed resources

- Packages: `dns_stack_base_packages`.
- Files: none.
- Services: `systemd-resolved` only when disabling is enabled.
- Users/groups: none.
- Firewall/API objects: none.

## Variables

| Variable | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `dns_stack_base_debug_mode` | boolean | no | `false` | Reports whether the role changed anything. |
| `dns_stack_base_packages` | list | no | base list | Packages for the DNS host. |
| `dns_stack_base_disable_systemd_resolved` | boolean | no | `true` | Frees port 53 for a local resolver. |

## Usage

```yaml
---
- name: Prepare DNS host
  hosts: dns
  become: true
  roles:
    - role: dns_stack_base
```

## Check mode and diff mode

The role uses `apt` and `systemd` modules; they support `--check --diff` within target-system capabilities.

## Dependencies

- None
