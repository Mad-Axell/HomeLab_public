# Proxmox LXC Role

Роль Ansible для автоматизированного создания и управления LXC контейнерами в Proxmox Virtual Environment (PVE).

## Описание

Роль `proxmox_lxc` предоставляет унифицированный способ создания LXC контейнеров в Proxmox через API. Поддерживает два режима работы:

1. **Автоматический режим** - автоматически загружает переменные из `host_vars` и `secrets.yaml` на основе переменных `host_name` и `host_vars`. Роль загружает переменные из файла `/etc/ansible/host_vars/{{ host_name }}.yml` и использует `host_vars` как префикс для поиска соответствующих секретов в `secrets.yaml`
2. **Ручной режим** - все параметры контейнера задаются вручную в плейбуке

## Возможности

- Создание LXC контейнеров с настраиваемыми ресурсами (CPU, RAM, диск)
- Автоматическая загрузка OS шаблонов
- Настройка сетевых интерфейсов с поддержкой IPv4/IPv6
- Конфигурация дополнительных точек монтирования
- Управление дополнительными настройками контейнера
- Поддержка как парольной, так и токенной аутентификации
- Автоматический запуск контейнера после создания

## Переменные

### Основные параметры подключения

| Переменная | Описание | По умолчанию |
|------------|----------|--------------|
| `pve_node` | Имя узла Proxmox | `mynode` |
| `pve_api_host` | IP/FQDN API Proxmox | `mynode.mycluster.org` |
| `pve_api_user` | Пользователь API | `automations@pam` |
| `pve_api_password` | Пароль API | - |
| `pve_api_token_id` | ID токена API | - |
| `pve_api_token_secret` | Секрет токена API | - |

### Параметры контейнера

| Переменная | Описание | По умолчанию |
|------------|----------|--------------|
| `pve_lxc_name` | Имя контейнера | `{{ inventory_hostname }}` |
| `pve_lxc_vmid` | VM ID контейнера | Автоопределение |
| `pve_lxc_ostemplate_name` | Имя OS шаблона | - |
| `pve_lxc_root_password` | Пароль root | - |
| `pve_lxc_cpu_cores` | Количество CPU ядер | - |
| `pve_lxc_memory` | Объем RAM (MB) | - |
| `pve_lxc_disk` | Размер диска (GB) | - |
| `pve_onboot` | Автозапуск при загрузке | `true` |
| `pve_lxc_unprivileged` | Непривилегированный контейнер | `true` |

### Сетевые настройки

| Переменная | Описание | По умолчанию |
|------------|----------|--------------|
| `pve_lxc_ip_address` | IP адрес контейнера | - |
| `pve_lxc_ip_mask` | Маска подсети | - |
| `pve_lxc_ip_gateway` | Шлюз по умолчанию | - |
| `pve_lxc_nameserver` | DNS серверы | - |
| `pve_lxc_searchdomain` | Домен поиска | - |

### Дополнительные настройки

| Переменная | Описание | По умолчанию |
|------------|----------|--------------|
| `pve_lxc_mounts` | Дополнительные точки монтирования | `[]` |
| `pve_lxc_net_interfaces` | Сетевые интерфейсы | `[]` |
| `pve_lxc_additional_configurations` | Дополнительные конфигурации | `[]` |
| `pve_lxc_features` | Особенности контейнера | - |

## Структура файлов конфигурации

### Файл secrets.yaml

Файл `secrets.yaml` содержит секретные данные для различных сервисов. Структура:

```yaml
# Глобальные параметры
ansible_user: user
ansible_password: "password"
ansible_connection: ssh
ansible_ssh_private_key_file: /path/to/SSH Keys/id_rsa

# Параметры для каждого сервиса (префикс_имя_сервиса)
service_pve_node: node_name
service_pve_api_user: api_user@pam
service_pve_api_password: "api_password"
service_pve_lxc_root_password: "lxc_password"
service_admin_user: service_admin
service_admin_password: "service_admin_password"
```


### Файл host_vars

```yaml
# Основные параметры контейнера
pve_lxc_name: "lxc_name"
pve_lxc_tech: "gateway_host_from_inventory"
pve_lxc_vmid: 999
pve_lxc_ip_mask: 24

# Сетевые настройки
pve_lxc_mac_address: "06:B9:6D:05:25:94"

# Ресурсы контейнера
pve_lxc_cpu_cores: 4
pve_lxc_cpu_limit: 1
pve_lxc_cpu_units: 1000
pve_lxc_memory: 2048
pve_lxc_swap: 4096
pve_lxc_disk: 16  # в GB для основного диска

# Описание контейнера
pve_lxc_description_extend: |
  - --//--//--//--//--//--//--//--//--//--//--
    - FRAME :       0  # Номер шкафа
    - Tech  :       0  # Номер технического места в шкафу
# - FRAME - Номер шкафа
# - Tech  - Номер технического места в шкафу

# OS шаблон
pve_lxc_ostemplate_name: "debian-12-standard_12.7-1_amd64.tar.zst"
pve_lxc_ostemplate_url: "http://download.proxmox.com/images/system/debian-12-standard_12.7-1_amd64.tar.zst"
pve_lxc_ostemplate_src_dest: "/var/lib/vz/template/cache/"
pve_lxc_ostemplate_src: "/var/lib/vz/template/cache/debian-12-standard_12.7-1_amd64.tar.zst"

# Особенности контейнера
pve_lxc_features:
  - nesting=1
  - keyctl=1

pve_lxc_unprivileged: true
```

Файл `host_vars` должен находиться по пути `/etc/ansible/host_vars/{{ host_name }}.yml` и загружается автоматически при выполнении роли.

## Примеры использования

### Пример 1: Автоматический режим

```yaml
- name: Create LXC container with automatic variable preparation
  hosts: proxmox_node
  become: true
  vars:
    debug_mode: true
    host_name: "web-server"
    host_vars: "web_server"
  vars_files:
    - /etc/ansible/VARS/secrets.yaml
  roles:
    - role: proxmox_lxc
```

### Пример 2: Ручной режим

```yaml
- name: Create LXC container with manual variables
  hosts: proxmox_node
  become: true
  vars:
    pve_node: "pve-node-1"
    pve_api_host: "192.168.1.10"
    pve_api_user: "root@pam"
    pve_api_password: "{{ vault_pve_password }}"
    pve_lxc_name: "database-server"
    pve_lxc_vmid: 1002
    pve_lxc_ostemplate_name: "debian-12-standard_12.2-1_amd64.tar.zst"
    pve_lxc_ip_address: "192.168.1.101"
    pve_lxc_ip_mask: "24"
    pve_lxc_ip_gateway: "192.168.1.1"
    pve_lxc_root_password: "{{ vault_root_password }}"
    pve_lxc_cpu_cores: 4
    pve_lxc_memory: 4096
    pve_lxc_disk: 64
  roles:
    - proxmox_lxc
```

### Пример 3: Создание нескольких контейнеров

```yaml
- name: Create multiple LXC containers
  hosts: proxmox_node
  become: true
  vars:
    debug_mode: false
  tasks:
    - name: Create web server container
      include_role:
        name: proxmox_lxc
      vars:
        host_name: "web-server"
        host_vars: "web_server"
    
    - name: Create database container
      include_role:
        name: proxmox_lxc
      vars:
        host_name: "database-server"
        host_vars: "database_server"
```

## Сетевые интерфейсы

Пример настройки сетевых интерфейсов:

```yaml
pve_lxc_net_interfaces:
  - id: net0
    name: eth0
    hwaddr: "{{ pve_lxc_mac_address }}"
    ip4: "{{ pve_lxc_ip_address }}"
    netmask4: "{{ pve_lxc_ip_mask }}"
    gw4: "{{ pve_lxc_ip_gateway }}"
    bridge: vmbr0
    firewall: true
    rate_limit: 1000
    vlan_tag: 200
```

## Точки монтирования

Пример настройки дополнительных точек монтирования:

```yaml
pve_lxc_mounts:
  - id: mp0
    storage: local-lvm
    size: 16
    mount_point: "/mnt/data"
    acl: false
    quota: false
    backup: true
    read_only: false
```

## Дополнительные конфигурации

Пример добавления дополнительных настроек в конфигурационный файл:

```yaml
pve_lxc_additional_configurations:
  - regexp: '^features'
    line: 'features: nesting=1'
    state: present
  - regexp: '^lxc.cgroup.devices.allow'
    line: 'lxc.cgroup.devices.allow = c 10:200 rwm'
    state: present
```

## Обработчики

Роль включает обработчик `pve_lxc wait for connection`, который ожидает доступности контейнера после создания.

## Безопасность

- Все пароли должны храниться в Ansible Vault
- Используйте токены API вместо паролей где возможно
- Файл `secrets.yaml` должен быть удален после настройки
- Рекомендуется использовать непривилегированные контейнеры

## Зависимости

Роль не имеет внешних зависимостей от других ролей Ansible.

## Лицензия

Роль распространяется в соответствии с лицензией проекта.
