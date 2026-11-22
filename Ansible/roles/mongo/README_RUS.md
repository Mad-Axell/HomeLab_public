# mongo

Роль устанавливает документную СУБД MongoDB 9.0 на LXC `172.25.40.153`.
В Debian 13 пакета mongodb нет из-за лицензирования (SSPL), поэтому
используется вендорный APT-репозиторий `repo.mongodb.org` — поддерживаемый
апстрим-путь; suite `trixie/mongodb-org/9.0` опубликован апстримом.

`mongod.conf` не имеет механизма drop-in, поэтому роль владеет файлом целиком
— пакет не переписывает его после установки.

## Что делает

- Проверяет платформу Debian, порт, bind-адрес и типы до любого изменения.
- Отказывается открывать прослушивание вне loopback без
  `mongo_authorization: enabled` и `mongo_admin_password_var`.
- Проверяет, что `mongo_admin_password_var` и каждый `password_var` из
  `mongo_users` разрешаются в переменные из `VARS/secrets.yml`.
- Скачивает ASCII-armored ключ подписи в
  `/etc/apt/keyrings/mongodb-server-9.0.asc` и регистрирует
  `deb [arch=amd64 signed-by=...] https://repo.mongodb.org/apt/debian
  trixie/mongodb-org/9.0 main` в
  `/etc/apt/sources.list.d/mongodb-org.list`.
- Устанавливает `mongodb-org` (мета-пакет вендора) и `python3-pymongo`,
  нужный модулям `community.mongodb`.
- Пишет `/etc/mongod.conf` целиком: `storage.dbPath`, `systemLog`,
  `net.port`/`net.bindIp`, `security.authorization` при включённой
  авторизации и `mongo_extra_settings`; изменение перезапускает `mongod`
  через handler.
- Создаёт административный аккаунт `mongo_admin_user` (роль `root` в базе
  `admin`) — при первом прогоне через localhost exception MongoDB.
- Создаёт прикладных пользователей из `mongo_users` с `update_password:
  on_create` — идемпотентно при повторных прогонах.

## Требования

- Debian (целевая платформа — Debian 13), `become: true`.
- Собранные facts: `ansible_facts.os_family`.
- Сетевой доступ к `https://repo.mongodb.org` и
  `https://www.mongodb.org/static/pgp/`.
- Коллекция `community.mongodb` на контроллере (фиксируется в project-level
  `requirements.yml`).
- CPU с AVX: MongoDB ≥ 5.0 требует AVX (в проекте хосты pve-main имеют AVX —
  см. `Docs/instructions/05_unifi_wifi.md` §0.1).
- Пароли — в `VARS/secrets.yml`, подключённом playbook'ом через
  `vars_files`; роль сама этот файл не читает.

## Изменяемые ресурсы

- Packages: `mongo_prerequisite_packages`, `mongo_packages`.
- Files: `/etc/apt/keyrings/mongodb-server-9.0.asc`,
  `/etc/apt/sources.list.d/mongodb-org.list`, `/etc/mongod.conf`.
- Services: `mongod`.
- Users/groups: none на уровне ОС (пользователь `mongodb` создаётся пакетом);
  объекты БД: аккаунт администратора и пользователи из `mongo_users`.
- Firewall/API objects: none.

## Переменные

| Variable | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `mongo_debug_mode` | boolean | no | `false` | Сводка после значимых изменений. |
| `mongo_repository_url` | string | no | `"https://repo.mongodb.org/apt/debian"` | URL APT-репозитория вендора. |
| `mongo_repository_suite` | string | no | `"trixie/mongodb-org/9.0"` | Suite: выпуск Debian + серия MongoDB. |
| `mongo_repository_component` | string | no | `"main"` | Компонент репозитория. |
| `mongo_repository_arch` | string | no | `"amd64"` | Закреплённая APT-архитектура. |
| `mongo_repository_key_url` | string | no | `"https://pgp.mongodb.com/server-9.0.asc"` | URL ключа подписи серии 9.0. |
| `mongo_keyring_directory` | string | no | `"/etc/apt/keyrings"` | Каталог ключа подписи. |
| `mongo_keyring_file` | string | no | `"mongodb-server-9.0.asc"` | Имя файла ключа (.asc = ASCII-armored). |
| `mongo_prerequisite_packages` | list | no | `["ca-certificates", "python3-apt"]` | Пакеты до подключения репозитория. |
| `mongo_packages` | list | no | `["mongodb-org", "python3-pymongo"]` | Сервер и pymongo для community.mongodb. |
| `mongo_config_path` | string | no | `"/etc/mongod.conf"` | Файл конфигурации (роль владеет целиком). |
| `mongo_db_path` | string | no | `"/var/lib/mongodb"` | Каталог баз данных. |
| `mongo_log_path` | string | no | `"/var/log/mongodb/mongod.log"` | Файл журнала. |
| `mongo_bind_ip` | string | no | `"127.0.0.1"` | Адреса прослушивания, через запятую. |
| `mongo_port` | integer | no | `27017` | TCP-порт mongod. |
| `mongo_authorization` | string | no | `"disabled"` | `security.authorization`: `enabled`/`disabled`. |
| `mongo_admin_user` | string | no | `"admin"` | Имя административного аккаунта (база `admin`, роль `root`). |
| `mongo_admin_password_var` | string/null | cond. | `null` | Имя переменной с паролем администратора; обязательно при `authorization: enabled`. |
| `mongo_users` | list | no | `[]` | Пользователи `{name, password_var, database?, roles?}`. |
| `mongo_extra_settings` | dict | no | `{}` | Дополнительные YAML-ключи верхнего уровня в mongod.conf. |
| `mongo_service_name` | string | no | `"mongod"` | Имя systemd-сервиса. |
| `mongo_service_state` | string | no | `"started"` | Устойчивое состояние: `started`/`stopped`. |
| `mongo_service_enabled` | boolean | no | `true` | Запуск при загрузке. |

Секреты не объявляются в defaults. `mongo_admin_password_var` и
`password_var` — *имена* переменных (например
`vault_mongo_admin_password`), предоставляемых `VARS/secrets.yml`; роль
разрешает их через `lookup('ansible.builtin.vars', ...)` во время прогона.

## Использование

```yaml
---
- name: Run the document database
  hosts: mongo
  become: true
  vars_files:
    - ../VARS/secrets.yml
  roles:
    - role: mongo
      vars:
        mongo_bind_ip: "127.0.0.1,172.25.40.153"
        mongo_authorization: "enabled"
        mongo_admin_password_var: "vault_mongo_admin_password"
        mongo_users:
          - name: "app"
            password_var: "vault_mongo_app_password"
            database: "appdb"
            roles:
              - { db: "appdb", role: "readWrite" }
```

## Check mode и diff mode

Роль поддерживает запуск:

```bash
ansible-playbook playbook.yml --check --diff
```

Ограничения:

- `get_url` в check mode не скачивает ключ — изменение только
  предсказывается при холодном прогоне.
- `community.mongodb.mongodb_user` поддерживает check mode; задачи
  пользователей помечены `no_log: true`, поэтому сведения об аккаунтах не
  попадают в вывод.
- `mongod.conf` секретов не содержит — diff показывается обычно.

## Handlers

- `Restart MongoDB` — перезапуск `mongod`; у сервера нет перечитывания
  конфигурации, изменения bind/authorization вступают в силу только через
  перезапуск. Handler применяется через `flush_handlers` до задач создания
  пользователей.

## Tags

- `debug` — итоговая сводка при `mongo_debug_mode: true`.

## Зависимости

- Коллекция `community.mongodb` (модуль `mongodb_user`, требует
  `python3-pymongo` на хосте — устанавливается ролью). Зафиксируйте её в
  project-level `requirements.yml` корня Ansible-проекта.

## Примечания

- `update_password: on_create` означает, что смена пароля существующего
  пользователя ролью не отслеживается — пересоздайте пользователя, если
  нужна ротация.
- При первом прогоне с включённой авторизацией администратор создаётся через
  localhost exception MongoDB: локальное подключение может создать первый
  аккаунт, пока пользователей нет.
- Умолчание (`authorization: disabled`, bind `127.0.0.1`) безопасно: сервер
  недоступен из сети. Открытие сетевого интерфейса без авторизации роль
  отклоняет на этапе assert.
