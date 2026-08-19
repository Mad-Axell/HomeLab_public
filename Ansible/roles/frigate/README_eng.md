# frigate

This role creates a Frigate Docker Compose project, writes Vault configuration, and brings the container to `present`.

## What it does

- Creates project, configuration, and media directories.
- Writes `compose.yml` and secret `config/config.yml`.
- Deploys Frigate with `community.docker.docker_compose_v2`.

## Requirements

- Docker Compose v2 available to the Ansible user.
- `become: true` for managed directories.
- `community.docker` in project-level `requirements.yml`.
- `vault_frigate_config` secret in `VARS/secrets.yml`.

## Managed resources

- Packages: none.
- Files: Compose project and configuration below `frigate_project_directory`.
- Services: Frigate container.
- Users/groups: none.
- Firewall/API objects: container-published ports.

## Variables

| Variable | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `frigate_debug_mode` | boolean | no | `false` | Reports whether the role changed anything. |
| `frigate_project_directory` | string | no | `"/opt/frigate"` | Compose-project directory. |
| `frigate_media_directory` | string | no | `"/mnt/frigate"` | Media directory. |
| `frigate_image` | string | no | stable image | Frigate image. |
| `frigate_container_name` | string | no | `"frigate"` | Container name. |
| `frigate_shm_size` | string | no | `"1gb"` | Shared-memory size. |
| `frigate_devices` | list | no | `[]` | Explicitly exposed devices. |
| `frigate_ports` | list | no | default ports | Published ports. |
| `vault_frigate_config` | string | yes | - | Complete Frigate `config.yml` content from Vault. |

## Usage

```yaml
---
- name: Deploy Frigate
  hosts: frigate
  become: true
  roles:
    - role: frigate
      vars:
        frigate_devices: ["/dev/bus/usb:/dev/bus/usb"]
```

## Check mode and diff mode

The Compose task has Docker-daemon-dependent check-mode limitations. The application configuration uses `no_log: true` and `diff: false`.

## Dependencies

- `community.docker`
