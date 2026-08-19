# install_packages

Роль приводит список системных пакетов к состоянию `present` или `absent` через менеджер пакетов целевой ОС.

## Что делает

- Проверяет, что список пакетов и требуемое состояние явно указаны.
- Устанавливает или удаляет заданные пакеты.

## Требования

- Linux с поддерживаемым Ansible менеджером пакетов.
- `become: true` для изменения системных пакетов.

## Изменяемые ресурсы

- Packages: пакеты из `install_packages_names`.
- Files: none.
- Services: none.
- Users/groups: none.
- Firewall/API objects: none.

## Переменные

| Variable | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `install_packages_debug_mode` | boolean | no | `false` | Показывает факт изменения списка пакетов. |
| `install_packages_names` | list | yes | `null` | Непустой список имен пакетов. |
| `install_packages_state` | string | no | `"present"` | `present` для установки или `absent` для удаления. |

## Использование

```yaml
---
- name: Install base utilities
  hosts: linux
  become: true
  roles:
    - role: base/install_packages
      vars:
        install_packages_names:
          - "curl"
          - "htop"
```

## Check mode и diff mode

Задача использует `ansible.builtin.package` и поддерживает `--check --diff` в пределах возможностей менеджера пакетов целевой ОС.

## Зависимости

- None
