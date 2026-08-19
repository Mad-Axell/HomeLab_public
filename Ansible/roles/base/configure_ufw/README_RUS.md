# configure_ufw

Роль устанавливает, настраивает и включает UFW на Debian/Ubuntu. Перед включением она применяет заданные политики и явно переданный список правил.

## Что делает

- Устанавливает пакет `ufw`.
- Устанавливает политики по умолчанию и уровень журналирования.
- Применяет правила и включает UFW.

## Требования

- Debian или Ubuntu.
- `become: true`.
- Коллекция `community.general`, зафиксированная в project-level `requirements.yml`.

## Изменяемые ресурсы

- Packages: `ufw`.
- Files: файлы конфигурации UFW, управляемые модулем UFW.
- Services: UFW.
- Users/groups: none.
- Firewall/API objects: политики и правила UFW.

## Переменные

| Variable | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `configure_ufw_debug_mode` | boolean | no | `false` | Показывает факт изменения конфигурации. |
| `configure_ufw_default_incoming_policy` | string | no | `"deny"` | Входящая политика по умолчанию. |
| `configure_ufw_default_outgoing_policy` | string | no | `"allow"` | Исходящая политика по умолчанию. |
| `configure_ufw_logging` | string | no | `"low"` | Уровень журналирования UFW. |
| `configure_ufw_rules` | list | yes | `null` | Правила с `rule`, `port`, `proto` и необязательными `from_ip`, `comment`. |

## Использование

```yaml
---
- name: Configure UFW
  hosts: debian
  become: true
  roles:
    - role: base/configure_ufw
      vars:
        configure_ufw_rules:
          - rule: "allow"
            port: "22"
            proto: "tcp"
            from_ip: "192.168.1.0/24"
            comment: "SSH from LAN"
```

## Check mode и diff mode

Пакет и правила поддерживают `--check --diff` в пределах возможностей модуля `community.general.ufw`. Включение файрвола меняет состояние хоста и должно запускаться с правилами, сохраняющими административный доступ.

## Зависимости

- `community.general`

## Примечания

- `configure_ufw_rules` намеренно не имеет рабочего значения по умолчанию: роль прекращает работу до изменений, если правила не объявлены.
