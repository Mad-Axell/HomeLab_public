# docker

Роль настраивает официальный APT-репозиторий Docker и устанавливает Docker Engine на Debian/Ubuntu.

## Что делает

- Устанавливает ключ и официальный Docker APT-репозиторий.
- Устанавливает Docker Engine, Buildx и Compose plugin.
- Управляет сервисом Docker и добавляет указанных пользователей в группу `docker`.

## Требования

- Debian или Ubuntu, `become: true` и доступ к репозиторию Docker.

## Изменяемые ресурсы

- Packages: `docker_packages`.
- Files: `/etc/apt/keyrings/docker.asc` и файл репозитория APT.
- Services: `docker`.
- Users/groups: членство перечисленных пользователей в группе `docker`.
- Firewall/API objects: none.

## Переменные

| Variable | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `docker_debug_mode` | boolean | no | `false` | Показывает факт изменения. |
| `docker_repository_url` | string | no | Docker URL | URL репозитория Docker. |
| `docker_repository_key_url` | string | no | Docker URL | URL ключа подписи. |
| `docker_apt_architecture` | string | no | `"amd64"` | Архитектура APT. |
| `docker_packages` | list | no | Docker Engine и plugins | Устанавливаемые пакеты. |
| `docker_service_name` | string | no | `"docker"` | Имя сервиса. |
| `docker_service_state` | string | no | `"started"` | Устойчивое состояние сервиса. |
| `docker_service_enabled` | boolean | no | `true` | Включает сервис при загрузке. |
| `docker_users` | list | no | `[]` | Существующие пользователи для группы `docker`. |

## Использование

```yaml
---
- name: Install Docker
  hosts: debian
  become: true
  roles:
    - role: docker
      vars:
        docker_users: ["operator"]
```

## Check mode и diff mode

Задачи репозитория, пакетов, сервиса и пользователей поддерживают `--check --diff` в пределах возможностей Ansible и APT.

## Зависимости

- None
