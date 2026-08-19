# netbox_docker_local

This role writes one secret NetBox Compose file and deploys it through Docker Compose v2.

## What it does

- Creates the project directory.
- Writes Vault-supplied `compose.yml` without logging content.
- Brings the Compose stack to `present`.

## Requirements

- Docker Compose v2 and `community.docker` in project-level `requirements.yml`.
- `become: true` for the project directory.
- `vault_netbox_docker_local_compose` in `VARS/secrets.yml`.

## Managed resources

- Packages: none.
- Files: `<project_directory>/compose.yml`.
- Services: NetBox Compose-stack containers.
- Users/groups: none.
- Firewall/API objects: depend on the supplied Compose file.

## Variables

| Variable | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `netbox_docker_local_debug_mode` | boolean | no | `false` | Reports whether the role changed anything. |
| `netbox_docker_local_project_directory` | string | no | `"/opt/netbox"` | Compose-project directory. |
| `vault_netbox_docker_local_compose` | string | yes | - | Complete Vault Compose content. |

## Usage

```yaml
---
- name: Deploy NetBox
  hosts: netbox
  become: true
  roles:
    - role: netbox_docker_local
```

## Check mode and diff mode

The secret Compose file uses `no_log: true` and `diff: false`; the Compose module has Docker-dependent check-mode limitations.

## Dependencies

- `community.docker`
