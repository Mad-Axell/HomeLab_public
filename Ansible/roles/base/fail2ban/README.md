# Fail2Ban Configuration Role

This Ansible role configures Fail2Ban with security best practices to protect your system against brute force attacks and unauthorized access attempts.

## Overview

Fail2Ban is an intrusion prevention software framework that protects computer servers from brute-force attacks. This role provides a comprehensive configuration that includes:

- SSH protection with customizable jail settings
- Configurable logging and monitoring
- Integration with UFW firewall
- Support for additional service jails (nginx, apache, etc.)
- Comprehensive validation and error handling

## Requirements

- Ansible 2.9 or higher
- Debian-based Linux distribution (Ubuntu, Debian)
- Root or sudo privileges
- UFW firewall (recommended)

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
| `fail2ban_jails.ssh.enabled` | `true` | Enable SSH jail |
| `fail2ban_jails.ssh.maxretry` | `3` | Maximum failed attempts |
| `fail2ban_jails.ssh.findtime` | `600` | Time window for attempts (seconds) |
| `fail2ban_jails.ssh.bantime` | `3600` | Ban duration (seconds) |
| `fail2ban_jails.ssh.banaction` | `ufw` | Ban action to use |

### Logging Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `ssh_logging.enabled` | `true` | Enable SSH logging |
| `ssh_logging.log_directory` | `/var/log/sshd` | SSH log directory |
| `ssh_logging.log_file` | `sshd.log` | SSH log file name |
| `ssh_logging.log_level` | `INFO` | SSH log level |

### Security Settings

| Variable | Default | Description |
|----------|---------|-------------|
| `fail2ban_ignoreip` | `['127.0.0.1/8', '::1', '192.168.1.0/24', '10.20.30.0/24']` | IPs to never ban |
| `backup_configuration` | `true` | Backup existing config |
| `validate_configuration` | `true` | Validate configuration |

## Example Playbook

```yaml
---
- hosts: servers
  become: true
  roles:
    - role: base/fail2ban
      vars:
        ssh_port: 2222
        fail2ban_jails:
          ssh:
            enabled: true
            maxretry: 5
            findtime: 300
            bantime: 7200
        fail2ban_ignoreip:
          - "127.0.0.1/8"
          - "::1"
          - "192.168.1.0/24"
          - "10.0.0.0/8"
```

## Advanced Configuration

### Custom Jails

You can add custom jails for additional services:

```yaml
fail2ban_additional_jails:
  nginx-http-auth:
    enabled: true
    port: "http,https"
    filter: nginx-http-auth
    logpath: /var/log/nginx/error.log
    maxretry: 3
    findtime: 600
    bantime: 3600
    banaction: ufw
```

### Custom Filters and Actions

```yaml
fail2ban_custom_filters:
  custom_filter:
    failregex: "^<HOST> .*$"
    ignoreregex: ""

fail2ban_custom_actions:
  custom_action:
    actionstart: ""
    actionstop: ""
    actioncheck: ""
    actionban: ""
    actionunban: ""
```

## Security Best Practices

1. **Configure ignore IPs**: Always include your management networks
2. **Use appropriate timeouts**: Balance security with usability
3. **Monitor logs**: Regularly check Fail2Ban logs for false positives
4. **Test configuration**: Verify rules work before production deployment
5. **Backup configuration**: Always backup before making changes

## Troubleshooting

### Common Issues

1. **Service not starting**: Check configuration syntax with `fail2ban-client reload`
2. **False positives**: Adjust `maxretry` and `findtime` values
3. **Log file issues**: Ensure log files exist and are readable
4. **UFW integration**: Verify UFW is properly configured

### Debug Commands

```bash
# Check Fail2Ban status
fail2ban-client status

# Check specific jail
fail2ban-client status sshd

# View banned IPs
fail2ban-client get sshd banned

# Test configuration
fail2ban-client reload

# View logs
tail -f /var/log/fail2ban.log
```

## Dependencies

This role has no external dependencies but works best with:
- `base/configure_ufw` role for firewall integration
- `base/security` role for additional security hardening

## License

This role is part of the HomeLab project and follows the same licensing terms.

## Contributing

When contributing to this role:
1. Follow Ansible best practices
2. Add appropriate validation
3. Update documentation
4. Test thoroughly before submitting
