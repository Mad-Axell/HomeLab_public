# Руководство по настройке PAM безопасности для виртуальных машин

## Обзор

Данное руководство описывает пошаговую настройку PAM (Pluggable Authentication Modules) для обеспечения безопасного доступа к виртуальным машинам с ограничением по IP-подсетям. Руководство предназначено для администраторов, настраивающих виртуальные машины с нуля.

## Архитектура безопасности

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Client IP     │───▶│   Firewall      │───▶│   SSH Daemon    │
│   (Subnet)      │    │   (UFW/iptables)│    │   (sshd)        │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                │                        │
                                ▼                        ▼
                       ┌─────────────────┐    ┌─────────────────┐
                       │   Logging       │    │   PAM Modules   │
                       │   (rsyslog)     │    │   (access,      │
                       └─────────────────┘    │    faillock)    │
                                              └─────────────────┘
```

## Порядок действий для настройки с нуля

12 детальных этапов с пошаговыми инструкциями:
ЭТАП 1: Подготовка и планирование
Анализ требований безопасности
Создание структуры новых файлов
Планирование архитектуры
ЭТАП 2: SSH конфигурация с ограничениями по подсетям
Полная SSH конфигурация с Match блоками
PAM sshd конфигурация с контролем доступа
Валидация конфигураций
ЭТАП 3: Настройка файрвола UFW
Установка и базовая настройка UFW
Дополнительные правила iptables
Персистентность правил
ЭТАП 4: Настройка fail2ban
Установка и конфигурация fail2ban
Кастомные фильтры
Мониторинг статуса
ЭТАП 5: Централизованное логирование
Настройка rsyslog
Конфигурация logrotate
Скрипты мониторинга логов
ЭТАП 6: Скрипты управления и мониторинга
Управление пользователями
Мониторинг безопасности
Тестирование доступа
ЭТАП 7: План аварийного восстановления
Скрипты аварийного доступа
Резервное копирование
Процедуры отката
ЭТАП 8: Обновление переменных и обработчиков
Расширенные переменные
Улучшенные обработчики
Интеграция компонентов
ЭТАП 9: Обновление основного файла задач
Интеграция новых задач
Логическая последовательность
Условное выполнение
ЭТАП 10: Создание шаблонов
Jinja2 шаблоны для конфигураций
Динамическая генерация
Переиспользование кода
ЭТАП 11: Тестирование и валидация
Тестовые playbooks
Процедуры тестирования
Валидация конфигураций
ЭТАП 12: Документация и развертывание
Обновление документации
План развертывания
Процедуры поддержки
Ключевые особенности развернутых рекомендаций:
Готовые YAML файлы с полными конфигурациями
Jinja2 шаблоны для динамической генерации
Пошаговые инструкции с объяснениями
Примеры кода для каждого компонента
Процедуры тестирования и валидации
План развертывания с временными рамками
Документация и поддержка



### Этап 1: Подготовка виртуальной машины

#### 1.1 Установка базовой системы
```bash
# Обновление системы
apt update && apt upgrade -y

# Установка необходимых пакетов
apt install -y openssh-server fail2ban ufw rsyslog auditd

# Проверка статуса SSH
systemctl status ssh
systemctl enable ssh
```

#### 1.2 Создание резервных копий
```bash
# Создать директорию для бэкапов
mkdir -p /etc/backups/security

# Создать резервные копии критических файлов
cp /etc/ssh/sshd_config /etc/backups/security/sshd_config.backup.$(date +%s)
cp /etc/pam.d/sshd /etc/backups/security/sshd.backup.$(date +%s)
cp /etc/security/access.conf /etc/backups/security/access.conf.backup.$(date +%s) 2>/dev/null || true
```

### Этап 2: Настройка пользователей и групп

#### 2.1 Создание структуры пользователей
```bash
# Создать скрипт управления пользователями
cat > /usr/local/bin/manage_users.sh << 'EOF'
#!/bin/bash

# Функция добавления пользователя с ограничениями
add_secure_user() {
    local username=$1
    local allowed_subnets=$2
    local groups=$3
    local shell=${4:-/bin/bash}
    local password=$5
    
    # Создать пользователя
    useradd -m -s $shell -G $groups $username
    
    # Установить пароль
    echo "$username:$password" | chpasswd
    
    # Принудительная смена пароля при первом входе
    passwd -e $username
    
    # Добавить в /etc/security/access.conf
    echo "+ : $username : $allowed_subnets" >> /etc/security/access.conf
    
    # Создать SSH директорию
    mkdir -p /home/$username/.ssh
    chmod 700 /home/$username/.ssh
    chown $username:$username /home/$username/.ssh
    
    echo "Пользователь $username создан с доступом из подсетей: $allowed_subnets"
}

# Пример использования:
# add_secure_user "admin" "10.20.30.0/24,192.168.1.0/24" "sudo,adm" "/bin/bash" "SecurePassword123!"
EOF

chmod +x /usr/local/bin/manage_users.sh
```

#### 2.2 Создание пользователей по ролям
```bash
# Администраторы - полный доступ
/usr/local/bin/manage_users.sh "admin" "10.20.30.0/24,192.168.1.0/24" "sudo,adm" "/bin/bash" "SecureAdminPass123!"

# Операторы - ограниченный доступ
/usr/local/bin/manage_users.sh "operator" "10.20.30.0/24" "adm" "/bin/bash" "SecureOperatorPass123!"

# Мониторинг - только чтение
/usr/local/bin/manage_users.sh "monitor" "10.20.30.0/24,10.30.150.0/24" "adm" "/bin/bash" "SecureMonitorPass123!"
```

### Этап 3: Настройка PAM модулей

#### 3.1 Установка необходимых PAM модулей
```bash
# Установка дополнительных PAM модулей
apt install -y libpam-modules libpam-modules-bin libpam-cap libpam-u2f

# Проверка доступных модулей
pam-config --query --sshd
```

#### 3.2 Конфигурация /etc/pam.d/sshd
```bash
# Создать резервную копию
cp /etc/pam.d/sshd /etc/pam.d/sshd.backup.$(date +%s)

# Настроить PAM для SSH
cat > /etc/pam.d/sshd << 'EOF'
# PAM configuration for the Secure Shell service

# Стандартная аутентификация Unix
auth       required     pam_env.so
auth       required     pam_env.so envfile=/etc/default/locale

# Контроль доступа по IP-подсетям
auth       required     pam_access.so

# Защита от брутфорс атак
auth       required     pam_faillock.so preauth audit silent deny=5 unlock_time=900
auth       sufficient   pam_unix.so nullok_secure
auth       [default=die] pam_faillock.so authfail audit deny=5 unlock_time=900
auth       required     pam_faillock.so authsucc audit deny=5 unlock_time=900

# Дополнительные проверки
auth       optional     pam_cap.so
auth       optional     pam_u2f.so authfile=/etc/u2f_mappings

# Управление учетными записями
account    required     pam_access.so
account    required     pam_faillock.so
account    required     pam_nologin.so
account    required     pam_unix.so

# Управление сессиями
session    required     pam_limits.so
session    required     pam_loginuid.so
session    optional     pam_keyinit.so force revoke
session    required     pam_unix.so

# Управление паролями
password   required     pam_unix.so obscure sha512
EOF
```

#### 3.3 Создание /etc/security/access.conf
```bash
cat > /etc/security/access.conf << 'EOF'
# Файл контроля доступа PAM
# Формат: permission : users : origins

# Разрешить доступ администраторам с определенных подсетей
+ : admin root : 10.20.30.0/24 192.168.1.0/24

# Разрешить доступ операторам
+ : operator : 10.20.30.0/24

# Разрешить доступ мониторингу
+ : monitor : 10.20.30.0/24 10.30.150.0/24

# Временные ограничения (рабочие часы)
+ : admin : 10.20.30.0/24 192.168.1.0/24 (Wk0900-1800)

# Запретить доступ всем остальным
- : ALL : ALL
EOF
```

#### 3.4 Настройка ограничений ресурсов
```bash
cat > /etc/security/limits.conf << 'EOF'
# Ограничения ресурсов по пользователям

# Администраторы
@admin     soft    nproc    100
@admin     hard    nproc    200
@admin     soft    nofile   1024
@admin     hard    nofile   2048

# Операторы
@operator  soft    nproc    50
@operator  hard    nproc    100
@operator  soft    nofile   512
@operator  hard    nofile   1024

# Мониторинг
@monitor   soft    nproc    20
@monitor   hard    nproc    50
@monitor   soft    nofile   256
@monitor   hard    nofile   512

# Ограничить количество SSH сессий
*          soft    maxlogins 3
*          hard    maxlogins 5
EOF
```

### Этап 4: Настройка SSH

#### 4.1 Конфигурация SSH daemon
```bash
# Создать резервную копию
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup.$(date +%s)

# Настроить SSH с ограничениями по подсетям
cat > /etc/ssh/sshd_config << 'EOF'
# SSH конфигурация с ограничениями по подсетям

# Базовые настройки
Port 22
Protocol 2
AddressFamily inet

# Аутентификация
LoginGraceTime 2m
PermitRootLogin no
StrictModes yes
MaxAuthTries 3
MaxSessions 3

# Публичные ключи
PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys

# Пароли
PasswordAuthentication yes
PermitEmptyPasswords no
ChallengeResponseAuthentication no

# X11 и порт-форвардинг
X11Forwarding no
X11DisplayOffset 10
PrintMotd no
PrintLastLog yes
TCPKeepAlive yes

# Логирование
SyslogFacility AUTH
LogLevel INFO

# Ограничения по подсетям
# Разрешить доступ с основных подсетей
Match Address 10.20.30.0/24,192.168.1.0/24
    AllowUsers admin root operator monitor
    PermitRootLogin yes
    PasswordAuthentication yes
    PubkeyAuthentication yes

# Разрешить доступ с NVR подсети только для мониторинга
Match Address 10.30.150.0/24
    AllowUsers monitor
    PermitRootLogin no
    PasswordAuthentication yes
    PubkeyAuthentication yes

# Запретить доступ с других подсетей
Match Address *
    AllowUsers none
    DenyUsers *
    PermitRootLogin no
    PasswordAuthentication no
    PubkeyAuthentication no
EOF
```

### Этап 5: Настройка файрвола

#### 5.1 Настройка UFW
```bash
# Сбросить правила UFW
ufw --force reset

# Настроить политики по умолчанию
ufw default deny incoming
ufw default allow outgoing

# Разрешить SSH только с определенных подсетей
ufw allow from 10.20.30.0/24 to any port 22 proto tcp comment 'SSH from main subnet'
ufw allow from 192.168.1.0/24 to any port 22 proto tcp comment 'SSH from management subnet'
ufw allow from 10.30.150.0/24 to any port 22 proto tcp comment 'SSH from NVR subnet'

# Включить UFW
ufw --force enable

# Проверить статус
ufw status verbose
```

#### 5.2 Дополнительные iptables правила
```bash
# Создать скрипт настройки дополнительных правил
cat > /usr/local/bin/setup_advanced_firewall.sh << 'EOF'
#!/bin/bash

# Блокировать подозрительные IP диапазоны
iptables -A INPUT -s 10.0.0.0/8 -p tcp --dport 22 -m conntrack --ctstate NEW -m recent --set --name SSH_ATTACK
iptables -A INPUT -s 10.0.0.0/8 -p tcp --dport 22 -m conntrack --ctstate NEW -m recent --update --seconds 60 --hitcount 3 --name SSH_ATTACK -j DROP

# Ограничить количество подключений с одного IP
iptables -A INPUT -p tcp --dport 22 -m conntrack --ctstate NEW -m recent --set --name SSH_CONN
iptables -A INPUT -p tcp --dport 22 -m conntrack --ctstate NEW -m recent --update --seconds 60 --hitcount 5 --name SSH_CONN -j DROP

# Логирование подозрительной активности
iptables -A INPUT -p tcp --dport 22 -m conntrack --ctstate NEW -j LOG --log-prefix "SSH_CONNECTION: " --log-level 4
EOF

chmod +x /usr/local/bin/setup_advanced_firewall.sh
/usr/local/bin/setup_advanced_firewall.sh
```

### Этап 6: Настройка fail2ban

#### 6.1 Конфигурация fail2ban
```bash
# Создать конфигурацию fail2ban
cat > /etc/fail2ban/jail.local << 'EOF'
[DEFAULT]
# Базовые настройки
bantime = 3600
findtime = 600
maxretry = 3
backend = systemd

[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 3600
findtime = 600

[sshd-ddos]
enabled = true
port = ssh
filter = sshd-ddos
logpath = /var/log/auth.log
maxretry = 6
bantime = 3600
findtime = 600
EOF

# Перезапустить fail2ban
systemctl restart fail2ban
systemctl enable fail2ban

# Проверить статус
fail2ban-client status
```

### Этап 7: Настройка логирования и мониторинга

#### 7.1 Настройка rsyslog
```bash
# Создать конфигурацию для SSH логирования
cat > /etc/rsyslog.d/50-ssh-security.conf << 'EOF'
# SSH логирование безопасности
:programname, isequal, "sshd" /var/log/ssh-security/ssh.log
& stop

# PAM логирование
:programname, isequal, "pam_access" /var/log/ssh-security/pam_access.log
& stop

:programname, isequal, "pam_faillock" /var/log/ssh-security/pam_faillock.log
& stop
EOF

# Создать директории для логов
mkdir -p /var/log/ssh-security
chmod 755 /var/log/ssh-security

# Перезапустить rsyslog
systemctl restart rsyslog
```

#### 7.2 Создание скрипта мониторинга
```bash
cat > /usr/local/bin/security_monitor.sh << 'EOF'
#!/bin/bash

# Скрипт мониторинга безопасности SSH

LOG_FILE="/var/log/ssh-security/security_monitor.log"
DATE=$(date '+%Y-%m-%d %H:%M:%S')

# Функция логирования
log_message() {
    echo "[$DATE] $1" >> $LOG_FILE
}

# Проверка SSH подключений
check_ssh_connections() {
    local connections=$(ss -tlnp | grep :22 | wc -l)
    log_message "SSH connections: $connections"
    
    if [ $connections -gt 10 ]; then
        log_message "WARNING: High number of SSH connections detected"
    fi
}

# Проверка fail2ban статуса
check_fail2ban() {
    local banned=$(fail2ban-client status sshd | grep "Currently banned" | awk '{print $4}')
    log_message "Fail2ban banned IPs: $banned"
    
    if [ $banned -gt 5 ]; then
        log_message "WARNING: High number of banned IPs"
    fi
}

# Проверка PAM блокировок
check_pam_blocks() {
    local blocks=$(grep "pam_faillock" /var/log/auth.log | grep "$(date '+%b %d')" | wc -l)
    log_message "PAM blocks today: $blocks"
}

# Основная функция
main() {
    log_message "=== Security Monitor Check ==="
    check_ssh_connections
    check_fail2ban
    check_pam_blocks
    log_message "=== End of Check ==="
}

# Запуск
main
EOF

chmod +x /usr/local/bin/security_monitor.sh

# Добавить в crontab для ежедневного запуска
echo "0 9 * * * /usr/local/bin/security_monitor.sh" | crontab -
```

### Этап 8: Тестирование и проверка

#### 8.1 Перезапуск сервисов
```bash
# Перезапустить все сервисы
systemctl restart ssh
systemctl restart fail2ban
systemctl restart rsyslog

# Проверить статус
systemctl status ssh
systemctl status fail2ban
systemctl status rsyslog
```

#### 8.2 Тестирование доступа
```bash
# Создать скрипт тестирования
cat > /usr/local/bin/test_access.sh << 'EOF'
#!/bin/bash

echo "=== Тестирование SSH доступа ==="

# Тест 1: Проверка SSH конфигурации
echo "1. Проверка SSH конфигурации..."
sshd -t
if [ $? -eq 0 ]; then
    echo "   ✓ SSH конфигурация корректна"
else
    echo "   ✗ Ошибка в SSH конфигурации"
fi

# Тест 2: Проверка PAM конфигурации
echo "2. Проверка PAM конфигурации..."
pam-config --query --sshd > /dev/null
if [ $? -eq 0 ]; then
    echo "   ✓ PAM конфигурация корректна"
else
    echo "   ✗ Ошибка в PAM конфигурации"
fi

# Тест 3: Проверка fail2ban
echo "3. Проверка fail2ban..."
fail2ban-client status sshd > /dev/null
if [ $? -eq 0 ]; then
    echo "   ✓ Fail2ban работает"
else
    echo "   ✗ Fail2ban не работает"
fi

# Тест 4: Проверка UFW
echo "4. Проверка UFW..."
ufw status | grep -q "Status: active"
if [ $? -eq 0 ]; then
    echo "   ✓ UFW активен"
else
    echo "   ✗ UFW не активен"
fi

echo "=== Тестирование завершено ==="
EOF

chmod +x /usr/local/bin/test_access.sh
/usr/local/bin/test_access.sh
```

### Этап 9: Создание плана аварийного восстановления

#### 9.1 Скрипт аварийного доступа
```bash
cat > /usr/local/bin/emergency_access.sh << 'EOF'
#!/bin/bash

# Скрипт аварийного восстановления SSH доступа

echo "=== Аварийное восстановление SSH доступа ==="

# Восстановить backup конфигурации SSH
if [ -f /etc/backups/security/sshd_config.backup.* ]; then
    cp /etc/backups/security/sshd_config.backup.* /etc/ssh/sshd_config
    echo "✓ SSH конфигурация восстановлена"
fi

# Восстановить backup PAM конфигурации
if [ -f /etc/backups/security/sshd.backup.* ]; then
    cp /etc/backups/security/sshd.backup.* /etc/pam.d/sshd
    echo "✓ PAM конфигурация восстановлена"
fi

# Очистить fail2ban блокировки
fail2ban-client unban --all
echo "✓ Fail2ban блокировки очищены"

# Сбросить UFW правила
ufw --force reset
ufw allow 22/tcp
ufw --force enable
echo "✓ UFW правила сброшены"

# Перезапустить SSH
systemctl restart ssh
echo "✓ SSH сервис перезапущен"

echo "=== Аварийное восстановление завершено ==="
echo "Проверьте доступ: ssh admin@$(hostname -I | awk '{print $1}')"
EOF

chmod +x /usr/local/bin/emergency_access.sh
```

#### 9.2 Создание резервного копирования
```bash
cat > /usr/local/bin/backup_security_configs.sh << 'EOF'
#!/bin/bash

# Скрипт резервного копирования конфигураций безопасности

BACKUP_DIR="/etc/backups/security"
DATE=$(date +%Y%m%d_%H%M%S)

echo "=== Создание резервной копии конфигураций безопасности ==="

# Создать архив с конфигурациями
tar -czf "$BACKUP_DIR/security_configs_$DATE.tar.gz" \
    /etc/ssh/ \
    /etc/pam.d/ \
    /etc/security/ \
    /etc/fail2ban/ \
    /etc/rsyslog.d/ \
    /usr/local/bin/manage_users.sh \
    /usr/local/bin/security_monitor.sh \
    /usr/local/bin/emergency_access.sh

echo "✓ Резервная копия создана: $BACKUP_DIR/security_configs_$DATE.tar.gz"

# Удалить старые копии (старше 30 дней)
find $BACKUP_DIR -name "security_configs_*.tar.gz" -mtime +30 -delete
echo "✓ Старые резервные копии удалены"

echo "=== Резервное копирование завершено ==="
EOF

chmod +x /usr/local/bin/backup_security_configs.sh

# Добавить в crontab для ежедневного резервного копирования
echo "0 2 * * * /usr/local/bin/backup_security_configs.sh" | crontab -
```

### Этап 10: Финальная проверка и документация

#### 10.1 Создание отчета о настройке
```bash
cat > /var/log/security_setup_report.log << 'EOF'
=== ОТЧЕТ О НАСТРОЙКЕ PAM БЕЗОПАСНОСТИ ===

Дата настройки: $(date)
Хост: $(hostname)
IP адрес: $(hostname -I | awk '{print $1}')

НАСТРОЕННЫЕ КОМПОНЕНТЫ:
✓ PAM модули (access, faillock, limits)
✓ SSH конфигурация с ограничениями по подсетям
✓ UFW файрвол с правилами доступа
✓ Fail2ban для защиты от брутфорс атак
✓ Централизованное логирование
✓ Мониторинг безопасности
✓ План аварийного восстановления
✓ Автоматическое резервное копирование

ПОДДЕРЖИВАЕМЫЕ ПОДСЕТИ:
- 10.20.30.0/24 (Основная инфраструктура)
- 192.168.1.0/24 (Сеть управления)
- 10.30.150.0/24 (NVR сеть)

ПОЛЬЗОВАТЕЛИ:
- admin: Полный доступ с 10.20.30.0/24, 192.168.1.0/24
- operator: Ограниченный доступ с 10.20.30.0/24
- monitor: Доступ для мониторинга с 10.20.30.0/24, 10.30.150.0/24

СКРИПТЫ УПРАВЛЕНИЯ:
- /usr/local/bin/manage_users.sh - Управление пользователями
- /usr/local/bin/security_monitor.sh - Мониторинг безопасности
- /usr/local/bin/emergency_access.sh - Аварийное восстановление
- /usr/local/bin/backup_security_configs.sh - Резервное копирование

ЛОГИ:
- /var/log/auth.log - Основные логи аутентификации
- /var/log/ssh-security/ - Логи безопасности SSH
- /var/log/security_setup_report.log - Отчет о настройке

КОНТАКТЫ:
- Администратор: admin@company.local
- Аварийные ситуации: Использовать emergency_access.sh

=== КОНЕЦ ОТЧЕТА ===
EOF
```

#### 10.2 Финальная проверка
```bash
# Запустить все проверки
/usr/local/bin/test_access.sh

# Проверить логи
tail -20 /var/log/auth.log
tail -20 /var/log/ssh-security/security_monitor.log

# Проверить статус всех сервисов
systemctl status ssh fail2ban rsyslog

echo "=== НАСТРОЙКА PAM БЕЗОПАСНОСТИ ЗАВЕРШЕНА ==="
echo "Отчет сохранен в: /var/log/security_setup_report.log"
echo "Для тестирования используйте: /usr/local/bin/test_access.sh"
echo "Для аварийного восстановления: /usr/local/bin/emergency_access.sh"
```

## Рекомендации по эксплуатации

### Ежедневные проверки
```bash
# Быстрая проверка безопасности
/usr/local/bin/security_monitor.sh

# Проверка статуса fail2ban
fail2ban-client status sshd

# Проверка SSH подключений
ss -tlnp | grep :22
```

### Еженедельные задачи
```bash
# Полная проверка безопасности
/usr/local/bin/test_access.sh

# Обновление системы
apt update && apt upgrade -y

# Проверка резервных копий
ls -la /etc/backups/security/
```

### Ежемесячные задачи
```bash
# Аудит пользователей
cat /etc/security/access.conf

# Проверка логов безопасности
grep "pam_faillock" /var/log/auth.log | tail -50

# Обновление паролей пользователей
passwd admin
passwd operator
passwd monitor
```

## Устранение неполадок

### Проблема: SSH недоступен
**Решение:**
1. Использовать скрипт аварийного доступа: `/usr/local/bin/emergency_access.sh`
2. Подключиться через консоль виртуализации
3. Проверить статус SSH: `systemctl status ssh`
4. Проверить конфигурацию: `sshd -t`

### Проблема: Пользователь не может подключиться
**Решение:**
1. Проверить IP адрес пользователя
2. Проверить `/etc/security/access.conf`
3. Проверить логи: `tail -f /var/log/auth.log`
4. Проверить UFW правила: `ufw status`

### Проблема: Высокое количество блокировок
**Решение:**
1. Проверить fail2ban: `fail2ban-client status sshd`
2. Проверить заблокированные IP: `fail2ban-client status sshd`
3. Настроить алерты в мониторинге
4. Рассмотреть увеличение порогов блокировки

## Контакты и поддержка

- **Администратор системы:** admin@company.local
- **Аварийные ситуации:** Использовать `/usr/local/bin/emergency_access.sh`
- **Мониторинг:** Проверять `/var/log/ssh-security/security_monitor.log`

---

**Версия документации:** 1.0  
**Дата создания:** $(date)  
**Автор:** System Administrator  
**Статус:** Готово к использованию
