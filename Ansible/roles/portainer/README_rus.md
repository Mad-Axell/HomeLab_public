# portainer

Ansible роль для развертывания и настройки Portainer - веб-интерфейса для управления Docker контейнерами.

## Описание

Эта роль автоматизирует развертывание Portainer в виде Docker контейнера на управляемых узлах. Роль поддерживает установку Portainer из официального образа Docker, настройку персистентного хранилища данных, управление сетевыми настройками, настройку политики перезапуска контейнера и проверку доступности веб-интерфейса после развертывания.

## Требования

### Требования к управляющему узлу

- Ansible 2.12 или выше (для полной функциональности)
- Python 3.9 или выше
- Коллекция `community.docker` установлена: `ansible-galaxy collection install community.docker`

### Требования к управляемым узлам

- Docker установлен и запущен (рекомендуется использовать роль `docker`)
- Доступ root или sudo
- Подключение к интернету для загрузки образа Portainer из Docker Hub
- Доступность порта 9000 (или другого указанного порта) для веб-интерфейса

### Зависимости

- Роль `docker` (рекомендуется для установки Docker, если он еще не установлен)

## Переменные роли

### Обязательные переменные

Отсутствуют

### Опциональные переменные

#### Основные настройки Portainer

| Переменная | Тип | По умолчанию | Описание |
|-----------|-----|--------------|----------|
| `version` | string | `latest` | Версия образа Portainer (тег Docker образа) |
| `container_image` | string | `portainer/portainer:{{ version }}` | Полное имя образа Docker для Portainer |
| `container_name` | string | `portainer` | Имя контейнера Portainer |
| `persistent_data_path` | string | `/opt/portainer:/data` | Путь для персистентных данных в формате `host_path:container_path` |
| `host_port` | int | `9000` | Порт на хосте для доступа к веб-интерфейсу Portainer |
| `container_ports` | list | `["9000:9000"]` | Список портов в формате `"host_port:container_port"` |

#### Настройки контейнера

| Переменная | Тип | По умолчанию | Описание |
|-----------|-----|--------------|----------|
| `container_restart_policy` | string | `always` | Политика перезапуска контейнера: `always`, `unless-stopped`, `on-failure`, `no` |
| `container_recreate` | bool | `false` | Пересоздавать ли контейнер при каждом запуске роли |
| `container_labels` | dict | `{}` | Словарь меток (labels) для контейнера |
| `container_network` | string | `omit` | Имя Docker сети для подключения контейнера (если не указано, используется сеть по умолчанию) |
| `container_links` | list | `omit` | Список ссылок на другие контейнеры (устаревший метод, рекомендуется использовать сети) |

#### Настройки очистки

| Переменная | Тип | По умолчанию | Описание |
|-----------|-----|--------------|----------|
| `remove_existing_container` | bool | `false` | Удалять ли существующий контейнер перед установкой |
| `remove_persistent_data` | bool | `false` | Удалять ли персистентные данные при очистке |

#### Настройки администратора (зарезервировано для будущего использования)

| Переменная | Тип | По умолчанию | Описание |
|-----------|-----|--------------|----------|
| `admin_user` | string | `admin` | Имя администратора Portainer (зарезервировано) |
| `admin_password` | string | `password` | Пароль администратора Portainer (зарезервировано) |
| `auth_method` | int | `1` | Метод аутентификации (зарезервировано) |

#### Настройки LDAP (зарезервировано для будущего использования)

| Переменная | Тип | По умолчанию | Описание |
|-----------|-----|--------------|----------|
| `ldap_account` | string | `uid=account_name,ou=Users,o=org,dc=mycompany,dc=com` | Учетная запись LDAP для привязки (зарезервировано) |
| `ldap_account_password` | string | `password` | Пароль учетной записи LDAP (зарезервировано) |
| `ldap_url` | string | `ldap.mycompany.com` | URL сервера LDAP (зарезервировано) |
| `ldap_port` | int | `636` | Порт сервера LDAP (зарезервировано) |
| `tls_enabled` | bool | `true` | Включить TLS для LDAP (зарезервировано) |
| `tls_skipverify` | bool | `true` | Пропускать проверку TLS сертификата (зарезервировано) |
| `start_tls` | bool | `true` | Использовать STARTTLS (зарезервировано) |
| `ldap_base_dn` | string | `ou=Users,o=org,dc=mycompany,dc=com` | Базовый DN для поиска LDAP (зарезервировано) |
| `ldap_filter` | string | `(objectClass=inetOrgPerson)` | Фильтр поиска LDAP (зарезервировано) |
| `ldap_username_attribute` | string | `uid` | Атрибут имени пользователя в LDAP (зарезервировано) |

#### Настройки реестра Docker (зарезервировано для будущего использования)

| Переменная | Тип | По умолчанию | Описание |
|-----------|-----|--------------|----------|
| `configure_registry` | bool | `false` | Настраивать ли реестр Docker (зарезервировано) |
| `registry_name` | string | `nexus-oss` | Имя реестра Docker (зарезервировано) |
| `registry_url` | string | `1.2.3.4` | URL реестра Docker (зарезервировано) |
| `registry_port` | int | `5001` | Порт реестра Docker (зарезервировано) |
| `registry_auth` | bool | `false` | Требуется ли аутентификация для реестра (зарезервировано) |
| `registry_type` | int | `3` | Тип реестра: `1` (Quay.io), `2` (Azure Container Registry) или `3` (custom registry) (зарезервировано) |
| `registry_username` | string | `username` | Имя пользователя для реестра (зарезервировано) |
| `registry_password` | string | `password` | Пароль для реестра (зарезервировано) |

#### Прочие настройки (зарезервировано для будущего использования)

| Переменная | Тип | По умолчанию | Описание |
|-----------|-----|--------------|----------|
| `configure_settings` | bool | `false` | Настраивать ли дополнительные параметры Portainer (зарезервировано) |
| `company_logo_url` | string | `'https://...'` | URL логотипа компании для отображения в интерфейсе (зарезервировано) |
| `templates_url` | string | `'https://raw.githubusercontent.com/portainer/templates/master/templates.json'` | URL шаблонов Docker Compose (зарезервировано) |
| `allow_bindmounts_users` | bool | `true` | Разрешить пользователям использовать bind mounts (зарезервировано) |
| `allow_privileged_users` | bool | `true` | Разрешить привилегированным пользователям выполнять привилегированные операции (зарезервировано) |
| `endpoints` | list | `[{name: local, url: ""}]` | Список эндпоинтов Docker для управления (зарезервировано) |

## Пример Playbook

### Базовое использование

```yaml
---
- name: Развертывание Portainer
  hosts: all
  become: true
  roles:
    - docker
    - portainer
```

### Развертывание Portainer с кастомным портом

```yaml
---
- name: Развертывание Portainer на порту 9443
  hosts: all
  become: true
  vars:
    host_port: 9443
    container_ports:
      - "9443:9000"
  roles:
    - docker
    - portainer
```

### Развертывание Portainer с кастомным путем данных

```yaml
---
- name: Развертывание Portainer с кастомным хранилищем
  hosts: all
  become: true
  vars:
    persistent_data_path: /mnt/data/portainer:/data
  roles:
    - docker
    - portainer
```

### Развертывание конкретной версии Portainer

```yaml
---
- name: Развертывание Portainer версии 2.20.0
  hosts: all
  become: true
  vars:
    version: "2.20.0"
  roles:
    - docker
    - portainer
```

### Развертывание Portainer с метками и сетью

```yaml
---
- name: Развертывание Portainer с метками
  hosts: all
  become: true
  vars:
    container_labels:
      environment: production
      managed_by: ansible
    container_network: docker_network
  roles:
    - docker
    - portainer
```

### Пересоздание контейнера Portainer

```yaml
---
- name: Пересоздание контейнера Portainer
  hosts: all
  become: true
  vars:
    container_recreate: true
  roles:
    - docker
    - portainer
```

### Очистка и переустановка Portainer

```yaml
---
- name: Очистка и переустановка Portainer
  hosts: all
  become: true
  vars:
    remove_existing_container: true
    remove_persistent_data: true
  roles:
    - docker
    - portainer
```

## Что делает эта роль

1. **Очистка существующего контейнера (опционально)**
   - Удаляет существующий контейнер Portainer (если `remove_existing_container: true`)
   - Удаляет персистентные данные (если `remove_persistent_data: true`)

2. **Развертывание контейнера Portainer**
   - Создает и запускает Docker контейнер с образом Portainer
   - Настраивает монтирование Docker socket (`/var/run/docker.sock`) для управления Docker
   - Настраивает персистентное хранилище данных
   - Настраивает порты для доступа к веб-интерфейсу
   - Применяет метки и сетевые настройки (если указаны)
   - Настраивает политику перезапуска контейнера

3. **Проверка состояния контейнера**
   - Проверяет, что контейнер успешно запущен
   - Выполняет проверку доступности веб-интерфейса Portainer
   - Ожидает готовности веб-интерфейса (до 10 попыток с задержкой 3 секунды)

4. **Установка фактов**
   - Устанавливает факт `portainer_is_running` с состоянием контейнера
   - Устанавливает факт `portainer_endpoint` с URL API Portainer

## Поддерживаемые дистрибутивы

Роль работает на любом дистрибутиве Linux, где установлен и запущен Docker:
- Debian/Ubuntu
- RedHat/CentOS/Fedora
- Alpine Linux
- Arch Linux
- Любой другой дистрибутив с Docker

## Конфигурация персистентного хранилища

Роль автоматически создает директорию для персистентных данных на хосте (если она не существует). Данные Portainer сохраняются в указанной директории и монтируются в контейнер по пути `/data`.

### Примеры путей

```yaml
# Стандартный путь
persistent_data_path: /opt/portainer:/data

# Кастомный путь
persistent_data_path: /mnt/storage/portainer:/data

# Путь в домашней директории пользователя
persistent_data_path: /home/user/portainer-data:/data
```

## Сетевая конфигурация

По умолчанию контейнер Portainer использует сеть Docker по умолчанию и доступен по IP-адресу контейнера. Для доступа к веб-интерфейсу используется порт, указанный в переменной `host_port`.

### Использование кастомной сети

```yaml
vars:
  container_network: my_docker_network
```

## Примечания

- Роль автоматически монтирует Docker socket (`/var/run/docker.sock`) в контейнер для управления Docker демоном
- После первого запуска Portainer необходимо выполнить первоначальную настройку через веб-интерфейс (создание администратора)
- Роль проверяет доступность веб-интерфейса после развертывания, но не выполняет автоматическую настройку администратора
- Переменные для настройки LDAP, реестров и других параметров зарезервированы для будущего использования
- Роль использует модуль `community.docker.docker_container` для управления контейнером
- При использовании `container_recreate: true` контейнер будет пересоздан при каждом запуске роли
- Роль поддерживает режим проверки (check mode) Ansible

## Устранение неполадок

### Ошибки при развертывании контейнера

Если возникают проблемы с развертыванием контейнера:
1. Проверьте, что Docker установлен и запущен: `systemctl status docker`
2. Убедитесь, что образ Portainer доступен: `docker pull portainer/portainer:latest`
3. Проверьте логи контейнера: `docker logs portainer`
4. Убедитесь, что порт не занят другим процессом: `netstat -tuln | grep 9000`

### Проблемы с доступом к веб-интерфейсу

Если веб-интерфейс недоступен:
1. Проверьте статус контейнера: `docker ps | grep portainer`
2. Проверьте, что порт проброшен корректно: `docker port portainer`
3. Проверьте настройки файрвола на хосте
4. Убедитесь, что контейнер запущен: `docker start portainer`

### Проблемы с персистентными данными

Если данные не сохраняются:
1. Проверьте права доступа к директории: `ls -la /opt/portainer`
2. Убедитесь, что путь указан корректно в формате `host_path:container_path`
3. Проверьте, что директория существует и доступна для записи

### Ошибки при монтировании Docker socket

Если возникают проблемы с доступом к Docker socket:
1. Проверьте права доступа к `/var/run/docker.sock`: `ls -la /var/run/docker.sock`
2. Убедитесь, что пользователь, от имени которого запускается контейнер, имеет доступ к Docker socket
3. Проверьте, что Docker демон запущен и доступен

### Контейнер не перезапускается автоматически

Если контейнер не перезапускается после перезагрузки системы:
1. Проверьте политику перезапуска: `docker inspect portainer | grep RestartPolicy`
2. Убедитесь, что Docker сервис настроен на автозапуск: `systemctl is-enabled docker`
3. Проверьте логи Docker: `journalctl -u docker`

## Безопасность

### Рекомендации по безопасности

- **Не используйте пароли по умолчанию**: Измените `admin_password` на безопасный пароль
- **Ограничьте доступ к порту**: Используйте файрвол для ограничения доступа к порту Portainer только с доверенных IP-адресов
- **Используйте HTTPS**: Настройте обратный прокси (nginx, traefik) с SSL/TLS сертификатом для доступа к Portainer
- **Ограничьте доступ к Docker socket**: Portainer требует доступа к Docker socket, что дает полный контроль над Docker демоном
- **Регулярно обновляйте Portainer**: Используйте конкретные версии вместо `latest` в production окружениях

### Пример настройки с обратным прокси

```yaml
# В playbook для настройки nginx/traefik
# Portainer должен быть доступен только через HTTPS
vars:
  host_port: 127.0.0.1:9000  # Только локальный доступ
  container_ports:
    - "127.0.0.1:9000:9000"
```

## Лицензия

MIT

## Автор

Mad-Axell [mad.axell@gmail.com]

## Поддержка

По вопросам и проблемам обращайтесь к автору или создайте issue в репозитории.

## Ссылки

- [Официальный сайт Portainer](https://www.portainer.io/)
- [Документация Portainer](https://docs.portainer.io/)
- [Docker Hub - Portainer](https://hub.docker.com/r/portainer/portainer)
- [Коллекция Ansible community.docker](https://docs.ansible.com/ansible/latest/collections/community/docker/)

