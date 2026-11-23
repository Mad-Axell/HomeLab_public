# zabbix_agentless_host

Регистрирует объект хоста на сервере Zabbix для устройств, не принимающих
агент. Вся работа идёт через Zabbix API с делегированием на localhost; на само
устройство ничего не устанавливается.

Применяется для appliance вроде Home Assistant OS, где в госте нет ни SSH, ни
агента, ни SNMP. Создаваемый интерфейс имеет тип `agent` без слушателя за ним:
его единственная задача — нести IP-адрес, чтобы серверные простые проверки
(ICMP ping, `net.tcp.service`, web-сценарии) имели к чему привязаться.

## Что делает

- Проверяет `zabbix_agentless_host_api_url`,
  `zabbix_agentless_host_api_password_var` и наличие хотя бы одной группы.
- Проверяет существование переменной из
  `zabbix_agentless_host_api_password_var` (значение не выводится).
- Создаёт каждую группу из `zabbix_agentless_host_groups` при отсутствии
  (throttled).
- Регистрирует/обновляет хост с заданными группами, шаблонами, описанием,
  статусом и макросами плюс интерфейс типа `agent` на разрешённый адрес.
- Печатает краткий debug-итог при включённом `zabbix_agentless_host_debug_mode`.

## Переменные

| Variable | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `zabbix_agentless_host_debug_mode` | bool | нет | `false` | Debug-вывод. |
| `zabbix_agentless_host_api_url` | string | да | `null` | Базовый URL веб-интерфейса Zabbix. |
| `zabbix_agentless_host_api_user` | string | нет | `"Admin"` | Логин API. |
| `zabbix_agentless_host_api_password_var` | string | да | `null` | Имя переменной с паролем API (разрешается через `vars`-lookup, не выводится). |
| `zabbix_agentless_host_name` | string | нет | `inventory_hostname` | Имя объекта хоста на сервере. |
| `zabbix_agentless_host_address` | string | нет | `ansible_host` цели | Адрес опроса; по умолчанию `ansible_host` целевой записи или текущего хоста. |
| `zabbix_agentless_host_target_host` | string | нет | `null` | Запись инвентаря для объекта; `null` = `inventory_hostname`. |
| `zabbix_agentless_host_groups` | list | да | `[]` | Группы хостов; создаются при отсутствии. |
| `zabbix_agentless_host_templates` | list | нет | `[]` | Имена привязанных шаблонов (должны совпадать с сервером). |
| `zabbix_agentless_host_macros` | list | нет | `[]` | Словари `{macro, value}`; значения с окончанием `_var` разрешаются как имена переменных. |
| `zabbix_agentless_host_description` | string | нет | `""` | Описание хоста. |
| `zabbix_agentless_host_status` | bool | нет | `true` | `false` создаёт хост выключенным. |

## Пример

```yaml
- name: Register Home Assistant as an agentless host
  hosts: localhost
  gather_facts: false
  vars_files:
    - ../VARS/secrets.yml
  roles:
    - role: zabbix_agentless_host
      vars:
        zabbix_agentless_host_api_url: "http://zabbix.example"
        zabbix_agentless_host_api_password_var: "zabbix_api_password"
        zabbix_agentless_host_target_host: homeassistant
        zabbix_agentless_host_name: homeassistant
        zabbix_agentless_host_groups:
          - "Smart home"
        zabbix_agentless_host_templates:
          - "ICMP Ping"
```

## Handlers и теги

Handlers нет. Итоговая задача несёт тег `debug`.

## Check mode

Модули `community.zabbix` выполняются в check mode как обычно; роль не считать
check-mode безопасной.
