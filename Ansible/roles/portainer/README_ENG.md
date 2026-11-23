# portainer

This role creates a data directory and runs a Portainer container through `community.docker`.

## What it does

- Creates persistent-data directory.
- Runs Portainer with `/var/run/docker.sock` and `/data` mounts.

## Requirements

- Running Docker, `become: true`, and `community.docker` in project-level `requirements.yml`.

## Managed resources

- Packages: none.
- Files: `portainer_data_directory`.
- Services: Portainer container.
- Users/groups: none.
- Firewall/API objects: published ports.

## Variables

| Variable | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `portainer_debug_mode` | boolean | no | `false` | Reports whether the role changed anything. |
| `portainer_image` | string | no | Portainer CE | Container image. |
| `portainer_container_name` | string | no | `"portainer"` | Container name. |
| `portainer_data_directory` | string | no | `"/opt/portainer"` | Data directory. |
| `portainer_published_ports` | list | no | `["9000:9000"]` | Published ports. |

## Usage

```yaml
---
- name: Deploy Portainer
  hosts: docker
  become: true
  roles:
    - role: portainer
```

## Check mode and diff mode

The container module supports `--check --diff` within Docker-daemon capabilities.

## Dependencies

- `community.docker`
