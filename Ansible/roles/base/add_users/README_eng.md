# base/add_users - Complete English Documentation

## Table of Contents

1. [Overview](#overview)
2. [Requirements](#requirements)
3. [Role Variables](#role-variables)
4. [Dependencies](#dependencies)
5. [Usage Examples](#usage-examples)
6. [Security Groups](#security-groups)
7. [Security Features](#security-features)
8. [Error Handling](#error-handling)
9. [Performance](#performance)
10. [Troubleshooting](#troubleshooting)
11. [Development](#development)

## Overview

The `base/add_users` role is a comprehensive user management solution for Linux systems that provides enterprise-grade features including user creation, sudo privilege management, security hardening, and cross-platform support.

### Key Features

- **User Management**: Create, update, and configure user accounts with full customization
- **Sudo Configuration**: Granular sudo privileges with security groups and command restrictions
- **Security Hardening**: Password policies, PAM configuration, account lockout, and access controls
- **Cross-Platform**: Support for Ubuntu, Debian, RHEL, and openSUSE systems
- **Comprehensive Validation**: Input validation, error handling, and rollback mechanisms
- **Structured Logging**: Detailed logging with JSON format for integration with log aggregators
- **Idempotent Operations**: Safe to run multiple times with consistent results

### Supported Operating Systems

| OS Family | Versions | Package Manager |
|-----------|----------|-----------------|
| Ubuntu    | 20.04, 22.04, 24.04 | apt |
| Debian    | 11, 12 | apt |
| RHEL      | 8, 9 | yum/dnf |
| openSUSE  | 15 | zypper |

## Requirements

### Ansible Requirements

- **Ansible Version**: 2.14 or higher
- **Python Version**: 3.8 or higher
- **Collections**: Uses only `ansible.builtin` modules

### System Requirements

- **Disk Space**: Minimum 1GB free space
- **Memory**: 512MB RAM minimum
- **Network**: Internet access for package installation
- **Privileges**: Root or sudo access required

### Required Packages

The role automatically installs the following packages:
- `sudo` - For privilege escalation
- `passwd` - For password management

## Role Variables

### Required Variables

#### `users_to_add`
**Type**: `list`  
**Required**: `true`  
**Description**: List of users to create or update with their configuration parameters

```yaml
users_to_add:
  - username: "john_doe"           # String. Username (lowercase, numbers, underscores only)
    password: "SecurePass123"      # String. Plain text password (will be hashed automatically)
    groups: ["docker", "wheel"]    # List. User groups (optional)
    is_sudoers: true               # Boolean. Grant sudo privileges (optional, default: false)
    shell: "/bin/bash"             # String. User shell (optional, default: /bin/bash)
    uid: 1001                      # Integer. User ID (optional, auto-assigned if not specified)
    gid: 1001                      # Integer. Primary group ID (optional, auto-assigned if not specified)
    create_home: true              # Boolean. Create home directory (optional, default: true)
    home: "/home/john_doe"         # String. Custom home directory path (optional)
    authorized_keys: []            # List. SSH public keys (optional)
    password_max_age: 90           # Integer. Password max age in days (optional, requires password_max_age_override: true)
```

### Optional Variables

#### Debug Configuration
```yaml
debug_mode: false                  # Boolean. Enable detailed debug output
debug_show_passwords: false        # Boolean. Show passwords in debug output (INSECURE)
```

#### User Creation Settings
```yaml
add_users_create_home: true        # Boolean. Default setting for home directory creation
add_users_home_prefix: "/home"     # String. Prefix path for user home directories
add_users_default_shell: "/bin/bash" # String. Default shell for users
```

#### Password Validation
```yaml
add_users_validate_passwords: true # Boolean. Enable password strength validation
add_users_min_password_length: 8   # Integer. Minimum password length requirement
```

#### Rollback Configuration
```yaml
enable_rollback: true              # Boolean. Enable automatic rollback on failure
backup_config: true                # Boolean. Create backup before changes
```

#### Performance Settings
```yaml
retries: 3                         # Integer. Number of retries for failed tasks
retry_delay: 5                     # Integer. Delay between retries in seconds
```

#### Security Policies
```yaml
password_max_age: 90               # Integer. Maximum password age in days
password_warn_age: 14              # Integer. Password warning age in days
password_max_age_override: false   # Boolean. Allow individual password_max_age per user
account_inactive_days: 30          # Integer. Days until account locks after password expiry
pam_deny_attempts: 3               # Integer. Failed login attempts before lockout
pam_unlock_time: 900               # Integer. Account unlock time in seconds (15 minutes)
password_remember_count: 12        # Integer. Number of old passwords to remember
password_history_file: /etc/security/opasswd # String. Password history file path
umask_system_users: '0027'         # String. Umask for system users
home_dir_permissions: '0750'       # String. Home directory permissions
```

#### Security Groups Configuration
```yaml
security_groups:                   # Dictionary. Security groups with members and allowed commands
  admins:                          # Full administrative access
    members: []                    # List. Usernames of admins
    commands:                      # List. Allowed commands (empty = ALL)
      - ALL
    nopasswd: true                 # Boolean. Allow NOPASSWD for these commands
    
  operators:                       # Limited operational access
    members: []                    # List. Usernames of operators
    commands:                      # List. Allowed commands
      - /bin/systemctl restart *
      - /bin/systemctl stop *
      - /bin/systemctl start *
      - /bin/systemctl status *
      - /bin/journalctl *
      - /usr/bin/docker *
      - /usr/local/bin/docker-compose *
    nopasswd: false                # Boolean. Require password for these commands
    
  auditors:                        # Read-only audit access
    members: []                    # List. Usernames of auditors
    commands:                      # List. Allowed commands
      - /bin/cat /var/log/*
      - /bin/tail /var/log/*
      - /bin/grep * /var/log/*
      - /bin/journalctl *
      - /bin/systemctl status *
      - /usr/bin/find /var/log/*
    nopasswd: true                 # Boolean. Allow NOPASSWD for read-only commands
```

## Dependencies

This role has no dependencies on other roles or collections. It uses only `ansible.builtin` modules.

## Usage Examples

### Basic User Creation

```yaml
- hosts: all
  roles:
    - role: base/add_users
      vars:
        users_to_add:
          - username: "john_doe"
            password: "SecurePass123"
            is_sudoers: true
            groups: ["sudo", "docker"]
```

### Advanced User Configuration

```yaml
- hosts: all
  roles:
    - role: base/add_users
      vars:
        debug_mode: true
        users_to_add:
          - username: "admin"
            password: "VerySecurePassword123!"
            groups: ["sudo", "docker", "wheel"]
            is_sudoers: true
            shell: "/bin/bash"
            uid: 1001
            create_home: true
            home: "/home/admin"
            authorized_keys:
              - "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC..."
            password_max_age: 60
            
          - username: "operator"
            password: "OperatorPass456!"
            groups: ["docker"]
            is_sudoers: true
            shell: "/bin/zsh"
            
          - username: "auditor"
            password: "AuditorPass789!"
            groups: ["audit"]
            is_sudoers: true
            shell: "/bin/bash"
```

### Security Groups Configuration

```yaml
- hosts: all
  roles:
    - role: base/add_users
      vars:
        security_groups:
          admins:
            members: ["admin", "root_admin"]
            commands: ["ALL"]
            nopasswd: true
            
          operators:
            members: ["operator1", "operator2"]
            commands:
              - "/bin/systemctl restart *"
              - "/bin/systemctl stop *"
              - "/usr/bin/docker *"
            nopasswd: false
            
          auditors:
            members: ["auditor1", "auditor2"]
            commands:
              - "/bin/cat /var/log/*"
              - "/bin/journalctl *"
            nopasswd: true
            
        users_to_add:
          - username: "admin"
            password: "AdminPass123!"
            is_sudoers: true
            
          - username: "operator1"
            password: "OperatorPass123!"
            is_sudoers: true
            
          - username: "auditor1"
            password: "AuditorPass123!"
            is_sudoers: true
```

### Production Configuration with Security Hardening

```yaml
- hosts: production_servers
  roles:
    - role: base/add_users
      vars:
        # Security hardening
        add_users_validate_passwords: true
        add_users_min_password_length: 12
        password_max_age: 60
        password_warn_age: 7
        account_inactive_days: 14
        pam_deny_attempts: 3
        pam_unlock_time: 1800  # 30 minutes
        
        # Rollback and backup
        enable_rollback: true
        backup_config: true
        
        # Logging
        log_file: "/var/log/ansible-user-management.log"
        
        # Users
        users_to_add:
          - username: "sysadmin"
            password: "{{ vault_sysadmin_password }}"
            is_sudoers: true
            groups: ["sudo", "docker", "wheel"]
            shell: "/bin/bash"
            password_max_age: 30
            
          - username: "developer"
            password: "{{ vault_developer_password }}"
            is_sudoers: true
            groups: ["docker", "developers"]
            shell: "/bin/zsh"
```

## Security Groups

Security groups provide a way to assign granular sudo privileges to users based on their role in the organization.

### Predefined Groups

#### `admins`
- **Purpose**: Full administrative access
- **Commands**: `ALL` (unrestricted)
- **NOPASSWD**: `true` (no password required)
- **Use Case**: System administrators, root-level access

#### `operators`
- **Purpose**: Limited operational access
- **Commands**: 
  - `/bin/systemctl restart *`
  - `/bin/systemctl stop *`
  - `/bin/systemctl start *`
  - `/bin/systemctl status *`
  - `/bin/journalctl *`
  - `/usr/bin/docker *`
  - `/usr/local/bin/docker-compose *`
- **NOPASSWD**: `false` (password required)
- **Use Case**: Operations team, service management

#### `auditors`
- **Purpose**: Read-only audit access
- **Commands**:
  - `/bin/cat /var/log/*`
  - `/bin/tail /var/log/*`
  - `/bin/grep * /var/log/*`
  - `/bin/journalctl *`
  - `/bin/systemctl status *`
  - `/usr/bin/find /var/log/*`
- **NOPASSWD**: `true` (no password required for read-only)
- **Use Case**: Security auditors, compliance monitoring

### Custom Security Groups

You can define custom security groups by adding them to the `security_groups` dictionary:

```yaml
security_groups:
  developers:
    members: ["dev1", "dev2"]
    commands:
      - "/usr/bin/git *"
      - "/usr/bin/docker *"
      - "/usr/local/bin/kubectl *"
    nopasswd: false
    
  database_admins:
    members: ["dbadmin1"]
    commands:
      - "/usr/bin/mysql *"
      - "/usr/bin/psql *"
      - "/usr/bin/mongodump *"
    nopasswd: false
```

## Security Features

### Password Policies

The role implements comprehensive password policies:

- **Minimum Length**: Configurable minimum password length (default: 8 characters)
- **Password History**: Prevents reuse of recent passwords (default: 12 passwords)
- **Password Aging**: Configurable password expiration (default: 90 days)
- **Password Complexity**: PAM integration for password quality requirements

### PAM Configuration

For Debian/Ubuntu systems, the role configures PAM modules:

- **pam_pwquality**: Password quality enforcement
- **pam_faillock**: Account lockout after failed attempts
- **pam_unix**: Password history and aging

### Account Security

- **Account Lockout**: Automatic lockout after failed login attempts
- **Inactivity Lockout**: Account lockout after password expiry for non-sudo users
- **Home Directory Permissions**: Secure permissions on user home directories
- **Reserved Username Protection**: Prevents creation of system-reserved usernames

### Sudo Security

- **Granular Permissions**: Command-specific sudo rules
- **Security Groups**: Role-based access control
- **Validation**: Automatic sudoers file validation
- **Backup**: Automatic backup of sudoers configuration

## Error Handling

### Rollback Mechanism

The role implements automatic rollback on failure:

```yaml
enable_rollback: true    # Enable automatic rollback
backup_config: true      # Create backups before changes
```

### Error Recovery

- **Block-Rescue Pattern**: Structured error handling with recovery
- **Partial Failure Handling**: Continue execution when possible
- **Detailed Error Logging**: Comprehensive error context and stack traces
- **Validation Failures**: Clear error messages for configuration issues

### Backup Strategy

- **Configuration Backups**: Automatic backup of modified files
- **Timestamped Backups**: Unique backup names with timestamps
- **Rollback Capability**: Automatic restoration on failure

## Performance

### Optimization Features

- **Idempotent Operations**: Safe to run multiple times
- **Conditional Execution**: Skip unnecessary operations
- **Parallel Processing**: Efficient group and user creation
- **Minimal Fact Gathering**: Only collect required system information

### Resource Usage

- **Memory**: Minimal memory footprint
- **Disk**: Small temporary files, cleaned up after execution
- **Network**: Only for package installation
- **CPU**: Efficient processing with minimal overhead

## Troubleshooting

### Common Issues

#### 1. Password Validation Failures

**Problem**: Password doesn't meet complexity requirements

**Solution**: 
```yaml
# Disable password validation (not recommended for production)
add_users_validate_passwords: false

# Or increase minimum length
add_users_min_password_length: 6
```

#### 2. Sudoers Validation Errors

**Problem**: `visudo` validation fails

**Solution**:
```bash
# Check sudoers syntax manually
sudo visudo -c

# Check specific user file
sudo visudo -c /etc/sudoers.d/username
```

#### 3. User Creation Failures

**Problem**: User creation fails with permission errors

**Solution**:
- Ensure playbook runs with appropriate privileges
- Check if username conflicts with existing users
- Verify UID/GID ranges are available

#### 4. PAM Configuration Issues

**Problem**: PAM modules not working correctly

**Solution**:
```bash
# Check PAM configuration
sudo pam-auth-update

# Test password quality
echo "password" | sudo pam_test_password
```

### Debug Mode

Enable debug mode for detailed output:

```yaml
debug_mode: true
debug_show_passwords: true  # WARNING: Shows passwords in logs
```

### Logging

Check the structured log file for detailed operation information:

```bash
tail -f /var/log/ansible-changes.log
```

## Development

### Testing

The role includes comprehensive testing capabilities:

```bash
# Run role tests
ansible-playbook -i inventory test-playbook.yml --check

# Test with debug mode
ansible-playbook -i inventory test-playbook.yml -e debug_mode=true
```

### Contributing

When contributing to this role:

1. Follow the coding standards in `ansible-expert-cursor-rules.md`
2. Add comprehensive tests for new features
3. Update documentation for any changes
4. Ensure cross-platform compatibility
5. Maintain idempotency

### Code Structure

```
roles/base/add_users/
├── defaults/main.yml          # Default variables
├── handlers/main.yml          # Event handlers
├── meta/
│   ├── main.yml              # Role metadata
│   └── argument_specs.yml    # Input validation
├── tasks/
│   ├── main.yml              # Main task flow
│   ├── validate.yml          # Input validation
│   ├── security.yml          # Security hardening
│   ├── sudoers_granular.yml  # Sudo configuration
│   ├── preflight.yml         # Pre-execution checks
│   └── install_packages.yml  # Package installation
├── templates/sudoers.d/user.j2 # Sudoers template
├── vars/main.yml             # Internal variables
├── README.md                 # Quick reference
├── README_eng.md            # Complete English docs
└── README_rus.md            # Complete Russian docs
```

### Version History

- **v1.0.0**: Initial release with basic user management
- **v1.1.0**: Added security groups and granular sudo
- **v1.2.0**: Enhanced security hardening and PAM integration
- **v1.3.0**: Added structured logging and error handling
- **v1.4.0**: Cross-platform support and performance optimization

---

**License**: MIT  
**Author**: Mad-Axell [mad.axell@gmail.com]  
**Maintainer**: Ansible Admin [admin@example.com]
