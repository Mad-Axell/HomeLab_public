# promtail

Роль устанавливает Promtail на Debian из официального APT-репозитория Grafana
(`apt.grafana.com`) и настраивает его как агент сбора логов: журнал systemd и
файлы `/var/log/*.log` отправляются в Loki по push API. Пакета `promtail` в
репозиториях Debian нет, поэтому источником установки служит репозиторий
вендора.

Promtail объявлен EOL в пользу Grafana Alloy (Grafana прекратила поддержку в
марте 2026), но остаётся простым классическим агентом Loki. Проект осознанно
сохраняет promtail как выбранный механизм доставки логов; переход на Alloy —
отдельное архитектурное решение.

## Что делает

- Проверяет платформу Debian и обязательный `promtail_loki_url` до любого
  изменения.
- Устанавливает `ca-certificates` и `python3-apt`.
- Скачивает ASCII-armored ключ подписи Grafana в
  `/etc/apt/keyrings/grafana.asc` без `apt-key` и регистрирует
  `deb [arch=amd64 signed-by=...] https://apt.grafana.com stable main` в
  `/etc/apt/sources.list.d/grafana.list`.
- Устанавливает пакет `promtail` (postinstall создаёт пользователя `promtail`
  и юнит `promtail.service`).
- Создаёт каталог `/var/log/journal` с владельцем `root:systemd-journal` и
  mode `2755`, если его нет, и каталог состояния `/var/lib/promtail` с
  владельцем `promtail` для файла позиций.
- Добавляет пользователя `promtail` в группы `adm` и `systemd-journal`: без
  них агент не может прочитать ни файлы `/var/log`, ни журнал. Пакет сам этих
  прав не выдаёт.
- Полностью заменяет `/etc/promtail/config.yml` шаблоном роли: positions
  файл, `clients.url` из `promtail_loki_url`, задание `journal` для
  `/var/log/journal` с relabel `__journal__systemd_unit` -> `unit` и
  статическое задание `varlogs` для `/var/log/*.log`. Перед заменой файл
  проверяется `promtail -check-syntax`.
- Приводит сервис `promtail` к устойчивому состоянию и сразу применяет
  перезапуск через `meta: flush_handlers` — новое членство в группах
  действует только после перезапуска процесса.

## Требования

- Debian (целевая платформа — Debian 13), `become: true`.
- Собранные facts: `ansible_facts.os_family`, `ansible_facts.nodename`.
- Сетевой доступ к `https://apt.grafana.com` и к endpoint'у из
  `promtail_loki_url`.

## Изменяемые ресурсы

- Packages: `promtail_prerequisite_packages`, `promtail_packages`.
- Files: `/etc/apt/keyrings/grafana.asc`,
  `/etc/apt/sources.list.d/grafana.list`, `/etc/promtail/config.yml`,
  каталоги `/var/log/journal` и `dirname promtail_positions_file`.
- Services: `promtail`.
- Users/groups: дополнительные группы `adm` и `systemd-journal` у пользователя
  `promtail` (сам пользователь создаётся postinstall пакета).
- Firewall/API objects: none.

## Переменные

| Variable | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `promtail_loki_url` | string | yes | `null` | Endpoint Loki push API, например `http://loki.example.invalid:3100/loki/api/v1/push`. |
| `promtail_repository_url` | string | no | `"https://apt.grafana.com"` | URL APT-репозитория Grafana. |
| `promtail_repository_suite` | string | no | `"stable"` | Suite репозитория Grafana. |
| `promtail_repository_component` | string | no | `"main"` | Компонент репозитория Grafana. |
| `promtail_repository_arch` | string | no | `"amd64"` | Закреплённая APT-архитектура. |
| `promtail_repository_key_url` | string | no | `"https://apt.grafana.com/gpg-full.key"` | URL ASCII-armored ключа подписи. |
| `promtail_keyring_directory` | string | no | `"/etc/apt/keyrings"` | Каталог ключа подписи. |
| `promtail_keyring_file` | string | no | `"grafana.asc"` | Имя файла ключа подписи. |
| `promtail_prerequisite_packages` | list | no | `["ca-certificates", "python3-apt"]` | Пакеты, нужные до подключения репозитория. |
| `promtail_packages` | list | no | `["promtail"]` | Пакеты из репозитория Grafana. |
| `promtail_http_listen_address` | string | no | `"0.0.0.0"` | Адрес endpoint'а метрик агента. |
| `promtail_http_listen_port` | integer | no | `9080` | Порт endpoint'а метрик агента. |
| `promtail_grpc_listen_address` | string | no | `"0.0.0.0"` | Адрес gRPC-интерфейса. |
| `promtail_grpc_listen_port` | integer | no | `0` | Порт gRPC-интерфейса; `0` отключает его. |
| `promtail_positions_file` | string | no | `"/var/lib/promtail/positions.yaml"` | Файл позиций чтения источников. |
| `promtail_journal_path` | string | no | `"/var/log/journal"` | Каталог файлов journald. |
| `promtail_journal_max_age` | string | no | `"12h"` | Глубина первого чтения журнала назад. |
| `promtail_varlog_path` | string | no | `"/var/log/*.log"` | Маска файлов задания varlogs. |
| `promtail_instance_label` | string | no | `"{{ ansible_facts.nodename }}"` | Значение метки `instance` у всех потоков. |
| `promtail_extra_scrape_configs` | list | no | `[]` | Дополнительные записи `scrape_configs`, добавляемые как есть. |
| `promtail_service_user` | string | no | `"promtail"` | Сервисная учётная запись пакета. |
| `promtail_user_groups` | list | no | `["adm", "systemd-journal"]` | Дополнительные группы для чтения источников. |
| `promtail_config_path` | string | no | `"/etc/promtail/config.yml"` | Управляемый файл конфигурации. |
| `promtail_service_name` | string | no | `"promtail"` | Имя systemd-сервиса. |
| `promtail_service_state` | string | no | `"started"` | Устойчивое состояние сервиса. |
| `promtail_service_enabled` | boolean | no | `true` | Запуск сервиса при загрузке. |
| `promtail_debug_mode` | boolean | no | `false` | Debug-вывод после значимых изменений. |

## Секреты

Роль не использует секретов и не читает `VARS/secrets.yml`. URL Loki —
несекретный обязательный вход.

## Использование

```yaml
---
- name: Install Promtail
  hosts: all
  become: true
  roles:
    - role: promtail
      vars:
        promtail_loki_url: "http://loki.example.invalid:3100/loki/api/v1/push"
```

С дополнительным файлом лога на конкретном хосте:

```yaml
promtail_extra_scrape_configs:
  - job_name: app
    static_configs:
      - targets:
          - localhost
        labels:
          job: app
          instance: "{{ ansible_facts.nodename }}"
          __path__: "/var/log/app/app.log"
```

## Check mode и diff mode

Роль поддерживает `--check --diff` частично, и это ограничение APT, а не
дефект:

- в check mode репозиторий фактически не добавляется, поэтому на чистом хосте
  задача установки `promtail_packages` сообщит об отсутствии
  пакета-кандидата; полноценный `--check` осмыслен на хосте, где репозиторий
  уже подключён прежним прогоном;
- `validate`-команда шаблона в check mode не выполняется;
- остальные задачи ведут себя в check/diff корректно.

## Зависимости

- None

## Handlers и теги

- Handlers: `Restart Promtail` вызывается при изменении
  `/etc/promtail/config.yml` и при изменении групп пользователя `promtail`.
- Tags: `debug` на итоговой debug-задаче.

## Примечания

- Если на хосте журнал временный (`Storage=volatile`/auto без
  `/var/log/journal`), задание `journal` вернёт пусто до перезапуска
  `systemd-journald`; Debian по умолчанию ведёт постоянный журнал, поэтому в
  штатной установке проблемы нет. Для временного журнала задайте
  `promtail_journal_path: "/run/log/journal"`.
- Postinstall пакета включает и перезапускает сервис на поставляемой
  конфигурации; роль заменяет её в том же прогоне и перезапускает сервис
  handler'ом.
