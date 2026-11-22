# traefik

Роль устанавливает reverse proxy Traefik на Debian как статический бинарный файл с официального релиза GitHub: создаёт выделенную системную учётную запись, systemd-юнит, статическую конфигурацию с редиректом HTTP→HTTPS и каталог file provider для динамической конфигурации. TLS-сертификат и закрытый ключ подаются извне; DNS-записи и выпуск сертификатов находятся вне области роли.

## Что делает

- Создаёт системные группу и пользователя `traefik`.
- Скачивает зафиксированный релиз Traefik и распаковывает бинарный файл в `/usr/local/bin`; установленная версия хранится в маркерном файле, поэтому обновления при смене `traefik_version` идемпотентны.
- Записывает статическую конфигурацию: `web` (`:80`) с постоянным редиректом на `websecure` (`:443`, TLS), file provider, отслеживающий `/etc/traefik/dynamic`.
- При `traefik_tls_enabled` записывает сертификат, закрытый ключ и динамический файл, назначающий их сертификатом по умолчанию; при выключении удаляет это материальные файлы.
- Записывает файлы из `traefik_dynamic_config_files` в каталог file provider (перечитываются без перезапуска) и удаляет из каталога файлы, которые больше не управляются ролью.
- Устанавливает systemd-юнит и приводит сервис `traefik` к запрошенному состоянию.

Ограничение: TLS работает только с заранее выпущенным сертификатом. Роль не реализует внутренний CA, ACME или Let's Encrypt; сертификат и ключ выдаёт внешний процесс (например, внутренний CA инфраструктуры), а роль лишь устанавливает их.

## Требования

- Debian или Ubuntu (целевая платформа проекта — Debian 13 LXC).
- `become: true`.
- Сетевой доступ с целевого хоста к `github.com` для загрузки релиза.
- При `traefik_tls_enabled` — переменная `traefik_tls_cert` и секрет `vault_traefik_tls_key` из `VARS/secrets.yml`, подключённого playbook'ом через `vars_files`.

## Изменяемые ресурсы

- Packages: none (установка из архива релиза, без apt).
- Files: `/usr/local/bin/traefik`, `/etc/traefik/traefik.yml`, `/etc/traefik/.installed-version`, `/etc/traefik/dynamic/*` (динамические файлы и удаление неуправляемых `*.yml`/`*.yaml`), `/etc/traefik/tls/fullchain.pem`, `/etc/traefik/tls/privkey.pem` (при включённом TLS), `/etc/systemd/system/traefik.service`; временный архив в `/tmp` удаляется.
- Services: `traefik` (systemd).
- Users/groups: `traefik`/`traefik` (system, без home и login shell).
- Firewall/API objects: none.

## Переменные

| Variable | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `traefik_debug_mode` | boolean | no | `false` | Debug-вывод после пользовательски значимых изменений (тег `debug`). |
| `traefik_version` | string | no | `"3.7.19"` | Зафиксированная версия релиза без ведущей `v`. |
| `traefik_arch` | string | no | `"amd64"` | Архитектура в имени ассета релиза. |
| `traefik_download_url` | string | no | GitHub releases URL | URL tarball'а; собирается из версии и архитектуры. |
| `traefik_archive_checksum` | string/null | no | `null` | Опциональный sha256 tarball'а из ассета `traefik_v<version>_checksums.txt`; `null` — без проверки. |
| `traefik_archive_path` | string | no | `/tmp/traefik_v...tar.gz` | Временный путь скачанного архива. |
| `traefik_binary_path` | string | no | `"/usr/local/bin/traefik"` | Путь установленного бинарного файла. |
| `traefik_version_marker_path` | string | no | `"/etc/traefik/.installed-version"` | Маркер установленной версии. |
| `traefik_user` | string | no | `"traefik"` | Учётная запись сервиса. |
| `traefik_group` | string | no | `"traefik"` | Группа сервиса. |
| `traefik_config_dir` | string | no | `"/etc/traefik"` | Каталог статической конфигурации. |
| `traefik_dynamic_dir` | string | no | `"/etc/traefik/dynamic"` | Отслеживаемый каталог file provider. |
| `traefik_tls_dir` | string | no | `"/etc/traefik/tls"` | Каталог сертификата и ключа. |
| `traefik_config_path` | string | no | `"/etc/traefik/traefik.yml"` | Файл статической конфигурации. |
| `traefik_tls_dynamic_path` | string | no | `"/etc/traefik/dynamic/10-tls.yml"` | Динамический файл хранилища сертификата. |
| `traefik_tls_cert_path` | string | no | `"/etc/traefik/tls/fullchain.pem"` | Путь PEM-цепочки. |
| `traefik_tls_key_path` | string | no | `"/etc/traefik/tls/privkey.pem"` | Путь PEM-ключа. |
| `traefik_unit_path` | string | no | `"/etc/systemd/system/traefik.service"` | Файл systemd-юнита. |
| `traefik_http_port` | integer | no | `80` | Порт entry point `web`; редирект на HTTPS. |
| `traefik_https_port` | integer | no | `443` | Порт entry point `websecure`. |
| `traefik_domain` | string | no | `"example.internal"` | Базовый домен для Jinja в `content` динамических файлов; переопределить реальной зоной. |
| `traefik_dynamic_config_files` | list of dict | no | `[]` | Динамические конфигурации file provider: `name` (имя файла, используется basename), `content` (YAML, рендерится как Jinja), опционально `sensitive` (скрывает вывод и diff элемента). |
| `traefik_dashboard_enabled` | boolean | no | `false` | Дашборд и API на `:8080` через `api.insecure`. |
| `traefik_log_level` | string | no | `"INFO"` | Уровень логирования. |
| `traefik_tls_enabled` | boolean | no | `false` | Включить HTTPS с внешним сертификатом и ключом. |
| `traefik_tls_cert` | string | yes, при `traefik_tls_enabled` | `null` | Содержимое PEM-цепочки сертификата; проверяется `assert` до изменений. |
| `traefik_service_name` | string | no | `"traefik"` | Имя systemd-сервиса. |
| `traefik_service_state` | string | no | `"started"` | Устойчивое состояние (`started`/`stopped`). |
| `traefik_service_enabled` | boolean | no | `true` | Автозапуск при загрузке. |

Секреты (только из `VARS/secrets.yml`, без значений в defaults):

| Variable | Type | Required | Description |
| --- | --- | --- | --- |
| `vault_traefik_tls_key` | string | yes, при `traefik_tls_enabled` | Содержимое PEM закрытого ключа. Таска записи использует `no_log: true` и `diff: false`. |

## Использование

```yaml
---
- name: Configure the reverse proxy
  hosts: traefik
  become: true
  vars_files:
    - "VARS/secrets.yml"  # vault_traefik_tls_key
  roles:
    - role: traefik
      vars:
        traefik_domain: "example.internal"
        traefik_tls_enabled: true
        traefik_tls_cert: "{{ lookup('ansible.builtin.file', 'fullchain.pem') }}"
        traefik_dynamic_config_files:
          - name: "grafana.yml"
            content: |
              http:
                routers:
                  grafana:
                    rule: "Host(`grafana.{{ traefik_domain }}`)"
                    entryPoints: ["websecure"]
                    service: "grafana"
                    tls: {}
                services:
                  grafana:
                    loadBalancer:
                      servers:
                        - url: "http://10.0.0.52:3000"
          - name: "dashboard-auth.yml"
            sensitive: true
            content: |
              http:
                middlewares:
                  admin-auth:
                    basicAuth:
                      users: ["admin:$apr1$..."]
```

## Check mode и diff mode

Роль поддерживает `ansible-playbook --check --diff` со следующими ограничениями:

- Загрузка tarball'а прогнозируется, но распаковка бинарного файла (`unarchive`) в check mode пропускается: архива на хосте ещё нет. Решение об установке принимается по маркеру версии.
- `diff` скрыт для закрытого ключа и для элементов `traefik_dynamic_config_files` с `sensitive: true`.
- `slurp` маркера пропускается при первом прогоне — установка прогнозируется корректно.

## Handlers

- `Reload systemd` — daemon-reload после изменения юнита.
- `Restart Traefik` — после изменения бинарного файла, статической конфигурации, сертификата/ключа или их удаления. Динамические файлы перечитываются file provider без перезапуска.

## Tags

- `debug` — сводная debug-таска; пропускается через `--skip-tags debug`.

## Templates

- `traefik.yml.j2` — статическая конфигурация.
- `dynamic_tls.yml.j2` — хранилище сертификата по умолчанию.
- `traefik.service.j2` — systemd-юнит.

## Зависимости

- None (только `ansible.builtin`).

## Примечания

- DNS-записи обслуживаемых имён (wildcard на адрес прокси) и правила firewall для портов 80/443/8080 находятся вне области роли и настраиваются отдельно (pfSense/Unbound в данной инфраструктуре).
- `traefik_dashboard_enabled` открывает API без аутентификации на `:8080` (`api.insecure`); ограничивайте доступ на firewall. Защита basic-auth оформляется middleware в `traefik_dynamic_config_files`.
- Без `traefik_tls_enabled` entry point `websecure` отвечает встроенным самоподписанным сертификатом Traefik, а редирект `web`→`websecure` остаётся включённым.
- Systemd-юнит выдаёт `CAP_NET_BIND_SERVICE`, поэтому Traefik слушает 80/443 от непривилегированной учётной записи.
