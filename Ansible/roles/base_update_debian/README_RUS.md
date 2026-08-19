# base_update_debian

Роль обновляет индекс APT и установленные пакеты Debian отдельным шагом от установки прикладных пакетов.

## Что делает

- Обновляет индекс APT с указанным сроком актуальности кэша.
- Выполняет обновление установленных пакетов выбранным режимом APT.

## Требования

- Debian/Ubuntu с собранными Ansible facts.
- `become: true`.

## Изменяемые ресурсы

- Packages: все установленные пакеты могут быть обновлены.
- Files: индекс APT в `/var/lib/apt/lists`.
- Services, users/groups, firewall/API objects: не управляются.

## Переменные

| Variable | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `base_update_debian_debug_mode` | boolean | no | `false` | Показывает сводку об изменении. |
| `base_update_debian_cache_valid_time` | integer | no | `86400` | Срок актуальности индекса APT в секундах. |
| `base_update_debian_upgrade_mode` | string | no | `"dist"` | Режим APT: `safe`, `full` или `dist`. |

## Использование

```yaml
---
- name: Update Debian host
  hosts: debian_hosts_group
  become: true
  roles:
    - role: base_update_debian
```

## Check mode и diff mode

`ansible.builtin.apt` поддерживает `--check`; содержательный diff для обновления пакетов не выводится.

## Зависимости

- None.
