# frigate

Ansible роль для установки и настройки Frigate NVR (Network Video Recorder) в Docker контейнере.

## Описание

Эта роль автоматизирует развертывание Frigate NVR - системы видеонаблюдения с обнаружением объектов на основе машинного обучения. Роль создает необходимые директории, генерирует конфигурационные файлы Docker Compose и Frigate из шаблонов, и запускает сервис в Docker контейнере. Роль поддерживает интеграцию с Google Coral EDGE TPU для ускорения обнаружения объектов, настройку go2rtc для потоковой передачи видео, и конфигурацию множественных камер с различными ролями (запись, обнаружение).

## Требования

### Требования к управляющему узлу

- Ansible 2.12 или выше
- Python 3.9 или выше

### Требования к управляемым узлам

- Дистрибутив семейства Debian (Debian, Ubuntu, Pop!_OS, Linux Mint)
- Docker и Docker Compose установлены (рекомендуется использовать роль `docker`)
- Доступ root или sudo
- Подключение к интернету для загрузки Docker образа
- Доступ к USB-устройствам (для Coral EDGE TPU, если используется)
- Доступ к GPU устройствам (для аппаратного ускорения видео, опционально)

### Зависимости

- Роль `docker` (рекомендуется для установки Docker и Docker Compose)
- Роль `coral-edge-tpu` (опционально, для поддержки Coral EDGE TPU)

## Переменные роли

### Обязательные переменные

| Переменная | Тип | Описание |
|-----------|-----|----------|
| `frigate_go2rtc_rtsp_user` | string | Имя пользователя для RTSP потоков go2rtc |
| `frigate_go2rtc_rtsp_pswd` | string | Пароль для RTSP потоков go2rtc |
| `frigate_camera_user` | string | Имя пользователя для доступа к IP-камерам |
| `frigate_camera_pswd` | string | Пароль для доступа к IP-камерам |

### Опциональные переменные

#### Основные настройки Docker

| Переменная | Тип | По умолчанию | Описание |
|-----------|-----|--------------|----------|
| `frigate_container_name` | string | `frigate_nvr` | Имя Docker контейнера |
| `frigate_version` | string | `0.15.1` | Версия образа Frigate Docker (можно использовать `stable` для последней стабильной версии) |
| `frigate_config_version` | string | `0.14` | Версия конфигурации Frigate |
| `frigate_shm_size` | string | `512mb` | Размер shared memory для контейнера (должен быть рассчитан на основе количества камер) |
| `frigate_tmpfs_size` | int | `5000000000` | Размер tmpfs для кэша (в байтах, по умолчанию ~5GB) |
| `frigate_tmpfs_target` | string | `/tmp/cache` | Точка монтирования tmpfs внутри контейнера |

#### Настройки путей и директорий

| Переменная | Тип | По умолчанию | Описание |
|-----------|-----|--------------|----------|
| `frigate_base_dir` | string | `/opt/frigate` | Базовая директория для данных Frigate |
| `frigate_config_dir` | string | `{{ frigate_base_dir }}/config` | Директория для конфигурационных файлов |
| `frigate_clips_dir` | string | `{{ frigate_base_dir }}/cctv_clips` | Директория для хранения клипов |
| `frigate_media_dir` | string | `{{ frigate_base_dir }}/media` | Директория для медиа файлов |
| `frigate_docker_compose_path` | string | `/opt/docker-compose.yaml` | Путь к файлу Docker Compose |

#### Настройки портов

| Переменная | Тип | По умолчанию | Описание |
|-----------|-----|--------------|----------|
| `frigate_port_go2rtc_web` | int | `1984` | Порт веб-интерфейса go2rtc |
| `frigate_port_authenticated` | int | `8971` | Порт аутентифицированного UI и API (для reverse proxy) |
| `frigate_port_internal` | int | `5000` | Порт внутреннего неаутентифицированного UI и API (только для Docker сети) |
| `frigate_port_rtmp` | int | `1935` | Порт RTMP потоков |
| `frigate_port_webrtc_tcp` | int | `8555` | Порт WebRTC over TCP |
| `frigate_port_webrtc_udp` | int | `8555` | Порт WebRTC over UDP |
| `frigate_port_rtsp` | int | `8554` | Порт RTSP рестриминга |

#### Настройки устройств

| Переменная | Тип | По умолчанию | Описание |
|-----------|-----|--------------|----------|
| `frigate_usb_device_host` | string | `/dev/bus/usb` | Путь к USB устройству на хосте |
| `frigate_usb_device_container` | string | `/dev/bus/usb` | Путь к USB устройству в контейнере |
| `frigate_gpu_device` | string | `/dev/dri/renderD128` | Путь к GPU устройству для аппаратного ускорения (Intel) |
| `frigate_timezone_host` | string | `/etc/localtime` | Путь к файлу часового пояса на хосте |
| `frigate_timezone_container` | string | `/etc/localtime` | Путь к файлу часового пояса в контейнере |
| `frigate_coral_device` | string | `usb` | Тип устройства Coral TPU: `usb` или `pci` |

#### Настройки томов Docker

| Переменная | Тип | По умолчанию | Описание |
|-----------|-----|--------------|----------|
| `frigate_config_volume_host` | string | `{{ frigate_config_dir }}` | Директория конфигурации на хосте |
| `frigate_config_volume_container` | string | `/config` | Директория конфигурации в контейнере |
| `frigate_media_volume_host` | string | `{{ frigate_media_dir }}` | Директория медиа на хосте |
| `frigate_media_volume_container` | string | `/media/frigate` | Директория медиа в контейнере |

#### Настройки обнаружения

| Переменная | Тип | По умолчанию | Описание |
|-----------|-----|--------------|----------|
| `frigate_detector_type` | string | `edgetpu` | Тип детектора: `edgetpu` (Coral TPU), `cpu` (CPU) |
| `frigate_track_objects` | list | `['person']` | Список объектов для отслеживания |
| `frigate_alert_labels` | list | `['person']` | Список меток для алертов |
| `frigate_detection_labels` | list | `['person']` | Список меток для детекций |

#### Настройки записи

| Переменная | Тип | По умолчанию | Описание |
|-----------|-----|--------------|----------|
| `frigate_record_enabled` | bool | `true` | Включить запись видео |
| `frigate_record_expire_interval` | int | `60` | Интервал истечения записей в секундах |
| `frigate_record_sync_recordings` | bool | `false` | Синхронизировать записи |
| `frigate_record_retain_days` | int | `1` | Количество дней хранения записей |
| `frigate_record_mode` | string | `all` | Режим записи: `all` (все), `motion` (только движение) |
| `frigate_record_preview_quality` | string | `medium` | Качество превью: `low`, `medium`, `high` |
| `frigate_pre_capture` | int | `7` | Секунд записи до события |
| `frigate_post_capture` | int | `7` | Секунд записи после события |
| `frigate_alerts_retain_days` | int | `10` | Количество дней хранения алертов |
| `frigate_alerts_retain_mode` | string | `motion` | Режим хранения алертов: `all`, `motion` |
| `frigate_detections_retain_days` | int | `10` | Количество дней хранения детекций |
| `frigate_detections_retain_mode` | string | `motion` | Режим хранения детекций: `all`, `motion` |

#### Настройки снимков

| Переменная | Тип | По умолчанию | Описание |
|-----------|-----|--------------|----------|
| `frigate_snapshots_enabled` | bool | `true` | Включить создание снимков |
| `frigate_snapshots_timestamp` | bool | `true` | Добавлять временную метку на снимки |
| `frigate_snapshots_bounding_box` | bool | `true` | Показывать рамку обнаруженного объекта |
| `frigate_snapshots_crop` | bool | `false` | Обрезать снимок до объекта |
| `frigate_snapshots_clean_copy` | bool | `false` | Создавать чистую копию снимка |
| `frigate_snapshots_retain_default` | int | `0` | Дней хранения снимков по умолчанию |
| `frigate_snapshots_retain_objects` | dict | `{'person': 0}` | Дней хранения снимков по типам объектов |

#### Настройки UI

| Переменная | Тип | По умолчанию | Описание |
|-----------|-----|--------------|----------|
| `frigate_ui_timezone` | string | `Europe/Moscow` | Часовой пояс для UI |
| `frigate_ui_time_format` | string | `24hour` | Формат времени: `12hour` или `24hour` |
| `frigate_ui_date_style` | string | `medium` | Стиль отображения даты |
| `frigate_ui_time_style` | string | `medium` | Стиль отображения времени |
| `frigate_ui_strftime_fmt` | string | `%Y-%m-%d %H:%M:%S` | Строка формата strftime |

#### Настройки Birdseye

| Переменная | Тип | По умолчанию | Описание |
|-----------|-----|--------------|----------|
| `frigate_birdseye_enabled` | bool | `false` | Включить вид Birdseye (общий обзор всех камер) |
| `frigate_birdseye_width` | int | `1280` | Ширина Birdseye |
| `frigate_birdseye_height` | int | `720` | Высота Birdseye |
| `frigate_birdseye_quality` | int | `15` | Качество Birdseye (1-31, меньше = лучше качество) |
| `frigate_birdseye_mode` | string | `motion` | Режим Birdseye: `motion`, `continuous`, `objects` |

#### Настройки MQTT

| Переменная | Тип | По умолчанию | Описание |
|-----------|-----|--------------|----------|
| `frigate_mqtt_enabled` | bool | `false` | Включить интеграцию с MQTT |

#### Настройки камер

| Переменная | Тип | По умолчанию | Описание |
|-----------|-----|--------------|----------|
| `frigate_cameras` | dict | `{}` | Словарь конфигураций камер (см. примеры ниже) |
| `frigate_go2rtc_host` | string | `10.30.150.5` | IP-адрес хоста go2rtc (обычно localhost или IP контейнера) |
| `frigate_camera_port` | int | `554` | Порт RTSP IP-камеры |
| `frigate_camera_channel` | int | `1` | Номер канала камеры |
| `frigate_camera_subtype_main` | int | `0` | Подтип основного потока камеры |
| `frigate_camera_subtype_sub` | int | `1` | Подтип дополнительного потока камеры |

#### Настройки go2rtc

| Переменная | Тип | По умолчанию | Описание |
|-----------|-----|--------------|----------|
| `frigate_go2rtc_rtsp_listen` | string | `:8554` | Адрес прослушивания RTSP go2rtc |

#### Настройки FFmpeg

| Переменная | Тип | По умолчанию | Описание |
|-----------|-----|--------------|----------|
| `frigate_ffmpeg_output_args_record` | string | `preset-record-generic-audio-copy` | Аргументы вывода FFmpeg для записи |
| `frigate_ffmpeg_input_args` | string | `preset-rtsp-restream-low-latency` | Аргументы ввода FFmpeg |
| `frigate_ffmpeg_retry_interval` | int | `10` | Интервал повтора FFmpeg в секундах |

#### Настройки перезагрузки

| Переменная | Тип | По умолчанию | Описание |
|-----------|-----|--------------|----------|
| `frigate_reboot_enabled` | bool | `true` | Выполнять перезагрузку LXC контейнера перед установкой |
| `frigate_reboot_timeout` | int | `3600` | Таймаут ожидания перезагрузки (в секундах) |
| `frigate_reboot_msg` | string | `Rebooting LXC in 5 seconds` | Сообщение при перезагрузке |

## Пример Playbook

### Базовое использование

```yaml
---
- name: Установка Frigate NVR
  hosts: nvr_hosts
  become: true
  vars:
    frigate_go2rtc_rtsp_user: "admin"
    frigate_go2rtc_rtsp_pswd: "secure_password"
    frigate_camera_user: "camera_user"
    frigate_camera_pswd: "camera_password"
  roles:
    - docker
    - coral-edge-tpu  # опционально
    - frigate
```

### Настройка с кастомными параметрами

```yaml
---
- name: Установка Frigate с настройками
  hosts: nvr_hosts
  become: true
  vars:
    frigate_go2rtc_rtsp_user: "admin"
    frigate_go2rtc_rtsp_pswd: "secure_password"
    frigate_camera_user: "camera_user"
    frigate_camera_pswd: "camera_password"
    
    frigate_version: "stable"
    frigate_shm_size: "1gb"
    frigate_tmpfs_size: 10000000000  # 10GB
    
    frigate_record_retain_days: 7
    frigate_alerts_retain_days: 30
    
    frigate_track_objects:
      - person
      - dog
      - cat
    
    frigate_birdseye_enabled: true
    frigate_birdseye_mode: "continuous"
  roles:
    - docker
    - frigate
```

### Настройка с несколькими камерами

```yaml
---
- name: Установка Frigate с несколькими камерами
  hosts: nvr_hosts
  become: true
  vars:
    frigate_go2rtc_rtsp_user: "admin"
    frigate_go2rtc_rtsp_pswd: "secure_password"
    frigate_camera_user: "camera_user"
    frigate_camera_pswd: "camera_password"
    
    frigate_cameras:
      DoorBell:
        enabled: true
        main_stream: "rtsp://10.30.150.11:554/cam/realmonitor?channel=1&subtype=0"
        sub_stream: "rtsp://10.30.150.11:554/cam/realmonitor?channel=1&subtype=1"
        record: true
        detect: true
      Entrance:
        enabled: true
        main_stream: "rtsp://10.30.150.12:554/cam/realmonitor?channel=1&subtype=0"
        sub_stream: "rtsp://10.30.150.12:554/cam/realmonitor?channel=1&subtype=1"
        record: true
        detect: true
  roles:
    - docker
    - frigate
```

### Использование без перезагрузки

```yaml
---
- name: Установка Frigate без перезагрузки
  hosts: nvr_hosts
  become: true
  vars:
    frigate_go2rtc_rtsp_user: "admin"
    frigate_go2rtc_rtsp_pswd: "secure_password"
    frigate_camera_user: "camera_user"
    frigate_camera_pswd: "camera_password"
    frigate_reboot_enabled: false
  roles:
    - docker
    - frigate
```

## Что делает эта роль

1. **Перезагружает LXC контейнер (опционально)**
   - Выполняет перезагрузку системы с таймаутом ожидания (если `frigate_reboot_enabled: true`)

2. **Создает рабочие директории**
   - Создает директорию для клипов: `{{ frigate_clips_dir }}`
   - Создает директорию для конфигурации: `{{ frigate_config_dir }}`
   - Устанавливает права доступа `0755` для директорий

3. **Генерирует Docker Compose файл**
   - Создает файл Docker Compose из шаблона `Docker_Compose_Frigate.j2`
   - Настраивает контейнер Frigate с необходимыми томами, портами и переменными окружения
   - Настраивает проброс USB устройств для Coral TPU
   - Настраивает проброс GPU устройств для аппаратного ускорения
   - Настраивает tmpfs для кэширования

4. **Генерирует конфигурационный файл Frigate**
   - Создает файл `config.yml` из шаблона `Frigate_Config.j2`
   - Настраивает детекторы (Coral TPU или CPU)
   - Настраивает go2rtc для потоковой передачи
   - Настраивает камеры с основными и дополнительными потоками
   - Настраивает параметры записи, снимков и обнаружения объектов
   - Настраивает UI параметры

5. **Запускает Frigate как сервис**
   - Запускает Docker Compose с созданным файлом конфигурации
   - Контейнер запускается в режиме detached (`-d`)
   - Контейнер настроен на автоматический перезапуск (`restart: unless-stopped`)

## Структура конфигурации

### Docker Compose

Роль создает Docker Compose файл со следующими характеристиками:
- **Образ**: `ghcr.io/blakeblackshear/frigate:{{ frigate_version }}`
- **Контейнер**: `frigate_nvr`
- **Режим**: `privileged: true` (необходимо для доступа к USB/GPU устройствам)
- **Тома**:
  - `/etc/localtime` → синхронизация времени
  - `{{ frigate_config_dir }}` → конфигурация
  - `{{ frigate_media_dir }}` → медиа файлы
  - tmpfs для кэша
- **Порты**: все необходимые порты для go2rtc, Frigate UI, RTSP, RTMP, WebRTC

### Конфигурация Frigate

Конфигурационный файл включает следующие секции:
- **MQTT**: интеграция с MQTT брокером (по умолчанию отключена)
- **Detectors**: настройка детекторов объектов (Coral TPU или CPU)
- **Birdseye**: общий вид всех камер
- **UI**: настройки пользовательского интерфейса
- **Review**: настройки алертов и детекций
- **go2rtc**: настройка потоковой передачи видео
- **FFmpeg**: настройки обработки видео
- **Objects**: настройки отслеживания объектов
- **Snapshots**: настройки создания снимков
- **Record**: настройки записи видео
- **Cameras**: конфигурация камер

## Поддерживаемые дистрибутивы

- Debian (все версии)
- Ubuntu (все версии)
- Pop!_OS
- Linux Mint
- Proxmox LXC контейнеры (Debian/Ubuntu)

## Интеграция с Coral EDGE TPU

Роль поддерживает использование Google Coral EDGE TPU для ускорения обнаружения объектов. Для использования Coral TPU:

1. Установите роль `coral-edge-tpu` перед установкой Frigate
2. Убедитесь, что USB устройство Coral TPU доступно в контейнере
3. В конфигурации Frigate будет использоваться детектор `edgetpu`

Пример конфигурации детектора в шаблоне:
```yaml
detectors:
  coral:
    type: edgetpu
    device: usb  # или pci для PCIe версии
```

## Настройка камер

Камеры настраиваются через переменную `frigate_cameras` или напрямую в шаблоне конфигурации. Каждая камера может иметь:

- **Основной поток (main)**: используется для записи высокого качества
- **Дополнительный поток (sub)**: используется для обнаружения объектов (меньшее разрешение для производительности)
- **Роли**: `record` (запись), `detect` (обнаружение)

Пример конфигурации камеры в шаблоне:
```yaml
cameras:
  DoorBell:
    enabled: true
    ffmpeg:
      inputs:
        - path: rtsp://user:pass@host:8554/DoorBell_main
          roles:
            - record
        - path: rtsp://user:pass@host:8554/DoorBell_sub
          roles:
            - detect
    live:
      stream_name: DoorBell_main
```

## Расчет размера shared memory

Размер shared memory (`shm_size`) должен быть рассчитан на основе количества камер и их разрешения. Формула:

```
shm_size = (количество камер) × (ширина) × (высота) × 1.5 × 3 / 1024 / 1024
```

Например, для 4 камер с разрешением 1920x1080:
```
shm_size = 4 × 1920 × 1080 × 1.5 × 3 / 1024 / 1024 ≈ 37 MB
```

Рекомендуется использовать значение с запасом (например, 512MB для небольшого количества камер).

## Безопасность

### Рекомендации по безопасности

1. **Используйте сильные пароли** для переменных `frigate_go2rtc_rtsp_pswd` и `frigate_camera_pswd`
2. **Храните пароли в Ansible Vault**:
   ```yaml
   ansible-vault encrypt_string 'your_password' --name 'frigate_camera_pswd'
   ```
3. **Ограничьте доступ к портам**:
   - Порт `5000` (внутренний) должен быть доступен только в Docker сети
   - Используйте reverse proxy для порта `8971` (аутентифицированный доступ)
   - Настройте файрвол для ограничения доступа к RTSP портам
4. **Используйте HTTPS** через reverse proxy для веб-интерфейса
5. **Регулярно обновляйте** образ Frigate до последней версии

### Использование Ansible Vault

```yaml
---
- name: Установка Frigate с защищенными паролями
  hosts: nvr_hosts
  become: true
  vars:
    frigate_go2rtc_rtsp_user: "admin"
    frigate_go2rtc_rtsp_pswd: !vault |
      $ANSIBLE_VAULT;1.1;AES256
      6638643965393438656438656438656438656438656438656438656438656438...
    frigate_camera_user: "camera_user"
    frigate_camera_pswd: !vault |
      $ANSIBLE_VAULT;1.1;AES256
      6638643965393438656438656438656438656438656438656438656438656438...
  roles:
    - docker
    - frigate
```

## Примечания

- Роль автоматически создает необходимые директории с правильными правами доступа
- Роль выполняет перезагрузку LXC контейнера по умолчанию (можно отключить через `frigate_reboot_enabled: false`)
- Конфигурационные файлы генерируются из шаблонов Jinja2, что позволяет использовать переменные Ansible
- Роль использует Docker Compose для управления контейнером
- Контейнер запускается в привилегированном режиме для доступа к USB/GPU устройствам
- Для оптимальной производительности рекомендуется использовать Coral EDGE TPU
- Размер tmpfs кэша можно настроить в зависимости от доступной памяти
- Роль поддерживает режим проверки (check mode) Ansible

## Устранение неполадок

### Проблемы с запуском контейнера

Если контейнер не запускается:

1. **Проверьте логи контейнера**:
   ```bash
   docker logs frigate_nvr
   ```

2. **Проверьте конфигурацию**:
   ```bash
   docker compose -f /opt/docker-compose.yaml config
   ```

3. **Проверьте доступность портов**:
   ```bash
   netstat -tulpn | grep -E '8971|5000|8554|8555'
   ```

4. **Проверьте права доступа к директориям**:
   ```bash
   ls -la /opt/frigate/
   ```

### Проблемы с обнаружением объектов

Если объекты не обнаруживаются:

1. **Проверьте доступность Coral TPU** (если используется):
   ```bash
   lsusb | grep -i coral
   ```

2. **Проверьте логи Frigate**:
   ```bash
   docker logs frigate_nvr | grep -i error
   ```

3. **Проверьте конфигурацию детектора** в `config.yml`

4. **Убедитесь, что потоки камер доступны**:
   ```bash
   ffprobe rtsp://user:pass@host:8554/stream_name
   ```

### Проблемы с записью видео

Если видео не записывается:

1. **Проверьте доступное место на диске**:
   ```bash
   df -h /opt/frigate/
   ```

2. **Проверьте права доступа к директории media**:
   ```bash
   ls -la /opt/frigate/media/
   ```

3. **Проверьте настройки записи** в секции `record` конфигурации

4. **Проверьте логи FFmpeg**:
   ```bash
   docker logs frigate_nvr | grep -i ffmpeg
   ```

### Проблемы с доступом к веб-интерфейсу

Если веб-интерфейс недоступен:

1. **Проверьте, что контейнер запущен**:
   ```bash
   docker ps | grep frigate
   ```

2. **Проверьте доступность порта**:
   ```bash
   curl http://localhost:8971
   ```

3. **Проверьте файрвол**:
   ```bash
   iptables -L -n | grep 8971
   ```

4. **Проверьте логи контейнера** на наличие ошибок

### Проблемы с перезагрузкой

Если перезагрузка вызывает проблемы:

1. **Отключите перезагрузку** через `frigate_reboot_enabled: false`
2. **Выполните перезагрузку вручную** перед запуском роли
3. **Увеличьте таймаут** через `frigate_reboot_timeout`

### Проблемы с производительностью

Для улучшения производительности:

1. **Используйте Coral EDGE TPU** вместо CPU детектора
2. **Увеличьте размер shared memory** (`frigate_shm_size`)
3. **Используйте отдельные потоки** для записи и обнаружения
4. **Настройте аппаратное ускорение** через GPU устройства
5. **Увеличьте размер tmpfs** для кэширования

## Обновление Frigate

Для обновления Frigate до новой версии:

1. **Измените переменную версии**:
   ```yaml
   frigate_version: "0.16.0"  # или "stable"
   ```

2. **Запустите роль повторно**:
   ```bash
   ansible-playbook playbook.yml -t frigate
   ```

3. **Или обновите вручную через Docker Compose**:
   ```bash
   docker compose -f /opt/docker-compose.yaml pull
   docker compose -f /opt/docker-compose.yaml up -d
   ```

## Мониторинг и обслуживание

### Проверка статуса

```bash
# Статус контейнера
docker ps | grep frigate

# Логи контейнера
docker logs -f frigate_nvr

# Использование ресурсов
docker stats frigate_nvr
```

### Очистка старых записей

Frigate автоматически удаляет записи согласно настройкам `retain`. Для ручной очистки:

```bash
# Очистка записей старше 7 дней
find /opt/frigate/media/recordings -type f -mtime +7 -delete

# Очистка клипов старше 30 дней
find /opt/frigate/media/clips -type f -mtime +30 -delete
```

### Резервное копирование

Рекомендуется регулярно создавать резервные копии:

```bash
# Резервное копирование конфигурации
tar -czf frigate-config-backup-$(date +%Y%m%d).tar.gz /opt/frigate/config/
```

## Лицензия

MIT

## Автор

Mad-Axell [mad.axell@gmail.com]

## Поддержка

По вопросам и проблемам обращайтесь к автору или создайте issue в репозитории.

## Ссылки

- [Официальная документация Frigate](https://docs.frigate.video/)
- [Репозиторий Frigate на GitHub](https://github.com/blakeblackshear/frigate)
- [Документация go2rtc](https://github.com/AlexxIT/go2rtc)
- [Документация Coral EDGE TPU](https://coral.ai/docs/)

