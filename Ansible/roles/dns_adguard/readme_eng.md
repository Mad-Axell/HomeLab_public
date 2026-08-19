# dns_adguard

This role installs AdGuard Home, creates a minimal DNS configuration, and manages its systemd service on Debian.

## What it does

- Downloads and installs AdGuard Home.
- Creates DNS and web-interface configuration.
- Manages the `AdGuardHome` service; configuration changes notify a restart handler.

## Requirements

- Debian or Ubuntu, `become: true`, and access to the release archive URL.
- Required `vault_dns_adguard_admin_password_hash` secret from `VARS/secrets.yml`.

## Managed resources

- Packages: none.
- Files: `/opt/AdGuardHome`, the systemd unit, and `AdGuardHome.yaml`.
- Services: `AdGuardHome`.
- Users/groups: none.
- Firewall/API objects: none.

## Variables

| Variable | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `dns_adguard_debug_mode` | boolean | no | `false` | Reports whether the role changed anything. |
| `dns_adguard_archive_url` | string | no | official URL | AdGuard Home archive. |
| `dns_adguard_install_dir` | string | no | `"/opt/AdGuardHome"` | Installation directory. |
| `dns_adguard_service_name` | string | no | `"AdGuardHome"` | systemd service name. |
| `dns_adguard_service_state` | string | no | `"started"` | Stable service state. |
| `dns_adguard_service_enabled` | boolean | no | `true` | Enables service at boot. |
| `dns_adguard_dns_port` | integer | no | `53` | DNS port. |
| `dns_adguard_web_port` | integer | no | `3000` | Web-interface port. |
| `dns_adguard_admin_user` | string | no | `"admin"` | Web-interface user. |
| `dns_adguard_upstream_dns` | list | no | `["127.0.0.1:5335"]` | Upstream DNS servers. |
| `vault_dns_adguard_admin_password_hash` | string | yes | - | Administrator password hash from Vault. |

## Usage

```yaml
---
- name: Configure AdGuard Home
  hosts: dns
  become: true
  roles:
    - role: dns_adguard
      vars:
        dns_adguard_upstream_dns: ["127.0.0.1:5335"]
```

## Check mode and diff mode

Archive download and service installation have check-mode limitations. The configuration template uses `no_log: true` and `diff: false`, so the secret hash is not displayed.

## Dependencies

- None
