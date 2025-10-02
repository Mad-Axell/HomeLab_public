# Ansible Role: add_users

[![License](https://img.shields.io/badge/license-MIT-brightgreen.svg)](LICENSE)

[English Documentation](README_eng.md) | [Русская документация](README_rus.md)

## Quick Start / Быстрый старт

### English
This role creates and manages user accounts on Linux systems with comprehensive validation, group management, and sudo privileges configuration. Supports Ubuntu, Debian, RHEL-based systems, and openSUSE.

```yaml
---
- name: Manage system users
  hosts: all
  become: true
  
  vars:
    users_to_add:
      - username: admin
        password: "SecurePassword123!"
        groups: ["docker", "wheel"]
        is_sudoers: true
        
  roles:
    - role: base.add_users
```

### Русский
Данная роль создает и управляет учетными записями пользователей в Linux системах с комплексной валидацией, управлением группами и настройкой sudo привилегий. Поддерживает Ubuntu, Debian, системы на базе RHEL и openSUSE.

```yaml
---
- name: Управление системными пользователями
  hosts: all
  become: true
  
  vars:
    users_to_add:
      - username: admin
        password: "SecurePassword123!"
        groups: ["docker", "wheel"]
        is_sudoers: true
        
  roles:
    - role: base.add_users
```

## Requirements / Требования

- Ansible >= 2.14
- Python >= 3.8
- Target OS: Ubuntu 20.04+, 22.04+, 24.04+, Debian 11+, 12+, RHEL/CentOS/Rocky Linux 8+, 9+, openSUSE 15+

## Role Variables / Переменные роли

See [defaults/main.yml](defaults/main.yml) and [meta/argument_specs.yml](meta/argument_specs.yml)

Key variables:
- `users_to_add` - List of users to create/update (required)
- `debug_mode` - Enable detailed debug output (default: false)
- `add_users_validate_passwords` - Enable password validation (default: true)
- `enable_rollback` - Enable automatic rollback on failure (default: true)

## Dependencies / Зависимости

None / Отсутствуют

## Example Playbook / Пример плейбука

```yaml
---
- name: Add users with sudo privileges
  hosts: all
  become: true
  
  vars:
    debug_mode: true
    add_users_min_password_length: 12
    
    users_to_add:
      - username: admin
        password: "SecurePassword123!"
        groups: ["docker", "wheel"]
        is_sudoers: true
        shell: /bin/bash
        
      - username: developer
        password: "DevPassword456!"
        groups: ["docker", "git"]
        is_sudoers: true
        
      - username: readonly
        password: "ReadOnly789!"
        groups: ["users"]
        is_sudoers: false

  roles:
    - role: base.add_users
```

## Testing / Тестирование

This role uses Molecule for testing:

```bash
molecule test
```

## License / Лицензия

MIT

## Author Information / Информация об авторах

Ansible Admin

For detailed documentation, see:
- [English Documentation](README_eng.md)
- [Русская документация](README_rus.md)

