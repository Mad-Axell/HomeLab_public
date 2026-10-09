# yandex_disk

Роль разворачивает консольный клиент Яндекс.Диска (`yandex-disk`) на Debian:
подключает официальный APT-репозиторий вендора, монтирует SMB-шару как
локальную копию Диска, пишет конфигурацию клиента и файл OAuth-токена и
запускает демон синхронизации systemd-юнитом от служебной учётной записи.

В лаборатории роль применяется к контейнеру `yandex` на pve-main: шара
`yandex` контейнера samba (backing — датасет `behemoth/yandex`) монтируется в
`/mnt/yandex` по CIFS, и демон синхронизирует её с облаком.

## Что делает

- Проверяет входные данные (`ansible.builtin.assert`) до первого изменения.
- Читает uid/gid служебных учётной записи и группы через `getent` — опции
  монтирования CIFS принимают числа.
- Скачивает ключ подписи `YANDEX-DISK-KEY.GPG` в `/etc/apt/keyrings/` и
  регистрирует репозиторий `repo.yandex.ru/yandex-disk` (без `apt-key`). Ключ
  вендора ASCII-armored и сохраняется как `.asc`.
- На Debian 13+ переводит верификатор подписей apt с `sqv` на `gpgv`
  (`APT::Key::GPGVCommand`, пакет `gpgv`, host-wide): `sqv` отвергает связку
  ключа вендора по SHA1, считая его небезопасным с 2026-02-01. Отключается
  через `yandex_disk_apt_gpgv_fallback: false`.
- Устанавливает пакеты `yandex-disk` и `cifs-utils`.
- Пишет `/etc/yandex-disk/smbcredentials` (0600, root) — логин и пароль SMB.
- Монтирует шару через запись в `/etc/fstab` (`_netdev`, `nofail`, uid/gid
  служебной учётной записи).
- Пишет `/etc/yandex-disk/config.cfg` (`auth`, `dir`, опционально
  `exclude-dirs`).
- Пишет `/etc/yandex-disk/passwd` (0600, владелец — служебная учётная запись)
  с содержимым файла токена — одной непрозрачной строкой, которую генерирует
  `yandex-disk token` (тот же формат, что у `~/.config/yandex-disk/passwd`).
- Устанавливает systemd-юнит `yandex-disk.service` (`Type=forking`,
  `RequiresMountsFor` на точку монтирования, `Restart=on-failure`) и
  управляет его состоянием.

## Требования

- Целевая ОС: Debian (проверено на Debian 13 LXC в Proxmox).
- `become: true` — роли нужен root.
- Служебная учётная запись и группа должны существовать до роли (в проекте их
  создаёт `base_add_users`).
- SMB-шара должна быть доступна на момент прогона; роль не проверяет её
  содержимое.
- Пакет `python3-apt` для `apt_repository` (в проекте ставится
  `base_install_packages`).

## Изменяемые ресурсы

- Packages: `yandex-disk`, `cifs-utils` (из `yandex_disk_packages`).
- Files: `/etc/apt/keyrings/yandex-disk.asc`,
  `/etc/apt/sources.list.d/yandex-disk.list`,
  `/etc/apt/apt.conf.d/99-yandex-disk-gpgv` (только Debian 13+),
  `/etc/yandex-disk/` со
  `smbcredentials`, `config.cfg`, `passwd`,
  `/etc/systemd/system/yandex-disk.service`.
- Mounts: запись CIFS в `/etc/fstab` и смонтированная точка
  `yandex_disk_mount_point`.
- Services: `yandex-disk.service` (systemd).
- Users/groups: не создаются и не меняются; роль только читает их id.

## Переменные

| Variable | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `yandex_disk_mount_source` | string | yes | `null` | UNC-путь шары (`//host/share`). Без него роль падает на assert. |
| `vault_yandex_disk_oauth_token` | string | yes | — | Содержимое файла токена клиента (blob целиком). Только `VARS/secrets.yml`. |
| `yandex_disk_mount_point` | string | no | `"/mnt/yandex"` | Точка монтирования шары. |
| `yandex_disk_samba_username` | string | no | `"yandex"` | Учётная запись SMB для монтирования. |
| `yandex_disk_samba_password_var` | string | yes | `"yandex_disk_samba_password"` | Имя переменной с паролем SMB; значение берётся из `VARS/secrets.yml` по имени. |
| `yandex_disk_samba_domain` | string | no | `"WORKGROUP"` | Workgroup в credentials-файле. |
| `yandex_disk_mount_fstype` | string | no | `"cifs"` | Тип ФС монтирования. |
| `yandex_disk_smb_version` | string | no | `"3.0"` | Диалект SMB. |
| `yandex_disk_credentials_path` | string | no | `"/etc/yandex-disk/smbcredentials"` | Файл учётных данных для mount.cifs. |
| `yandex_disk_mount_file_mode` | string | no | `"0664"` | Режим файлов на шаре. |
| `yandex_disk_mount_dir_mode` | string | no | `"2775"` | Режим каталогов на шаре. |
| `yandex_disk_mount_static_options` | list | no | `[iocharset=utf8, _netdev, nofail]` | Статические опции CIFS. |
| `yandex_disk_service_user` | string | no | `"yandex"` | Учётная запись демона (создаётся вне роли). |
| `yandex_disk_service_group` | string | no | `"nas"` | Группа демона. |
| `yandex_disk_config_dir` | string | no | `"/etc/yandex-disk"` | Каталог конфигурации. |
| `yandex_disk_config_path` | string | no | `"/etc/yandex-disk/config.cfg"` | Путь config.cfg. |
| `yandex_disk_auth_path` | string | no | `"/etc/yandex-disk/passwd"` | Файл OAuth-токена (ключ `auth`). |
| `yandex_disk_sync_dir` | string | no | mount point | Локальная копия Диска (ключ `dir`). |
| `yandex_disk_exclude_dirs` | list | no | `[]` | Исключаемые каталоги (`exclude-dirs`). |
| `yandex_disk_service_name` | string | no | `"yandex-disk"` | Имя systemd-юнита. |
| `yandex_disk_service_state` | string | no | `"started"` | Устойчивое состояние (`started`/`stopped`). |
| `yandex_disk_service_enabled` | boolean | no | `true` | Автозапуск юнита. |
| `yandex_disk_binary_path` | string | no | `"/usr/bin/yandex-disk"` | Бинарник клиента. |
| `yandex_disk_restart_sec` | int | no | `30` | `RestartSec` юнита. |
| `yandex_disk_repository_*` | string | no | см. defaults | URL/ключ/имя APT-репозитория. |
| `yandex_disk_architecture` | string | no | `"amd64"` | Архитектура в строке deb. |
| `yandex_disk_packages` | list | no | `[yandex-disk, cifs-utils]` | Устанавливаемые пакеты. |
| `yandex_disk_debug_mode` | boolean | no | `false` | Debug-вывод после значимых изменений. |

## Использование

```yaml
---
- name: Configure Yandex Disk sync
  hosts: yandex
  become: true
  vars_files:
    - ../VARS/secrets.yml   # vault_yandex_disk_* и пароль SMB
  roles:
    - role: yandex_disk
      vars:
        yandex_disk_mount_source: "//172.25.40.44/yandex"
        yandex_disk_samba_password_var: "nas_server_samba_password"
```

Полный сценарий с созданием LXC — `playbooks/lxc.install.yandex_disk.yml`
приватного репозитория.

## Check mode и diff mode

Роль поддерживает `--check --diff`: все таски либо предсказывают изменение,
либо помечены `no_log`/`diff: false`. `getent` только читает. Замечание: при
первом прогоне `--check` на пустой системе задача монтирования опирается на
uid/gid из `getent`, поэтому учётная запись должна существовать уже в момент
check (она создаётся `base_add_users` в том же playbook раньше).

## Зависимости

- Роли: учётная запись и группа демона ожидаются от `base_add_users`.
- Коллекции: `ansible.posix` (модуль `mount`), зафиксирована в project-level `requirements.yml`.
- Внешние сервисы: APT-репозиторий `repo.yandex.ru`, SMB-сервер с шарой.
- Секреты: `vault_yandex_disk_oauth_token` и переменная, названная
  `yandex_disk_samba_password_var`, — из `VARS/secrets.yml`, подключённого
  через `vars_files` в play.

## Handlers

- `Restart yandex-disk` — `daemon_reload` + restart юнита; срабатывает по
  `notify` от изменений `config.cfg`, `passwd` и unit-файла. Пропускается,
  когда `yandex_disk_service_state: "stopped"`.

## Tags

- `debug` — на всех debug-тасках (`--skip-tags debug`).

## Примечания

- OAuth-токен нельзя получить неинтерактивно: `yandex-disk token` просит
  открыть `https://ya.ru/device` и ввести показанный код (живёт ~300 секунд).
  Получите токен один раз на любой машине с установленным клиентом и впишите
  содержимое созданного файла `~/.config/yandex-disk/passwd` (одна строка
  целиком) в `vault_yandex_disk_oauth_token`. Если сервер отвергает записанный
  токен (демон сообщает об ошибке авторизации), выполните `yandex-disk token`
  внутри контейнера и скопируйте полученный файл поверх `yandex_disk_auth_path`.
- Задачи с паролем SMB и токеном выполняются с `no_log: true` и
  `diff: false`; их значения нельзя выводить через debug.
- Демон перезапускается только handler'ом по изменениям; устойчивое состояние
  задаёт `yandex_disk_service_state`.
- В systemd-юните `RequiresMountsFor` гарантирует, что демон не стартует на
  пустой точке монтирования.
