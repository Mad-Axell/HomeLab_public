# unifi_controller

Роль подключает ключ и APT-репозиторий UniFi, устанавливает сервер UniFi Network и включает его systemd-сервис.

## Что делает

- Устанавливает зависимости, keyring и ключ репозитория.
- Подключает переданный APT-репозиторий.
- Устанавливает пакет UniFi и запускает сервис.

## Требования

- Debian или Ubuntu, `become: true` и доступ к репозиторию.

## Изменяемые ресурсы

- Packages: `unifi_controller_package_name`.
- Files: `/etc/apt/keyrings/unifi-controller.asc` и файл репозитория.
- Services: `unifi_controller_service_name`.
- Users/groups: none.
- Firewall/API objects: порты UniFi должны быть разрешены отдельной ролью firewall.

## Переменные

| Variable | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `unifi_controller_debug_mode` | boolean | no | `false` | Показывает факт изменения. |
| `unifi_controller_repository` | string | yes | `null` | URI репозитория с distribution/components. |
| `unifi_controller_repository_key_url` | string | yes | `null` | URL ключа подписи. |
| `unifi_controller_package_name` | string | no | `"unifi"` | Пакет UniFi. |
| `unifi_controller_service_name` | string | no | `"unifi"` | Имя сервиса. |

## Использование

```yaml
---
- name: Install UniFi Network Server
  hosts: unifi
  become: true
  roles:
    - role: unifi_controller
      vars:
        unifi_controller_repository: "https://repository.example.invalid/debian stable ubiquiti"
        unifi_controller_repository_key_url: "https://repository.example.invalid/key.asc"
```

## Check mode и diff mode

Задачи репозитория, пакета и сервиса поддерживают `--check --diff` в пределах возможностей APT.

## Зависимости

- None
