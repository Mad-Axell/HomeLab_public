# install_apts

An Ansible role for installing essential packages on Ubuntu/Debian systems with comprehensive validation and debugging capabilities.

## Description

This role provides a robust solution for installing essential packages on Debian/Ubuntu systems. It includes parameter validation, comprehensive error handling, detailed debugging output, and verification of successful installation.

## Features

- ✅ **Parameter Validation**: Comprehensive validation of all role parameters
- ✅ **Error Handling**: Robust error handling with retry mechanisms
- ✅ **Debug Output**: Detailed debugging information when enabled
- ✅ **System Verification**: Checks system prerequisites and package availability
- ✅ **Installation Verification**: Verifies successful package installation
- ✅ **Flexible Configuration**: Support for essential and optional packages
- ✅ **Cache Management**: Configurable APT cache management
- ✅ **Upgrade Control**: Optional system package upgrades

## Requirements

- Ansible 2.9 or higher
- Debian/Ubuntu based systems
- APT package manager
- Python 3 (for Ansible execution)

## Role Variables

### Required Variables

None - all variables have sensible defaults.

### Optional Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `debug_mode` | `false` | Enable detailed debug output |
| `apt_cache_valid_time` | `86400` | APT cache validity time in seconds (24 hours) |
| `apt_update_cache` | `true` | Whether to update APT cache |
| `apt_upgrade_packages` | `true` | Whether to upgrade system packages |
| `apt_install_timeout` | `600` | Package installation timeout in seconds |
| `apt_install_recommends` | `true` | Install recommended packages |
| `apt_install_suggests` | `false` | Install suggested packages |

### Package Lists

| Variable | Default | Description |
|----------|---------|-------------|
| `apt_packages` | See defaults | List of essential packages to install |
| `apt_optional_packages` | `[]` | List of optional packages to install |

## Default Essential Packages

The role installs the following essential packages by default:

- `acl` - Access Control Lists
- `sudo` - Superuser do
- `net-tools` - Network utilities
- `gnupg` - GNU Privacy Guard
- `auditd` - System audit daemon
- `libpam-pwquality` - Password quality enforcement
- `htop` - Interactive process viewer
- `curl` - Command line tool for transferring data
- `wget` - Internet file retriever
- `python3` - Python 3 interpreter
- `python3-pip` - Python package installer
- `python3-requests` - HTTP library for Python
- `build-essential` - Essential build tools
- `apt-transport-https` - HTTPS transport for APT
- `software-properties-common` - Software properties management
- `ca-certificates` - Certificate authorities
- `openssh-client` - SSH client
- `iputils-ping` - Network testing tools
- `dnsutils` - DNS utilities

## Dependencies

None.

## Example Playbook

### Basic Usage

```yaml
---
- name: Install essential packages
  hosts: all
  become: yes
  roles:
    - install_apts
```

### Advanced Usage with Custom Configuration

```yaml
---
- name: Install packages with custom configuration
  hosts: all
  become: yes
  vars:
    debug_mode: true
    apt_update_cache: true
    apt_upgrade_packages: false
    apt_cache_valid_time: 3600
    apt_optional_packages:
      - vim
      - git
      - tree
      - jq
  roles:
    - install_apts
```

### Skip Package Upgrades

```yaml
---
- name: Install packages without upgrading system
  hosts: all
  become: yes
  vars:
    apt_upgrade_packages: false
  roles:
    - install_apts
```

### Install Only Specific Packages

```yaml
---
- name: Install custom package list
  hosts: all
  become: yes
  vars:
    apt_packages:
      - curl
      - wget
      - python3
      - git
    apt_optional_packages:
      - vim
      - htop
  roles:
    - install_apts
```

## Tags

The role supports the following tags:

- `validation` - Run parameter validation only
- `always` - Always run (used for validation)

## Debug Mode

Enable debug mode to see detailed information about the installation process:

```yaml
vars:
  debug_mode: true
```

Debug output includes:
- System information
- Package installation status
- APT cache update results
- Installation verification results
- Final installation summary

## Error Handling

The role includes comprehensive error handling:

- **Parameter Validation**: Validates all input parameters before execution
- **System Prerequisites**: Checks system compatibility and APT availability
- **Retry Mechanism**: Retries package installation up to 3 times with 10-second delays
- **Installation Verification**: Verifies all packages are successfully installed
- **Clear Error Messages**: Provides detailed error messages for troubleshooting

## Validation

The role includes a separate validation file (`tasks/validate.yml`) that:

- Validates parameter types and formats
- Checks package name formats
- Ensures boolean parameters are properly set
- Provides detailed validation feedback

## Testing

To test the role:

```bash
# Test with debug mode
ansible-playbook -i inventory playbook.yml -e "debug_mode=true"

# Test validation only
ansible-playbook -i inventory playbook.yml --tags validation

# Test on specific hosts
ansible-playbook -i inventory playbook.yml --limit ubuntu_servers
```

## Troubleshooting

### Common Issues

1. **Package installation fails**: Check if the package name is correct and available in repositories
2. **APT cache issues**: Try setting `apt_update_cache: true` and `apt_cache_valid_time: 0`
3. **Permission issues**: Ensure the playbook runs with `become: yes`
4. **Network issues**: Check connectivity to package repositories

### Debug Information

Enable debug mode to get detailed information:

```yaml
vars:
  debug_mode: true
```