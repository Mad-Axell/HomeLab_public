# homepage

Роль разворачивает gethomepage — единую витрину сервисов — как проект Docker
Compose v2 на целевом хосте с уже установленным Docker и генерирует
конфигурационные YAML-файлы из входных переменных.

Выбран Docker, а не сборка `git clone` + `pnpm build`: панель живёт в
отдельном LXC, и контейнер с готовым образом даёт меньше подвижных частей
(нет toolchain Node.js/pnpm на целевой машине, обновление сводится к смене
тега). Вся конфигурация Homepage — обычные YAML-файлы, которые роль пишет в
каталог, смонтированный в `/app/config`.

## Что делает

- Проверяет платформу Debian и структуру входных переменных ранним
  `ansible.builtin.assert` до первого изменения.
- Создает каталог проекта Compose и каталог конфигурации
  `homepage_config_dir`.
- Генерирует `compose.yml` из шаблона: образ, имя контейнера, публикация
  порта, bind-монтирование `homepage_config_dir` в `/app/config`, опциональный
  `HOMEPAGE_ALLOWED_HOSTS` и произвольные `homepage_env`. Шаблон может нести
  секреты `HOMEPAGE_VAR_*`, поэтому задача использует `diff: false`.
- Генерирует `services.yaml`, `widgets.yaml` и `settings.yaml` в
  `homepage_config_dir` через `to_nice_yaml` — входные структуры
  соответствуют формату upstream один в один, без собственной схемы роли.
- Приводит проект к состоянию `homepage_state` через
  `community.docker.docker_compose_v2`. При изменении `compose.yml` или файлов
  конфигурации контейнер пересоздается/перезапускается модулем, поэтому
  handler для restart не используется.
- Не заполняет каталог сервисов сама: состав групп и виджетов — данные
  приватного репозитория, передаваемые через `homepage_services`,
  `homepage_widgets` и `homepage_settings`.

## Требования

- Целевая ОС: Debian 13 (LXC).
- Docker Engine и Compose v2 plugin на целевом хосте; их ставит роль
  `docker`, роль `homepage` Docker не устанавливает.
- `become: true` для создания каталогов и работы с Docker.
- Коллекция `community.docker`, зафиксированная в project-level
  `requirements.yml`.

## Изменяемые ресурсы

- Packages: none.
- Files: `compose.yml` в `homepage_project_directory`; `services.yaml`,
  `widgets.yaml`, `settings.yaml` в `homepage_config_dir`.
- Services: контейнер Homepage через Docker Compose.
- Users/groups: none.
- Firewall/API objects: публикуемый контейнером порт `homepage_port`.

## Переменные

| Variable | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `homepage_debug_mode` | boolean | no | `false` | Включает debug-вывод после значимых изменений. |
| `homepage_state` | string | no | `"present"` | Требуемое состояние проекта Compose: `present` или `absent`. |
| `homepage_project_directory` | string | no | `"/opt/homepage"` | Каталог проекта Compose с `compose.yml`. |
| `homepage_config_dir` | string | no | `"/opt/homepage/config"` | Каталог хоста, монтируемый в контейнер как `/app/config`. |
| `homepage_image` | string | no | `"ghcr.io/gethomepage/homepage:latest"` | Образ контейнера Homepage. |
| `homepage_container_name` | string | no | `"homepage"` | Имя контейнера Homepage. |
| `homepage_port` | integer | no | `3000` | Порт хоста, публикующий веб-интерфейс (внутри контейнера порт 3000). |
| `homepage_allowed_hosts` | string | no | `null` | Имена через запятую для `HOMEPAGE_ALLOWED_HOSTS`; при null доступен только localhost. |
| `homepage_env` | dict | no | `{}` | Дополнительные переменные окружения, включая секреты `HOMEPAGE_VAR_*`. |
| `homepage_services` | list | no | `[]` | Группы сервисов в формате upstream `services.yaml`. |
| `homepage_widgets` | list | no | `[]` | Виджеты верхнего уровня в формате upstream `widgets.yaml`. |
| `homepage_settings` | dict | no | `{}` | Глобальные настройки для `settings.yaml`. |

Обязательных переменных без дефолта и секретов у роли нет; секретные ключи
API виджетов передаются через `homepage_env` как `HOMEPAGE_VAR_*` из
приватного репозитория.

## Использование

```yaml
---
- name: Deploy Homepage
  hosts: homepage
  become: true
  roles:
    - role: docker
    - role: homepage
      vars:
        homepage_allowed_hosts: "homepage.dragons-nest.home.arpa,172.25.40.14"
        homepage_settings:
          title: "Dragons Nest"
          theme: "dark"
        homepage_services:
          - Monitoring:
              - Uptime Kuma:
                  href: "https://uptime.dragons-nest.home.arpa"
                  icon: "uptime-kuma.png"
        homepage_widgets:
          - uptimekuma:
              url: "https://uptime.dragons-nest.home.arpa"
              slug: "status"
```

## Check mode и diff mode

Роль поддерживает запуск:

```bash
ansible-playbook playbook.yml --check --diff
```

`ansible.builtin.file` и шаблоны конфигурации корректно показывают diff.
Задача рендера `compose.yml` использует `diff: false`, потому что
`homepage_env` может содержать секреты `HOMEPAGE_VAR_*`.
`community.docker.docker_compose_v2` поддерживает check mode частично:
достоверность прогнозируемых изменений зависит от Docker daemon, поэтому
итог check-прогона для задачи развертывания следует считать оценкой.

## Зависимости

- Коллекция `community.docker` (project-level `requirements.yml`).
- Роль `docker` как предусловие на уровне playbook; `meta`-зависимость не
  используется, порядок ролей задает playbook.

## Примечания

- `homepage_services`, `homepage_widgets` и `homepage_settings`
  рендерятся в upstream-формате дословно: ключи групп, сервисов и опций
  соответствуют документации gethomepage, роль не трансформирует структуру.
- Секретные ключи API (Sonarr, Plex, WUD и т.п.) не пишите в YAML напрямую:
  объявите их в `homepage_env` как `HOMEPAGE_VAR_<name>` и ссылайтесь из
  YAML-файлов плейсхолдером `{{HOMEPAGE_VAR_<name>}}` — тогда файлы
  конфигурации остаются несекретными и читаемыми в diff.
- `HOMEPAGE_ALLOWED_HOSTS` обязателен upstream при доступе по имени хоста:
  без него Homepage отвечает ошибкой «host not allowed» для любого имени,
  кроме localhost.
- Повторный прогон идемпотентен: проект и файлы, уже находящиеся в требуемом
  состоянии, не дают изменений.
- Состояние `absent` останавливает и удаляет контейнеры проекта, но файлы
  `compose.yml` и конфигурации на диске сохраняются.
