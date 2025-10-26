# Base Install Packages Role - English Documentation

## Overview

The `base.install_packages` role provides comprehensive package installation capabilities across multiple operating system families (Debian, RedHat, SUSE) with advanced features including automatic security updates, structured logging, and robust error handling.

## Table of Contents

- [Requirements](#requirements)
- [Role Variables](#role-variables)
- [Dependencies](#dependencies)
- [Example Playbook](#example-playbook)
- [Advanced Usage](#advanced-usage)
- [Platform Support](#platform-support)
- [Logging](#logging)
- [Troubleshooting](#troubleshooting)
- [License](#license)

## Requirements

### Ansible Version
- **Minimum**: Ansible 2.9+
- **Recommended**: Ansible 2.14+

### Supported Operating Systems

#### Debian Family
- **Ubuntu**: focal (20.04), jammy (22.04), noble (24.04)
- **Debian**: bullseye (11), bookworm (12), trixie (13)

#### RedHat Family
- **EL**: 7, 8, 9
- **CentOS**: 7
- **Rocky Linux**: 8, 9
- **AlmaLinux**: 8, 9

#### SUSE Family
- **openSUSE**: 15.3, 15.4, 15.5, Tumbleweed
- **SLES**: 15.3, 15.4, 15.5

### Python Requirements
- Python 3.6+ (on target hosts)
- Required Python packages: `ansible`, `community.general` (for SUSE support)

## Role Variables

### Core Configuration

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `essential_packages` | list | See defaults | Universal package names to install |
| `optional_packages` | list | `[]` | Additional packages to install |
| `debug_mode` | bool | `false` | Enable comprehensive debug output |
| `validate_parameters` | bool | `true` | Enable parameter validation |
| `log_file` | str | `/var/log/ansible-changes.log` | Path to structured log file |

### Package Management

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `package_update_cache` | bool | `true` | Update package cache before installation |
| `package_upgrade_packages` | bool | `true` | Upgrade system packages |
| `package_cache_valid_time` | int | `86400` | Cache validity time in seconds (24 hours) |
| `package_install_recommends` | bool | `true` | Install recommended packages |

### Automatic Updates

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `autoupdates_enabled` | bool | `true` | Enable automatic security updates |
| `security_updates_only` | bool | `true` | Install only security updates |
| `reboot_if_required` | bool | `false` | Allow automatic reboot after updates |
| `gpg_require_signed` | bool | `true` | Require GPG signature verification |
| `autoupdates_autoremove` | bool | `true` | Remove unused dependencies (Debian/Ubuntu) |
| `autoupdates_schedule_enabled` | bool | `true` | Enable scheduled automatic updates |
| `autoupdates_time` | str | `"02:00"` | Time for automatic updates |
| `autoupdates_download_only` | bool | `false` | Download updates without installing |

### Default Essential Packages

The role installs these universal packages (mapped to platform-specific names):

- `acl` - Access Control Lists
- `sudo` - Superuser do
- `net-tools` - Network utilities
- `gnupg` - GNU Privacy Guard
- `audit` - System audit daemon
- `libpwquality` - Password quality enforcement
- `htop` - Interactive process viewer
- `curl` - Command line tool for transferring data
- `wget` - Internet file retriever
- `openssh-clients` - SSH client
- `iputils` - Network testing tools
- `bind-utils` - DNS utilities

## Dependencies

### Ansible Collections
```yaml
collections:
  - name: community.general
    version: ">=3.0.0"
```

### Role Dependencies
None - this role is designed to be independent.

## Example Playbook

### Basic Usage

```yaml
---
- name: Install essential packages
  hosts: all
  become: yes
  roles:
    - role: base.install_packages
      vars:
        essential_packages:
          - sudo
          - curl
          - wget
          - htop
        debug_mode: true
```

### Advanced Configuration

```yaml
---
- name: Configure server with packages and auto-updates
  hosts: servers
  become: yes
  roles:
    - role: base.install_packages
      vars:
        # Essential packages
        essential_packages:
          - sudo
          - curl
          - wget
          - htop
          - vim
          - git
        
        # Optional packages
        optional_packages:
          - tree
          - jq
          - unzip
        
        # Debug and logging
        debug_mode: true
        log_file: "/var/log/ansible-package-install.log"
        
        # Automatic updates
        autoupdates_enabled: true
        security_updates_only: true
        reboot_if_required: false
        autoupdates_time: "03:00"
```

### Platform-Specific Examples

#### Debian/Ubuntu
```yaml
---
- name: Configure Ubuntu server
  hosts: ubuntu_servers
  become: yes
  roles:
    - role: base.install_packages
      vars:
        essential_packages:
          - sudo
          - curl
          - wget
        autoupdates_enabled: true
        autoupdates_autoremove: true
```

#### RedHat/CentOS
```yaml
---
- name: Configure CentOS server
  hosts: centos_servers
  become: yes
  roles:
    - role: base.install_packages
      vars:
        essential_packages:
          - sudo
          - curl
          - wget
        autoupdates_enabled: true
        security_updates_only: true
```

#### SUSE/openSUSE
```yaml
---
- name: Configure SUSE server
  hosts: suse_servers
  become: yes
  roles:
    - role: base.install_packages
      vars:
        essential_packages:
          - sudo
          - curl
          - wget
        autoupdates_enabled: true
        autoupdates_time: "02:30"
```

## Advanced Usage

### Custom Package Mappings

The role automatically maps universal package names to platform-specific names. You can override these mappings:

```yaml
---
- name: Custom package mappings
  hosts: all
  become: yes
  roles:
    - role: base.install_packages
      vars:
        package_mappings:
          debian:
            custom_package: "custom-debian-package"
          redhat:
            custom_package: "custom-redhat-package"
          suse:
            custom_package: "custom-suse-package"
```

### Conditional Package Installation

```yaml
---
- name: Conditional package installation
  hosts: all
  become: yes
  roles:
    - role: base.install_packages
      vars:
        essential_packages:
          - sudo
          - curl
          - wget
        optional_packages: "{{ development_packages if is_development | default(false) else [] }}"
```

### Custom Logging Configuration

```yaml
---
- name: Custom logging setup
  hosts: all
  become: yes
  roles:
    - role: base.install_packages
      vars:
        log_file: "/var/log/custom-ansible-changes.log"
        debug_mode: true
```

## Platform Support

### Package Manager Mapping

| OS Family | Package Manager | Auto-update Tool |
|-----------|----------------|------------------|
| Debian/Ubuntu | APT | unattended-upgrades |
| RedHat/CentOS 7 | YUM | yum-cron |
| RedHat/CentOS 8+ | DNF | dnf-automatic |
| SUSE/openSUSE | Zypper | Custom systemd service |

### OS-Specific Features

#### Debian/Ubuntu
- APT package management
- `unattended-upgrades` for automatic security updates
- GPG signature verification
- Automatic dependency cleanup

#### RedHat/CentOS
- YUM/DNF package management
- `yum-cron` (RHEL 7) or `dnf-automatic` (RHEL 8+) for automatic updates
- RPM GPG signature verification
- Repository metadata verification

#### SUSE/openSUSE
- Zypper package management
- Custom systemd service and timer for automatic updates
- RPM GPG signature verification
- Repository refresh and key management

## Logging

### Structured Logging Format

All operations are logged in JSON format to the specified log file:

```json
{
  "timestamp": "2024-01-15T10:30:45Z",
  "level": "INFO",
  "event_type": "PACKAGE_INSTALL",
  "component": "ESSENTIAL",
  "hostname": "server01",
  "status": "SUCCESS",
  "packages": "sudo,curl,wget",
  "user": "ansible",
  "playbook": "install_packages",
  "correlation_id": "1705312245"
}
```

### Log Event Types

- `ROLE_START` - Role execution started
- `ROLE_COMPLETE` - Role execution completed
- `CACHE_UPDATE` - Package cache updated
- `PACKAGE_INSTALL` - Packages installed
- `CONFIG_CHANGE` - Configuration changed
- `SERVICE_MANAGE` - Service management operations

### Log Analysis

```bash
# View all package installations
grep "PACKAGE_INSTALL" /var/log/ansible-changes.log

# View configuration changes
grep "CONFIG_CHANGE" /var/log/ansible-changes.log

# View errors
grep '"level":"ERROR"' /var/log/ansible-changes.log
```

## Troubleshooting

### Common Issues

#### Package Installation Failures
```bash
# Check package availability
ansible host -m shell -a "apt list --installed | grep package_name"  # Debian/Ubuntu
ansible host -m shell -a "rpm -qa | grep package_name"  # RedHat/CentOS
ansible host -m shell -a "zypper se -i package_name"  # SUSE
```

#### Automatic Updates Not Working
```bash
# Check service status
ansible host -m shell -a "systemctl status unattended-upgrades"  # Debian/Ubuntu
ansible host -m shell -a "systemctl status dnf-automatic.timer"  # RedHat/CentOS 8+
ansible host -m shell -a "systemctl status yum-cron"  # RedHat/CentOS 7
ansible host -m shell -a "systemctl status zypper-automatic-update.timer"  # SUSE
```

#### GPG Signature Issues
```bash
# Refresh GPG keys
ansible host -m shell -a "apt-key update"  # Debian/Ubuntu
ansible host -m shell -a "rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-*"  # RedHat/CentOS
ansible host -m shell -a "zypper refresh"  # SUSE
```

### Debug Mode

Enable debug mode for detailed output:

```yaml
---
- name: Debug package installation
  hosts: all
  become: yes
  roles:
    - role: base.install_packages
      vars:
        debug_mode: true
        essential_packages:
          - sudo
          - curl
```

### Validation Issues

The role includes comprehensive parameter validation. Common validation errors:

- Invalid package names
- Unsupported OS family
- Invalid boolean values
- Missing required parameters

Check the role execution output for specific validation error messages.

## License

MIT

## Author

Mad-Axell [mad.axell@gmail.com]

## Changelog

### Version 2.0.0
- Added structured logging support
- Enhanced error handling with rollback mechanisms
- Improved multi-platform support
- Added comprehensive parameter validation

### Version 1.0.0
- Initial release
- Basic package installation support
- Multi-platform compatibility
