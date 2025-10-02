# Proxmox LXC Container Management Role - English Documentation

[![Ansible](https://img.shields.io/badge/ansible-2.14%2B-blue.svg)](https://www.ansible.com/)
[![License](https://img.shields.io/badge/license-MIT-brightgreen.svg)](LICENSE)

## Table of Contents

- [Overview](#overview)
- [Requirements](#requirements)
- [Installation](#installation)
- [Role Variables](#role-variables)
  - [Debug and Validation](#debug-and-validation)
  - [Proxmox API Connection](#proxmox-api-connection)
  - [Container Configuration](#container-configuration)
  - [OS Template Configuration](#os-template-configuration)
  - [Resource Allocation](#resource-allocation)
  - [Network Configuration](#network-configuration)
  - [Advanced Configuration](#advanced-configuration)
- [Dependencies](#dependencies)
- [Example Playbooks](#example-playbooks)
- [Advanced Usage](#advanced-usage)
- [Troubleshooting](#troubleshooting)
- [Performance Tuning](#performance-tuning)
- [License](#license)

## Overview

This Ansible role automates the creation and management of LXC containers in Proxmox Virtual Environment (PVE). It provides a comprehensive solution for container lifecycle management with features including:

- **Automated Deployment**: Create LXC containers with minimal configuration
- **Template Management**: Automatic download and caching of OS templates
- **Network Configuration**: Flexible network interface setup with multiple networks support
- **Resource Management**: CPU, memory, and disk allocation
- **Validation**: Comprehensive preflight checks and parameter validation
- **Error Handling**: Robust error handling with retry logic
- **Bilingual Support**: Debug output in English and Russian
- **Security**: Password masking and secure credential handling

## Requirements

### System Requirements

- **Ansible Version**: 2.14 or higher
- **Python Version**: 3.8 or higher
- **Target System**: Proxmox VE 7.x or 8.x
- **Control Node**: Linux-based system with Ansible installed

### Python Dependencies

The role automatically installs the following Python packages on the target host:
- `python3`
- `python3-pip`
- `python3-proxmoxer`

### Ansible Collections

- `community.general` (version 8.0.0 or higher)

Install the required collection:

```bash
ansible-galaxy collection install community.general
```

## Installation

### From Local Directory

```bash
# Clone or copy the role to your roles directory
cp -r proxmox_lxc /etc/ansible/roles/

# Or specify in your playbook
roles_path = ./roles:/etc/ansible/roles
```

### Using Ansible Galaxy (if published)

```bash
ansible-galaxy install namespace.proxmox_lxc
```

## Role Variables

### Debug and Validation

```yaml
# Enable detailed debug output
debug_mode: true                    # Boolean. Default: true

# Debug output language: 'english', 'russian', 'both'
debug_lang: "both"                  # String. Default: "both"

# Show passwords in debug output (INSECURE)
debug_show_passwords: false         # Boolean. Default: false

# Enable parameter validation
validate_parameters: true           # Boolean. Default: true

# Enable strict validation mode
strict_validation: true             # Boolean. Default: true
```

### Performance and Reliability

```yaml
# Async task timeout in seconds
async_timeout: 300                  # Integer. Default: 300

# Number of retries for failed tasks
retries: 3                          # Integer. Default: 3

# Delay between retries in seconds
retry_delay: 5                      # Integer. Default: 5
```

### Proxmox API Connection

```yaml
# FQDN or IP of the Proxmox API endpoint
pve_api_host: "proxmox.example.com"   # Required

# Proxmox node hostname
pve_node: "pve-node1"                  # Required

# API authentication (choose one method)

# Method 1: Username/Password
pve_api_user: "root@pam"              # String
pve_api_password: "your_password"     # String (use Ansible Vault!)

# Method 2: API Token
pve_api_token_id: "user@pam!token"    # String
pve_api_token_secret: "secret-value"  # String (use Ansible Vault!)

# SSL certificate validation
pve_validate_certs: false             # Boolean. Default: false

# Module default behavior
pve_default_behavior: compatibility   # String. Options: compatibility, no_defaults
```

### Container Configuration

```yaml
# Container hostname
pve_hostname: "{{ inventory_hostname.split('.')[0] }}"  # Required

# Container VMID (auto-assigned if not specified)
pve_lxc_vmid: 100                     # Integer. Optional

# Container description
pve_lxc_description: |                # String. Optional
  Production web server
  Managed by Ansible

# Root password for the container
pve_lxc_root_password: "password"     # Required (use Ansible Vault!)

# SSH public key for root user
pve_lxc_root_authorized_pubkey: "{{ lookup('file', '~/.ssh/id_rsa.pub') }}"  # Optional
```

### OS Template Configuration

```yaml
# Template name in Proxmox
pve_lxc_ostemplate_name: "ubuntu-22.04-standard_22.04-1_amd64.tar.zst"

# Template download URL (if not present)
pve_lxc_ostemplate_url: "http://download.proxmox.com/images/system/ubuntu-22.04-standard_22.04-1_amd64.tar.zst"

# Local template source path
pve_lxc_ostemplate_src: "/path/to/template.tar.zst"

# Template storage
pve_lxc_ostemplate_storage: "local"   # Default: local

# Template content type
pve_lxc_ostemplate_content_type: "vztmpl"  # Default: vztmpl

# Template operation timeout (seconds)
pve_lxc_ostemplate_timeout: 60        # Default: 60

# Force template upload
pve_lxc_ostemplate_force: true        # Default: true
```

### Resource Allocation

```yaml
# CPU configuration
pve_lxc_cpu_cores: 2                  # Number of CPU cores
pve_lxc_cpu_limit: 2                  # CPU limit
pve_lxc_cpu_units: 1024               # CPU units (weight)

# Memory configuration
pve_lxc_memory: 2048                  # Memory in MB
pve_lxc_swap: 512                     # Swap in MB

# Disk configuration
pve_lxc_disk: 20                      # Disk size in GB
pve_lxc_storage: "local-lvm"          # Storage name

# Container behavior
pve_onboot: true                      # Start on boot
pve_lxc_unprivileged: true            # Create unprivileged container
pve_lxc_force: true                   # Force operations
```

### Network Configuration

```yaml
# DNS configuration
pve_lxc_nameserver: "8.8.8.8 8.8.4.4"
pve_lxc_searchdomain: "example.com"

# Network interfaces
pve_lxc_net_interfaces:
  - id: net0
    name: eth0
    hwaddr: "AA:BB:CC:DD:EE:FF"      # Optional (auto-assigned if not specified)
    ip4: "192.168.1.100"             # IPv4 address or "dhcp"
    netmask4: 24                     # CIDR notation
    gw4: "192.168.1.1"               # IPv4 gateway
    bridge: vmbr0                    # Bridge name
    firewall: true                   # Enable firewall
    rate_limit: 1000                 # Rate limit in MB/s (optional)
    vlan_tag: 100                    # VLAN tag (optional)
  
  - id: net1
    name: eth1
    ip6: "2001:db8::10"              # IPv6 address or "dhcp" or "auto"
    netmask6: 64
    gw6: "2001:db8::1"
    bridge: vmbr1
```

### Advanced Configuration

```yaml
# Container features
pve_lxc_features:
  - nesting=1
  - keyctl=1

# Hook script
pve_lxc_hookscript: "local:snippets/container_hook.sh"

# Additional mount points
pve_lxc_mounts:
  - id: mp0
    storage: local-lvm
    size: 50                         # Size in GB
    mount_point: "/mnt/data"
    acl: false
    quota: false
    backup: true
    skip_replication: false
    read_only: false

# Additional manual configurations (added to container.conf)
pve_lxc_additional_configurations:
  - regexp: '^features'
    line: 'features: nesting=1,keyctl=1'
    state: present
  
  - regexp: '^lxc.cgroup.devices.allow'
    line: 'lxc.cgroup.devices.allow = c 10:200 rwm'
    state: present
```

## Dependencies

This role requires the `community.general` collection for Proxmox modules.

Create a `requirements.yml` file:

```yaml
---
collections:
  - name: community.general
    version: ">=8.0.0"
```

Install dependencies:

```bash
ansible-galaxy collection install -r requirements.yml
```

## Example Playbooks

### Basic Container Creation

```yaml
---
- name: Create basic LXC container
  hosts: proxmox_hosts
  become: true
  
  roles:
    - role: proxmox_lxc
      vars:
        pve_api_host: "proxmox.local"
        pve_node: "pve1"
        pve_api_user: "root@pam"
        pve_api_password: "{{ vault_proxmox_password }}"
        pve_hostname: "web-server"
        pve_lxc_ostemplate_name: "debian-12-standard_12.2-1_amd64.tar.zst"
        pve_lxc_root_password: "{{ vault_container_password }}"
        pve_lxc_cpu_cores: 2
        pve_lxc_memory: 2048
        pve_lxc_disk: 20
```

### Advanced Configuration with Multiple Networks

```yaml
---
- name: Create container with advanced networking
  hosts: proxmox_hosts
  become: true
  
  vars:
    container_hostname: "app-server-01"
  
  roles:
    - role: proxmox_lxc
      vars:
        debug_mode: true
        debug_lang: english
        
        # API Configuration
        pve_api_host: "{{ inventory_hostname }}"
        pve_node: "{{ inventory_hostname }}"
        pve_api_token_id: "ansible@pam!automation"
        pve_api_token_secret: "{{ vault_api_token }}"
        
        # Container Configuration
        pve_hostname: "{{ container_hostname }}"
        pve_lxc_vmid: 150
        pve_lxc_description: |
          Application Server
          Environment: Production
          Managed by: Ansible Automation
        pve_lxc_root_password: "{{ vault_container_password }}"
        pve_lxc_root_authorized_pubkey: "{{ lookup('file', '~/.ssh/id_rsa.pub') }}"
        
        # Template
        pve_lxc_ostemplate_name: "ubuntu-22.04-standard_22.04-1_amd64.tar.zst"
        pve_lxc_ostemplate_url: "http://download.proxmox.com/images/system/ubuntu-22.04-standard_22.04-1_amd64.tar.zst"
        
        # Resources
        pve_lxc_cpu_cores: 4
        pve_lxc_memory: 8192
        pve_lxc_swap: 2048
        pve_lxc_disk: 100
        pve_lxc_storage: "local-lvm"
        
        # Behavior
        pve_onboot: true
        pve_lxc_unprivileged: true
        
        # Network
        pve_lxc_nameserver: "8.8.8.8 1.1.1.1"
        pve_lxc_searchdomain: "example.com"
        pve_lxc_net_interfaces:
          - id: net0
            name: eth0
            ip4: "192.168.1.150"
            netmask4: 24
            gw4: "192.168.1.1"
            bridge: vmbr0
            firewall: true
          
          - id: net1
            name: eth1
            ip4: "10.0.0.150"
            netmask4: 24
            bridge: vmbr1
            firewall: false
        
        # Additional mounts
        pve_lxc_mounts:
          - id: mp0
            storage: local-lvm
            size: 50
            mount_point: "/mnt/data"
            backup: true
          
          - id: mp1
            storage: local-lvm
            size: 20
            mount_point: "/mnt/logs"
            backup: false
        
        # Features
        pve_lxc_features:
          - nesting=1
          - keyctl=1
```

### Using with Inventory

**inventory.yml:**

```yaml
all:
  children:
    proxmox_nodes:
      hosts:
        pve1.example.com:
          ansible_host: 192.168.1.10
        pve2.example.com:
          ansible_host: 192.168.1.11
    
    containers:
      hosts:
        web-01:
          pve_lxc_vmid: 101
          pve_lxc_cpu_cores: 2
          pve_lxc_memory: 2048
          pve_lxc_disk: 20
          pve_lxc_ip_address: "192.168.1.101"
        
        db-01:
          pve_lxc_vmid: 102
          pve_lxc_cpu_cores: 4
          pve_lxc_memory: 8192
          pve_lxc_disk: 100
          pve_lxc_ip_address: "192.168.1.102"
```

**playbook.yml:**

```yaml
---
- name: Deploy containers
  hosts: proxmox_nodes
  
  vars:
    pve_api_host: "{{ inventory_hostname }}"
    pve_node: "{{ inventory_hostname.split('.')[0] }}"
    pve_api_user: "root@pam"
    pve_api_password: "{{ vault_proxmox_password }}"
    pve_lxc_ostemplate_name: "debian-12-standard_12.2-1_amd64.tar.zst"
    pve_lxc_root_password: "{{ vault_container_password }}"
  
  tasks:
    - name: Create containers
      include_role:
        name: proxmox_lxc
      vars:
        pve_hostname: "{{ item }}"
        pve_lxc_vmid: "{{ hostvars[item].pve_lxc_vmid }}"
        pve_lxc_cpu_cores: "{{ hostvars[item].pve_lxc_cpu_cores }}"
        pve_lxc_memory: "{{ hostvars[item].pve_lxc_memory }}"
        pve_lxc_disk: "{{ hostvars[item].pve_lxc_disk }}"
      loop: "{{ groups['containers'] }}"
```

## Advanced Usage

### Using Ansible Vault for Secrets

Create a vault file:

```bash
ansible-vault create group_vars/all/vault.yml
```

Add your secrets:

```yaml
---
vault_proxmox_password: "your_proxmox_password"
vault_container_password: "your_container_password"
vault_api_token: "your_api_token_secret"
```

Use in playbook:

```bash
ansible-playbook playbook.yml --ask-vault-pass
```

### Custom Template Management

Download and use custom template:

```yaml
- role: proxmox_lxc
  vars:
    pve_lxc_ostemplate_src: "/opt/templates/custom-template.tar.zst"
    pve_lxc_ostemplate_name: "custom-template.tar.zst"
    pve_lxc_ostemplate_storage: "local"
```

### Container with Docker Support

```yaml
- role: proxmox_lxc
  vars:
    pve_lxc_features:
      - nesting=1
      - keyctl=1
    pve_lxc_additional_configurations:
      - regexp: '^features'
        line: 'features: nesting=1,keyctl=1'
        state: present
```

## Troubleshooting

### Enable Debug Mode

```yaml
debug_mode: true
debug_lang: both
debug_show_passwords: false  # Only set to true in isolated environments
```

### Common Issues

#### Issue: API Connection Failed

**Solution:**
1. Verify API credentials
2. Check network connectivity
3. Verify SSL certificate settings
4. Enable debug mode to see detailed error messages

```yaml
pve_validate_certs: false  # For self-signed certificates
strict_validation: true    # Enable thorough validation
```

#### Issue: Template Download Failed

**Solution:**
1. Check template URL
2. Verify network connectivity
3. Check available disk space
4. Increase timeout values

```yaml
pve_lxc_ostemplate_timeout: 120
retries: 5
retry_delay: 10
```

#### Issue: Insufficient Resources

**Solution:**
1. Check Proxmox node resources
2. Verify storage availability
3. Review resource allocation

### Validation and Testing

Run with validation enabled:

```bash
ansible-playbook playbook.yml \
  -e "validate_parameters=true" \
  -e "strict_validation=true" \
  -e "debug_mode=true"
```

### Preflight Checks

The role automatically performs:
- Ansible version check (>= 2.14)
- Python version check (>= 3.8)
- Required Python modules check
- Disk space check (>= 1GB free)
- API connectivity test

## Performance Tuning

### Retry Configuration

Adjust retry settings for unreliable networks:

```yaml
retries: 5                 # Increase retry count
retry_delay: 10            # Increase delay between retries
async_timeout: 600         # Increase timeout for long operations
```

### Parallel Execution

Use Ansible's forks for parallel container creation:

```bash
ansible-playbook playbook.yml --forks=10
```

### Template Caching

Pre-download templates to avoid repeated downloads:

```yaml
pve_lxc_ostemplate_storage: "local"
pve_lxc_ostemplate_force: false  # Don't re-upload if exists
```

## Tags

The role supports the following tags:

- `always` - Tasks that always run (validation, preflight)
- `validation` - Parameter validation tasks
- `preflight` - Preflight check tasks
- `packages` - Package installation tasks
- `template` - Template management tasks
- `download` - Template download tasks
- `upload` - Template upload tasks
- `container` - Container creation tasks
- `config` - Configuration tasks
- `debug` - Debug output tasks

Usage:

```bash
# Run only validation
ansible-playbook playbook.yml --tags validation

# Skip debug output
ansible-playbook playbook.yml --skip-tags debug

# Run only container creation
ansible-playbook playbook.yml --tags container
```

## License

MIT

## Author Information

DevOps Team - Internal Infrastructure Team

## Contributing

When contributing to this role, please ensure:

1. All variables are documented
2. Examples are provided for new features
3. Debug output is bilingual (English/Russian)
4. Proper error handling is implemented
5. Changes are tested on supported Proxmox versions

## Support

For issues and questions:
- Review this documentation
- Check the [troubleshooting](#troubleshooting) section
- Enable debug mode for detailed output
- Contact the DevOps team

---

**Last Updated:** 2025
**Role Version:** 1.0.0
**Minimum Ansible Version:** 2.14

