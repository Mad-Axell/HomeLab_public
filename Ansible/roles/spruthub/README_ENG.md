# spruthub

This role deploys Sprut.hub as a Docker Compose v2 project on a dedicated SBC host (Debian) with Docker already installed and brings the container to the desired state. In HomeLab it applies to the `spruthub` device (172.25.40.201, SERVICES network) in `smarthome_group`.

## What it does

- Validates the OS family (`Debian`) and the required `spruthub_image` variable before making any change.
- Creates the Compose project directory and the persistent data directory.
- Renders `compose.yml` from a template: image, container name, network mode, port publishing for non-host mode, a data bind mount, device passthrough (`devices`), the `privileged` flag, and extra environment variables.
- Brings the project to `spruthub_state` through `community.docker.docker_compose_v2`.
- When `compose.yml` changes, the module recreates the container automatically (default `recreate` behavior), so no separate restart handler is used.
- Does not configure the product itself: the account, sticks, integrations, and the MQTT connection to the central Mosquitto (172.25.40.155) are set up in the Sprut.hub web UI and are out of the role scope.

## Requirements

- Target OS: Debian family (SBC, not a Proxmox LXC).
- Docker Engine and the Compose v2 plugin on the target host; they are installed by the `docker` role, `spruthub` does not install Docker.
- `become: true` to create directories and work with Docker.
- The `community.docker` collection, pinned in the project-level `requirements.yml`.
- The Sprut.hub image: the vendor distributes the software under a license and there is no public image registry. `spruthub_image` must reference an image the target Docker daemon can use (for example, one already loaded locally on the device, or one in a registry reachable by the host).

## Managed resources

- Packages: none.
- Files: `compose.yml` in `spruthub_project_directory`, the data directory `spruthub_data_dir`.
- Services: the Sprut.hub container via Docker Compose.
- Users/groups: none.
- Firewall/API objects: the ports from `spruthub_ports` when the network mode is not `host`; with `host` the container uses the host network directly.

## Variables

| Variable | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `spruthub_debug_mode` | boolean | no | `false` | Enables debug output after significant changes. |
| `spruthub_state` | string | no | `"present"` | Desired Compose project state: `present` or `absent`. |
| `spruthub_project_directory` | string | no | `"/opt/spruthub"` | Compose project directory holding `compose.yml`. |
| `spruthub_data_dir` | string | no | `"/opt/spruthub/data"` | Host directory mounted as the data volume. |
| `spruthub_image` | string | yes | - | Sprut.hub image reference with tag; there is no public default, the caller supplies the value. The role fails before making changes if it is not set. |
| `spruthub_container_name` | string | no | `"spruthub"` | Sprut.hub container name. |
| `spruthub_container_data_path` | string | no | `"/data"` | Mount target of the data volume inside the container; must match the vendor image layout. |
| `spruthub_network_mode` | string | no | `"host"` | Docker network mode; `host` is required for LAN device discovery. |
| `spruthub_ports` | list of strings | no | `[]` | Port mappings in "host:container" form; applied only for non-host mode. |
| `spruthub_devices` | list of strings | no | `[]` | Host devices passed through (Zigbee/Z-Wave USB coordinators). |
| `spruthub_extra_volumes` | list of strings | no | `[]` | Extra bind mounts. |
| `spruthub_privileged` | boolean | no | `false` | Run the container in privileged mode. |
| `spruthub_extra_environment` | dict | no | `{}` | Additional non-secret environment variables. |

The role has no secrets: product credentials are entered in its web UI. Secrets must not be passed through `spruthub_extra_environment`; if secret inputs ever appear, they must be read from `VARS/secrets.yml` by variable name (`*_var` indirection), not by value.

## Usage

```yaml
---
- name: Deploy Sprut.hub
  hosts: spruthub
  become: true
  roles:
    - role: docker
    - role: spruthub
      vars:
        spruthub_image: "vendor-supplied/image:tag"
        spruthub_devices:
          - "/dev/serial/by-id/usb-SprutStick_ZigBee-if00"
        spruthub_debug_mode: true
```

## Check mode and diff mode

The role supports:

```bash
ansible-playbook playbook.yml --check --diff
```

`ansible.builtin.file` and `ansible.builtin.template` report diffs correctly. `community.docker.docker_compose_v2` supports check mode partially: predicted changes depend on the Docker daemon, so treat the deployment task's check-mode result as an estimate. Pulling the image is impossible when it exists neither on the host nor in a reachable registry.

## Dependencies

- The `community.docker` collection (project-level `requirements.yml`).
- The `docker` role as a playbook-level prerequisite; no `meta` dependency is used, role order is set by the playbook.

## Notes

- Sprut.hub CE is a licensed vendor product: the image and license come through vendor channels. The role neither downloads nor activates the software; it only describes the container.
- MQTT integration with the central Mosquitto (172.25.40.155) is application-level configuration in the Sprut.hub web UI; the role does not manage it. Intercom and WirenBoard integration go through the same broker.
- For Zigbee/Z-Wave stick passthrough prefer the stable `/dev/serial/by-id/...` path, which survives USB reconnection.
- `host` is the expected network mode for the hub (mDNS, HomeKit, device discovery); switching to bridge may break discovery.
- The `absent` state stops and removes the project containers but keeps `compose.yml` and on-disk data.
- Reruns are idempotent: a project already in the desired state reports no changes.
