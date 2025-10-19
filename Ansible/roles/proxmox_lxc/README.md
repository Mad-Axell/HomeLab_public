# Proxmox LXC Role

Ansible role for automated creation and management of LXC containers in Proxmox Virtual Environment (PVE).

## 📋 Overview

This role provides comprehensive automation for LXC container lifecycle management in Proxmox environments, including:

- **Container Creation**: Automated LXC container provisioning with customizable resources
- **Template Management**: OS template download, upload, and management
- **Network Configuration**: Flexible network interface setup with static or DHCP addressing
- **Resource Allocation**: CPU, memory, disk, and storage configuration
- **Structured Logging**: JSON-formatted logging for all operations
- **Error Handling**: Comprehensive error handling with rollback capabilities
- **Cross-platform Support**: Support for Debian, RedHat, and SUSE families

## 🚀 Quick Start

### Basic Usage

```yaml
- hosts: proxmox_nodes
  roles:
    - role: proxmox_lxc
      vars:
        pve_api_host: "pve.example.com"
        pve_node: "pve-node-01"
        pve_hostname: "my-container"
        pve_lxc_root_password: "{{ vault_root_password }}"
        pve_lxc_ostemplate_name: "debian-11-standard_11.7-1_amd64.tar.gz"
        pve_lxc_cpu_cores: 2
        pve_lxc_memory: 1024
        pve_lxc_disk: 20
        pve_lxc_ip_address: "192.168.1.100"
```

### Advanced Configuration

```yaml
- hosts: proxmox_nodes
  roles:
    - role: proxmox_lxc
      vars:
        # API Configuration
        pve_api_host: "pve.example.com"
        pve_node: "pve-node-01"
        pve_api_user: "automations@pam"
        pve_api_password: "{{ vault_api_password }}"
        
        # Container Configuration
        pve_hostname: "web-server-01"
        pve_lxc_vmid: 200
        pve_lxc_root_password: "{{ vault_root_password }}"
        pve_lxc_ostemplate_name: "ubuntu-22.04-standard_22.04-1_amd64.tar.gz"
        
        # Resource Allocation
        pve_lxc_cpu_cores: 4
        pve_lxc_memory: 2048
        pve_lxc_disk: 50
        pve_lxc_storage: "local-lvm"
        
        # Network Configuration
        pve_lxc_ip_address: "192.168.1.100"
        pve_lxc_ip_mask: "24"
        pve_lxc_ip_gateway: "192.168.1.1"
        pve_lxc_nameserver: "8.8.8.8"
        
        # Advanced Settings
        pve_lxc_unprivileged: true
        pve_onboot: true
        debug_mode: true
        log_file: "/var/log/ansible-proxmox-lxc.log"
```

## 📚 Documentation

For complete documentation, see:

- **[README_eng.md](README_eng.md)** - Complete English documentation
- **[README_rus.md](README_rus.md)** - Полная документация на русском языке

## 🔧 Requirements

- **Ansible**: 2.14+
- **Python**: 3.8+
- **Proxmox VE**: 7.0+ or 8.0+
- **Collections**: `community.general`

## 🏷️ Tags

- `packages` - Package installation tasks
- `validation` - Parameter validation tasks
- `template` - Template management tasks
- `container` - Container creation and management tasks
- `network` - Network configuration tasks
- `logging` - Structured logging tasks
- `debug` - Debug output tasks

## 📊 Structured Logging

The role provides comprehensive JSON-structured logging with the following event types:

- `PACKAGE_INSTALL` - Python package installation
- `CONTAINER_CREATION` - LXC container creation
- `ROLE_EXECUTION_SUMMARY` - Overall role execution summary
- `ERROR` events for all failure scenarios

## 🔐 Security

- All sensitive data (passwords, tokens) should be stored in Ansible Vault
- Use `no_log: true` for tasks handling sensitive information
- Enable `debug_show_passwords: false` in production environments

## 📝 License

MIT

## 👥 Authors

Mad-Axell [mad.axell@gmail.com]

## 🔗 Links

- [Proxmox VE Documentation](https://pve.proxmox.com/wiki/Main_Page)
- [Ansible Community General Collection](https://docs.ansible.com/ansible/latest/collections/community/general/)
- [LXC Documentation](https://linuxcontainers.org/lxc/)
