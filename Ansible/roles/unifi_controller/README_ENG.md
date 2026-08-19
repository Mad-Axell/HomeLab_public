# unifi_controller

This role installs a UniFi repository key and APT repository, installs UniFi Network Server, and enables its systemd service.

## What it does

- Installs repository prerequisites, keyring, and signing key.
- Adds the supplied APT repository.
- Installs the UniFi package and starts its service.

## Requirements

- Debian or Ubuntu, `become: true`, and repository access.

## Managed resources

- Packages: `unifi_controller_package_name`.
- Files: `/etc/apt/keyrings/unifi-controller.asc` and repository file.
- Services: `unifi_controller_service_name`.
- Users/groups: none.
- Firewall/API objects: UniFi ports must be allowed by a separate firewall role.

## Variables

| Variable | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `unifi_controller_debug_mode` | boolean | no | `false` | Reports whether the role changed anything. |
| `unifi_controller_repository` | string | yes | `null` | Repository URI with distribution/components. |
| `unifi_controller_repository_key_url` | string | yes | `null` | Signing-key URL. |
| `unifi_controller_package_name` | string | no | `"unifi"` | UniFi package. |
| `unifi_controller_service_name` | string | no | `"unifi"` | Service name. |

## Usage

```yaml
---
- name: Install UniFi Network Server
  hosts: unifi
  become: true
  roles:
    - role: unifi_controller
      vars:
        unifi_controller_repository: "https://repository.example.invalid/debian stable ubiquiti"
        unifi_controller_repository_key_url: "https://repository.example.invalid/key.asc"
```

## Check mode and diff mode

Repository, package, and service tasks support `--check --diff` within APT capabilities.

## Dependencies

- None
