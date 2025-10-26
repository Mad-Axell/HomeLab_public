# base/add_users

**EN:** Comprehensive user management role with sudo privileges and security hardening  
**RU:** Комплексная роль управления пользователями с sudo привилегиями и усилением безопасности

## Quick Links

- [📖 Complete English Documentation](README_eng.md)
- [📖 Полная русская документация](README_rus.md)
- [🔧 Usage Examples](#usage-examples)
- [🛡️ Security Features](#security-features)

## Overview

This role provides enterprise-grade user management capabilities for Linux systems with:

- **User Creation & Management**: Create, update, and configure user accounts
- **Sudo Privileges**: Granular sudo configuration with security groups
- **Security Hardening**: Password policies, PAM configuration, and access controls
- **Cross-Platform Support**: Ubuntu, Debian, RHEL, and openSUSE
- **Comprehensive Validation**: Input validation and error handling

## Quick Start

```yaml
- hosts: all
  roles:
    - role: base/add_users
      vars:
        users_to_add:
          - username: "admin"
            password: "SecurePass123"
            is_sudoers: true
            groups: ["sudo", "docker"]
```

## Security Groups

- **admins**: Full administrative access
- **operators**: Limited operational access (systemctl, docker)
- **auditors**: Read-only audit access

## Requirements

- Ansible 2.14+
- Python 3.8+
- Supported OS: Ubuntu 20.04+, Debian 11+, RHEL 8+, openSUSE 15+

## License

MIT

## Author

Mad-Axell [mad.axell@gmail.com]
