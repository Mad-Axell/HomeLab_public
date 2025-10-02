# SSH Configuration Role - English Documentation

## Overview

The `base.configure_ssh` role is a comprehensive Ansible role designed to configure SSH servers with security best practices and network-based access control. This role provides fine-grained control over SSH authentication methods based on network source addresses, ensuring secure remote access while maintaining operational flexibility.

## Key Features

### Network-Based Access Control
- **Trusted Networks**: Allow password-only authentication for specified subnets
- **Untrusted Networks**: Require both password and public key authentication
- **Automatic Subnet Management**: Extract and deduplicate subnets from user definitions
- **Flexible Configuration**: Support both direct subnet configuration and user-based configuration

### Security Hardening
- Disabled root login by default
- Strong cryptographic algorithms and ciphers
- Rate limiting and connection management
- Comprehensive logging and monitoring
- SSH banner configuration
- Protocol version enforcement

### Cross-Platform Support
- **Debian Family**: Debian, Ubuntu, Linux Mint
- **RedHat Family**: RHEL, CentOS, Rocky Linux, AlmaLinux, Fedora
- **SUSE Family**: openSUSE, SLES

### Advanced Features
- Comprehensive parameter validation
- Configuration testing and validation
- Backup and recovery capabilities
- Detailed debug output and logging
- Service management and monitoring

## Role Structure

```
roles/base/configure_ssh/
├── defaults/
│   └── main.yml          # Default variables and settings
├── handlers/
│   └── main.yml          # Service handlers and notifications
├── tasks/
│   ├── main.yml          # Main configuration tasks
│   ├── validate.yml      # Parameter validation tasks
│   ├── process_allowed_subnets.yml    # Process allowed subnets
│   ├── process_denied_subnets.yml     # Process denied subnets
│   └── process_not_trusted_subnets.yml # Process not trusted subnets
├── templates/
│   ├── sshd_config.j2    # SSH daemon configuration template
│   └── ssh_banner.j2     # SSH banner template
├── files/
│   └── dynamic_greeting.sh # Dynamic greeting script
├── README.md             # Main documentation
├── readme_eng.md         # English documentation
├── readme_rus.md         # Russian documentation
└── example-playbook.yml  # Usage examples
```

## Configuration Modes

### 1. Direct Subnet Configuration

Configure subnets directly without user definitions:

```yaml
- hosts: servers
  roles:
    - role: base.configure_ssh
      vars:
        allowed_subnets:
          - "192.168.1.0/24"
          - "10.20.30.0/24"
        denied_subnets:
          - "192.168.0.0/24"
          - "10.10.10.0/24"
```

### 2. User-Based Configuration

Extract subnets from user definitions (recommended for dashboard integration):

```yaml
- hosts: servers
  roles:
    - role: base.configure_ssh
      vars:
        users_to_add:
          - username: "admin"
            password: "SecurePassword123!"
            groups: ["sudo", "admin"]
            is_sudoers: true
            shell: /bin/bash
            allowed_subnets:
              - "192.168.1.0/24"
              - "10.20.30.0/24"
            denied_subnets: []
            authorized_keys: []
```

## Variables

### SSH Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `ssh_port` | `22` | SSH server port |
| `ssh_protocol` | `"tcp"` | SSH protocol (tcp/udp) |
| `ssh_service_name` | `"sshd"` | SSH service name |

### Security Settings

| Variable | Default | Description |
|----------|---------|-------------|
| `ssh_security.password_authentication` | `"yes"` | Allow password authentication |
| `ssh_security.pubkey_authentication` | `"no"` | Allow public key authentication |
| `ssh_security.permit_root_login` | `"yes"` | Allow root login |
| `ssh_security.max_auth_tries` | `6` | Maximum authentication attempts |
| `ssh_security.login_grace_time` | `60` | Login grace time in seconds |

### Network Access Control

| Variable | Default | Description |
|----------|---------|-------------|
| `ssh_access_control.trusted_networks_password_auth` | `true` | Allow password auth for trusted networks |
| `ssh_access_control.untrusted_networks_require_both` | `true` | Require both password and key for untrusted networks |
| `ssh_access_control.default_network_behavior` | `"restrictive"` | Default behavior for undefined networks |

### Advanced Settings

| Variable | Default | Description |
|----------|---------|-------------|
| `ssh_advanced.x11_forwarding` | `false` | Enable X11 forwarding |
| `ssh_advanced.allow_tcp_forwarding` | `false` | Allow TCP forwarding |
| `ssh_advanced.use_match_blocks` | `true` | Use Match blocks for network-specific rules |

## Usage Examples

### Basic Configuration

```yaml
- hosts: servers
  roles:
    - role: base.configure_ssh
      vars:
        ssh_port: 2222
        users_to_add:
          - username: "admin"
            password: "SecurePassword123!"
            groups: ["sudo"]
            is_sudoers: true
            shell: /bin/bash
            allowed_subnets:
              - "192.168.1.0/24"
            denied_subnets: []
            authorized_keys: []
```

### Advanced Security Configuration

```yaml
- hosts: servers
  roles:
    - role: base.configure_ssh
      vars:
        ssh_security:
          max_auth_tries: 2
          login_grace_time: 30
          client_alive_interval: 300
          client_alive_count_max: 2
        ssh_advanced:
          x11_forwarding: false
          allow_tcp_forwarding: false
          use_match_blocks: true
        users_to_add:
          - username: "admin"
            password: "VerySecurePassword123!"
            groups: ["sudo", "admin"]
            is_sudoers: true
            shell: /bin/bash
            allowed_subnets:
              - "192.168.1.0/24"
              - "10.20.30.0/24"
            denied_subnets:
              - "192.168.0.0/24"
            authorized_keys:
              - "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC..."
```

### Dashboard Integration

```yaml
- hosts: dashboard
  roles:
    - role: base.configure_ssh
      vars:
        # Use dashboard_users_to_add from host_vars
        users_to_add: "{{ dashboard_users_to_add }}"
        ssh_security:
          password_authentication: "yes"
          pubkey_authentication: "yes"
        ssh_access_control:
          trusted_networks_password_auth: true
          untrusted_networks_require_both: true
```

## Network Access Control Logic

### Trusted Networks
- **Password Authentication**: Allowed (if `trusted_networks_password_auth: true`)
- **Public Key Authentication**: Always allowed
- **Access Method**: Either password OR key authentication

### Untrusted Networks
- **Password Authentication**: Allowed (if `untrusted_networks_require_both: true`)
- **Public Key Authentication**: Required
- **Access Method**: Both password AND key authentication required

### Denied Networks
- **Access**: Completely denied
- **Implementation**: Uses SSH Match blocks with `DenyUsers *`

## Security Features

### Cryptographic Settings
- **Host Key Algorithms**: RSA-SHA2, ECDSA, Ed25519
- **KEX Algorithms**: Curve25519, ECDH, Diffie-Hellman
- **Ciphers**: ChaCha20-Poly1305, AES-GCM, AES-CTR
- **MACs**: HMAC-SHA2 with ETM

### Connection Management
- **Client Alive Interval**: 300 seconds
- **Client Alive Count Max**: 2
- **Login Grace Time**: 60 seconds
- **Max Auth Tries**: 3

### Logging and Monitoring
- **Log Level**: INFO
- **Syslog Facility**: AUTH
- **Banner**: Security warning message
- **Last Login**: Displayed on connection

## Validation and Testing

### Parameter Validation
- SSH port range validation (1-65535)
- Subnet format validation (CIDR notation)
- User structure validation
- Cryptographic algorithm validation
- Boolean parameter validation

### Configuration Testing
- SSH configuration syntax testing (`sshd -t`)
- Service status validation
- Network connectivity testing
- Authentication method testing

## Backup and Recovery

### Automatic Backups
- Configuration file backups before changes
- Timestamped backup files
- Configurable backup retention
- Backup directory management

### Recovery Options
- Configuration rollback capability
- Service restart on configuration errors
- Detailed error logging and reporting

## Tags

The role supports the following tags for selective execution:

- `validation` - Parameter validation tasks
- `configuration` - SSH configuration tasks
- `service` - Service management tasks
- `backup` - Backup operations
- `debug` - Debug output tasks
- `testing` - Configuration testing tasks

## Dependencies

### Ansible Collections
- `ansible.builtin` (>=2.9.0)
- `community.general` (>=3.0.0)
- `ansible.posix` (>=1.0.0)

### System Requirements
- Linux operating system
- Root or sudo privileges
- OpenSSH server package
- Systemd service management

## Troubleshooting

### Common Issues

1. **SSH Service Not Starting**
   - Check SSH configuration syntax: `sshd -t`
   - Verify service name: `systemctl status sshd`
   - Check logs: `journalctl -u sshd`

2. **Authentication Failures**
   - Verify network access control rules
   - Check user permissions and groups
   - Validate SSH key formats

3. **Configuration Validation Errors**
   - Enable debug mode: `debug_mode: true`
   - Check parameter validation results
   - Verify subnet format (CIDR notation)

### Debug Mode

Enable debug mode for detailed output:

```yaml
- hosts: servers
  roles:
    - role: base.configure_ssh
      vars:
        debug_mode: true
        validate_configuration: true
```

## Best Practices

1. **Use User-Based Configuration**: Prefer `users_to_add` over direct subnet configuration for better integration with user management systems.

2. **Enable Validation**: Always use `validate_configuration: true` in production environments.

3. **Backup Configuration**: Enable `ssh_backup_enabled: true` for automatic backups.

4. **Test Configuration**: Use `sshd -t` to validate configuration before applying changes.

5. **Monitor Logs**: Regularly check SSH logs for security events and authentication failures.

6. **Network Segmentation**: Use specific subnets for trusted networks rather than broad ranges.

7. **Key Management**: Implement proper SSH key management and rotation policies.

## Contributing

When contributing to this role:

1. Follow Ansible best practices
2. Maintain bilingual documentation (English/Russian)
3. Include comprehensive validation
4. Add appropriate error handling
5. Update tests and examples
6. Follow the established code structure

## License

MIT License - see LICENSE file for details.
