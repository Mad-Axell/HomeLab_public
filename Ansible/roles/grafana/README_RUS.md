# grafana

Роль устанавливает Grafana на Debian-хост из официального APT-репозитория
`apt.grafana.com`, пишет `/etc/grafana/grafana.ini` из шаблона (HTTP-порт,
domain/root_url, встроенный администратор, подключение к базе данных),
декларативно провизионирует источники данных и дашборды и ставит плагины
через `grafana-cli`. По умолчанию Grafana работает на внешнем PostgreSQL и
роль сама создаёт свою базу и роль в нём (`grafana_database_manage`);
встроенный sqlite3 выбирается через `grafana_database_type`. Пароли
приходят из внешних секретов по имени переменной; SSO через Keycloak -
осознанно следующий этап и в эту роль не входит.

## Что делает

- Проверяет платформу Debian, структуру входных списков, имена секретных
  переменных (`grafana_admin_password_var`, при postgres также
  `grafana_database_host` и `grafana_database_password_var`, а при
  `grafana_database_manage` ещё и `grafana_database_admin_password_var`)
  ранним `ansible.builtin.assert`, а затем отдельной проверкой убеждается,
  что названные секреты существуют - всё до любых изменений.
- Скачивает armored-ключ подписи в `/etc/apt/keyrings/grafana.asc` и
  подключает репозиторий
  `deb [arch=amd64 signed-by=...] https://apt.grafana.com stable main`.
- Устанавливает пакет `grafana` и, при `grafana_database_type: "postgres"`,
  пакеты из `grafana_database_packages` (`python3-psycopg2`), нужные модулям
  `community.postgresql` на целевом хосте.
- При `grafana_database_type: "postgres"` и `grafana_database_manage: true`
  создаёт роль PostgreSQL `grafana_database_user` (LOGIN, пароль из
  `grafana_database_password_var`) и базу `grafana_database_name` с
  владельцем `grafana_database_user`; подключение выполняется
  привилегированной учётной записью `grafana_database_admin_user`. Обе таски
  идут с `no_log: true`.
- Пишет `grafana.ini` из шаблона, включая секцию `[database]` при
  `grafana_database_type: "postgres"`. Файл содержит пароли, поэтому таска
  использует `no_log: true` и `diff: false`.
- Пишет `/etc/grafana/provisioning/datasources/datasources.yaml` из списка
  `grafana_datasources` и провайдер
  `/etc/grafana/provisioning/dashboards/dashboards.yaml`, указывающий на
  `grafana_dashboards_path`.
- Копирует JSON-файлы дашбордов из `grafana_dashboards` в
  `grafana_dashboards_path`; провайдер перечитывает каталог по интервалу, без
  перезапуска.
- Ставит плагины из `grafana_plugins` (по умолчанию
  `alexanderzobnin-zabbix-app`) через `grafana-cli plugins install`, но только
  отсутствующие в выводе `grafana-cli plugins ls` - поэтому установка
  идемпотентна.
- Управляет сервисом `grafana-server`; изменения конфигурации и установка
  плагинов перезапускают его через handler.

## Требования

- Debian (целевая платформа проекта - Debian 13, LXC); `become: true`.
- Исходящий HTTPS-доступ к `apt.grafana.com`.
- При `grafana_database_type: "postgres"`: доступный по сети PostgreSQL.
  При `grafana_database_manage: true` (по умолчанию) роль создаёт базу и
  роль сама от имени `grafana_database_admin_user`; при `false` ожидает их
  уже созданными (см. раздел "Примечания").
- Секреты из `VARS/secrets.yml`, названные в `grafana_admin_password_var` и
  `grafana_database_password_var` (а при управлении базой также в
  `grafana_database_admin_password_var`), подключённые playbook'ом (см.
  раздел "Секреты").

## Изменяемые ресурсы

- Packages: `ca-certificates`, `python3-apt`, пакеты из `grafana_packages`
  (`grafana`) и, при бэкенде postgres, `python3-psycopg2` из
  `grafana_database_packages`.
- Files: `/etc/apt/keyrings/grafana.asc`,
  `/etc/apt/sources.list.d/grafana.list`, `/etc/grafana/grafana.ini`,
  `/etc/grafana/provisioning/datasources/datasources.yaml`,
  `/etc/grafana/provisioning/dashboards/dashboards.yaml`, каталог
  `/var/lib/grafana/dashboards` и JSON-файлы дашбордов в нём, плагины в
  `/var/lib/grafana/plugins`.
- Services: `grafana-server`.
- Database objects: при `grafana_database_manage: true` роль PostgreSQL
  `grafana_database_user` и база `grafana_database_name`.
- Users/groups, firewall/API objects: не управляются. Доступ к
  `grafana_http_port` настраивается отдельной ролью firewall.

## Переменные

| Variable | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `grafana_debug_mode` | boolean | no | `false` | Включает debug-сводку после значимых изменений. |
| `grafana_repository_url` | string | no | `"https://apt.grafana.com"` | URL APT-репозитория Grafana. |
| `grafana_repository_key_url` | string | no | `"https://apt.grafana.com/gpg.key"` | URL armored-ключа подписи. |
| `grafana_repository_keyring` | string | no | `"/etc/apt/keyrings/grafana.asc"` | Локальный путь ключа подписи (расширение `.asc` обязательно для armored-ключа). |
| `grafana_repository_filename` | string | no | `"grafana"` | Имя файла источника в `/etc/apt/sources.list.d`. |
| `grafana_repository_suite` | string | no | `"stable"` | Сьюта репозитория. |
| `grafana_repository_component` | string | no | `"main"` | Компонент репозитория. |
| `grafana_apt_architecture` | string | no | `"amd64"` | APT-архитектура пакетов. |
| `grafana_packages` | list | no | `["grafana"]` | Устанавливаемые пакеты. |
| `grafana_config_path` | string | no | `"/etc/grafana/grafana.ini"` | Путь основного конфигурационного файла. |
| `grafana_http_port` | integer | no | `3000` | HTTP-порт Grafana. |
| `grafana_domain` | string | no | `"localhost"` | Публичное доменное имя инстанса (`domain` в grafana.ini). |
| `grafana_root_url` | string или null | no | `null` | Полный root URL для ссылок; при `null` Grafana вычисляет его из protocol/domain/http_port. |
| `grafana_admin_user` | string | no | `"admin"` | Логин встроенного администратора. |
| `grafana_admin_password_var` | string или null | yes | `null` | Имя переменной с паролем администратора в `VARS/secrets.yml`; задаётся по имени, чтобы значение не попадало в host_vars. |
| `grafana_database_type` | string | no | `"postgres"` | Бэкенд базы: `"postgres"` или `"sqlite3"`. |
| `grafana_database_host` | string или null | при postgres | `null` | Хост PostgreSQL; проверяется `assert`, когда `grafana_database_type` равен `"postgres"`. |
| `grafana_database_port` | integer | no | `5432` | Порт PostgreSQL. |
| `grafana_database_name` | string | no | `"grafana"` | Имя базы Grafana. |
| `grafana_database_user` | string | no | `"grafana"` | Логин подключения к базе. |
| `grafana_database_password_var` | string или null | при postgres | `null` | Имя переменной с паролем к базе в `VARS/secrets.yml`; обязательно при `grafana_database_type: "postgres"`. |
| `grafana_database_manage` | boolean | no | `true` | Создавать базу и её роль до первого запуска; при `false` ожидаются готовые объекты. |
| `grafana_database_admin_user` | string | no | `"postgres"` | Привилегированная учётная запись, используемая только для создания базы и роли. |
| `grafana_database_admin_password_var` | string или null | при postgres и manage | `null` | Имя переменной с привилегированным паролем в `VARS/secrets.yml`; обязательно при `grafana_database_type: "postgres"` и `grafana_database_manage: true`. |
| `grafana_database_packages` | list | no | `["python3-psycopg2"]` | Внутреннее: пакеты для модулей `community.postgresql` на целевом хосте. |
| `grafana_datasources_config_path` | string | no | `"/etc/grafana/provisioning/datasources/datasources.yaml"` | Путь файла провизионирования источников. |
| `grafana_datasources` | list | no | `[]` | Источники данных: у каждого обязательны `name`, `type`, `url`; опциональны `access` (по умолчанию `"proxy"`) и `is_default` (по умолчанию `false`). |
| `grafana_dashboards_provider_path` | string | no | `"/etc/grafana/provisioning/dashboards/dashboards.yaml"` | Путь файла провайдера дашбордов. |
| `grafana_dashboards_path` | string | no | `"/var/lib/grafana/dashboards"` | Каталог, сканируемый провайдером. |
| `grafana_dashboards` | list | no | `[]` | JSON-файлы дашбордов; относительные имена ищутся в `files/` роли. |
| `grafana_plugins_path` | string | no | `"/var/lib/grafana/plugins"` | Каталог плагинов; создаётся ролью до `grafana-cli plugins ls`, который без него падает. |
| `grafana_plugins` | list | no | `["alexanderzobnin-zabbix-app"]` | ID плагинов для `grafana-cli plugins install`. |
| `grafana_service_name` | string | no | `"grafana-server"` | Имя systemd-юнита. |
| `grafana_service_state` | string | no | `"started"` | Устойчивое состояние сервиса (`started`/`stopped`). |
| `grafana_service_enabled` | boolean | no | `true` | Включать сервис при загрузке. |

## Секреты

Секреты задаются не прямыми именами, а через переменные `*_password_var`,
указывающие на ключи `VARS/secrets.yml` (конвенция проекта, как в
`zabbix_server` и `netbox`): значение секрета остаётся только в secrets.yml
и не попадает в host_vars. Playbook подключает `VARS/secrets.yml` через
`vars_files`.

| Variable | Type | Required | Description |
| --- | --- | --- | --- |
| секрет из `grafana_admin_password_var` | string | yes | Пароль встроенного администратора, например ключ `grafana_admin_password`. Проверяется ранним `assert`; роль падает до внесения изменений, если переменная не существует. |
| секрет из `grafana_database_password_var` | string | при postgres | Пароль подключения к PostgreSQL, например ключ `grafana_db_password`. Обязателен при `grafana_database_type: "postgres"`. |
| секрет из `grafana_database_admin_password_var` | string | при postgres и manage | Пароль привилегированной учётной записи `grafana_database_admin_user` на сервере PostgreSQL, например общий ключ `db_admin_password`. Обязателен при `grafana_database_type: "postgres"` и `grafana_database_manage: true`; используется только для создания базы и роли. |

Таска, пишущая `grafana.ini`, использует `no_log: true` и `diff: false`:
секреты попадают только в файл на целевом хосте и не показываются в выводе и
diff. Пароль администратора применяется один раз - когда Grafana создаёт
учётную запись при первом старте (файл пишется до первого запуска сервиса).
Смена пароля существующего администратора ролью не выполняется; это делается
вручную через `grafana-cli admin reset-admin-password` или через UI/API.

## Handlers

- `Restart Grafana server` - `systemd restart grafana-server`. Вызывается при
  изменении `grafana.ini`, файлов провизионирования (`datasources.yaml`,
  `dashboards.yaml`) и при установке плагинов. Копии JSON-дашбордов перезапуск
  не вызывают: провайдер перечитывает каталог каждые
  `updateIntervalSeconds`.

## Использование

```yaml
---
- name: Configure Grafana
  hosts: grafana
  become: true
  vars_files:
    - "../VARS/secrets.yml"
  roles:
    - role: grafana
      vars:
        grafana_admin_password_var: "grafana_admin_password"
        grafana_database_host: "postgresql.example.internal"
        grafana_database_password_var: "grafana_db_password"
        grafana_database_admin_password_var: "db_admin_password"
        grafana_domain: "grafana.example.internal"
        grafana_root_url: "http://grafana.example.internal:3000/"
        grafana_datasources:
          - name: "Prometheus"
            type: "prometheus"
            url: "http://prometheus.example.internal:9090"
            is_default: true
          - name: "Loki"
            type: "loki"
            url: "http://loki.example.internal:3100"
          - name: "Zabbix"
            type: "alexanderzobnin-zabbix-datasource"
            url: "http://zabbix.example.internal/api_jsonrpc.php"
```

## Check mode и diff mode

Роль поддерживает запуск с `--check --diff` со следующими ограничениями:

- `diff` для `grafana.ini` отключён (`diff: false`) - файл содержит секрет.
- На первом `--check`-прогоне установка пакета `grafana` пропускается:
  спрогнозированный репозиторий ещё не индексируется APT. Когда репозиторий
  уже существует, проверка пакета выполняется как обычно.
- `grafana-cli plugins ls` выполняется и в check mode (`check_mode: false`,
  read-only), но только если бинарник уже существует. Установка плагинов -
  `ansible.builtin.command` - в check mode пропускается самим Ansible.
- `--tags debug` и `--skip-tags debug` безопасны: сводка проверяет
  `result is defined` для каждого register.

## Зависимости

- Коллекция `community.postgresql` (модули `postgresql_user` и
  `postgresql_db` для создания базы и роли); остальные модули -
  `ansible.builtin`.

## Примечания

- При `grafana_database_manage: true` (по умолчанию) роль сама создаёт свою
  базу и роль в PostgreSQL - по конвенции проекта приложение владеет своей
  схемой. Для этого нужен пароль привилегированной учётной записи
  `grafana_database_admin_user`, названный в
  `grafana_database_admin_password_var` (например, общий секрет
  `db_admin_password`). При `grafana_database_manage: false` роль ожидает,
  что база и роль уже созданы внешним способом.
- Перевод существующего инстанса с sqlite3 на PostgreSQL не переносит данные:
  при смене `grafana_database_type` Grafana стартует с пустой базой и
  накатывает схему сама; миграция содержимого - ручная операция вне роли.
- Ключ репозитория хранится как armored `.asc`: APT принимает armored-keyring
  через `signed-by` только с расширением `.asc`, поэтому отдельный шаг
  `gpg --dearmor` не нужен - как и в ролях `docker` и `yandex_disk`.
- SSO/OIDC через Keycloak - запланированный второй этап; в этой роли
  намеренно используется только локальный администратор.
- Список `grafana_datasources` пуст по умолчанию: конкретные адреса
  Prometheus/Loki/Zabbix - значения приватного репозитория.
- JSON-дашборды для `grafana_dashboards` кладутся в каталог `files/` этой
  роли; абсолютные пути в списке копируются как заданы.
