# Роль Ansible для Fail2ban - Русская документация

## Содержание

1. [Обзор](#обзор)
2. [Особенности](#особенности)
3. [Поддерживаемые операционные системы](#поддерживаемые-операционные-системы)
4. [Требования](#требования)
5. [Установка](#установка)
6. [Переменные роли](#переменные-роли)
7. [Зависимости](#зависимости)
8. [Примеры Playbook](#примеры-playbook)
9. [Интеграция с host_vars/dashboard.yml](#интеграция-с-host_varsdashboardyml)
10. [Расширенная конфигурация](#расширенная-конфигурация)
11. [Устранение неполадок](#устранение-неполадок)
12. [Участие в разработке](#участие-в-разработке)

## Обзор

Роль Ansible для Fail2ban обеспечивает комплексную установку и настройку системы предотвращения вторжений Fail2ban на различных дистрибутивах Linux. Эта роль предназначена для защиты SSH доступа при сохранении подключения для авторизованных пользователей из доверенных сетей.

## Особенности

### Основные возможности
- **Кроссплатформенная поддержка**: Debian, Ubuntu, RedHat, CentOS, Rocky Linux, AlmaLinux, SUSE, openSUSE
- **Защита SSH**: Настраиваемая защита от атак методом перебора с поддержкой белого списка
- **Защита на основе пользователей**: Интеграция с системами управления пользователями
- **Интеграция с файрволом**: Поддержка iptables, firewalld, UFW
- **Уведомления по электронной почте**: Настраиваемые email-уведомления
- **Комплексное логирование**: Детальное логирование и ротация логов
- **Усиление безопасности**: Поддержка SELinux, AppArmor
- **Резервное копирование и восстановление**: Автоматическое резервное копирование конфигурации

### Расширенные возможности
- **Универсальное сопоставление пакетов**: Автоматическое разрешение имен пакетов для различных дистрибутивов
- **Выполнение OS-специфичных задач**: Оптимизированные задачи для каждого семейства операционных систем
- **Комплексная валидация**: Валидация параметров с детальными сообщениями об ошибках
- **Структурированная обработка ошибок**: Корректная обработка ошибок с информативным отладочным выводом
- **Оптимизация производительности**: Настраиваемые ограничения памяти и потоков
- **Соответствие требованиям безопасности**: Управление правами доступа к файлам и контекстом SELinux

## Поддерживаемые операционные системы

| Семейство ОС | Дистрибутивы | Менеджер пакетов | Файрвол | Менеджер служб |
|--------------|--------------|------------------|---------|----------------|
| Debian       | Debian, Ubuntu, Linux Mint | apt | UFW, iptables | systemd |
| RedHat       | RHEL, CentOS, Rocky Linux, AlmaLinux, Fedora | yum/dnf | firewalld, iptables | systemd |
| SUSE         | openSUSE, SLES | zypper | iptables, SuSEfirewall2 | systemd |

## Требования

### Системные требования
- Ansible 2.9 или выше
- Python 3.6 или выше
- Права root или sudo
- Доступ к интернету для установки пакетов
- Минимум 512MB RAM
- Минимум 100MB дискового пространства

### Сетевые требования
- SSH доступ к целевым хостам
- Доступ к репозиториям пакетов
- Доступ к почтовому серверу (если включены email-уведомления)

## Установка

### Из Ansible Galaxy
```bash
ansible-galaxy install fail2ban
```

### Из исходного кода
```bash
git clone https://github.com/your-repo/fail2ban-ansible-role.git
cd fail2ban-ansible-role
```

## Переменные роли

### Основные переменные конфигурации

```yaml
# Настройки отладки и валидации
debug_mode: true                    # Включить отладочный вывод
backup_enabled: true               # Включить резервное копирование конфигурации
validate_parameters: true          # Включить валидацию параметров
strict_validation: true            # Включить строгую валидацию

# Настройки установки Fail2ban
fail2ban_install: true             # Установить пакет fail2ban
fail2ban_service_enabled: true     # Включить службу fail2ban
fail2ban_service_state: started    # Состояние службы (started/stopped)
```

### Конфигурация Fail2ban

```yaml
fail2ban_config:
  loglevel: INFO                   # Уровень логирования (DEBUG, INFO, WARNING, ERROR, CRITICAL)
  logtarget: /var/log/fail2ban.log # Путь к файлу логов
  socket: /var/run/fail2ban/fail2ban.sock # Файл сокета
  pidfile: /var/run/fail2ban/fail2ban.pid # Файл PID
  dbfile: /var/lib/fail2ban/fail2ban.sqlite3 # Файл базы данных
  dbpurgeage: 86400               # Возраст очистки базы данных в секундах
  ignoreip: []                    # IP адреса для игнорирования
  bantime: 600                    # Время блокировки в секундах
  findtime: 600                   # Время поиска в секундах
  maxretry: 3                     # Максимальное количество попыток
  action: iptables-multiport      # Действие по умолчанию
```

### Настройки защиты SSH

```yaml
ssh_protection:
  enabled: true                   # Включить защиту SSH
  port: "22"                      # Порт SSH
  protocol: tcp                   # Протокол SSH
  maxretry: 3                     # Максимальное количество попыток SSH
  bantime: 3600                   # Время блокировки SSH в секундах
  findtime: 600                   # Время поиска SSH в секундах
  whitelist_enabled: true         # Включить белый список
  whitelist_ips: []               # Дополнительные IP для белого списка
  whitelist_networks: []          # Дополнительные сети для белого списка
```

### Настройки защиты на основе пользователей

```yaml
user_based_protection:
  enabled: true                   # Включить защиту на основе пользователей
  trusted_users: []               # Список доверенных пользователей
  trusted_networks: []            # Список доверенных сетей
```

### Настройки интеграции с файрволом

```yaml
firewall_integration:
  enabled: true                   # Включить интеграцию с файрволом
  firewall_backend: auto          # Бэкенд файрвола (auto, iptables, firewalld, ufw)
  firewall_chain: INPUT           # Цепочка файрвола
```

### Настройки уведомлений по электронной почте

```yaml
email_notifications:
  enabled: false                  # Включить уведомления по почте
  destemail: root@localhost       # Email получателя
  sender: fail2ban@localhost      # Email отправителя
  action: "%%(action_mw)s"        # Действие для почты
```

### Настройки безопасности

```yaml
security_settings:
  config_file_mode: '0644'        # Права доступа к конфигурационному файлу
  log_file_mode: '0640'           # Права доступа к файлу логов
  socket_file_mode: '0644'        # Права доступа к файлу сокета
  selinux_enabled: false          # Включить поддержку SELinux
  selinux_context: system_u:object_r:fail2ban_exec_t:s0 # Контекст SELinux
```

### Настройки производительности

```yaml
performance_settings:
  max_memory: 256                 # Максимальное использование памяти в МБ
  max_threads: 4                  # Максимальное количество потоков
  db_max_connections: 10          # Максимальное количество соединений с БД
```

### Настройки резервного копирования

```yaml
backup_settings:
  backup_dir: /etc/fail2ban/backup # Директория резервного копирования
  backup_retention: 7             # Хранение резервных копий в днях
  backup_compress: true           # Сжимать резервные копии
```

## Зависимости

Отсутствуют

## Примеры Playbook

### Базовая установка

```yaml
---
- hosts: servers
  become: yes
  roles:
    - fail2ban
```

### Расширенная конфигурация

```yaml
---
- hosts: servers
  become: yes
  roles:
    - fail2ban
  vars:
    debug_mode: true
    backup_enabled: true
    
    ssh_protection:
      enabled: true
      port: "2222"
      maxretry: 5
      bantime: 7200
      whitelist_networks:
        - "192.168.1.0/24"
        - "10.0.0.0/8"
    
    user_based_protection:
      enabled: true
      trusted_users:
        - admin
        - deploy
        - monitoring
    
    email_notifications:
      enabled: true
      destemail: admin@company.com
      sender: fail2ban@company.com
    
    firewall_integration:
      enabled: true
      firewall_backend: firewalld
    
    security_settings:
      selinux_enabled: true
      config_file_mode: '0600'
```

### Интеграция с пользователями Dashboard

```yaml
---
- hosts: dashboard
  become: yes
  roles:
    - fail2ban
  vars:
    ssh_protection:
      enabled: true
      whitelist_enabled: true
    
    user_based_protection:
      enabled: true
      # Эти значения будут автоматически извлечены из dashboard_users_to_add
      trusted_users: "{{ dashboard_users_to_add | map(attribute='username') | list }}"
      trusted_networks: "{{ dashboard_users_to_add | map(attribute='allowed_subnets') | flatten | unique }}"
```

## Интеграция с host_vars/dashboard.yml

Роль автоматически интегрируется с переменной `dashboard_users_to_add` из `host_vars/dashboard.yml`:

```yaml
# Из host_vars/dashboard.yml
dashboard_users_to_add:
  - username: "admin"
    password: "secure_password"
    groups: ["sudo", "dashboard"]
    is_sudoers: true
    shell: /bin/bash
    allowed_subnets:
      - "192.168.1.0/24"
      - "10.20.30.0/24"
    denied_subnets: []
  - username: "deploy"
    password: "deploy_password"
    groups: ["dashboard"]
    is_sudoers: false
    shell: /bin/bash
    allowed_subnets:
      - "192.168.1.0/24"
      - "10.20.30.0/24"
    denied_subnets: []
```

Роль автоматически:
- Извлечет доверенных пользователей из `dashboard_users_to_add`
- Извлечет доверенные сети из `allowed_subnets`
- Настроит fail2ban для добавления этих пользователей и сетей в белый список
- Обеспечит сохранение SSH доступа для авторизованных пользователей

## Расширенная конфигурация

### Пользовательские правила

```yaml
additional_jails:
  apache:
    enabled: true
    port: "http,https"
    filter: apache-auth
    logpath: /var/log/apache2/error.log
    maxretry: 3
    bantime: 600
    findtime: 600
  
  nginx:
    enabled: true
    port: "http,https"
    filter: nginx-http-auth
    logpath: /var/log/nginx/error.log
    maxretry: 3
    bantime: 600
    findtime: 600
```

### Пользовательские фильтры и действия

```yaml
advanced_settings:
  custom_filters:
    - /etc/fail2ban/filter.d/custom-filter.conf
  
  custom_actions:
    - /etc/fail2ban/action.d/custom-action.conf
  
  custom_jails:
    - name: custom-service
      enabled: true
      port: 8080
      filter: custom-service
      logpath: /var/log/custom-service.log
      maxretry: 5
      bantime: 1800
      findtime: 300
```

## Устранение неполадок

### Частые проблемы

1. **Служба не запускается**
   - Проверьте синтаксис конфигурации: `fail2ban-client -t`
   - Убедитесь в правильности прав доступа к файлу логов
   - Проверьте правила файрвола

2. **SSH доступ заблокирован**
   - Проверьте конфигурацию белого списка
   - Проверьте доверенные сети
   - Просмотрите логи fail2ban: `journalctl -u fail2ban`

3. **Не удается установить пакеты**
   - Обновите кэш пакетов
   - Проверьте конфигурацию репозитория
   - Убедитесь в наличии сетевого подключения

### Режим отладки

Включите режим отладки для детального вывода:

```yaml
debug_mode: true
```

### Файлы логов

- Логи Fail2ban: `/var/log/fail2ban.log`
- Системные логи: `journalctl -u fail2ban`
- Тест конфигурации: `fail2ban-client -t`

### Полезные команды

```bash
# Проверить статус fail2ban
fail2ban-client status

# Проверить конкретное правило
fail2ban-client status sshd

# Разблокировать IP
fail2ban-client set sshd unbanip 192.168.1.100

# Тестировать конфигурацию
fail2ban-client -t

# Перезагрузить конфигурацию
systemctl reload fail2ban
```

## Участие в разработке

1. Сделайте форк репозитория
2. Создайте ветку для новой функции
3. Внесите изменения
4. Добавьте тесты, если применимо
5. Отправьте pull request

## Лицензия

MIT

## Информация об авторе

Эта роль была создана в соответствии со стандартами ansible-rule для разработки корпоративных ролей Ansible.
