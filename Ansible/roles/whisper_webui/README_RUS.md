# whisper_webui

Роль разворачивает [Whisper-WebUI](https://github.com/jhj0517/Whisper-WebUI) —
веб-интерфейс распознавания речи в текст поверх faster-whisper с инференсом на
CPU. В HomeLab роль применяется к LXC `stt` (`172.25.40.204`) на pve-main;
интерфейс публикуется через Traefik как `stt.dragons-nest.home.arpa`.

## Что делает

- Ставит системные пакеты: `git`, `ffmpeg`, `rubberband-cli`, Python и
  инструментарий сборки.
- Создаёт системную учётную запись и каталог данных `/opt/whisper-webui-data`
  (модели и результаты — вне версионированного дерева).
- Скачивает tarball релиза Whisper-WebUI в `/opt/Whisper-WebUI-<version>` и
  переключает на него симлинк `/opt/whisper-webui`.
- Исправляет `requirements.txt`: заменяет CUDA-индекс PyTorch на CPU и
  закрепляет git+-зависимости на проверенных коммитах
  (`whisper_webui_pinned_git_deps`), чтобы pip-прогон был идемпотентен.
- Форк `jhj0517-whisper` ставится из локального клона
  `/opt/whisper-webui-build` с пропатченным `setup.py`: его
  `exec()`/`locals()`-чтение версии несовместимо с Python 3.13 (PEP 667), а
  `pkg_resources` требует `setuptools<81` в сборочном окружении
  (`PIP_CONSTRAINT`).
- Собирает venv и ставит Python-зависимости (PyTorch CPU, faster-whisper,
  gradio, pyannote, UVR).
- Рендерит `configs/default_parameters.yaml` (предвыбранные модель, язык, VAD,
  токен диаризации) и systemd-юнит `whisper-webui.service`.
- Предзагружает перечисленные модели faster-whisper в общий каталог данных.
- Управляет состоянием сервиса; перезапуск — через handler.

## Требования

- Целевая ОС: Debian (проверяется assert; развёртывание лаборатории — Debian 13).
- `become: true`; `become_user` используется для предзагрузки моделей (sudo
  ставится ролью `base_install_packages` раньше в playbook).
- Доступ хоста в интернет: tarball с GitHub, пакеты pip, модели с Hugging Face.
- Секреты передаются только именами переменных из `VARS/secrets.yml`.

## Изменяемые ресурсы

- Packages: `git`, `ffmpeg`, `rubberband-cli`, `python3`, `python3-dev`,
  `python3-venv`, `python3-packaging`, `build-essential`, `ca-certificates`
- Files: `/opt/Whisper-WebUI-<version>/`, симлинк `/opt/whisper-webui`,
  `/opt/whisper-webui-data`, `requirements.txt` внутри дерева,
  `configs/default_parameters.yaml`, `/etc/systemd/system/whisper-webui.service`
- Services: `whisper-webui`
- Users/groups: системная учётная запись `stt` (по умолчанию)
- Firewall/API objects: none

## Переменные

| Variable | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `whisper_webui_debug_mode` | bool | no | `false` | Debug-вывод после изменений. |
| `whisper_webui_version` | string | no | `"1.0.8"` | Выпуск Whisper-WebUI без ведущей `v`. |
| `whisper_webui_download_url` | string | no | GitHub tarball | URL архива релиза. |
| `whisper_webui_release_dir` | string | no | `/opt/Whisper-WebUI-<version>` | Каталог распакованного выпуска. |
| `whisper_webui_pinned_git_deps` | dict | no | см. defaults | Коммиты для git+-зависимостей; пересматривать при обновлении версии. |
| `whisper_webui_whisper_fork_commit` | string | no | `19724431…` | Закреплённый коммит форка jhj0517-whisper. |
| `whisper_webui_build_root` | string | no | `"/opt/whisper-webui-build"` | Каталог пропатченного клона форка. |
| `whisper_webui_build_constraints` | string | no | `"setuptools<81"` | Содержимое `PIP_CONSTRAINT`-файла сборки. |
| `whisper_webui_install_root` | string | no | `"/opt/whisper-webui"` | Симлинк на каталог выпуска. |
| `whisper_webui_data_root` | string | no | `"/opt/whisper-webui-data"` | Модели и результаты вне дерева релиза. |
| `whisper_webui_system_user` | string | no | `"stt"` | Системная учётная запись сервиса. |
| `whisper_webui_packages` | list | no | см. defaults | Системные пакеты. |
| `whisper_webui_pip_extra_index_url` | string | no | `https://download.pytorch.org/whl/cpu` | Индекс wheel PyTorch (CPU). |
| `whisper_webui_server_name` | string | no | `"0.0.0.0"` | Адрес прослушивания Gradio. |
| `whisper_webui_server_port` | int | no | `7860` | Порт Gradio. |
| `whisper_webui_root_path` | string | no | `""` | Публичный подпуть за прокси. |
| `whisper_webui_auth_user_var` | string/null | no | `null` | Имя переменной с логином basic-auth; оба или ни одного. |
| `whisper_webui_auth_password_var` | string/null | no | `null` | Имя переменной с паролем basic-auth. |
| `whisper_webui_default_model` | string | no | `"large-v3-turbo"` | Предвыбранная модель faster-whisper. |
| `whisper_webui_default_language` | string | no | `"Russian"` | Предвыбранный язык распознавания. |
| `whisper_webui_default_file_format` | string | no | `"SRT"` | Предвыбранный формат выдачи. |
| `whisper_webui_vad_filter` | bool | no | `true` | Предвыбор фильтра Silero VAD. |
| `whisper_webui_diarization_token_var` | string/null | no | `null` | Имя переменной с HF-токеном для pyannote. |
| `whisper_webui_preload_models` | list | no | `["large-v3-turbo"]` | Модели для предзагрузки при развёртывании. |
| `whisper_webui_cpu_threads` | int | no | `4` | `OMP_NUM_THREADS` для инференса. |
| `whisper_webui_service_state` | string | no | `"started"` | Устойчивое состояние сервиса. |
| `whisper_webui_service_enabled` | bool | no | `true` | Автозапуск сервиса. |

## Использование

```yaml
---
- name: Install Whisper-WebUI
  hosts: stt
  become: true
  vars_files:
    - ../VARS/secrets.yml
  roles:
    - role: whisper_webui
      vars:
        whisper_webui_cpu_threads: 8
        whisper_webui_auth_user_var: vault_whisper_webui_admin_user
        whisper_webui_auth_password_var: vault_whisper_webui_admin_password
```

## Check mode и diff mode

Роль в целом работает с `--check --diff`: пакеты, каталоги, шаблоны и сервис
отчитываются о прогнозируемых изменениях. Ограничения:

- `unarchive` и `command` (venv, предзагрузка моделей) в check mode пропускаются
  без выполнения — это внешние загрузки, прогнозировать их нельзя.
- Шаблоны с секретами и юнит записываются с `no_log`/`diff: false`, поэтому diff
  по ним не показывается.

## Зависимости

- None. В playbook роль идёт после `base_install_packages` и `base_set_locale`.

## Примечания

- Basic-auth пароль передаётся аргументом командной строки и виден в списке
  процессов на хосте; юнит при этом читаем только root. Это барьер на случай,
  настоящая граница доступа — Traefik + Keycloak.
- Диаризация (pyannote) требует HF-токен с принятыми условиями моделей
  `pyannote/speaker-diarization-3.1` и `pyannote/segmentation-3.0`; без
  `whisper_webui_diarization_token_var` функция в UI не работает.
- CUDA-индекс в `requirements.txt` заменяется на CPU: контейнер без GPU.
- При обновлении `whisper_webui_version` сверить и перезакрепить коммиты в
  `whisper_webui_pinned_git_deps` и шаблон `default_parameters.yaml` с апстримом.
- Сервис публикуется отдельно через Traefik как `stt.dragons-nest.home.arpa`;
  маршрут и Host Override на pfSense настраиваются вне этой роли.
