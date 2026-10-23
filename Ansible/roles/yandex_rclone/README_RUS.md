# yandex_rclone

Роль разворачивает одностороннее (облако → шара) зеркало Яндекс.Диска через
`rclone`. Заменяет консольный демон `yandex-disk`, который перестал получать
файлы после аварии в дата-центрах Яндекса в октябре 2026 (массовые HTTP 503 на
скачивание). Роль монтирует SMB-шару, ставит upstream-пакет rclone, пишет
конфиг с OAuth-приложением лаборатории и включает таймер systemd, который
запускает `rclone sync` по расписанию.

## Что делает

- Устанавливает `cifs-utils` из Debian и pinned `.deb`-пакет rclone
  (`yandex_rclone_deb_url`). Сборка rclone в самом Debian 13 старше формата
  токена бэкенда Yandex.
- Пишет `/etc/rclone/smbcredentials` (0600, root) и монтирует CIFS-шару.
- Пишет `/etc/rclone/rclone.conf` (0600, служебная учётка) с `client_id`,
  `client_secret` и JSON-блобом OAuth-токена. По умолчанию файл создаётся
  только при отсутствии (`yandex_rclone_config_overwrite: false`): rclone
  сам переписывает токен при обновлении, и перезапись конфига протухшим
  refresh-токеном сломала бы авторизацию.
- Создаёт `/var/log/rclone` с владельцем-служебной учёткой.
- Устанавливает `yandex-rclone.service` (oneshot `rclone sync`, `RequiresMountsFor`
  на точку монтирования) и `yandex-rclone.timer` (периодические прогоны).
  Сервис enabled для запуска при загрузке; таймер enabled и started.

## Требования

- Целевая ОС: Debian (проверено на Debian 13).
- Права: `become` до root.
- Служебная учётная запись и группа (`yandex`/`nas` в HomeLab) должны
  существовать до роли — обычно их создаёт `base_add_users`.
- Параметр `ansible.posix` — коллекция `ansible.posix` для модуля mount
  (фиксируется project-level `requirements.yml`).
- Секреты в `VARS/secrets.yml`: `vault_yandex_rclone_client_secret`,
  `vault_yandex_rclone_token` и переменная, чьё имя передано через
  `yandex_rclone_samba_password_var` (пароль Samba).

## Изменяемые ресурсы

- Packages: `cifs-utils` (apt), `rclone` (deb-файл, скачанный get_url).
- Files: `/etc/rclone/smbcredentials`, `/etc/rclone/rclone.conf`,
  `/etc/systemd/system/yandex-rclone.service`,
  `/etc/systemd/system/yandex-rclone.timer`, `/var/log/rclone/`,
  точка монтирования.
- Mounts: CIFS `yandex_rclone_mount_source` в `yandex_rclone_mount_point`.
- Services: `yandex-rclone.service` (enabled), `yandex-rclone.timer`
  (enabled, started).
- Handlers: `Reload systemd` при изменении файлов юнитов.

## Переменные

| Variable | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `yandex_rclone_mount_source` | string | yes | `null` | UNC-путь SMB-шары — целевого каталога зеркала. |
| `yandex_rclone_samba_password_var` | string | yes | `null` | Имя переменной в secrets.yml с паролем Samba. |
| `yandex_rclone_client_id` | string | yes | `null` | OAuth client id собственного приложения лаборатории. |
| `vault_yandex_rclone_client_secret` | string | yes (secrets.yml) | - | Секрет OAuth-приложения; не хранить вне secrets.yml. |
| `vault_yandex_rclone_token` | string | yes (secrets.yml) | - | JSON-блоб токена rclone (`access_token`, `refresh_token`, `expiry`). |
| `yandex_rclone_mount_point` | string | no | `"/mnt/yandex"` | Точка монтирования шары. |
| `yandex_rclone_mount_fstype` | string | no | `"cifs"` | Тип ФС монтирования. |
| `yandex_rclone_smb_version` | string | no | `"3.0"` | Диалект SMB. |
| `yandex_rclone_credentials_path` | string | no | `"/etc/rclone/smbcredentials"` | Путь файла учётных данных mount.cifs. |
| `yandex_rclone_samba_username` | string | no | `"yandex"` | Учётная запись Samba. |
| `yandex_rclone_samba_domain` | string | no | `"WORKGROUP"` | Рабочая группа NetBIOS. |
| `yandex_rclone_mount_file_mode` | string | no | `"0664"` | Права файлов на шаре. |
| `yandex_rclone_mount_dir_mode` | string | no | `"02775"` | Права каталогов на шаре. |
| `yandex_rclone_mount_static_options` | list | no | `["iocharset=utf8","_netdev","nofail"]` | Дополнительные опции CIFS. |
| `yandex_rclone_service_user` | string | no | `"yandex"` | Учётная запись сервиса. |
| `yandex_rclone_service_group` | string | no | `"nas"` | Группа сервиса. |
| `yandex_rclone_config_dir` | string | no | `"/etc/rclone"` | Каталог конфигурации rclone. |
| `yandex_rclone_config_path` | string | no | `"/etc/rclone/rclone.conf"` | Путь конфигурации rclone. |
| `yandex_rclone_config_overwrite` | bool | no | `false` | Перезаписывать rclone.conf при существовании. |
| `yandex_rclone_remote_name` | string | no | `"yandex"` | Имя remote-секции rclone. |
| `yandex_rclone_deb_url` | string | no | upstream v1.75.2 | URL .deb-пакета rclone. |
| `yandex_rclone_deb_path` | string | no | `"/tmp/rclone-v1.75.2-linux-amd64.deb"` | Локальный путь .deb. |
| `yandex_rclone_apt_packages` | list | no | `["cifs-utils"]` | Пакеты из Debian. |
| `yandex_rclone_backup_dir` | string | no | `<mount>/.rclone-backup` | Каталог для файлов, удалённых/изменённых в облаке. |
| `yandex_rclone_excludes` | list | no | `["/.rclone-backup/**","/.sync/**"]` | Исключения из синхронизации. |
| `yandex_rclone_transfers` | int | no | `4` | Параллельные передачи. |
| `yandex_rclone_checkers` | int | no | `8` | Параллельные checker-потоки. |
| `yandex_rclone_buffer_size` | string | no | `"8M"` | Буфер на передачу. |
| `yandex_rclone_contimeout` | string | no | `"15s"` | Таймаут соединения. |
| `yandex_rclone_timeout` | string | no | `"45s"` | Таймаут простоя передачи. |
| `yandex_rclone_retries` | int | no | `2` | Повторы операции sync. |
| `yandex_rclone_low_level_retries` | int | no | `3` | Повторы на запрос. |
| `yandex_rclone_log_dir` | string | no | `"/var/log/rclone"` | Каталог логов. |
| `yandex_rclone_log_file` | string | no | `<log_dir>/sync.log` | Файл лога sync. |
| `yandex_rclone_log_level` | string | no | `"INFO"` | Уровень логирования. |
| `yandex_rclone_service_name` | string | no | `"yandex-rclone"` | Базовое имя юнитов. |
| `yandex_rclone_service_enabled` | bool | no | `true` | Enable сервиса при загрузке. |
| `yandex_rclone_timer_enabled` | bool | no | `true` | Enable+start таймера. |
| `yandex_rclone_timer_oncalendar` | string | no | `"hourly"` | Расписание таймера. |
| `yandex_rclone_timer_randomized_sec` | int | no | `300` | Случайная задержка таймера. |
| `yandex_rclone_binary_path` | string | no | `"/usr/bin/rclone"` | Путь бинарника rclone. |
| `yandex_rclone_debug_mode` | bool | no | `false` | Debug-вывод изменений. |

## Использование

```yaml
---
- name: Configure the Yandex Disk mirror
  hosts: yandex
  become: true
  vars_files:
    - ../VARS/secrets.yml
  roles:
    - role: yandex_rclone
      vars:
        yandex_rclone_mount_source: "//172.25.40.44/yandex"
        yandex_rclone_samba_password_var: "nas_server_samba_password"
        yandex_rclone_client_id: "<lab-oauth-app-client-id>"
```

## Check mode и diff mode

Роль поддерживает `--check --diff`. Таски с секретами используют
`no_log: true` и `diff: false`, поэтому diff не показывает содержимое
smbcredentials и rclone.conf. В check mode `ansible.builtin.apt deb=` может
не предсказать изменение точно; `ansible.posix.mount` в check mode не
выполняет само монтирование.

## Зависимости

- Коллекция `ansible.posix` (модуль `mount`).
- `base_add_users` для служебной учётной записи и группы до роли.

## Примечания

- `rclone sync` зеркалирует облако в одну сторону: файлы, удалённые в облаке,
  перемещаются в `yandex_rclone_backup_dir`, а не удаляются насовсем.
- Токен rclone получается интерактивно (`rclone authorize yandex <id>
  <secret>` либо ручной code-обмен `oauth.yandex.ru/verification_code`) и
  хранится как единый JSON в `vault_yandex_rclone_token`. Access-token живёт
  ~год, refresh-токен обновляет его автоматически.
- После аварии в дата-центрах Яндекса (октябрь 2026) часть файлов на
  недоступных storage-нодах временно не скачивается ни одним клиентом —
  короткие таймауты (`yandex_rclone_contimeout`/`yandex_rclone_timeout`)
  позволяют прогону не зависать; недоступные файлы доезжают в следующих
  прогонах по мере восстановления Яндексом.
