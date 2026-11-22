# spruthub

Роль разворачивает Sprut.hub как проект Docker Compose v2 на выделенном SBC-хосте (Debian) с уже установленным Docker и приводит контейнер к требуемому состоянию. В HomeLab роль применяется к устройству `spruthub` (172.25.40.201, сеть SERVICES) из `smarthome_group`.

## Что делает

- Проверяет семейство ОС (`Debian`) и обязательную переменную `spruthub_image` до внесения изменений.
- Создает каталог проекта Compose и каталог постоянных данных.
- Генерирует `compose.yml` из шаблона: образ, имя контейнера, сетевой режим, публикация портов при не-host режиме, bind-монтирование данных, проброс устройств (`devices`), флаг `privileged` и дополнительные переменные окружения.
- Приводит проект к состоянию `spruthub_state` через `community.docker.docker_compose_v2`.
- При изменении `compose.yml` модуль пересоздает контейнер автоматически (`recreate` по умолчанию), поэтому отдельный handler для restart не используется.
- Не настраивает сам продукт: учетную запись, стики, интеграции и MQTT-подключение к центральному Mosquitto (172.25.40.155) выполняют в веб-интерфейсе Sprut.hub; это выходит за рамки роли.

## Требования

- Целевая ОС: семейство Debian (SBC, не Proxmox LXC).
- Docker Engine и Compose v2 plugin на целевом хосте; их ставит роль `docker`, роль `spruthub` Docker не устанавливает.
- `become: true` для создания каталогов и работы с Docker.
- Коллекция `community.docker`, зафиксированная в project-level `requirements.yml`.
- Образ Sprut.hub: вендор распространяет ПО по лицензии, публичного реестра образа нет. `spruthub_image` должен указывать на образ, доступный демону целевого хоста (например, уже загруженный локально на устройстве, либо в реестре, доступном хосту).

## Изменяемые ресурсы

- Packages: none.
- Files: `compose.yml` в `spruthub_project_directory`, каталог данных `spruthub_data_dir`.
- Services: контейнер Sprut.hub через Docker Compose.
- Users/groups: none.
- Firewall/API objects: порты из `spruthub_ports` при сетевом режиме, отличном от `host`; при `host` контейнер использует сеть хоста напрямую.

## Переменные

| Variable | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `spruthub_debug_mode` | boolean | no | `false` | Включает debug-вывод после значимых изменений. |
| `spruthub_state` | string | no | `"present"` | Требуемое состояние проекта Compose: `present` или `absent`. |
| `spruthub_project_directory` | string | no | `"/opt/spruthub"` | Каталог проекта Compose с `compose.yml`. |
| `spruthub_data_dir` | string | no | `"/opt/spruthub/data"` | Каталог хоста, монтируемый как том данных. |
| `spruthub_image` | string | yes | - | Ссылка на образ Sprut.hub с тегом; публичного дефолта нет, значение передает вызывающая сторона. Роль падает до внесения изменений, если переменная не задана. |
| `spruthub_container_name` | string | no | `"spruthub"` | Имя контейнера Sprut.hub. |
| `spruthub_container_data_path` | string | no | `"/data"` | Точка монтирования тома данных внутри контейнера; должна соответствовать образу вендора. |
| `spruthub_network_mode` | string | no | `"host"` | Сетевой режим Docker; `host` нужен для обнаружения устройств в LAN. |
| `spruthub_ports` | list of strings | no | `[]` | Публикации портов "host:container"; применяются только при не-host режиме. |
| `spruthub_devices` | list of strings | no | `[]` | Пробрасываемые устройства хоста (Zigbee/Z-Wave USB-координаторы). |
| `spruthub_extra_volumes` | list of strings | no | `[]` | Дополнительные bind-монтирования. |
| `spruthub_privileged` | boolean | no | `false` | Привилегированный режим контейнера. |
| `spruthub_extra_environment` | dict | no | `{}` | Дополнительные несекретные переменные окружения. |

Секретов у роли нет: учетные данные продукта вводятся в его веб-интерфейсе. Секреты нельзя передавать через `spruthub_extra_environment`; если в будущем появятся секретные входы, они должны читаться из `VARS/secrets.yml` по имени переменной (`*_var`), а не значением.

## Использование

```yaml
---
- name: Deploy Sprut.hub
  hosts: spruthub
  become: true
  roles:
    - role: docker
    - role: spruthub
      vars:
        spruthub_image: "vendor-supplied/image:tag"
        spruthub_devices:
          - "/dev/serial/by-id/usb-SprutStick_ZigBee-if00"
        spruthub_debug_mode: true
```

## Check mode и diff mode

Роль поддерживает запуск:

```bash
ansible-playbook playbook.yml --check --diff
```

`ansible.builtin.file` и `ansible.builtin.template` корректно показывают diff. `community.docker.docker_compose_v2` поддерживает check mode частично: достоверность прогнозируемых изменений зависит от Docker daemon, поэтому итог check-прогона для задачи развертывания следует считать оценкой. Pull образа невозможен, если его нет ни на хосте, ни в доступном реестре.

## Зависимости

- Коллекция `community.docker` (project-level `requirements.yml`).
- Роль `docker` как предусловие на уровне playbook; `meta`-зависимость не используется, порядок ролей задает playbook.

## Примечания

- Sprut.hub CE — лицензируемый продукт вендора: образ и лицензия поставляются через каналы вендора, роль не скачивает и не активирует ПО, она только описывает контейнер.
- MQTT-интеграция с центральным Mosquitto (172.25.40.155) — настройка уровня приложения в веб-интерфейсе Sprut.hub; роль ею не управляет. Домофон и связь с WirenBoard идут через тот же брокер.
- Для проброса Zigbee/Z-Wave стика предпочтителен стабильный путь `/dev/serial/by-id/...`, переживающий переподключение USB.
- Режим `host` — ожидаемый режим хаба (mDNS, HomeKit, обнаружение устройств); при переходе на bridge сетевое обнаружение может перестать работать.
- Состояние `absent` останавливает и удаляет контейнеры проекта, но `compose.yml` и данные на диске сохраняются.
- Повторный прогон идемпотентен: проект, уже находящийся в требуемом состоянии, не дает изменений.
