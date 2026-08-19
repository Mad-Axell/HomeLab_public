# configure_ufw

This role installs, configures, and enables UFW on Debian/Ubuntu. It applies the selected default policies and explicitly supplied rules before enabling the firewall.

## What it does

- Installs the `ufw` package.
- Sets default policies and the logging level.
- Applies rules and enables UFW.

## Requirements

- Debian or Ubuntu.
- `become: true`.
- The `community.general` collection pinned in the project-level `requirements.yml`.

## Managed resources

- Packages: `ufw`.
- Files: UFW configuration files managed by the UFW module.
- Services: UFW.
- Users/groups: none.
- Firewall/API objects: UFW policies and rules.

## Variables

| Variable | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `configure_ufw_debug_mode` | boolean | no | `false` | Reports whether configuration changed. |
| `configure_ufw_default_incoming_policy` | string | no | `"deny"` | Default incoming policy. |
| `configure_ufw_default_outgoing_policy` | string | no | `"allow"` | Default outgoing policy. |
| `configure_ufw_logging` | string | no | `"low"` | UFW logging level. |
| `configure_ufw_rules` | list | yes | `null` | Rules with `rule`, `port`, `proto`, and optional `from_ip`, `comment`. |

## Usage

```yaml
---
- name: Configure UFW
  hosts: debian
  become: true
  roles:
    - role: base/configure_ufw
      vars:
        configure_ufw_rules:
          - rule: "allow"
            port: "22"
            proto: "tcp"
            from_ip: "192.168.1.0/24"
            comment: "SSH from LAN"
```

## Check mode and diff mode

Package and rule tasks support `--check --diff` within the limits of `community.general.ufw`. Enabling a firewall changes host state and must be run with rules that preserve administrative access.

## Dependencies

- `community.general`

## Notes

- `configure_ufw_rules` deliberately has no working default: the role stops before changes if rules are not declared.
