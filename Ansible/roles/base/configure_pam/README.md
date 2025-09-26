# configure_pam Role

## Description / Описание

**English**: Secure PAM (Pluggable Authentication Modules) configuration role for Linux systems with user management and network access control.

**Русский**: Роль для безопасной настройки PAM (Pluggable Authentication Modules) в Linux с управлением пользователями и сетевым доступом.

## Key Features / Основные возможности

### 🔐 Authentication Security / Безопасность аутентификации
- **PAM faillock**: Protection against brute force attacks / Защита от брутфорс атак
- **Password Quality**: Strict password requirements / Строгие требования к паролям
- **Session Limits**: Control of concurrent logins / Контроль одновременных входов
- **Secure TTY**: Root access restrictions / Ограничения доступа root

### 👥 User Management / Управление пользователями
- **User Creation**: Automatic user setup / Автоматическое создание пользователей
- **Groups & Permissions**: Sudo rights management / Управление правами sudo
- **SSH Directories**: Home directory setup / Настройка домашних директорий
- **Validation**: Data structure verification / Проверка структуры данных

### 🌐 Network Access Control / Контроль сетевого доступа
- **pam_access**: IP-based access control / Контроль доступа по IP
- **pam_listfile**: User list management / Управление списками пользователей
- **SSH Security**: SSH parameter configuration / Настройка параметров SSH
- **Management Script**: Access control automation / Автоматизация контроля доступа

### 🛡️ Lockout Prevention / Предотвращение блокировки
- **Pre-checks**: System validation / Проверка системы
- **Backup**: Configuration backups / Резервное копирование
- **Critical Users**: Admin account protection / Защита админских аккаунтов
- **Audit**: Role application tracking / Отслеживание применения роли

## Quick Start / Быстрый старт

### Basic Usage / Базовое использование

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

### Advanced Configuration / Расширенная конфигурация

```yaml
- hosts: servers
  roles:
    - configure_pam
  vars:
    debug_mode: true
    pam_faillock_deny: 5
    pam_pwquality_minlen: 14
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
```

## Requirements / Требования

- **Ansible**: 2.9+
- **OS**: Debian/Ubuntu or RedHat/CentOS
- **Privileges**: root access for PAM configuration
- **Modules**: pam_faillock, pam_pwquality, pam_limits, pam_wheel

## Main Variables / Основные переменные

| Variable | Default | Description |
|----------|---------|-------------|
| `debug_mode` | `false` | Enable debug mode / Включить режим отладки |
| `pam_backup_enabled` | `true` | Create backups / Создавать резервные копии |
| `pam_prevent_lockout` | `true` | Prevent access lockout / Предотвращать блокировку |
| `pam_faillock_deny` | `3` | Failed attempts before lockout / Попытки до блокировки |
| `pam_pwquality_minlen` | `12` | Minimum password length / Минимальная длина пароля |
| `pam_network_access_enabled` | `true` | Enable network access control / Включить сетевой контроль |

## users_to_add Structure / Структура users_to_add

```yaml
users_to_add:
  - username: "admin"                    # Username / Имя пользователя (required / обязательно)
    password: "SecurePassword123!"       # Password / Пароль (required / обязательно)
    groups: ["sudo", "admin"]            # Groups / Группы (optional / опционально)
    is_sudoers: true                     # Admin rights / Права администратора (optional / опционально)
    shell: /bin/bash                     # Shell / Оболочка (optional / опционально)
    allowed_subnets:                     # Allowed networks / Разрешенные сети (optional / опционально)
      - "192.168.1.0/24"
    denied_ssh_subnets:                  # Denied networks / Запрещенные сети (optional / опционально)
      - "192.168.0.0/24"
```

## Access Management Script / Скрипт управления доступом

The role creates `/root/manage_ssh_access.sh` for access management:

```bash
# Add user with subnet access / Добавить пользователя с доступом из подсети
./manage_ssh_access.sh add user1 192.168.1.0/24

# Create new user / Создать нового пользователя
./manage_ssh_access.sh add-user user2 password123 192.168.1.0/24

# Deny user access / Запретить доступ пользователю
./manage_ssh_access.sh deny-user user3

# Show current rules / Показать текущие правила
./manage_ssh_access.sh list

# Restart SSH / Перезапустить SSH
./manage_ssh_access.sh reload
```

## Security Features / Функции безопасности

1. **Lockout Prevention** / **Предотвращение блокировки**: Pre-application checks / Проверки перед применением
2. **Backup** / **Резервное копирование**: Automatic configuration backups / Автоматические резервные копии
3. **Validation** / **Валидация**: Parameter verification / Проверка параметров
4. **Audit** / **Аудит**: Role application tracking / Отслеживание применения роли

## Files Created / Создаваемые файлы

- `/etc/security/access.conf` - pam_access configuration / конфигурация pam_access
- `/etc/security/ssh_users` - Allowed SSH users / Разрешенные SSH пользователи
- `/etc/security/denied_users` - Denied users / Запрещенные пользователи
- `/root/manage_ssh_access.sh` - Access management script / Скрипт управления доступом
- `/etc/sudoers.d/` - Sudo configuration files / Файлы конфигурации sudo

## Documentation / Документация

For complete documentation, see / Для полной документации см.:

- **[README_eng.md](README_eng.md)** - Complete English documentation / Полная документация на английском
- **[README_rus.md](README_rus.md)** - Полная документация на русском языке

## License / Лицензия

MIT

## Author / Автор

Ansible Admin
