# ns_server

Роль устанавливает Unbound и настраивает DNS-forwarder с явно заданными upstream-серверами.

## Что делает

- Устанавливает `unbound`.
- Создает проверяемую конфигурацию forward-zone.
- Управляет сервисом Unbound через handler при изменении конфигурации.

## Требования

- Debian или Ubuntu и `become: true`.

## Изменяемые ресурсы

- Packages: `unbound`.
- Files: `/etc/unbound/unbound.conf.d/ns-server.conf`.
- Services: `unbound`.
- Users/groups: none.
- Firewall/API objects: порт DNS следует разрешить отдельной ролью файрвола.

## Переменные

| Variable | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `ns_server_debug_mode` | boolean | no | `false` | Показывает факт изменения. |
| `ns_server_listen_address` | string | no | `"0.0.0.0"` | Адрес DNS-слушателя. |
| `ns_server_listen_port` | integer | no | `53` | Порт DNS-слушателя. |
| `ns_server_forward_addresses` | list | no | публичные DNS | Вышестоящие DNS-серверы. |

## Использование

```yaml
---
- name: Configure DNS forwarder
  hosts: dns
  become: true
  roles:
    - role: ns_server
```

## Check mode и diff mode

Конфигурация проверяется `unbound-checkconf` до замены и поддерживает `--check --diff`; изменение вызывает handler перезапуска.

## Зависимости

- None
