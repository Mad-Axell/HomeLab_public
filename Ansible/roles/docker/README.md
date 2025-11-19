# docker

Ansible role for installing and configuring Docker on managed nodes.

## Description

This role automates the installation of Docker Community Edition (CE) or Enterprise Edition (EE) on various Linux distributions. The role supports installation of Docker from official Docker repositories, Docker service management, installation of Docker Compose (plugin or standalone), Docker daemon configuration, and adding users to the docker group for working without sudo.

## Requirements

### Control Node Requirements

- Ansible 2.12 or higher (for full functionality)
- Python 3.9 or higher

### Managed Node Requirements

- Debian family distribution (Debian, Ubuntu, Pop!_OS, Linux Mint)
- Or RedHat family distribution (RHEL, CentOS, Fedora)
- Or Alpine Linux
- Or Arch Linux
- Root or sudo access
- Internet connectivity for package installation and repository downloads

### Dependencies

None

## Role Variables

### Required Variables

None

### Optional Variables

#### Docker Core Settings

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `docker_edition` | string | `'ce'` | Docker edition: `'ce'` (Community Edition) or `'ee'` (Enterprise Edition) |
| `docker_packages` | list | `["docker-ce", "docker-ce-cli", "docker-ce-rootless-extras", "containerd.io", "docker-buildx-plugin"]` | List of Docker packages to install |
| `docker_packages_state` | string | `present` | Package state: `present`, `absent`, `latest` |
| `docker_add_repo` | bool | `true` | Whether to add the official Docker repository |

#### Docker Service Settings

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `docker_service_manage` | bool | `true` | Whether to manage the Docker service |
| `docker_service_state` | string | `started` | Service state: `started`, `stopped`, `restarted` |
| `docker_service_enabled` | bool | `true` | Whether to enable Docker service at boot |
| `docker_restart_handler_state` | string | `restarted` | State for restart handler |

#### Docker Compose Plugin Settings

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `docker_install_compose_plugin` | bool | `true` | Whether to install Docker Compose Plugin (recommended) |
| `docker_compose_package` | string | `docker-compose-plugin` | Docker Compose Plugin package name |
| `docker_compose_package_state` | string | `present` | Package state: `present`, `absent`, `latest` |

#### Docker Compose (standalone) Settings

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `docker_install_compose` | bool | `false` | Whether to install standalone Docker Compose (deprecated method) |
| `docker_compose_version` | string | `"v2.11.1"` | Docker Compose version to install |
| `docker_compose_arch` | string | `"{{ ansible_architecture }}"` | Architecture for Docker Compose |
| `docker_compose_path` | string | `/usr/local/bin/docker-compose` | Installation path for Docker Compose |

#### Repository Settings (Debian/Ubuntu)

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `docker_repo_url` | string | `https://download.docker.com/linux` | Base URL for Docker repository |
| `docker_apt_release_channel` | string | `stable` | Release channel: `stable` or `nightly` |
| `docker_apt_arch` | string | `"{{ 'arm64' if ansible_architecture == 'aarch64' else 'amd64' }}"` | Architecture for APT repository |
| `docker_apt_gpg_key` | string | `"{{ docker_repo_url }}/{{ docker_apt_ansible_distribution \| lower }}/gpg"` | GPG key URL for repository |
| `docker_apt_gpg_key_checksum` | string | `sha256:1500c1f56fa9e26b9b8f42452a553675796ade0807cdce11975eb98170b3a570` | GPG key checksum |
| `docker_apt_ignore_key_error` | bool | `true` | Whether to ignore errors when adding GPG key |

#### Repository Settings (RedHat/CentOS/Fedora)

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `docker_yum_repo_url` | string | `"{{ docker_repo_url }}/{{ (ansible_distribution == 'Fedora') \| ternary('fedora','centos') }}/docker-{{ docker_edition }}.repo"` | YUM repository file URL |
| `docker_yum_repo_enable_nightly` | string | `'0'` | Enable nightly repository: `'0'` or `'1'` |
| `docker_yum_repo_enable_test` | string | `'0'` | Enable test repository: `'0'` or `'1'` |
| `docker_yum_gpg_key` | string | `"{{ docker_repo_url }}/centos/gpg"` | GPG key URL for YUM |

#### User Management

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `docker_users` | list | `[]` | List of users to add to the docker group |

#### Docker Daemon Settings

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `docker_daemon_options` | dict | `{}` | Dictionary of options for Docker daemon configuration (written to `/etc/docker/daemon.json`) |

## Example Playbook

### Basic Usage

```yaml
---
- name: Install Docker
  hosts: all
  become: true
  roles:
    - docker
```

### Install Docker with User Management

```yaml
---
- name: Install Docker with user configuration
  hosts: all
  become: true
  vars:
    docker_users:
      - ansible_user
      - deploy
  roles:
    - docker
```

### Configure Docker with Custom Daemon Options

```yaml
---
- name: Install Docker with daemon configuration
  hosts: all
  become: true
  vars:
    docker_daemon_options:
      log-driver: "json-file"
      log-opts:
        max-size: "10m"
        max-file: "3"
      storage-driver: "overlay2"
      default-address-pools:
        - base: "172.17.0.0/12"
          size: 24
  roles:
    - docker
```

## What This Role Does

1. **Loads OS-specific variables**
2. **Configures Docker Repository** (Debian/Ubuntu or RedHat/CentOS/Fedora)
3. **Installs Docker Packages**
4. **Installs Docker Compose Plugin**
5. **Configures Docker Daemon**
6. **Manages Docker Service**
7. **Installs Standalone Docker Compose** (Optional)
8. **Adds Users to Docker Group**

## Supported Distributions

- Debian/Ubuntu (Debian, Ubuntu, Pop!_OS, Linux Mint)
- RedHat/CentOS/Fedora (RHEL 7/8/9, CentOS 7/8, Fedora)
- Alpine Linux
- Arch Linux

## License

MIT

## Author

Mad-Axell [mad.axell@gmail.com]

