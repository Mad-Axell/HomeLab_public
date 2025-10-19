# Proxmox LXC Role - Complete Documentation

## 📋 Table of Contents

1. [Overview](#overview)
2. [Requirements](#requirements)
3. [Installation](#installation)
4. [Role Variables](#role-variables)
5. [Usage Examples](#usage-examples)
6. [Advanced Configuration](#advanced-configuration)
7. [Structured Logging](#structured-logging)
8. [Error Handling](#error-handling)
9. [Security Considerations](#security-considerations)
10. [Troubleshooting](#troubleshooting)
11. [Contributing](#contributing)

## Overview

The `proxmox_lxc` role provides comprehensive automation for LXC container lifecycle management in Proxmox Virtual Environment (PVE). This role follows Ansible best practices and includes structured logging, error handling, and cross-platform support.

### Key Features

- **Automated Container Creation**: Create LXC containers with customizable resources
- **Template Management**: Download, upload, and manage OS templates
- **Network Configuration**: Configure network interfaces with static or DHCP addressing
- **Resource Management**: Allocate CPU, memory, disk, and storage resources
- **Structured Logging**: JSON-formatted logging for all operations
- **Error Handling**: Comprehensive error handling with rollback capabilities
- **Cross-platform Support**: Support for Debian, RedHat, and SUSE families
- **Validation**: Parameter validation and preflight checks

## Requirements

### System Requirements

- **Ansible**: 2.14 or higher
- **Python**: 3.8 or higher
- **Proxmox VE**: 7.0+ or 8.0+
- **Target OS**: Debian, Ubuntu, RHEL, CentOS, openSUSE, SLES

### Ansible Collections

```yaml
collections:
  - community.general
```

### Python Dependencies

The role automatically installs the following Python packages:
- `python3`
- `python3-pip`
- `python3-proxmoxer`

## Installation

### 1. Install Required Collections

```bash
ansible-galaxy collection install community.general
```

### 2. Clone or Download the Role

```bash
# Using ansible-galaxy
ansible-galaxy install local.proxmox_lxc

# Or clone from repository
git clone <repository-url> roles/proxmox_lxc
```

### 3. Update Requirements

```bash
ansible-galaxy install -r requirements.yml
```

## Role Variables

### Debug and Validation Settings

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `debug_mode` | bool | `true` | Enable detailed debug output |
| `debug_lang` | str | `"both"` | Debug output language (`english`, `russian`, `both`) |
| `debug_show_passwords` | bool | `false` | Show passwords in debug mode (INSECURE) |
| `validate_parameters` | bool | `true` | Enable parameter validation |
| `strict_validation` | bool | `true` | Enable strict validation mode |

### Performance and Reliability Settings

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `async_timeout` | int | `300` | Async task timeout in seconds |
| `retries` | int | `3` | Number of retries for failed tasks |
| `retry_delay` | int | `5` | Delay between retries in seconds |
| `log_file` | str | `"/var/log/ansible-proxmox-lxc.log"` | Path to structured log file |

### Proxmox API Connection

| Variable | Type | Required | Description |
|----------|------|----------|-------------|
| `pve_api_host` | str | Yes | FQDN or IP of the Proxmox API endpoint |
| `pve_node` | str | Yes | Proxmox node hostname where LXC container will be created |
| `pve_api_user` | str | No* | User to connect to Proxmox API |
| `pve_api_password` | str | No* | Password for Proxmox API user |
| `pve_api_token_id` | str | No* | Proxmox API token ID |
| `pve_api_token_secret` | str | No* | Proxmox API token secret |
| `pve_validate_certs` | bool | `false` | Validate SSL certificates when connecting to Proxmox API |
| `pve_default_behavior` | str | `"compatibility"` | Proxmox module default behavior setting |

*Either user/password or token authentication is required.

### Container Configuration

| Variable | Type | Required | Description |
|----------|------|----------|-------------|
| `pve_hostname` | str | Yes | Hostname for the LXC container |
| `pve_lxc_vmid` | int | No | VM ID for the container (auto-assigned if not specified) |
| `pve_lxc_description` | str | No | Description for the container |
| `pve_lxc_root_password` | str | Yes | Root password for the container |
| `pve_lxc_root_authorized_pubkey` | str | No | SSH public key for root user |

### OS Template Configuration

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `pve_lxc_ostemplate_name` | str | - | Name of the OS template |
| `pve_lxc_ostemplate_url` | str | - | URL to download OS template if not present |
| `pve_lxc_ostemplate_src` | str | - | Local path to OS template source |
| `pve_lxc_ostemplate_storage` | str | `"local"` | Storage name for OS templates |
| `pve_lxc_ostemplate_content_type` | str | `"vztmpl"` | Content type for OS template |
| `pve_lxc_ostemplate_timeout` | int | `60` | Timeout for template operations in seconds |
| `pve_lxc_ostemplate_force` | bool | `true` | Force template upload even if it exists |
| `pve_lxc_ostemplate_state` | str | `"present"` | Desired state of the template |

### Resource Configuration

| Variable | Type | Description |
|----------|------|-------------|
| `pve_lxc_cpu_cores` | int | Number of CPU cores |
| `pve_lxc_cpu_limit` | int | CPU limit |
| `pve_lxc_cpu_units` | int | CPU units (weight) |
| `pve_lxc_memory` | int | Memory size in MB |
| `pve_lxc_swap` | int | Swap size in MB |
| `pve_lxc_disk` | int | Disk size in GB |
| `pve_lxc_storage` | str | Storage name for container disk |

### Container Behavior

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `pve_onboot` | bool | `true` | Start container on node boot |
| `pve_lxc_unprivileged` | bool | `true` | Create unprivileged container |
| `pve_lxc_force` | bool | `true` | Force container operations |
| `pve_lxc_timeout` | int | `30` | Timeout for container operations in seconds |

### Network Configuration

| Variable | Type | Description |
|----------|------|-------------|
| `pve_lxc_nameserver` | str | DNS nameserver(s) |
| `pve_lxc_searchdomain` | str | DNS search domain |
| `pve_lxc_ip_address` | str | IP address for the container |
| `pve_lxc_ip_mask` | str | IP subnet mask for container network interface |
| `pve_lxc_ip_gateway` | str | IP gateway for the container |
| `pve_lxc_mac_address` | str | MAC address for container network interface |
| `pve_lxc_net_interfaces` | list | List of network interfaces configuration |

### Advanced Configuration

| Variable | Type | Description |
|----------|------|-------------|
| `pve_lxc_features` | list | Container features (nesting, keyctl, etc.) |
| `pve_lxc_hookscript` | str | Hook script path |
| `pve_lxc_mounts` | list | List of additional mount points |
| `pve_lxc_additional_configurations` | list | Additional configurations to add to container.conf |
| `proxmox_config_dir` | str | Proxmox configuration directory |
| `proxmox_template_cache_dir` | str | Template cache directory path |

## Usage Examples

### Basic Container Creation

```yaml
- hosts: proxmox_nodes
  roles:
    - role: proxmox_lxc
      vars:
        pve_api_host: "pve.example.com"
        pve_node: "pve-node-01"
        pve_hostname: "web-server"
        pve_lxc_root_password: "{{ vault_root_password }}"
        pve_lxc_ostemplate_name: "debian-11-standard_11.7-1_amd64.tar.gz"
        pve_lxc_cpu_cores: 2
        pve_lxc_memory: 1024
        pve_lxc_disk: 20
        pve_lxc_ip_address: "192.168.1.100"
```

### Multi-Container Deployment

```yaml
- hosts: proxmox_nodes
  roles:
    - role: proxmox_lxc
      vars:
        pve_api_host: "{{ proxmox_api_host }}"
        pve_node: "{{ proxmox_node }}"
        pve_hostname: "{{ item.hostname }}"
        pve_lxc_root_password: "{{ vault_root_password }}"
        pve_lxc_ostemplate_name: "{{ item.template }}"
        pve_lxc_cpu_cores: "{{ item.cpu_cores }}"
        pve_lxc_memory: "{{ item.memory }}"
        pve_lxc_disk: "{{ item.disk }}"
        pve_lxc_ip_address: "{{ item.ip_address }}"
      loop:
        - hostname: "web-01"
          template: "ubuntu-22.04-standard_22.04-1_amd64.tar.gz"
          cpu_cores: 2
          memory: 1024
          disk: 20
          ip_address: "192.168.1.10"
        - hostname: "db-01"
          template: "debian-11-standard_11.7-1_amd64.tar.gz"
          cpu_cores: 4
          memory: 2048
          disk: 50
          ip_address: "192.168.1.20"
```

### Token-Based Authentication

```yaml
- hosts: proxmox_nodes
  roles:
    - role: proxmox_lxc
      vars:
        pve_api_host: "pve.example.com"
        pve_node: "pve-node-01"
        pve_api_token_id: "automations@pam!ansible"
        pve_api_token_secret: "{{ vault_api_token_secret }}"
        pve_hostname: "secure-container"
        pve_lxc_root_password: "{{ vault_root_password }}"
        pve_lxc_ostemplate_name: "alpine-3.18-standard_3.18.4-1_amd64.tar.gz"
```

## Advanced Configuration

### Custom Network Configuration

```yaml
- hosts: proxmox_nodes
  roles:
    - role: proxmox_lxc
      vars:
        pve_api_host: "pve.example.com"
        pve_node: "pve-node-01"
        pve_hostname: "networked-container"
        pve_lxc_root_password: "{{ vault_root_password }}"
        pve_lxc_ostemplate_name: "debian-11-standard_11.7-1_amd64.tar.gz"
        pve_lxc_net_interfaces:
          - id: net0
            name: eth0
            hwaddr: "02:00:00:00:00:01"
            ip4: "192.168.1.100"
            netmask4: "24"
            gw4: "192.168.1.1"
            bridge: vmbr0
            firewall: true
          - id: net1
            name: eth1
            ip4: "10.0.0.100"
            netmask4: "24"
            bridge: vmbr1
            firewall: false
```

### Additional Mount Points

```yaml
- hosts: proxmox_nodes
  roles:
    - role: proxmox_lxc
      vars:
        pve_api_host: "pve.example.com"
        pve_node: "pve-node-01"
        pve_hostname: "storage-container"
        pve_lxc_root_password: "{{ vault_root_password }}"
        pve_lxc_ostemplate_name: "debian-11-standard_11.7-1_amd64.tar.gz"
        pve_lxc_mounts:
          - id: mp0
            storage: local-lvm
            size: 100
            mount_point: "/mnt/data"
            acl: true
            quota: false
            backup: true
            read_only: false
          - id: mp1
            storage: nfs-storage
            size: 50
            mount_point: "/mnt/logs"
            acl: false
            quota: true
            backup: false
            read_only: true
```

### Custom Container Features

```yaml
- hosts: proxmox_nodes
  roles:
    - role: proxmox_lxc
      vars:
        pve_api_host: "pve.example.com"
        pve_node: "pve-node-01"
        pve_hostname: "featured-container"
        pve_lxc_root_password: "{{ vault_root_password }}"
        pve_lxc_ostemplate_name: "ubuntu-22.04-standard_22.04-1_amd64.tar.gz"
        pve_lxc_features:
          - nesting=1
          - keyctl=1
          - fuse=1
        pve_lxc_hookscript: "local:snippets/vm_hook.sh"
```

## Structured Logging

The role provides comprehensive JSON-structured logging with the following features:

### Log File Location

Default log file: `/var/log/ansible-proxmox-lxc.log`

Custom log file:
```yaml
log_file: "/var/log/custom-proxmox-lxc.log"
```

### Event Types

| Event Type | Description |
|------------|-------------|
| `PACKAGE_INSTALL` | Python package installation |
| `PACKAGE_INSTALL_FAILURE` | Package installation failure |
| `CONTAINER_CREATION` | LXC container creation |
| `CONTAINER_CREATION_FAILURE` | Container creation failure |
| `ROLE_EXECUTION_SUMMARY` | Overall role execution summary |

### Log Entry Structure

```json
{
  "timestamp": "2024-01-15T10:30:45.123456Z",
  "level": "INFO",
  "event_type": "CONTAINER_CREATION",
  "service_name": "proxmox_lxc",
  "container_name": "web-server",
  "vmid": "200",
  "changed": true,
  "status": "SUCCESS",
  "user": "ansible",
  "host": "pve-node-01",
  "playbook": "deploy-containers.yml",
  "task": "Create the container",
  "correlation_id": "1705312245",
  "message": "LXC container creation completed",
  "metadata": {
    "api_host": "pve.example.com",
    "node": "pve-node-01",
    "template": "debian-11-standard_11.7-1_amd64.tar.gz",
    "cpu_cores": 2,
    "memory": 1024,
    "disk_size": 20,
    "ip_address": "192.168.1.100",
    "unprivileged": true,
    "onboot": true
  }
}
```

### Log Analysis

You can analyze logs using standard tools:

```bash
# View recent container creations
grep "CONTAINER_CREATION" /var/log/ansible-proxmox-lxc.log | tail -10

# Count successful operations
grep '"status": "SUCCESS"' /var/log/ansible-proxmox-lxc.log | wc -l

# Find errors
grep '"level": "ERROR"' /var/log/ansible-proxmox-lxc.log

# Parse with jq
cat /var/log/ansible-proxmox-lxc.log | jq '.metadata.container_name'
```

## Error Handling

The role includes comprehensive error handling with the following features:

### Block-Rescue Pattern

All critical operations use the block-rescue pattern:

```yaml
- name: "Critical operation"
  block:
    - name: "Main operation"
      # ... main task ...
  rescue:
    - name: "Error handling"
      # ... error handling ...
    - name: "Fail with details"
      ansible.builtin.fail:
        msg: "Operation failed. Check debug output for details."
```

### Retry Logic

Configurable retry logic for failed operations:

```yaml
retries: 3
retry_delay: 5
```

### Structured Error Logging

All errors are logged with full context:

```json
{
  "level": "ERROR",
  "event_type": "CONTAINER_CREATION_FAILURE",
  "error_message": "Container creation failed: insufficient resources",
  "error_type": "ProxmoxAPIError",
  "metadata": {
    "api_host": "pve.example.com",
    "node": "pve-node-01",
    "template": "debian-11-standard_11.7-1_amd64.tar.gz"
  }
}
```

## Security Considerations

### Password Management

- Store all passwords in Ansible Vault
- Use `no_log: true` for sensitive tasks
- Enable `debug_show_passwords: false` in production

### Token Authentication

Prefer token-based authentication over user/password:

```yaml
pve_api_token_id: "automations@pam!ansible"
pve_api_token_secret: "{{ vault_api_token_secret }}"
```

### SSL Certificate Validation

Enable SSL certificate validation in production:

```yaml
pve_validate_certs: true
```

### Network Security

- Use firewall rules to restrict API access
- Implement network segmentation
- Use VPN or private networks for API communication

## Troubleshooting

### Common Issues

#### 1. API Connection Failed

**Error**: `Proxmox API is not reachable`

**Solutions**:
- Check network connectivity to Proxmox host
- Verify firewall rules allow port 8006
- Confirm API host and credentials

#### 2. Template Not Found

**Error**: `Template not found`

**Solutions**:
- Verify template name and availability
- Check template storage location
- Download template manually if needed

#### 3. Insufficient Resources

**Error**: `Insufficient resources`

**Solutions**:
- Check available CPU, memory, and disk space
- Reduce resource requirements
- Free up resources on the node

#### 4. Permission Denied

**Error**: `Permission denied`

**Solutions**:
- Verify API user permissions
- Check token permissions
- Ensure user has necessary roles

### Debug Mode

Enable debug mode for detailed troubleshooting:

```yaml
debug_mode: true
debug_lang: "both"
debug_show_passwords: false  # Keep false in production
```

### Log Analysis

Check structured logs for detailed error information:

```bash
# View recent errors
grep '"level": "ERROR"' /var/log/ansible-proxmox-lxc.log | tail -5

# Check specific container operations
grep '"container_name": "web-server"' /var/log/ansible-proxmox-lxc.log
```

## Contributing

### Development Setup

1. Clone the repository
2. Install development dependencies
3. Run tests with Molecule
4. Follow Ansible best practices

### Code Style

- Follow Ansible style guidelines
- Use FQCN for all modules
- Include bilingual comments (English/Russian)
- Add structured logging for all operations

### Testing

```bash
# Run Molecule tests
molecule test

# Test specific scenario
molecule test -s default
```

### Pull Requests

1. Fork the repository
2. Create a feature branch
3. Make changes with tests
4. Submit pull request with description

## License

MIT License - see LICENSE file for details.

## Support

For support and questions:

- Create an issue in the repository
- Check existing documentation
- Review troubleshooting section
- Contact Mad-Axell [mad.axell@gmail.com]
