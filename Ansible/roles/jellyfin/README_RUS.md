# jellyfin

Роль устанавливает медиа-сервер Jellyfin на хост Debian из официального
APT-репозитория `repo.jellyfin.org`, ставит пакеты аппаратного
транскодирования VAAPI и открывает сервисной учетной записи доступ к
`/dev/dri` через группы устройств.

Выбрана нативная установка из APT, а не Docker: официальный репозиторий
Jellyfin является поддерживаемым upstream-путем для Debian и даёт меньше
подвижных частей внутри LXC, где сервис — единственный. Проброс `/dev/dri` в
контейнер выполняет провижининг Proxmox; роль только ставит драйверы и
добавляет пользователя `jellyfin` в группы устройств.

## Что делает

- Проверяет платформу Debian и структуру входных списков ранним
  `ansible.builtin.assert` до первого изменения.
- Загружает armored-ключ подписи в `/etc/apt/keyrings/jellyfin.asc` и
  регистрирует репозиторий `deb [arch=amd64 signed-by=...]
  https://repo.jellyfin.org/debian <release> main` для текущего релиза
  Debian.
- Устанавливает пакеты `jellyfin_packages` (метапакет `jellyfin`, который
  подтягивает `jellyfin-server`, `jellyfin-web` и `jellyfin-ffmpeg`) и
  `jellyfin_transcoding_packages` (драйвер VAAPI и диагностику).
- Создает каталоги из `jellyfin_media_dirs` как точки монтирования; сами
  bind-монтирования и наполнение медиа — задача провижининга, роль не
  управляет их содержимым и правами внутри.
- Создает группы устройств `jellyfin_device_groups` при отсутствии и
  добавляет в них пользователя `jellyfin_service_user`; изменение групп
  перезапускает сервис через handler, чтобы сервер подхватил доступ к
  рендерингу.
- Управляет сервисом `jellyfin` (состояние и автозапуск).
- Не управляет конфигурацией Jellyfin (`system.xml`, `encoding.xml`,
  библиотеки, пользователи): выбор VAAPI и остальные настройки выполняются в
  админ-панели и выходят за рамки роли.

## Требования

- Целевая ОС: Debian 13 (LXC).
- `become: true` для установки пакетов и управления пользователями.
- Исходящий HTTPS-доступ к `repo.jellyfin.org`.
- Для аппаратного транскодирования — проброшенный провижинингом `/dev/dri`;
  роль проверяет только членство в группах, наличие устройства не требует.

## Изменяемые ресурсы

- Packages: `ca-certificates`, `python3-apt`, `jellyfin_packages`,
  `jellyfin_transcoding_packages`.
- Files: `/etc/apt/keyrings/jellyfin.asc`,
  `/etc/apt/sources.list.d/jellyfin.list`, каталоги `jellyfin_media_dirs`.
- Services: `jellyfin` (systemd-юнит `jellyfin.service`).
- Users/groups: группы `jellyfin_device_groups` (создаются при отсутствии);
  пользователь `jellyfin_service_user` добавляется в эти группы.
- Firewall/API objects: none (Jellyfin слушает порт 8096 по умолчанию,
  конфигурацией порта роль не управляет).

## Переменные

| Variable | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `jellyfin_debug_mode` | boolean | no | `false` | Включает debug-вывод после значимых изменений. |
| `jellyfin_repository_url` | string | no | `"https://repo.jellyfin.org/debian"` | URL официального APT-репозитория Jellyfin. |
| `jellyfin_repository_key_url` | string | no | `"https://repo.jellyfin.org/debian/jellyfin_team.gpg.key"` | URL armored-ключа подписи репозитория. |
| `jellyfin_repository_keyring` | string | no | `"/etc/apt/keyrings/jellyfin.asc"` | Локальный путь ключа подписи. |
| `jellyfin_repository_filename` | string | no | `"jellyfin"` | Имя файла источника в `/etc/apt/sources.list.d`. |
| `jellyfin_repository_component` | string | no | `"main"` | Компонент репозитория. |
| `jellyfin_apt_architecture` | string | no | `"amd64"` | APT-архитектура пакетов. |
| `jellyfin_packages` | list | no | `["jellyfin"]` | Пакеты из репозитория Jellyfin. |
| `jellyfin_transcoding_packages` | list | no | `["libva2", "libva-drm2", "mesa-va-drivers", "vainfo"]` | Драйверы VAAPI и диагностика; дефолт рассчитан на AMD iGPU (Ryzen 7 8700G), на Intel замените на `intel-media-va-driver`. |
| `jellyfin_service_user` | string | no | `"jellyfin"` | Сервисная учетная запись, созданная пакетом. |
| `jellyfin_device_groups` | list | no | `["render", "video"]` | Группы устройств для доступа к `/dev/dri`. |
| `jellyfin_media_dirs` | list | no | `[]` | Каталоги-точки монтирования медиа; реальные пути задаются приватным репозиторием. |
| `jellyfin_service_name` | string | no | `"jellyfin"` | Имя systemd-юнита. |
| `jellyfin_service_state` | string | no | `"started"` | Желаемое устойчивое состояние: `started` или `stopped`. |
| `jellyfin_service_enabled` | boolean | no | `true` | Автозапуск сервиса при загрузке. |

Секретов и обязательных переменных без дефолта у роли нет.

## Использование

```yaml
---
- name: Deploy Jellyfin
  hosts: jellyfin
  become: true
  roles:
    - role: jellyfin
      vars:
        jellyfin_media_dirs:
          - "/media"
```

## Handlers

- `Restart Jellyfin server` — перезапускает сервис при изменении групп
  устройств сервисной учетной записи.

## Check mode и diff mode

Роль поддерживает запуск:

```bash
ansible-playbook playbook.yml --check --diff
```

На хосте, где репозиторий Jellyfin ещё не зарегистрирован, задача установки
пакетов в check mode пропускается: спрогнозированный репозиторий нельзя
проиндексировать. Зависящие от пакета шаги (пользователь `jellyfin`, сервис)
на первом прогнозном прогоне могут давать неточный прогноз; после реального
прогона check mode отражает состояние корректно.

## Зависимости

- None (используются только модули `ansible.builtin`).

## Примечания

- Выбор VAAPI-транскодирования, библиотеки медиа, пользователи и сетевые
  настройки конфигурируются в админ-панели Jellyfin; роль ими не управляет.
- Значение `jellyfin_transcoding_packages` по умолчанию соответствует iGPU
  AMD процессора Ryzen 7 8700G (`mesa-va-drivers`); `vainfo` оставлен в
  списке для проверки VAAPI вручную (`vainfo` от пользователя в группе
  `render`).
- Повторный прогон идемпотентен: уже установленные пакеты, группы и точки
  монтирования не дают изменений.
