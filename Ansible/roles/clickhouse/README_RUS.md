# clickhouse

Роль устанавливает аналитическую СУБД ClickHouse на LXC `172.25.40.152`.
В Debian 13 пакетов clickhouse нет, поэтому используется официальный
APT-репозиторий вендора `packages.clickhouse.com/deb` — поддерживаемый
апстрим-путь, как и для grafana/promtail в этом проекте.

Конфигурация ведётся только через drop-in'ы: `config.d/90-ansible.xml` для
сетевых и прочих настроек и `users.d/90-ansible.xml` для аккаунтов.
Поставляемые `config.xml`/`users.xml` остаются нетронутыми.

## Что делает

- Проверяет платформу Debian, listen-хосты, порты и типы до любого изменения.
- Проверяет, что у каждого аккаунта есть имя и ровно один из `password_var` /
  `password_sha256_var`, разрешаемый в переменную из `VARS/secrets.yml`.
- Когда сервер слушает не только loopback, требует управляемую запись
  `default` в `clickhouse_users`: пакетный пользователь `default` принимает
  удалённые подключения с пустым паролем.
- Скачивает ASCII-armored ключ подписи в `/etc/apt/keyrings/clickhouse.asc` и
  регистрирует `deb [arch=amd64 signed-by=...] https://packages.clickhouse.com/deb
  stable main` в `/etc/apt/sources.list.d/clickhouse.list`.
- Проверяет, что `clickhouse_data_directory` — отдельная файловая система
  (bind mount ZFS-датасета `behemoth/databases/clickhouse`), до установки
  сервера; при `clickhouse_require_separate_filesystem: false` проверка
  отключается.
- Устанавливает `clickhouse-server` и `clickhouse-client`, передаёт каталог
  данных пользователю `clickhouse`.
- Пишет drop-in `config.d` (listen_host с `replace`, порты, extra-настройки);
  изменение перезапускает сервис через handler.
- Пишет drop-in `users.d` с аккаунтами (или удаляет его при пустом списке);
  ClickHouse применяет users.d сам, перезапуск не нужен.
- Управляет сервисом `clickhouse-server`.

## Требования

- Debian (целевая платформа — Debian 13), `become: true`.
- Собранные facts: `ansible_facts.os_family`.
- Сетевой доступ к `https://packages.clickhouse.com`.
- Пароли аккаунтов — в `VARS/secrets.yml`, подключённом playbook'ом через
  `vars_files`; роль сама этот файл не читает.

## Изменяемые ресурсы

- Packages: `clickhouse_prerequisite_packages`, `clickhouse_packages`.
- Files: `/etc/apt/keyrings/clickhouse.asc`,
  `/etc/apt/sources.list.d/clickhouse.list`,
  `/etc/clickhouse-server/config.d/90-ansible.xml`,
  `/etc/clickhouse-server/users.d/90-ansible.xml`, каталог данных.
- Services: `clickhouse-server`.
- Users/groups: none (системного пользователя создаёт пакет).
- Firewall/API objects: none.

## Переменные

| Variable | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `clickhouse_debug_mode` | boolean | no | `false` | Сводка после значимых изменений. |
| `clickhouse_repository_url` | string | no | `"https://packages.clickhouse.com/deb"` | URL APT-репозитория вендора. |
| `clickhouse_repository_suite` | string | no | `"stable"` | Suite репозитория. |
| `clickhouse_repository_component` | string | no | `"main"` | Компонент репозитория. |
| `clickhouse_repository_arch` | string | no | `"amd64"` | Закреплённая APT-архитектура. |
| `clickhouse_repository_key_url` | string | no | `"https://packages.clickhouse.com/rpm/lts/repodata/repomd.xml.key"` | URL ключа подписи. |
| `clickhouse_keyring_directory` | string | no | `"/etc/apt/keyrings"` | Каталог ключа подписи. |
| `clickhouse_keyring_file` | string | no | `"clickhouse.asc"` | Имя файла ключа (.asc = ASCII-armored). |
| `clickhouse_prerequisite_packages` | list | no | `["ca-certificates", "python3-apt"]` | Пакеты до подключения репозитория. |
| `clickhouse_packages` | list | no | `["clickhouse-server", "clickhouse-client"]` | Пакеты сервера и клиента. |
| `clickhouse_data_directory` | string | no | `"/var/lib/clickhouse"` | Каталог данных. |
| `clickhouse_require_separate_filesystem` | boolean | no | `true` | Требовать отдельную ФС для каталога данных. |
| `clickhouse_config_path` | string | no | `"/etc/clickhouse-server/config.d/90-ansible.xml"` | Drop-in настроек сервера. |
| `clickhouse_users_path` | string | no | `"/etc/clickhouse-server/users.d/90-ansible.xml"` | Drop-in аккаунтов. |
| `clickhouse_listen_hosts` | list | no | `["127.0.0.1"]` | Адреса прослушивания; первый заменяет умолчания пакета. |
| `clickhouse_tcp_port` | integer | no | `9000` | Порт родного TCP-протокола. |
| `clickhouse_http_port` | integer | no | `8123` | Порт HTTP-интерфейса. |
| `clickhouse_users` | list | cond. | `[]` | Аккаунты `{name, password_var|password_sha256_var, networks?, profile?}`; запись `default` обязательна при listen вне loopback. |
| `clickhouse_extra_settings` | dict | no | `{}` | Дополнительные `<имя>значение</имя>` в config.d. |
| `clickhouse_service_name` | string | no | `"clickhouse-server"` | Имя systemd-сервиса. |
| `clickhouse_service_state` | string | no | `"started"` | Устойчивое состояние: `started`/`stopped`. |
| `clickhouse_service_enabled` | boolean | no | `true` | Запуск при загрузке. |

Секреты не объявляются в defaults. `password_var` хранит имя переменной с
открытым паролем, `password_sha256_var` — имя переменной с hex-строкой
`sha256(password)`; обе разрешаются из `VARS/secrets.yml` во время прогона.

## Использование

```yaml
---
- name: Run the analytic database
  hosts: clickhouse
  become: true
  vars_files:
    - ../VARS/secrets.yml
  roles:
    - role: clickhouse
      vars:
        clickhouse_listen_hosts:
          - "127.0.0.1"
          - "172.25.40.152"
        clickhouse_users:
          - name: "default"
            password_sha256_var: "vault_clickhouse_default_password_sha256"
            networks:
              - "127.0.0.1"
          - name: "analytics"
            password_var: "vault_clickhouse_analytics_password"
            networks:
              - "172.25.40.0/24"
```

## Check mode и diff mode

Роль поддерживает запуск:

```bash
ansible-playbook playbook.yml --check --diff
```

Ограничения:

- Проверка файловой системы (`stat %d`) выполняется и в check mode — это
  read-only команда.
- `users.d` помечен `no_log: true` и `diff: false`: содержимое с паролями не
  показывается ни в выводе, ни в diff.
- `get_url` в check mode не скачивает ключ, поэтому при холодном прогоне в
  check mode изменение ключа только предсказывается.

## Handlers

- `Restart ClickHouse` — перезапуск сервиса. Изменения `users.d` ClickHouse
  применяет сам; `listen_host` и порты привязывают сокеты только при старте,
  поэтому изменение `config.d` перезапускает сервис.

## Tags

- `debug` — итоговая сводка при `clickhouse_debug_mode: true`.

## Зависимости

- None. Используются только модули `ansible.builtin`.

## Примечания

- Postinstall `clickhouse-server` может запросить пароль пользователя
  `default` интерактивно; Ansible запускает apt с
  `DEBIAN_FRONTEND=noninteractive`, поэтому запрос пропускается, а пароль
  задаётся декларативно через `clickhouse_users`.
- Данные — реальные и должны пережить контейнер: по умолчанию роль падает,
  если `/var/lib/clickhouse` не на отдельной ФС (ожидается bind mount
  ZFS-датасета `behemoth/databases/clickhouse`).
- `password` в users.d — открытый пароль, читаемый ClickHouse; файл хранится
  `0640 root:clickhouse`. Предпочтительный вариант — `password_sha256_var`.
