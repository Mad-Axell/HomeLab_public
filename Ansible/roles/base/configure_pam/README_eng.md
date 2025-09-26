# configure_pam Role

## Description

The `configure_pam` role is designed for comprehensive PAM (Pluggable Authentication Modules) configuration in Linux systems with user management and network access control. The role provides secure authentication system configuration with protection against brute force attacks, password quality control, and network access management.

## Key Features

### 🔐 Authentication Security
- **PAM faillock**: Protection against brute force attacks with configurable lockout parameters
- **Password Quality**: Strict password requirements through pam_pwquality
- **Session Limits**: Control of concurrent login sessions through pam_limits
- **Secure TTY**: Restrict root access to console only

### 👥 User Management
- **User Creation**: Automatic user creation and configuration
- **Groups and Permissions**: Management of group membership and sudo rights
- **SSH Directories**: Automatic creation of home directories and SSH folders
- **Validation**: Verification of user data structure correctness

### 🌐 Network Access Control
- **pam_access**: Access control by IP addresses and subnets
- **pam_listfile**: Management of allowed/denied user lists
- **SSH Security**: SSH security parameter configuration
- **Management Script**: Automatic creation of access management script

### 🛡️ Lockout Prevention
- **Pre-checks**: System validation before applying changes
- **Backup**: Automatic creation of configuration backups
- **Critical Users**: Protection of administrative accounts from lockout
- **Audit**: Creation of role application audit files

## Requirements

### System Requirements
- **Ansible**: version 2.9 or higher
- **OS**: Debian/Ubuntu or RedHat/CentOS
- **Privileges**: root access for PAM configuration
- **PAM Modules**: pam_faillock, pam_pwquality, pam_limits, pam_wheel

### Dependencies
- **libpam-modules**: Core PAM modules
- **libpam-pwquality**: Password quality module
- **openssh-server**: SSH server for network access

## Variables

### Main Settings

| Variable | Default | Description |
|----------|---------|-------------|
| `debug_mode` | `false` | Enable debug mode with verbose output |
| `pam_backup_enabled` | `true` | Create backups before making changes |
| `pam_prevent_lockout` | `true` | Enable lockout prevention measures |

### PAM faillock Settings

| Variable | Default | Description |
|----------|---------|-------------|
| `pam_faillock_deny` | `3` | Number of failed attempts before lockout |
| `pam_unlock_time` | `1800` | Lockout duration in seconds (30 minutes) |
| `pam_faillock_audit` | `true` | Enable audit of failed attempts |
| `pam_faillock_silent` | `false` | Don't be silent about lockouts |

### Password Quality Settings

| Variable | Default | Description |
|----------|---------|-------------|
| `pam_pwquality_retry` | `3` | Number of password input attempts |
| `pam_pwquality_minlen` | `12` | Minimum password length |
| `pam_pwquality_difok` | `5` | Minimum different characters from old password |
| `pam_pwquality_ucredit` | `-1` | Require minimum 1 uppercase letter |
| `pam_pwquality_lcredit` | `-1` | Require minimum 1 lowercase letter |
| `pam_pwquality_dcredit` | `-1` | Require minimum 1 digit |
| `pam_pwquality_ocredit` | `-1` | Require minimum 1 special character |
| `pam_pwquality_minclass` | `3` | Require minimum 3 character classes |
| `pam_pwquality_maxrepeat` | `2` | Maximum consecutive repeated characters |
| `pam_pwquality_gecoscheck` | `true` | Check against user GECOS information |
| `pam_pwquality_reject_username` | `true` | Reject passwords containing username |

### Session Limits Settings

| Variable | Default | Description |
|----------|---------|-------------|
| `pam_limits_enabled` | `true` | Enable PAM limits |
| `pam_limits_maxlogins` | `10` | Maximum concurrent logins per user |
| `pam_limits_maxsyslogins` | `50` | Maximum concurrent system logins |

### PAM wheel Settings

| Variable | Default | Description |
|----------|---------|-------------|
| `pam_wheel_group` | `"sudo"` | Group for wheel functionality |
| `pam_wheel_use_uid` | `true` | Use UID instead of username |
| `pam_check_groups` | `true` | Check group existence before creating sudoers |

### Root Access Restrictions

| Variable | Default | Description |
|----------|---------|-------------|
| `pam_root_console_only` | `true` | Restrict root login to console only |
| `pam_root_securetty` | `true` | Use secure TTY for root login |

### Network Access

| Variable | Default | Description |
|----------|---------|-------------|
| `pam_network_access_enabled` | `true` | Enable network access control |
| `pam_access_file` | `"/etc/security/access.conf"` | pam_access configuration file |
| `pam_ssh_users_file` | `"/etc/security/ssh_users"` | Allowed SSH users file |
| `pam_denied_users_file` | `"/etc/security/denied_users"` | Denied users file |

### SSH Security Settings

| Variable | Default | Description |
|----------|---------|-------------|
| `ssh_security.max_auth_tries` | `3` | Maximum SSH authentication attempts |
| `ssh_security.permit_empty_passwords` | `"no"` | Allow empty SSH passwords |
| `ssh_security.password_authentication` | `"yes"` | SSH password authentication |
| `ssh_security.pubkey_authentication` | `"yes"` | SSH public key authentication |

### User Management

| Variable | Default | Description |
|----------|---------|-------------|
| `pam_create_missing_users` | `true` | Create missing users |
| `pam_add_users_to_wheel` | `true` | Add users to wheel group |
| `pam_default_shell` | `"/bin/bash"` | Default shell for new users |
| `pam_default_groups` | `["users"]` | Default groups for new users |

## users_to_add Data Structure

Main structure for user management:

```yaml
users_to_add:
  - username: "admin"                    # Username (required)
    password: "SecurePassword123!"       # Password (required)
    groups: ["sudo", "admin"]            # User groups (optional)
    is_sudoers: true                     # Is administrator (optional)
    shell: /bin/bash                     # Shell (optional)
    allowed_subnets:                     # Allowed subnets (optional)
      - "192.168.1.0/24"
      - "10.20.30.0/24"
    denied_ssh_subnets:                  # Denied subnets (optional)
      - "192.168.0.0/24"
      - "10.10.10.0/24"
```

### users_to_add Structure Fields

- **username** (required): Username for creation/management
- **password** (required): User password (will be encrypted)
- **groups** (optional): List of groups to add user to
- **is_sudoers** (optional): If `true`, user will get sudo rights
- **shell** (optional): User shell (default `/bin/bash`)
- **allowed_subnets** (optional): List of allowed subnets for connection
- **denied_ssh_subnets** (optional): List of denied subnets for SSH

## Usage Examples

### Basic Usage

```yaml
- hosts: servers
  roles:
    - configure_pam
  vars:
    users_to_add:
      - username: "admin"
        password: "SecurePassword123!"
        groups: ["sudo"]
        is_sudoers: true
        allowed_subnets:
          - "192.168.1.0/24"
```

### Advanced Configuration

```yaml
- hosts: servers
  roles:
    - configure_pam
  vars:
    debug_mode: true
    pam_faillock_deny: 5
    pam_pwquality_minlen: 14
    pam_limits_maxlogins: 5
    users_to_add:
      - username: "admin"
        password: "AdminPass123!"
        groups: ["sudo", "admin"]
        is_sudoers: true
        allowed_subnets:
          - "192.168.1.0/24"
          - "10.0.0.0/8"
        denied_ssh_subnets:
          - "0.0.0.0/0"
      - username: "user1"
        password: "UserPass123!"
        groups: ["users"]
        allowed_subnets:
          - "192.168.1.0/24"
```

### High Security Configuration

```yaml
- hosts: servers
  roles:
    - configure_pam
  vars:
    debug_mode: true
    pam_faillock_deny: 3
    pam_unlock_time: 3600
    pam_pwquality_minlen: 16
    pam_pwquality_minclass: 4
    pam_limits_maxlogins: 3
    pam_network_access_enabled: true
    ssh_security:
      max_auth_tries: 2
      permit_empty_passwords: "no"
      password_authentication: "no"
      pubkey_authentication: "yes"
    users_to_add:
      - username: "admin"
        password: "VerySecurePassword123!"
        groups: ["sudo"]
        is_sudoers: true
        allowed_subnets:
          - "192.168.1.0/24"
```

## Files Created by Role

### Configuration Files
- `/etc/security/access.conf` - pam_access configuration
- `/etc/security/ssh_users` - Allowed SSH users list
- `/etc/security/denied_users` - Denied users list
- `/etc/sudoers.d/` - Sudo configuration files for users

### Scripts and Reports
- `/root/manage_ssh_access.sh` - Access management script
- `/tmp/pam_role_applied_*` - Role application audit files
- `/tmp/pam_users_summary_*` - User reports
- `/tmp/pam_network_summary_*` - Network configuration reports

### Backup Files
- `*.backup` - Backup copies of all modified configuration files

## Access Management Script

The role creates `/root/manage_ssh_access.sh` script for access management:

```bash
# Add user with access from subnet
./manage_ssh_access.sh add user1 192.168.1.0/24

# Create new user
./manage_ssh_access.sh add-user user2 password123 192.168.1.0/24

# Deny access to user
./manage_ssh_access.sh deny-user user3

# Show current rules
./manage_ssh_access.sh list

# Restart SSH
./manage_ssh_access.sh reload

# Test user access from IP
./manage_ssh_access.sh test user1 192.168.1.100
```

## Security

### Role Security Measures

1. **Lockout Prevention**: 
   - Pre-application configuration checks
   - Critical user protection
   - Alternative access methods

2. **Backup**: 
   - Automatic backup creation
   - Change rollback capability

3. **Validation**: 
   - Parameter validation before application
   - User data structure validation
   - Group and module existence checks

4. **Audit**: 
   - Role application audit file creation
   - Detailed operation reports
   - Debug information when debug_mode is enabled

### Security Recommendations

1. **Before applying role**:
   - Ensure alternative server access is available
   - Check critical user existence
   - Create wheel group if it doesn't exist

2. **Parameter configuration**:
   - Use strict password requirements
   - Limit login attempts
   - Configure network access restrictions

3. **Monitoring**:
   - Regularly check authentication logs
   - Monitor role audit files
   - Use access management script for operational management

## Limitations

### System Limitations
- Requires root privileges for PAM configuration
- Works only with Debian/Ubuntu and RedHat/CentOS systems
- Requires critical PAM modules in system

### Functional Limitations
- Doesn't create groups automatically (requires pre-creation)
- No LDAP/AD authentication support
- Limited IPv6 support in network settings

## Troubleshooting

### Common Issues

1. **Role cannot create users**:
   - Check access privileges
   - Verify users_to_add structure correctness
   - Check group existence

2. **Access lockout**:
   - Use console access
   - Check role audit files
   - Use emergency unlock

3. **Validation errors**:
   - Check parameter correctness
   - Verify PAM module existence
   - Check system requirements

### Debug Information

Enable `debug_mode: true` for detailed role execution information:

```yaml
vars:
  debug_mode: true
```

## License

MIT

## Author

Ansible Admin

## Version

1.0.0

## Changelog

### v1.0.0
- Initial release
- Basic PAM configuration functionality
- User management and network access control
- Lockout prevention
- Comprehensive documentation and examples
