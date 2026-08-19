# docker

This role configures the official Docker APT repository and installs Docker Engine on Debian/Ubuntu.

## What it does

- Installs the signing key and official Docker APT repository.
- Installs Docker Engine, Buildx, and Compose plugin.
- Manages Docker and adds selected users to the `docker` group.

## Requirements

- Debian or Ubuntu, `become: true`, and access to the Docker repository.

## Managed resources

- Packages: `docker_packages`.
- Files: `/etc/apt/keyrings/docker.asc` and the APT repository file.
- Services: `docker`.
- Users/groups: listed users' membership in the `docker` group.
- Firewall/API objects: none.

## Variables

| Variable | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `docker_debug_mode` | boolean | no | `false` | Reports whether the role changed anything. |
| `docker_repository_url` | string | no | Docker URL | Docker repository URL. |
| `docker_repository_key_url` | string | no | Docker URL | Signing-key URL. |
| `docker_apt_architecture` | string | no | `"amd64"` | APT architecture. |
| `docker_packages` | list | no | Docker Engine and plugins | Packages to install. |
| `docker_service_name` | string | no | `"docker"` | Service name. |
| `docker_service_state` | string | no | `"started"` | Stable service state. |
| `docker_service_enabled` | boolean | no | `true` | Enables service at boot. |
| `docker_users` | list | no | `[]` | Existing users to add to `docker`. |

## Usage

```yaml
---
- name: Install Docker
  hosts: debian
  become: true
  roles:
    - role: docker
      vars:
        docker_users: ["operator"]
```

## Check mode and diff mode

Repository, package, service, and user tasks support `--check --diff` within Ansible and APT capabilities.

## Dependencies

- None
