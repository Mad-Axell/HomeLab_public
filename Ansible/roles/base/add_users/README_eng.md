# add_users - User Management Role

**Role:** `base.add_users`  
**Description:** Comprehensive user management role with sudo privileges and group configuration  
**Author:** Mad-Axell [mad.axell@gmail.com]  
**License:** MIT  
**Min Ansible Version:** 2.14  
**Supported Platforms:** Ubuntu 20.04+, Debian 11+

## Overview

The `add_users` role provides comprehensive user account management capabilities for Linux systems, including user creation, sudo privileges configuration, security group management, and security hardening. It supports granular sudo permissions through security groups and includes extensive validation and logging features.

## Features

### Core Functionality
- **User Account Management**: Create and update user accounts with full configuration options
- **Sudo Privileges**: Configure sudo access with granular permissions through security groups
- **Group Management**: Automatic creation and management of user groups
- **Password Management**: Secure password handling with automatic hashing

### Security Features
- **Password Policies**: Configurable password aging, complexity requirements, and history
- **PAM Configuration**: Automatic PAM setup for password quality and account lockout
- **Account Security**: Account inactivity lockout and secure home directory permissions
- **Input Validation**: Comprehensive validation of usernames, passwords, and configuration

### Advanced Features
- **Structured Logging**: JSON-formatted logging for all operations and changes
- **Error Handling**: Block-rescue patterns with automatic rollback on failure
- **Security Groups**: Granular sudo permissions with specific command restrictions
- **Validation**: Preflight checks and comprehensive input validation

## Requirements

### System Requirements
- **Operating System**: Debian family distributions (Ubuntu 20.04+, Debian 11+)
- **Ansible Version**: 2.14 or higher
- **Python Version**: 3.8 or higher
- **Privileges**: Root access required for user management operations

### Required Packages
The role automatically installs the following packages:
- `sudo` - Sudo privilege management
- `passwd` - Password management utilities

## Role Variables

### Required Variables

#### `users_to_add`
**Type:** `list`  
**Required:** `true`  
**Description:** List of users to create or update with their configuration parameters

**User Object Structure:**
```yaml
users_to_add:
  - username: "user1"                    # Required: Username (lowercase, alphanumeric, underscores)
    password: "SecurePass123"            # Required: Plain text password (will be hashed)
    groups: ["docker", "wheel"]          # Optional: List of groups
    is_sudoers: true                     # Optional: Grant sudo privileges (default: false)
    shell: "/bin/bash"                   # Optional: User shell (default: /bin/bash)
    uid: 1001                            # Optional: User ID (auto-assigned if not specified)
    gid: 1001                            # Optional: Primary group ID
    create_home: true                    # Optional: Create home directory (default: true)
    home: "/home/user1"                  # Optional: Custom home directory path
    security_groups: ["admins"]          # Optional: Security groups for granular sudo
    password_max_age: 90                 # Optional: Individual password max age (requires override)
```

### Optional Variables

#### Debug Configuration
```yaml
debug_mode: false                        # Boolean: Enable detailed debug output
debug_show_passwords: false              # Boolean: Show passwords in debug (INSECURE)
```

#### User Creation Defaults
```yaml
add_users_create_home: true              # Boolean: Create home directory by default
add_users_home_prefix: "/home"           # String: Home directory prefix
add_users_default_shell: "/bin/bash"     # String: Default shell for users
```

#### Password Validation
```yaml
add_users_validate_passwords: true       # Boolean: Enable password validation
add_users_min_password_length: 8         # Integer: Minimum password length
```

#### Security Configuration
```yaml
password_max_age: 90                     # Integer: Maximum password age in days
password_warn_age: 14                    # Integer: Password warning age in days
account_inactive_days: 30                # Integer: Days until account locks after password expiry
password_max_age_override: false         # Boolean: Allow individual password_max_age per user
pam_deny_attempts: 3                     # Integer: Failed login attempts before lockout
pam_unlock_time: 900                     # Integer: Account unlock time in seconds (15 min)
password_remember_count: 12              # Integer: Number of old passwords to remember
password_history_file: /etc/security/opasswd  # String: Password history file
umask_system_users: '0027'               # String: Umask for system users
home_dir_permissions: '0750'             # String: Home directory permissions
min_uid: 1000                            # Integer: Minimum UID for regular users
max_uid: 60000                           # Integer: Maximum UID for regular users
```

#### Security Groups Configuration
```yaml
security_groups:                         # Dictionary: Security groups with members and commands
  admins:                                # Full administrative access
    members: []                          # List: Usernames of admins
    commands:                            # List: Allowed commands (empty = ALL)
      - ALL
    nopasswd: false                      # Boolean: Allow NOPASSWD for these commands
  
  operators:                             # Limited operational access
    members: []                          # List: Usernames of operators
    commands:                            # List: Allowed commands
      - /bin/systemctl restart *
      - /bin/systemctl stop *
      - /bin/systemctl start *
      - /bin/systemctl status *
      - /bin/journalctl *
      - /usr/bin/docker *
      - /usr/local/bin/docker-compose *
    nopasswd: false                      # Boolean: Require password for these commands
  
  auditors:                              # Read-only audit access
    members: []                          # List: Usernames of auditors
    commands:                            # List: Allowed commands
      - /bin/cat /var/log/*
      - /bin/tail /var/log/*
      - /bin/grep * /var/log/*
      - /bin/journalctl *
      - /bin/systemctl status *
      - /usr/bin/find /var/log/*
    nopasswd: false                      # Boolean: Allow NOPASSWD for read-only commands
```

#### Rollback and Performance
```yaml
enable_rollback: true                    # Boolean: Enable automatic rollback on failure
backup_config: true                      # Boolean: Create backup before changes
async_timeout: 300                       # Integer: Timeout for async operations (seconds)
retries: 3                               # Integer: Number of retry attempts for failed tasks
retry_delay: 5                           # Integer: Delay between retry attempts (seconds)
```

#### Logging
```yaml
log_file: "/var/log/ansible-changes.log"  # String: Path to structured log file
```

## Dependencies

None. This role is self-contained and does not depend on other roles.

## Example Playbook

### Basic User Creation
```yaml
---
- hosts: all
  become: true
  vars:
    users_to_add:
      - username: admin_user
        password: "SecurePass123"
        is_sudoers: true
        groups: ["docker", "wheel"]
      - username: developer
        password: "DevPass456"
        groups: ["docker"]
        shell: "/bin/zsh"
  roles:
    - base.add_users
```

### Advanced Configuration with Security Groups
```yaml
---
- hosts: all
  become: true
  vars:
    users_to_add:
      - username: sysadmin
        password: "AdminPass789"
        is_sudoers: true
        security_groups: ["admins"]
        groups: ["docker", "wheel"]
      - username: operator
        password: "OpPass123"
        is_sudoers: true
        security_groups: ["operators"]
        groups: ["docker"]
      - username: auditor
        password: "AuditPass456"
        is_sudoers: true
        security_groups: ["auditors"]
    
    security_groups:
      admins:
        members: ["sysadmin"]
        commands: ["ALL"]
        nopasswd: false
      operators:
        members: ["operator"]
        commands:
          - /bin/systemctl restart *
          - /bin/systemctl stop *
          - /bin/systemctl start *
          - /usr/bin/docker *
        nopasswd: false
      auditors:
        members: ["auditor"]
        commands:
          - /bin/cat /var/log/*
          - /bin/journalctl *
        nopasswd: true
    
    debug_mode: true
    add_users_validate_passwords: true
    password_max_age: 60
    enable_rollback: true
    
  roles:
    - base.add_users
```

### Individual Password Policies
```yaml
---
- hosts: all
  become: true
  vars:
    users_to_add:
      - username: admin
        password: "AdminPass123"
        is_sudoers: true
        password_max_age: 30  # 30 days for admin
      - username: user
        password: "UserPass456"
        password_max_age: 90  # 90 days for regular user
    
    password_max_age_override: true  # Enable individual password policies
    
  roles:
    - base.add_users
```

## Security Features

### Password Policies
- **Password Aging**: Configurable maximum password age with individual overrides
- **Password Complexity**: Minimum length requirements and complexity validation
- **Password History**: Prevents reuse of recent passwords
- **Account Lockout**: Automatic account lockout after failed login attempts

### PAM Configuration
The role automatically configures PAM modules for:
- **Password Quality**: `pam_pwquality` for password complexity
- **Account Lockout**: `pam_faillock` for failed login protection
- **Password History**: `pam_unix` with password history tracking

### File Permissions
- **Home Directories**: Secure permissions (0750) for user home directories
- **Sudoers Files**: Proper permissions (0440) for sudo configuration files
- **Password History**: Secure permissions (0600) for password history file

## Structured Logging

The role implements comprehensive structured logging in JSON format. All operations are logged to `/var/log/ansible-changes.log` (configurable) with the following information:

- **Timestamp**: ISO 8601 format
- **Event Type**: Type of operation (USER_CREATE, PACKAGE_INSTALL, etc.)
- **User**: Ansible user executing the operation
- **Host**: Target hostname
- **Correlation ID**: Unique identifier for tracing related operations
- **Metadata**: Contextual information specific to each operation

### Log Event Types
- `USER_CREATE`: User account creation
- `PACKAGE_INSTALL`: Package installation
- `CONFIG_CHANGE`: Configuration file changes
- `SERVICE_CHANGE`: Service state changes
- `PERMISSION_CHANGE`: File permission changes
- `TASK_FAILURE`: Task execution failures

## Error Handling

The role implements comprehensive error handling with:

### Block-Rescue Patterns
- **User Creation**: Automatic rollback on user creation failures
- **Configuration Changes**: Backup and restore on configuration failures
- **Package Installation**: Graceful handling of package installation failures

### Rollback Mechanisms
- **Configuration Backup**: Automatic backup of modified configuration files
- **User Account Recovery**: Rollback of user account changes on failure
- **Sudoers Validation**: Automatic validation and rollback of invalid sudoers configurations

## Validation

### Preflight Checks
- **Ansible Version**: Ensures minimum Ansible version (2.14+)
- **OS Compatibility**: Validates Debian family distribution
- **Python Version**: Ensures minimum Python version (3.8+)

### Input Validation
- **Username Format**: Validates username follows system conventions
- **Password Strength**: Validates password meets minimum requirements
- **Shell Validation**: Ensures shell is in allowed shells list
- **UID Range**: Validates UID is within acceptable range
- **Duplicate Detection**: Prevents duplicate usernames in configuration

## Tags

The role supports the following tags for selective execution:

- `always`: Always executed tasks
- `debug`: Debug output tasks
- `facts`: Fact gathering tasks
- `groups`: Group management tasks
- `install`: Package installation tasks
- `packages`: Package-related tasks
- `preflight`: Preflight check tasks
- `security`: Security configuration tasks
- `sudo`: Sudo configuration tasks
- `users`: User management tasks
- `validation`: Input validation tasks

## Return Values

The role sets the following facts:

- `existing_usernames`: List of existing system usernames
- `unique_groups`: List of unique groups to be created
- `user_security_groups_map`: Mapping of users to security groups
- `validation_stats`: Validation statistics

## Troubleshooting

### Common Issues

1. **Permission Denied**: Ensure the playbook runs with `become: true`
2. **Invalid Username**: Check username follows system conventions (lowercase, alphanumeric, underscores)
3. **Password Too Short**: Ensure password meets minimum length requirements
4. **Sudoers Validation Failed**: Check security group configuration and command syntax

### Debug Mode

Enable debug mode for detailed output:
```yaml
vars:
  debug_mode: true
  debug_show_passwords: true  # WARNING: Shows passwords in output
```

### Log Analysis

Check the structured log file for detailed operation information:
```bash
tail -f /var/log/ansible-changes.log | jq .
```

## License

MIT

## Author Information

**Author:** Mad-Axell  
**Email:** mad.axell@gmail.com  
**Role Version:** 1.0.0  
**Last Updated:** 2024
