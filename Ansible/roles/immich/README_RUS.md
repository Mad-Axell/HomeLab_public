# immich

Эта роль разворачивает Immich (фотобиблиотека с распознаванием лиц и объектов
на машинном обучении) как проект Docker Compose v2 на целевом хосте с уже
установленным Docker — в этом проекте хост `immich` (172.25.40.92, LXC 422).
Установка на голый металл апстримом не поддерживается;
поддерживаемый апстримом путь — Docker Compose, он же проектная конвенция для
сервисов, живущих только в контейнере (`uptime`, `frigate`). Стек состоит из
контейнеров `immich-server` и `immich-machine-learning`, получающих
конфигурацию из файла `.env`. Роль использует внешний PostgreSQL (в проекте
172.25.40.151) и внешний Redis (172.25.40.154) вместо бандловых
compose-контейнеров, как описано в каталоге Docs. По умолчанию роль сама
создаёт базу, роль и нужные расширения (`immich_manage_database`), а секреты
передаются именем переменной через `*_password_var`.

## Что делает

- Проверяет платформу Debian и обязательные входы (`immich_db_host`,
  `immich_redis_host`, `immich_db_password_var`, плюс
  `immich_db_admin_password_var` при включённом `immich_manage_database`)
  ранним `ansible.builtin.assert`, затем отдельной проверкой убеждается, что
  названные секреты существуют — всё до первого изменения.
- Устанавливает `python3-psycopg2` (`immich_database_packages`), нужный
  модулям `community.postgresql` на целевом хосте.
- При `immich_manage_database: true` создаёт роль PostgreSQL
  `immich_db_user` (LOGIN, пароль из `immich_db_password_var`), базу
  `immich_db_name` с владельцем `immich_db_user` и расширения из
  `immich_db_extensions` (`vchord`, `earthdistance`, с `cascade`, так что
  pgvector подтягивается для VectorChord). Подключение выполняется
  привилегированной учётной записью `immich_db_admin_user`; все три задачи
  работают с `no_log: true`.
- Создаёт каталог проекта Compose `immich_project_directory`, каталог
  библиотеки `immich_upload_dir` и кэш моделей `immich_ml_cache_dir`.
- Отрисовывает `compose.yml` (`Docker_Compose_Immich.j2`): `immich-server`
  публикует `immich_web_port` на порт контейнера 2283 и монтирует каталог
  библиотеки как `/data`; `immich-machine-learning` монтирует кэш моделей
  как `/cache`. Оба контейнера читают `env_file: .env` и работают с
  `restart: unless-stopped`.
- Пишет `.env` (`immich.env.j2`) с `TZ`, `UPLOAD_LOCATION=/data`,
  переменными подключения `DB_*` включая пароль, `REDIS_HOSTNAME`,
  `REDIS_PORT` и при необходимости `REDIS_PASSWORD`; режим `0640`, задача
  работает с `no_log: true` и `diff: false`.
- Приводит проект к состоянию `immich_state` через
  `community.docker.docker_compose_v2`. При изменении `compose.yml` или
  `.env` модуль пересоздаёт контейнеры автоматически, поэтому отдельный
  handler перезапуска не нужен.
- Не создаёт учётную запись администратора, не настраивает внешние
  библиотеки и не публикует сервис через обратный прокси: учётная запись
  создаётся мастером первого запуска Immich, а Traefik публикует сервис
  своим file provider — оба пункта вне задач роли.

## Требования

- Целевая ОС: Debian 13 (проверяется `ansible_facts.os_family == 'Debian'`),
  в проекте — LXC.
- Docker Engine и плагин Compose v2 на целевом хосте; их устанавливает роль
  `docker`, `immich` Docker не ставит.
- `become: true` для создания каталогов и работы с Docker.
- Коллекции `community.docker` и `community.postgresql`, зафиксированные в
  project-level `requirements.yml`.
- Внешний сервер PostgreSQL (проект: `postgresql`, 172.25.40.151),
  доступный на `immich_db_port`. Для расширения `vchord` на сервере должны
  быть установлены VectorChord и pgvector, а `vchord.so` — перечислен в
  `shared_preload_libraries`; это настраивается на стороне сервера
  (`postgresql_extra_settings` роли `postgresql`), а не этой ролью.
- Внешний сервер Redis (проект: `redis`, 172.25.40.154), доступный на
  `immich_redis_port`.
- `VARS/secrets.yml`, подключённый playbook через `vars_files` — роль сама
  его не загружает.

## Изменяемые ресурсы

- Packages: `python3-psycopg2` из `immich_database_packages`.
- Files: `compose.yml` и `.env` в `immich_project_directory`, каталоги
  `immich_upload_dir` и `immich_ml_cache_dir`.
- Services: контейнеры `immich-server` и `immich-machine-learning` через
  Docker Compose.
- Users/groups: none.
- Database objects: при `immich_manage_database: true` роль PostgreSQL
  `immich_db_user`, база `immich_db_name` и расширения `vchord` +
  `earthdistance` внутри неё.
- Firewall/API objects: публикуемый контейнером порт `immich_web_port`.

## Переменные

| Variable | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `immich_debug_mode` | boolean | no | `false` | Итог изменений в debug-выводе. |
| `immich_state` | string | no | `"present"` | Требуемое состояние проекта Compose: `present` или `absent`. |
| `immich_project_directory` | string | no | `"/opt/immich"` | Каталог проекта Compose с `compose.yml` и `.env`. |
| `immich_upload_dir` | string | no | `"/opt/immich/library"` | Каталог хоста, монтируемый в серверный контейнер как `/data`; до загрузки реальной библиотеки укажите смонтированное фотохранилище. |
| `immich_ml_cache_dir` | string | no | `"/opt/immich/model-cache"` | Каталог хоста, монтируемый в ML-контейнер как `/cache`. |
| `immich_server_image` | string | no | `"ghcr.io/immich-app/immich-server:release"` | Образ сервера; для фиксации версии укажите `vX.Y.Z`. |
| `immich_ml_image` | string | no | `"ghcr.io/immich-app/immich-machine-learning:release"` | Образ машинного обучения; тег должен совпадать с сервером. |
| `immich_web_port` | integer | no | `2283` | Порт хоста, публикующий веб-интерфейс. |
| `immich_timezone` | string | no | `"Europe/Moscow"` | Часовой пояс IANA для меток времени библиотеки. |
| `immich_db_host` | string | yes | `null` | Адрес PostgreSQL; умолчания нет, проверяется assert. |
| `immich_db_port` | integer | no | `5432` | Порт PostgreSQL. |
| `immich_db_name` | string | no | `"immich"` | База Immich; создаётся ролью при `immich_manage_database: true`. |
| `immich_db_user` | string | no | `"immich"` | Логин Immich; создаётся ролью при `immich_manage_database: true`. |
| `immich_db_password_var` | string or null | yes | `null` | Имя переменной с паролем к базе из `VARS/secrets.yml`; пишется в `.env` как `DB_PASSWORD`. |
| `immich_manage_database` | boolean | no | `true` | Создать базу, роль и расширения до первого запуска; `false` ожидает их уже созданными. |
| `immich_db_admin_user` | string | no | `"postgres"` | Привилегированная учётная запись только для создания базы, роли и расширений. |
| `immich_db_admin_password_var` | string or null | in manage mode | `null` | Имя переменной с привилегированным паролем из `VARS/secrets.yml`; обязательно при `immich_manage_database: true`. |
| `immich_db_extensions` | list | no | `["vchord", "earthdistance"]` | Внутренний: расширения, создаваемые внутри базы Immich с `cascade`. |
| `immich_database_packages` | list | no | `["python3-psycopg2"]` | Внутренний: пакеты, нужные модулям `community.postgresql`. |
| `immich_redis_host` | string | yes | `null` | Адрес Redis; умолчания нет, проверяется assert. |
| `immich_redis_port` | integer | no | `6379` | Порт Redis. |
| `immich_redis_password_var` | string or null | no | `null` | Имя переменной с паролем Redis из `VARS/secrets.yml`; при `null` `REDIS_PASSWORD` не пишется в `.env`. |

## Секреты

Секреты указываются не прямыми именами, а через переменные `*_password_var`,
ссылающиеся на ключи `VARS/secrets.yml` (проектная конвенция, как у
`keycloak`, `zabbix_server` и `netbox`): значение секрета живёт только в
secrets.yml и никогда не попадает в host_vars. Playbook подключает
`VARS/secrets.yml` через `vars_files`; `defaults/main.yml` объявляет только
имена переменных. Ранние `ansible.builtin.assert` проверяют, что имена
заданы и названные секреты существуют — всё до первого изменения системы.

| Variable | Type | Required | Purpose |
| --- | --- | --- | --- |
| секрет по имени `immich_db_password_var` | string | yes | Пароль `immich_db_user`, например ключ `immich_db_password`; пишется в `.env` как `DB_PASSWORD`. |
| секрет по имени `immich_db_admin_password_var` | string | in manage mode | Пароль привилегированной учётной записи `immich_db_admin_user` на сервере PostgreSQL, например общий ключ `db_admin_password`; используется только для создания базы, роли и расширений. |
| секрет по имени `immich_redis_password_var` | string | no | Пароль Redis, например общий ключ `requirepass`; пишется в `.env` как `REDIS_PASSWORD`, когда имя переменной задано. |

`.env` — единственное место, где роль материализует секреты; его задача
работает с `no_log: true` и `diff: false`. В `compose.yml` секретов нет.

## Использование

```yaml
---
- name: Deploy Immich
  hosts: immich
  become: true
  vars_files:
    - ../VARS/secrets.yml
  roles:
    - role: docker
    - role: immich
      vars:
        immich_db_host: "172.25.40.151"
        immich_db_password_var: "immich_db_password"
        immich_db_admin_password_var: "db_admin_password"
        immich_redis_host: "172.25.40.154"
        immich_redis_password_var: "redis_requirepass"
```

## Tags

- `debug` — итоговая debug-задача при `immich_debug_mode: true`.

## Templates

- `Docker_Compose_Immich.j2` → `immich_project_directory/compose.yml`
- `immich.env.j2` → `immich_project_directory/.env` (секреты)

## Check mode и diff mode

Роль поддерживает `--check --diff`. Ограничения:

- `ansible.builtin.file` и шаблон compose корректно показывают diff; `.env`
  diff не показывает никогда (`diff: false`) — это ожидаемо, а не
  ограничение.
- `community.docker.docker_compose_v2` поддерживает check mode частично:
  предсказанные изменения зависят от демона Docker, поэтому результат задачи
  развертывания в check mode считайте оценкой.
- Модули `community.postgresql` в check mode ничего не создают; сторона базы
  предсказывается, но не применяется.

## Зависимости

- Коллекции `community.docker` и `community.postgresql`
  (project-level `requirements.yml`).
- Роль `docker` как prerequisite на уровне playbook; зависимость через
  `meta` не используется, порядок ролей задаёт playbook.
- Внешние: сервер PostgreSQL с установленными VectorChord и pgvector,
  сервер Redis и `VARS/secrets.yml`.

## Примечания

- **VectorChord обязателен на сервере PostgreSQL.** С Immich v1.133 (и
  обязательно с v3) апстрим использует расширение `vchord`; в пакетах Debian
  его нет — установите VectorChord на хосте `postgresql` и добавьте
  `vchord.so` в `shared_preload_libraries` там (`postgresql_extra_settings`
  роли `postgresql`), либо переопределите `immich_db_extensions` и
  предоставьте эквивалентные расширения самостоятельно. Без них
  `CREATE EXTENSION` падает.
- `immich_upload_dir` по умолчанию указывает на локальный путь. Целевое
  значение — фотохранилище, смонтированное в LXC слоем provisioning
  (ресурс `behemoth`/`media` по Docs 06); само монтирование вне задач роли —
  переопределите переменную на точку монтирования.
- За Traefik сервис публикуется как `immich.dragons-nest.home.arpa`;
  публикация — задача роли `traefik`, эта роль лишь выставляет
  `immich_web_port`.
- Состояние `absent` останавливает и удаляет контейнеры проекта, но
  сохраняет `compose.yml`, `.env` и данные на диске.
- Повторные прогоны идемпотентны: проект уже в требуемом состоянии не
  сообщает изменений.
