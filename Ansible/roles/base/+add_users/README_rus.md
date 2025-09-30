# Роль add_users | Add Users Role

## Описание | Description

**Русский**: Роль `add_users` предоставляет автоматизированную функциональность создания и управления пользователями в Linux-системах. Поддерживает создание новых пользователей, обновление существующих, управление группами и настройку sudo-привилегий с комплексной валидацией и функциями безопасности.

**English**: The `add_users` role provides automated user creation and management functionality for Linux systems. It supports creating new users, updating existing ones, managing groups, and configuring sudo privileges with comprehensive validation and security features.

## Основные возможности | Key Features

### 🔐 Управление пользователями | User Management
- ✅ Создание новых системных пользователей с полной конфигурацией
- ✅ Обновление существующих пользователей (пароли, группы)
- ✅ Автоматическое создание домашних директорий
- ✅ Настройка пользовательских оболочек (bash, sh, zsh, fish)
- ✅ Управление UID/GID пользователей

### 👥 Управление группами | Group Management
- ✅ Автоматическое создание необходимых групп
- ✅ Добавление пользователей в группы
- ✅ Поддержка множественного членства в группах
- ✅ Валидация имен групп

### 🛡️ Безопасность и sudo | Security and Sudo
- ✅ Индивидуальные файлы конфигурации sudoers
- ✅ Безопасные права доступа к файлам sudo
- ✅ Валидация sudo-привилегий
- ✅ Проверка зарезервированных системных имен
- ✅ Валидация надежности паролей

### 🔍 Валидация и отладка | Validation and Debugging
- ✅ Комплексная валидация входных параметров
- ✅ Проверка форматов имен пользователей и групп
- ✅ Валидация путей и UID
- ✅ Подробная отладочная информация на двух языках
- ✅ Статистика выполнения операций

## Требования | Requirements

### Системные требования | System Requirements
- **Ansible**: >= 2.9
- **ОС**: Linux (Ubuntu, Debian, CentOS, RHEL, AlmaLinux, Rocky Linux)
- **Права**: root или sudo-привилегии
- **Python**: >= 2.7 или >= 3.6

### Зависимости | Dependencies
- `ansible.builtin` collection
- Модули: `user`, `group`, `getent`, `file`, `copy`, `debug`

## Установка | Installation

### Использование в playbook | Using in Playbook

```yaml
---
- name: Создание пользователей системы | Create system users
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

### Переменные по умолчанию | Default Variables

```yaml
# Режим отладки - показывает подробную информацию
debug_mode: true

# Список пользователей для добавления
users_to_add: []

# Глобальные настройки
add_users_create_home: true
add_users_home_prefix: "/home"
add_users_default_shell: "/bin/bash"
add_users_validate_passwords: true
add_users_min_password_length: 8
```

## Конфигурация | Configuration

### Структура пользователя | User Structure

```yaml
users_to_add:
  - username: "имя_пользователя"        # Обязательно | Required
    password: "пароль"                  # Обязательно | Required
    groups: ["группа1", "группа2"]     # Опционально | Optional
    is_sudoers: true/false             # Опционально | Optional
    shell: "/bin/bash"                 # Опционально | Optional
    uid: 1001                          # Опционально | Optional
    gid: 1001                          # Опционально | Optional
    create_home: true                  # Опционально | Optional
    home: "/home/пользователь"         # Опционально | Optional
```

### Параметры пользователя | User Parameters

| Параметр | Тип | Обязательный | Описание |
|----------|-----|--------------|----------|
| `username` | string | ✅ | Имя пользователя (только строчные буквы, цифры, подчеркивания) |
| `password` | string | ✅ | Пароль пользователя (минимум 8 символов) |
| `groups` | list | ❌ | Список групп для добавления пользователя |
| `is_sudoers` | boolean | ❌ | Предоставить sudo-привилегии (по умолчанию: false) |
| `shell` | string | ❌ | Оболочка пользователя (по умолчанию: /bin/bash) |
| `uid` | integer | ❌ | UID пользователя (автоматически, если не указан) |
| `gid` | integer | ❌ | GID пользователя (автоматически, если не указан) |
| `create_home` | boolean | ❌ | Создать домашнюю директорию (по умолчанию: true) |
| `home` | string | ❌ | Путь к домашней директории |

### Поддерживаемые оболочки | Supported Shells

- `/bin/bash` (по умолчанию)
- `/bin/sh`
- `/bin/zsh`
- `/bin/fish`
- `/usr/bin/bash`
- `/usr/bin/sh`
- `/usr/bin/zsh`
- `/usr/bin/fish`

## Примеры использования | Usage Examples

### Пример 1: Создание администратора | Example 1: Create Administrator

```yaml
---
- name: Создание администратора системы | Create system administrator
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

### Пример 2: Создание группы разработчиков | Example 2: Create Developer Group

```yaml
---
- name: Создание пользователей-разработчиков | Create developer users
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

### Пример 3: Создание пользователей с кастомными настройками | Example 3: Create Users with Custom Settings

```yaml
---
- name: Создание пользователей с кастомными настройками | Create users with custom settings
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

## Теги | Tags

Роль поддерживает следующие теги для селективного выполнения:

| Тег | Описание | Description |
|-----|----------|-------------|
| `validation` | Выполнить только валидацию | Run validation only |
| `debug` | Показать отладочную информацию | Show debug information |
| `facts` | Собрать системную информацию | Gather system information |
| `groups` | Создать группы | Create groups |
| `users` | Управление пользователями | User management |
| `sudo` | Настройка sudo | Sudo configuration |
| `create` | Создание ресурсов | Create resources |
| `update` | Обновление ресурсов | Update resources |
| `cleanup` | Очистка ресурсов | Cleanup resources |
| `summary` | Показать сводку | Show summary |
| `always` | Всегда выполнять | Always execute |

### Пример использования тегов | Example Tag Usage

```bash
# Выполнить только валидацию
ansible-playbook playbook.yml --tags validation

# Создать только группы
ansible-playbook playbook.yml --tags groups

# Управление пользователями без sudo
ansible-playbook playbook.yml --tags users --skip-tags sudo

# Показать отладочную информацию
ansible-playbook playbook.yml --tags debug
```

## Валидация | Validation

Роль выполняет комплексную валидацию входных данных:

### Проверки безопасности | Security Checks
- ✅ Проверка зарезервированных системных имен
- ✅ Валидация надежности паролей
- ✅ Проверка формата имен пользователей
- ✅ Валидация путей оболочек
- ✅ Проверка диапазонов UID

### Проверки целостности | Integrity Checks
- ✅ Проверка обязательных параметров
- ✅ Валидация форматов групп
- ✅ Проверка абсолютных путей
- ✅ Обнаружение дублирующихся имен
- ✅ Проверка существования переменных

### Зарезервированные имена | Reserved Names

Роль автоматически проверяет следующие зарезервированные имена:
- `root`, `daemon`, `bin`, `sys`, `sync`
- `games`, `man`, `lp`, `mail`, `news`
- `www-data`, `backup`, `list`, `irc`
- `nobody`, `systemd-*`, `_apt`, `tss`
- И другие системные учетные записи

## Отладка | Debugging

### Включение режима отладки | Enable Debug Mode

```yaml
vars:
  debug_mode: true
```

### Отладочная информация | Debug Information

Роль предоставляет подробную отладочную информацию:

1. **Конфигурация пользователей** - детали каждого пользователя
2. **Системная информация** - количество существующих пользователей и групп
3. **План выполнения** - какие пользователи будут созданы/обновлены
4. **Статистика групп** - список групп для создания
5. **Sudo-информация** - пользователи с административными правами
6. **Финальная сводка** - статистика выполненных операций

### Пример вывода отладки | Example Debug Output

```yaml
TASK [base/add_users : Display user configuration details (Russian)] ****
ok: [server1] => (item={'username': 'admin', 'password': '***', 'groups': ['sudo'], 'is_sudoers': True}) => {
    "msg": [
        "=============================================================================",
        "Детали конфигурации пользователя (Русский):",
        "=============================================================================",
        "Имя пользователя:        admin",
        "Группы:                  sudo",
        "Sudo привилегии:         Да",
        "Оболочка:                /bin/bash",
        "UID:                     авто",
        "Создать домашнюю папку:  Да",
        "Домашняя директория:     /home/admin",
        "============================================================================="
    ]
}
```

## Обработчики | Handlers

Роль включает следующие обработчики:

### Уведомления | Notifications
- `notify user creation` - уведомление об успешном создании пользователя
- `restart sshd` - перезапуск SSH на RedHat-системах
- `restart ssh` - перезапуск SSH на Debian-системах

### Автоматические действия | Automatic Actions
- Перезапуск SSH-службы при необходимости
- Уведомления о создании пользователей
- Валидация конфигурации sudo

## Безопасность | Security

### Рекомендации по безопасности | Security Recommendations

1. **Пароли**:
   - Используйте сложные пароли (минимум 8 символов)
   - Включите валидацию паролей: `add_users_validate_passwords: true`
   - Рассмотрите использование Ansible Vault для хранения паролей

2. **Sudo-привилегии**:
   - Предоставляйте sudo только при необходимости
   - Используйте индивидуальные файлы sudoers
   - Регулярно проверяйте sudo-конфигурацию

3. **Пользователи**:
   - Избегайте зарезервированных системных имен
   - Используйте стандартные форматы имен
   - Создавайте домашние директории в стандартных местах

### Использование Ansible Vault | Using Ansible Vault

```bash
# Создать зашифрованный файл с паролями
ansible-vault create passwords.yml

# Содержимое passwords.yml:
users_to_add:
  - username: admin
    password: "{{ vault_admin_password }}"
    is_sudoers: true
```

```yaml
# В playbook:
vars_files:
  - passwords.yml
```

## Устранение неполадок | Troubleshooting

### Частые проблемы | Common Issues

#### 1. Ошибка валидации пароля | Password Validation Error
```
Password for user 'admin' is too short. Minimum length is 8 characters
```
**Решение**: Увеличьте длину пароля или отключите валидацию:
```yaml
add_users_validate_passwords: false
```

#### 2. Зарезервированное имя пользователя | Reserved Username
```
Username 'root' is reserved and cannot be used
```
**Решение**: Используйте другое имя пользователя, не входящее в список зарезервированных.

#### 3. Неверный формат имени | Invalid Username Format
```
Username 'Admin' contains invalid characters
```
**Решение**: Используйте только строчные буквы, цифры и подчеркивания.

#### 4. Неверная оболочка | Invalid Shell
```
Shell '/bin/custom' is not in the list of valid shells
```
**Решение**: Используйте поддерживаемую оболочку или добавьте ее в `valid_shells`.

### Логи и диагностика | Logs and Diagnostics

```bash
# Запуск с подробным выводом
ansible-playbook playbook.yml -vvv

# Запуск только валидации
ansible-playbook playbook.yml --tags validation

# Проверка синтаксиса
ansible-playbook playbook.yml --syntax-check

# Тестовый запуск (dry-run)
ansible-playbook playbook.yml --check
```

## Совместимость | Compatibility

### Поддерживаемые операционные системы | Supported Operating Systems

| ОС | Версии | Статус |
|----|--------|--------|
| Ubuntu | 20.04, 22.04, 24.04 | ✅ Полная поддержка |
| Debian | 11, 12, 13 | ✅ Полная поддержка |
| CentOS | 7, 8, 9 | ✅ Полная поддержка |
| RHEL | 7, 8, 9 | ✅ Полная поддержка |
| AlmaLinux | 8, 9 | ✅ Полная поддержка |
| Rocky Linux | 8, 9 | ✅ Полная поддержка |

### Требования к Ansible | Ansible Requirements

- **Минимальная версия**: 2.9
- **Рекомендуемая версия**: 2.12+
- **Коллекции**: `ansible.builtin`
- **Python**: 2.7+ или 3.6+

## Лучшие практики | Best Practices

### Структура роли | Role Structure

Роль следует стандартной структуре Ansible:

```
add_users/
├── defaults/main.yaml      # Переменные по умолчанию
├── vars/main.yaml          # Внутренние переменные
├── tasks/
│   ├── main.yaml          # Основные задачи
│   └── validate.yml       # Валидация параметров
├── handlers/main.yml      # Обработчики
├── meta/main.yml          # Метаданные роли
├── README.md              # Основная документация
├── README_rus.md          # Документация на русском
└── README_eng.md          # Документация на английском
```

### Принципы разработки | Development Principles

1. **Идемпотентность**: Роль может выполняться многократно без побочных эффектов
2. **Безопасность**: Комплексная валидация входных данных
3. **Отладка**: Подробная информация о выполнении операций
4. **Модульность**: Четкое разделение задач по функциональности
5. **Документированность**: Полная документация на двух языках

### Рекомендации по использованию | Usage Recommendations

1. **Тестирование**: Всегда используйте `--check` перед применением
2. **Валидация**: Запускайте с тегом `validation` для проверки данных
3. **Отладка**: Включайте `debug_mode: true` для диагностики
4. **Безопасность**: Используйте Ansible Vault для паролей
5. **Теги**: Применяйте теги для селективного выполнения

## Лицензия | License

MIT License

## Автор | Author

Ansible Admin

## Версия | Version

1.0.0