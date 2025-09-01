# PAM Configuration Role

This Ansible role configures PAM (Pluggable Authentication Modules) for enhanced system security on Linux systems.

## Overview

The PAM Configuration role implements comprehensive security measures through PAM modules:

- **Account Lockout Protection**: Prevents brute-force attacks using `pam_faillock` and `pam_tally2`
- **Password Quality Enforcement**: Ensures strong passwords with `pam_pwquality`
- **Session Control**: Manages user sessions and limits with `pam_limits`
- **Privilege Escalation Control**: Restricts `su` and `sudo` access with `pam_wheel`
- **Root Access Restrictions**: Secures root login and SSH access
- **Additional Security**: Implements umask and MOTD for enhanced security

## Requirements

- Ansible 2.9+
- Target system: Debian/Ubuntu or RedHat/CentOS
- Root or sudo privileges
- Required PAM modules (usually pre-installed)

## Role Variables

### Debug and Backup Settings

| Variable | Default | Description |
|----------|---------|-------------|
| `debug_mode` | `false` | Enable verbose debug output |
| `pam_backup_enabled` | `true` | Create backups before modifications |
| `pam_backup_suffix` | `.backup` | Backup file suffix |

### PAM Faillock Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `pam_faillock_deny` | `3` | Failed attempts before lockout (1-10) |
| `pam_unlock_time` | `1800` | Lockout duration in seconds (60-86400) |
| `pam_faillock_audit` | `true` | Enable audit logging |
| `pam_faillock_silent` | `false` | Silent lockout mode |

### Password Quality Settings

| Variable | Default | Description |
|----------|---------|-------------|
| `pam_pwquality_retry` | `3` | Password entry retries (1-5) |
| `pam_pwquality_minlen` | `12` | Minimum password length (8-32) |
| `pam_pwquality_difok` | `5` | Different chars from old password (1-10) |
| `pam_pwquality_ucredit` | `-1` | Require uppercase letters |
| `pam_pwquality_lcredit` | `-1` | Require lowercase letters |
| `pam_pwquality_dcredit` | `-1` | Require digits |
| `pam_pwquality_ocredit` | `-1` | Require special characters |
| `pam_pwquality_minclass` | `3` | Require character classes (1-4) |
| `pam_pwquality_maxrepeat` | `2` | Max consecutive repeated chars (0-10) |
| `pam_pwquality_gecoscheck` | `true` | Check against GECOS info |
| `pam_pwquality_reject_username` | `true` | Reject passwords with username |

### Session and Limits

| Variable | Default | Description |
|----------|---------|-------------|
| `pam_limits_enabled` | `true` | Enable PAM limits |
| `pam_limits_maxlogins` | `10` | Max concurrent logins per user (1-100) |
| `pam_limits_maxsyslogins` | `50` | Max concurrent system logins (10-1000) |

### Wheel and Sudo Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `pam_wheel_group` | `sudo` | Group for wheel functionality |
| `pam_wheel_use_uid` | `true` | Use UID instead of username |

### PAM Tally2 (Alternative Lockout)

| Variable | Default | Description |
|----------|---------|-------------|
| `pam_tally2_enabled` | `true` | Enable PAM tally2 |
| `pam_tally2_deny` | `5` | Deny after N failed attempts (1-10) |
| `pam_tally2_unlock_time` | `1800` | Unlock time in seconds (60-86400) |
| `pam_tally2_reset` | `true` | Reset counter on successful login |

### Root Access Security

| Variable | Default | Description |
|----------|---------|-------------|
| `pam_root_console_only` | `true` | Restrict root to console only |
| `pam_root_securetty` | `true` | Use secure TTY for root login |

## Dependencies

This role has no dependencies on other roles.

## Example Playbook

```yaml
---
- hosts: servers
  become: yes
  roles:
    - role: base/configure_pam
      vars:
        pam_faillock_deny: 5
        pam_unlock_time: 900
        pam_pwquality_minlen: 16
        debug_mode: true
```

## Advanced Configuration

### Custom Password Policy

```yaml
---
- hosts: servers
  become: yes
  roles:
    - role: base/configure_pam
      vars:
        pam_pwquality_minlen: 16
        pam_pwquality_minclass: 4
        pam_pwquality_maxrepeat: 1
        pam_pwquality_gecoscheck: true
        pam_pwquality_reject_username: true
```

### Strict Lockout Policy

```yaml
---
- hosts: servers
  become: yes
  roles:
    - role: base/configure_pam
      vars:
        pam_faillock_deny: 3
        pam_unlock_time: 3600
        pam_faillock_audit: true
        pam_faillock_silent: false
```

## Tags

The role supports the following tags for selective execution:

- `pam` - All PAM-related tasks
- `validation` - Parameter validation tasks
- `backup` - Backup creation tasks
- `setup` - Initial setup tasks
- `faillock` - Account lockout configuration
- `tally2` - PAM tally2 configuration
- `password` - Password quality configuration
- `limits` - Session limits configuration
- `wheel` - Wheel group configuration
- `sudo` - Sudo access configuration
- `root` - Root access restrictions
- `verify` - Configuration verification
- `debug` - Debug output tasks

## Files Modified

The role modifies the following system files:

- `/etc/pam.d/common-auth`
- `/etc/pam.d/common-account`
- `/etc/pam.d/common-password`
- `/etc/pam.d/common-session`
- `/etc/pam.d/su`
- `/etc/sudoers.d/`
- `/etc/security/limits.conf`
- `/etc/securetty`
- `/etc/ssh/sshd_config`

## Security Considerations

1. **Backup Creation**: Always enable backups before applying changes
2. **Testing**: Test configuration in a safe environment first
3. **Access Control**: Ensure you have alternative access methods
4. **Monitoring**: Monitor system logs after applying changes
5. **Rollback**: Keep backup files for potential rollback

## Troubleshooting

### Common Issues

1. **Locked Out**: Use console access or boot into recovery mode
2. **SSH Issues**: Check SSH configuration and restart service
3. **Password Problems**: Verify password policy settings
4. **Permission Errors**: Ensure proper file permissions

### Verification Commands

```bash
# Check PAM configuration
pam_tally2 --user username

# Verify password policy
cat /etc/pam.d/common-password

# Check account lockout
cat /etc/pam.d/common-auth

# Test sudo access
sudo -l
```

## License

This role is provided as-is for educational and security hardening purposes.

## Contributing

When contributing to this role:

1. Follow Ansible best practices
2. Add appropriate validation
3. Include error handling
4. Update documentation
5. Test thoroughly
