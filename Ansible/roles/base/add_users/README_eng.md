# Add Users Role | Роль add_users

## Description | Описание

**English**: The `add_users` role provides automated user creation and management functionality for Linux systems. It supports creating new users, updating existing ones, managing groups, and configuring sudo privileges with comprehensive validation and security features.

**Русский**: Роль `add_users` предоставляет автоматизированную функциональность создания и управления пользователями в Linux-системах. Поддерживает создание новых пользователей, обновление существующих, управление группами и настройку sudo-привилегий с комплексной валидацией и функциями безопасности.

## Key Features | Основные возможности

### 🔐 User Management | Управление пользователями
- ✅ Create new system users with full configuration
- ✅ Update existing users (passwords, groups)
- ✅ Automatic home directory creation
- ✅ User shell configuration (bash, sh, zsh, fish)
- ✅ UID/GID management

### 👥 Group Management | Управление группами
- ✅ Automatic creation of required groups
- ✅ Add users to groups
- ✅ Multiple group membership support
- ✅ Group name validation

### 🛡️ Security and Sudo | Безопасность и sudo
- ✅ Individual sudoers configuration files
- ✅ Secure file permissions for sudo
- ✅ Sudo privileges validation
- ✅ Reserved system name checking
- ✅ Password strength validation

### 🔍 Validation and Debugging | Валидация и отладка
- ✅ Comprehensive input parameter validation
- ✅ Username and group format checking
- ✅ Path and UID validation
- ✅ Detailed debug information in two languages
- ✅ Operation execution statistics

## Requirements | Требования

### System Requirements | Системные требования
- **Ansible**: >= 2.9
- **OS**: Linux (Ubuntu, Debian, CentOS, RHEL, AlmaLinux, Rocky Linux)
- **Privileges**: root or sudo privileges
- **Python**: >= 2.7 or >= 3.6

### Dependencies | Зависимости
- `ansible.builtin` collection
- Modules: `user`, `group`, `getent`, `file`, `copy`, `debug`

## Installation | Установка

### Using in Playbook | Использование в playbook

```yaml
---
- name: Create system users | Создание пользователей системы
  hosts: all
  become: true
  vars:
    users_to_add:
      - username: admin
        password: "SecurePassword123"
        groups: ["docker", "wheel", "developers"]
        is_sudoers: true
        shell: /bin/bash
        uid: 1001
        create_home: true
        home: "/home/admin"
      
      - username: developer
        password: "DevPassword456"
        groups: ["developers", "git"]
        is_sudoers: false
        shell: /bin/zsh
        create_home: true

  roles:
    - role: base/add_users
```

### Default Variables | Переменные по умолчанию

```yaml
# Debug mode - shows detailed information
debug_mode: true

# List of users to add
users_to_add: []

# Global settings
add_users_create_home: true
add_users_home_prefix: "/home"
add_users_default_shell: "/bin/bash"
add_users_validate_passwords: true
add_users_min_password_length: 8
```

## Configuration | Конфигурация

### User Structure | Структура пользователя

```yaml
users_to_add:
  - username: "username"               # Required | Обязательно
    password: "password"               # Required | Обязательно
    groups: ["group1", "group2"]       # Optional | Опционально
    is_sudoers: true/false            # Optional | Опционально
    shell: "/bin/bash"                # Optional | Опционально
    uid: 1001                         # Optional | Опционально
    gid: 1001                         # Optional | Опционально
    create_home: true                 # Optional | Опционально
    home: "/home/username"            # Optional | Опционально
```

### User Parameters | Параметры пользователя

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `username` | string | ✅ | Username (lowercase letters, numbers, underscores only) |
| `password` | string | ✅ | User password (minimum 8 characters) |
| `groups` | list | ❌ | List of groups to add user to |
| `is_sudoers` | boolean | ❌ | Grant sudo privileges (default: false) |
| `shell` | string | ❌ | User shell (default: /bin/bash) |
| `uid` | integer | ❌ | User UID (auto-assigned if not specified) |
| `gid` | integer | ❌ | User GID (auto-assigned if not specified) |
| `create_home` | boolean | ❌ | Create home directory (default: true) |
| `home` | string | ❌ | Home directory path |

### Supported Shells | Поддерживаемые оболочки

- `/bin/bash` (default)
- `/bin/sh`
- `/bin/zsh`
- `/bin/fish`
- `/usr/bin/bash`
- `/usr/bin/sh`
- `/usr/bin/zsh`
- `/usr/bin/fish`

## Usage Examples | Примеры использования

### Example 1: Create Administrator | Пример 1: Создание администратора

```yaml
---
- name: Create system administrator | Создание администратора системы
  hosts: all
  become: true
  vars:
    users_to_add:
      - username: admin
        password: "AdminPass123!"
        groups: ["sudo", "docker", "wheel"]
        is_sudoers: true
        shell: /bin/bash
        uid: 1001

  roles:
    - role: base/add_users
```

### Example 2: Create Developer Group | Пример 2: Создание группы разработчиков

```yaml
---
- name: Create developer users | Создание пользователей-разработчиков
  hosts: all
  become: true
  vars:
    users_to_add:
      - username: dev1
        password: "DevPass123!"
        groups: ["developers", "git", "docker"]
        is_sudoers: false
        shell: /bin/zsh
      
      - username: dev2
        password: "DevPass456!"
        groups: ["developers", "git"]
        is_sudoers: false
        shell: /bin/bash

  roles:
    - role: base/add_users
```

### Example 3: Create Users with Custom Settings | Пример 3: Создание пользователей с кастомными настройками

```yaml
---
- name: Create users with custom settings | Создание пользователей с кастомными настройками
  hosts: all
  become: true
  vars:
    users_to_add:
      - username: webadmin
        password: "WebAdmin123!"
        groups: ["www-data", "nginx"]
        is_sudoers: true
        shell: /bin/bash
        home: "/var/www/webadmin"
        create_home: true
      
      - username: dbadmin
        password: "DbAdmin123!"
        groups: ["postgres", "mysql"]
        is_sudoers: true
        shell: /bin/bash
        home: "/opt/dbadmin"
        create_home: true

  roles:
    - role: base/add_users
```

## Tags | Теги

The role supports the following tags for selective execution:

| Tag | Description |
|-----|-------------|
| `validation` | Run validation only |
| `debug` | Show debug information |
| `facts` | Gather system information |
| `groups` | Create groups |
| `users` | User management |
| `sudo` | Sudo configuration |
| `create` | Create resources |
| `update` | Update resources |
| `cleanup` | Cleanup resources |
| `summary` | Show summary |
| `always` | Always execute |

### Example Tag Usage | Пример использования тегов

```bash
# Run validation only
ansible-playbook playbook.yml --tags validation

# Create groups only
ansible-playbook playbook.yml --tags groups

# User management without sudo
ansible-playbook playbook.yml --tags users --skip-tags sudo

# Show debug information
ansible-playbook playbook.yml --tags debug
```

## Validation | Валидация

The role performs comprehensive input data validation:

### Security Checks | Проверки безопасности
- ✅ Reserved system name checking
- ✅ Password strength validation
- ✅ Username format validation
- ✅ Shell path validation
- ✅ UID range checking

### Integrity Checks | Проверки целостности
- ✅ Required parameter validation
- ✅ Group format validation
- ✅ Absolute path validation
- ✅ Duplicate name detection
- ✅ Variable existence checking

### Reserved Names | Зарезервированные имена

The role automatically checks the following reserved names:
- `root`, `daemon`, `bin`, `sys`, `sync`
- `games`, `man`, `lp`, `mail`, `news`
- `www-data`, `backup`, `list`, `irc`
- `nobody`, `systemd-*`, `_apt`, `tss`
- And other system accounts

## Debugging | Отладка

### Enable Debug Mode | Включение режима отладки

```yaml
vars:
  debug_mode: true
```

### Debug Information | Отладочная информация

The role provides detailed debug information:

1. **User Configuration** - details of each user
2. **System Information** - count of existing users and groups
3. **Execution Plan** - which users will be created/updated
4. **Group Statistics** - list of groups to create
5. **Sudo Information** - users with administrative privileges
6. **Final Summary** - statistics of performed operations

### Example Debug Output | Пример вывода отладки

```yaml
TASK [base/add_users : Display user configuration details (English)] ****
ok: [server1] => (item={'username': 'admin', 'password': '***', 'groups': ['sudo'], 'is_sudoers': True}) => {
    "msg": {
        "user": "admin",
        "configuration": {
            "username": "admin",
            "groups": ["sudo"],
            "sudo_privileges": true,
            "shell": "/bin/bash",
            "uid": "auto",
            "create_home": true,
            "home_directory": "/home/admin"
        }
    }
}
```

## Handlers | Обработчики

The role includes the following handlers:

### Notifications | Уведомления
- `notify user creation` - notification of successful user creation
- `restart sshd` - restart SSH on RedHat systems
- `restart ssh` - restart SSH on Debian systems

### Automatic Actions | Автоматические действия
- SSH service restart when needed
- User creation notifications
- Sudo configuration validation

## Security | Безопасность

### Security Recommendations | Рекомендации по безопасности

1. **Passwords**:
   - Use complex passwords (minimum 8 characters)
   - Enable password validation: `add_users_validate_passwords: true`
   - Consider using Ansible Vault for password storage

2. **Sudo Privileges**:
   - Grant sudo only when necessary
   - Use individual sudoers files
   - Regularly audit sudo configuration

3. **Users**:
   - Avoid reserved system names
   - Use standard naming formats
   - Create home directories in standard locations

### Using Ansible Vault | Использование Ansible Vault

```bash
# Create encrypted file with passwords
ansible-vault create passwords.yml

# Contents of passwords.yml:
users_to_add:
  - username: admin
    password: "{{ vault_admin_password }}"
    is_sudoers: true
```

```yaml
# In playbook:
vars_files:
  - passwords.yml
```

## Troubleshooting | Устранение неполадок

### Common Issues | Частые проблемы

#### 1. Password Validation Error | Ошибка валидации пароля
```
Password for user 'admin' is too short. Minimum length is 8 characters
```
**Solution**: Increase password length or disable validation:
```yaml
add_users_validate_passwords: false
```

#### 2. Reserved Username | Зарезервированное имя пользователя
```
Username 'root' is reserved and cannot be used
```
**Solution**: Use a different username not in the reserved list.

#### 3. Invalid Username Format | Неверный формат имени
```
Username 'Admin' contains invalid characters
```
**Solution**: Use only lowercase letters, numbers, and underscores.

#### 4. Invalid Shell | Неверная оболочка
```
Shell '/bin/custom' is not in the list of valid shells
```
**Solution**: Use a supported shell or add it to `valid_shells`.

### Logs and Diagnostics | Логи и диагностика

```bash
# Run with verbose output
ansible-playbook playbook.yml -vvv

# Run validation only
ansible-playbook playbook.yml --tags validation

# Check syntax
ansible-playbook playbook.yml --syntax-check

# Test run (dry-run)
ansible-playbook playbook.yml --check
```

## Compatibility | Совместимость

### Supported Operating Systems | Поддерживаемые операционные системы

| OS | Versions | Status |
|----|----------|--------|
| Ubuntu | 20.04, 22.04, 24.04 | ✅ Full support |
| Debian | 11, 12, 13 | ✅ Full support |
| CentOS | 7, 8, 9 | ✅ Full support |
| RHEL | 7, 8, 9 | ✅ Full support |
| AlmaLinux | 8, 9 | ✅ Full support |
| Rocky Linux | 8, 9 | ✅ Full support |

### Ansible Requirements | Требования к Ansible

- **Minimum version**: 2.9
- **Recommended version**: 2.12+
- **Collections**: `ansible.builtin`
- **Python**: 2.7+ or 3.6+
