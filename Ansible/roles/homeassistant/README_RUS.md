# homeassistant

Роль разворачивает Home Assistant Container как проект Docker Compose v2 на выделенном SBC-хосте (Debian) с уже установленным Docker и приводит контейнер к требуемому состоянию. В HomeLab роль применяется к устройству `homeassistant` (172.25.40.202, сеть SERVICES) из `smarthome_group`. Роль ставит только контейнерный вариант продукта: установки Home Assistant OS и Supervised не поддерживаются.

## Что делает

- Проверяет семейство ОС (`Debian`) и непустую ссылку на образ до внесения изменений.
- Создает каталог проекта Compose и каталог постоянной конфигурации.
- Генерирует `compose.yml` из шаблона: образ, имя контейнера, сетевой режим `host` или публикация `homeassistant_port:8123`, bind-монтирование `/config`, проброс устройств, флаг `privileged`, `TZ` и дополнительные переменные окружения.
- Приводит проект к состоянию `homeassistant_state` через `community.docker.docker_compose_v2`.
- При изменении `compose.yml` модуль пересоздает контейнер автоматически (`recreate` по умолчанию), поэтому отдельный handler для restart не используется.
- Не настраивает сам продукт: onboarding, учетную запись, интеграции и MQTT-подключение к центральному Mosquitto (172.25.40.155) выполняют в веб-интерфейсе; содержимое `configuration.yaml` ролью не управляется.

## Требования

- Целевая ОС: семейство Debian (SBC, не Proxmox LXC).
- Docker Engine и Compose v2 plugin на целевом хосте; их ставит роль `docker`, роль `homeassistant` Docker не устанавливает.
- `become: true` для создания каталогов и работы с Docker.
- Коллекция `community.docker`, зафиксированная в project-level `requirements.yml`.

## Изменяемые ресурсы

- Packages: none.
- Files: `compose.yml` в `homeassistant_project_directory`, каталог конфигурации `homeassistant_config_dir`.
- Services: контейнер Home Assistant через Docker Compose.
- Users/groups: none.
- Firewall/API objects: порт `homeassistant_port` при сетевом режиме, отличном от `host`; при `host` контейнер использует сеть хоста напрямую и веб-интерфейс слушает 8123.

## Переменные

| Variable | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `homeassistant_debug_mode` | boolean | no | `false` | Включает debug-вывод после значимых изменений. |
| `homeassistant_state` | string | no | `"present"` | Требуемое состояние проекта Compose: `present` или `absent`. |
| `homeassistant_project_directory` | string | no | `"/opt/homeassistant"` | Каталог проекта Compose с `compose.yml`. |
| `homeassistant_config_dir` | string | no | `"/opt/homeassistant/config"` | Каталог хоста, монтируемый в контейнер как `/config`. |
| `homeassistant_image` | string | no | `"ghcr.io/home-assistant/home-assistant:stable"` | Образ Home Assistant с зафиксированным тегом; подходит и `homeassistant/home-assistant` с Docker Hub. |
| `homeassistant_container_name` | string | no | `"homeassistant"` | Имя контейнера Home Assistant. |
| `homeassistant_network_mode` | string | no | `"host"` | Сетевой режим Docker; `host` включает обнаружение устройств в LAN, иначе публикуется `homeassistant_port`. |
| `homeassistant_port` | integer | no | `8123` | Порт хоста для веб-интерфейса; применяется только при не-host режиме. |
| `homeassistant_timezone` | string or null | no | `null` | Опциональное значение переменной окружения `TZ`; при null не задается. |
| `homeassistant_devices` | list of strings | no | `[]` | Пробрасываемые устройства хоста (Zigbee/Z-Wave USB-координаторы). |
| `homeassistant_extra_volumes` | list of strings | no | `[]` | Дополнительные bind-монтирования. |
| `homeassistant_privileged` | boolean | no | `false` | Привилегированный режим контейнера. |
| `homeassistant_extra_environment` | dict | no | `{}` | Дополнительные несекретные переменные окружения. |

Секретов у роли нет: учетные данные и токены продукта создаются в его веб-интерфейсе и в `configuration.yaml`. Секреты нельзя передавать через `homeassistant_extra_environment`; если в будущем появятся секретные входы, они должны читаться из `VARS/secrets.yml` по имени переменной (`*_var`), а не значением.

## Использование

```yaml
---
- name: Deploy Home Assistant
  hosts: homeassistant
  become: true
  roles:
    - role: docker
    - role: homeassistant
      vars:
        homeassistant_timezone: "Europe/Moscow"
        homeassistant_devices:
          - "/dev/serial/by-id/usb-ITead_Sonoff_Zigbee_Dongle-if00"
        homeassistant_debug_mode: true
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

- Поддерживается только Home Assistant Container; Home Assistant OS и Supervised (supervisord) не входят в область роли.
- MQTT-интеграция с центральным Mosquitto (172.25.40.155:1883) — настройка уровня приложения в веб-интерфейсе Home Assistant; роль ею не управляет. События Frigate и данные WirenBoard приходят через тот же брокер.
- Для проброса Zigbee/Z-Wave стика предпочтителен стабильный путь `/dev/serial/by-id/...`, переживающий переподключение USB.
- Режим `host` рекомендован для обнаружения устройств (mDNS, SSDP, HomeKit); при переходе на bridge доступен только порт `homeassistant_port`, а сетевое обнаружение может перестать работать.
- Состояние `absent` останавливает и удаляет контейнеры проекта, но `compose.yml` и конфигурацию на диске сохраняет.
- Повторный прогон идемпотентен: проект, уже находящийся в требуемом состоянии, не дает изменений.
