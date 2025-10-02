# Роль управления LXC контейнерами Proxmox - Русская документация

[![Ansible](https://img.shields.io/badge/ansible-2.14%2B-blue.svg)](https://www.ansible.com/)
[![License](https://img.shields.io/badge/license-MIT-brightgreen.svg)](LICENSE)

## Содержание

- [Обзор](#обзор)
- [Требования](#требования)
- [Установка](#установка)
- [Переменные роли](#переменные-роли)
  - [Отладка и валидация](#отладка-и-валидация)
  - [Подключение к API Proxmox](#подключение-к-api-proxmox)
  - [Конфигурация контейнера](#конфигурация-контейнера)
  - [Конфигурация шаблона ОС](#конфигурация-шаблона-ос)
  - [Выделение ресурсов](#выделение-ресурсов)
  - [Настройка сети](#настройка-сети)
  - [Расширенная конфигурация](#расширенная-конфигурация)
- [Зависимости](#зависимости)
- [Примеры playbook](#примеры-playbook)
- [Расширенное использование](#расширенное-использование)
- [Решение проблем](#решение-проблем)
- [Настройка производительности](#настройка-производительности)
- [Лицензия](#лицензия)

## Обзор

Данная роль Ansible автоматизирует создание и управление LXC контейнерами в Proxmox Virtual Environment (PVE). Она предоставляет комплексное решение для управления жизненным циклом контейнеров со следующими возможностями:

- **Автоматическое развертывание**: Создание LXC контейнеров с минимальной конфигурацией
- **Управление шаблонами**: Автоматическая загрузка и кэширование шаблонов ОС
- **Настройка сети**: Гибкая настройка сетевых интерфейсов с поддержкой нескольких сетей
- **Управление ресурсами**: Выделение CPU, памяти и дискового пространства
- **Валидация**: Комплексные предварительные проверки и валидация параметров
- **Обработка ошибок**: Надежная обработка ошибок с логикой повторных попыток
- **Двуязычная поддержка**: Отладочный вывод на английском и русском языках
- **Безопасность**: Маскировка паролей и безопасная обработка учетных данных

## Требования

### Системные требования

- **Версия Ansible**: 2.14 или выше
- **Версия Python**: 3.8 или выше
- **Целевая система**: Proxmox VE 7.x или 8.x
- **Управляющий узел**: Система на базе Linux с установленным Ansible

### Зависимости Python

Роль автоматически устанавливает следующие пакеты Python на целевом хосте:
- `python3`
- `python3-pip`
- `python3-proxmoxer`

### Коллекции Ansible

- `community.general` (версия 8.0.0 или выше)

Установка требуемой коллекции:

```bash
ansible-galaxy collection install community.general
```

## Установка

### Из локальной директории

```bash
# Скопируйте роль в директорию ролей
cp -r proxmox_lxc /etc/ansible/roles/

# Или укажите в playbook
roles_path = ./roles:/etc/ansible/roles
```

### Используя Ansible Galaxy (если опубликована)

```bash
ansible-galaxy install namespace.proxmox_lxc
```

## Переменные роли

### Отладка и валидация

```yaml
# Включить детальный отладочный вывод
debug_mode: true                    # Логическое. По умолчанию: true

# Язык отладочного вывода: 'english', 'russian', 'both'
debug_lang: "both"                  # Строка. По умолчанию: "both"

# Показывать пароли в отладочном выводе (НЕБЕЗОПАСНО)
debug_show_passwords: false         # Логическое. По умолчанию: false

# Включить валидацию параметров
validate_parameters: true           # Логическое. По умолчанию: true

# Включить режим строгой валидации
strict_validation: true             # Логическое. По умолчанию: true
```

### Производительность и надежность

```yaml
# Таймаут асинхронных задач в секундах
async_timeout: 300                  # Целое число. По умолчанию: 300

# Количество повторов для неудачных задач
retries: 3                          # Целое число. По умолчанию: 3

# Задержка между повторами в секундах
retry_delay: 5                      # Целое число. По умолчанию: 5
```

### Подключение к API Proxmox

```yaml
# FQDN или IP адрес Proxmox API
pve_api_host: "proxmox.example.com"   # Обязательно

# Имя узла Proxmox
pve_node: "pve-node1"                  # Обязательно

# Аутентификация API (выберите один метод)

# Метод 1: Имя пользователя/Пароль
pve_api_user: "root@pam"              # Строка
pve_api_password: "ваш_пароль"        # Строка (используйте Ansible Vault!)

# Метод 2: API токен
pve_api_token_id: "user@pam!token"    # Строка
pve_api_token_secret: "секретное_значение"  # Строка (используйте Ansible Vault!)

# Проверка SSL сертификата
pve_validate_certs: false             # Логическое. По умолчанию: false

# Поведение модуля по умолчанию
pve_default_behavior: compatibility   # Строка. Варианты: compatibility, no_defaults
```

### Конфигурация контейнера

```yaml
# Имя хоста контейнера
pve_hostname: "{{ inventory_hostname.split('.')[0] }}"  # Обязательно

# VMID контейнера (авто-назначается если не указан)
pve_lxc_vmid: 100                     # Целое число. Опционально

# Описание контейнера
pve_lxc_description: |                # Строка. Опционально
  Продуктивный веб-сервер
  Управляется Ansible

# Пароль root для контейнера
pve_lxc_root_password: "пароль"       # Обязательно (используйте Ansible Vault!)

# SSH публичный ключ для пользователя root
pve_lxc_root_authorized_pubkey: "{{ lookup('file', '~/.ssh/id_rsa.pub') }}"  # Опционально
```

### Конфигурация шаблона ОС

```yaml
# Имя шаблона в Proxmox
pve_lxc_ostemplate_name: "ubuntu-22.04-standard_22.04-1_amd64.tar.zst"

# URL загрузки шаблона (если отсутствует)
pve_lxc_ostemplate_url: "http://download.proxmox.com/images/system/ubuntu-22.04-standard_22.04-1_amd64.tar.zst"

# Путь к локальному шаблону
pve_lxc_ostemplate_src: "/путь/к/шаблону.tar.zst"

# Хранилище для шаблонов
pve_lxc_ostemplate_storage: "local"   # По умолчанию: local

# Тип содержимого шаблона
pve_lxc_ostemplate_content_type: "vztmpl"  # По умолчанию: vztmpl

# Таймаут операций с шаблоном (секунды)
pve_lxc_ostemplate_timeout: 60        # По умолчанию: 60

# Принудительная загрузка шаблона
pve_lxc_ostemplate_force: true        # По умолчанию: true
```

### Выделение ресурсов

```yaml
# Конфигурация CPU
pve_lxc_cpu_cores: 2                  # Количество ядер CPU
pve_lxc_cpu_limit: 2                  # Лимит CPU
pve_lxc_cpu_units: 1024               # CPU units (вес)

# Конфигурация памяти
pve_lxc_memory: 2048                  # Память в МБ
pve_lxc_swap: 512                     # Swap в МБ

# Конфигурация диска
pve_lxc_disk: 20                      # Размер диска в ГБ
pve_lxc_storage: "local-lvm"          # Имя хранилища

# Поведение контейнера
pve_onboot: true                      # Запускать при загрузке
pve_lxc_unprivileged: true            # Создать непривилегированный контейнер
pve_lxc_force: true                   # Принудительные операции
```

### Настройка сети

```yaml
# Конфигурация DNS
pve_lxc_nameserver: "8.8.8.8 8.8.4.4"
pve_lxc_searchdomain: "example.com"

# Сетевые интерфейсы
pve_lxc_net_interfaces:
  - id: net0
    name: eth0
    hwaddr: "AA:BB:CC:DD:EE:FF"      # Опционально (авто-назначается если не указан)
    ip4: "192.168.1.100"             # IPv4 адрес или "dhcp"
    netmask4: 24                     # Нотация CIDR
    gw4: "192.168.1.1"               # IPv4 шлюз
    bridge: vmbr0                    # Имя моста
    firewall: true                   # Включить брандмауэр
    rate_limit: 1000                 # Ограничение скорости в МБ/с (опционально)
    vlan_tag: 100                    # VLAN тег (опционально)
  
  - id: net1
    name: eth1
    ip6: "2001:db8::10"              # IPv6 адрес или "dhcp" или "auto"
    netmask6: 64
    gw6: "2001:db8::1"
    bridge: vmbr1
```

### Расширенная конфигурация

```yaml
# Функции контейнера
pve_lxc_features:
  - nesting=1
  - keyctl=1

# Hook скрипт
pve_lxc_hookscript: "local:snippets/container_hook.sh"

# Дополнительные точки монтирования
pve_lxc_mounts:
  - id: mp0
    storage: local-lvm
    size: 50                         # Размер в ГБ
    mount_point: "/mnt/data"
    acl: false
    quota: false
    backup: true
    skip_replication: false
    read_only: false

# Дополнительные ручные конфигурации (добавляются в container.conf)
pve_lxc_additional_configurations:
  - regexp: '^features'
    line: 'features: nesting=1,keyctl=1'
    state: present
  
  - regexp: '^lxc.cgroup.devices.allow'
    line: 'lxc.cgroup.devices.allow = c 10:200 rwm'
    state: present
```

## Зависимости

Данная роль требует коллекцию `community.general` для модулей Proxmox.

Создайте файл `requirements.yml`:

```yaml
---
collections:
  - name: community.general
    version: ">=8.0.0"
```

Установите зависимости:

```bash
ansible-galaxy collection install -r requirements.yml
```

## Примеры playbook

### Базовое создание контейнера

```yaml
---
- name: Создание базового LXC контейнера
  hosts: proxmox_hosts
  become: true
  
  roles:
    - role: proxmox_lxc
      vars:
        pve_api_host: "proxmox.local"
        pve_node: "pve1"
        pve_api_user: "root@pam"
        pve_api_password: "{{ vault_proxmox_password }}"
        pve_hostname: "web-server"
        pve_lxc_ostemplate_name: "debian-12-standard_12.2-1_amd64.tar.zst"
        pve_lxc_root_password: "{{ vault_container_password }}"
        pve_lxc_cpu_cores: 2
        pve_lxc_memory: 2048
        pve_lxc_disk: 20
```

### Расширенная конфигурация с несколькими сетями

```yaml
---
- name: Создание контейнера с расширенной настройкой сети
  hosts: proxmox_hosts
  become: true
  
  vars:
    container_hostname: "app-server-01"
  
  roles:
    - role: proxmox_lxc
      vars:
        debug_mode: true
        debug_lang: russian
        
        # Конфигурация API
        pve_api_host: "{{ inventory_hostname }}"
        pve_node: "{{ inventory_hostname }}"
        pve_api_token_id: "ansible@pam!automation"
        pve_api_token_secret: "{{ vault_api_token }}"
        
        # Конфигурация контейнера
        pve_hostname: "{{ container_hostname }}"
        pve_lxc_vmid: 150
        pve_lxc_description: |
          Сервер приложений
          Окружение: Продуктив
          Управляется: Ansible Automation
        pve_lxc_root_password: "{{ vault_container_password }}"
        pve_lxc_root_authorized_pubkey: "{{ lookup('file', '~/.ssh/id_rsa.pub') }}"
        
        # Шаблон
        pve_lxc_ostemplate_name: "ubuntu-22.04-standard_22.04-1_amd64.tar.zst"
        pve_lxc_ostemplate_url: "http://download.proxmox.com/images/system/ubuntu-22.04-standard_22.04-1_amd64.tar.zst"
        
        # Ресурсы
        pve_lxc_cpu_cores: 4
        pve_lxc_memory: 8192
        pve_lxc_swap: 2048
        pve_lxc_disk: 100
        pve_lxc_storage: "local-lvm"
        
        # Поведение
        pve_onboot: true
        pve_lxc_unprivileged: true
        
        # Сеть
        pve_lxc_nameserver: "8.8.8.8 1.1.1.1"
        pve_lxc_searchdomain: "example.com"
        pve_lxc_net_interfaces:
          - id: net0
            name: eth0
            ip4: "192.168.1.150"
            netmask4: 24
            gw4: "192.168.1.1"
            bridge: vmbr0
            firewall: true
          
          - id: net1
            name: eth1
            ip4: "10.0.0.150"
            netmask4: 24
            bridge: vmbr1
            firewall: false
        
        # Дополнительные монтирования
        pve_lxc_mounts:
          - id: mp0
            storage: local-lvm
            size: 50
            mount_point: "/mnt/data"
            backup: true
          
          - id: mp1
            storage: local-lvm
            size: 20
            mount_point: "/mnt/logs"
            backup: false
        
        # Функции
        pve_lxc_features:
          - nesting=1
          - keyctl=1
```

### Использование с инвентарем

**inventory.yml:**

```yaml
all:
  children:
    proxmox_nodes:
      hosts:
        pve1.example.com:
          ansible_host: 192.168.1.10
        pve2.example.com:
          ansible_host: 192.168.1.11
    
    containers:
      hosts:
        web-01:
          pve_lxc_vmid: 101
          pve_lxc_cpu_cores: 2
          pve_lxc_memory: 2048
          pve_lxc_disk: 20
          pve_lxc_ip_address: "192.168.1.101"
        
        db-01:
          pve_lxc_vmid: 102
          pve_lxc_cpu_cores: 4
          pve_lxc_memory: 8192
          pve_lxc_disk: 100
          pve_lxc_ip_address: "192.168.1.102"
```

**playbook.yml:**

```yaml
---
- name: Развертывание контейнеров
  hosts: proxmox_nodes
  
  vars:
    pve_api_host: "{{ inventory_hostname }}"
    pve_node: "{{ inventory_hostname.split('.')[0] }}"
    pve_api_user: "root@pam"
    pve_api_password: "{{ vault_proxmox_password }}"
    pve_lxc_ostemplate_name: "debian-12-standard_12.2-1_amd64.tar.zst"
    pve_lxc_root_password: "{{ vault_container_password }}"
  
  tasks:
    - name: Создание контейнеров
      include_role:
        name: proxmox_lxc
      vars:
        pve_hostname: "{{ item }}"
        pve_lxc_vmid: "{{ hostvars[item].pve_lxc_vmid }}"
        pve_lxc_cpu_cores: "{{ hostvars[item].pve_lxc_cpu_cores }}"
        pve_lxc_memory: "{{ hostvars[item].pve_lxc_memory }}"
        pve_lxc_disk: "{{ hostvars[item].pve_lxc_disk }}"
      loop: "{{ groups['containers'] }}"
```

## Расширенное использование

### Использование Ansible Vault для секретов

Создайте файл vault:

```bash
ansible-vault create group_vars/all/vault.yml
```

Добавьте ваши секреты:

```yaml
---
vault_proxmox_password: "ваш_пароль_proxmox"
vault_container_password: "ваш_пароль_контейнера"
vault_api_token: "ваш_секрет_api_токена"
```

Используйте в playbook:

```bash
ansible-playbook playbook.yml --ask-vault-pass
```

### Управление пользовательскими шаблонами

Загрузка и использование пользовательского шаблона:

```yaml
- role: proxmox_lxc
  vars:
    pve_lxc_ostemplate_src: "/opt/templates/custom-template.tar.zst"
    pve_lxc_ostemplate_name: "custom-template.tar.zst"
    pve_lxc_ostemplate_storage: "local"
```

### Контейнер с поддержкой Docker

```yaml
- role: proxmox_lxc
  vars:
    pve_lxc_features:
      - nesting=1
      - keyctl=1
    pve_lxc_additional_configurations:
      - regexp: '^features'
        line: 'features: nesting=1,keyctl=1'
        state: present
```

## Решение проблем

### Включение режима отладки

```yaml
debug_mode: true
debug_lang: both
debug_show_passwords: false  # Устанавливайте true только в изолированных окружениях
```

### Распространенные проблемы

#### Проблема: Не удалось подключиться к API

**Решение:**
1. Проверьте учетные данные API
2. Проверьте сетевое подключение
3. Проверьте настройки SSL сертификата
4. Включите режим отладки для детальных сообщений об ошибках

```yaml
pve_validate_certs: false  # Для самоподписанных сертификатов
strict_validation: true    # Включить тщательную валидацию
```

#### Проблема: Ошибка загрузки шаблона

**Решение:**
1. Проверьте URL шаблона
2. Проверьте сетевое подключение
3. Проверьте доступное место на диске
4. Увеличьте значения таймаута

```yaml
pve_lxc_ostemplate_timeout: 120
retries: 5
retry_delay: 10
```

#### Проблема: Недостаточно ресурсов

**Решение:**
1. Проверьте ресурсы узла Proxmox
2. Проверьте доступность хранилища
3. Пересмотрите выделение ресурсов

### Валидация и тестирование

Запуск с включенной валидацией:

```bash
ansible-playbook playbook.yml \
  -e "validate_parameters=true" \
  -e "strict_validation=true" \
  -e "debug_mode=true"
```

### Предварительные проверки

Роль автоматически выполняет:
- Проверку версии Ansible (>= 2.14)
- Проверку версии Python (>= 3.8)
- Проверку требуемых модулей Python
- Проверку места на диске (>= 1ГБ свободно)
- Тест подключения к API

## Настройка производительности

### Конфигурация повторных попыток

Настройка параметров повторов для нестабильных сетей:

```yaml
retries: 5                 # Увеличить количество повторов
retry_delay: 10            # Увеличить задержку между повторами
async_timeout: 600         # Увеличить таймаут для долгих операций
```

### Параллельное выполнение

Используйте параметр forks Ansible для параллельного создания контейнеров:

```bash
ansible-playbook playbook.yml --forks=10
```

### Кэширование шаблонов

Предварительная загрузка шаблонов для избежания повторных загрузок:

```yaml
pve_lxc_ostemplate_storage: "local"
pve_lxc_ostemplate_force: false  # Не загружать повторно если существует
```

## Теги

Роль поддерживает следующие теги:

- `always` - Задачи, которые всегда выполняются (валидация, preflight)
- `validation` - Задачи валидации параметров
- `preflight` - Задачи предварительных проверок
- `packages` - Задачи установки пакетов
- `template` - Задачи управления шаблонами
- `download` - Задачи загрузки шаблонов
- `upload` - Задачи выгрузки шаблонов
- `container` - Задачи создания контейнеров
- `config` - Задачи конфигурации
- `debug` - Задачи отладочного вывода

Использование:

```bash
# Выполнить только валидацию
ansible-playbook playbook.yml --tags validation

# Пропустить отладочный вывод
ansible-playbook playbook.yml --skip-tags debug

# Выполнить только создание контейнера
ansible-playbook playbook.yml --tags container
```

## Лицензия

MIT

## Информация об авторах

DevOps Team - Internal Infrastructure Team

## Вклад в развитие

При внесении изменений в эту роль, пожалуйста, убедитесь:

1. Все переменные документированы
2. Примеры предоставлены для новых функций
3. Отладочный вывод двуязычный (Английский/Русский)
4. Реализована правильная обработка ошибок
5. Изменения протестированы на поддерживаемых версиях Proxmox

## Поддержка

По вопросам и проблемам:
- Изучите эту документацию
- Проверьте раздел [решение проблем](#решение-проблем)
- Включите режим отладки для детального вывода
- Свяжитесь с командой DevOps

---

**Последнее обновление:** 2025
**Версия роли:** 1.0.0
**Минимальная версия Ansible:** 2.14

