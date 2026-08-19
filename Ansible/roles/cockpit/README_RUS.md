# cockpit

Роль устанавливает Cockpit и модуль `cockpit-storaged`, затем включает socket-активацию веб-интерфейса. Управление экспортом Samba/NFS остается в роли `nas_server`.

## Что делает

- Устанавливает Cockpit и интерфейс управления дисками из уже настроенных репозиториев Debian.
- Включает и запускает `cockpit.socket`.

## Требования

- Debian/Ubuntu с собранными Ansible facts.
- `become: true`.
- Доступные и доверенные APT-репозитории с указанными пакетами.

## Изменяемые ресурсы

- Packages: `cockpit`, `cockpit-storaged` и пакеты из `cockpit_packages`.
- Files: индекс APT в `/var/lib/apt/lists`.
- Services: `cockpit.socket`.
- Users/groups, firewall/API objects: не управляются. Доступ к TCP 9090 настраивается отдельной ролью файрвола.

## Переменные

| Variable | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `cockpit_debug_mode` | boolean | no | `false` | Показывает сводку об изменении. |
| `cockpit_packages` | list | no | `['cockpit', 'cockpit-storaged']` | Пакеты Cockpit из настроенных APT-репозиториев. |
| `cockpit_cache_valid_time` | integer | no | `3600` | Срок актуальности индекса APT в секундах. |
| `cockpit_socket_name` | string | no | `"cockpit.socket"` | Управляемый socket unit systemd. |

## Использование

```yaml
---
- name: Configure Cockpit storage management
  hosts: samba
  become: true
  roles:
    - role: cockpit
```

## Check mode и diff mode

Установка пакетов и управление socket unit поддерживают `--check`; содержательный diff не выводится. Роль не выполняет HTTP-проверок и не открывает firewall-порт.

## Зависимости

- None.

Пакеты 45Drives не добавляются: прежний удаленный сценарий использовал неподтвержденный `curl | bash`. Если такие пакеты нужны, сначала настройте доверенный APT-репозиторий отдельной ролью, затем явно дополните `cockpit_packages`.
