# keycloak

Устанавливает сервер Keycloak из апстримного tar-архива на Debian 13 LXC
(в проекте — 172.25.40.42, LXC 402): Java-окружение, системная учётная запись,
версионированное дерево `/opt/keycloak-<версия>` с симлинком `/opt/keycloak`,
`conf/keycloak.conf` для внешнего PostgreSQL и работы за обратным прокси
Traefik, systemd-юнит и начальный администратор через переменные окружения
`KC_BOOTSTRAP_ADMIN_*`. Результат — работающий Keycloak по HTTP на внутреннем
порту 8080, готовый терминироваться Traefik по
`https://keycloak.dragons-nest.home.arpa`.

## Что делает

- Ставит Java-пакет `keycloak_java_package` (по умолчанию
  `default-jre-headless`, в Debian 13 — OpenJDK 21).
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
  `0640 root:keycloak`; задача выполняется с `no_log: true` и `diff: false`.
- Ставит systemd-юнит `keycloak.service` (`kc.sh start --optimized`) и после
  смены выпуска или конфигурации выполняет `kc.sh build`, чтобы `--optimized`
  стартовал на актуальной сборке.
- Запускает и включает сервис; перезапуск при изменении конфигурации, окружения
  или юнита выполняет handler `Restart Keycloak`.

## Требования

- Целевая ОС: Debian 13 (проверяется `ansible_facts.os_family == 'Debian'`).
- Права: `become: true`; сборка выполняется от `become_user: keycloak`.
- Внешний PostgreSQL с уже созданными базой и логином: в проекте это хост
  `postgresql` (172.25.40.151), а база и роль заводятся отдельно ролью
  `postgresql` в orchestration playbook. Эта роль базу не создаёт.
- `VARS/secrets.yml`, подключённый playbook'ом через `vars_files`, — роль сама
  его не загружает.
- Доступ целевого хоста к `keycloak_download_url` (по умолчанию github.com) —
  архив скачивается на целевом хосте.
- Секреты `vault_keycloak_db_password` и `vault_keycloak_admin_password`
  обязательны и проверяются ранним `ansible.builtin.assert`.

## Изменяемые ресурсы

- Packages: пакет из `keycloak_java_package` (`default-jre-headless`).
- Files: `/tmp/keycloak-<версия>.tar.gz`, `/opt/keycloak-<версия>/`,
  симлинк `/opt/keycloak`, `/opt/keycloak/conf/keycloak.conf`,
  `/etc/keycloak/keycloak.env`, `/etc/systemd/system/keycloak.service`.
- Services: `keycloak.service`.
- Users/groups: `keycloak` (system, `/usr/sbin/nologin`).

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
| `keycloak_db_name` | string | no | `"keycloak"` | База Keycloak (должна существовать). |
| `keycloak_db_user` | string | no | `"keycloak"` | Логин Keycloak (должен существовать). |
| `keycloak_hostname` | string | yes | `null` | Публичный базовый URL, напр. `"https://keycloak.dragons-nest.home.arpa"`; проверяется assert. |
| `keycloak_hostname_strict` | boolean | no | `true` | `hostname-strict` в hostname v2. |
| `keycloak_http_enabled` | boolean | no | `true` | HTTP-слушатель; true за Traefik. |
| `keycloak_http_port` | integer | no | `8080` | Порт HTTP-слушателя. |
| `keycloak_proxy_headers` | string | no | `"xforwarded"` | Доверенные forwarded-заголовки прокси. |
| `keycloak_extra_options` | dict | no | `{}` | Дополнительные пары `option=value` в keycloak.conf. |
| `keycloak_admin_user` | string | no | `"admin"` | Имя bootstrap-администратора. |
| `keycloak_env_file` | string | no | `"/etc/keycloak/keycloak.env"` | Файл секретного окружения юнита. |
| `keycloak_service_name` | string | no | `"keycloak"` | Имя systemd-юнита. |
| `keycloak_service_state` | string | no | `"started"` | Устойчивое состояние сервиса: `started` или `stopped`. |
| `keycloak_service_enabled` | boolean | no | `true` | Запуск сервиса при загрузке. |

## Секреты

Секреты приходят только из `VARS/secrets.yml`, подключённого playbook'ом; в
`defaults/main.yml` их нет даже как `null`, а наличие проверяет единый ранний
`ansible.builtin.assert` (с `quiet: true`) до первого изменения системы.

| Secret | Required | Назначение |
| --- | --- | --- |
| `vault_keycloak_db_password` | yes | Пароль `keycloak_db_user`; попадает в `keycloak.env` как `KC_DB_PASSWORD`. |
| `vault_keycloak_admin_password` | yes | Пароль bootstrap-администратора; `KC_BOOTSTRAP_ADMIN_PASSWORD`. |

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

- None — только `ansible.builtin`. Внешние: PostgreSQL с готовой базой и логином,
  `VARS/secrets.yml`.

## Примечания

- **Вне области роли:** создание realm `dragons-nest`, политика MFA/OTP и
  OIDC-клиент для Grafana — это фаза 2 после установки (по плану
  `PLAN_observability.md`, этап после Traefik); создание базы и логина на
  хосте postgresql тоже вне роли — их оркестрирует playbook через роль
  `postgresql`.
- Bootstrap-администратор через `KC_BOOTSTRAP_ADMIN_*` создаётся при первом
  старте, когда в realm master ещё нет администратора; после этого заведите
  постоянную учётную запись администратора в консоли.
- Приложение рассчитано на работу за Traefik: `http-enabled=true`,
  `proxy-headers=xforwarded`, `keycloak_hostname` — внешнее HTTPS-имя.
- Обновление версии: поднять `keycloak_version` — скачается новый архив,
  распакуется рядом, симлинк переключится, выполнится `kc.sh build`, сервис
  перезапустится handler'ом.
