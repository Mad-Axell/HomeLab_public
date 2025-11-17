# NAS Server Role - Русская документация

Автоматизированная Ansible роль для установки и настройки NAS сервера в LXC контейнере на Proxmox VE.

## Описание

Роль устанавливает и настраивает полнофункциональный NAS сервер со следующими компонентами:

- **Cockpit** - Веб-интерфейс управления сервером с модулями 45Drives (file-sharing, navigator, identities)
- **Samba** - Файловый обмен для Windows/Linux/Mac с интеграцией Cockpit
- **NFS** - Сетевой файловый доступ для Linux клиентов (опционально)
- **Управление хранилищем** - Подготовка системного хранилища и управление пакетами

## Требования

### Предварительные условия

- Debian 11 или выше (рекомендуется Debian 12)
- LXC контейнер на Proxmox VE
- Сетевое подключение к интернету
- Доступ root или sudo
- Доступность systemd-resolved

### Минимальные требования

- 100 GB свободного дискового пространства
- Привилегированный LXC контейнер (если требуется)
- Сетевой доступ к хосту Proxmox (для управления ZFS)

## Переменные роли

### Конфигурация отладки

```yaml
debug_mode: false                      # Boolean. Enable debug output
                                        # Логическое значение. Включить отладочный вывод
```

### Конфигурация Cockpit

```yaml
cockpit_port: 9090                     # Integer. Port for Cockpit web interface
                                        # Целое число. Порт веб-интерфейса Cockpit
cockpit_listen_address: "0.0.0.0"      # String. IP address for Cockpit to listen on
                                        # Строка. IP-адрес для прослушивания Cockpit
cockpit_configure_listener: false      # Boolean. Configure Cockpit listener in cockpit.conf (may cause problems)
                                        # Логическое значение. Настроить прослушиватель Cockpit в cockpit.conf (может вызвать проблемы)
cockpit_modules:                       # List. List of Cockpit modules to install from 45Drives repository
                                        # Список. Список модулей Cockpit для установки из репозитория 45Drives
  - "cockpit-file-sharing"
  - "cockpit-navigator"
  - "cockpit-identities"
```

### Конфигурация Samba

```yaml
samba_workgroup: "WORKGROUP"           # String. Samba workgroup name
                                        # Строка. Имя рабочей группы Samba
samba_security: "user"                 # String. Samba security mode (user, share, domain, ads)
                                        # Строка. Режим безопасности Samba (user, share, domain, ads)
samba_share_method: "registry"         # String. Method for adding shares: 'samba' (config files) or 'registry' (net conf commands)
                                        # Строка. Метод добавления шаров: 'samba' (файлы конфигурации) или 'registry' (команды net conf)
samba_users: []                        # List. List of Samba users to create
                                        # Список. Список пользователей Samba для создания
samba_groups: []                       # List. List of Samba groups to create
                                        # Список. Список групп Samba для создания
samba_shares: []                       # List. List of Samba shares to create
                                        # Список. Список шаров Samba для создания
```

#### Структура пользователей Samba

```yaml
samba_users:
  - name: "nasuser"                    # String. Username
                                        # Строка. Имя пользователя
    password: "secure_password"         # String. User password (use Ansible Vault)
                                        # Строка. Пароль пользователя (используйте Ansible Vault)
    groups: ["nas-group"]              # List. List of groups user belongs to
                                        # Список. Список групп, к которым принадлежит пользователь
    shell: "/bin/bash"                  # String. User shell
                                        # Строка. Оболочка пользователя
    system_user: false                 # Boolean. Create as system user
                                        # Логическое значение. Создать как системного пользователя
    create_home: true                   # Boolean. Create home directory
                                        # Логическое значение. Создать домашнюю директорию
```

#### Структура групп Samba

```yaml
samba_groups:
  - name: "nas-group"                  # String. Group name
                                        # Строка. Имя группы
    gid: 2000                          # Integer. Group ID (optional)
                                        # Целое число. Идентификатор группы (необязательно)
```

#### Структура шаров Samba

```yaml
samba_shares:
  - name: "nas-storage"                # String. Share name
                                        # Строка. Имя шара
    comment: "NAS Storage Share"       # String. Share description
                                        # Строка. Описание шара
    path: "/mnt/nas-storage"           # String. Path to share directory
                                        # Строка. Путь к директории шара
    browsable: true                    # Boolean. Allow browsing in network neighborhood
                                        # Логическое значение. Разрешить просмотр в сетевом окружении
    writable: true                     # Boolean. Allow write access
                                        # Логическое значение. Разрешить запись
    read_only: false                   # Boolean. Read-only share
                                        # Логическое значение. Шар только для чтения
    public: true                       # Boolean. Public share
                                        # Логическое значение. Публичный шар
    guest_ok: false                    # Boolean. Allow guest access
                                        # Логическое значение. Разрешить гостевой доступ
    create_mask: "0664"                # String. File creation mask
                                        # Строка. Маска создания файлов
    directory_mask: "0775"              # String. Directory creation mask
                                        # Строка. Маска создания директорий
    force_user: "nasuser"              # String. Force file ownership to user
                                        # Строка. Принудительное владение файлами пользователем
    force_group: "nas-group"           # String. Force file ownership to group
                                        # Строка. Принудительное владение файлами группой
    valid_users: ["nasuser", "@nas-group"]  # List. List of allowed users/groups
                                            # Список. Список разрешенных пользователей/групп
    write_list: ["nasuser", "@nas-group"]  # List. List of users/groups with write access
                                            # Список. Список пользователей/групп с правом записи
    setgid: true                       # Boolean. Set setgid bit on directories
                                        # Логическое значение. Установить бит setgid на директориях
```

### Конфигурация NFS

```yaml
nfs_enabled: false                     # Boolean. Enable NFS server
                                        # Логическое значение. Включить NFS сервер
nfs_exports: []                        # List. List of NFS exports
                                        # Список. Список NFS экспортов
```

#### Структура экспортов NFS

```yaml
nfs_exports:
  - path: "/mnt/nas-storage"           # String. Path to export
                                        # Строка. Путь для экспорта
    clients: "*(rw,sync,no_subtree_check,no_root_squash)"  # String. Client access specification
                                                            # Строка. Спецификация доступа клиентов
```

### Системная конфигурация

```yaml
backports_enabled: false                # Boolean. Enable Debian backports repository
                                        # Логическое значение. Включить репозиторий Debian backports
essential_packages:                    # List. List of essential packages to install
                                        # Список. Список основных пакетов для установки
  - curl
  - wget
  - net-tools
```

## Методы добавления шаров

Роль поддерживает два метода добавления Samba шаров:

### Метод Samba (файлы конфигурации)

Создает конфигурационные файлы в `/etc/samba/smb.conf.d/share-<name>.conf`. Этот метод использует стандартные конфигурационные файлы Samba и подходит для традиционной настройки.

**Преимущества:**
- Стандартные конфигурационные файлы Samba
- Легко редактировать вручную
- Удобно для контроля версий

**Недостатки:**
- Не полностью интегрирован с модулем Cockpit file-sharing

### Метод Registry (команды net conf)

Добавляет шары напрямую в реестр Samba с помощью команд `net conf addshare` и `net conf setparm`. Этот метод обеспечивает полную интеграцию с модулем Cockpit file-sharing, так как Cockpit использует реестр для управления шарами.

**Преимущества:**
- Полная интеграция с Cockpit
- Шары видны и управляемы в интерфейсе Cockpit
- Динамическое управление шарами

**Недостатки:**
- Требует включения registry в smb.conf
- Менее традиционный подход

**Рекомендация:** Используйте метод `registry` при работе с Cockpit.

## Зависимости

Отсутствуют.

## Пример Playbook

### Базовое использование

```yaml
---
- name: Развертывание NAS сервера
  hosts: nas_container
  become: true
  roles:
    - nas_server
```

### С кастомными переменными

```yaml
---
- name: Развертывание NAS сервера
  hosts: nas_container
  become: true
  vars:
    cockpit_port: 9090
    cockpit_listen_address: "0.0.0.0"
    samba_users:
      - name: "storage"
        password: "{{ vault_storage_pass }}"
        groups: ["nas", "samba"]
        shell: "/bin/bash"
      - name: "backup"
        password: "{{ vault_backup_pass }}"
        groups: ["nas", "samba"]
        shell: "/bin/bash"
    samba_groups:
      - name: "nas"
        gid: 2000
    samba_shares:
      - name: "media"
        path: "/mnt/nas-storage/media"
        comment: "Хранилище медиа"
        force_user: "storage"
        force_group: "nas"
        valid_users: ["storage", "@nas"]
        write_list: ["storage", "@nas"]
      - name: "backups"
        path: "/mnt/nas-storage/backups"
        comment: "Хранилище резервных копий"
        force_user: "backup"
        force_group: "nas"
        valid_users: ["backup", "@nas"]
        write_list: ["backup", "@nas"]
    nfs_enabled: true
    nfs_exports:
      - path: "/mnt/nas-storage"
        clients: "192.168.1.0/24(rw,sync,no_subtree_check)"
  roles:
    - nas_server
```

### С методом Registry для интеграции с Cockpit

```yaml
---
- name: Развертывание NAS сервера с методом Registry
  hosts: nas_container
  become: true
  vars:
    samba_share_method: "registry"
    samba_users:
      - name: "storage"
        password: "{{ vault_storage_pass }}"
        groups: ["nas", "samba"]
    samba_shares:
      - name: "media"
        path: "/mnt/nas-storage/media"
        comment: "Хранилище медиа"
        browsable: true
        writable: true
        force_user: "storage"
        force_group: "nas"
        create_mask: "0664"
        directory_mask: "0775"
  roles:
    - nas_server
```

## Структура роли

```
nas_server/
├── defaults/
│   └── main.yml           # Переменные по умолчанию
├── handlers/
│   └── main.yml           # Обработчики (перезапуск samba и т.д.)
├── meta/
│   └── main.yml           # Метаданные роли
├── tasks/
│   ├── main.yml           # Точка входа
│   ├── cockpit.yml        # Установка Cockpit
│   ├── samba.yml          # Настройка Samba
│   ├── nfs.yml            # Настройка NFS (опционально)
│   └── storage.yml        # Подготовка хранилища
├── templates/
│   ├── samba-global.j2    # Шаблон глобальной конфигурации Samba
│   ├── samba-share.j2     # Шаблон конфигурации шара Samba
│   └── nfs-exports.j2     # Шаблон конфигурации экспортов NFS
├── README.md              # Краткий обзор
├── README_eng.md          # Полная английская документация
└── README_rus.md         # Полная русская документация
```

## Теги

Роль поддерживает следующие теги для выборочного выполнения:

- `checks` - Предварительные проверки
- `storage` - Настройка хранилища
- `packages` - Установка пакетов
- `cockpit` - Установка и настройка Cockpit
- `samba` - Установка и настройка Samba
- `nfs` - Установка и настройка NFS
- `users` - Управление пользователями
- `shares` - Управление шарами
- `config` - Задачи конфигурации
- `services` - Управление сервисами
- `verification` - Проверка статуса

### Примеры использования тегов

```bash
# Установить только Cockpit
ansible-playbook playbook.yml --tags cockpit

# Настроить только Samba
ansible-playbook playbook.yml --tags samba

# Пропустить проверки
ansible-playbook playbook.yml --skip-tags checks

# Установить пакеты и настроить Samba
ansible-playbook playbook.yml --tags packages,samba
```

## Процесс установки

### Этап 1: Подготовка хранилища

1. Добавление репозитория backports (если включено)
2. Обновление кэша apt
3. Обновление системных пакетов
4. Установка основных пакетов

### Этап 2: Установка Cockpit

1. Установка пакета Cockpit
2. Настройка репозитория 45Drives
3. Обновление кэша apt после добавления репозитория
4. Установка модулей Cockpit из 45Drives
5. Настройка прослушивателя Cockpit (если включено)
6. Обеспечение включения и запуска сокета Cockpit
7. Ожидание доступности сервиса Cockpit
8. Проверка работы Cockpit

### Этап 3: Настройка Samba

1. Инициализация коллекций групп из пользователей
2. Создание групп Samba
3. Создание пользователей Samba
4. Установка паролей Samba
5. Включение пользователей Samba
6. Добавление включения registry в конфигурацию Samba (для интеграции с Cockpit)
7. Обеспечение существования директории конфигурации Samba
8. Резервное копирование оригинальной конфигурации Samba
9. Генерация глобальной конфигурации Samba
10. Добавление директивы include для конфигураций шаров (если используется метод samba)
11. Создание директорий шаров Samba
12. Установка бита setgid на директориях шаров (если настроено)
13. Генерация конфигураций шаров Samba (метод samba) или добавление в registry (метод registry)
14. Проверка синтаксиса конфигурации Samba
15. Проверка конфигурации Samba
16. Обеспечение включения и запуска сервисов Samba
17. Проверка работы сервисов Samba

### Этап 4: Настройка NFS (опционально)

1. Установка NFS kernel server (если включено)
2. Генерация конфигурации экспортов NFS
3. Создание директорий экспорта NFS
4. Экспорт шаров NFS
5. Обеспечение включения и запуска сервисов NFS
6. Проверка работы сервиса NFS

## Особенности реализации

### Идемпотентность

Все операции проверяют существование перед изменением. Роль использует встроенные модули Ansible для обеспечения идемпотентности.

### Безопасность

- Пароли пользователей обрабатываются с `no_log: true` где необходимо
- Конфигурационные файлы имеют правильные права доступа
- Поддержка Ansible Vault для хранения секретов
- Настраиваемый режим безопасности Samba

### Обработка ошибок

- Проверка синтаксиса конфигурации перед применением изменений
- Информативные сообщения об ошибках
- Варианты отката при недоступности внешних ресурсов

## Устранение неполадок

### Cockpit недоступен

1. Проверьте статус сервиса: `systemctl status cockpit.socket`
2. Проверьте порт: `netstat -tlnp | grep 9090` или `ss -tlnp | grep 9090`
3. Проверьте логи: `journalctl -u cockpit.socket`
4. Убедитесь, что правила файрвола разрешают порт 9090

### Samba не работает

1. Проверьте синтаксис конфигурации: `testparm -s`
2. Проверьте статус сервисов: `systemctl status smbd nmbd`
3. Проверьте логи: `tail -f /var/log/samba/log.*`
4. Убедитесь, что директории шаров существуют и имеют правильные права
5. Проверьте существование пользователей Samba: `pdbedit -L`

### NFS не работает

1. Проверьте статус сервиса: `systemctl status nfs-kernel-server`
2. Проверьте экспорты: `exportfs -v`
3. Проверьте логи: `journalctl -u nfs-kernel-server`
4. Убедитесь, что правила файрвола разрешают порты NFS (111, 2049)

### Проблемы с методом шаров

**Метод Registry:**
- Убедитесь, что `include = registry` присутствует в `/etc/samba/smb.conf`
- Проверьте шары в реестре: `net conf list`
- Убедитесь, что модуль Cockpit file-sharing установлен

**Метод Samba:**
- Проверьте файлы конфигурации шаров в `/etc/samba/smb.conf.d/`
- Убедитесь, что директива include присутствует в основной конфигурации: `include = /etc/samba/smb.conf.d/*.conf`

## Лицензия

MIT

## Автор

Mad-Axell [mad.axell@gmail.com]

