# Роль Base Install Packages - Русская Документация

## Обзор

Роль `base.install_packages` предоставляет комплексные возможности установки пакетов для множественных семейств операционных систем (Debian, RedHat, SUSE) с расширенными функциями, включая автоматические обновления безопасности, структурированное логирование и надежную обработку ошибок.

## Содержание

- [Требования](#требования)
- [Переменные роли](#переменные-роли)
- [Зависимости](#зависимости)
- [Пример Playbook](#пример-playbook)
- [Расширенное использование](#расширенное-использование)
- [Поддержка платформ](#поддержка-платформ)
- [Логирование](#логирование)
- [Устранение неполадок](#устранение-неполадок)
- [Лицензия](#лицензия)

## Требования

### Версия Ansible
- **Минимальная**: Ansible 2.9+
- **Рекомендуемая**: Ansible 2.14+

### Поддерживаемые операционные системы

#### Семейство Debian
- **Ubuntu**: focal (20.04), jammy (22.04), noble (24.04)
- **Debian**: bullseye (11), bookworm (12), trixie (13)

#### Семейство RedHat
- **EL**: 7, 8, 9
- **CentOS**: 7
- **Rocky Linux**: 8, 9
- **AlmaLinux**: 8, 9

#### Семейство SUSE
- **openSUSE**: 15.3, 15.4, 15.5, Tumbleweed
- **SLES**: 15.3, 15.4, 15.5

### Требования Python
- Python 3.6+ (на целевых хостах)
- Необходимые пакеты Python: `ansible`, `community.general` (для поддержки SUSE)

## Переменные роли

### Основная конфигурация

| Переменная | Тип | По умолчанию | Описание |
|------------|-----|--------------|----------|
| `essential_packages` | list | См. defaults | Универсальные имена пакетов для установки |
| `optional_packages` | list | `[]` | Дополнительные пакеты для установки |
| `debug_mode` | bool | `false` | Включить подробный отладочный вывод |
| `validate_parameters` | bool | `true` | Включить валидацию параметров |
| `log_file` | str | `/var/log/ansible-changes.log` | Путь к файлу структурированного лога |

### Управление пакетами

| Переменная | Тип | По умолчанию | Описание |
|------------|-----|--------------|----------|
| `package_update_cache` | bool | `true` | Обновлять кэш пакетов перед установкой |
| `package_upgrade_packages` | bool | `true` | Обновлять системные пакеты |
| `package_cache_valid_time` | int | `86400` | Время валидности кэша в секундах (24 часа) |
| `package_install_recommends` | bool | `true` | Устанавливать рекомендуемые пакеты |

### Автоматические обновления

| Переменная | Тип | По умолчанию | Описание |
|------------|-----|--------------|----------|
| `autoupdates_enabled` | bool | `true` | Включить автоматические обновления безопасности |
| `security_updates_only` | bool | `true` | Устанавливать только обновления безопасности |
| `reboot_if_required` | bool | `false` | Разрешить автоматическую перезагрузку после обновлений |
| `gpg_require_signed` | bool | `true` | Требовать проверку GPG подписи |
| `autoupdates_autoremove` | bool | `true` | Удалять неиспользуемые зависимости (Debian/Ubuntu) |
| `autoupdates_schedule_enabled` | bool | `true` | Включить запланированные автоматические обновления |
| `autoupdates_time` | str | `"02:00"` | Время для автоматических обновлений |
| `autoupdates_download_only` | bool | `false` | Загружать обновления без установки |

### Основные пакеты по умолчанию

Роль устанавливает эти универсальные пакеты (сопоставленные с именами для конкретных платформ):

- `acl` - Списки контроля доступа
- `sudo` - Выполнение от имени суперпользователя
- `net-tools` - Сетевые утилиты
- `gnupg` - GNU Privacy Guard
- `audit` - Демон аудита системы
- `libpwquality` - Контроль качества паролей
- `htop` - Интерактивный просмотрщик процессов
- `curl` - Инструмент командной строки для передачи данных
- `wget` - Загрузчик файлов из интернета
- `openssh-clients` - SSH клиент
- `iputils` - Инструменты тестирования сети
- `bind-utils` - DNS утилиты

## Зависимости

### Коллекции Ansible
```yaml
collections:
  - name: community.general
    version: ">=3.0.0"
```

### Зависимости ролей
Отсутствуют - роль разработана как независимая.

## Пример Playbook

### Базовое использование

```yaml
---
- name: Установка основных пакетов
  hosts: all
  become: yes
  roles:
    - role: base.install_packages
      vars:
        essential_packages:
          - sudo
          - curl
          - wget
          - htop
        debug_mode: true
```

### Расширенная конфигурация

```yaml
---
- name: Настройка сервера с пакетами и автобновлениями
  hosts: servers
  become: yes
  roles:
    - role: base.install_packages
      vars:
        # Основные пакеты
        essential_packages:
          - sudo
          - curl
          - wget
          - htop
          - vim
          - git
        
        # Дополнительные пакеты
        optional_packages:
          - tree
          - jq
          - unzip
        
        # Отладка и логирование
        debug_mode: true
        log_file: "/var/log/ansible-package-install.log"
        
        # Автоматические обновления
        autoupdates_enabled: true
        security_updates_only: true
        reboot_if_required: false
        autoupdates_time: "03:00"
```

### Примеры для конкретных платформ

#### Debian/Ubuntu
```yaml
---
- name: Настройка сервера Ubuntu
  hosts: ubuntu_servers
  become: yes
  roles:
    - role: base.install_packages
      vars:
        essential_packages:
          - sudo
          - curl
          - wget
        autoupdates_enabled: true
        autoupdates_autoremove: true
```

#### RedHat/CentOS
```yaml
---
- name: Настройка сервера CentOS
  hosts: centos_servers
  become: yes
  roles:
    - role: base.install_packages
      vars:
        essential_packages:
          - sudo
          - curl
          - wget
        autoupdates_enabled: true
        security_updates_only: true
```

#### SUSE/openSUSE
```yaml
---
- name: Настройка сервера SUSE
  hosts: suse_servers
  become: yes
  roles:
    - role: base.install_packages
      vars:
        essential_packages:
          - sudo
          - curl
          - wget
        autoupdates_enabled: true
        autoupdates_time: "02:30"
```

## Расширенное использование

### Пользовательские сопоставления пакетов

Роль автоматически сопоставляет универсальные имена пакетов с именами для конкретных платформ. Вы можете переопределить эти сопоставления:

```yaml
---
- name: Пользовательские сопоставления пакетов
  hosts: all
  become: yes
  roles:
    - role: base.install_packages
      vars:
        package_mappings:
          debian:
            custom_package: "custom-debian-package"
          redhat:
            custom_package: "custom-redhat-package"
          suse:
            custom_package: "custom-suse-package"
```

### Условная установка пакетов

```yaml
---
- name: Условная установка пакетов
  hosts: all
  become: yes
  roles:
    - role: base.install_packages
      vars:
        essential_packages:
          - sudo
          - curl
          - wget
        optional_packages: "{{ development_packages if is_development | default(false) else [] }}"
```

### Пользовательская конфигурация логирования

```yaml
---
- name: Пользовательская настройка логирования
  hosts: all
  become: yes
  roles:
    - role: base.install_packages
      vars:
        log_file: "/var/log/custom-ansible-changes.log"
        debug_mode: true
```

## Поддержка платформ

### Сопоставление менеджеров пакетов

| Семейство ОС | Менеджер пакетов | Инструмент автобновления |
|---------------|------------------|---------------------------|
| Debian/Ubuntu | APT | unattended-upgrades |
| RedHat/CentOS 7 | YUM | yum-cron |
| RedHat/CentOS 8+ | DNF | dnf-automatic |
| SUSE/openSUSE | Zypper | Пользовательский systemd сервис |

### Функции для конкретных ОС

#### Debian/Ubuntu
- Управление пакетами APT
- `unattended-upgrades` для автоматических обновлений безопасности
- Проверка GPG подписи
- Автоматическая очистка зависимостей

#### RedHat/CentOS
- Управление пакетами YUM/DNF
- `yum-cron` (RHEL 7) или `dnf-automatic` (RHEL 8+) для автоматических обновлений
- Проверка GPG подписи RPM
- Проверка метаданных репозитория

#### SUSE/openSUSE
- Управление пакетами Zypper
- Пользовательский systemd сервис и таймер для автоматических обновлений
- Проверка GPG подписи RPM
- Обновление репозитория и управление ключами

## Логирование

### Формат структурированного логирования

Все операции логируются в формате JSON в указанный файл лога:

```json
{
  "timestamp": "2024-01-15T10:30:45Z",
  "level": "INFO",
  "event_type": "PACKAGE_INSTALL",
  "component": "ESSENTIAL",
  "hostname": "server01",
  "status": "SUCCESS",
  "packages": "sudo,curl,wget",
  "user": "ansible",
  "playbook": "install_packages",
  "correlation_id": "1705312245"
}
```

### Типы событий лога

- `ROLE_START` - Выполнение роли начато
- `ROLE_COMPLETE` - Выполнение роли завершено
- `CACHE_UPDATE` - Кэш пакетов обновлен
- `PACKAGE_INSTALL` - Пакеты установлены
- `CONFIG_CHANGE` - Конфигурация изменена
- `SERVICE_MANAGE` - Операции управления сервисами

### Анализ логов

```bash
# Просмотр всех установок пакетов
grep "PACKAGE_INSTALL" /var/log/ansible-changes.log

# Просмотр изменений конфигурации
grep "CONFIG_CHANGE" /var/log/ansible-changes.log

# Просмотр ошибок
grep '"level":"ERROR"' /var/log/ansible-changes.log
```

## Устранение неполадок

### Распространенные проблемы

#### Сбои установки пакетов
```bash
# Проверка доступности пакетов
ansible host -m shell -a "apt list --installed | grep package_name"  # Debian/Ubuntu
ansible host -m shell -a "rpm -qa | grep package_name"  # RedHat/CentOS
ansible host -m shell -a "zypper se -i package_name"  # SUSE
```

#### Автоматические обновления не работают
```bash
# Проверка статуса сервиса
ansible host -m shell -a "systemctl status unattended-upgrades"  # Debian/Ubuntu
ansible host -m shell -a "systemctl status dnf-automatic.timer"  # RedHat/CentOS 8+
ansible host -m shell -a "systemctl status yum-cron"  # RedHat/CentOS 7
ansible host -m shell -a "systemctl status zypper-automatic-update.timer"  # SUSE
```

#### Проблемы с GPG подписями
```bash
# Обновление GPG ключей
ansible host -m shell -a "apt-key update"  # Debian/Ubuntu
ansible host -m shell -a "rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-*"  # RedHat/CentOS
ansible host -m shell -a "zypper refresh"  # SUSE
```

### Режим отладки

Включите режим отладки для подробного вывода:

```yaml
---
- name: Отладка установки пакетов
  hosts: all
  become: yes
  roles:
    - role: base.install_packages
      vars:
        debug_mode: true
        essential_packages:
          - sudo
          - curl
```

### Проблемы валидации

Роль включает комплексную валидацию параметров. Распространенные ошибки валидации:

- Недопустимые имена пакетов
- Неподдерживаемое семейство ОС
- Недопустимые логические значения
- Отсутствующие обязательные параметры

Проверьте вывод выполнения роли для конкретных сообщений об ошибках валидации.

## Лицензия

MIT

## Автор

Mad-Axell [mad.axell@gmail.com]

## История изменений

### Версия 2.0.0
- Добавлена поддержка структурированного логирования
- Улучшена обработка ошибок с механизмами отката
- Расширена поддержка мультиплатформенности
- Добавлена комплексная валидация параметров

### Версия 1.0.0
- Первоначальный релиз
- Базовая поддержка установки пакетов
- Совместимость с мультиплатформами
