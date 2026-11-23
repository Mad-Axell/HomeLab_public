# portainer

Роль создает каталог данных и запускает контейнер Portainer через `community.docker`.

## Что делает

- Создает каталог постоянных данных.
- Запускает Portainer с монтированием `/var/run/docker.sock` и `/data`.

## Требования

- Запущенный Docker, `become: true` и `community.docker` в project-level `requirements.yml`.

## Изменяемые ресурсы

- Packages: none.
- Files: `portainer_data_directory`.
- Services: контейнер Portainer.
- Users/groups: none.
- Firewall/API objects: опубликованные порты.

## Переменные

| Variable | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `portainer_debug_mode` | boolean | no | `false` | Показывает факт изменения. |
| `portainer_image` | string | no | Portainer CE | Образ контейнера. |
| `portainer_container_name` | string | no | `"portainer"` | Имя контейнера. |
| `portainer_data_directory` | string | no | `"/opt/portainer"` | Каталог данных. |
| `portainer_published_ports` | list | no | `["9000:9000"]` | Опубликованные порты. |

## Использование

```yaml
---
- name: Deploy Portainer
  hosts: docker
  become: true
  roles:
    - role: portainer
```

## Check mode и diff mode

Контейнерный модуль поддерживает `--check --diff` в пределах возможностей Docker daemon.

## Зависимости

- `community.docker`
