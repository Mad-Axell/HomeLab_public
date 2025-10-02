# UFW Configuration Role / Роль конфигурации UFW

## Description / Описание

This Ansible role configures firewall with security best practices for cross-platform Linux systems. The role supports UFW (Uncomplicated Firewall) for Debian/Ubuntu systems and firewalld for RedHat/SUSE systems. It provides comprehensive firewall configuration with parameter validation, debug information, and service status monitoring.

Эта роль Ansible настраивает файрвол с применением лучших практик безопасности для кроссплатформенных Linux систем. Роль поддерживает UFW (Uncomplicated Firewall) для систем Debian/Ubuntu и firewalld для систем RedHat/SUSE. Роль обеспечивает комплексную настройку файрвола с валидацией параметров, отладочной информацией и мониторингом состояния службы.

## Key Features / Основные возможности

- **Cross-Platform Support / Кроссплатформенная поддержка**: Supports Debian/Ubuntu (UFW) and RedHat/SUSE (firewalld) systems / Поддерживает системы Debian/Ubuntu (UFW) и RedHat/SUSE (firewalld)
- **Secure Default Configuration / Безопасная конфигурация по умолчанию**: Deny incoming, allow outgoing by default / Запрет входящих, разрешение исходящих по умолчанию
- **SSH Access Control / Контроль доступа SSH**: Configurable SSH access from specific subnets / Настраиваемый доступ SSH с определенных подсетей
- **Rate Limiting / Ограничение скорости**: Optional SSH rate limiting to prevent brute force attacks / Опциональное ограничение скорости SSH для предотвращения атак перебора
- **Custom Rules / Пользовательские правила**: Flexible custom firewall rules / Гибкие пользовательские правила файрвола
- **Input Validation / Валидация входных данных**: Comprehensive validation of all parameters / Комплексная валидация всех параметров
- **Service Monitoring / Мониторинг службы**: Comprehensive firewall service health checks and diagnostics / Комплексные проверки состояния и диагностика службы файрвола
- **Configuration Backup / Резервное копирование**: Automatic backup before configuration changes / Автоматическое резервное копирование перед изменениями
- **OS Detection / Определение ОС**: Automatic detection and configuration based on OS family / Автоматическое определение и настройка на основе семейства ОС
- **Bilingual Support / Двуязычная поддержка**: Comments and messages in Russian and English / Комментарии и сообщения на русском и английском языках

## Quick Start / Быстрый старт

### Basic Usage / Базовое использование

```yaml
- hosts: servers
  roles:
    - role: base/configure_ufw
```

### With Custom Users and SSH Port / С пользовательскими пользователями и портом SSH

```yaml
- hosts: servers
  vars:
    ssh_port: 2222
    users_to_add:
      - username: "admin"
        password: "SecurePassword123!"
        groups: ["sudo", "admin"]
        is_sudoers: true
        shell: /bin/bash
        allowed_subnets:
          - "10.0.0.0/8"
        denied_subnets: []
  roles:
    - role: base/configure_ufw
```

## Requirements / Требования

- Ansible 2.9+
- Supported Linux systems / Поддерживаемые Linux системы:
  - **Debian family**: Ubuntu, Debian, Linux Mint / **Семейство Debian**: Ubuntu, Debian, Linux Mint
  - **RedHat family**: RHEL, CentOS, Rocky Linux, AlmaLinux, Fedora / **Семейство RedHat**: RHEL, CentOS, Rocky Linux, AlmaLinux, Fedora
  - **SUSE family**: openSUSE, SLES / **Семейство SUSE**: openSUSE, SLES
- Required collections / Необходимые коллекции:
  - `community.general` (for UFW module / для модуля UFW)
  - `ansible.posix` (for firewalld module / для модуля firewalld)

## Documentation / Документация

For complete documentation, please refer to the following files:

Для полной документации, пожалуйста, обратитесь к следующим файлам:

- **[English Documentation / Английская документация](readme_eng.md)** - Complete role documentation in English / Полная документация роли на английском языке
- **[Russian Documentation / Русская документация](readme_rus.md)** - Полная документация роли на русском языке / Complete role documentation in Russian

## License / Лицензия

This role is licensed under the MIT License.

Эта роль лицензирована под лицензией MIT.

## Author Information / Информация об авторе

Created for HomeLab infrastructure management.

Создана для управления инфраструктурой HomeLab.
