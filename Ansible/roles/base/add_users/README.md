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
- ✅ **Automatic container detection** - faillock disabled in containers
- ✅ **User login verification** - automatic SSH/Proxmox compatibility checks
- ✅ Comprehensive input validation
- ✅ Structured JSON logging
- ✅ Error handling with rollback support
- ✅ Debian/Ubuntu support

## PAM Configuration for Containers

**⚠️ Important:** The role automatically detects container environments and disables `pam_faillock` in containers because:
- `/var/run/faillock` is ephemeral (tmpfs) and cleared on restart
- Container state is temporary, making lockout tracking ineffective
- Containers use network isolation for security instead

To force enable faillock in containers (not recommended):
```yaml
enable_faillock_in_containers: true
```

See [README_eng.md](README_eng.md) or [README_rus.md](README_rus.md) for detailed documentation.

## License

MIT

## Author

Mad-Axell [mad.axell@gmail.com]
