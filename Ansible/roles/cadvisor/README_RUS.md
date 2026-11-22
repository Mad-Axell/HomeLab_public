# cadvisor

Роль разворачивает cAdvisor как проект Docker Compose v2 на целевом хосте с уже установленным Docker и приводит контейнер к требуемому состоянию. cAdvisor публикует метрики контейнеров (CPU, память, сеть, файловые системы) на порту 8080 для сбора Prometheus.

## Что делает

- Создает каталог проекта Compose.
- Генерирует `compose.yml` из шаблона: образ с зафиксированным тегом, имя контейнера, режим `privileged`, внутренний набор read-only bind-монтирований хоста (`/`, `/var/run`, `/sys`, `/var/lib/docker`, `/dev/disk` и сокет Docker), публикация порта и опциональные дополнительные переменные окружения.
- Приводит проект к состоянию `cadvisor_state` через `community.docker.docker_compose_v2`.
- При изменении `compose.yml` модуль пересоздает контейнер автоматически (`recreate` по умолчанию), поэтому отдельный handler для restart не используется.
- Не устанавливает Docker и не настраивает scrape-задания Prometheus: сбор метрик настраивается на стороне Prometheus и выходит за рамки роли.

## Требования

- Целевая ОС: Debian 13 (LXC), проверяется `ansible_facts.os_family == 'Debian'` до внесения изменений.
- Docker Engine и Compose v2 plugin на целевом хосте; их ставит роль `docker`, роль `cadvisor` Docker не устанавливает.
- `become: true` для создания каталогов и работы с Docker.
- Коллекция `community.docker`, зафиксированная в project-level `requirements.yml`.
- Порт `cadvisor_port`, доступный с хоста Prometheus на целевом хосте.

## Изменяемые ресурсы

- Packages: none.
- Files: `compose.yml` в `cadvisor_project_directory`.
- Services: контейнер cAdvisor через Docker Compose.
- Users/groups: none.
- Firewall/API objects: публикуемый контейнером порт `cadvisor_port`.

## Переменные

| Variable | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `cadvisor_debug_mode` | boolean | no | `false` | Включает debug-вывод после значимых изменений. |
| `cadvisor_state` | string | no | `"present"` | Требуемое состояние проекта Compose: `present` или `absent`. |
| `cadvisor_project_directory` | string | no | `"/opt/cadvisor"` | Каталог проекта Compose с `compose.yml`. |
| `cadvisor_image` | string | no | `"gcr.io/cadvisor/cadvisor:v0.49.2"` | Образ cAdvisor с зафиксированным тегом релиза; переопределяется при необходимости в новом пине. |
| `cadvisor_container_name` | string | no | `"cadvisor"` | Имя контейнера cAdvisor. |
| `cadvisor_port` | integer | no | `8080` | Порт хоста, публикующий endpoint метрик cAdvisor. |
| `cadvisor_privileged` | boolean | no | `true` | Привилегированный режим контейнера; требуется cAdvisor для полного набора метрик хоста и контейнеров. |
| `cadvisor_docker_socket` | string | no | `"/var/run/docker.sock"` | Путь на хосте к сокету Docker, монтируемый в контейнер в режиме read-only. |
| `cadvisor_volume_map` | list of strings | no | см. `defaults/main.yml` | Внутренний набор read-only bind-монтирований, необходимых cAdvisor; не предназначен для регулярных переопределений. |
| `cadvisor_extra_environment` | dictionary | no | `{}` | Дополнительные несекретные переменные окружения контейнера; секреты здесь размещать нельзя. |

Обязательных переменных без дефолта и секретов у роли нет.

## Использование

```yaml
---
- name: Deploy cAdvisor
  hosts: docker_hosts
  become: true
  roles:
    - role: docker
    - role: cadvisor
      vars:
        cadvisor_port: 8080
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

- Секреты не требуются: cAdvisor отдает метрики без аутентификации, поэтому порт `cadvisor_port` следует ограничить сетью мониторинга или хостом Prometheus.
- cAdvisor предоставляет веб-интерфейс на `http://<host>:<cadvisor_port>/` и endpoint метрик Prometheus на `http://<host>:<cadvisor_port>/metrics`.
- Привилегированный режим и read-only монтирования хоста обязательны для полного набора метрик; отключение `cadvisor_privileged` или удаление монтирований ухудшает собираемые данные.
- Повторный прогон идемпотентен: проект, уже находящийся в требуемом состоянии, не дает изменений.
- Состояние `absent` останавливает и удаляет контейнер проекта, но файл `compose.yml` на диске сохраняется.
