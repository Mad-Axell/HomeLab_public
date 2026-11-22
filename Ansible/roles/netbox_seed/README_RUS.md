# netbox_seed

Роль применяет описанные в переменных объекты NetBox через REST API. Она не думает о
топологии: каждый элемент списка `netbox_seed_*` — готовый словарь `data` для
соответствующего модуля коллекции `netbox.netbox`. Роль только проверяет доступ,
применяет объекты в порядке зависимостей и обрабатывает первичные IP отдельным
проходом после адресов.

## Что делает

Проверяет URL и токен API, затем по порядку применяет: RIR → сайты → стойки →
производители → роли устройств и IPAM-роли → типы устройств → группы VLAN и VLAN →
типы кластеров и кластеры → префиксы → устройства → виртуальные машины →
интерфейсы устройств и VM → MAC-адреса → IP-адреса → первичные IP устройств и VM.

## Требования

- Достижимый REST API NetBox (роль ходит по `netbox_seed_api_url` с хоста,
  на котором выполняется play).
- Коллекция `netbox.netbox` и пакет `pynetbox` в интерпретаторе, которым Ansible
  выполняет модули на этом хосте.
- Токен API v2 с правом записи (`nbt_<key>.<plaintext>`) — создаётся ролью
  `netbox` при заданном `netbox_api_token_var`.

## Изменяемые ресурсы

- Объекты NetBox, перечисленные в списках `netbox_seed_*`: `state` каждого —
  `netbox_seed_state` (`present` или `absent`).
- `netbox.netbox` не удаляет объекты, которых нет в списках: роль только
  гарантирует описанное состояние, а не зеркалирует каталог.

## Переменные

| Variable | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `netbox_seed_debug_mode` | boolean | no | `false` | Сводка по количеству объектов. |
| `netbox_seed_api_url` | string | yes | `null` | Базовый URL NetBox, например `http://172.25.40.15`. |
| `netbox_seed_api_token_var` | string | yes | `null` | Имя переменной с токеном `nbt_<key>.<plaintext>`. |
| `netbox_seed_validate_certs` | boolean | no | `true` | Проверка TLS-сертификата для https URL. |
| `netbox_seed_state` | string | no | `present` | `present` или `absent` для всех объектов. |
| `netbox_seed_rirs` | list | no | `[]` | `data` для `netbox_rir`. |
| `netbox_seed_sites` | list | no | `[]` | `data` для `netbox_site`. |
| `netbox_seed_locations` | list | no | `[]` | `data` для `netbox_location`; потомки сайта для устройств в помещениях. |
| `netbox_seed_racks` | list | no | `[]` | `data` для `netbox_rack`. |
| `netbox_seed_manufacturers` | list | no | `[]` | `data` для `netbox_manufacturer`. |
| `netbox_seed_device_roles` | list | no | `[]` | `data` для `netbox_device_role`. |
| `netbox_seed_ipam_roles` | list | no | `[]` | `data` для `netbox_ipam_role`. |
| `netbox_seed_device_types` | list | no | `[]` | `data` для `netbox_device_type`. |
| `netbox_seed_vlan_groups` | list | no | `[]` | `data` для `netbox_vlan_group`. |
| `netbox_seed_vlans` | list | no | `[]` | `data` для `netbox_vlan`. |
| `netbox_seed_cluster_types` | list | no | `[]` | `data` для `netbox_cluster_type`. |
| `netbox_seed_clusters` | list | no | `[]` | `data` для `netbox_cluster`. |
| `netbox_seed_prefixes` | list | no | `[]` | `data` для `netbox_prefix`. |
| `netbox_seed_devices` | list | no | `[]` | `data` для `netbox_device`. Поле `primary_ip4` применяется отдельным проходом после адресов. |
| `netbox_seed_device_bays` | list | no | `[]` | `data` для `netbox_device_bay`; каждый элемент содержит `name`, `device` (родителя) и `installed_device` (потомка). |
| `netbox_seed_wireless_lan_groups` | list | no | `[]` | `data` для `netbox_wireless_lan_group`. |
| `netbox_seed_wireless_lans` | list | no | `[]` | `data` для `netbox_wireless_lan`; `vlan` ссылается на VLAN по имени. |
| `netbox_seed_cables` | list | no | `[]` | `data` для `netbox_cable`; терминации ссылаются на существующие интерфейсы. |
| `netbox_seed_services` | list | no | `[]` | `data` для `netbox_service`; `device` или `virtual_machine` плюс `protocol`/`ports`. |
| `netbox_seed_virtual_machines` | list | no | `[]` | `data` для `netbox_virtual_machine`. `primary_ip4` — как у устройств. |
| `netbox_seed_device_interfaces` | list | no | `[]` | `data` для `netbox_device_interface`. |
| `netbox_seed_vm_interfaces` | list | no | `[]` | `data` для `netbox_vm_interface`. |
| `netbox_seed_mac_addresses` | list | no | `[]` | `data` для `netbox_mac_address`; каждый элемент содержит `mac_address` и `assigned_object`, указывающий на существующий интерфейс. |
| `netbox_seed_ip_addresses` | list | no | `[]` | `data` для `netbox_ip_address`. |

## Использование

```yaml
---
- name: Seed NetBox from the network registry
  hosts: localhost
  gather_facts: false
  vars_files:
    - ../VARS/secrets.yml
  roles:
    - role: netbox_seed
      vars:
        netbox_seed_api_url: "http://172.25.40.15"
        netbox_seed_api_token_var: netbox_api_token
```

## Check mode и diff mode

Модули `netbox.netbox` поддерживают `--check` и показывают `diff` изменений
объектов. Первый прогон в `--check` корректен: создаваемые объекты помечаются как
планируемые. Ограничение: `primary_ip4` прогнозируется только на втором проходе и
может не оцениваться для ещё не созданных адресов.

## Зависимости

- Коллекция `netbox.netbox` (в `requirements.yml` приватного репозитория).
- Пакет `pynetbox` в интерпретаторе Ansible на хосте выполнения.
