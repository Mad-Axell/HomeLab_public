# Развернутые рекомендации по улучшению роли configure_pam

## Обзор и анализ текущего состояния

### Текущие возможности роли:
- ✅ Настройка PAM faillock для защиты от брутфорс атак
- ✅ Конфигурация качества паролей (pwquality)
- ✅ Управление пользователями с группами
- ✅ Настройка PAM limits для контроля ресурсов
- ✅ Предварительные проверки безопасности
- ✅ Резервное копирование конфигураций

### Критические недостатки:
- ❌ Отсутствует SSH конфигурация с ограничениями по подсетям
- ❌ Неполная PAM sshd конфигурация
- ❌ Нет настройки файрвола (UFW)
- ❌ Отсутствует fail2ban
- ❌ Неполное логирование безопасности
- ❌ Нет плана аварийного восстановления

---

## ЭТАП 1: Подготовка и планирование

### Шаг 1.1: Анализ требований безопасности

**Цель:** Определить полный набор требований безопасности для роли.

**Действия:**
1. Изучить существующую инфраструктуру
2. Определить разрешенные подсети
3. Выявить роли пользователей
4. Спланировать уровни защиты

**Создать файл:** `docs/security_requirements.md`
```markdown
# Требования безопасности для роли configure_pam

## Сетевые ограничения
- Разрешенные подсети: 10.20.30.0/24, 192.168.1.0/24, 10.30.150.0/24
- Запрещенные подсети: все остальные
- SSH порт: 22 (стандартный)

## Роли пользователей
- admin: полный доступ с ограниченных подсетей
- operator: ограниченный доступ
- monitor: доступ только для мониторинга

## Уровни защиты
1. Сетевой (UFW файрвол)
2. SSH (Match блоки)
3. PAM (access control)
4. Приложение (fail2ban)
```

### Шаг 1.2: Создание структуры новых файлов

**Цель:** Организовать новые файлы задач по функциональности.

**Создать директории:**
```bash
mkdir -p /etc/ansible/roles/base/configure_pam/tasks/{ssh,firewall,monitoring,recovery}
mkdir -p /etc/ansible/roles/base/configure_pam/templates/{ssh,firewall,scripts}
mkdir -p /etc/ansible/roles/base/configure_pam/files/{scripts,configs}
```

**Структура файлов:**
```
tasks/
├── ssh/
│   ├── ssh_config.yml
│   ├── ssh_security.yml
│   └── ssh_testing.yml
├── firewall/
│   ├── ufw_setup.yml
│   ├── iptables_rules.yml
│   └── firewall_testing.yml
├── monitoring/
│   ├── logging_setup.yml
│   ├── fail2ban_config.yml
│   └── monitoring_scripts.yml
└── recovery/
    ├── backup_scripts.yml
    ├── emergency_recovery.yml
    └── rollback_procedures.yml
```

---

## ЭТАП 2: SSH конфигурация с ограничениями по подсетям

### Шаг 2.1: Создание SSH конфигурации

**Файл:** `tasks/ssh/ssh_config.yml`

```yaml
---
# SSH Configuration with Subnet Restrictions
# Конфигурация SSH с ограничениями по подсетям

- name: "Backup SSH configuration / Создать резервную копию SSH конфигурации"
  ansible.builtin.copy:
    src: /etc/ssh/sshd_config
    dest: "/etc/backups/security/sshd_config.backup.{{ ansible_date_time.epoch }}"
    remote_src: yes
    backup: no
  when: pam_backup_enabled

- name: "Configure SSH basic settings / Настроить базовые параметры SSH"
  ansible.builtin.lineinfile:
    path: /etc/ssh/sshd_config
    regexp: "^{{ item.regexp }}"
    line: "{{ item.line }}"
    state: present
    backup: yes
  loop:
    - { regexp: '^#?Port', line: 'Port {{ ssh_port | default(22) }}' }
    - { regexp: '^#?Protocol', line: 'Protocol 2' }
    - { regexp: '^#?AddressFamily', line: 'AddressFamily inet' }
    - { regexp: '^#?LoginGraceTime', line: 'LoginGraceTime 2m' }
    - { regexp: '^#?StrictModes', line: 'StrictModes yes' }
    - { regexp: '^#?MaxAuthTries', line: 'MaxAuthTries {{ ssh_max_auth_tries | default(3) }}' }
    - { regexp: '^#?MaxSessions', line: 'MaxSessions {{ ssh_max_sessions | default(3) }}' }
    - { regexp: '^#?PubkeyAuthentication', line: 'PubkeyAuthentication yes' }
    - { regexp: '^#?AuthorizedKeysFile', line: 'AuthorizedKeysFile .ssh/authorized_keys' }
    - { regexp: '^#?PasswordAuthentication', line: 'PasswordAuthentication yes' }
    - { regexp: '^#?PermitEmptyPasswords', line: 'PermitEmptyPasswords no' }
    - { regexp: '^#?ChallengeResponseAuthentication', line: 'ChallengeResponseAuthentication no' }
    - { regexp: '^#?X11Forwarding', line: 'X11Forwarding no' }
    - { regexp: '^#?PrintMotd', line: 'PrintMotd no' }
    - { regexp: '^#?PrintLastLog', line: 'PrintLastLog yes' }
    - { regexp: '^#?TCPKeepAlive', line: 'TCPKeepAlive yes' }
    - { regexp: '^#?SyslogFacility', line: 'SyslogFacility AUTH' }
    - { regexp: '^#?LogLevel', line: 'LogLevel INFO' }
  notify: reload sshd config

- name: "Configure SSH subnet restrictions / Настроить ограничения SSH по подсетям"
  ansible.builtin.blockinfile:
    path: /etc/ssh/sshd_config
    block: |
      # SSH Subnet Access Control
      # Разрешить доступ с основных подсетей
      Match Address {{ ssh_allowed_subnets | join(',') }}
          AllowUsers {{ ssh_allowed_users | join(' ') }}
          PermitRootLogin {{ 'yes' if ssh_allow_root else 'no' }}
          PasswordAuthentication yes
          PubkeyAuthentication yes
          MaxAuthTries {{ ssh_max_auth_tries | default(3) }}
      
      # Разрешить доступ с NVR подсети только для мониторинга
      Match Address {{ ssh_monitor_subnets | join(',') }}
          AllowUsers {{ ssh_monitor_users | join(' ') }}
          PermitRootLogin no
          PasswordAuthentication yes
          PubkeyAuthentication yes
          MaxAuthTries {{ ssh_max_auth_tries | default(3) }}
      
      # Запретить доступ с других подсетей
      Match Address *
          AllowUsers none
          DenyUsers *
          PermitRootLogin no
          PasswordAuthentication no
          PubkeyAuthentication no
    marker: "# {mark} ANSIBLE MANAGED SSH SUBNET RESTRICTIONS"
    state: present
    backup: yes
  notify: reload sshd config

- name: "Validate SSH configuration / Проверить конфигурацию SSH"
  ansible.builtin.command: sshd -t
  register: ssh_config_validation
  changed_when: false
  failed_when: ssh_config_validation.rc != 0

- name: "Display SSH configuration validation results / Показать результаты проверки SSH"
  ansible.builtin.debug:
    msg: "SSH configuration validation: {{ 'PASSED' if ssh_config_validation.rc == 0 else 'FAILED' }}"
  when: debug_mode
```

### Шаг 2.2: Создание PAM sshd конфигурации

**Файл:** `tasks/ssh/ssh_security.yml`

```yaml
---
# SSH Security Configuration with PAM
# Конфигурация безопасности SSH с PAM

- name: "Backup PAM sshd configuration / Создать резервную копию PAM sshd"
  ansible.builtin.copy:
    src: /etc/pam.d/sshd
    dest: "/etc/backups/security/sshd.backup.{{ ansible_date_time.epoch }}"
    remote_src: yes
    backup: no
  when: pam_backup_enabled

- name: "Configure PAM sshd with access control / Настроить PAM sshd с контролем доступа"
  ansible.builtin.copy:
    dest: /etc/pam.d/sshd
    content: |
      # PAM configuration for the Secure Shell service
      # Generated by Ansible role configure_pam
      # Date: {{ ansible_date_time.iso8601 }}
      
      # Standard Unix authentication
      auth       required     pam_env.so
      auth       required     pam_env.so envfile=/etc/default/locale
      
      # Network access control
      auth       required     pam_access.so accessfile={{ pam_access_file }}
      
      # Brute force protection
      auth       required     pam_faillock.so preauth audit silent deny={{ pam_faillock_deny }} unlock_time={{ pam_unlock_time }}
      auth       sufficient   pam_unix.so nullok_secure
      auth       [default=die] pam_faillock.so authfail audit deny={{ pam_faillock_deny }} unlock_time={{ pam_unlock_time }}
      auth       required     pam_faillock.so authsucc audit deny={{ pam_faillock_deny }} unlock_time={{ pam_unlock_time }}
      
      # Additional security checks
      auth       optional     pam_cap.so
      {% if pam_u2f_enabled %}
      auth       optional     pam_u2f.so authfile=/etc/u2f_mappings
      {% endif %}
      
      # Account management
      account    required     pam_access.so accessfile={{ pam_access_file }}
      account    required     pam_faillock.so
      account    required     pam_nologin.so
      account    required     pam_unix.so
      
      # Session management
      session    required     pam_limits.so
      session    required     pam_loginuid.so
      session    optional     pam_keyinit.so force revoke
      session    required     pam_unix.so
      
      # Password management
      password   required     pam_unix.so obscure sha512
    backup: yes
  notify: restart ssh

- name: "Configure PAM access control file / Настроить файл контроля доступа PAM"
  ansible.builtin.template:
    src: access.conf.j2
    dest: "{{ pam_access_file }}"
    mode: '0644'
    owner: root
    group: root
    backup: yes
  notify: restart ssh

- name: "Test PAM sshd configuration / Протестировать конфигурацию PAM sshd"
  ansible.builtin.command: pam-config --query --sshd
  register: pam_sshd_test
  changed_when: false
  failed_when: false

- name: "Display PAM sshd test results / Показать результаты теста PAM sshd"
  ansible.builtin.debug:
    msg: "PAM sshd test: {{ pam_sshd_test.stdout | default('test failed') }}"
  when: debug_mode
```

---

## ЭТАП 3: Настройка файрвола UFW

### Шаг 3.1: Установка и базовая настройка UFW

**Файл:** `tasks/firewall/ufw_setup.yml`

```yaml
---
# UFW Firewall Setup
# Настройка файрвола UFW

- name: "Install UFW package / Установить пакет UFW"
  ansible.builtin.package:
    name: ufw
    state: present
  when: ufw_enabled

- name: "Stop UFW service before configuration / Остановить службу UFW перед настройкой"
  ansible.builtin.service:
    name: ufw
    state: stopped
  when: ufw_enabled

- name: "Reset UFW rules / Сбросить правила UFW"
  ansible.builtin.command: ufw --force reset
  changed_when: true
  when: ufw_enabled

- name: "Configure UFW default policies / Настроить политики UFW по умолчанию"
  ansible.builtin.ufw:
    direction: "{{ item.direction }}"
    policy: "{{ item.policy }}"
  loop:
    - { direction: 'incoming', policy: 'deny' }
    - { direction: 'outgoing', policy: 'allow' }
  when: ufw_enabled

- name: "Allow SSH from allowed subnets / Разрешить SSH с разрешенных подсетей"
  ansible.builtin.ufw:
    rule: allow
    src: "{{ item }}"
    port: "{{ ssh_port | default('22') }}"
    proto: tcp
    comment: "SSH from {{ item }}"
  loop: "{{ ufw_allowed_subnets | default(ssh_allowed_subnets) }}"
  when: ufw_enabled

- name: "Allow SSH from monitor subnets / Разрешить SSH с подсетей мониторинга"
  ansible.builtin.ufw:
    rule: allow
    src: "{{ item }}"
    port: "{{ ssh_port | default('22') }}"
    proto: tcp
    comment: "SSH monitoring from {{ item }}"
  loop: "{{ ufw_monitor_subnets | default(ssh_monitor_subnets) }}"
  when: ufw_enabled

- name: "Deny SSH from all other sources / Запретить SSH со всех остальных источников"
  ansible.builtin.ufw:
    rule: deny
    port: "{{ ssh_port | default('22') }}"
    proto: tcp
    comment: "Deny SSH from unauthorized sources"
  when: ufw_enabled

- name: "Enable UFW / Включить UFW"
  ansible.builtin.ufw:
    state: enabled
  when: ufw_enabled

- name: "Check UFW status / Проверить статус UFW"
  ansible.builtin.command: ufw status verbose
  register: ufw_status
  changed_when: false
  when: ufw_enabled

- name: "Display UFW status / Показать статус UFW"
  ansible.builtin.debug:
    msg: "{{ ufw_status.stdout_lines }}"
  when: 
    - ufw_enabled
    - debug_mode
```

### Шаг 3.2: Дополнительные правила iptables

**Файл:** `tasks/firewall/iptables_rules.yml`

```yaml
---
# Additional iptables rules for enhanced security
# Дополнительные правила iptables для повышенной безопасности

- name: "Create iptables security script / Создать скрипт безопасности iptables"
  ansible.builtin.template:
    src: iptables_security.sh.j2
    dest: /usr/local/bin/iptables_security.sh
    mode: '0755'
    owner: root
    group: root
  when: iptables_enhanced_security

- name: "Execute iptables security script / Выполнить скрипт безопасности iptables"
  ansible.builtin.command: /usr/local/bin/iptables_security.sh
  when: iptables_enhanced_security

- name: "Create iptables rules backup / Создать резервную копию правил iptables"
  ansible.builtin.command: iptables-save > /etc/backups/security/iptables_rules.backup.{{ ansible_date_time.epoch }}
  when: 
    - iptables_enhanced_security
    - pam_backup_enabled

- name: "Make iptables rules persistent / Сделать правила iptables постоянными"
  ansible.builtin.copy:
    dest: /etc/rc.local
    content: |
      #!/bin/bash
      /usr/local/bin/iptables_security.sh
      exit 0
    mode: '0755'
    owner: root
    group: root
  when: iptables_enhanced_security
```

---

## ЭТАП 4: Настройка fail2ban

### Шаг 4.1: Установка и конфигурация fail2ban

**Файл:** `tasks/monitoring/fail2ban_config.yml`

```yaml
---
# Fail2ban Configuration
# Конфигурация fail2ban

- name: "Install fail2ban package / Установить пакет fail2ban"
  ansible.builtin.package:
    name: fail2ban
    state: present
  when: fail2ban_enabled

- name: "Stop fail2ban service / Остановить службу fail2ban"
  ansible.builtin.service:
    name: fail2ban
    state: stopped
  when: fail2ban_enabled

- name: "Configure fail2ban jail.local / Настроить fail2ban jail.local"
  ansible.builtin.template:
    src: jail.local.j2
    dest: /etc/fail2ban/jail.local
    mode: '0644'
    owner: root
    group: root
    backup: yes
  when: fail2ban_enabled
  notify: restart fail2ban

- name: "Configure fail2ban sshd filter / Настроить фильтр fail2ban sshd"
  ansible.builtin.copy:
    dest: /etc/fail2ban/filter.d/sshd-custom.conf
    content: |
      [Definition]
      failregex = ^%(__prefix_line)s(?:error: PAM: )?[aA]uthentication failure for .* from <HOST>( via \w+)?\s*$
                  ^%(__prefix_line)s(?:error: PAM: )?User not known to the underlying authentication module for .* from <HOST>\s*$
                  ^%(__prefix_line)sFailed \w+ for .*? from <HOST>(?: port \d+)?(?: ssh\d*)?(: (ruser .*|(\d+\.\d+\.\d+\.\d+)|(\[.*\])))?\s*$
                  ^%(__prefix_line)sROOT LOGIN REFUSED.* FROM <HOST>\s*$
                  ^%(__prefix_line)s[iI](?:llegal|nvalid) user .* from <HOST>\s*$
                  ^%(__prefix_line)sUser .+ from <HOST> not allowed because not listed in AllowUsers\s*$
                  ^%(__prefix_line)sauthentication failure; logname=\S* uid=\S* euid=\S* tty=\S* ruser=\S* rhost=<HOST>(?:\s+user=.*)?\s*$
                  ^%(__prefix_line)srefused connect from \S+ \(<HOST>\)\s*$
                  ^%(__prefix_line)sAddress <HOST> .* POSSIBLE BREAK-IN ATTEMPT!\s*$
                  ^%(__prefix_line)sUser .+ from <HOST> not allowed because none of user's groups are listed in AllowGroups\s*$
      ignoreregex =
    mode: '0644'
    owner: root
    group: root
  when: fail2ban_enabled

- name: "Start and enable fail2ban / Запустить и включить fail2ban"
  ansible.builtin.systemd:
    name: fail2ban
    state: started
    enabled: yes
  when: fail2ban_enabled

- name: "Check fail2ban status / Проверить статус fail2ban"
  ansible.builtin.command: fail2ban-client status
  register: fail2ban_status
  changed_when: false
  when: fail2ban_enabled

- name: "Display fail2ban status / Показать статус fail2ban"
  ansible.builtin.debug:
    msg: "{{ fail2ban_status.stdout_lines }}"
  when: 
    - fail2ban_enabled
    - debug_mode
```

---

## ЭТАП 5: Централизованное логирование

### Шаг 5.1: Настройка rsyslog

**Файл:** `tasks/monitoring/logging_setup.yml`

```yaml
---
# Centralized Logging Setup
# Настройка централизованного логирования

- name: "Create SSH security log directory / Создать директорию логов SSH безопасности"
  ansible.builtin.file:
    path: /var/log/ssh-security
    state: directory
    mode: '0755'
    owner: root
    group: root
  when: security_logging_enabled

- name: "Configure rsyslog for SSH security / Настроить rsyslog для SSH безопасности"
  ansible.builtin.template:
    src: rsyslog_ssh_security.conf.j2
    dest: /etc/rsyslog.d/50-ssh-security.conf
    mode: '0644'
    owner: root
    group: root
    backup: yes
  when: security_logging_enabled
  notify: restart rsyslog

- name: "Configure logrotate for security logs / Настроить logrotate для логов безопасности"
  ansible.builtin.copy:
    dest: /etc/logrotate.d/ssh-security
    content: |
      /var/log/ssh-security/*.log {
          daily
          missingok
          rotate {{ log_retention_days | default(30) }}
          compress
          delaycompress
          notifempty
          create 644 root root
          postrotate
              /bin/kill -HUP `cat /var/run/rsyslogd.pid 2> /dev/null` 2> /dev/null || true
          endscript
      }
    mode: '0644'
    owner: root
    group: root
  when: security_logging_enabled

- name: "Create log monitoring script / Создать скрипт мониторинга логов"
  ansible.builtin.template:
    src: log_monitor.sh.j2
    dest: /usr/local/bin/log_monitor.sh
    mode: '0755'
    owner: root
    group: root
  when: security_logging_enabled

- name: "Setup log monitoring cron job / Настроить задачу cron для мониторинга логов"
  ansible.builtin.cron:
    name: "Security log monitoring"
    minute: "*/5"
    job: "/usr/local/bin/log_monitor.sh"
  when: security_logging_enabled
```

---

## ЭТАП 6: Скрипты управления и мониторинга

### Шаг 6.1: Скрипты управления пользователями

**Файл:** `tasks/monitoring/monitoring_scripts.yml`

```yaml
---
# Monitoring and Management Scripts
# Скрипты мониторинга и управления

- name: "Create user management script / Создать скрипт управления пользователями"
  ansible.builtin.template:
    src: manage_users.sh.j2
    dest: /usr/local/bin/manage_users.sh
    mode: '0755'
    owner: root
    group: root

- name: "Create security monitoring script / Создать скрипт мониторинга безопасности"
  ansible.builtin.template:
    src: security_monitor.sh.j2
    dest: /usr/local/bin/security_monitor.sh
    mode: '0755'
    owner: root
    group: root

- name: "Create access testing script / Создать скрипт тестирования доступа"
  ansible.builtin.template:
    src: test_access.sh.j2
    dest: /usr/local/bin/test_access.sh
    mode: '0755'
    owner: root
    group: root

- name: "Setup security monitoring cron job / Настроить задачу cron для мониторинга безопасности"
  ansible.builtin.cron:
    name: "Security monitoring"
    minute: "0"
    hour: "9"
    job: "/usr/local/bin/security_monitor.sh --report"
  when: security_monitoring_enabled
```

---

## ЭТАП 7: План аварийного восстановления

### Шаг 7.1: Скрипты аварийного восстановления

**Файл:** `tasks/recovery/emergency_recovery.yml`

```yaml
---
# Emergency Recovery Procedures
# Процедуры аварийного восстановления

- name: "Create emergency access script / Создать скрипт аварийного доступа"
  ansible.builtin.template:
    src: emergency_access.sh.j2
    dest: /usr/local/bin/emergency_access.sh
    mode: '0755'
    owner: root
    group: root

- name: "Create backup script / Создать скрипт резервного копирования"
  ansible.builtin.template:
    src: backup_security_configs.sh.j2
    dest: /usr/local/bin/backup_security_configs.sh
    mode: '0755'
    owner: root
    group: root

- name: "Create rollback script / Создать скрипт отката"
  ansible.builtin.template:
    src: rollback_security.sh.j2
    dest: /usr/local/bin/rollback_security.sh
    mode: '0755'
    owner: root
    group: root

- name: "Setup automatic backup cron job / Настроить автоматическое резервное копирование"
  ansible.builtin.cron:
    name: "Security config backup"
    minute: "0"
    hour: "2"
    job: "/usr/local/bin/backup_security_configs.sh"
  when: automatic_backup_enabled
```

---

## ЭТАП 8: Обновление переменных и обработчиков

### Шаг 8.1: Расширение переменных

**Добавить в `defaults/main.yml`:**

```yaml
# SSH Configuration
ssh_port: 22
ssh_protocol: 2
ssh_max_auth_tries: 3
ssh_max_sessions: 3
ssh_allow_root: false

# SSH Subnet Restrictions
ssh_allowed_subnets:
  - "10.20.30.0/24"
  - "192.168.1.0/24"
ssh_monitor_subnets:
  - "10.30.150.0/24"
ssh_allowed_users:
  - "admin"
  - "root"
  - "operator"
ssh_monitor_users:
  - "monitor"

# UFW Configuration
ufw_enabled: true
ufw_allowed_subnets: "{{ ssh_allowed_subnets }}"
ufw_monitor_subnets: "{{ ssh_monitor_subnets }}"

# iptables Enhanced Security
iptables_enhanced_security: true

# Fail2ban Configuration
fail2ban_enabled: true
fail2ban_bantime: 3600
fail2ban_findtime: 600
fail2ban_maxretry: 3

# Logging Configuration
security_logging_enabled: true
centralized_logging_enabled: true
log_retention_days: 30

# Monitoring Configuration
security_monitoring_enabled: true
monitoring_script_path: "/usr/local/bin/security_monitor.sh"

# Backup Configuration
automatic_backup_enabled: true
backup_retention_days: 30
backup_script_path: "/usr/local/bin/backup_security_configs.sh"

# Emergency Recovery
emergency_recovery_enabled: true
emergency_script_path: "/usr/local/bin/emergency_access.sh"

# PAM U2F (optional)
pam_u2f_enabled: false
```

### Шаг 8.2: Обновление обработчиков

**Обновить `handlers/main.yml`:**

```yaml
---
# Enhanced PAM configuration handlers
# Улучшенные обработчики конфигурации PAM

- name: "restart ssh / перезапустить ssh"
  ansible.builtin.service:
    name: ssh
    state: restarted
  listen: "restart ssh"

- name: "restart sshd / перезапустить sshd"
  ansible.builtin.service:
    name: sshd
    state: restarted
  listen: "restart ssh"

- name: "reload sshd config / перезагрузить конфигурацию sshd"
  ansible.builtin.service:
    name: sshd
    state: reloaded
  listen: "reload sshd config"

- name: "restart fail2ban / перезапустить fail2ban"
  ansible.builtin.service:
    name: fail2ban
    state: restarted
  listen: "restart fail2ban"

- name: "restart rsyslog / перезапустить rsyslog"
  ansible.builtin.service:
    name: rsyslog
    state: restarted
  listen: "restart rsyslog"

- name: "reload ufw / перезагрузить ufw"
  ansible.builtin.command: ufw --force reload
  changed_when: true
  listen: "reload ufw"

- name: "reload pam / перезагрузить pam"
  ansible.builtin.command: "faillock --reset"
  changed_when: false
  listen: "reload pam"

- name: "flush pam cache / очистить кэш pam"
  ansible.builtin.command: "faillock --reset --user root"
  changed_when: false
  listen: "flush pam cache"
```

---

## ЭТАП 9: Обновление основного файла задач

### Шаг 9.1: Интеграция новых задач

**Обновить `tasks/main.yml`:**

```yaml
---
# Main tasks for configure_pam role
# Основные задачи роли configure_pam

# Existing tasks...
- name: "Include pre-checks tasks / Включить задачи предварительных проверок"
  include_tasks: pre_checks.yml
  when: pam_prevent_lockout | default(true)

# ... existing tasks ...

# NEW: SSH Configuration
- name: "Include SSH configuration tasks / Включить задачи конфигурации SSH"
  include_tasks: ssh/ssh_config.yml
  when: ssh_configuration_enabled | default(true)

- name: "Include SSH security tasks / Включить задачи безопасности SSH"
  include_tasks: ssh/ssh_security.yml
  when: ssh_security_enabled | default(true)

# NEW: Firewall Configuration
- name: "Include UFW setup tasks / Включить задачи настройки UFW"
  include_tasks: firewall/ufw_setup.yml
  when: ufw_enabled

- name: "Include iptables rules tasks / Включить задачи правил iptables"
  include_tasks: firewall/iptables_rules.yml
  when: iptables_enhanced_security

# NEW: Monitoring Configuration
- name: "Include fail2ban configuration tasks / Включить задачи конфигурации fail2ban"
  include_tasks: monitoring/fail2ban_config.yml
  when: fail2ban_enabled

- name: "Include logging setup tasks / Включить задачи настройки логирования"
  include_tasks: monitoring/logging_setup.yml
  when: security_logging_enabled

- name: "Include monitoring scripts tasks / Включить задачи скриптов мониторинга"
  include_tasks: monitoring/monitoring_scripts.yml
  when: security_monitoring_enabled

# NEW: Recovery Configuration
- name: "Include emergency recovery tasks / Включить задачи аварийного восстановления"
  include_tasks: recovery/emergency_recovery.yml
  when: emergency_recovery_enabled

# Existing tasks...
- name: "Include user management tasks / Включить задачи управления пользователями"
  include_tasks: user_management.yml
  when: users_to_add | length > 0

# ... rest of existing tasks ...
```

---

## ЭТАП 10: Создание шаблонов

### Шаг 10.1: SSH шаблоны

**Файл:** `templates/ssh/access.conf.j2`

```jinja2
# PAM access control configuration
# Generated by Ansible role configure_pam
# Date: {{ ansible_date_time.iso8601 }}

# Allow local access
{% if pam_access_allow_local %}
+ : ALL : LOCAL
{% endif %}

# Allow console access
{% if pam_access_allow_console %}
+ : ALL : console
{% endif %}

# Allow specific users from allowed subnets
{% for user in users_to_add %}
{% if user.allowed_subnets is defined and user.allowed_subnets | length > 0 %}
{% for subnet in user.allowed_subnets %}
+ : {{ user.username }} : {{ subnet }}
{% endfor %}
{% endif %}
{% endfor %}

# Deny specific subnets for all users
{% for user in users_to_add %}
{% if user.denied_ssh_subnets is defined and user.denied_ssh_subnets | length > 0 %}
{% for subnet in user.denied_ssh_subnets %}
- : {{ user.username }} : {{ subnet }}
{% endfor %}
{% endif %}
{% endfor %}

# Default policy
{% if pam_access_deny_all_other %}
- : ALL : ALL
{% else %}
+ : ALL : ALL
{% endif %}
```

### Шаг 10.2: Fail2ban шаблоны

**Файл:** `templates/monitoring/jail.local.j2`

```jinja2
[DEFAULT]
# Base settings
bantime = {{ fail2ban_bantime }}
findtime = {{ fail2ban_findtime }}
maxretry = {{ fail2ban_maxretry }}
backend = systemd

[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = {{ fail2ban_maxretry }}
bantime = {{ fail2ban_bantime }}
findtime = {{ fail2ban_findtime }}

[sshd-ddos]
enabled = true
port = ssh
filter = sshd-ddos
logpath = /var/log/auth.log
maxretry = 6
bantime = {{ fail2ban_bantime }}
findtime = {{ fail2ban_findtime }}
```

---

## ЭТАП 11: Тестирование и валидация

### Шаг 11.1: Создание тестовых playbooks

**Файл:** `tests/test_pam_role.yml`

```yaml
---
# Test playbook for configure_pam role
# Тестовый playbook для роли configure_pam

- name: "Test configure_pam role / Тестировать роль configure_pam"
  hosts: test_hosts
  become: yes
  vars:
    debug_mode: true
    ssh_configuration_enabled: true
    ufw_enabled: true
    fail2ban_enabled: true
    security_logging_enabled: true
    users_to_add:
      - username: "testuser"
        password: "TestPass123!"
        groups: ["sudo"]
        allowed_subnets:
          - "10.20.30.0/24"
  
  roles:
    - configure_pam
  
  post_tasks:
    - name: "Run security tests / Запустить тесты безопасности"
      command: /usr/local/bin/test_access.sh
      register: test_results
    
    - name: "Display test results / Показать результаты тестов"
      debug:
        msg: "{{ test_results.stdout_lines }}"
```

### Шаг 11.2: Процедуры тестирования

**Создать файл:** `tests/testing_procedures.md`

```markdown
# Процедуры тестирования роли configure_pam

## Предварительное тестирование
1. Запустить playbook в режиме --check
2. Проверить синтаксис всех конфигураций
3. Убедиться в наличии всех зависимостей

## Функциональное тестирование
1. SSH доступ с разрешенных подсетей
2. Блокировка SSH с неразрешенных подсетей
3. Работа fail2ban при попытках взлома
4. Логирование событий безопасности
5. Функционирование скриптов мониторинга

## Тестирование аварийного восстановления
1. Симуляция блокировки SSH
2. Запуск скрипта аварийного восстановления
3. Проверка восстановления доступа
4. Тестирование отката конфигураций
```

---

## ЭТАП 12: Документация и развертывание

### Шаг 12.1: Обновление документации

**Обновить `README.md`:**

```markdown
# Configure PAM Role - Enhanced Security

## Новые возможности
- SSH конфигурация с ограничениями по подсетям
- UFW файрвол с правилами безопасности
- fail2ban для защиты от атак
- Централизованное логирование
- Скрипты мониторинга и управления
- План аварийного восстановления

## Переменные
[Список всех новых переменных]

## Примеры использования
[Примеры конфигураций]

## Процедуры тестирования
[Инструкции по тестированию]
```

### Шаг 12.2: План развертывания

**Создать файл:** `docs/deployment_plan.md`

```markdown
# План развертывания улучшенной роли configure_pam

## Фаза 1: Подготовка (1-2 дня)
- Создание тестовой среды
- Подготовка всех файлов
- Тестирование на изолированной системе

## Фаза 2: Пилотное развертывание (3-5 дней)
- Развертывание на тестовом хосте
- Проверка всех функций
- Исправление выявленных проблем

## Фаза 3: Массовое развертывание (1-2 недели)
- Поэтапное развертывание на всех хостах
- Мониторинг процесса
- Документирование результатов

## Фаза 4: Поддержка и оптимизация (постоянно)
- Мониторинг работы системы
- Обновление конфигураций
- Улучшение процедур
```

---

## Заключение

Данные развернутые рекомендации предоставляют пошаговый план превращения текущей роли `configure_pam` в комплексное решение для настройки PAM безопасности. Каждый этап детально описан с примерами кода, что позволяет систематически внедрить все улучшения.

**Ключевые преимущества после внедрения:**
- Многоуровневая защита (сеть → SSH → PAM → приложение)
- Автоматизированное управление пользователями
- Централизованный мониторинг безопасности
- План аварийного восстановления
- Полная документация и тестирование

**Время внедрения:** 2-3 недели при работе одного администратора
**Сложность:** Средняя (требует знания Ansible, PAM, SSH, UFW)
**Риски:** Низкие (при поэтапном внедрении с тестированием)
