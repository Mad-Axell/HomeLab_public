# cockpit

Роль устанавливает Cockpit и модуль `cockpit-storaged`, включает socket-активацию веб-интерфейса и при непустом `cockpit_45drives_packages` подключает APT-репозиторий 45Drives и ставит из него дополнительные модули (по умолчанию файловый менеджер `cockpit-navigator`). Управление экспортом Samba/NFS остается в роли `nas_server`.

## Что делает

- Устанавливает Cockpit и интерфейс управления дисками из уже настроенных репозиториев Debian.
- Включает и запускает `cockpit.socket`.
- Скачивает ключ подписи 45Drives в `/usr/share/keyrings/45drives-archive-keyring.gpg`.
- Создает `/etc/apt/sources.list.d/45drives.sources` (deb822, подпись `signed-by` ключом выше) и ставит пакеты из `cockpit_45drives_packages` — по умолчанию `cockpit-navigator`, файловый менеджер в веб-интерфейсе Cockpit.

## Требования

- Debian/Ubuntu с собранными Ansible facts.
- `become: true`.
- Доступные и доверенные APT-репозитории с указанными пакетами.
- При непустом `cockpit_45drives_packages` — исходящий HTTPS-доступ к `repo.45drives.com`; Ansible core >= 2.15 (модуль `deb822_repository`).

## Изменяемые ресурсы

- Packages: `cockpit`, `cockpit-storaged`, пакеты из `cockpit_packages` и `cockpit_45drives_packages`.
- Files: `/usr/share/keyrings/45drives-archive-keyring.gpg`, `/etc/apt/sources.list.d/45drives.sources`, индекс APT в `/var/lib/apt/lists`.
- Services: `cockpit.socket`.
- Users/groups, firewall/API objects: не управляются. Доступ к TCP 9090 настраивается отдельной ролью файрвола.

## Переменные

| Variable | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `cockpit_debug_mode` | boolean | no | `false` | Показывает сводку об изменении. |
| `cockpit_packages` | list | no | `['cockpit', 'cockpit-storaged']` | Пакеты Cockpit из настроенных APT-репозиториев. |
| `cockpit_cache_valid_time` | integer | no | `3600` | Срок актуальности индекса APT в секундах. |
| `cockpit_socket_name` | string | no | `"cockpit.socket"` | Управляемый socket unit systemd. |
| `cockpit_45drives_packages` | list | no | `['cockpit-navigator']` | Дополнительные модули Cockpit из репозитория 45Drives; пустой список отключает подключение репозитория и установку модулей. |
| `cockpit_45drives_repo_key_url` | string | internal | `"https://repo.45drives.com/key/gpg.asc"` | URL ключа подписи репозитория 45Drives. |
| `cockpit_45drives_repo_key_path` | string | internal | `"/usr/share/keyrings/45drives-archive-keyring.gpg"` | Путь ключевого файла подписи. |
| `cockpit_45drives_repo_uri` | string | internal | `"https://repo.45drives.com/debian"` | URI APT-репозитория. |
| `cockpit_45drives_repo_suites` | list | internal | `['focal']` | Сьюты репозитория 45Drives. |
| `cockpit_45drives_repo_components` | list | internal | `['main']` | Компоненты репозитория 45Drives. |

## Использование

```yaml
---
- name: Configure Cockpit storage management
  hosts: samba
  become: true
  roles:
    - role: cockpit
```

Без дополнительных модулей 45Drives:

```yaml
  roles:
    - role: cockpit
      vars:
        cockpit_45drives_packages: []
```

## Check mode и diff mode

Установка пакетов, `get_url`, `deb822_repository` и управление socket unit поддерживают `--check`; содержательный diff не выводится. В `--check` на первом прогоне установка `cockpit_45drives_packages` пропускается: прогнозно созданный репозиторий не попадает в индекс APT; когда репозиторий уже существует, проверка пакетов выполняется как обычно. Роль не выполняет HTTP-проверок и не открывает firewall-порт.

## Зависимости

- None.

## Примечания

- Репозиторий 45Drives подключается декларативно: ключ скачивается `get_url` по HTTPS, источник описывается `deb822_repository` с `signed-by`. Прежний сценарий через неподтвержденный `curl | bash` не используется.
- Сьюта репозитория — `focal`: пакеты 45Drives универсальные (`all`), официально поддерживается Debian 13/Proxmox trixie.
- `cockpit-navigator` — только файловый менеджер; он не изменяет `smb.conf` и не влияет на шары, которыми владеет `nas_server`.
