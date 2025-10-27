# install_packages - Debian Package Installation Role

## Description

This role installs essential packages on Debian/Ubuntu systems with comprehensive validation, advanced debugging capabilities, and production-ready error handling. It supports both essential and optional packages, automatic security updates configuration, and includes structured logging for all operations.

## Features

- **Universal Package Management**: Installs essential packages for Debian/Ubuntu systems
- **Automatic Security Updates**: Configures unattended-upgrades for security updates
- **Comprehensive Validation**: Preflight checks and post-deployment verification
- **Structured Logging**: JSON-formatted logs for all operations
- **Error Handling**: Block-rescue patterns with rollback capabilities
- **Debug Support**: Detailed debugging output with system metrics
- **Performance Monitoring**: Execution time tracking and performance metrics

## Supported Platforms

- **Ubuntu**: focal, jammy, noble
- **Debian**: bullseye, bookworm, trixie

## Requirements

- Ansible 2.9 or higher
- Debian family operating systems
- Root or sudo privileges
- Network connectivity for package downloads

## Role Variables

### Essential Configuration

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `debug_mode` | bool | `false` | Enable comprehensive debug output |
| `log_file` | str | `"/var/log/ansible-changes.log"` | Path to structured log file |
| `validate_parameters` | bool | `true` | Enable parameter validation |
| `verify_deployment` | bool | `true` | Enable post-deployment verification |

### Package Management

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `package_cache_valid_time` | int | `86400` | Package cache validity time in seconds (24 hours) |
| `package_update_cache` | bool | `true` | Update package cache before operations |
| `package_upgrade_packages` | bool | `true` | Upgrade system packages to latest versions |
| `package_install_recommends` | bool | `true` | Install recommended packages along with main packages |

### Essential Packages

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `essential_packages` | list | See below | List of essential packages to install |

**Default Essential Packages:**
- `acl` - Access Control Lists
- `sudo` - Superuser do
- `net-tools` - Network utilities
- `gnupg` - GNU Privacy Guard
- `htop` - Interactive process viewer
- `curl` - Command line tool for transferring data
- `wget` - Internet file retriever
- `openssh-client` - SSH client
- `iputils-ping` - Network testing tools
- `dnsutils` - DNS utilities
- `apt-transport-https` - HTTPS transport for APT
- `software-properties-common` - Software properties management

### Optional Packages

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `optional_packages` | list | `[]` | List of optional packages to install |

### Automatic Security Updates

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `autoupdates_enabled` | bool | `false` | Enable automatic security updates |
| `security_updates_only` | bool | `true` | Install only security updates |
| `reboot_if_required` | bool | `false` | Allow automatic system reboot if required |
| `gpg_require_signed` | bool | `true` | Require GPG signature verification |
| `autoupdates_autoremove` | bool | `true` | Automatic removal of unused dependencies |
| `autoupdates_schedule_enabled` | bool | `true` | Enable automatic update schedule |
| `autoupdates_time` | str | `"02:00"` | Time for automatic updates |
| `autoupdates_download_only` | bool | `false` | Download updates without installing |

### System Requirements

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `min_disk_space` | int | `1073741824` | Minimum disk space in bytes (1GB) |
| `min_memory_mb` | int | `512` | Minimum memory in MB |
| `required_mounts` | list | `["/"]` | Required mount points for preflight checks |

## Dependencies

None

## Example Playbook

### Basic Usage

```yaml
---
- hosts: all
  become: true
  roles:
    - role: install_packages
      vars:
        debug_mode: true
        essential_packages:
          - acl
          - sudo
          - curl
          - wget
```

### With Optional Packages

```yaml
---
- hosts: all
  become: true
  roles:
    - role: install_packages
      vars:
        essential_packages:
          - acl
          - sudo
          - curl
        optional_packages:
          - vim
          - git
          - htop
        debug_mode: true
```

### With Automatic Security Updates

```yaml
---
- hosts: all
  become: true
  roles:
    - role: install_packages
      vars:
        autoupdates_enabled: true
        security_updates_only: true
        reboot_if_required: false
        autoupdates_time: "03:00"
```

## Role Structure

```
roles/base/install_packages/
├── defaults/main.yml              # Default variables
├── handlers/main.yml              # Service restart handlers
├── meta/
│   ├── main.yml                   # Role metadata
│   └── argument_specs.yml         # Input validation specs
├── tasks/
│   ├── main.yml                   # Main orchestration
│   ├── validate.yml               # Parameter validation
│   ├── preflight.yml              # Pre-execution checks
│   ├── debian.yml                 # Debian/Ubuntu specific tasks
│   ├── autoupdate_debian.yml      # Automatic updates config
│   └── verify.yml                 # Post-deployment verification
├── templates/
│   ├── 20auto-upgrades.j2         # APT periodic config
│   └── 50unattended-upgrades.j2   # Unattended upgrades config
├── README.md                      # Brief overview
├── README_eng.md                  # Complete English docs
└── README_rus.md                  # Complete Russian docs
```

## Task Flow

1. **Validation**: Validate role arguments and parameters
2. **Preflight Checks**: Verify system compatibility and resources
3. **Package Cache Management**: Update APT cache if enabled
4. **System Upgrade**: Upgrade packages if enabled
5. **Essential Package Installation**: Install required packages
6. **Optional Package Installation**: Install optional packages if defined
7. **Verification**: Verify all packages are installed correctly
8. **Automatic Updates Configuration**: Configure security updates if enabled

## Preflight Checks

The role performs comprehensive preflight checks:

- Ansible version validation (2.9+)
- OS compatibility (Debian family only)
- Disk space verification
- Memory requirements check
- Network connectivity test
- Package manager availability
- Required directories existence
- Filesystem writability

## Structured Logging

All operations are logged to a structured JSON file (`/var/log/ansible-changes.log` by default) with the following information:

- Timestamp and correlation ID
- Event type and level
- User and host information
- Operation metadata
- Success/failure status

## Error Handling

The role implements comprehensive error handling:

- Block-rescue patterns for critical operations
- Automatic rollback on configuration failures
- Detailed error messages with context
- Graceful degradation for non-critical failures

## Performance Features

- Configurable package cache validity
- Retry mechanisms for failed operations
- Execution time tracking
- Resource usage monitoring
- Optimized APT operations

## Security Features

- GPG signature verification for packages
- Secure configuration file permissions
- No hardcoded secrets
- Input validation and sanitization
- Audit trail through structured logging

## Troubleshooting

### Common Issues

1. **Package Installation Failures**
   - Check network connectivity
   - Verify package names are correct
   - Ensure sufficient disk space

2. **Permission Errors**
   - Run playbook with `become: true`
   - Check sudo configuration
   - Verify user has necessary privileges

3. **Validation Failures**
   - Check parameter types and values
   - Ensure all required variables are defined
   - Verify OS compatibility

### Debug Mode

Enable debug mode for detailed output:

```yaml
- role: install_packages
  vars:
    debug_mode: true
```

This will provide:
- Detailed system information
- Package availability analysis
- Installation progress tracking
- Performance metrics
- Comprehensive error details

## License

MIT

## Author

System Administrator [mad.axell@gmail.com]
