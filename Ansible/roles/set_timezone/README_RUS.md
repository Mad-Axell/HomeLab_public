# set_timezone

Роль приводит системную таймзону хоста к заданному значению.

## Что делает

- Проверяет, что имя таймзоны задано.
- Применяет таймзону через `community.general.timezone`.

## Требования

- `become: true`.
- Коллекция `community.general`.

## Изменяемые ресурсы

- Files: `/etc/localtime` и `/etc/timezone` (изменяет модуль).
- Services: модуль сам перезапускает `cron`, если этого требует система.
- Packages: none.
- Users/groups: none.

## Переменные

| Variable | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `set_timezone_name` | string | yes | `null` | Имя таймзоны IANA, например `Europe/Moscow`. |
| `set_timezone_debug_mode` | boolean | no | `false` | Показывает факт изменения. |

## Секретные внешние входы

Роль не использует секретов и не читает `VARS/secrets.yml`.

## Использование

```yaml
---
- name: Set the host timezone
  hosts: all
  become: true
  roles:
    - role: set_timezone
      vars:
        set_timezone_name: "Europe/Moscow"
```

## Check mode и diff mode

`community.general.timezone` поддерживает check mode; при `--check` таймзона не
меняется, а изменение только предсказывается.

## Зависимости

- `community.general`

## Handlers и tags

- Handlers: отсутствуют.
- Tags: `debug` на итоговой debug-задаче.
