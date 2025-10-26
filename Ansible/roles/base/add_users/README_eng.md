# base.add_users - Complete English Documentation

## Role Overview

The `base.add_users` role is designed for comprehensive user management on Linux systems with advanced security configuration, group management, and sudo privileges setup. This role supports multiple Linux distributions and provides extensive security hardening capabilities.

## Features

### Core Functionality
- **User Management**: Create and update user accounts with customizable parameters
- **Group Management**: Automatic group creation and membership assignment
- **Sudo Configuration**: Granular sudo privileges with security groups
- **Security Hardening**: PAM configuration, password policies, and account security
- **Cross-Platform Support**: Ubuntu, Debian, RHEL/CentOS, and openSUSE
- **Multilingual Support**: English and Russian debug output

### Security Features
- **Password Policies**: Configurable password strength requirements
- **Account Lockout**: Automatic account lockout for inactive users
- **Password History**: Prevention of password reuse
- **PAM Integration**: OS-specific PAM configuration for enhanced security
- **Secure Permissions**: Proper file and directory permissions

### Advanced Features
- **Security Groups**: Role-based access control with granular permissions
- **Structured Logging**: Comprehensive operation logging with correlation IDs
- **Error Handling**: Graceful degradation and automatic rollback
- **Validation**: Extensive input validation and preflight checks
- **Performance**: Optimized execution with retry mechanisms

## Requirements

### System Requirements
- **Ansible**: Version 2.14 or higher
- **Python**: Version 3.8 or higher
- **Operating Systems**: Ubuntu 20.04+, Debian 11+, RHEL 8+, openSUSE 15+
- **Privileges**: Root access required for user management

### Dependencies
- **Ansible Modules**: user, group, file, lineinfile, template, systemd
- **System Packages**: sudo, passwd, libpam-pwquality, libpam-modules
- **Utilities**: visudo, chage, useradd, usermod

## Role Variables

### Core Configuration

```yaml
# User management
users_to_add: []                    # List. Users to create or update
  - username: "user_name"           # String. Username (required)
    password: "secure_password"      # String. Plain text password (required)
    groups: ["group1", "group2"]    # List. User groups
    is_sudoers: true                # Boolean. Grant sudo privileges
    shell: "/bin/bash"              # String. User shell
    uid: 1001                       # Integer. User ID (optional)
    gid: 1001                       # Integer. Group ID (optional)
    create_home: true               # Boolean. Create home directory
    home: "/home/user_name"         # String. Home directory path

# Debug configuration
debug_mode: false                   # Boolean. Enable detailed debug output
debug_lang: 'both'                  # String. Debug language: english/russian/both
debug_show_passwords: false         # Boolean. Show passwords in debug (INSECURE)
```

### Security Configuration

```yaml
# Password policies
add_users_validate_passwords: true     # Boolean. Enable password validation
add_users_min_password_length: 8     # Integer. Minimum password length
password_max_age: 90                 # Integer. Maximum password age in days
password_warn_age: 14                # Integer. Password warning age in days
account_inactive_days: 30            # Integer. Days until account locks
pam_deny_attempts: 3                 # Integer. Failed login attempts before lockout
pam_unlock_time: 900                 # Integer. Account unlock time in seconds
password_remember_count: 12          # Integer. Number of old passwords to remember

# File permissions
umask_system_users: '0027'           # String. Umask for system users
home_dir_permissions: '0750'         # String. Home directory permissions
```

### Security Groups Configuration

```yaml
security_groups:
  admins:                            # Full administrative access
    members: ["admin1", "admin2"]
    commands: ["ALL"]
    nopasswd: true
  operators:                         # Limited operational access
    members: ["op1", "op2"]
    commands:
      - "/bin/systemctl restart *"
      - "/bin/systemctl stop *"
    nopasswd: false
  auditors:                          # Read-only audit access
    members: ["audit1"]
    commands:
      - "/bin/cat /var/log/*"
      - "/bin/journalctl *"
    nopasswd: true
```

### Performance Configuration

```yaml
# Rollback and backup
enable_rollback: true                # Boolean. Enable automatic rollback on failure
backup_config: true                  # Boolean. Create backup before changes

# Performance tuning
retries: 3                           # Integer. Number of retries for failed tasks
retry_delay: 5                       # Integer. Delay between retries in seconds
```

## Usage Examples

### Basic User Creation

```yaml
- hosts: servers
  roles:
    - role: base.add_users
      vars:
        users_to_add:
          - username: "john"
            password: "SecurePass123"
            groups: ["docker", "wheel"]
            is_sudoers: true
```

### Advanced Configuration

```yaml
- hosts: servers
  roles:
    - role: base.add_users
      vars:
        debug_mode: true
        debug_lang: "english"
        users_to_add:
          - username: "admin"
            password: "AdminPass123"
            groups: ["wheel", "docker"]
            is_sudoers: true
            shell: "/bin/bash"
            uid: 1001
            create_home: true
          - username: "operator"
            password: "OpPass123"
            groups: ["operators"]
            is_sudoers: false
        security_groups:
          operators:
            members: ["operator"]
            commands:
              - "/bin/systemctl restart *"
              - "/bin/systemctl stop *"
            nopasswd: false
```

### Security Hardening

```yaml
- hosts: servers
  roles:
    - role: base.add_users
      vars:
        # Enhanced security settings
        add_users_validate_passwords: true
        add_users_min_password_length: 12
        password_max_age: 60
        password_warn_age: 7
        account_inactive_days: 15
        pam_deny_attempts: 3
        pam_unlock_time: 1800
        password_remember_count: 24
        
        # Secure permissions
        umask_system_users: '0027'
        home_dir_permissions: '0700'
        
        users_to_add:
          - username: "secure_user"
            password: "VerySecurePassword123!"
            is_sudoers: true
```

## Task Flow

### 1. Preflight Checks
- Ansible version validation (≥2.14)
- OS compatibility check
- Python version validation (≥3.8)
- System information gathering

### 2. Input Validation
- Required parameter validation
- Username format validation
- Password strength validation
- Reserved username checks
- Duplicate username detection

### 3. Group Management
- Extract unique groups from user configuration
- Create required groups
- Handle group creation errors gracefully

### 4. User Management
- Create new users with full configuration
- Update existing users
- Configure group memberships
- Set up home directories with proper permissions

### 5. Sudo Configuration
- Create granular sudoers files
- Configure security groups
- Validate sudoers configuration
- Clean up unused sudoers files

### 6. Security Hardening
- Configure PAM for password policies
- Set up account lockout policies
- Configure password history
- Apply secure permissions

## Error Handling

### Graceful Degradation
- Continue execution with partial failures
- Log detailed error information
- Provide rollback mechanisms
- Maintain system stability

### Retry Mechanisms
- Automatic retries for transient failures
- Configurable retry count and delays
- Exponential backoff for critical operations

### Rollback Support
- Automatic backup creation
- Configuration restoration on failure
- State recovery mechanisms

## Logging

### Structured Logging
All operations are logged with structured JSON format:

```json
{
  "timestamp": "2024-01-15T10:30:00Z",
  "level": "INFO",
  "event_type": "USER_CREATION",
  "user": "ansible_user",
  "host": "target_host",
  "correlation_id": "1705312200",
  "message": "User created successfully",
  "metadata": {
    "username": "john",
    "groups": ["docker", "wheel"],
    "sudo_privileges": true
  }
}
```

### Debug Output
- Detailed operation summaries
- Bilingual support (English/Russian)
- Password masking for security
- Performance metrics

## Security Considerations

### Password Security
- Passwords are hashed using SHA-512
- Password masking in debug output
- Configurable password strength requirements
- Password history tracking

### File Permissions
- Secure home directory permissions
- Proper sudoers file permissions
- Configurable umask settings
- Backup file security

### Access Control
- Role-based access control
- Granular sudo permissions
- Account lockout policies
- Audit trail maintenance

## Performance Optimization

### Execution Optimization
- Parallel task execution where possible
- Conditional task execution
- Efficient fact gathering
- Resource optimization

### Monitoring
- Execution time tracking
- Resource usage monitoring
- Performance metrics collection
- Bottleneck identification

## Troubleshooting

### Common Issues
1. **Permission Denied**: Ensure root privileges
2. **PAM Configuration**: Check package installation
3. **Sudoers Validation**: Use `visudo -c` for validation
4. **User Creation**: Verify username format and availability

### Debug Mode
```yaml
debug_mode: true
debug_lang: "english"
debug_show_passwords: true  # ONLY for testing!
```

### Log Analysis
- Check structured logs for detailed information
- Use correlation IDs for operation tracking
- Monitor error patterns
- Validate configuration changes

## Best Practices

### Security
- Use strong passwords
- Enable password validation
- Configure appropriate lockout policies
- Regular security audits

### Configuration
- Use Ansible Vault for sensitive data
- Implement least privilege principles
- Regular backup of configurations
- Monitor sudo usage

### Maintenance
- Regular password updates
- Security group reviews
- Permission audits
- Log analysis

## Support

For issues and questions:
- **Author**: Mad-Axell [mad.axell@gmail.com]
- **License**: MIT
- **Version**: 1.0.0
- **Ansible Version**: 2.14+
