# cadvisor

This role deploys cAdvisor as a Docker Compose v2 project on a target host with Docker already installed and brings the container to the desired state. cAdvisor exposes per-container CPU, memory, network and filesystem metrics on port 8080 for Prometheus scraping.

## What it does

- Creates the Compose project directory.
- Renders `compose.yml` from a template: pinned image, container name, `privileged` mode, the internal set of read-only host bind mounts (`/`, `/var/run`, `/sys`, `/var/lib/docker`, `/dev/disk`, and the Docker socket), port publishing, and optional extra environment variables.
- Brings the project to `cadvisor_state` through `community.docker.docker_compose_v2`.
- When `compose.yml` changes, the module recreates the container automatically (default `recreate` behavior), so no separate restart handler is used.
- Does not install Docker and does not configure Prometheus scrape jobs: scraping is set up on the Prometheus side, out of this role's scope.

## Requirements

- Target OS: Debian 13 (LXC), asserted via `ansible_facts.os_family == 'Debian'` before any change.
- Docker Engine and the Compose v2 plugin on the target host; they are installed by the `docker` role, `cadvisor` does not install Docker.
- `become: true` to create directories and work with Docker.
- The `community.docker` collection, pinned in the project-level `requirements.yml`.
- Port `cadvisor_port` reachable from the Prometheus host on the target.

## Managed resources

- Packages: none.
- Files: `compose.yml` in `cadvisor_project_directory`.
- Services: the cAdvisor container via Docker Compose.
- Users/groups: none.
- Firewall/API objects: the container-published port `cadvisor_port`.

## Variables

| Variable | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `cadvisor_debug_mode` | boolean | no | `false` | Enables debug output after significant changes. |
| `cadvisor_state` | string | no | `"present"` | Desired Compose project state: `present` or `absent`. |
| `cadvisor_project_directory` | string | no | `"/opt/cadvisor"` | Compose project directory holding `compose.yml`. |
| `cadvisor_image` | string | no | `"gcr.io/cadvisor/cadvisor:v0.49.2"` | cAdvisor image with a pinned release tag; overridable when a new pin is needed. |
| `cadvisor_container_name` | string | no | `"cadvisor"` | cAdvisor container name. |
| `cadvisor_port` | integer | no | `8080` | Host port publishing the cAdvisor metrics endpoint. |
| `cadvisor_privileged` | boolean | no | `true` | Run the container in privileged mode; required by cAdvisor for full host and container metrics. |
| `cadvisor_docker_socket` | string | no | `"/var/run/docker.sock"` | Host path to the Docker socket mounted read-only into the container. |
| `cadvisor_volume_map` | list of strings | no | see `defaults/main.yml` | Internal set of read-only bind mounts cAdvisor needs; not meant for routine overrides. |
| `cadvisor_extra_environment` | dictionary | no | `{}` | Additional non-secret environment variables for the container; secrets must not be placed here. |

The role has no required variables without defaults and no secrets.

## Usage

```yaml
---
- name: Deploy cAdvisor
  hosts: docker_hosts
  become: true
  roles:
    - role: docker
    - role: cadvisor
      vars:
        cadvisor_port: 8080
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

- No secrets are required: cAdvisor exposes metrics without authentication, so restrict `cadvisor_port` to the monitoring network or the Prometheus host.
- cAdvisor serves its web UI on `http://<host>:<cadvisor_port>/` and the Prometheus metrics endpoint on `http://<host>:<cadvisor_port>/metrics`.
- Privileged mode plus the read-only host mounts are required by cAdvisor for full metrics; dropping `cadvisor_privileged` or the mounts degrades the collected data.
- Reruns are idempotent: a project already in the desired state reports no changes.
- The `absent` state stops and removes the project container but keeps `compose.yml` on disk.
