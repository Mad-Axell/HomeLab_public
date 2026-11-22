# node_exporter

Роль устанавливает `prometheus-node-exporter` из пакетов Debian на любой
наблюдаемый хост и управляет его аргументами через
`/etc/default/prometheus-node-exporter`. Аналог `zabbix_agent` для стека
Prometheus: сервер, настраиваемый ролью `prometheus`, опрашивает endpoint
`/metrics` на порту 9100.

## Что делает

- Устанавливает пакет `prometheus-node-exporter` из репозитория Debian.
- Рендерит `/etc/default/prometheus-node-exporter` — файл `$ARGS`, который
  поставляемый unit подставляет в `ExecStart`, — из шаблона
  `templates/prometheus-node-exporter.j2` с флагом `--web.listen-address` из
  `node_exporter_listen_address`/`node_exporter_listen_port` и дополнительными
  флагами `node_exporter_extra_args`.
- Управляет сервисом `prometheus-node-exporter`; изменение аргументов вызывает
  handler `Restart node exporter`.

## Требования

- ОС семейства Debian (роль рассчитана на Debian 13).
- `become: true` — установка пакетов, запись `/etc/default` и управление systemd.

## Изменяемые ресурсы

- Packages: `prometheus-node-exporter`.
- Files: `/etc/default/prometheus-node-exporter`.
- Services: `prometheus-node-exporter`.
- Users/groups: none.
- Firewall/API objects: none.

## Переменные

| Variable | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `node_exporter_debug_mode` | boolean | no | `false` | Показывать сводку после значимых изменений. |
| `node_exporter_packages` | list | no | `["prometheus-node-exporter"]` | Устанавливаемые пакеты. |
| `node_exporter_defaults_path` | string | no | `"/etc/default/prometheus-node-exporter"` | Environment-файл `$ARGS`, которым роль владеет целиком. |
| `node_exporter_listen_address` | string | no | `"0.0.0.0"` | Адрес прослушивания endpoint `/metrics`. |
| `node_exporter_listen_port` | integer | no | `9100` | TCP-порт endpoint `/metrics`. |
| `node_exporter_extra_args` | list | no | `[]` | Дополнительные флаги, дописываемые в `ARGS` (например `--collector.systemd`). |
| `node_exporter_service_name` | string | no | `"prometheus-node-exporter"` | Имя systemd-сервиса. |
| `node_exporter_service_state` | string | no | `"started"` | Устойчивое состояние сервиса: `started` или `stopped`. |
| `node_exporter_service_enabled` | boolean | no | `true` | Запуск сервиса при загрузке. |

Обязательных переменных без дефолта и секретов у роли нет.

## Использование

```yaml
---
- name: Install node_exporter on monitored hosts
  hosts: all
  become: true
  roles:
    - role: node_exporter
```

С нестандартным портом и дополнительными коллекторами:

```yaml
    - role: node_exporter
      vars:
        node_exporter_listen_port: 19100
        node_exporter_extra_args:
          - "--collector.systemd"
```

## Check mode и diff mode

Роль полностью поддерживает запуск:

```bash
ansible-playbook playbook.yml --check --diff
```

Секретов в `/etc/default/prometheus-node-exporter` нет, поэтому diff файла
показывается обычным образом.

## Handlers

- `Restart node exporter` — перезапуск сервиса; `ARGS` читается только при
  старте процесса, поэтому перечитывания нет. Пропускается, если
  `node_exporter_service_state` не `started`.

## Tags

- `debug` — итоговая сводка изменений при `node_exporter_debug_mode: true`.

## Зависимости

- None. Используются только модули `ansible.builtin`.

## Примечания

- Сетевой доступ с сервера Prometheus на порт `node_exporter_listen_port` —
  вне области роли (firewall настраивается отдельно).
- Адрес `0.0.0.0` слушает все IPv4-интерфейсы; для привязки к конкретному
  адресу задайте `node_exporter_listen_address`.
