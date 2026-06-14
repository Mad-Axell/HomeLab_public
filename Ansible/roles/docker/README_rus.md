# docker

Ansible роль для установки и настройки Docker на управляемых узлах.

## Описание

Эта роль автоматизирует установку Docker Community Edition (CE) или Enterprise Edition (EE) на различных дистрибутивах Linux. Роль поддерживает установку Docker из официальных репозиториев Docker, управление сервисом Docker, установку Docker Compose (плагин или standalone), настройку параметров демона Docker и добавление пользователей в группу docker для работы без sudo.

## Требования

### Требования к управляющему узлу

- Ansible 2.12 или выше (для полной функциональности)
- Python 3.9 или выше

### Требования к управляемым узлам

- Дистрибутив семейства Debian (Debian, Ubuntu, Pop!_OS, Linux Mint)
- Или дистрибутив семейства RedHat (RHEL, CentOS, Fedora)
- Или Alpine Linux
- Или Arch Linux
- Доступ root или sudo
- Подключение к интернету для установки пакетов и загрузки репозиториев

### Зависимости

Отсутствуют

## Переменные роли

### Обязательные переменные

Отсутствуют

### Опциональные переменные

#### Основные настройки Docker

| Переменная | Тип | По умолчанию | Описание |
|-----------|-----|--------------|----------|
| `docker_edition` | string | `'ce'` | Редакция Docker: `'ce'` (Community Edition) или `'ee'` (Enterprise Edition) |
| `docker_packages` | list | `["docker-ce", "docker-ce-cli", "docker-ce-rootless-extras", "containerd.io", "docker-buildx-plugin"]` | Список пакетов Docker для установки |
| `docker_packages_state` | string | `present` | Состояние пакетов: `present`, `absent`, `latest` |
| `docker_add_repo` | bool | `true` | Добавлять ли официальный репозиторий Docker |

#### Настройки сервиса Docker

| Переменная | Тип | По умолчанию | Описание |
|-----------|-----|--------------|----------|
| `docker_service_manage` | bool | `true` | Управлять ли сервисом Docker |
| `docker_service_state` | string | `started` | Состояние сервиса: `started`, `stopped`, `restarted` |
| `docker_service_enabled` | bool | `true` | Включать ли автозапуск Docker при загрузке системы |
| `docker_restart_handler_state` | string | `restarted` | Состояние для обработчика перезапуска |

#### Настройки Docker Compose Plugin

| Переменная | Тип | По умолчанию | Описание |
|-----------|-----|--------------|----------|
| `docker_install_compose_plugin` | bool | `true` | Устанавливать ли Docker Compose Plugin (рекомендуется) |
| `docker_compose_package` | string | `docker-compose-plugin` | Имя пакета Docker Compose Plugin |
| `docker_compose_package_state` | string | `present` | Состояние пакета: `present`, `absent`, `latest` |

#### Настройки Docker Compose (standalone)

| Переменная | Тип | По умолчанию | Описание |
|-----------|-----|--------------|----------|
| `docker_install_compose` | bool | `false` | Устанавливать ли standalone Docker Compose (устаревший метод) |
| `docker_compose_version` | string | `"v2.11.1"` | Версия Docker Compose для установки |
| `docker_compose_arch` | string | `"{{ ansible_architecture }}"` | Архитектура для Docker Compose |
| `docker_compose_path` | string | `/usr/local/bin/docker-compose` | Путь установки Docker Compose |

#### Настройки репозитория (Debian/Ubuntu)

| Переменная | Тип | По умолчанию | Описание |
|-----------|-----|--------------|----------|
| `docker_repo_url` | string | `https://download.docker.com/linux` | Базовый URL репозитория Docker |
| `docker_apt_release_channel` | string | `stable` | Канал релизов: `stable` или `nightly` |
| `docker_apt_arch` | string | `"{{ 'arm64' if ansible_architecture == 'aarch64' else 'amd64' }}"` | Архитектура для APT репозитория |
| `docker_apt_gpg_key` | string | `"{{ docker_repo_url }}/{{ docker_apt_ansible_distribution \| lower }}/gpg"` | URL GPG ключа репозитория |
| `docker_apt_gpg_key_checksum` | string | `sha256:1500c1f56fa9e26b9b8f42452a553675796ade0807cdce11975eb98170b3a570` | Контрольная сумма GPG ключа |
| `docker_apt_ignore_key_error` | bool | `true` | Игнорировать ошибки при добавлении GPG ключа |

#### Настройки репозитория (RedHat/CentOS/Fedora)

| Переменная | Тип | По умолчанию | Описание |
|-----------|-----|--------------|----------|
| `docker_yum_repo_url` | string | `"{{ docker_repo_url }}/{{ (ansible_distribution == 'Fedora') \| ternary('fedora','centos') }}/docker-{{ docker_edition }}.repo"` | URL файла репозитория YUM |
| `docker_yum_repo_enable_nightly` | string | `'0'` | Включить nightly репозиторий: `'0'` или `'1'` |
| `docker_yum_repo_enable_test` | string | `'0'` | Включить test репозиторий: `'0'` или `'1'` |
| `docker_yum_gpg_key` | string | `"{{ docker_repo_url }}/centos/gpg"` | URL GPG ключа для YUM |

#### Управление пользователями

| Переменная | Тип | По умолчанию | Описание |
|-----------|-----|--------------|----------|
| `docker_users` | list | `[]` | Список пользователей для добавления в группу docker |

#### Настройки демона Docker

| Переменная | Тип | По умолчанию | Описание |
|-----------|-----|--------------|----------|
| `docker_daemon_options` | dict | `{}` | Словарь опций для конфигурации демона Docker (записывается в `/etc/docker/daemon.json`) |

## Пример Playbook

### Базовое использование

```yaml
---
- name: Установка Docker
  hosts: all
  become: true
  roles:
    - docker
```

### Установка Docker с добавлением пользователей

```yaml
---
- name: Установка Docker с настройкой пользователей
  hosts: all
  become: true
  vars:
    docker_users:
      - ansible_user
      - deploy
  roles:
    - docker
```

### Настройка Docker с кастомными параметрами демона

```yaml
---
- name: Установка Docker с настройкой демона
  hosts: all
  become: true
  vars:
    docker_daemon_options:
      log-driver: "json-file"
      log-opts:
        max-size: "10m"
        max-file: "3"
      storage-driver: "overlay2"
      default-address-pools:
        - base: "172.17.0.0/12"
          size: 24
  roles:
    - docker
```

### Установка Docker Enterprise Edition

```yaml
---
- name: Установка Docker EE
  hosts: all
  become: true
  vars:
    docker_edition: 'ee'
  roles:
    - docker
```

### Установка standalone Docker Compose (устаревший метод)

```yaml
---
- name: Установка Docker с standalone Compose
  hosts: all
  become: true
  vars:
    docker_install_compose_plugin: false
    docker_install_compose: true
    docker_compose_version: "v2.11.1"
  roles:
    - docker
```

### Отключение автозапуска Docker

```yaml
---
- name: Установка Docker без автозапуска
  hosts: all
  become: true
  vars:
    docker_service_enabled: false
  roles:
    - docker
```

## Что делает эта роль

1. **Загружает OS-специфичные переменные**
   - Определяет переменные в зависимости от дистрибутива (Debian, RedHat, Alpine, Archlinux)

2. **Настраивает репозиторий Docker (Debian/Ubuntu)**
   - Удаляет старые версии Docker (docker, docker.io, docker-engine)
   - Устанавливает зависимости (apt-transport-https, ca-certificates, gnupg/gnupg2)
   - Добавляет GPG ключ репозитория Docker
   - Добавляет официальный репозиторий Docker в источники APT

3. **Настраивает репозиторий Docker (RedHat/CentOS/Fedora)**
   - Удаляет старые версии Docker (docker, docker-common, docker-engine)
   - Добавляет GPG ключ репозитория Docker
   - Добавляет официальный репозиторий Docker
   - Настраивает nightly и test репозитории (если необходимо)
   - Настраивает containerd для RHEL 8

4. **Устанавливает пакеты Docker**
   - Устанавливает Docker CE/EE и необходимые компоненты
   - Устанавливает containerd.io
   - Устанавливает docker-buildx-plugin

5. **Устанавливает Docker Compose Plugin**
   - Устанавливает docker-compose-plugin из репозитория (если включено)

6. **Настраивает демон Docker**
   - Создает директорию `/etc/docker/` (если необходимо)
   - Записывает конфигурацию демона в `/etc/docker/daemon.json` (если заданы `docker_daemon_options`)

7. **Управляет сервисом Docker**
   - Запускает и включает автозапуск сервиса Docker (если `docker_service_manage: true`)

8. **Устанавливает standalone Docker Compose (опционально)**
   - Проверяет текущую версию
   - Загружает и устанавливает указанную версию Docker Compose (если `docker_install_compose: true`)

9. **Добавляет пользователей в группу docker**
   - Добавляет указанных пользователей в группу docker для работы без sudo
   - Сбрасывает SSH соединение для применения изменений группы

## Поддерживаемые дистрибутивы

### Debian/Ubuntu
- Debian (все версии)
- Ubuntu (все версии)
- Pop!_OS
- Linux Mint

### RedHat/CentOS/Fedora
- RHEL 7, 8, 9
- CentOS 7, 8
- Fedora (все версии)

### Другие
- Alpine Linux
- Arch Linux

## Конфигурация демона Docker

Роль позволяет настраивать демон Docker через переменную `docker_daemon_options`. Примеры конфигураций:

### Логирование

```yaml
docker_daemon_options:
  log-driver: "json-file"
  log-opts:
    max-size: "10m"
    max-file: "3"
```

### Хранилище

```yaml
docker_daemon_options:
  storage-driver: "overlay2"
```

### Сетевые настройки

```yaml
docker_daemon_options:
  default-address-pools:
    - base: "172.17.0.0/12"
      size: 24
```

### Реестры и зеркала

```yaml
docker_daemon_options:
  registry-mirrors:
    - "https://mirror.example.com"
  insecure-registries:
    - "registry.example.com:5000"
```

## Примечания

- Роль автоматически определяет архитектуру системы и использует соответствующие пакеты
- Для Ubuntu вариантов (Pop!_OS, Linux Mint) используется специальная логика определения дистрибутива
- Роль использует обработчики (handlers) для перезапуска Docker при изменении конфигурации
- При добавлении пользователей в группу docker выполняется сброс SSH соединения для применения изменений
- Роль поддерживает режим проверки (check mode) Ansible
- Для RHEL 8 роль автоматически настраивает containerd и удаляет конфликтующий пакет runc
- Standalone Docker Compose считается устаревшим методом, рекомендуется использовать Docker Compose Plugin

## Устранение неполадок

### Ошибки при добавлении GPG ключа

Если возникают проблемы с добавлением GPG ключа:
1. Проверьте подключение к интернету
2. Убедитесь, что DNS разрешение работает корректно
3. Проверьте доступность URL репозитория
4. Для старых систем без поддержки SNI роль автоматически использует альтернативный метод с curl

### Проблемы с установкой пакетов

Проверьте:
- Доступность репозитория Docker
- Корректность настройки GPG ключа
- Соответствие архитектуры системы и пакетов
- Наличие необходимых зависимостей

### Пользователь не может использовать Docker без sudo

Убедитесь, что:
- Пользователь добавлен в список `docker_users`
- Выполнен выход и повторный вход в систему (или перезапущен SSH сеанс)
- Группа docker существует: `getent group docker`

### Ошибки при запуске сервиса Docker

Проверьте:
- Логи сервиса: `journalctl -u docker`
- Конфигурацию демона: `/etc/docker/daemon.json`
- Доступность необходимых устройств и ресурсов системы
- Конфликты с другими контейнерными решениями

### Проблемы с Docker Compose

Если Docker Compose не работает:
- Проверьте установку плагина: `docker compose version`
- Для standalone версии проверьте путь: `{{ docker_compose_path }}`
- Убедитесь, что файл имеет права на выполнение: `chmod +x /usr/local/bin/docker-compose`

## Лицензия

MIT

## Автор

Mad-Axell [mad.axell@gmail.com]

## Поддержка

По вопросам и проблемам обращайтесь к автору или создайте issue в репозитории.

