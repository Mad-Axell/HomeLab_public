# keycloak

Устанавливает сервер Keycloak из апстримного tar-архива на Debian 13 LXC
(в проекте — 172.25.40.42, LXC 402): Java-окружение, системная учётная запись,
версионированное дерево `/opt/keycloak-<версия>` с симлинком `/opt/keycloak`,
`conf/keycloak.conf` для внешнего PostgreSQL и работы за обратным прокси
Traefik, systemd-юнит и начальный администратор через переменные окружения
`KC_BOOTSTRAP_ADMIN_*`. По умолчанию роль сама создаёт свою базу и роль в
PostgreSQL (`keycloak_manage_database`), а секреты передаются по имени
переменной через `*_password_var`. Результат — работающий Keycloak по HTTP
на внутреннем порту 8080, готовый терминироваться Traefik по
`https://keycloak.dragons-nest.home.arpa`.

## Что делает

- Проверяет платформу Debian, обязательные входы (`keycloak_db_host`,
  `keycloak_hostname`, `keycloak_db_password_var`,
  `keycloak_admin_password_var`, а при `keycloak_manage_database` ещё и
  `keycloak_db_admin_password_var`) ранним `ansible.builtin.assert`, затем
  отдельной проверкой убеждается, что названные секреты существуют — всё до
  любых изменений.
- Ставит Java-пакет `keycloak_java_package` (по умолчанию
  `default-jre-headless`, в Debian 13 — OpenJDK 21) и пакеты из
  `keycloak_database_packages` (`python3-psycopg2`), нужные модулям
  `community.postgresql` на целевом хосте.
- При `keycloak_manage_database: true` создаёт роль PostgreSQL
  `keycloak_db_user` (LOGIN, пароль из `keycloak_db_password_var`) и базу
  `keycloak_db_name` с владельцем `keycloak_db_user`; подключение выполняется
  привилегированной учётной записью `keycloak_db_admin_user`. Обе таски идут
  с `no_log: true`.
- Создаёт системные группу и пользователя `keycloak`.
- Скачивает `keycloak-<версия>.tar.gz` и распаковывает в `/opt`; `/opt/keycloak`
  — симлинк на версионированный каталог, поэтому обновление и откат сводятся к
  смене одной ссылки.
- Рендерит `conf/keycloak.conf`: `db=postgres`, `db-url` из
  `keycloak_db_host`/`keycloak_db_port`/`keycloak_db_name`,
  `hostname`, `hostname-strict`, `http-enabled`, `http-port`,
  `proxy-headers`, плюс `keycloak_extra_options`.
- Пишет `/etc/keycloak/keycloak.env` с секретами (`KC_DB_PASSWORD`,
  `KC_BOOTSTRAP_ADMIN_USERNAME`, `KC_BOOTSTRAP_ADMIN_PASSWORD`), права
  `0640 root:keycloak`; значения разрешаются через `lookup` по именам из
  `*_password_var`, задача выполняется с `no_log: true` и `diff: false`.
- Ставит systemd-юнит `keycloak.service` (`kc.sh start --optimized`) и после
  смены выпуска или конфигурации выполняет `kc.sh build`, чтобы `--optimized`
  стартовал на актуальной сборке.
- Запускает и включает сервис; перезапуск при изменении конфигурации, окружения
  или юнита выполняет handler `Restart Keycloak`.

## Требования

- Целевая ОС: Debian 13 (проверяется `ansible_facts.os_family == 'Debian'`).
- Права: `become: true`; сборка выполняется от `become_user: keycloak`.
- Внешний PostgreSQL: в проекте это хост `postgresql` (172.25.40.151). При
  `keycloak_manage_database: true` (по умолчанию) роль создаёт базу и роль
  сама от имени `keycloak_db_admin_user`; при `false` ожидает их уже
  созданными.
- `VARS/secrets.yml`, подключённый playbook'ом через `vars_files`, — роль сама
  его не загружает.
- Доступ целевого хоста к `keycloak_download_url` (по умолчанию github.com) —
  архив скачивается на целевом хосте.
- Секреты, названные в `keycloak_db_password_var`,
  `keycloak_admin_password_var` и (при управлении базой)
  `keycloak_db_admin_password_var`, обязательны и проверяются ранними
  `ansible.builtin.assert`.

## Изменяемые ресурсы

- Packages: пакет из `keycloak_java_package` (`default-jre-headless`) и
  `python3-psycopg2` из `keycloak_database_packages`.
- Files: `/tmp/keycloak-<версия>.tar.gz`, `/opt/keycloak-<версия>/`,
  симлинк `/opt/keycloak`, `/opt/keycloak/conf/keycloak.conf`,
  `/etc/keycloak/keycloak.env`, `/etc/systemd/system/keycloak.service`.
- Services: `keycloak.service`.
- Users/groups: `keycloak` (system, `/usr/sbin/nologin`).
- Database objects: при `keycloak_manage_database: true` роль PostgreSQL
  `keycloak_db_user` и база `keycloak_db_name`.

## Переменные

| Variable | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `keycloak_debug_mode` | boolean | no | `false` | Итог изменений в debug-выводе. |
| `keycloak_java_package` | string | no | `"default-jre-headless"` | Java-пакет; для пина — `openjdk-21-jre-headless`. |
| `keycloak_version` | string | no | `"26.8.2"` | Устанавливаемая версия Keycloak. |
| `keycloak_download_url` | string | no | URL GitHub releases | URL tar-архива выпуска. |
| `keycloak_download_checksum` | string или null | no | `null` | Проверка архива в формате get_url, напр. `"sha256:<hex>"`; `null` пропускает параметр. |
| `keycloak_archive_path` | string | no | `"/tmp/keycloak-{{ keycloak_version }}.tar.gz"` | Путь скачанного архива. |
| `keycloak_release_dir` | string | no | `"/opt/keycloak-{{ keycloak_version }}"` | Внутреннее: каталог распакованного выпуска. |
| `keycloak_install_root` | string | no | `"/opt/keycloak"` | Симлинк на активный выпуск. |
| `keycloak_system_user` | string | no | `"keycloak"` | Системный пользователь сервиса. |
| `keycloak_system_group` | string | no | `"keycloak"` | Основная группа сервиса. |
| `keycloak_db_host` | string | yes | `null` | Адрес PostgreSQL; без дефолта, проверяется assert. |
| `keycloak_db_port` | integer | no | `5432` | Порт PostgreSQL. |
| `keycloak_db_name` | string | no | `"keycloak"` | База Keycloak; создаётся ролью при `keycloak_manage_database: true`. |
| `keycloak_db_user` | string | no | `"keycloak"` | Логин Keycloak; создаётся ролью при `keycloak_manage_database: true`. |
| `keycloak_db_password_var` | string или null | yes | `null` | Имя переменной с паролем к базе в `VARS/secrets.yml`; попадает в `keycloak.env` как `KC_DB_PASSWORD`. |
| `keycloak_manage_database` | boolean | no | `true` | Создавать базу и её роль до первого запуска; при `false` ожидаются готовые объекты. |
| `keycloak_db_admin_user` | string | no | `"postgres"` | Привилегированная учётная запись, используемая только для создания базы и роли. |
| `keycloak_db_admin_password_var` | string или null | при manage | `null` | Имя переменной с привилегированным паролем в `VARS/secrets.yml`; обязательно при `keycloak_manage_database: true`. |
| `keycloak_database_packages` | list | no | `["python3-psycopg2"]` | Внутреннее: пакеты для модулей `community.postgresql` на целевом хосте. |
| `keycloak_hostname` | string | yes | `null` | Публичный базовый URL, напр. `"https://keycloak.dragons-nest.home.arpa"`; проверяется assert. |
| `keycloak_hostname_strict` | boolean | no | `true` | `hostname-strict` в hostname v2. |
| `keycloak_http_enabled` | boolean | no | `true` | HTTP-слушатель; true за Traefik. |
| `keycloak_http_port` | integer | no | `8080` | Порт HTTP-слушателя. |
| `keycloak_proxy_headers` | string | no | `"xforwarded"` | Доверенные forwarded-заголовки прокси. |
| `keycloak_extra_options` | dict | no | `{}` | Дополнительные пары `option=value` в keycloak.conf. |
| `keycloak_admin_user` | string | no | `"admin"` | Имя bootstrap-администратора. |
| `keycloak_admin_password_var` | string или null | yes | `null` | Имя переменной с паролем bootstrap-администратора в `VARS/secrets.yml`; попадает в `keycloak.env` как `KC_BOOTSTRAP_ADMIN_PASSWORD`. |
| `keycloak_env_file` | string | no | `"/etc/keycloak/keycloak.env"` | Файл секретного окружения юнита. |
| `keycloak_service_name` | string | no | `"keycloak"` | Имя systemd-юнита. |
| `keycloak_service_state` | string | no | `"started"` | Устойчивое состояние сервиса: `started` или `stopped`. |
| `keycloak_service_enabled` | boolean | no | `true` | Запуск сервиса при загрузке. |

## Секреты

Секреты задаются не прямыми именами, а через переменные `*_password_var`,
указывающие на ключи `VARS/secrets.yml` (конвенция проекта, как в
`zabbix_server` и `netbox`): значение секрета остаётся только в secrets.yml
и не попадает в host_vars. Playbook подключает `VARS/secrets.yml` через
`vars_files`; в `defaults/main.yml` объявлены только имена переменных.
Наличие имён проверяет ранний `ansible.builtin.assert`, а существование
самих секретов — отдельная проверка `Validate the Keycloak secrets`, обе до
первого изменения системы.

| Variable | Type | Required | Назначение |
| --- | --- | --- | --- |
| секрет из `keycloak_db_password_var` | string | yes | Пароль `keycloak_db_user`, например ключ `keycloak_db_password`; попадает в `keycloak.env` как `KC_DB_PASSWORD`. |
| секрет из `keycloak_admin_password_var` | string | yes | Пароль bootstrap-администратора, например ключ `keycloak_admin_password`; `KC_BOOTSTRAP_ADMIN_PASSWORD`. |
| секрет из `keycloak_db_admin_password_var` | string | при manage | Пароль привилегированной учётной записи `keycloak_db_admin_user` на сервере PostgreSQL, например общий ключ `db_admin_password`. Обязателен при `keycloak_manage_database: true`; используется только для создания базы и роли. |

Файл `keycloak.env` — единственное место, где роль материализует секреты; его
задача выполняется с `no_log: true` и `diff: false`. `keycloak.conf` секретов
не содержит.

## Использование

```yaml
---
- name: Install Keycloak
  hosts: keycloak
  become: true
  vars_files:
    - ../VARS/secrets.yml
  roles:
    - role: keycloak
      vars:
        keycloak_db_host: "172.25.40.151"
        keycloak_db_password_var: "keycloak_db_password"
        keycloak_db_admin_password_var: "db_admin_password"
        keycloak_admin_password_var: "keycloak_admin_password"
        keycloak_hostname: "https://keycloak.dragons-nest.home.arpa"
```

## Handlers

- `Restart Keycloak` — уведомляется задачами `keycloak.conf`, `keycloak.env` и
  юнита.

## Tags

- `debug` — итоговая debug-задача при `keycloak_debug_mode: true`.

## Templates

- `keycloak.conf.j2` → `/opt/keycloak/conf/keycloak.conf`
- `keycloak.service.j2` → `/etc/systemd/system/keycloak.service`
- `keycloak.env.j2` → `/etc/keycloak/keycloak.env` (секреты)

## Check mode и diff mode

Роль поддерживает `--check --diff`. Ограничения:

- `kc.sh build` — задача `ansible.builtin.command`, в check mode не выполняется
  (она и так идёт только после изменения выпуска или конфигурации);
  соответственно фактическая сборка прогнозируется, но не выполняется.
- Запуск/перезапуск сервиса в check mode не происходит.
- `keycloak.env` никогда не показывает diff (`diff: false`) — это ожидаемо, а
  не ограничение.

## Зависимости

- Коллекция `community.postgresql` (модули `postgresql_user` и
  `postgresql_db` для создания базы и роли); остальные модули —
  `ansible.builtin`. Внешние: PostgreSQL, `VARS/secrets.yml`.

## Примечания

- **Вне области роли:** создание realm `dragons-nest`, политика MFA/OTP и
  OIDC-клиент для Grafana — это фаза 2 после установки (по плану
  `PLAN_observability.md`, этап после Traefik).
- При `keycloak_manage_database: true` (по умолчанию) роль сама создаёт свою
  базу и роль в PostgreSQL — по конвенции проекта приложение владеет своей
  схемой. Для этого нужен пароль привилегированной учётной записи
  `keycloak_db_admin_user`, названный в `keycloak_db_admin_password_var`
  (например, общий секрет `db_admin_password`). При
  `keycloak_manage_database: false` роль ожидает, что база и роль уже
  созданы внешним способом.
- Bootstrap-администратор через `KC_BOOTSTRAP_ADMIN_*` создаётся при первом
  старте, когда в realm master ещё нет администратора; после этого заведите
  постоянную учётную запись администратора в консоли.
- Приложение рассчитано на работу за Traefik: `http-enabled=true`,
  `proxy-headers=xforwarded`, `keycloak_hostname` — внешнее HTTPS-имя.
- Обновление версии: поднять `keycloak_version` — скачается новый архив,
  распакуется рядом, симлинк переключится, выполнится `kc.sh build`, сервис
  перезапустится handler'ом.
