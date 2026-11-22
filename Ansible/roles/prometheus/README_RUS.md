# prometheus

Роль устанавливает сервер Prometheus из пакетов Debian и целиком управляет
`/etc/prometheus/prometheus.yml`. Роль предназначена для хоста мониторинга
(`prometheus`, 172.25.40.54 по каталогу сервисов); экспортеры на опрашиваемых
хостах ставит отдельная роль `node_exporter`.

## Что делает

- Устанавливает пакет `prometheus` из репозитория Debian.
- Рендерит `/etc/prometheus/prometheus.yml` из шаблона `templates/prometheus.yml.j2`:
  секция `global` с интервалами и `scrape_configs`, который либо выводится
  дословно из `prometheus_scrape_configs`, либо генерируется — задание
  `prometheus` для самого сервера (`localhost:9090`) и задание `nodes`, цели
  которого собираются из членов `prometheus_target_groups` по `ansible_host`
  (с откатом на имя в инвентаре) на порт `prometheus_node_exporter_port`.
- Управляет сервисом `prometheus`; изменение конфигурации вызывает handler
  `Reload prometheus` (SIGHUP через `systemctl reload`).

## Требования

- ОС семейства Debian (роль рассчитана на Debian 13).
- `become: true` — установка пакетов, запись `/etc/prometheus` и управление systemd.
- Хосты из `prometheus_target_groups` существуют в инвентаре; для корректных
  целей у них задан `ansible_host`.
- На целях работает node_exporter на порту `prometheus_node_exporter_port`
  (роль `node_exporter`).

## Изменяемые ресурсы

- Packages: `prometheus`.
- Files: `/etc/prometheus/prometheus.yml` (владение целиком, `prometheus:prometheus`, `0640`).
- Services: `prometheus`.
- Users/groups: none (учётную запись `prometheus` создаёт пакет).
- Firewall/API objects: none.

## Переменные

| Variable | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `prometheus_debug_mode` | boolean | no | `false` | Показывать сводку после значимых изменений. |
| `prometheus_packages` | list | no | `["prometheus"]` | Устанавливаемые пакеты. |
| `prometheus_config_path` | string | no | `"/etc/prometheus/prometheus.yml"` | Файл конфигурации, которым роль владеет целиком. |
| `prometheus_scrape_interval` | string | no | `"15s"` | Глобальный интервал опроса. |
| `prometheus_evaluation_interval` | string | no | `"15s"` | Глобальный интервал вычисления правил. |
| `prometheus_scrape_configs` | list | no | `[]` | Полное содержимое `scrape_configs`; когда пусто, генерируются задания `prometheus` и `nodes`. |
| `prometheus_target_groups` | list | no | `["all"]` | Группы инвентаря для генерации целей задания `nodes`. |
| `prometheus_node_exporter_port` | integer | no | `9100` | Порт node_exporter на генерируемых целях. |
| `prometheus_service_name` | string | no | `"prometheus"` | Имя systemd-сервиса. |
| `prometheus_service_state` | string | no | `"started"` | Устойчивое состояние сервиса: `started` или `stopped`. |
| `prometheus_service_enabled` | boolean | no | `true` | Запуск сервиса при загрузке. |

Обязательных переменных без дефолта и секретов у роли нет. Учётные данные опроса
(`basic_auth`, `bearer_token`) можно передавать внутри
`prometheus_scrape_configs`; их значения принадлежат `VARS/secrets.yml`
приватного репозитория и подставляются playbook'ом, а не объявляются в defaults.

## Использование

```yaml
---
- name: Install the Prometheus server
  hosts: prometheus
  become: true
  roles:
    - role: prometheus
```

С заданиями опроса, описанными вручную:

```yaml
    - role: prometheus
      vars:
        prometheus_scrape_configs:
          - job_name: "nodes"
            static_configs:
              - targets: ["172.25.40.54:9100"]
```

## Check mode и diff mode

Роль поддерживает запуск:

```bash
ansible-playbook playbook.yml --check --diff
```

Ограничение: задача шаблона использует `diff: false`, потому что
`scrape_configs` может нести учётные данные опроса, поэтому содержимое
`prometheus.yml` в diff не показывается — виден только факт изменения файла.

## Handlers

- `Reload prometheus` — `systemctl reload prometheus` (SIGHUP), вызывается при
  изменении `prometheus.yml`; пропускается, если `prometheus_service_state` не
  `started`.

## Tags

- `debug` — итоговая сводка изменений при `prometheus_debug_mode: true`.

## Зависимости

- None. Используются только модули `ansible.builtin`; роль `node_exporter`
  отвечает за экспортеры на опрашиваемых хостах.

## Примечания

- `/etc/default/prometheus` роль не трогает: Debian пропатчил умолчания бинаря
  (конфиг `/etc/prometheus/prometheus.yml`, хранилище
  `/var/lib/prometheus/metrics2`), поэтому `ARGS` пакета остаётся пустым. Адрес
  web-интерфейса (по умолчанию `0.0.0.0:9090`), retention и прочие стартовые
  флаги задаются через `ARGS` в `/etc/default/prometheus` и лежат вне области
  этой роли.
- Цели генерируемого задания получают стандартную метку `instance` вида
  `адрес:порт`; имя хоста в инвентаре в метки не переносится.
