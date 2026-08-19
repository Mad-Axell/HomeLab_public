# dns_unbound

This role installs Unbound, creates a DNSSEC trust anchor, downloads root hints, and manages the local systemd service.

## What it does

- Installs `unbound` and `unbound-anchor`.
- Creates the trust anchor and downloads root hints.
- Writes validated configuration and manages the Unbound service.

## Requirements

- Debian or Ubuntu.
- `become: true` and access to the root-hints URL.

## Managed resources

- Packages: `unbound`, `unbound-anchor`.
- Files: root key, root hints, and `/etc/unbound/unbound.conf.d/10-server.conf`.
- Services: `unbound`.
- Users/groups: none.
- Firewall/API objects: none.

## Variables

| Variable | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `dns_unbound_debug_mode` | boolean | no | `false` | Reports whether the role changed anything. |
| `dns_unbound_service_name` | string | no | `"unbound"` | Service name. |
| `dns_unbound_service_state` | string | no | `"started"` | Stable service state. |
| `dns_unbound_service_enabled` | boolean | no | `true` | Enables service at boot. |
| `dns_unbound_listen_address` | string | no | `"127.0.0.1"` | Listener address. |
| `dns_unbound_listen_port` | integer | no | `5335` | Listener port. |
| `dns_unbound_num_threads` | integer | no | `2` | Worker thread count. |
| `dns_unbound_root_hints_url` | string | no | Internic URL | Root-hints URL. |
| `dns_unbound_config_path` | string | no | Debian path | Configuration path. |
| `dns_unbound_root_key_path` | string | no | Debian path | Trust-anchor path. |
| `dns_unbound_root_hints_path` | string | no | Debian path | Root-hints path. |

## Usage

```yaml
---
- name: Configure local recursive DNS
  hosts: dns
  become: true
  roles:
    - role: dns_unbound
      vars:
        dns_unbound_listen_port: 5335
```

## Check mode and diff mode

Trust-anchor creation and root-hints download have check-mode limitations. Configuration is validated with `unbound-checkconf` before replacement; a change notifies the restart handler.

## Dependencies

- None
