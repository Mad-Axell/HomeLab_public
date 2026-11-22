# uptime

Роль разворачивает Uptime Kuma как проект Docker Compose v2 на целевом хосте с уже установленным Docker и приводит контейнер к требуемому состоянию.

## Что делает

- Создает каталог проекта Compose и каталог постоянных данных.
- Генерирует `compose.yml` из шаблона с образом, именем контейнера, публикацией порта и bind-монтированием данных.
- Приводит проект к состоянию `uptime_state` через `community.docker.docker_compose_v2`.
- При изменении `compose.yml` модуль пересоздает контейнер автоматически (`recreate` по умолчанию), поэтому отдельный handler для restart не используется.
- Не создает мониторы, статус-страницы, каналы уведомлений и учетную запись администратора: они настраиваются вручную в веб-интерфейсе Uptime Kuma или через его API и выходят за рамки роли.

## Требования

- Целевая ОС: Debian 13 (LXC).
- Docker Engine и Compose v2 plugin на целевом хосте; их ставит роль `docker`, роль `uptime` Docker не устанавливает.
- `become: true` для создания каталогов и работы с Docker.
- Коллекция `community.docker`, зафиксированная в project-level `requirements.yml`.

## Изменяемые ресурсы

- Packages: none.
- Files: `compose.yml` в `uptime_project_directory`, каталог данных `uptime_kuma_data_dir`.
- Services: контейнер Uptime Kuma через Docker Compose.
- Users/groups: none.
- Firewall/API objects: публикуемый контейнером порт `uptime_port`.

## Переменные

| Variable | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `uptime_debug_mode` | boolean | no | `false` | Включает debug-вывод после значимых изменений. |
| `uptime_state` | string | no | `"present"` | Требуемое состояние проекта Compose: `present` или `absent`. |
| `uptime_project_directory` | string | no | `"/opt/uptime-kuma"` | Каталог проекта Compose с `compose.yml`. |
| `uptime_kuma_data_dir` | string | no | `"/opt/uptime-kuma/data"` | Каталог хоста, монтируемый в контейнер как `/data`. |
| `uptime_kuma_image` | string | no | `"louislam/uptime-kuma:1"` | Образ Uptime Kuma с зафиксированным тегом. |
| `uptime_container_name` | string | no | `"uptime-kuma"` | Имя контейнера Uptime Kuma. |
| `uptime_port` | integer | no | `3001` | Порт хоста, публикующий веб-интерфейс Uptime Kuma. |

Обязательных переменных без дефолта и секретов у роли нет.

## Использование

```yaml
---
- name: Deploy Uptime Kuma
  hosts: uptime
  become: true
  roles:
    - role: docker
    - role: uptime
      vars:
        uptime_port: 3001
```

## Check mode и diff mode

Роль поддерживает запуск:

```bash
ansible-playbook playbook.yml --check --diff
```

`ansible.builtin.file` и `ansible.builtin.template` корректно показывают diff. `community.docker.docker_compose_v2` поддерживает check mode частично: достоверность прогнозируемых изменений зависит от Docker daemon, поэтому итог check-прогона для задачи развертывания следует считать оценкой.

## Зависимости

- Коллекция `community.docker` (project-level `requirements.yml`).
- Роль `docker` как предусловие на уровне playbook; `meta`-зависимость не используется, порядок ролей задает playbook.

## Примечания

- Секреты для установки не требуются: учетная запись администратора создается при первом входе в веб-интерфейс Uptime Kuma.
- Мониторы HTTP/HTTPS/TCP/ICMP, уведомления (включая Telegram) и статус-страницы настраиваются вручную в веб-интерфейсе или через API Uptime Kuma; роль ими не управляет.
- Повторный прогон идемпотентен: проект, уже находящийся в требуемом состоянии, не дает изменений.
- Состояние `absent` останавливает и удаляет контейнеры проекта, но файлы `compose.yml` и данные на диске сохраняются.
