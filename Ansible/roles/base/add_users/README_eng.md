# Ansible Role: add_users

## Table of Contents

- [Description](#description)
- [Features](#features)
- [Requirements](#requirements)
- [Role Variables](#role-variables)
  - [Required Variables](#required-variables)
  - [Optional Variables](#optional-variables)
  - [User Configuration Options](#user-configuration-options)
- [Dependencies](#dependencies)
- [Example Playbooks](#example-playbooks)
  - [Basic Usage](#basic-usage)
  - [Advanced Usage](#advanced-usage)
  - [Production Usage](#production-usage)
- [Tags](#tags)
- [Error Handling](#error-handling)
- [Security Features](#security-features)
- [Platform-Specific Behavior](#platform-specific-behavior)
- [Verification](#verification)
- [Troubleshooting](#troubleshooting)
- [License](#license)
- [Author Information](#author-information)

---

## Description

This Ansible role creates and manages user accounts on Linux systems with comprehensive validation, group management, and sudo privileges configuration. It provides a robust solution for user management across multiple Linux distributions.

**Key capabilities:**
- User account creation and updates
- Password hashing with SHA-512
- Group management (creation and assignment)
- Sudo privileges configuration
- Comprehensive input validation
- Automatic rollback on failure
- Post-deployment verification
- Bilingual debug output (English/Russian)

---

## Features

- ✅ **User Management**: Create and update user accounts with full configuration
- ✅ **Group Management**: Automatically create groups and manage group memberships
- ✅ **Sudo Configuration**: Configure sudo privileges with individual sudoers files
- ✅ **Password Security**: SHA-512 password hashing with strength validation
- ✅ **Validation**: Comprehensive validation of all inputs (usernames, passwords, UIDs, GIDs, shells, paths)
- ✅ **Preflight Checks**: Verify Ansible version, OS compatibility, and Python version
- ✅ **Error Handling**: Automatic rollback with backup/restore functionality
- ✅ **Verification**: Post-deployment checks to ensure users are properly configured
- ✅ **Multi-Platform**: Support for Debian, Ubuntu, RHEL, CentOS, Rocky Linux, openSUSE
- ✅ **Debug Output**: Structured logging with English/Russian language support
- ✅ **Reserved Names**: Protection against using system reserved usernames

---

## Requirements

### Ansible Version
- **Minimum**: 2.14
- **Recommended**: Latest stable version

### Python Version
- **Minimum**: 3.8
- **Recommended**: 3.10+

### Target Operating Systems
- **Ubuntu**: 20.04, 22.04, 24.04
- **Debian**: 11, 12
- **RHEL/CentOS/Rocky Linux**: 8, 9
- **openSUSE**: 15

### Privileges
- Root access or sudo privileges on target systems
- Use `become: true` in playbooks

---

## Role Variables

### Required Variables

#### `users_to_add`
- **Type**: List of dictionaries
- **Required**: Yes
- **Description**: List of users to create or update

Each user dictionary must contain:
- `username` (string, required): Username for the account
- `password` (string, required): Plain text password (will be hashed automatically)

Example:
```yaml
users_to_add:
  - username: admin
    password: "SecurePassword123"
```

### Optional Variables

#### Debug Configuration

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `debug_mode` | boolean | `false` | Enable detailed debug output |
| `debug_lang` | string | `both` | Debug language: `english`, `russian`, or `both` |
| `debug_show_passwords` | boolean | `false` | Show passwords in debug output (INSECURE - testing only) |

#### User Defaults

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `add_users_create_home` | boolean | `true` | Create home directory by default |
| `add_users_home_prefix` | string | `/home` | Prefix path for user home directories |
| `add_users_default_shell` | string | `/bin/bash` | Default shell for users |

#### Password Validation

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `add_users_validate_passwords` | boolean | `true` | Enable password strength validation |
| `add_users_min_password_length` | integer | `8` | Minimum password length requirement |

#### Rollback and Backup

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `enable_rollback` | boolean | `true` | Enable automatic rollback on failure |
| `backup_config` | boolean | `true` | Create backup before changes |

#### Performance

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `retries` | integer | `3` | Number of retries for failed tasks |
| `retry_delay` | integer | `5` | Delay between retries in seconds |

#### Verification

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `verify_deployment` | boolean | `true` | Enable post-deployment verification |
| `verify_user_login` | boolean | `true` | Verify users can login |

### User Configuration Options

Each user in the `users_to_add` list supports the following options:

| Option | Type | Required | Default | Description |
|--------|------|----------|---------|-------------|
| `username` | string | Yes | - | Username (lowercase letters, numbers, underscores only) |
| `password` | string | Yes | - | Plain text password (will be hashed) |
| `groups` | list | No | `[]` | List of groups user should be member of |
| `is_sudoers` | boolean | No | `false` | Grant sudo privileges |
| `shell` | string | No | `/bin/bash` | User shell (must be in valid_shells list) |
| `uid` | integer | No | auto | User ID (1000-60000 for regular users) |
| `gid` | integer | No | auto | Primary group ID |
| `create_home` | boolean | No | `true` | Create home directory |
| `home` | string | No | `/home/{username}` | Custom home directory path (must be absolute) |

---

## Dependencies

None

---

## Example Playbooks

### Basic Usage

Create a single user with sudo privileges:

```yaml
---
- name: Create admin user
  hosts: all
  become: true
  
  vars:
    users_to_add:
      - username: admin
        password: "SecurePassword123"
        is_sudoers: true
        
  roles:
    - role: base.add_users
```

### Advanced Usage

Create multiple users with different configurations:

```yaml
---
- name: Setup development team users
  hosts: development_servers
  become: true
  
  vars:
    debug_mode: true
    debug_lang: english
    add_users_min_password_length: 12
    
    users_to_add:
      # System administrator
      - username: sysadmin
        password: "Admin!SecurePass2024"
        groups: ["docker", "wheel", "systemd-journal"]
        is_sudoers: true
        shell: /bin/bash
        
      # Developer with specific UID
      - username: developer
        password: "Dev!SecurePass2024"
        groups: ["docker", "git", "developers"]
        is_sudoers: true
        shell: /bin/zsh
        uid: 5000
        
      # Read-only monitoring user
      - username: monitoring
        password: "Monitor!Pass2024"
        groups: ["systemd-journal"]
        is_sudoers: false
        shell: /bin/sh
        
      # Service account
      - username: appuser
        password: "App!ServicePass2024"
        groups: ["app"]
        is_sudoers: false
        create_home: false
        home: /opt/app

  roles:
    - role: base.add_users
      tags: ['users', 'setup']
```

### Production Usage

Production deployment with full error handling:

```yaml
---
- name: Production user management
  hosts: production_servers
  become: true
  serial: 5  # Process 5 servers at a time
  max_fail_percentage: 10
  
  vars:
    # Production settings
    debug_mode: false
    add_users_validate_passwords: true
    add_users_min_password_length: 16
    enable_rollback: true
    backup_config: true
    verify_deployment: true
    
    # Load users from vault
    users_to_add: "{{ vault_production_users }}"
    
  pre_tasks:
    - name: Ensure we're on production servers
      ansible.builtin.assert:
        that:
          - inventory_hostname in groups['production']
          - ansible_distribution in ['Ubuntu', 'Debian', 'RedHat', 'Rocky']
        fail_msg: "This playbook should only run on production servers"
        
  roles:
    - role: base.add_users
      tags: ['users', 'security']
      
  post_tasks:
    - name: Send notification
      ansible.builtin.debug:
        msg: "User management completed on {{ inventory_hostname }}"
```

---

## Tags

The role supports the following tags for selective execution:

| Tag | Description |
|-----|-------------|
| `always` | Tasks that always run (validation, variable loading) |
| `validate` | Input validation tasks |
| `preflight` | Preflight checks (Ansible version, OS compatibility) |
| `validation` | User data validation |
| `facts` | Fact gathering tasks |
| `groups` | Group management tasks |
| `users` | User creation and management |
| `create` | User/group creation tasks |
| `update` | User update tasks |
| `sudo` | Sudo configuration tasks |
| `verify` | Post-deployment verification |
| `debug` | Debug output tasks |

**Example usage:**
```bash
# Only create users, skip verification
ansible-playbook playbook.yml --tags users --skip-tags verify

# Only run validation
ansible-playbook playbook.yml --tags validation

# Full run except debug output
ansible-playbook playbook.yml --skip-tags debug
```

---

## Error Handling

The role implements comprehensive error handling:

### Automatic Rollback
When `enable_rollback: true` (default), the role will:
1. Create backups before making changes
2. Validate all configurations
3. Automatically restore previous state on failure
4. Provide detailed error messages

### Backup Strategy
When `backup_config: true` (default):
- Sudoers files are backed up to `/root/sudoers_backup_<timestamp>.tar.gz`
- Individual sudoers files are backed up before modification
- Rollback uses these backups to restore previous state

### Validation Failures
The role validates:
- Username format (lowercase, numbers, underscores only)
- Password length (configurable minimum)
- Reserved system usernames
- UID/GID ranges
- Shell paths (must be in valid_shells list)
- Home directory paths (must be absolute)
- Duplicate usernames in configuration

### Retry Mechanism
Failed tasks automatically retry with configurable settings:
- Default retries: 3
- Default delay: 5 seconds
- Configurable via `retries` and `retry_delay` variables

---

## Security Features

### Password Security
- **Hashing**: SHA-512 algorithm for all passwords
- **Validation**: Configurable minimum length requirements
- **No Logging**: All password operations use `no_log: true`
- **Debug Safety**: Passwords masked in debug output unless explicitly enabled

### File Permissions
- Sudoers files: `0440` (read-only for root and sudo group)
- Shadow files: `0000` (root only)
- Config files: `0644` (readable by all, writable by owner)
- Home directories: `0755` (user accessible)

### Access Control
- Reserved username protection (root, daemon, bin, sys, etc.)
- UID range validation (1000-60000 for regular users)
- Sudo privilege management with individual sudoers files
- Group-based access control

### Validation
- Sudoers file syntax validation with `visudo -c`
- Username format enforcement
- Shell path validation
- Home directory path validation

---

## Platform-Specific Behavior

### Debian/Ubuntu
```yaml
sudo_group: sudo
package_manager: apt
valid_shells:
  - /bin/bash
  - /bin/sh
  - /bin/zsh
  - /bin/fish
  - /usr/bin/bash
  - /usr/bin/sh
  - /usr/bin/zsh
  - /usr/bin/fish
  - /bin/dash
```

### RHEL/CentOS/Rocky Linux
```yaml
sudo_group: wheel
package_manager: dnf  # or yum for EL7
valid_shells:
  - /bin/bash
  - /bin/sh
  - /bin/zsh
  - /bin/fish
  - /usr/bin/bash
  - /usr/bin/sh
  - /usr/bin/zsh
  - /usr/bin/fish
```

### SUSE/openSUSE
```yaml
sudo_group: wheel
package_manager: zypper
valid_shells:
  - /bin/bash
  - /bin/sh
  - /bin/zsh
  - /bin/fish
  - /usr/bin/bash
  - /usr/bin/sh
  - /usr/bin/zsh
  - /usr/bin/fish
```

---

## Verification

The role includes post-deployment verification (when `verify_deployment: true`):

### Checks Performed
1. ✅ User exists in passwd database
2. ✅ User group memberships are correct
3. ✅ Sudoers files exist for sudo users
4. ✅ Sudoers files absent for non-sudo users
5. ✅ Home directories exist (when create_home: true)
6. ✅ User shell configuration is correct

### Verification Output
When `debug_mode: true`, detailed verification results are displayed:
- Total users verified
- Users successfully created
- Sudo users verified
- Home directories created
- Overall verification status

---

## Troubleshooting

### Common Issues

**Issue**: User creation fails with "Username contains invalid characters"
```
Solution: Use only lowercase letters, numbers, and underscores in usernames
Valid: admin, user_1, dev123
Invalid: Admin, user-1, dev.user
```

**Issue**: Password validation fails
```
Solution: Ensure password meets minimum length requirement
- Check add_users_min_password_length setting
- Default minimum is 8 characters
- Use strong passwords with mixed case, numbers, symbols
```

**Issue**: Sudo configuration fails
```
Solution: Verify sudoers file syntax
- Check logs for validation errors
- Ensure backup_config: true for safety
- Manually validate: sudo visudo -c
```

**Issue**: Role fails on unsupported OS
```
Solution: Check supported OS list
- Ubuntu 20.04+, Debian 11+, RHEL/CentOS/Rocky 8+, openSUSE 15+
- Update OS or use compatible version
```

### Debug Mode

Enable detailed debugging:
```yaml
vars:
  debug_mode: true
  debug_lang: english
  debug_show_passwords: false  # Set to true only in test environments
```

Debug output includes:
- User configuration details
- System information
- Group creation results
- User creation/update results
- Sudo configuration status
- Verification results

### Log Files

Check system logs for errors:
```bash
# View role execution logs
journalctl -xe

# Check auth logs
tail -f /var/log/auth.log  # Debian/Ubuntu
tail -f /var/log/secure    # RHEL/CentOS
```

---

## License

MIT License

Copyright (c) 2024 Ansible Admin

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

---

## Author Information

**Ansible Admin**

For issues, questions, or contributions:
- Email: admin@example.com
- Documentation: See [README.md](README.md) for overview
- Russian Documentation: See [README_rus.md](README_rus.md)

---

**Related Documentation:**
- [Main README](README.md) - Quick start guide
- [Russian Documentation](README_rus.md) - Русская документация
- [Role Variables](defaults/main.yml) - Default variables
- [Argument Specifications](meta/argument_specs.yml) - Complete variable documentation

