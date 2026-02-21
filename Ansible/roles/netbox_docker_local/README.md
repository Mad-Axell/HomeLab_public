# NetBox Docker Local

Ansible role for deploying NetBox DCIM/IPAM as a Docker Compose stack on a local host.

Ansible-роль для развёртывания NetBox DCIM/IPAM в виде стека Docker Compose на локальном хосте.

## Description / Описание

[NetBox](https://github.com/netbox-community/netbox) is an open-source web application for managing and documenting computer networks and data centers (DCIM/IPAM). This role deploys the full NetBox stack using [netbox-docker](https://github.com/netbox-community/netbox-docker) images.

[NetBox](https://github.com/netbox-community/netbox) — это веб-приложение с открытым исходным кодом для управления и документирования компьютерных сетей и дата-центров (DCIM/IPAM). Эта роль разворачивает полный стек NetBox с использованием образов [netbox-docker](https://github.com/netbox-community/netbox-docker).

The role creates the necessary directory structure, generates a `docker-compose.yml` from a Jinja2 template with all environment variables, and starts the services. On subsequent runs, if the configuration changes, containers are automatically recreated via a handler.

Роль создаёт необходимую структуру директорий, генерирует `docker-compose.yml` из Jinja2-шаблона со всеми переменными окружения и запускает сервисы. При повторных запусках, если конфигурация изменилась, контейнеры автоматически пересоздаются через handler.

## Architecture / Архитектура

The role deploys 5 containers:

Роль разворачивает 5 контейнеров:

| Container / Контейнер | Image / Образ | Purpose / Назначение |
|---|---|---|
| `netbox` | `netboxcommunity/netbox` | Web application (Granian server) / Веб-приложение (сервер Granian) |
| `netbox-worker` | `netboxcommunity/netbox` | Background task worker (rqworker) / Фоновый обработчик задач |
| `netbox-postgres` | `postgres:18-alpine` | PostgreSQL database / База данных PostgreSQL |
| `netbox-redis` | `valkey/valkey:9.0-alpine` | Task queue (with AOF persistence) / Очередь задач (с AOF-персистенцией) |
| `netbox-redis-cache` | `valkey/valkey:9.0-alpine` | Caching layer / Кэширование |

```
                    ┌─────────────────────────────────────┐
                    │         Host :{{ netbox_port }}      │
                    └──────────────┬──────────────────────┘
                                   │
                    ┌──────────────▼──────────────────────┐
                    │         netbox (:8080)               │
                    │     Granian web server               │
                    └───┬──────────┬─────────────┬────────┘
                        │          │             │
               ┌────────▼───┐ ┌───▼────────┐ ┌──▼───────────┐
               │  postgres   │ │   redis    │ │  redis-cache │
               │   (:5432)   │ │  (:6379)   │ │   (:6379)    │
               └─────────────┘ └─────┬──────┘ └──────────────┘
                                     │
                    ┌────────────────▼────────────────────┐
                    │       netbox-worker                  │
                    │     rqworker (background jobs)       │
                    └─────────────────────────────────────┘
```

Data is stored in named Docker volumes:

Данные хранятся в именованных Docker-томах:

| Volume / Том | Purpose / Назначение |
|---|---|
| `netbox-postgres` | PostgreSQL database files / Файлы базы данных |
| `netbox-redis-data` | Redis AOF persistence / Персистенция Redis |
| `netbox-redis-cache-data` | Redis cache data / Данные кэша Redis |
| `netbox-media-files` | Uploaded media files / Загруженные медиа-файлы |
| `netbox-reports-files` | Custom reports / Пользовательские отчёты |
| `netbox-scripts-files` | Custom scripts / Пользовательские скрипты |

## Quick Start / Быстрый старт

```yaml
---
- name: Deploy NetBox
  hosts: netbox_server
  become: true
  roles:
    - docker
    - role: netbox_docker_local
      vars:
        netbox_db_password: "{{ vault_netbox_db_password }}"
        netbox_redis_password: "{{ vault_netbox_redis_password }}"
        netbox_redis_cache_password: "{{ vault_netbox_redis_cache_password }}"
        netbox_secret_key: "{{ vault_netbox_secret_key }}"
        netbox_superuser_password: "{{ vault_netbox_superuser_password }}"
```

After deployment, NetBox will be available at `http://<host>:8080/`.

После развёртывания NetBox будет доступен по адресу `http://<host>:8080/`.

## Requirements / Требования

- Ansible >= 2.12
- Target OS: Debian 11/12, Ubuntu 20.04/22.04/24.04
- Docker Engine and Docker Compose plugin installed (use `docker` role)
- Root or sudo access
- Internet connectivity for Docker image pull
- Minimum 2 GB RAM, 4 GB recommended

## Dependencies / Зависимости

- `docker` role — for Docker Engine and Docker Compose plugin installation

## Role Variables / Переменные роли

### Versions / Версии образов

| Variable / Переменная | Default | Description / Описание |
|---|---|---|
| `netbox_version` | `v4.5-4.0.0` | NetBox Docker image tag / Тег образа NetBox |
| `netbox_postgres_version` | `18-alpine` | PostgreSQL image tag / Тег образа PostgreSQL |
| `netbox_valkey_version` | `9.0-alpine` | Valkey (Redis) image tag / Тег образа Valkey |

### Directories / Директории

| Variable / Переменная | Default | Description / Описание |
|---|---|---|
| `netbox_base_dir` | `/opt/netbox` | Base directory for compose file / Базовая директория |
| `netbox_docker_compose_path` | `{{ netbox_base_dir }}/docker-compose.yml` | Path to generated compose file / Путь к compose-файлу |

### Container settings / Настройки контейнеров

| Variable / Переменная | Default | Description / Описание |
|---|---|---|
| `netbox_container_prefix` | `netbox` | Prefix for container names / Префикс имён контейнеров |
| `netbox_restart_policy` | `unless-stopped` | Docker restart policy / Политика перезапуска |
| `netbox_port` | `8080` | Host port for NetBox web UI / Порт на хосте для веб-интерфейса |

### Database (PostgreSQL) / База данных

| Variable / Переменная | Default | Description / Описание |
|---|---|---|
| `netbox_db_name` | `netbox` | Database name / Имя базы данных |
| `netbox_db_user` | `netbox` | Database user / Пользователь БД |
| `netbox_db_password` | `changeme_db_password` | Database password / Пароль БД |

### Redis (Valkey) / Кэш и очереди

| Variable / Переменная | Default | Description / Описание |
|---|---|---|
| `netbox_redis_password` | `changeme_redis_password` | Redis password (task queue) / Пароль Redis (очереди) |
| `netbox_redis_cache_password` | `changeme_redis_cache_password` | Redis password (cache) / Пароль Redis (кэш) |

### NetBox Application / Приложение

| Variable / Переменная | Default | Description / Описание |
|---|---|---|
| `netbox_secret_key` | `changeme_...` | Secret key (min 50 chars!) / Секретный ключ (мин. 50 символов!) |
| `netbox_api_token_pepper` | `""` | API token pepper (NetBox 4.x+) / Перец для API-токенов |
| `netbox_cors_origin_allow_all` | `true` | Allow all CORS origins / Разрешить все CORS-источники |
| `netbox_graphql_enabled` | `true` | Enable GraphQL API / Включить GraphQL API |
| `netbox_webhooks_enabled` | `true` | Enable webhooks / Включить вебхуки |
| `netbox_metrics_enabled` | `false` | Enable Prometheus metrics / Включить метрики Prometheus |
| `netbox_granian_workers` | `4` | Number of Granian workers / Количество воркеров Granian |
| `netbox_granian_backpressure` | `4` | Granian backpressure value / Значение backpressure Granian |

### Email / Почта

| Variable / Переменная | Default | Description / Описание |
|---|---|---|
| `netbox_email_server` | `localhost` | SMTP server / SMTP-сервер |
| `netbox_email_port` | `25` | SMTP port / Порт SMTP |
| `netbox_email_username` | `""` | SMTP username / Имя пользователя SMTP |
| `netbox_email_password` | `""` | SMTP password / Пароль SMTP |
| `netbox_email_from` | `netbox@example.com` | Sender address / Адрес отправителя |
| `netbox_email_use_ssl` | `false` | Use SSL / Использовать SSL |
| `netbox_email_use_tls` | `false` | Use TLS / Использовать TLS |
| `netbox_email_timeout` | `5` | Connection timeout (seconds) / Таймаут соединения (секунды) |

> **Note:** `email_use_ssl` and `email_use_tls` are mutually exclusive.
>
> **Примечание:** `email_use_ssl` и `email_use_tls` взаимоисключающие.

### Superuser / Суперпользователь

| Variable / Переменная | Default | Description / Описание |
|---|---|---|
| `netbox_skip_superuser` | `false` | Skip superuser creation / Пропустить создание суперпользователя |
| `netbox_superuser_name` | `admin` | Superuser login / Логин суперпользователя |
| `netbox_superuser_email` | `admin@example.com` | Superuser email / Email суперпользователя |
| `netbox_superuser_password` | `admin` | Superuser password / Пароль суперпользователя |
| `netbox_superuser_api_token` | `""` | Predefined API token (optional) / Предустановленный API-токен |

> **Warning:** The superuser is only created on first launch when the database is empty. Changing these variables after initial deployment has no effect.
>
> **Внимание:** Суперпользователь создаётся только при первом запуске, когда БД пуста. Изменение этих переменных после первичного развёртывания не имеет эффекта.

## Role Structure / Структура роли

```
netbox_docker_local/
├── defaults/
│   └── main.yml              # Default variables / Переменные по умолчанию
├── handlers/
│   └── main.yml              # Handlers / Обработчики
├── tasks/
│   └── main.yml              # Main tasks / Основные задачи
├── templates/
│   └── docker-compose.yml.j2 # Docker Compose template / Шаблон Docker Compose
└── README.md                 # This file / Этот файл
```

## Tags / Теги

| Tag / Тег | Scope / Область |
|---|---|
| `netbox` | All role tasks / Все задачи роли |
| `setup` | Directory creation / Создание директорий |
| `config` | Configuration deployment / Развёртывание конфигурации |
| `deploy` | Container startup / Запуск контейнеров |

Usage example / Пример использования:

```bash
# Deploy only configuration changes / Развернуть только изменения конфигурации
ansible-playbook playbook.yml --tags config

# Full deployment / Полное развёртывание
ansible-playbook playbook.yml --tags netbox
```

## Example Playbooks / Примеры плейбуков

### Basic deployment / Базовое развёртывание

```yaml
---
- name: Deploy NetBox
  hosts: netbox_server
  become: true
  roles:
    - docker
    - netbox_docker_local
```

### Production deployment with Vault / Production с Vault

```yaml
---
- name: Deploy NetBox (production)
  hosts: netbox_server
  become: true
  roles:
    - docker
    - role: netbox_docker_local
      vars:
        netbox_port: 8443
        netbox_db_password: "{{ vault_netbox_db_password }}"
        netbox_redis_password: "{{ vault_netbox_redis_password }}"
        netbox_redis_cache_password: "{{ vault_netbox_redis_cache_password }}"
        netbox_secret_key: "{{ vault_netbox_secret_key }}"
        netbox_api_token_pepper: "{{ vault_netbox_api_token_pepper }}"
        netbox_skip_superuser: false
        netbox_superuser_name: "admin"
        netbox_superuser_password: "{{ vault_netbox_superuser_password }}"
        netbox_superuser_email: "admin@company.com"
        netbox_granian_workers: 8
        netbox_email_server: "smtp.company.com"
        netbox_email_port: 587
        netbox_email_use_tls: true
        netbox_email_from: "netbox@company.com"
        netbox_email_username: "netbox"
        netbox_email_password: "{{ vault_netbox_email_password }}"
```

### Deployment in Proxmox LXC / Развёртывание в Proxmox LXC

```yaml
---
- name: Deploy NetBox in LXC container
  hosts: netbox_lxc
  become: true
  roles:
    - role: base/install_packages
    - role: docker
    - role: netbox_docker_local
      vars:
        netbox_port: 8080
        netbox_granian_workers: 2
        netbox_db_password: "{{ vault_netbox_db_password }}"
        netbox_secret_key: "{{ vault_netbox_secret_key }}"
```

## Files Created / Создаваемые файлы

| Path / Путь | Description / Описание |
|---|---|
| `/opt/netbox/` | Base directory / Базовая директория |
| `/opt/netbox/docker-compose.yml` | Generated Docker Compose config / Сгенерированная конфигурация Docker Compose |

## Post-Installation / После установки

### Verify deployment / Проверка развёртывания

```bash
# Check container status / Проверить статус контейнеров
docker compose -f /opt/netbox/docker-compose.yml ps

# View logs / Просмотр логов
docker compose -f /opt/netbox/docker-compose.yml logs -f netbox

# Check NetBox version / Проверить версию NetBox
docker exec netbox python /opt/netbox/netbox/manage.py version
```

### Create superuser manually / Создание суперпользователя вручную

If `netbox_skip_superuser: true` was set, create one manually:

Если был установлен `netbox_skip_superuser: true`, создайте вручную:

```bash
docker exec -it netbox python /opt/netbox/netbox/manage.py createsuperuser
```

### Database backup / Резервное копирование БД

```bash
# Create backup / Создать бэкап
docker exec netbox-postgres \
  pg_dump -U netbox -d netbox > netbox_backup_$(date +%F).sql

# Restore from backup / Восстановить из бэкапа
cat netbox_backup.sql | docker exec -i netbox-postgres \
  psql -U netbox -d netbox
```

### Version upgrade / Обновление версии

To upgrade NetBox, change the `netbox_version` variable and re-run the playbook. The handler will detect the configuration change and recreate the containers.

Для обновления NetBox измените переменную `netbox_version` и перезапустите плейбук. Handler обнаружит изменение конфигурации и пересоздаст контейнеры.

```yaml
netbox_version: "v4.6-4.1.0"  # New version / Новая версия
```

> **Important:** Before upgrading, always create a database backup. Some versions may require database migration, which runs automatically on container start.
>
> **Важно:** Перед обновлением всегда создавайте бэкап базы данных. Некоторые версии могут требовать миграции БД, которая выполняется автоматически при старте контейнера.

### Reverse proxy / Обратный прокси

For production use, it is recommended to place NetBox behind a reverse proxy (Nginx, Caddy, Traefik) with TLS termination. Example Nginx configuration:

Для production рекомендуется разместить NetBox за обратным прокси (Nginx, Caddy, Traefik) с терминацией TLS. Пример конфигурации Nginx:

```nginx
server {
    listen 443 ssl http2;
    server_name netbox.example.com;

    ssl_certificate     /etc/ssl/certs/netbox.crt;
    ssl_certificate_key /etc/ssl/private/netbox.key;

    client_max_body_size 25m;

    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

## Troubleshooting / Устранение неполадок

### NetBox does not start / NetBox не запускается

```bash
# Check all container statuses / Проверить статусы всех контейнеров
docker compose -f /opt/netbox/docker-compose.yml ps -a

# Check NetBox container logs / Проверить логи контейнера NetBox
docker compose -f /opt/netbox/docker-compose.yml logs netbox

# Check database connectivity / Проверить подключение к БД
docker exec netbox-postgres pg_isready -U netbox
```

### Worker not processing tasks / Воркер не обрабатывает задачи

```bash
# Check worker logs / Проверить логи воркера
docker compose -f /opt/netbox/docker-compose.yml logs netbox-worker

# Restart worker / Перезапустить воркер
docker compose -f /opt/netbox/docker-compose.yml restart netbox-worker
```

### Redis connection issues / Проблемы с подключением к Redis

```bash
# Test Redis connectivity / Проверить подключение к Redis
docker exec netbox-redis valkey-cli -a '<redis_password>' ping

# Test Redis cache connectivity / Проверить подключение к Redis-cache
docker exec netbox-redis-cache valkey-cli -a '<redis_cache_password>' ping
```

### Complete stack restart / Полный перезапуск стека

```bash
docker compose -f /opt/netbox/docker-compose.yml down
docker compose -f /opt/netbox/docker-compose.yml up -d --wait
```

## Security Recommendations / Рекомендации по безопасности

1. **Always change default passwords** — all `changeme_*` values must be replaced in production.

   **Всегда меняйте пароли по умолчанию** — все значения `changeme_*` должны быть заменены в production.

2. **Use Ansible Vault** for storing secrets:

   **Используйте Ansible Vault** для хранения секретов:

   ```bash
   ansible-vault encrypt_string 'my_secret_password' --name 'vault_netbox_db_password'
   ```

3. **Generate a strong secret key** (minimum 50 characters):

   **Сгенерируйте надёжный секретный ключ** (минимум 50 символов):

   ```bash
   python3 -c "import secrets; print(secrets.token_urlsafe(64))"
   ```

4. **Restrict network access** — NetBox should not be exposed directly to the internet. Use a reverse proxy with TLS.

   **Ограничьте сетевой доступ** — NetBox не должен быть доступен напрямую из интернета. Используйте обратный прокси с TLS.

5. **Set `netbox_cors_origin_allow_all: false`** in production and configure specific allowed origins.

   **Установите `netbox_cors_origin_allow_all: false`** в production и настройте конкретные разрешённые источники.

## License

MIT

## Author

Mad-Axell
