# ns_server

This role installs Unbound and configures a DNS forwarder with explicitly declared upstream servers.

## What it does

- Installs `unbound`.
- Writes validated forward-zone configuration.
- Manages the Unbound service with a handler for configuration changes.

## Requirements

- Debian or Ubuntu and `become: true`.

## Managed resources

- Packages: `unbound`.
- Files: `/etc/unbound/unbound.conf.d/ns-server.conf`.
- Services: `unbound`.
- Users/groups: none.
- Firewall/API objects: the DNS port must be allowed by a separate firewall role.

## Variables

| Variable | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `ns_server_debug_mode` | boolean | no | `false` | Reports whether the role changed anything. |
| `ns_server_listen_address` | string | no | `"0.0.0.0"` | DNS listener address. |
| `ns_server_listen_port` | integer | no | `53` | DNS listener port. |
| `ns_server_forward_addresses` | list | no | public DNS | Upstream DNS resolvers. |

## Usage

```yaml
---
- name: Configure DNS forwarder
  hosts: dns
  become: true
  roles:
    - role: ns_server
```

## Check mode and diff mode

Configuration is validated with `unbound-checkconf` before replacement and supports `--check --diff`; a change notifies the restart handler.

## Dependencies

- None
