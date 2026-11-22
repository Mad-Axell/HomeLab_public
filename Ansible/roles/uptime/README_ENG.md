# uptime

This role deploys Uptime Kuma as a Docker Compose v2 project on a target host with Docker already installed and brings the container to the desired state.

## What it does

- Creates the Compose project directory and the persistent data directory.
- Renders `compose.yml` from a template with the image, container name, port publishing, and a data bind mount.
- Brings the project to `uptime_state` through `community.docker.docker_compose_v2`.
- When `compose.yml` changes, the module recreates the container automatically (default `recreate` behavior), so no separate restart handler is used.
- Does not create monitors, status pages, notification channels, or the administrator account: these are configured manually in the Uptime Kuma web UI or via its API and are out of the role scope.

## Requirements

- Target OS: Debian 13 (LXC).
- Docker Engine and the Compose v2 plugin on the target host; they are installed by the `docker` role, `uptime` does not install Docker.
- `become: true` to create directories and work with Docker.
- The `community.docker` collection, pinned in the project-level `requirements.yml`.

## Managed resources

- Packages: none.
- Files: `compose.yml` in `uptime_project_directory`, the data directory `uptime_kuma_data_dir`.
- Services: the Uptime Kuma container via Docker Compose.
- Users/groups: none.
- Firewall/API objects: the container-published port `uptime_port`.

## Variables

| Variable | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `uptime_debug_mode` | boolean | no | `false` | Enables debug output after significant changes. |
| `uptime_state` | string | no | `"present"` | Desired Compose project state: `present` or `absent`. |
| `uptime_project_directory` | string | no | `"/opt/uptime-kuma"` | Compose project directory holding `compose.yml`. |
| `uptime_kuma_data_dir` | string | no | `"/opt/uptime-kuma/data"` | Host directory mounted into the container as `/data`. |
| `uptime_kuma_image` | string | no | `"louislam/uptime-kuma:1"` | Uptime Kuma image with a pinned tag. |
| `uptime_container_name` | string | no | `"uptime-kuma"` | Uptime Kuma container name. |
| `uptime_port` | integer | no | `3001` | Host port publishing the Uptime Kuma web interface. |

The role has no required variables without defaults and no secrets.

## Usage

```yaml
---
- name: Deploy Uptime Kuma
  hosts: uptime
  become: true
  roles:
    - role: docker
    - role: uptime
      vars:
        uptime_port: 3001
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

- No secrets are required for installation: the administrator account is created on first login to the Uptime Kuma web UI.
- HTTP/HTTPS/TCP/ICMP monitors, notifications (including Telegram), and status pages are configured manually in the web UI or through the Uptime Kuma API; the role does not manage them.
- Reruns are idempotent: a project already in the desired state reports no changes.
- The `absent` state stops and removes the project containers but keeps `compose.yml` and on-disk data.
