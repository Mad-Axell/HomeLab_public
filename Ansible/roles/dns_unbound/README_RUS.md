# dns_unbound

Роль устанавливает Unbound, создает DNSSEC trust anchor, получает root hints и управляет локальным systemd-сервисом.

## Что делает

- Устанавливает `unbound` и `unbound-anchor`.
- Создает trust anchor и скачивает root hints.
- Создает проверяемую конфигурацию и управляет сервисом Unbound.

## Требования

- Debian или Ubuntu.
- `become: true` и доступ к URL root hints.

## Изменяемые ресурсы

- Packages: `unbound`, `unbound-anchor`.
- Files: root key, root hints и `/etc/unbound/unbound.conf.d/10-server.conf`.
- Services: `unbound`.
- Users/groups: none.
- Firewall/API objects: none.

## Переменные

| Variable | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `dns_unbound_debug_mode` | boolean | no | `false` | Показывает факт изменения. |
| `dns_unbound_service_name` | string | no | `"unbound"` | Имя сервиса. |
| `dns_unbound_service_state` | string | no | `"started"` | Устойчивое состояние сервиса. |
| `dns_unbound_service_enabled` | boolean | no | `true` | Включает сервис при загрузке. |
| `dns_unbound_listen_address` | string | no | `"127.0.0.1"` | Адрес слушателя. |
| `dns_unbound_listen_port` | integer | no | `5335` | Порт слушателя. |
| `dns_unbound_num_threads` | integer | no | `2` | Число рабочих потоков. |
| `dns_unbound_root_hints_url` | string | no | Internic URL | URL root hints. |
| `dns_unbound_config_path` | string | no | путь Debian | Путь конфигурации. |
| `dns_unbound_root_key_path` | string | no | путь Debian | Путь trust anchor. |
| `dns_unbound_root_hints_path` | string | no | путь Debian | Путь root hints. |

## Использование

```yaml
---
- name: Configure local recursive DNS
  hosts: dns
  become: true
  roles:
    - role: dns_unbound
      vars:
        dns_unbound_listen_port: 5335
```

## Check mode и diff mode

Создание trust anchor и скачивание root hints имеют ограничения check mode. Конфигурация перед заменой проверяется `unbound-checkconf`; ее изменение вызывает handler перезапуска.

## Зависимости

- None
