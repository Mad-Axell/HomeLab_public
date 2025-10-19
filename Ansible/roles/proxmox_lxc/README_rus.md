# Proxmox LXC Role - Полная документация

## 📋 Содержание

1. [Обзор](#обзор)
2. [Требования](#требования)
3. [Установка](#установка)
4. [Переменные роли](#переменные-роли)
5. [Примеры использования](#примеры-использования)
6. [Расширенная конфигурация](#расширенная-конфигурация)
7. [Структурированное логирование](#структурированное-логирование)
8. [Обработка ошибок](#обработка-ошибок)
9. [Соображения безопасности](#соображения-безопасности)
10. [Устранение неполадок](#устранение-неполадок)
11. [Участие в разработке](#участие-в-разработке)

## Обзор

Роль `proxmox_lxc` обеспечивает комплексную автоматизацию управления жизненным циклом LXC контейнеров в Proxmox Virtual Environment (PVE). Эта роль следует лучшим практикам Ansible и включает структурированное логирование, обработку ошибок и кроссплатформенную поддержку.

### Ключевые возможности

- **Автоматическое создание контейнеров**: Создание LXC контейнеров с настраиваемыми ресурсами
- **Управление шаблонами**: Загрузка, выгрузка и управление шаблонами ОС
- **Конфигурация сети**: Настройка сетевых интерфейсов со статической или DHCP адресацией
- **Управление ресурсами**: Выделение ресурсов CPU, памяти, диска и хранилища
- **Структурированное логирование**: Логирование всех операций в формате JSON
- **Обработка ошибок**: Комплексная обработка ошибок с возможностью отката
- **Кроссплатформенная поддержка**: Поддержка семейств Debian, RedHat и SUSE
- **Валидация**: Валидация параметров и предварительные проверки

## Требования

### Системные требования

- **Ansible**: 2.14 или выше
- **Python**: 3.8 или выше
- **Proxmox VE**: 7.0+ или 8.0+
- **Целевая ОС**: Debian, Ubuntu, RHEL, CentOS, openSUSE, SLES

### Коллекции Ansible

```yaml
collections:
  - community.general
```

### Зависимости Python

Роль автоматически устанавливает следующие пакеты Python:
- `python3`
- `python3-pip`
- `python3-proxmoxer`

## Установка

### 1. Установка необходимых коллекций

```bash
ansible-galaxy collection install community.general
```

### 2. Клонирование или загрузка роли

```bash
# Используя ansible-galaxy
ansible-galaxy install local.proxmox_lxc

# Или клонирование из репозитория
git clone <repository-url> roles/proxmox_lxc
```

### 3. Обновление требований

```bash
ansible-galaxy install -r requirements.yml
```

## Переменные роли

### Настройки отладки и валидации

| Переменная | Тип | По умолчанию | Описание |
|------------|-----|--------------|----------|
| `debug_mode` | bool | `true` | Включить детальный вывод отладки |
| `debug_lang` | str | `"both"` | Язык отладочного вывода (`english`, `russian`, `both`) |
| `debug_show_passwords` | bool | `false` | Показывать пароли в режиме отладки (НЕБЕЗОПАСНО) |
| `validate_parameters` | bool | `true` | Включить валидацию параметров |
| `strict_validation` | bool | `true` | Включить режим строгой валидации |

### Настройки производительности и надежности

| Переменная | Тип | По умолчанию | Описание |
|------------|-----|--------------|----------|
| `async_timeout` | int | `300` | Таймаут асинхронных задач в секундах |
| `retries` | int | `3` | Количество повторов для неудачных задач |
| `retry_delay` | int | `5` | Задержка между повторами в секундах |
| `log_file` | str | `"/var/log/ansible-proxmox-lxc.log"` | Путь к файлу структурированного лога |

### Подключение к API Proxmox

| Переменная | Тип | Обязательно | Описание |
|------------|-----|-------------|----------|
| `pve_api_host` | str | Да | FQDN или IP адрес Proxmox API |
| `pve_node` | str | Да | Имя узла Proxmox где будет создан LXC контейнер |
| `pve_api_user` | str | Нет* | Пользователь для подключения к Proxmox API |
| `pve_api_password` | str | Нет* | Пароль пользователя Proxmox API |
| `pve_api_token_id` | str | Нет* | ID токена Proxmox API |
| `pve_api_token_secret` | str | Нет* | Секрет токена Proxmox API |
| `pve_validate_certs` | bool | `false` | Проверять SSL сертификаты при подключении к Proxmox API |
| `pve_default_behavior` | str | `"compatibility"` | Настройка поведения модуля Proxmox по умолчанию |

*Требуется либо аутентификация пользователь/пароль, либо токен.

### Конфигурация контейнера

| Переменная | Тип | Обязательно | Описание |
|------------|-----|-------------|----------|
| `pve_hostname` | str | Да | Имя хоста для LXC контейнера |
| `pve_lxc_vmid` | int | Нет | VM ID контейнера (автоматически назначается если не указан) |
| `pve_lxc_description` | str | Нет | Описание контейнера |
| `pve_lxc_root_password` | str | Да | Пароль root для контейнера |
| `pve_lxc_root_authorized_pubkey` | str | Нет | SSH публичный ключ для пользователя root |

### Конфигурация шаблона ОС

| Переменная | Тип | По умолчанию | Описание |
|------------|-----|--------------|----------|
| `pve_lxc_ostemplate_name` | str | - | Имя шаблона ОС |
| `pve_lxc_ostemplate_url` | str | - | URL для загрузки шаблона ОС если отсутствует |
| `pve_lxc_ostemplate_src` | str | - | Локальный путь к источнику шаблона ОС |
| `pve_lxc_ostemplate_storage` | str | `"local"` | Имя хранилища для шаблонов ОС |
| `pve_lxc_ostemplate_content_type` | str | `"vztmpl"` | Тип содержимого для шаблона ОС |
| `pve_lxc_ostemplate_timeout` | int | `60` | Таймаут операций с шаблоном в секундах |
| `pve_lxc_ostemplate_force` | bool | `true` | Принудительная загрузка шаблона даже если он существует |
| `pve_lxc_ostemplate_state` | str | `"present"` | Желаемое состояние шаблона |

### Конфигурация ресурсов

| Переменная | Тип | Описание |
|------------|-----|----------|
| `pve_lxc_cpu_cores` | int | Количество ядер CPU |
| `pve_lxc_cpu_limit` | int | Лимит CPU |
| `pve_lxc_cpu_units` | int | CPU units (вес) |
| `pve_lxc_memory` | int | Размер памяти в МБ |
| `pve_lxc_swap` | int | Размер swap в МБ |
| `pve_lxc_disk` | int | Размер диска в ГБ |
| `pve_lxc_storage` | str | Имя хранилища для диска контейнера |

### Поведение контейнера

| Переменная | Тип | По умолчанию | Описание |
|------------|-----|--------------|----------|
| `pve_onboot` | bool | `true` | Запускать контейнер при загрузке узла |
| `pve_lxc_unprivileged` | bool | `true` | Создать непривилегированный контейнер |
| `pve_lxc_force` | bool | `true` | Принудительные операции с контейнером |
| `pve_lxc_timeout` | int | `30` | Таймаут операций с контейнером в секундах |

### Конфигурация сети

| Переменная | Тип | Описание |
|------------|-----|----------|
| `pve_lxc_nameserver` | str | DNS сервер(ы) |
| `pve_lxc_searchdomain` | str | DNS домен поиска |
| `pve_lxc_ip_address` | str | IP адрес контейнера |
| `pve_lxc_ip_mask` | str | Маска подсети IP для сетевого интерфейса контейнера |
| `pve_lxc_ip_gateway` | str | IP шлюз для контейнера |
| `pve_lxc_mac_address` | str | MAC адрес для сетевого интерфейса контейнера |
| `pve_lxc_net_interfaces` | list | Список конфигураций сетевых интерфейсов |

### Расширенная конфигурация

| Переменная | Тип | Описание |
|------------|-----|----------|
| `pve_lxc_features` | list | Функции контейнера (nesting, keyctl и т.д.) |
| `pve_lxc_hookscript` | str | Путь к hook скрипту |
| `pve_lxc_mounts` | list | Список дополнительных точек монтирования |
| `pve_lxc_additional_configurations` | list | Дополнительные конфигурации для добавления в container.conf |
| `proxmox_config_dir` | str | Директория конфигурации Proxmox |
| `proxmox_template_cache_dir` | str | Путь к директории кэша шаблонов |

## Примеры использования

### Базовое создание контейнера

```yaml
- hosts: proxmox_nodes
  roles:
    - role: proxmox_lxc
      vars:
        pve_api_host: "pve.example.com"
        pve_node: "pve-node-01"
        pve_hostname: "web-server"
        pve_lxc_root_password: "{{ vault_root_password }}"
        pve_lxc_ostemplate_name: "debian-11-standard_11.7-1_amd64.tar.gz"
        pve_lxc_cpu_cores: 2
        pve_lxc_memory: 1024
        pve_lxc_disk: 20
        pve_lxc_ip_address: "192.168.1.100"
```

### Развертывание нескольких контейнеров

```yaml
- hosts: proxmox_nodes
  roles:
    - role: proxmox_lxc
      vars:
        pve_api_host: "{{ proxmox_api_host }}"
        pve_node: "{{ proxmox_node }}"
        pve_hostname: "{{ item.hostname }}"
        pve_lxc_root_password: "{{ vault_root_password }}"
        pve_lxc_ostemplate_name: "{{ item.template }}"
        pve_lxc_cpu_cores: "{{ item.cpu_cores }}"
        pve_lxc_memory: "{{ item.memory }}"
        pve_lxc_disk: "{{ item.disk }}"
        pve_lxc_ip_address: "{{ item.ip_address }}"
      loop:
        - hostname: "web-01"
          template: "ubuntu-22.04-standard_22.04-1_amd64.tar.gz"
          cpu_cores: 2
          memory: 1024
          disk: 20
          ip_address: "192.168.1.10"
        - hostname: "db-01"
          template: "debian-11-standard_11.7-1_amd64.tar.gz"
          cpu_cores: 4
          memory: 2048
          disk: 50
          ip_address: "192.168.1.20"
```

### Аутентификация по токену

```yaml
- hosts: proxmox_nodes
  roles:
    - role: proxmox_lxc
      vars:
        pve_api_host: "pve.example.com"
        pve_node: "pve-node-01"
        pve_api_token_id: "automations@pam!ansible"
        pve_api_token_secret: "{{ vault_api_token_secret }}"
        pve_hostname: "secure-container"
        pve_lxc_root_password: "{{ vault_root_password }}"
        pve_lxc_ostemplate_name: "alpine-3.18-standard_3.18.4-1_amd64.tar.gz"
```

## Расширенная конфигурация

### Пользовательская конфигурация сети

```yaml
- hosts: proxmox_nodes
  roles:
    - role: proxmox_lxc
      vars:
        pve_api_host: "pve.example.com"
        pve_node: "pve-node-01"
        pve_hostname: "networked-container"
        pve_lxc_root_password: "{{ vault_root_password }}"
        pve_lxc_ostemplate_name: "debian-11-standard_11.7-1_amd64.tar.gz"
        pve_lxc_net_interfaces:
          - id: net0
            name: eth0
            hwaddr: "02:00:00:00:00:01"
            ip4: "192.168.1.100"
            netmask4: "24"
            gw4: "192.168.1.1"
            bridge: vmbr0
            firewall: true
          - id: net1
            name: eth1
            ip4: "10.0.0.100"
            netmask4: "24"
            bridge: vmbr1
            firewall: false
```

### Дополнительные точки монтирования

```yaml
- hosts: proxmox_nodes
  roles:
    - role: proxmox_lxc
      vars:
        pve_api_host: "pve.example.com"
        pve_node: "pve-node-01"
        pve_hostname: "storage-container"
        pve_lxc_root_password: "{{ vault_root_password }}"
        pve_lxc_ostemplate_name: "debian-11-standard_11.7-1_amd64.tar.gz"
        pve_lxc_mounts:
          - id: mp0
            storage: local-lvm
            size: 100
            mount_point: "/mnt/data"
            acl: true
            quota: false
            backup: true
            read_only: false
          - id: mp1
            storage: nfs-storage
            size: 50
            mount_point: "/mnt/logs"
            acl: false
            quota: true
            backup: false
            read_only: true
```

### Пользовательские функции контейнера

```yaml
- hosts: proxmox_nodes
  roles:
    - role: proxmox_lxc
      vars:
        pve_api_host: "pve.example.com"
        pve_node: "pve-node-01"
        pve_hostname: "featured-container"
        pve_lxc_root_password: "{{ vault_root_password }}"
        pve_lxc_ostemplate_name: "ubuntu-22.04-standard_22.04-1_amd64.tar.gz"
        pve_lxc_features:
          - nesting=1
          - keyctl=1
          - fuse=1
        pve_lxc_hookscript: "local:snippets/vm_hook.sh"
```

## Структурированное логирование

Роль обеспечивает комплексное структурированное логирование в формате JSON со следующими возможностями:

### Расположение файла лога

Файл лога по умолчанию: `/var/log/ansible-proxmox-lxc.log`

Пользовательский файл лога:
```yaml
log_file: "/var/log/custom-proxmox-lxc.log"
```

### Типы событий

| Тип события | Описание |
|-------------|----------|
| `PACKAGE_INSTALL` | Установка пакетов Python |
| `PACKAGE_INSTALL_FAILURE` | Ошибка установки пакетов |
| `CONTAINER_CREATION` | Создание LXC контейнера |
| `CONTAINER_CREATION_FAILURE` | Ошибка создания контейнера |
| `ROLE_EXECUTION_SUMMARY` | Общая сводка выполнения роли |

### Структура записи лога

```json
{
  "timestamp": "2024-01-15T10:30:45.123456Z",
  "level": "INFO",
  "event_type": "CONTAINER_CREATION",
  "service_name": "proxmox_lxc",
  "container_name": "web-server",
  "vmid": "200",
  "changed": true,
  "status": "SUCCESS",
  "user": "ansible",
  "host": "pve-node-01",
  "playbook": "deploy-containers.yml",
  "task": "Create the container",
  "correlation_id": "1705312245",
  "message": "LXC container creation completed",
  "metadata": {
    "api_host": "pve.example.com",
    "node": "pve-node-01",
    "template": "debian-11-standard_11.7-1_amd64.tar.gz",
    "cpu_cores": 2,
    "memory": 1024,
    "disk_size": 20,
    "ip_address": "192.168.1.100",
    "unprivileged": true,
    "onboot": true
  }
}
```

### Анализ логов

Вы можете анализировать логи с помощью стандартных инструментов:

```bash
# Просмотр недавних созданий контейнеров
grep "CONTAINER_CREATION" /var/log/ansible-proxmox-lxc.log | tail -10

# Подсчет успешных операций
grep '"status": "SUCCESS"' /var/log/ansible-proxmox-lxc.log | wc -l

# Поиск ошибок
grep '"level": "ERROR"' /var/log/ansible-proxmox-lxc.log

# Парсинг с jq
cat /var/log/ansible-proxmox-lxc.log | jq '.metadata.container_name'
```

## Обработка ошибок

Роль включает комплексную обработку ошибок со следующими возможностями:

### Паттерн Block-Rescue

Все критические операции используют паттерн block-rescue:

```yaml
- name: "Критическая операция"
  block:
    - name: "Основная операция"
      # ... основная задача ...
  rescue:
    - name: "Обработка ошибки"
      # ... обработка ошибки ...
    - name: "Завершение с деталями"
      ansible.builtin.fail:
        msg: "Операция завершилась с ошибкой. Проверьте отладочный вывод для деталей."
```

### Логика повторов

Настраиваемая логика повторов для неудачных операций:

```yaml
retries: 3
retry_delay: 5
```

### Структурированное логирование ошибок

Все ошибки логируются с полным контекстом:

```json
{
  "level": "ERROR",
  "event_type": "CONTAINER_CREATION_FAILURE",
  "error_message": "Container creation failed: insufficient resources",
  "error_type": "ProxmoxAPIError",
  "metadata": {
    "api_host": "pve.example.com",
    "node": "pve-node-01",
    "template": "debian-11-standard_11.7-1_amd64.tar.gz"
  }
}
```

## Соображения безопасности

### Управление паролями

- Храните все пароли в Ansible Vault
- Используйте `no_log: true` для чувствительных задач
- Включите `debug_show_passwords: false` в продакшене

### Аутентификация по токену

Предпочитайте аутентификацию по токену вместо пользователь/пароль:

```yaml
pve_api_token_id: "automations@pam!ansible"
pve_api_token_secret: "{{ vault_api_token_secret }}"
```

### Валидация SSL сертификатов

Включите валидацию SSL сертификатов в продакшене:

```yaml
pve_validate_certs: true
```

### Сетевая безопасность

- Используйте правила брандмауэра для ограничения доступа к API
- Реализуйте сегментацию сети
- Используйте VPN или частные сети для связи с API

## Устранение неполадок

### Распространенные проблемы

#### 1. Не удалось подключиться к API

**Ошибка**: `Proxmox API is not reachable`

**Решения**:
- Проверьте сетевое подключение к хосту Proxmox
- Убедитесь, что правила брандмауэра разрешают порт 8006
- Подтвердите хост API и учетные данные

#### 2. Шаблон не найден

**Ошибка**: `Template not found`

**Решения**:
- Проверьте имя шаблона и его доступность
- Проверьте расположение хранилища шаблонов
- Загрузите шаблон вручную при необходимости

#### 3. Недостаточно ресурсов

**Ошибка**: `Insufficient resources`

**Решения**:
- Проверьте доступные ресурсы CPU, памяти и диска
- Уменьшите требования к ресурсам
- Освободите ресурсы на узле

#### 4. Доступ запрещен

**Ошибка**: `Permission denied`

**Решения**:
- Проверьте права пользователя API
- Проверьте права токена
- Убедитесь, что пользователь имеет необходимые роли

### Режим отладки

Включите режим отладки для детального устранения неполадок:

```yaml
debug_mode: true
debug_lang: "both"
debug_show_passwords: false  # Оставьте false в продакшене
```

### Анализ логов

Проверьте структурированные логи для получения подробной информации об ошибках:

```bash
# Просмотр недавних ошибок
grep '"level": "ERROR"' /var/log/ansible-proxmox-lxc.log | tail -5

# Проверка операций с конкретным контейнером
grep '"container_name": "web-server"' /var/log/ansible-proxmox-lxc.log
```

## Участие в разработке

### Настройка разработки

1. Клонируйте репозиторий
2. Установите зависимости разработки
3. Запустите тесты с Molecule
4. Следуйте лучшим практикам Ansible

### Стиль кода

- Следуйте рекомендациям по стилю Ansible
- Используйте FQCN для всех модулей
- Включайте двуязычные комментарии (английский/русский)
- Добавляйте структурированное логирование для всех операций

### Тестирование

```bash
# Запуск тестов Molecule
molecule test

# Тестирование конкретного сценария
molecule test -s default
```

### Pull Requests

1. Форкните репозиторий
2. Создайте ветку функции
3. Внесите изменения с тестами
4. Отправьте pull request с описанием

## Лицензия

MIT License - см. файл LICENSE для деталей.

## Поддержка

Для поддержки и вопросов:

- Создайте issue в репозитории
- Проверьте существующую документацию
- Изучите раздел устранения неполадок
- Обратитесь к Mad-Axell [mad.axell@gmail.com]
