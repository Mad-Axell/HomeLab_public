# SSH Configuration Role / Роль конфигурации SSH

## Overview / Обзор

The `base.configure_ssh` role is a comprehensive Ansible role designed to configure SSH servers with security best practices and network-based access control. This role provides fine-grained control over SSH authentication methods based on network source addresses, ensuring secure remote access while maintaining operational flexibility.

Роль `base.configure_ssh` - это комплексная Ansible роль, предназначенная для настройки SSH серверов с применением лучших практик безопасности и контролем доступа на основе сети. Эта роль обеспечивает детальный контроль над методами аутентификации SSH на основе сетевых адресов источника, гарантируя безопасный удаленный доступ при сохранении операционной гибкости.

## Key Features / Ключевые возможности

### Network-Based Access Control / Контроль доступа на основе сети
- **Trusted Networks**: Allow password-only authentication for specified subnets / **Доверенные сети**: Разрешить аутентификацию только по паролю для указанных подсетей
- **Untrusted Networks**: Require both password and public key authentication / **Недоверенные сети**: Требовать как пароль, так и аутентификацию по публичному ключу
- **Automatic Subnet Management**: Extract and deduplicate subnets from user definitions / **Автоматическое управление подсетями**: Извлечение и дедупликация подсетей из определений пользователей
- **Flexible Configuration**: Support both direct subnet configuration and user-based configuration / **Гибкая конфигурация**: Поддержка как прямой конфигурации подсетей, так и конфигурации на основе пользователей

### Security Hardening / Усиление безопасности
- Disabled root login by default / Отключен вход root по умолчанию
- Strong cryptographic algorithms and ciphers / Надежные криптографические алгоритмы и шифры
- Rate limiting and connection management / Ограничение скорости и управление соединениями
- Comprehensive logging and monitoring / Комплексное логирование и мониторинг
- SSH banner configuration / Конфигурация баннера SSH
- Protocol version enforcement / Принудительное использование версии протокола

### Cross-Platform Support / Кроссплатформенная поддержка
- **Debian Family**: Debian, Ubuntu, Linux Mint / **Семейство Debian**: Debian, Ubuntu, Linux Mint
- **RedHat Family**: RHEL, CentOS, Rocky Linux, AlmaLinux, Fedora / **Семейство RedHat**: RHEL, CentOS, Rocky Linux, AlmaLinux, Fedora
- **SUSE Family**: openSUSE, SLES / **Семейство SUSE**: openSUSE, SLES

### Advanced Features / Расширенные возможности
- Comprehensive parameter validation / Комплексная валидация параметров
- Configuration testing and validation / Тестирование и валидация конфигурации
- Backup and recovery capabilities / Возможности резервного копирования и восстановления
- Detailed debug output and logging / Подробный отладочный вывод и логирование
- Service management and monitoring / Управление службами и мониторинг

## Role Structure / Структура роли

```
roles/base/configure_ssh/
├── defaults/
│   └── main.yml          # Default variables and settings / Переменные по умолчанию и настройки
├── handlers/
│   └── main.yml          # Service handlers and notifications / Обработчики служб и уведомления
├── tasks/
│   ├── main.yml          # Main configuration tasks / Основные задачи конфигурации
│   ├── validate.yml      # Parameter validation tasks / Задачи валидации параметров
│   ├── process_allowed_subnets.yml    # Process allowed subnets / Обработка разрешенных подсетей
│   ├── process_denied_subnets.yml     # Process denied subnets / Обработка запрещенных подсетей
│   └── process_not_trusted_subnets.yml # Process not trusted subnets / Обработка недоверенных подсетей
├── templates/
│   ├── sshd_config.j2    # SSH daemon configuration template / Шаблон конфигурации SSH демона
│   └── ssh_banner.j2     # SSH banner template / Шаблон баннера SSH
├── files/
│   └── dynamic_greeting.sh # Dynamic greeting script / Скрипт динамического приветствия
├── README.md             # Main documentation / Основная документация
├── readme_eng.md         # English documentation / Английская документация
├── readme_rus.md         # Russian documentation / Русская документация
└── example-playbook.yml  # Usage examples / Примеры использования
```

## Quick Start / Быстрый старт

### Basic Configuration / Базовая конфигурация

```yaml
- hosts: servers
  roles:
    - role: base.configure_ssh
      vars:
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

### Direct Subnet Configuration / Прямая конфигурация подсетей

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
```

## Configuration Modes / Режимы конфигурации

### 1. Direct Subnet Configuration / Прямая конфигурация подсетей
Configure subnets directly without user definitions / Настройка подсетей напрямую без определений пользователей

### 2. User-Based Configuration / Конфигурация на основе пользователей
Extract subnets from user definitions (recommended for dashboard integration) / Извлечение подсетей из определений пользователей (рекомендуется для интеграции с dashboard)

## Variables / Переменные

### SSH Configuration / Конфигурация SSH
- `ssh_port`: SSH server port (default: 22) / Порт SSH сервера (по умолчанию: 22)
- `ssh_protocol`: SSH protocol (default: "tcp") / Протокол SSH (по умолчанию: "tcp")
- `ssh_service_name`: SSH service name (default: "sshd") / Имя службы SSH (по умолчанию: "sshd")

### Security Settings / Настройки безопасности
- `ssh_security.password_authentication`: Allow password authentication (default: "yes") / Разрешить аутентификацию по паролю (по умолчанию: "yes")
- `ssh_security.pubkey_authentication`: Allow public key authentication (default: "no") / Разрешить аутентификацию по публичному ключу (по умолчанию: "no")
- `ssh_security.permit_root_login`: Allow root login (default: "yes") / Разрешить вход root (по умолчанию: "yes")
- `ssh_security.max_auth_tries`: Maximum authentication attempts (default: 6) / Максимальное количество попыток аутентификации (по умолчанию: 6)

### Network Access Control / Контроль доступа к сети
- `ssh_access_control.trusted_networks_password_auth`: Allow password auth for trusted networks (default: true) / Разрешить аутентификацию по паролю для доверенных сетей (по умолчанию: true)
- `ssh_access_control.untrusted_networks_require_both`: Require both password and key for untrusted networks (default: true) / Требовать и пароль, и ключ для недоверенных сетей (по умолчанию: true)
- `ssh_access_control.default_network_behavior`: Default behavior for undefined networks (default: "restrictive") / Поведение по умолчанию для неопределенных сетей (по умолчанию: "restrictive")

## Tags / Теги

The role supports the following tags for selective execution / Роль поддерживает следующие теги для выборочного выполнения:

- `validation` - Parameter validation tasks / Задачи валидации параметров
- `configuration` - SSH configuration tasks / Задачи конфигурации SSH
- `service` - Service management tasks / Задачи управления службами
- `backup` - Backup operations / Операции резервного копирования
- `debug` - Debug output tasks / Задачи отладочного вывода
- `testing` - Configuration testing tasks / Задачи тестирования конфигурации
- `allowed_subnets` - Allowed subnets processing / Обработка разрешенных подсетей
- `denied_subnets` - Denied subnets processing / Обработка запрещенных подсетей
- `not_trusted_subnets` - Not trusted subnets processing / Обработка недоверенных подсетей

## Dependencies / Зависимости

### Ansible Collections / Коллекции Ansible
- `ansible.builtin` (>=2.9.0)
- `community.general` (>=3.0.0)
- `ansible.posix` (>=1.0.0)

### System Requirements / Системные требования
- Linux operating system / Операционная система Linux
- Root or sudo privileges / Привилегии root или sudo
- OpenSSH server package / Пакет OpenSSH сервера
- Systemd service management / Управление службами systemd

## Documentation / Документация

For detailed documentation, please refer to / Для подробной документации, пожалуйста, обратитесь к:

- [English Documentation](readme_eng.md) / [Английская документация](readme_eng.md)
- [Russian Documentation](readme_rus.md) / [Русская документация](readme_rus.md)
- [Example Playbook](example-playbook.yml) / [Пример плейбука](example-playbook.yml)

## License / Лицензия

MIT License - see LICENSE file for details / Лицензия MIT - см. файл LICENSE для подробностей.
