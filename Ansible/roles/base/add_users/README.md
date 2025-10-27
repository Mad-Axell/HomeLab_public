# add_users

**EN:** User management role with sudo and group configuration  
**RU:** Роль управления пользователями с sudo и конфигурацией групп

## Quick Start

```yaml
- hosts: all
  become: true
  roles:
    - role: base.add_users
      vars:
        users_to_add:
          - username: admin_user
            password: "SecurePass123"
            is_sudoers: true
            groups: ["docker", "wheel"]
```

## Documentation

- **[Complete English Documentation](README_eng.md)** - Full documentation in English
- **[Полная документация на русском](README_rus.md)** - Полная документация на русском языке

## Features

- ✅ User account creation and management
- ✅ Sudo privileges configuration
- ✅ Security groups with granular permissions
- ✅ Password policies and PAM configuration
- ✅ Comprehensive input validation
- ✅ Structured JSON logging
- ✅ Error handling with rollback support
- ✅ Debian/Ubuntu support

## License

MIT

## Author

Mad-Axell [mad.axell@gmail.com]
