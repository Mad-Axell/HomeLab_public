# Package Installation Role

This Ansible role installs and manages packages on Ubuntu/Debian systems with a focus on security, flexibility, and best practices.

## Features

- **Categorized Package Management**: Organizes packages by purpose (essential, security, admin, dev, network)
- **Flexible Installation Options**: Configurable package states, recommendations, and suggestions
- **Repository Management**: Support for additional APT repositories
- **Cache Management**: Intelligent APT cache handling with configurable validity
- **Cleanup Capabilities**: Remove unnecessary packages and clean up system
- **Comprehensive Validation**: Input parameter validation before execution
- **Tagged Tasks**: Selective execution of specific task groups
- **Idempotent**: Safe to run multiple times

## Requirements

- Ansible 2.9+
- Ubuntu/Debian target systems
- Root or sudo access

## Role Variables

### Basic Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `debug_mode` | `false` | Enable verbose output and detailed logging |
| `validate_packages` | `true` | Enable input parameter validation |
| `fail_on_validation_error` | `true` | Fail playbook on validation errors |

### Package Categories

#### Essential Packages (Always Installed)
```yaml
essential_packages:
  - acl
  - sudo
  - net-tools
  - gnupg
```

#### Security Packages
```yaml
security_packages:
  - auditd      # System audit daemon for SIEM integration
  - ufw         # Uncomplicated firewall
  - fail2ban    # Intrusion prevention system
  - libpam-pwquality  # Password quality enforcement
```

#### System Administration Packages
```yaml
admin_packages:
  - htop        # Interactive process viewer
  - curl        # Command line tool for transferring data
  - wget        # Internet file retriever
  - vim         # Text editor
  - tree        # Directory listing in tree format
```

#### Development Packages
```yaml
dev_packages:
  - python3
  - python3-pip
  - python3-requests
  - build-essential
```

#### Network Packages
```yaml
network_packages:
  - apt-transport-https
  - software-properties-common
  - ca-certificates
  - openssh-client
```

### Package Installation Options

| Variable | Default | Description |
|----------|---------|-------------|
| `package_installation.state` | `present` | Package state (present, latest, absent) |
| `package_installation.force_apt_get` | `false` | Use force option (use with caution) |
| `package_installation.allow_unauthenticated` | `false` | Allow unsigned packages |
| `package_installation.install_recommends` | `true` | Install recommended packages |
| `package_installation.install_suggests` | `false` | Install suggested packages |

### Cache Management

| Variable | Default | Description |
|----------|---------|-------------|
| `apt_cache_valid_time` | `86400` | Cache validity time in seconds (24 hours) |
| `apt_update_cache` | `true` | Update package cache before installation |
| `apt_upgrade_packages` | `false` | Perform system upgrade (dist-upgrade) |

### Additional Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `packages_to_remove` | `[]` | List of packages to remove |
| `additional_repositories` | `[]` | List of additional APT repositories |

## Additional Repositories Format

```yaml
additional_repositories:
  - repo: "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"
    state: present
    filename: docker
    key_url: "https://download.docker.com/linux/ubuntu/gpg"
  - repo: "ppa:ansible/ansible"
    state: present
```

## Example Playbook

### Basic Usage

```yaml
- hosts: servers
  roles:
    - role: base/install_apts
```

### Custom Package Selection

```yaml
- hosts: servers
  vars:
    essential_packages:
      - acl
      - sudo
      - net-tools
      - gnupg
      - curl
    security_packages:
      - auditd
      - ufw
    admin_packages:
      - htop
      - vim
    dev_packages: []
    network_packages: []
  roles:
    - role: base/install_apts
```

### Development Server

```yaml
- hosts: dev_servers
  vars:
    essential_packages:
      - acl
      - sudo
      - net-tools
      - gnupg
    security_packages:
      - auditd
      - ufw
    admin_packages:
      - htop
      - vim
      - tree
    dev_packages:
      - python3
      - python3-pip
      - python3-requests
      - build-essential
    network_packages:
      - apt-transport-https
      - software-properties-common
      - ca-certificates
    additional_repositories:
      - repo: "ppa:ansible/ansible"
        state: present
    apt_upgrade_packages: true
  roles:
    - role: base/install_apts
```

### Production Server with Cleanup

```yaml
- hosts: production_servers
  vars:
    essential_packages:
      - acl
      - sudo
      - net-tools
      - gnupg
    security_packages:
      - auditd
      - ufw
      - fail2ban
      - libpam-pwquality
    admin_packages:
      - htop
      - vim
    dev_packages: []
    network_packages:
      - ca-certificates
    packages_to_remove:
      - snapd
      - ubuntu-server
    debug_mode: false
    apt_upgrade_packages: false
  roles:
    - role: base/install_apts
```

## Task Tags

The role provides several tags for selective execution:

- `validation`: Run only validation tasks
- `facts`: Gather package facts
- `cache`: Manage APT cache
- `upgrade`: Perform system upgrades
- `packages`: Install/remove packages
- `essential`: Install essential packages
- `security`: Install security packages
- `admin`: Install administration packages
- `dev`: Install development packages
- `network`: Install network packages
- `repositories`: Manage repositories
- `cleanup`: Clean up system
- `debug`: Show debug information

### Example: Install Only Security Packages

```bash
ansible-playbook playbook.yml --tags "security,packages"
```

### Example: Skip Package Installation, Only Update Cache

```bash
ansible-playbook playbook.yml --skip-tags "packages"
```

## Security Best Practices

1. **Minimal Package Installation**: Only install necessary packages
2. **Security Packages First**: Prioritize security-related packages
3. **Avoid Force Options**: Use `force_apt_get: false` unless absolutely necessary
4. **Regular Updates**: Keep package cache updated
5. **Cleanup**: Remove unnecessary packages after installation
6. **Repository Security**: Only add trusted repositories

## Dependencies

This role has no dependencies on other roles, but can work in conjunction with:

- `base/configure_ufw` - When UFW is in security_packages
- `base/fail2ban` - When fail2ban is in security_packages
- `base/security` - For additional security hardening

## Troubleshooting

### Common Issues

1. **Package Not Found**: Check if package name is correct for your distribution
2. **Repository Errors**: Verify repository URLs and GPG keys
3. **Permission Denied**: Ensure proper sudo access
4. **Cache Issues**: Clear APT cache manually if needed

### Debug Mode

Enable debug mode to see detailed information:

```yaml
debug_mode: true
```

### Validation Errors

Check validation output for configuration issues:

```bash
ansible-playbook playbook.yml --tags "validation"
```

## License

This role is licensed under the MIT License.

## Author Information

Created for HomeLab infrastructure management.

## Contributing

1. Follow Ansible best practices
2. Test changes in a safe environment
3. Update documentation for any new features
4. Ensure backward compatibility
