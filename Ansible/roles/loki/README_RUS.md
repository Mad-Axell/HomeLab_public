# loki

Роль устанавливает Grafana Loki на Debian из официального APT-репозитория
Grafana (`apt.grafana.com`) и настраивает однобинарное развёртывание: локальное
хранилище на файловой системе, удаление старых логов compactor'ом и управляемый
systemd-сервис. Пакета `loki` в репозиториях Debian нет, поэтому источником
установки служит репозиторий вендора.

## Что делает

- Проверяет, что целевая система относится к семейству Debian.
- Устанавливает `ca-certificates` и `python3-apt` — то, что нужно для HTTPS и
  `apt_repository`.
- Скачивает ASCII-armored ключ подписи Grafana в
  `/etc/apt/keyrings/grafana.asc` без использования `apt-key` и регистрирует
  `deb [arch=amd64 signed-by=...] https://apt.grafana.com stable main` в
  `/etc/apt/sources.list.d/grafana.list`.
- Устанавливает пакет `loki` (postinstall пакета сам создаёт пользователя
  `loki` и юнит `loki.service` и запускает сервис на поставляемой
  конфигурации).
- Создаёт постоянный каталог данных `/var/lib/loki` с владельцем `loki`:
  поставляемая пакетом конфигурация держит все данные в `/tmp/loki` и теряет их
  при перезагрузке.
- Полностью заменяет `/etc/loki/config.yml` шаблоном роли: `auth_enabled:
  false`, filesystem storage со схемой `tsdb`/`v13`, compactor с
  `retention_enabled` и `deletion_mode: filter-and-delete`, отключённая
  отправка анонимной статистики. Перед заменой файл проверяется командой
  `loki -verify-config`.
- Приводит сервис `loki` к устойчивому состоянию и сразу применяет перезапуск
  через `meta: flush_handlers`.

## Требования

- Debian (целевая платформа — Debian 13 LXC), `become: true`.
- Собранные facts: роль читает `ansible_facts.os_family`.
- Сетевой доступ к `https://apt.grafana.com`.

## Изменяемые ресурсы

- Packages: `loki_prerequisite_packages`, `loki_packages`.
- Files: `/etc/apt/keyrings/grafana.asc`,
  `/etc/apt/sources.list.d/grafana.list`, `/etc/loki/config.yml`, каталог
  `loki_data_dir`.
- Services: `loki`.
- Users/groups: none (пользователь `loki` создаётся postinstall пакета).
- Firewall/API objects: none.

## Переменные

| Variable | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `loki_repository_url` | string | no | `"https://apt.grafana.com"` | URL APT-репозитория Grafana. |
| `loki_repository_suite` | string | no | `"stable"` | Suite репозитория Grafana. |
| `loki_repository_component` | string | no | `"main"` | Компонент репозитория Grafana. |
| `loki_repository_arch` | string | no | `"amd64"` | Закреплённая APT-архитектура. |
| `loki_repository_key_url` | string | no | `"https://apt.grafana.com/gpg-full.key"` | URL ASCII-armored ключа подписи. |
| `loki_keyring_directory` | string | no | `"/etc/apt/keyrings"` | Каталог ключа подписи. |
| `loki_keyring_file` | string | no | `"grafana.asc"` | Имя файла ключа подписи. |
| `loki_prerequisite_packages` | list | no | `["ca-certificates", "python3-apt"]` | Пакеты, нужные до подключения репозитория. |
| `loki_packages` | list | no | `["loki"]` | Пакеты из репозитория Grafana. |
| `loki_auth_enabled` | boolean | no | `false` | Аутентификация арендаторов. |
| `loki_http_listen_address` | string | no | `"0.0.0.0"` | Адрес HTTP API. |
| `loki_http_listen_port` | integer | no | `3100` | Порт HTTP API. |
| `loki_grpc_listen_address` | string | no | `"0.0.0.0"` | Адрес gRPC-интерфейса. |
| `loki_grpc_listen_port` | integer | no | `9095` | Порт gRPC-интерфейса. |
| `loki_log_level` | string | no | `"info"` | Уровень логирования. |
| `loki_data_dir` | string | no | `"/var/lib/loki"` | Каталог данных Loki. |
| `loki_retention_period` | string | no | `"744h"` | Срок хранения логов (31 день). |
| `loki_config_path` | string | no | `"/etc/loki/config.yml"` | Управляемый файл конфигурации. |
| `loki_service_name` | string | no | `"loki"` | Имя systemd-сервиса. |
| `loki_service_state` | string | no | `"started"` | Устойчивое состояние сервиса. |
| `loki_service_enabled` | boolean | no | `true` | Запуск сервиса при загрузке. |
| `loki_debug_mode` | boolean | no | `false` | Debug-вывод после значимых изменений. |

## Секреты

Роль не использует секретов и не читает `VARS/secrets.yml`.

## Использование

```yaml
---
- name: Install Grafana Loki
  hosts: loki
  become: true
  roles:
    - role: loki
```

## Check mode и diff mode

Роль поддерживает `--check --diff` частично, и это ограничение APT, а не дефект:

- в check mode репозиторий фактически не добавляется, поэтому на чистом хосте
  задача установки `loki_packages` сообщит об отсутствии пакета-кандидата;
  полноценный `--check` осмыслен на хосте, где репозиторий уже подключён
  прежним прогоном;
- `validate`-команда шаблона в check mode не выполняется;
- остальные задачи ведут себя в check/diff корректно.

## Зависимости

- None

## Handlers и теги

- Handlers: `Restart Loki` вызывается при изменении `/etc/loki/config.yml`.
- Tags: `debug` на итоговой debug-задаче.

## Примечания

- `auth_enabled: false` подразумевает доверенную сеть: любой клиент с доступом
  к порту 3100 может писать и читать логи. Ограничение доступа — задача
  firewall, а не этой роли.
- Конфигурация рассчитана на один узел: `replication_factor: 1` и ring на
  `inmemory`. Для кластера потребуется другой шаблон.
- Postinstall пакета запускает сервис на поставляемой конфигурации с
  `/tmp/loki`; роль заменяет конфигурацию в том же прогоне и перезапускает
  сервис handler'ом, поэтому `/tmp/loki` в работу не попадает.
