# mosquitto

Роль устанавливает MQTT-брокер Mosquitto из пакетов Debian и настраивает его
целиком через drop-in `/etc/mosquitto/conf.d/90-ansible.conf`: listener'ы,
аутентификацию и авторизацию. Это центральный брокер умного дома
(`172.25.40.155`): его клиенты — spruthub, Home Assistant, Frigate и
WirenBoard 7.

Целевое состояние по плану защиты A-35: TLS-listener 8883 и у каждого клиента
собственные учётные данные и ACL; plaintext 1883 выключается только после
миграции всех клиентов. Роль держит 1883 включённым по умолчанию и делает TLS
опциональным и полностью декларативным.

## Что делает

- Проверяет платформу Debian, порты и то, что включён хотя бы один listener.
- Требует хотя бы один аккаунт, когда `mosquitto_allow_anonymous: false`, и
  проверяет, что каждый `password_var` разрешается в переменную из
  `VARS/secrets.yml` — до любого изменения хоста.
- При `mosquitto_tls_enabled: true` проверяет, что `cafile`/`certfile`/`keyfile`
  заданы и существуют на хосте (сертификаты доставляет внешний CA-процесс).
- Устанавливает пакет `mosquitto`.
- Пишет drop-in `/etc/mosquitto/conf.d/90-ansible.conf`: listener'ы,
  `allow_anonymous`, `password_file`, `acl_file`, `mosquitto_extra_settings`.
- Пишет `/etc/mosquitto/acl` из `mosquitto_acl_entries` (или удаляет файл, когда
  список пуст).
- Пишет `/etc/mosquitto/passwd.defs` (plaintext `имя:пароль`, `0600 root`) и при
  его изменении пересобирает `/etc/mosquitto/passwd`: копия заготовки +
  `mosquitto_passwd -U` хэширует записи на месте. Двухшаговая сборка делает
  прогон идемпотентным — сами пароли на хосте хранятся хэшированными.
- Управляет сервисом `mosquitto`; изменения конфигурации, ACL и паролей
  перезапускают его через handler.

## Требования

- Debian (целевая платформа — Debian 13), `become: true`.
- Собранные facts: `ansible_facts.os_family`.
- При `mosquitto_tls_enabled: true` — файлы сертификатов уже на хосте.
- Пароли аккаунтов — в `VARS/secrets.yml`, подключённом playbook'ом через
  `vars_files`; роль сама этот файл не читает.

## Изменяемые ресурсы

- Packages: `mosquitto`.
- Files: `/etc/mosquitto/conf.d/90-ansible.conf`, `/etc/mosquitto/acl`,
  `/etc/mosquitto/passwd.defs`, `/etc/mosquitto/passwd`.
- Services: `mosquitto`.
- Users/groups: none (системного пользователя создаёт пакет).
- Firewall/API objects: none.

## Переменные

| Variable | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `mosquitto_debug_mode` | boolean | no | `false` | Сводка после значимых изменений. |
| `mosquitto_packages` | list | no | `["mosquitto"]` | Устанавливаемые пакеты. |
| `mosquitto_managed_config` | string | no | `"/etc/mosquitto/conf.d/90-ansible.conf"` | Drop-in, которым владеет роль. |
| `mosquitto_password_definitions` | string | no | `"/etc/mosquitto/passwd.defs"` | Plaintext-заготовка файла паролей (`0600 root`). |
| `mosquitto_password_file` | string | no | `"/etc/mosquitto/passwd"` | Хэшированный `password_file` брокера. |
| `mosquitto_acl_file` | string | no | `"/etc/mosquitto/acl"` | `acl_file` брокера. |
| `mosquitto_listener_enabled` | boolean | no | `true` | Обычный listener (A-35: off после миграции клиентов). |
| `mosquitto_port` | integer | no | `1883` | Порт listener'а без шифрования. |
| `mosquitto_listener_address` | string/null | no | `null` | Адрес привязки plaintext-listener'а. |
| `mosquitto_tls_enabled` | boolean | no | `false` | Включить TLS-listener. |
| `mosquitto_tls_port` | integer | no | `8883` | Порт TLS-listener'а. |
| `mosquitto_tls_cafile` | string/null | cond. | `null` | CA-сертификат на хосте; обязателен при TLS. |
| `mosquitto_tls_certfile` | string/null | cond. | `null` | Сертификат брокера; обязателен при TLS. |
| `mosquitto_tls_keyfile` | string/null | cond. | `null` | Закрытый ключ брокера; обязателен при TLS. |
| `mosquitto_tls_require_certificate` | boolean | no | `false` | Требовать клиентский сертификат на TLS-listener'е. |
| `mosquitto_allow_anonymous` | boolean | no | `false` | Разрешить подключения без учётных данных. |
| `mosquitto_users` | list | cond. | `[]` | Аккаунты `{name, password_var}`; обязателен непустой список при `allow_anonymous: false`. |
| `mosquitto_acl_entries` | list | no | `[]` | ACL `{name, topics}`; topic — dict `{access, topic}` или строка. |
| `mosquitto_extra_settings` | dict | no | `{}` | Дополнительные директивы `имя значение` в drop-in. |
| `mosquitto_service_name` | string | no | `"mosquitto"` | Имя systemd-сервиса. |
| `mosquitto_service_state` | string | no | `"started"` | Устойчивое состояние: `started`/`stopped`. |
| `mosquitto_service_enabled` | boolean | no | `true` | Запуск при загрузке. |

Секреты не объявляются в defaults. Каждый `password_var` — это *имя* переменной
(например `vault_mosquitto_spruthub_password`) из `VARS/secrets.yml`; роль
разрешает его через `lookup('ansible.builtin.vars', ...)` во время прогона.

## Использование

```yaml
---
- name: Run the central MQTT broker
  hosts: mosquitto
  become: true
  vars_files:
    - ../VARS/secrets.yml
  roles:
    - role: mosquitto
      vars:
        mosquitto_users:
          - name: "spruthub"
            password_var: "vault_mosquitto_spruthub_password"
          - name: "homeassistant"
            password_var: "vault_mosquitto_homeassistant_password"
          - name: "wirenboard"
            password_var: "vault_mosquitto_wirenboard_password"
        mosquitto_acl_entries:
          - name: "wirenboard"
            topics:
              - { access: "readwrite", topic: "devices/#" }
        mosquitto_tls_enabled: false
```

## Check mode и diff mode

Роль поддерживает запуск:

```bash
ansible-playbook playbook.yml --check --diff
```

Ограничения:

- `stat` сертификатов выполняется и в check mode (`check_mode: false`), это
  read-only проверка.
- Задача `mosquitto_passwd -U` (command) в check mode пропускается; её
  изменение предсказывает шаблон `passwd.defs`.
- Файлы с паролями помечены `no_log: true` и `diff: false` — их содержимое не
  показывается ни в выводе, ни в diff.

## Handlers

- `Restart Mosquitto` — перезапуск сервиса. SIGHUP перечитывает лишь часть
  конфигурации; изменения listener'ов, паролей и TLS применяются только через
  перезапуск.

## Tags

- `debug` — итоговая сводка при `mosquitto_debug_mode: true`.

## Зависимости

- None. Используются только модули `ansible.builtin`.

## Примечания

- `passwd.defs` содержит открытые пароли и остаётся на хосте с `0600 root:root`
  — это необходимая ступень идемпотентной сборки; брокер читает только
  хэшированный `passwd`.
- Удаление имени из `mosquitto_users` пересобирает файл паролей без него —
  аккаунт отзывается декларативно.
- ACL действует только на аутентифицированных клиентов; при
  `allow_anonymous: true` анонимные клиенты не ограничены `user`-записями.
- Директивы аутентификации глобальны (без `per_listener_settings`) и действуют
  на оба listener'а — и 1883, и 8883 требуют одни и те же учётные данные.
