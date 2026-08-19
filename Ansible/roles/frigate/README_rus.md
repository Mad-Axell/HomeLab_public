# frigate

Роль создает Docker Compose-проект Frigate, записывает конфигурацию из Vault и приводит контейнер к состоянию `present`.

## Что делает

- Создает каталоги проекта, конфигурации и медиа.
- Создает `compose.yml` и секретный `config/config.yml`.
- Запускает Frigate через `community.docker.docker_compose_v2`.

## Требования

- Установленный Docker Compose v2, доступный для пользователя Ansible.
- `become: true` для управляемых каталогов.
- Коллекция `community.docker` в project-level `requirements.yml`.
- Секрет `vault_frigate_config` в `VARS/secrets.yml`.

## Изменяемые ресурсы

- Packages: none.
- Files: Compose-проект и конфигурация под `frigate_project_directory`.
- Services: контейнер Frigate.
- Users/groups: none.
- Firewall/API objects: опубликованные контейнером порты.

## Переменные

| Variable | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `frigate_debug_mode` | boolean | no | `false` | Показывает факт изменения. |
| `frigate_project_directory` | string | no | `"/opt/frigate"` | Каталог Compose-проекта. |
| `frigate_media_directory` | string | no | `"/mnt/frigate"` | Каталог медиа. |
| `frigate_image` | string | no | stable image | Образ Frigate. |
| `frigate_container_name` | string | no | `"frigate"` | Имя контейнера. |
| `frigate_shm_size` | string | no | `"1gb"` | Размер shared memory. |
| `frigate_devices` | list | no | `[]` | Явно передаваемые устройства. |
| `frigate_ports` | list | no | стандартные порты | Публикуемые порты. |
| `vault_frigate_config` | string | yes | - | Полное содержимое Frigate `config.yml` из Vault. |

## Использование

```yaml
---
- name: Deploy Frigate
  hosts: frigate
  become: true
  roles:
    - role: frigate
      vars:
        frigate_devices: ["/dev/bus/usb:/dev/bus/usb"]
```

## Check mode и diff mode

Задача Compose имеет ограничения check mode, зависящие от Docker daemon. Конфигурация приложения использует `no_log: true` и `diff: false`.

## Зависимости

- `community.docker`
