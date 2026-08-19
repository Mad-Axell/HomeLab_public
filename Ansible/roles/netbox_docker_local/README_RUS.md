# netbox_docker_local

Роль записывает один секретный Compose-файл NetBox и развертывает его через Docker Compose v2.

## Что делает

- Создает каталог проекта.
- Записывает `compose.yml` из Vault без вывода содержимого.
- Приводит Compose-стек к состоянию `present`.

## Требования

- Docker Compose v2 и `community.docker` в project-level `requirements.yml`.
- `become: true` для каталога проекта.
- `vault_netbox_docker_local_compose` в `VARS/secrets.yml`.

## Изменяемые ресурсы

- Packages: none.
- Files: `<project_directory>/compose.yml`.
- Services: контейнеры Compose-стека NetBox.
- Users/groups: none.
- Firewall/API objects: зависят от переданного Compose-файла.

## Переменные

| Variable | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `netbox_docker_local_debug_mode` | boolean | no | `false` | Показывает факт изменения. |
| `netbox_docker_local_project_directory` | string | no | `"/opt/netbox"` | Каталог Compose-проекта. |
| `vault_netbox_docker_local_compose` | string | yes | - | Полное содержимое Compose из Vault. |

## Использование

```yaml
---
- name: Deploy NetBox
  hosts: netbox
  become: true
  roles:
    - role: netbox_docker_local
```

## Check mode и diff mode

Секретный Compose-файл использует `no_log: true` и `diff: false`; модуль Compose имеет зависящие от Docker ограничения check mode.

## Зависимости

- `community.docker`
