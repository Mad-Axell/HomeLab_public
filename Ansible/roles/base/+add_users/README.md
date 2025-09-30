# add_users Role | Роль add_users

## Description | Описание

**English**: The `add_users` role provides automated user creation and management functionality for Linux systems. It supports creating new users, updating existing ones, managing groups, and configuring sudo privileges with comprehensive validation and security features.

**Русский**: Роль `add_users` предоставляет автоматизированную функциональность создания и управления пользователями в Linux-системах. Поддерживает создание новых пользователей, обновление существующих, управление группами и настройку sudo-привилегий с комплексной валидацией и функциями безопасности.

## Key Features | Основные возможности

- ✅ **User Management** | **Управление пользователями**: Create/update users with full configuration
- ✅ **Group Management** | **Управление группами**: Automatic group creation and management
- ✅ **Sudo Configuration** | **Настройка sudo**: Individual sudo privileges with secure configuration files
- ✅ **Comprehensive Validation** | **Комплексная валидация**: Input parameter validation and security checks
- ✅ **Debug Information** | **Отладочная информация**: Detailed execution monitoring and logging
- ✅ **Multi-shell Support** | **Поддержка оболочек**: bash, sh, zsh, fish support
- ✅ **Security Features** | **Функции безопасности**: Reserved name checking, password validation

## Quick Start | Быстрый старт

```yaml
---
- name: Create users | Создание пользователей
  hosts: all
  become: true
  vars:
    users_to_add:
      - username: admin
        password: "SecurePassword123"
        groups: ["docker", "wheel"]
        is_sudoers: true
        shell: /bin/bash

  roles:
    - role: base/add_users
```

## Documentation | Документация

For complete documentation, please refer to:

Для полной документации обратитесь к:

- **[README_eng.md](README_eng.md)** - Complete English documentation | Полная документация на английском языке
- **[README_rus.md](README_rus.md)** - Полная документация на русском языке | Complete Russian documentation

## Requirements | Требования

- Ansible >= 2.9
- Linux systems (Ubuntu, Debian, CentOS, RHEL)
- Root or sudo privileges | Права root или sudo

## License | Лицензия

MIT License

## Author | Автор

Ansible Admin