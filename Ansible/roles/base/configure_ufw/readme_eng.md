# UFW Configuration Role

## Description

This Ansible role configures Uncomplicated Firewall (UFW) with security best practices for Ubuntu/Debian systems. The role provides comprehensive firewall configuration with parameter validation, debug information, and service status monitoring.

## Features

- **Secure Default Configuration**: Deny incoming, allow outgoing by default
- **SSH Access Control**: Configurable SSH access from specific subnets
- **Rate Limiting**: Optional SSH rate limiting to prevent brute force attacks
- **Custom Rules**: Flexible custom firewall rules
- **Input Validation**: Comprehensive validation of all parameters
- **Logging Configuration**: Configurable logging levels
- **Service Monitoring**: Comprehensive UFW service health checks and diagnostics
- **Configuration Backup**: Automatic backup before configuration changes
- **IPv6 Management**: Optional IPv6 support control
- **Idempotent**: Safe to run multiple times
- **Bilingual Support**: Comments and messages in Russian and English

## Requirements

- Ansible 2.9+
- Ubuntu/Debian target systems
- `community.general` collection

## Role Variables

### Basic Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `debug_mode` | `true` | Enable verbose output |
| `ssh_port` | `22` | SSH port number |
| `ssh_protocol` | `"tcp"` | SSH protocol (tcp/udp) |
| `users_to_add` | `[]` | List of users with their SSH access settings |

### UFW Policies

| Variable | Default | Description |
|----------|---------|-------------|
| `ufw_default_incoming` | `"deny"` | Default incoming policy |
| `ufw_default_outgoing` | `"allow"` | Default outgoing policy |
| `ufw_logging` | `"medium"` | Logging level (off/low/medium/high/full) |
| `ufw_state` | `"enabled"` | UFW state (enabled/disabled/reset) |

### Security Features

| Variable | Default | Description |
|----------|---------|-------------|
| `ssh_rate_limit` | `true` | Enable SSH rate limiting |
| `ssh_rate_limit_attempts` | `3` | Number of attempts before rate limiting (1-10) |
| `ssh_rate_limit_time` | `60` | Time window for rate limiting (seconds, 1-300) |

### Custom Rules

| Variable | Default | Description |
|----------|---------|-------------|
| `ufw_rules` | `[{"rule": "allow", "port": "80", "proto": "tcp", "comment": "HTTP"}, {"rule": "allow", "port": "443", "proto": "tcp", "comment": "HTTPS"}, {"rule": "allow", "port": "22", "proto": "tcp", "comment": "SSH"}]` | List of custom UFW rules |

### Validation

| Variable | Default | Description |
|----------|---------|-------------|
| `validate_configuration` | `true` | Enable input validation |
| `fail_on_validation_error` | `true` | Fail playbook on validation errors |
| `ufw_ipv6` | `false` | Enable/disable IPv6 support |
| `ufw_backup_enabled` | `true` | Enable configuration backup |
| `ufw_backup_dir` | `"/etc/ufw/backup"` | Backup directory path |
| `ufw_backup_suffix` | `".bak"` | Backup file suffix |
| `ufw_backup_count` | `5` | Number of backup files to keep (1-10) |

## Users and Custom UFW Rules Format

### User Structure

```yaml
users_to_add:
  - username: "admin"                    # username
    password: "SecurePassword123!"       # user password
    groups: ["sudo", "admin"]            # user groups
    is_sudoers: true                     # sudo privileges
    shell: /bin/bash                     # user shell
    allowed_subnets:                     # allowed subnets for SSH
      - "192.168.1.0/24"
      - "10.20.30.0/24"
    denied_subnets:                      # denied subnets for SSH
      - "192.168.0.0/24"
      - "10.10.10.0/24"
```

### Custom UFW Rules Format

```yaml
ufw_rules:
  - rule: "allow"           # allow, deny, reject, limit
    port: "80"              # port number or service name
    proto: "tcp"            # tcp or udp
    from_ip: "192.168.1.0/24"  # optional: restrict to specific IP/subnet
    comment: "HTTP access"  # optional: rule description
```

## Example Playbook

### Basic Usage

```yaml
- hosts: servers
  roles:
    - role: base/configure_ufw
```

### Advanced Configuration

```yaml
- hosts: servers
  vars:
    users_to_add:
      - username: "admin"
        password: "SecurePassword123!"
        groups: ["sudo", "admin"]
        is_sudoers: true
        shell: /bin/bash
        allowed_subnets:
          - "10.0.0.0/8"
          - "172.16.0.0/12"
        denied_subnets:
          - "192.168.0.0/24"
      - username: "developer"
        password: "DevPassword456!"
        groups: ["developers"]
        is_sudoers: false
        shell: /bin/bash
        allowed_subnets:
          - "10.1.0.0/16"
        denied_subnets: []
    ssh_port: 2222
    ufw_rules:
      - rule: "allow"
        port: "80"
        proto: "tcp"
        comment: "HTTP"
      - rule: "allow"
        port: "443"
        proto: "tcp"
        comment: "HTTPS"
      - rule: "allow"
        port: "3306"
        proto: "tcp"
        from_ip: "10.0.0.0/8"
        comment: "MySQL from internal network"
    ssh_rate_limit: true
    ufw_logging: "medium"
  roles:
    - role: base/configure_ufw
```

### Production Environment

```yaml
- hosts: production_servers
  vars:
    users_to_add:
      - username: "admin"
        password: "VerySecurePassword789!"
        groups: ["sudo", "admin"]
        is_sudoers: true
        shell: /bin/bash
        allowed_subnets:
          - "10.1.0.0/16"  # Management network
        denied_subnets:
          - "0.0.0.0/0"    # Deny access from internet
    ufw_rules:
      - rule: "allow"
        port: "443"
        proto: "tcp"
        comment: "HTTPS only"
    ssh_rate_limit: true
    ssh_rate_limit_attempts: 3
    ssh_rate_limit_time: 60
    ufw_logging: "high"
    debug_mode: false
  roles:
    - role: base/configure_ufw
```

## Security Best Practices

1. **Restrict SSH Access**: Only allow SSH from trusted subnets
2. **Use Non-Standard SSH Port**: Consider changing from port 22
3. **Enable Rate Limiting**: Prevent brute force attacks (3 attempts per 60 seconds)
4. **Minimal Rule Set**: Only allow necessary ports
5. **Regular Logging**: Monitor firewall activity (medium level logging)
6. **Disable IPv6**: Disable IPv6 support unless specifically needed
7. **Configuration Backup**: Always backup before making changes
8. **Test Configuration**: Always test in staging environment first

## Diagnostics and Monitoring

The role includes comprehensive diagnostics and monitoring capabilities:

### Service Status Monitoring
- **Service Health Checks**: Verifies UFW service is active and enabled
- **Systemctl Integration**: Uses systemctl to check service status
- **Detailed Status Reporting**: Shows ActiveState, SubState, and LoadState

### Logging and Debugging
- **Verbose Output**: When `debug_mode: true`, shows detailed configuration steps
- **Service Logs**: Displays UFW service logs if service is not active
- **Configuration Summary**: Shows final UFW configuration summary
- **Status Display**: Shows `ufw status verbose` output

### Error Handling
- **Validation Failures**: Comprehensive input validation with clear error messages
- **Service Assertions**: Ensures UFW service is properly configured
- **Backup Verification**: Creates backups before configuration changes

### Troubleshooting

If UFW service fails to start or configure properly:

1. **Check Service Status**: The role will automatically display service logs
2. **Verify Configuration**: Review the configuration summary output
3. **Check Logs**: Use `journalctl -u ufw.service` for detailed logs
4. **Validate Rules**: Ensure all custom rules are properly formatted
5. **Network Connectivity**: Verify SSH access from allowed subnets

## Tags

The role supports the following tags for selective execution:

- `validation` - Parameter validation
- `installation` - Package installation
- `backup` - Backup operations
- `configuration` - UFW configuration
- `ssh` - SSH settings
- `custom_rules` - Custom rules
- `rate_limiting` - Rate limiting
- `ipv6` - IPv6 settings
- `service` - Service management
- `debug` - Debug information
- `status` - Status checks
- `summary` - Final summary
- `handlers` - Handlers
- `ufw` - All UFW tasks

## Dependencies

This role has no dependencies on other roles.

## License

This role is licensed under the MIT License.

## Author Information

Created for HomeLab infrastructure management.

## Changelog

### v2.0.0
- Added bilingual support (Russian/English)
- Improved task names with descriptive titles
- Added tags for all tasks
- Enhanced debug information
- Improved parameter validation
- Added comprehensive service status checks

### v1.0.0
- Initial role version
- Basic UFW configuration
- Parameter validation
- Backup functionality
- Custom rules support
