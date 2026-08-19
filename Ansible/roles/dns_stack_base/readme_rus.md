# dns_stack_base

Роль готовит Debian/Ubuntu к установке локального DNS-сервиса, не настраивая сам резолвер.

## Что делает

- Устанавливает список базовых пакетов.
- По выбору останавливает, отключает и маскирует `systemd-resolved`.

## Требования

- Debian или Ubuntu.
- `become: true`.

## Изменяемые ресурсы

- Packages: `dns_stack_base_packages`.
- Files: none.
- Services: `systemd-resolved`, только если включено отключение.
- Users/groups: none.
- Firewall/API objects: none.

## Переменные

| Variable | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `dns_stack_base_debug_mode` | boolean | no | `false` | Показывает факт изменения. |
| `dns_stack_base_packages` | list | no | базовый список | Пакеты для DNS-хоста. |
| `dns_stack_base_disable_systemd_resolved` | boolean | no | `true` | Освобождает порт 53 для локального резолвера. |

## Использование

```yaml
---
- name: Prepare DNS host
  hosts: dns
  become: true
  roles:
    - role: dns_stack_base
```

## Check mode и diff mode

Роль использует модули `apt` и `systemd`; они поддерживают `--check --diff` в пределах возможностей целевой системы.

## Зависимости

- None
