# grafana

Роль устанавливает Grafana на Debian-хост из официального APT-репозитория
`apt.grafana.com`, пишет `/etc/grafana/grafana.ini` из шаблона (HTTP-порт,
domain/root_url, встроенный администратор), декларативно провизионирует
источники данных и дашборды и ставит плагины через `grafana-cli`. Локальный
администратор получает пароль из внешнего секрета; SSO через Keycloak -
осознанно следующий этап и в эту роль не входит.

## Что делает

- Проверяет платформу Debian, структуру входных списков и наличие секрета
  `vault_grafana_admin_password` одним ранним `ansible.builtin.assert` до
  любых изменений.
- Скачивает armored-ключ подписи в `/etc/apt/keyrings/grafana.asc` и
  подключает репозиторий
  `deb [arch=amd64 signed-by=...] https://apt.grafana.com stable main`.
- Устанавливает пакет `grafana` и пишет `grafana.ini` из шаблона. Файл
  содержит пароль администратора, поэтому таска использует `no_log: true` и
  `diff: false`.
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
- Секрет `vault_grafana_admin_password`, подключённый playbook'ом (см.
  раздел "Секреты").

## Изменяемые ресурсы

- Packages: `ca-certificates`, `python3-apt`, пакеты из `grafana_packages`
  (`grafana`).
- Files: `/etc/apt/keyrings/grafana.asc`,
  `/etc/apt/sources.list.d/grafana.list`, `/etc/grafana/grafana.ini`,
  `/etc/grafana/provisioning/datasources/datasources.yaml`,
  `/etc/grafana/provisioning/dashboards/dashboards.yaml`, каталог
  `/var/lib/grafana/dashboards` и JSON-файлы дашбордов в нём, плагины в
  `/var/lib/grafana/plugins`.
- Services: `grafana-server`.
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
| `grafana_datasources_config_path` | string | no | `"/etc/grafana/provisioning/datasources/datasources.yaml"` | Путь файла провизионирования источников. |
| `grafana_datasources` | list | no | `[]` | Источники данных: у каждого обязательны `name`, `type`, `url`; опциональны `access` (по умолчанию `"proxy"`) и `is_default` (по умолчанию `false`). |
| `grafana_dashboards_provider_path` | string | no | `"/etc/grafana/provisioning/dashboards/dashboards.yaml"` | Путь файла провайдера дашбордов. |
| `grafana_dashboards_path` | string | no | `"/var/lib/grafana/dashboards"` | Каталог, сканируемый провайдером. |
| `grafana_dashboards` | list | no | `[]` | JSON-файлы дашбордов; относительные имена ищутся в `files/` роли. |
| `grafana_plugins` | list | no | `["alexanderzobnin-zabbix-app"]` | ID плагинов для `grafana-cli plugins install`. |
| `grafana_service_name` | string | no | `"grafana-server"` | Имя systemd-юнита. |
| `grafana_service_state` | string | no | `"started"` | Устойчивое состояние сервиса (`started`/`stopped`). |
| `grafana_service_enabled` | boolean | no | `true` | Включать сервис при загрузке. |

## Секреты

| Variable | Type | Required | Description |
| --- | --- | --- | --- |
| `vault_grafana_admin_password` | string | yes | Пароль встроенного администратора. Приходит из `VARS/secrets.yml`, который playbook подключает через `vars_files`; в `defaults/main.yml` не объявляется. Проверяется ранним `assert`, и роль падает до внесения изменений, если секрет не задан. |

Таска, пишущая `grafana.ini`, использует `no_log: true` и `diff: false`:
секрет попадает только в файл на целевом хосте и не показывается в выводе и
diff. Значение применяется один раз - когда Grafana создаёт учётную запись
при первом старте (файл пишется до первого запуска сервиса). Смена пароля
существующего администратора ролью не выполняется; это делается вручную через
`grafana-cli admin reset-admin-password` или через UI/API.

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

- None. Используются только модули `ansible.builtin`.

## Примечания

- Ключ репозитория хранится как armored `.asc`: APT принимает armored-keyring
  через `signed-by` только с расширением `.asc`, поэтому отдельный шаг
  `gpg --dearmor` не нужен - как и в ролях `docker` и `yandex_disk`.
- SSO/OIDC через Keycloak - запланированный второй этап; в этой роли
  намеренно используется только локальный администратор.
- Список `grafana_datasources` пуст по умолчанию: конкретные адреса
  Prometheus/Loki/Zabbix - значения приватного репозитория.
- JSON-дашборды для `grafana_dashboards` кладутся в каталог `files/` этой
  роли; абсолютные пути в списке копируются как заданы.
