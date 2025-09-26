# Fail2Ban Ansible Role

## Description

The `base/fail2ban` role is designed for automated setup and configuration of the Fail2Ban intrusion prevention system following Ansible security best practices. The role provides comprehensive protection for SSH servers and other services against brute-force attacks and unauthorized access attempts.

### Version 2.0.0 - Improvements

- ✅ **Comprehensive parameter validation** - all parameters are validated before application
- ✅ **Enhanced debug information** - detailed execution logs for troubleshooting
- ✅ **Improved task names** - more descriptive and informative task names
- ✅ **Bilingual comments** - all comments in English and Russian languages
- ✅ **Complete tagging** - all tasks are properly tagged for selective execution
- ✅ **Updated documentation** - comprehensive guides and usage examples

## Purpose

Fail2Ban is an intrusion prevention software framework that protects computer servers from brute-force attacks. This role provides:

- **SSH Protection**: Configures SSH jail with customizable settings
- **UFW Integration**: Automatically blocks IP addresses through UFW firewall
- **Configurable Logging**: Configures rsyslog for detailed SSH logging
- **Configuration Validation**: Validates all parameters before application
- **Debug Information**: Detailed execution logs for troubleshooting
- **Additional Services Support**: Ability to configure jails for nginx, apache, and other services

## Requirements

### System Requirements
- **Ansible**: version 2.9 or higher
- **OS**: Debian-based Linux (Ubuntu, Debian)
- **Access Rights**: root or sudo privileges
- **Firewall**: UFW (recommended)

### Dependencies
- `fail2ban` - main protection system
- `rsyslog` - logging system
- `iptables` - for firewall operations

## Role Variables

### Main Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `fail2ban_install` | `true` | Whether to install Fail2Ban |
| `fail2ban_packages` | `['fail2ban', 'rsyslog', 'iptables']` | Required packages |
| `debug_mode` | `true` | Enable debug output |

### SSH Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `ssh_port` | `22` | SSH port number |
| `ssh_protocol` | `"tcp"` | SSH protocol |

### Jail Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `fail2ban_jails` | See below | Main Fail2Ban jails |
| `fail2ban_additional_jails` | See below | Additional jails |

#### Main Jails (fail2ban_jails)

```yaml
fail2ban_jails:
  ssh:
    enabled: true
    port: "{{ ssh_port }}"
    filter: sshd
    logpath: /var/log/sshd/sshd.log
    maxretry: 3
    findtime: 600
    bantime: 3600
    banaction: ufw
    ignoreip: "127.0.0.1/8 ::1"
  
  sshd:
    enabled: true
    port: "{{ ssh_port }}"
    filter: sshd
    logpath: /var/log/auth.log
    maxretry: 3
    findtime: 600
    bantime: 3600
    banaction: ufw
    ignoreip: "127.0.0.1/8 ::1"
```

#### Additional Jails (fail2ban_additional_jails)

```yaml
fail2ban_additional_jails:
  nginx-http-auth:
    enabled: false
    port: "http,https"
    filter: nginx-http-auth
    logpath: /var/log/nginx/error.log
    maxretry: 3
    findtime: 600
    bantime: 3600
    banaction: ufw
  
  apache-auth:
    enabled: false
    port: "http,https"
    filter: apache-auth
    logpath: /var/log/apache2/error.log
    maxretry: 3
    findtime: 600
    bantime: 3600
    banaction: ufw
```

### Global Fail2Ban Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `fail2ban_global_config` | See below | Global Fail2Ban settings |

```yaml
fail2ban_global_config:
  loglevel: INFO
  logtarget: /var/log/fail2ban.log
  dbpurgeage: 86400
  socket: /var/run/fail2ban/fail2ban.sock
  pidfile: /var/run/fail2ban/fail2ban.pid
  dbfile: /var/lib/fail2ban/fail2ban.sqlite3
  banaction: ufw
  banaction_allports: ufw
```

### SSH Logging Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `ssh_logging` | See below | SSH logging settings |

```yaml
ssh_logging:
  enabled: true
  log_directory: /var/log/sshd
  log_file: sshd.log
  log_level: INFO
  syslog_facility: AUTH
```

### Ignored IP Addresses

| Variable | Default | Description |
|----------|---------|-------------|
| `fail2ban_ignoreip` | `['127.0.0.1/8', '::1', '192.168.1.0/24', '10.20.30.0/24']` | IP addresses that should never be banned |

### Service Management

| Variable | Default | Description |
|----------|---------|-------------|
| `fail2ban_service_state` | `started` | Fail2Ban service state |
| `fail2ban_service_enabled` | `true` | Fail2Ban service autostart |

### Validation Settings

| Variable | Default | Description |
|----------|---------|-------------|
| `validate_configuration` | `true` | Enable configuration validation |
| `fail_on_validation_error` | `true` | Stop execution on validation error |

### Backup Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `backup_configuration` | `true` | Create configuration backups |

### Custom Filters and Actions

| Variable | Default | Description |
|----------|---------|-------------|
| `fail2ban_custom_filters` | `{}` | Custom filters |
| `fail2ban_custom_actions` | `{}` | Custom actions |

## Usage Examples

### Basic Usage

```yaml
---
- hosts: servers
  become: true
  roles:
    - role: base/fail2ban
```

### Configuration with Custom Parameters

```yaml
---
- hosts: servers
  become: true
  roles:
    - role: base/fail2ban
      vars:
        ssh_port: 2222
        debug_mode: true
        fail2ban_jails:
          ssh:
            enabled: true
            maxretry: 5
            findtime: 300
            bantime: 7200
            ignoreip: "127.0.0.1/8 ::1 192.168.1.0/24"
```

### Enabling Additional Jails

```yaml
---
- hosts: webservers
  become: true
  roles:
    - role: base/fail2ban
      vars:
        fail2ban_additional_jails:
          nginx-http-auth:
            enabled: true
            maxretry: 3
            findtime: 600
            bantime: 3600
          apache-auth:
            enabled: true
            maxretry: 3
            findtime: 600
            bantime: 3600
```

### Configuration with Custom Filters

```yaml
---
- hosts: servers
  become: true
  roles:
    - role: base/fail2ban
      vars:
        fail2ban_custom_filters:
          custom-ssh:
            enabled: true
            port: "{{ ssh_port }}"
            filter: custom-ssh
            logpath: /var/log/custom-ssh.log
            maxretry: 3
            findtime: 600
            bantime: 3600
```

## Tags

The role supports the following tags for selective execution:

- `validation` - validation tasks
- `packages` - package installation
- `configuration` - configuration tasks
- `service` - service management
- `ssh` - SSH configuration
- `logging` - logging configuration
- `debug` - debug information
- `fail2ban` - all role tasks

### Tag Usage Examples

```bash
# Run only validation
ansible-playbook playbook.yml --tags validation

# Run only package installation
ansible-playbook playbook.yml --tags packages

# Skip debug information
ansible-playbook playbook.yml --skip-tags debug
```

## Role Structure

```
roles/base/fail2ban/
├── defaults/
│   └── main.yaml          # Default variables
├── handlers/
│   └── main.yml           # Event handlers
├── tasks/
│   ├── main.yaml          # Main tasks
│   ├── validate.yaml      # Configuration validation
│   ├── configure_ssh_logging.yaml  # SSH logging configuration
│   └── cleanup.yml        # Configuration cleanup
├── templates/
│   ├── fail2ban.conf.j2   # Global configuration template
│   └── jail.local.j2      # Jail configuration template
├── README.md              # Main documentation
├── readme_rus.md          # Full Russian documentation
├── readme_eng.md          # Full English documentation
├── SECURITY.md            # Security information
└── example-playbook.yml   # Example playbook
```

## Configuration Validation

The role includes comprehensive validation of all parameters:

### Validated Parameters

1. **Required Variables**: Check for presence of all necessary variables
2. **SSH Port**: Validate port number (1-65535)
3. **SSH Protocol**: Check protocol correctness (tcp/udp)
4. **Jail Configuration**: Validate all jail parameters
5. **IP Addresses**: Validate format of ignored IP addresses
6. **System**: Check operating system compatibility
7. **Disk Space**: Check available space for logs

### Disabling Validation

```yaml
---
- hosts: servers
  become: true
  roles:
    - role: base/fail2ban
      vars:
        validate_configuration: false
```

## Debug Information

The role provides detailed debug information:

### Enabling Debug Mode

```yaml
---
- hosts: servers
  become: true
  roles:
    - role: base/fail2ban
      vars:
        debug_mode: true
```

### Debug Information Includes

- Package installation status
- Directory and file creation results
- Service configuration status
- Validation results
- Service restart status
- Banned IP information

## Service Management

### Automatic Restart

The role automatically restarts services when configuration changes:

- `fail2ban` - when jail or global configuration changes
- `rsyslog` - when logging configuration changes
- `sshd` - when SSH settings change

### Manual Management

```bash
# Check Fail2Ban status
sudo systemctl status fail2ban

# Restart Fail2Ban
sudo systemctl restart fail2ban

# Check active jails
sudo fail2ban-client status

# Check specific jail
sudo fail2ban-client status sshd
```

## Monitoring and Logging

### Fail2Ban Logs

```bash
# Main Fail2Ban log
sudo tail -f /var/log/fail2ban.log

# SSH log (if separate logging is configured)
sudo tail -f /var/log/sshd/sshd.log

# System authentication log
sudo tail -f /var/log/auth.log
```

### Monitoring Banned IPs

```bash
# Show all banned IPs
sudo fail2ban-client status sshd

# Unban specific IP
sudo fail2ban-client set sshd unbanip 192.168.1.100

# Unban all IPs
sudo fail2ban-client unban --all
```

## Security

### Security Recommendations

1. **Configure Ignored IPs**: Add trusted networks to `fail2ban_ignoreip`
2. **Monitor Logs**: Regularly check logs for suspicious activity
3. **Updates**: Regularly update Fail2Ban and system
4. **Backups**: Use `backup_configuration: true`

### Configuration for High-Load Systems

```yaml
---
- hosts: servers
  become: true
  roles:
    - role: base/fail2ban
      vars:
        fail2ban_jails:
          ssh:
            enabled: true
            maxretry: 5        # More attempts for high-load systems
            findtime: 300      # Shorter detection time
            bantime: 1800      # Shorter ban time
```

## Troubleshooting

### Common Issues

#### 1. Fail2Ban Won't Start

```bash
# Check configuration
sudo fail2ban-client -t

# Check logs
sudo journalctl -u fail2ban -f
```

#### 2. SSH Jail Not Working

```bash
# Check log path
sudo fail2ban-client status sshd

# Check log file permissions
sudo ls -la /var/log/auth.log
```

#### 3. UFW Not Blocking IPs

```bash
# Check UFW status
sudo ufw status

# Check iptables rules
sudo iptables -L
```

### Diagnostic Commands

```bash
# Check Fail2Ban configuration
sudo fail2ban-client -t

# Reload configuration
sudo fail2ban-client reload

# Check active filters
sudo fail2ban-client status

# Check specific filter
sudo fail2ban-client get sshd logpath
```

## Configuration Cleanup

### Removing Fail2Ban

```yaml
---
- hosts: servers
  become: true
  roles:
    - role: base/fail2ban
      vars:
        fail2ban_cleanup: true
        fail2ban_remove_packages: true  # Remove packages
```

### What Gets Removed During Cleanup

- Stop and disable Fail2Ban service
- Remove configuration files
- Restore SSH settings
- Remove SSH log directory (optional)
- Remove packages (optional)

## Integration with Other Roles

### With UFW Role

```yaml
---
- hosts: servers
  become: true
  roles:
    - role: base/configure_ufw
      vars:
        ufw_default_policy: deny
        ufw_rules:
          - rule: allow
            port: "22"
            proto: tcp
    - role: base/fail2ban
```

### With Security Role

```yaml
---
- hosts: servers
  become: true
  roles:
    - role: base/security
    - role: base/fail2ban
```

## Performance

### Optimization for High-Load Systems

```yaml
---
- hosts: servers
  become: true
  roles:
    - role: base/fail2ban
      vars:
        fail2ban_global_config:
          loglevel: WARNING  # Less logging
          dbpurgeage: 43200  # More frequent DB cleanup
        fail2ban_jails:
          ssh:
            enabled: true
            maxretry: 5
            findtime: 300
            bantime: 1800
```

### Performance Monitoring

```bash
# Check resource usage
sudo systemctl status fail2ban
ps aux | grep fail2ban

# Check database size
sudo ls -lh /var/lib/fail2ban/fail2ban.sqlite3
```

## Updates and Support

### Updating the Role

1. Update the role from repository
2. Check for variable changes
3. Test on staging environment
4. Apply to production

### Getting Support

- Check execution logs with `debug_mode: true`
- Use tags to diagnose specific components
- Refer to Fail2Ban documentation
- Check version compatibility

## License

This role is part of the HomeLab project and follows the same licensing terms.

## Contributing

When contributing to this role:

1. Follow Ansible best practices
2. Add appropriate validation
3. Update documentation
4. Test thoroughly before submitting
5. Add tests for new features

## Changelog

### Version 2.0.0 (Current)
- ✅ **Comprehensive parameter validation** - added detailed validation of all configuration parameters
- ✅ **Enhanced debug information** - added detailed execution logs for all operations
- ✅ **Improved task names** - all tasks received more descriptive and informative names
- ✅ **Bilingual comments** - all comments translated to English and Russian languages
- ✅ **Complete tagging** - all tasks properly tagged for selective execution
- ✅ **Updated documentation** - created comprehensive guides and usage examples
- ✅ **Enhanced error handling** - added more robust error handling and exception management
- ✅ **Extended system validation** - added OS compatibility and resource availability checks

### Version 1.0.0
- Initial role version
- Basic Fail2Ban functionality
- SSH protection support
- UFW integration
- Core configuration tasks

## Ansible Best Practices Compliance

This role fully complies with Ansible best practices:

### ✅ Role Structure
- Proper file organization in directories
- Use of standard directories (tasks, handlers, templates, defaults)
- Clear separation of responsibilities between files

### ✅ Validation and Error Handling
- Comprehensive validation of all input parameters
- Operating system compatibility checks
- IP address and port format validation
- Disk space availability verification

### ✅ Tagging and Modularity
- All tasks properly tagged with appropriate tags
- Ability for selective component execution
- Modular structure with separate files for different functions

### ✅ Documentation and Comments
- Comprehensive documentation in two languages
- Comments for each task in English and Russian
- Usage examples and configuration guides
- Troubleshooting guides

### ✅ Security
- Adherence to principle of least privilege
- Proper file and directory permissions
- Validation of all user input data
- Configuration backup before changes

### ✅ Idempotency
- All tasks are idempotent
- State checking before operation execution
- Proper handling of repeated runs