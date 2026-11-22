# homeassistant

This role deploys Home Assistant Container as a Docker Compose v2 project on a dedicated SBC host (Debian) with Docker already installed and brings the container to the desired state. In HomeLab it applies to the `homeassistant` device (172.25.40.202, SERVICES network) in `smarthome_group`. Only the container flavor of the product is supported: Home Assistant OS and Supervised installs are out of scope.

## What it does

- Validates the OS family (`Debian`) and a non-empty image reference before making any change.
- Creates the Compose project directory and the persistent config directory.
- Renders `compose.yml` from a template: image, container name, `host` network mode or `homeassistant_port:8123` publishing, a `/config` bind mount, device passthrough, the `privileged` flag, `TZ`, and extra environment variables.
- Brings the project to `homeassistant_state` through `community.docker.docker_compose_v2`.
- When `compose.yml` changes, the module recreates the container automatically (default `recreate` behavior), so no separate restart handler is used.
- Does not configure the product itself: onboarding, the account, integrations, and the MQTT connection to the central Mosquitto (172.25.40.155) are set up in the web UI; `configuration.yaml` content is not managed by the role.

## Requirements

- Target OS: Debian family (SBC, not a Proxmox LXC).
- Docker Engine and the Compose v2 plugin on the target host; they are installed by the `docker` role, `homeassistant` does not install Docker.
- `become: true` to create directories and work with Docker.
- The `community.docker` collection, pinned in the project-level `requirements.yml`.

## Managed resources

- Packages: none.
- Files: `compose.yml` in `homeassistant_project_directory`, the config directory `homeassistant_config_dir`.
- Services: the Home Assistant container via Docker Compose.
- Users/groups: none.
- Firewall/API objects: the `homeassistant_port` when the network mode is not `host`; with `host` the container uses the host network directly and the web UI listens on 8123.

## Variables

| Variable | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `homeassistant_debug_mode` | boolean | no | `false` | Enables debug output after significant changes. |
| `homeassistant_state` | string | no | `"present"` | Desired Compose project state: `present` or `absent`. |
| `homeassistant_project_directory` | string | no | `"/opt/homeassistant"` | Compose project directory holding `compose.yml`. |
| `homeassistant_config_dir` | string | no | `"/opt/homeassistant/config"` | Host directory mounted into the container as `/config`. |
| `homeassistant_image` | string | no | `"ghcr.io/home-assistant/home-assistant:stable"` | Home Assistant image with a pinned tag; `homeassistant/home-assistant` from Docker Hub also works. |
| `homeassistant_container_name` | string | no | `"homeassistant"` | Home Assistant container name. |
| `homeassistant_network_mode` | string | no | `"host"` | Docker network mode; `host` enables LAN device discovery, otherwise `homeassistant_port` is published. |
| `homeassistant_port` | integer | no | `8123` | Host port for the web interface; applied only for non-host mode. |
| `homeassistant_timezone` | string or null | no | `null` | Optional `TZ` environment value; omitted when null. |
| `homeassistant_devices` | list of strings | no | `[]` | Host devices passed through (Zigbee/Z-Wave USB coordinators). |
| `homeassistant_extra_volumes` | list of strings | no | `[]` | Extra bind mounts. |
| `homeassistant_privileged` | boolean | no | `false` | Run the container in privileged mode. |
| `homeassistant_extra_environment` | dict | no | `{}` | Additional non-secret environment variables. |

The role has no secrets: product credentials and tokens are created in the web UI and in `configuration.yaml`. Secrets must not be passed through `homeassistant_extra_environment`; if secret inputs ever appear, they must be read from `VARS/secrets.yml` by variable name (`*_var` indirection), not by value.

## Usage

```yaml
---
- name: Deploy Home Assistant
  hosts: homeassistant
  become: true
  roles:
    - role: docker
    - role: homeassistant
      vars:
        homeassistant_timezone: "Europe/Moscow"
        homeassistant_devices:
          - "/dev/serial/by-id/usb-ITead_Sonoff_Zigbee_Dongle-if00"
        homeassistant_debug_mode: true
```

## Check mode and diff mode

The role supports:

```bash
ansible-playbook playbook.yml --check --diff
```

`ansible.builtin.file` and `ansible.builtin.template` report diffs correctly. `community.docker.docker_compose_v2` supports check mode partially: predicted changes depend on the Docker daemon, so treat the deployment task's check-mode result as an estimate.

## Dependencies

- The `community.docker` collection (project-level `requirements.yml`).
- The `docker` role as a playbook-level prerequisite; no `meta` dependency is used, role order is set by the playbook.

## Notes

- Only Home Assistant Container is supported; Home Assistant OS and Supervised (supervisord) installs are out of the role scope.
- MQTT integration with the central Mosquitto (172.25.40.155:1883) is application-level configuration in the Home Assistant web UI; the role does not manage it. Frigate events and WirenBoard data arrive through the same broker.
- For Zigbee/Z-Wave stick passthrough prefer the stable `/dev/serial/by-id/...` path, which survives USB reconnection.
- `host` is the recommended network mode for device discovery (mDNS, SSDP, HomeKit); switching to bridge publishes only `homeassistant_port` and may break discovery.
- The `absent` state stops and removes the project containers but keeps `compose.yml` and the on-disk configuration.
- Reruns are idempotent: a project already in the desired state reports no changes.
