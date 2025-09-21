# install_apts

Ansible роль для установки базовых пакетов на Ubuntu/Debian системах.

## Описание

Роль `install_apts` предназначена для установки набора основных пакетов, необходимых для базовой настройки Ubuntu/Debian систем. Роль автоматически обновляет кэш пакетов и может выполнять обновление системы.

## Возможности

- Обновление кэша APT пакетов
- Установка набора предопределенных базовых пакетов
- Возможность обновления существующих пакетов
- Настраиваемое время валидности кэша
- Режим отладки для детального вывода

## Установленные пакеты

Роль устанавливает следующие категории пакетов:

### Системные утилиты
- `acl` - Access Control Lists
- `sudo` - Superuser do
- `net-tools` - Network utilities
- `htop` - Interactive process viewer
- `iputils-ping` - Network testing tools
- `dnsutils` - DNS utilities

### Безопасность
- `gnupg` - GNU Privacy Guard
- `auditd` - System audit daemon
- `libpam-pwquality` - Password quality enforcement
- `openssh-client` - SSH client

### Сетевые инструменты
- `curl` - Command line tool for transferring data
- `wget` - Internet file retriever

### Python и разработка
- `python3` - Python 3 interpreter
- `python3-pip` - Python package installer
- `python3-requests` - HTTP library for Python
- `build-essential` - Essential build tools

### APT и сертификаты
- `apt-transport-https` - HTTPS transport for APT
- `software-properties-common` - Software properties management
- `ca-certificates` - Certificate authorities

## Переменные

### Основные настройки

| Переменная | По умолчанию | Описание |
|------------|--------------|----------|
| `debug_mode` | `false` | Включить режим отладки для детального вывода |
| `apt_cache_valid_time` | `86400` | Время валидности кэша APT в секундах (24 часа) |
| `apt_update_cache` | `true` | Обновлять кэш пакетов перед установкой |
| `apt_upgrade_packages` | `true` | Обновлять существующие пакеты |

### Список пакетов

| Переменная | Описание |
|------------|----------|
| `apt_packages` | Список пакетов для установки (массив строк) |

## Примеры использования

### Базовое использование

```yaml
- hosts: all
  roles:
    - base.install_apts
```

### С дополнительными пакетами

```yaml
- hosts: all
  roles:
    - role: base.install_apts
      vars:
        apt_packages:
          - acl
          - sudo
          - htop
          - vim
          - git
```

### С отключенным обновлением

```yaml
- hosts: all
  roles:
    - role: base.install_apts
      vars:
        apt_upgrade_packages: false
        apt_update_cache: false
```

### С настройкой кэша

```yaml
- hosts: all
  roles:
    - role: base.install_apts
      vars:
        apt_cache_valid_time: 3600  # 1 час
        debug_mode: true
```


