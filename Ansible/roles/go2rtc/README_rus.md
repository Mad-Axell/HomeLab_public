# go2rtc

Развёртывает **go2rtc** — выделенный шлюз камер — как Docker-контейнер через
Docker Compose v2.

## Что делает роль

1. Проверяет наличие `vault_go2rtc_config` и корректность списка портов.
2. Создаёт каталог проекта и подкаталог `config`.
3. Рендерит `compose.yml` из шаблона `Docker_Compose_Go2rtc.j2`.
4. Записывает `config/go2rtc.yaml` из `vault_go2rtc_config` (секрет, без
   вывода diff и логов).
5. Поднимает или обновляет контейнер через `community.docker.docker_compose_v2`.

## Зачем отдельный контейнер

go2rtc встроен в Frigate, но выделенный экземпляр даёт:

- **одно подключение к камере** — detect, запись, live view Home Assistant и
  ручные проверки тянут один поток из go2rtc, а не четыре RTSP-сессии из камеры;
- **постоянный UI на :1984** — конфиг штатного go2rtc внутри Frigate
  пересоздаётся при каждом старте, у выделенного он стабилен;
- **независимый жизненный цикл** — обновление и отладка отдельно от Frigate.

Чтобы не потерять live view и birdseye, внутренний go2rtc Frigate подключается
к выделенному как к источнику: `go2rtc.streams.<cam> =
rtsp://<user>:<pass>@go2rtc:8554/<stream>` — поэтому контейнеры связаны общей
Docker-сетью `go2rtc_network_name`, а RTSP/WebRTC-порты выделенного go2rtc на
хост не публикуются (во избежание конфликта с рестримом Frigate на 8554/8555).

## Переменные

| Переменная | Тип | Обяз. | Default | Назначение |
| --- | --- | --- | --- | --- |
| `go2rtc_debug_mode` | bool | нет | `false` | Включить debug-сводку изменений. |
| `go2rtc_project_directory` | string | нет | `"/opt/go2rtc"` | Каталог Compose-проекта. |
| `go2rtc_image` | string | нет | `"alexxit/go2rtc:1.9.15"` | Образ контейнера. |
| `go2rtc_container_name` | string | нет | `"go2rtc"` | Имя контейнера. |
| `go2rtc_ports` | list | нет | `["1984:1984"]` | Публикуемые порты (веб-интерфейс). |
| `go2rtc_network_name` | string | нет | `"cam_streams"` | Общая сеть с потребителями (Frigate подключает её как external). |

## Секретный вход

| Переменная | Назначение |
| --- | --- |
| `vault_go2rtc_config` | Полный `go2rtc.yaml` (streams с RTSP-URL и кредами камер, секция `rtsp:` с user/password для внешних потребителей, `api:`, `webrtc:`). Читается из `VARS/secrets.yml` playbook-ом; роль Vault-файлы не загружает. |

## Требования

- Docker Engine и compose v2 на целевом хосте (роль `docker` в этом проекте).
- `community.docker` на контроллере.

## Пример

```yaml
- hosts: frigate
  vars_files: [../VARS/secrets.yml]
  roles:
    - role: go2rtc
```

## Ограничения check mode

`docker_compose_v2` в check mode не применяет изменения; задача проходит, но
контейнер не создаётся. Copy/template отрабатывают как обычно.
