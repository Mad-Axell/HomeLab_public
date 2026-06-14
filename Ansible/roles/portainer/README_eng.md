# portainer

Ansible role for deploying and configuring Portainer - a web interface for managing Docker containers.

## Description

This role automates the deployment of Portainer as a Docker container on managed nodes. The role supports installation of Portainer from the official Docker image, configuration of persistent data storage, network settings management, container restart policy configuration, and verification of web interface availability after deployment.

## Requirements

### Control Node Requirements

- Ansible 2.12 or higher (for full functionality)
- Python 3.9 or higher
- `community.docker` collection installed: `ansible-galaxy collection install community.docker`

### Managed Node Requirements

- Docker installed and running (recommended: use `docker` role)
- Root or sudo access
- Internet connectivity for downloading Portainer image from Docker Hub
- Port 9000 (or other specified port) available for web interface

### Dependencies

- `docker` role (recommended for Docker installation if not already installed)

## Role Variables

### Required Variables

None

### Optional Variables

#### Portainer Core Settings

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `version` | string | `latest` | Portainer image version (Docker image tag) |
| `container_image` | string | `portainer/portainer:{{ version }}` | Full Docker image name for Portainer |
| `container_name` | string | `portainer` | Portainer container name |
| `persistent_data_path` | string | `/opt/portainer:/data` | Path for persistent data in format `host_path:container_path` |
| `host_port` | int | `9000` | Host port for accessing Portainer web interface |
| `container_ports` | list | `["9000:9000"]` | List of ports in format `"host_port:container_port"` |

#### Container Settings

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `container_restart_policy` | string | `always` | Container restart policy: `always`, `unless-stopped`, `on-failure`, `no` |
| `container_recreate` | bool | `false` | Whether to recreate container on each role run |
| `container_labels` | dict | `{}` | Dictionary of labels for container |
| `container_network` | string | `omit` | Docker network name for container connection (if not specified, default network is used) |
| `container_links` | list | `omit` | List of links to other containers (deprecated method, networks recommended) |

#### Cleanup Settings

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `remove_existing_container` | bool | `false` | Whether to remove existing container before installation |
| `remove_persistent_data` | bool | `false` | Whether to remove persistent data during cleanup |

#### Administrator Settings (reserved for future use)

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `admin_user` | string | `admin` | Portainer administrator username (reserved) |
| `admin_password` | string | `password` | Portainer administrator password (reserved) |
| `auth_method` | int | `1` | Authentication method (reserved) |

#### LDAP Settings (reserved for future use)

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `ldap_account` | string | `uid=account_name,ou=Users,o=org,dc=mycompany,dc=com` | LDAP bind account (reserved) |
| `ldap_account_password` | string | `password` | LDAP account password (reserved) |
| `ldap_url` | string | `ldap.mycompany.com` | LDAP server URL (reserved) |
| `ldap_port` | int | `636` | LDAP server port (reserved) |
| `tls_enabled` | bool | `true` | Enable TLS for LDAP (reserved) |
| `tls_skipverify` | bool | `true` | Skip TLS certificate verification (reserved) |
| `start_tls` | bool | `true` | Use STARTTLS (reserved) |
| `ldap_base_dn` | string | `ou=Users,o=org,dc=mycompany,dc=com` | LDAP base DN for search (reserved) |
| `ldap_filter` | string | `(objectClass=inetOrgPerson)` | LDAP search filter (reserved) |
| `ldap_username_attribute` | string | `uid` | Username attribute in LDAP (reserved) |

#### Docker Registry Settings (reserved for future use)

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `configure_registry` | bool | `false` | Whether to configure Docker registry (reserved) |
| `registry_name` | string | `nexus-oss` | Docker registry name (reserved) |
| `registry_url` | string | `1.2.3.4` | Docker registry URL (reserved) |
| `registry_port` | int | `5001` | Docker registry port (reserved) |
| `registry_auth` | bool | `false` | Whether registry requires authentication (reserved) |
| `registry_type` | int | `3` | Registry type: `1` (Quay.io), `2` (Azure Container Registry) or `3` (custom registry) (reserved) |
| `registry_username` | string | `username` | Registry username (reserved) |
| `registry_password` | string | `password` | Registry password (reserved) |

#### Miscellaneous Settings (reserved for future use)

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `configure_settings` | bool | `false` | Whether to configure additional Portainer settings (reserved) |
| `company_logo_url` | string | `'https://...'` | Company logo URL for display in interface (reserved) |
| `templates_url` | string | `'https://raw.githubusercontent.com/portainer/templates/master/templates.json'` | Docker Compose templates URL (reserved) |
| `allow_bindmounts_users` | bool | `true` | Allow users to use bind mounts (reserved) |
| `allow_privileged_users` | bool | `true` | Allow privileged users to perform privileged operations (reserved) |
| `endpoints` | list | `[{name: local, url: ""}]` | List of Docker endpoints for management (reserved) |

## Example Playbook

### Basic Usage

```yaml
---
- name: Deploy Portainer
  hosts: all
  become: true
  roles:
    - docker
    - portainer
```

### Deploy Portainer with Custom Port

```yaml
---
- name: Deploy Portainer on port 9443
  hosts: all
  become: true
  vars:
    host_port: 9443
    container_ports:
      - "9443:9000"
  roles:
    - docker
    - portainer
```

### Deploy Portainer with Custom Data Path

```yaml
---
- name: Deploy Portainer with custom storage
  hosts: all
  become: true
  vars:
    persistent_data_path: /mnt/data/portainer:/data
  roles:
    - docker
    - portainer
```

### Deploy Specific Portainer Version

```yaml
---
- name: Deploy Portainer version 2.20.0
  hosts: all
  become: true
  vars:
    version: "2.20.0"
  roles:
    - docker
    - portainer
```

### Deploy Portainer with Labels and Network

```yaml
---
- name: Deploy Portainer with labels
  hosts: all
  become: true
  vars:
    container_labels:
      environment: production
      managed_by: ansible
    container_network: docker_network
  roles:
    - docker
    - portainer
```

### Recreate Portainer Container

```yaml
---
- name: Recreate Portainer container
  hosts: all
  become: true
  vars:
    container_recreate: true
  roles:
    - docker
    - portainer
```

### Cleanup and Reinstall Portainer

```yaml
---
- name: Cleanup and reinstall Portainer
  hosts: all
  become: true
  vars:
    remove_existing_container: true
    remove_persistent_data: true
  roles:
    - docker
    - portainer
```

## What This Role Does

1. **Cleanup existing container (optional)**
   - Removes existing Portainer container (if `remove_existing_container: true`)
   - Removes persistent data (if `remove_persistent_data: true`)

2. **Deploy Portainer container**
   - Creates and starts Docker container with Portainer image
   - Configures Docker socket mount (`/var/run/docker.sock`) for Docker management
   - Configures persistent data storage
   - Configures ports for web interface access
   - Applies labels and network settings (if specified)
   - Configures container restart policy

3. **Verify container status**
   - Verifies that container started successfully
   - Performs Portainer web interface availability check
   - Waits for web interface readiness (up to 10 attempts with 3 second delay)

4. **Set facts**
   - Sets `portainer_is_running` fact with container state
   - Sets `portainer_endpoint` fact with Portainer API URL

## Supported Distributions

The role works on any Linux distribution where Docker is installed and running:
- Debian/Ubuntu
- RedHat/CentOS/Fedora
- Alpine Linux
- Arch Linux
- Any other distribution with Docker

## Persistent Storage Configuration

The role automatically creates directory for persistent data on host (if it doesn't exist). Portainer data is saved in specified directory and mounted into container at `/data` path.

### Path Examples

```yaml
# Standard path
persistent_data_path: /opt/portainer:/data

# Custom path
persistent_data_path: /mnt/storage/portainer:/data

# Path in user home directory
persistent_data_path: /home/user/portainer-data:/data
```

## Network Configuration

By default, Portainer container uses Docker default network and is accessible via container IP address. For web interface access, port specified in `host_port` variable is used.

### Using Custom Network

```yaml
vars:
  container_network: my_docker_network
```

## Notes

- The role automatically mounts Docker socket (`/var/run/docker.sock`) into container for Docker daemon management
- After first Portainer start, initial setup must be performed via web interface (administrator creation)
- The role verifies web interface availability after deployment but does not perform automatic administrator setup
- Variables for LDAP, registry, and other settings configuration are reserved for future use
- The role uses `community.docker.docker_container` module for container management
- When using `container_recreate: true`, container will be recreated on each role run
- The role supports Ansible check mode

## Troubleshooting

### Container Deployment Errors

If you encounter issues with container deployment:
1. Check that Docker is installed and running: `systemctl status docker`
2. Verify that Portainer image is available: `docker pull portainer/portainer:latest`
3. Check container logs: `docker logs portainer`
4. Ensure port is not occupied by another process: `netstat -tuln | grep 9000`

### Web Interface Access Issues

If web interface is not accessible:
1. Check container status: `docker ps | grep portainer`
2. Verify port is mapped correctly: `docker port portainer`
3. Check firewall settings on host
4. Ensure container is running: `docker start portainer`

### Persistent Data Issues

If data is not persisting:
1. Check directory permissions: `ls -la /opt/portainer`
2. Ensure path is specified correctly in `host_path:container_path` format
3. Verify directory exists and is writable

### Docker Socket Mount Errors

If you encounter issues with Docker socket access:
1. Check permissions on `/var/run/docker.sock`: `ls -la /var/run/docker.sock`
2. Ensure user running container has access to Docker socket
3. Verify Docker daemon is running and accessible

### Container Not Auto-restarting

If container doesn't restart after system reboot:
1. Check restart policy: `docker inspect portainer | grep RestartPolicy`
2. Ensure Docker service is enabled for autostart: `systemctl is-enabled docker`
3. Check Docker logs: `journalctl -u docker`

## Security

### Security Recommendations

- **Don't use default passwords**: Change `admin_password` to a secure password
- **Restrict port access**: Use firewall to limit Portainer port access only from trusted IP addresses
- **Use HTTPS**: Configure reverse proxy (nginx, traefik) with SSL/TLS certificate for Portainer access
- **Limit Docker socket access**: Portainer requires Docker socket access, which gives full control over Docker daemon
- **Regularly update Portainer**: Use specific versions instead of `latest` in production environments

### Reverse Proxy Configuration Example

```yaml
# In playbook for nginx/traefik configuration
# Portainer should be accessible only via HTTPS
vars:
  host_port: 127.0.0.1:9000  # Local access only
  container_ports:
    - "127.0.0.1:9000:9000"
```

## License

MIT

## Author

Mad-Axell [mad.axell@gmail.com]

## Support

For questions and issues, contact the author or create an issue in the repository.

## Links

- [Portainer Official Website](https://www.portainer.io/)
- [Portainer Documentation](https://docs.portainer.io/)
- [Docker Hub - Portainer](https://hub.docker.com/r/portainer/portainer)
- [Ansible community.docker Collection](https://docs.ansible.com/ansible/latest/collections/community/docker/)

