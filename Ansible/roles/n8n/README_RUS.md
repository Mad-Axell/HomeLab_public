# n8n

Эта роль разворачивает n8n (автоматизация workflows; в проекте маршрутизирует
уведомления Zabbix, Prometheus, Home Assistant и Frigate в Telegram по
Docs 06) как проект Docker Compose v2 на целевом хосте с уже установленным
Docker — хост `n8n` (172.25.40.203, LXC 441). Контейнерное развёртывание —
поддерживаемый апстримом путь для production и проектная конвенция для
сервисов, живущих только в контейнере (`uptime`, `frigate`, `immich`). Роль
использует внешний PostgreSQL (в проекте 172.25.40.151) вместо встроенного
SQLite, по умолчанию сама создаёт базу и роль (`n8n_manage_database`), а ключ
шифрования учётных данных фиксирует через indirection
`n8n_encryption_key_var`.

## Что делает

- Проверяет платформу Debian и обязательные входы (`n8n_db_host`,
  `n8n_db_password_var`, `n8n_encryption_key_var`, плюс
  `n8n_db_admin_password_var` при включённом `n8n_manage_database`) ранним
  `ansible.builtin.assert`, затем отдельной проверкой убеждается, что
  названные секреты существуют — всё до первого изменения.
- Устанавливает `python3-psycopg2` (`n8n_database_packages`), нужный
  модулям `community.postgresql` на целевом хосте.
- При `n8n_manage_database: true` создаёт роль PostgreSQL `n8n_db_user`
  (LOGIN, пароль из `n8n_db_password_var`) и базу `n8n_db_name` с владельцем
  `n8n_db_user`; подключение выполняется привилегированной учётной записью
  `n8n_db_admin_user`. Обе задачи работают с `no_log: true`.
- Создаёт каталог проекта Compose `n8n_project_directory` и каталог данных
  `n8n_data_dir` с владельцем uid/gid 1000 — учётной записью `node`, от имени
  которой работает контейнер n8n.
- Отрисовывает `compose.yml` (`Docker_Compose_N8n.j2`): контейнер `n8n`
  публикует `n8n_web_port` на порт контейнера 5678 и монтирует каталог
  данных как `/home/node/.n8n`; читает `env_file: .env` и работает с
  `restart: unless-stopped`.
- Пишет `.env` (`n8n.env.j2`) с `GENERIC_TIMEZONE`/`TZ`, переменными
  подключения `DB_POSTGRESDB_*` включая пароль, `N8N_ENCRYPTION_KEY`,
  `N8N_PROTOCOL`, `N8N_SECURE_COOKIE`, и при необходимости `N8N_HOST` и
  `WEBHOOK_URL`; режим `0640`, задача работает с `no_log: true` и
  `diff: false`.
- Приводит проект к состоянию `n8n_state` через
  `community.docker.docker_compose_v2`. При изменении `compose.yml` или
  `.env` модуль пересоздаёт контейнер автоматически, поэтому отдельный
  handler перезапуска не нужен.
- Не создаёт учётную запись владельца, не импортирует workflows и не
  публикует сервис через обратный прокси: владелец создаётся мастером
  первого запуска n8n, а Traefik публикует сервис своим file provider — всё
  вне задач роли.

## Требования

- Целевая ОС: Debian 13 (проверяется `ansible_facts.os_family == 'Debian'`),
  в проекте — LXC.
- Docker Engine и плагин Compose v2 на целевом хосте; их устанавливает роль
  `docker`, `n8n` Docker не ставит.
- `become: true` для создания каталогов и работы с Docker.
- Коллекции `community.docker` и `community.postgresql`, зафиксированные в
  project-level `requirements.yml`.
- Внешний сервер PostgreSQL (проект: `postgresql`, 172.25.40.151),
  доступный на `n8n_db_port`; postgres — единственный поддерживаемый бэкенд.
- `VARS/secrets.yml`, подключённый playbook через `vars_files` — роль сама
  его не загружает.

## Изменяемые ресурсы

- Packages: `python3-psycopg2` из `n8n_database_packages`.
- Files: `compose.yml` и `.env` в `n8n_project_directory`, каталог
  `n8n_data_dir` (uid/gid 1000).
- Services: контейнер `n8n` через Docker Compose.
- Users/groups: none.
- Database objects: при `n8n_manage_database: true` роль PostgreSQL
  `n8n_db_user` и база `n8n_db_name`.
- Firewall/API objects: публикуемый контейнером порт `n8n_web_port`.

## Переменные

| Variable | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `n8n_debug_mode` | boolean | no | `false` | Итог изменений в debug-выводе. |
| `n8n_state` | string | no | `"present"` | Требуемое состояние проекта Compose: `present` или `absent`. |
| `n8n_project_directory` | string | no | `"/opt/n8n"` | Каталог проекта Compose с `compose.yml` и `.env`. |
| `n8n_data_dir` | string | no | `"/opt/n8n/data"` | Каталог хоста, монтируемый в контейнер как `/home/node/.n8n`; владелец uid/gid 1000. |
| `n8n_image` | string | no | `"docker.n8n.io/n8nio/n8n:stable"` | Образ n8n; для фиксации версии укажите `X.Y.Z`. |
| `n8n_container_name` | string | no | `"n8n"` | Имя контейнера n8n. |
| `n8n_web_port` | integer | no | `5678` | Порт хоста, публикующий веб-интерфейс. |
| `n8n_timezone` | string | no | `"Europe/Moscow"` | Часовой пояс IANA для расписаний workflows. |
| `n8n_db_host` | string | yes | `null` | Адрес PostgreSQL; умолчания нет, проверяется assert. |
| `n8n_db_port` | integer | no | `5432` | Порт PostgreSQL. |
| `n8n_db_name` | string | no | `"n8n"` | База n8n; создаётся ролью при `n8n_manage_database: true`. |
| `n8n_db_user` | string | no | `"n8n"` | Логин n8n; создаётся ролью при `n8n_manage_database: true`. |
| `n8n_db_password_var` | string or null | yes | `null` | Имя переменной с паролем к базе из `VARS/secrets.yml`; пишется в `.env` как `DB_POSTGRESDB_PASSWORD`. |
| `n8n_manage_database` | boolean | no | `true` | Создать базу и её роль до первого запуска; `false` ожидает их уже созданными. |
| `n8n_db_admin_user` | string | no | `"postgres"` | Привилегированная учётная запись только для создания базы и роли. |
| `n8n_db_admin_password_var` | string or null | in manage mode | `null` | Имя переменной с привилегированным паролем из `VARS/secrets.yml`; обязательно при `n8n_manage_database: true`. |
| `n8n_database_packages` | list | no | `["python3-psycopg2"]` | Внутренний: пакеты, нужные модулям `community.postgresql`. |
| `n8n_encryption_key_var` | string or null | yes | `null` | Имя переменной с `N8N_ENCRYPTION_KEY` в `VARS/secrets.yml`; проверяется assert. |
| `n8n_hostname` | string or null | no | `null` | Публичное имя, пишется как `N8N_HOST`; `null` или пустая строка опускает переменную. |
| `n8n_protocol` | string | no | `"http"` | Протокол слушателя; `http`, потому что TLS завершает Traefik. |
| `n8n_webhook_url` | string or null | no | `null` | Внешний URL, пишется как `WEBHOOK_URL`; `null` или пустая строка опускает переменную. |
| `n8n_secure_cookie` | boolean | no | `true` | `N8N_SECURE_COOKIE`; `true` за Traefik/HTTPS, `false` только для прямого доступа по HTTP. |

## Секреты

Секреты указываются не прямыми именами, а через переменные `*_var`,
ссылающиеся на ключи `VARS/secrets.yml` (проектная конвенция, как у
`keycloak`, `zabbix_server` и `netbox`): значение секрета живёт только в
secrets.yml и никогда не попадает в host_vars. Playbook подключает
`VARS/secrets.yml` через `vars_files`; `defaults/main.yml` объявляет только
имена переменных. Ранние `ansible.builtin.assert` проверяют, что имена
заданы и названные секреты существуют — всё до первого изменения системы.

| Variable | Type | Required | Purpose |
| --- | --- | --- | --- |
| секрет по имени `n8n_db_password_var` | string | yes | Пароль `n8n_db_user`, например ключ `n8n_db_password`; пишется в `.env` как `DB_POSTGRESDB_PASSWORD`. |
| секрет по имени `n8n_encryption_key_var` | string | yes | `N8N_ENCRYPTION_KEY`, например ключ `n8n_encryption_key`; шифрует учётные данные, сохраняемые workflows. Без зафиксированного ключа пересозданный каталог данных делает все сохранённые учётные данные нечитаемыми. |
| секрет по имени `n8n_db_admin_password_var` | string | in manage mode | Пароль привилегированной учётной записи `n8n_db_admin_user` на сервере PostgreSQL, например общий ключ `db_admin_password`; используется только для создания базы и роли. |

`.env` — единственное место, где роль материализует секреты; его задача
работает с `no_log: true` и `diff: false`. В `compose.yml` секретов нет.

## Использование

```yaml
---
- name: Deploy n8n
  hosts: n8n
  become: true
  vars_files:
    - ../VARS/secrets.yml
  roles:
    - role: docker
    - role: n8n
      vars:
        n8n_db_host: "172.25.40.151"
        n8n_db_password_var: "n8n_db_password"
        n8n_db_admin_password_var: "db_admin_password"
        n8n_encryption_key_var: "n8n_encryption_key"
        n8n_hostname: "n8n.dragons-nest.home.arpa"
        n8n_webhook_url: "https://n8n.dragons-nest.home.arpa/"
```

## Tags

- `debug` — итоговая debug-задача при `n8n_debug_mode: true`.

## Templates

- `Docker_Compose_N8n.j2` → `n8n_project_directory/compose.yml`
- `n8n.env.j2` → `n8n_project_directory/.env` (секреты)

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
- Внешние: сервер PostgreSQL и `VARS/secrets.yml`.

## Примечания

- Учётная запись владельца создаётся мастером настройки n8n при первом
  входе; старый env-based basic auth удалён апстримом, поэтому роль его не
  моделирует.
- За Traefik сервис публикуется как `n8n.dragons-nest.home.arpa`;
  публикация — задача роли `traefik`. Задайте `n8n_hostname` и
  `n8n_webhook_url` внешним именем, чтобы webhook-узлы объявляли достижимые
  адреса.
- Состояние `absent` останавливает и удаляет контейнер проекта, но
  сохраняет `compose.yml`, `.env` и данные на диске.
- Повторные прогоны идемпотентны: проект уже в требуемом состоянии не
  сообщает изменений.
