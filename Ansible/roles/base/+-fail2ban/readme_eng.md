# Fail2ban Ansible Role - English Documentation

## Table of Contents

1. [Overview](#overview)
2. [Features](#features)
3. [Supported Operating Systems](#supported-operating-systems)
4. [Requirements](#requirements)
5. [Installation](#installation)
6. [Role Variables](#role-variables)
7. [Dependencies](#dependencies)
8. [Example Playbooks](#example-playbooks)
9. [Integration with host_vars/dashboard.yml](#integration-with-host_varsdashboardyml)
10. [Advanced Configuration](#advanced-configuration)
11. [Troubleshooting](#troubleshooting)
12. [Contributing](#contributing)

## Overview

The Fail2ban Ansible role provides comprehensive installation and configuration of the Fail2ban intrusion prevention system across multiple Linux distributions. This role is designed to protect SSH access while maintaining connectivity for authorized users from trusted networks.

## Features

### Core Features
- **Cross-platform support**: Debian, Ubuntu, RedHat, CentOS, Rocky Linux, AlmaLinux, SUSE, openSUSE
- **SSH protection**: Configurable SSH brute-force protection with whitelist support
- **User-based protection**: Integration with user management systems
- **Firewall integration**: Support for iptables, firewalld, UFW
- **Email notifications**: Configurable email alerts
- **Comprehensive logging**: Detailed logging and log rotation
- **Security hardening**: SELinux, AppArmor support
- **Backup and recovery**: Automatic configuration backups

### Advanced Features
- **Universal package mapping**: Automatic package name resolution across distributions
- **OS-specific task execution**: Optimized tasks for each operating system family
- **Comprehensive validation**: Parameter validation with detailed error messages
- **Structured error handling**: Graceful error handling with informative debug output
- **Performance optimization**: Configurable memory and thread limits
- **Security compliance**: File permissions and SELinux context management

## Supported Operating Systems

| OS Family | Distributions | Package Manager | Firewall | Service Manager |
|-----------|---------------|-----------------|----------|-----------------|
| Debian    | Debian, Ubuntu, Linux Mint | apt | UFW, iptables | systemd |
| RedHat    | RHEL, CentOS, Rocky Linux, AlmaLinux, Fedora | yum/dnf | firewalld, iptables | systemd |
| SUSE      | openSUSE, SLES | zypper | iptables, SuSEfirewall2 | systemd |

## Requirements

### System Requirements
- Ansible 2.9 or higher
- Python 3.6 or higher
- Root or sudo privileges
- Internet access for package installation
- Minimum 512MB RAM
- Minimum 100MB disk space

### Network Requirements
- SSH access to target hosts
- Package repository access
- Email server access (if email notifications enabled)

## Installation

### From Ansible Galaxy
```bash
ansible-galaxy install fail2ban
```

### From Source
```bash
git clone https://github.com/your-repo/fail2ban-ansible-role.git
cd fail2ban-ansible-role
```

## Role Variables

### Main Configuration Variables

```yaml
# Debug and Validation Settings
debug_mode: true                    # Enable debug output
backup_enabled: true               # Enable configuration backups
validate_parameters: true          # Enable parameter validation
strict_validation: true            # Enable strict validation

# Fail2ban Installation Settings
fail2ban_install: true             # Install fail2ban package
fail2ban_service_enabled: true     # Enable fail2ban service
fail2ban_service_state: started    # Service state (started/stopped)
```

### Fail2ban Configuration

```yaml
fail2ban_config:
  loglevel: INFO                   # Log level (DEBUG, INFO, WARNING, ERROR, CRITICAL)
  logtarget: /var/log/fail2ban.log # Log file path
  socket: /var/run/fail2ban/fail2ban.sock # Socket file
  pidfile: /var/run/fail2ban/fail2ban.pid # PID file
  dbfile: /var/lib/fail2ban/fail2ban.sqlite3 # Database file
  dbpurgeage: 86400               # Database purge age in seconds
  ignoreip: []                    # IP addresses to ignore
  bantime: 600                    # Ban time in seconds
  findtime: 600                   # Find time in seconds
  maxretry: 3                     # Maximum retry attempts
  action: iptables-multiport      # Default action
```

### SSH Protection Settings

```yaml
ssh_protection:
  enabled: true                   # Enable SSH protection
  port: "22"                      # SSH port
  protocol: tcp                   # SSH protocol
  maxretry: 3                     # Maximum SSH retry attempts
  bantime: 3600                   # SSH ban time in seconds
  findtime: 600                   # SSH find time in seconds
  whitelist_enabled: true         # Enable whitelist
  whitelist_ips: []               # Additional IPs to whitelist
  whitelist_networks: []          # Additional networks to whitelist
```

### User-based Protection Settings

```yaml
user_based_protection:
  enabled: true                   # Enable user-based protection
  trusted_users: []               # List of trusted users
  trusted_networks: []            # List of trusted networks
```

### Firewall Integration Settings

```yaml
firewall_integration:
  enabled: true                   # Enable firewall integration
  firewall_backend: auto          # Firewall backend (auto, iptables, firewalld, ufw)
  firewall_chain: INPUT           # Firewall chain
```

### Email Notification Settings

```yaml
email_notifications:
  enabled: false                  # Enable email notifications
  destemail: root@localhost       # Destination email
  sender: fail2ban@localhost      # Sender email
  action: "%%(action_mw)s"        # Email action
```

### Security Settings

```yaml
security_settings:
  config_file_mode: '0644'        # Configuration file permissions
  log_file_mode: '0640'           # Log file permissions
  socket_file_mode: '0644'        # Socket file permissions
  selinux_enabled: false          # Enable SELinux support
  selinux_context: system_u:object_r:fail2ban_exec_t:s0 # SELinux context
```

### Performance Settings

```yaml
performance_settings:
  max_memory: 256                 # Maximum memory usage in MB
  max_threads: 4                  # Maximum number of threads
  db_max_connections: 10          # Maximum database connections
```

### Backup Settings

```yaml
backup_settings:
  backup_dir: /etc/fail2ban/backup # Backup directory
  backup_retention: 7             # Backup retention in days
  backup_compress: true           # Compress backups
```

## Dependencies

None

## Example Playbooks

### Basic Installation

```yaml
---
- hosts: servers
  become: yes
  roles:
    - fail2ban
```

### Advanced Configuration

```yaml
---
- hosts: servers
  become: yes
  roles:
    - fail2ban
  vars:
    debug_mode: true
    backup_enabled: true
    
    ssh_protection:
      enabled: true
      port: "2222"
      maxretry: 5
      bantime: 7200
      whitelist_networks:
        - "192.168.1.0/24"
        - "10.0.0.0/8"
    
    user_based_protection:
      enabled: true
      trusted_users:
        - admin
        - deploy
        - monitoring
    
    email_notifications:
      enabled: true
      destemail: admin@company.com
      sender: fail2ban@company.com
    
    firewall_integration:
      enabled: true
      firewall_backend: firewalld
    
    security_settings:
      selinux_enabled: true
      config_file_mode: '0600'
```

### Integration with Dashboard Users

```yaml
---
- hosts: dashboard
  become: yes
  roles:
    - fail2ban
  vars:
    ssh_protection:
      enabled: true
      whitelist_enabled: true
    
    user_based_protection:
      enabled: true
      # These will be automatically extracted from dashboard_users_to_add
      trusted_users: "{{ dashboard_users_to_add | map(attribute='username') | list }}"
      trusted_networks: "{{ dashboard_users_to_add | map(attribute='allowed_subnets') | flatten | unique }}"
```

## Integration with host_vars/dashboard.yml

The role automatically integrates with the `dashboard_users_to_add` variable from `host_vars/dashboard.yml`:

```yaml
# From host_vars/dashboard.yml
dashboard_users_to_add:
  - username: "admin"
    password: "secure_password"
    groups: ["sudo", "dashboard"]
    is_sudoers: true
    shell: /bin/bash
    allowed_subnets:
      - "192.168.1.0/24"
      - "10.20.30.0/24"
    denied_subnets: []
  - username: "deploy"
    password: "deploy_password"
    groups: ["dashboard"]
    is_sudoers: false
    shell: /bin/bash
    allowed_subnets:
      - "192.168.1.0/24"
      - "10.20.30.0/24"
    denied_subnets: []
```

The role will automatically:
- Extract trusted users from `dashboard_users_to_add`
- Extract trusted networks from `allowed_subnets`
- Configure fail2ban to whitelist these users and networks
- Ensure SSH access is maintained for authorized users

## Advanced Configuration

### Custom Jails

```yaml
additional_jails:
  apache:
    enabled: true
    port: "http,https"
    filter: apache-auth
    logpath: /var/log/apache2/error.log
    maxretry: 3
    bantime: 600
    findtime: 600
  
  nginx:
    enabled: true
    port: "http,https"
    filter: nginx-http-auth
    logpath: /var/log/nginx/error.log
    maxretry: 3
    bantime: 600
    findtime: 600
```

### Custom Filters and Actions

```yaml
advanced_settings:
  custom_filters:
    - /etc/fail2ban/filter.d/custom-filter.conf
  
  custom_actions:
    - /etc/fail2ban/action.d/custom-action.conf
  
  custom_jails:
    - name: custom-service
      enabled: true
      port: 8080
      filter: custom-service
      logpath: /var/log/custom-service.log
      maxretry: 5
      bantime: 1800
      findtime: 300
```

## Troubleshooting

### Common Issues

1. **Service fails to start**
   - Check configuration syntax: `fail2ban-client -t`
   - Verify log file permissions
   - Check firewall rules

2. **SSH access blocked**
   - Verify whitelist configuration
   - Check trusted networks
   - Review fail2ban logs: `journalctl -u fail2ban`

3. **Package installation fails**
   - Update package cache
   - Check repository configuration
   - Verify network connectivity

### Debug Mode

Enable debug mode for detailed output:

```yaml
debug_mode: true
```

### Log Files

- Fail2ban logs: `/var/log/fail2ban.log`
- System logs: `journalctl -u fail2ban`
- Configuration test: `fail2ban-client -t`

### Useful Commands

```bash
# Check fail2ban status
fail2ban-client status

# Check specific jail
fail2ban-client status sshd

# Unban IP
fail2ban-client set sshd unbanip 192.168.1.100

# Test configuration
fail2ban-client -t

# Reload configuration
systemctl reload fail2ban
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

MIT

## Author Information

This role was created following the ansible-rule standards for enterprise-grade Ansible role development.
