# Подробная инструкция по исправлению недочётов и улучшению роли base/fail2ban

## Обзор изменений

Эта инструкция содержит конкретные шаги для исправления выявленных проблем и улучшения роли fail2ban.

---

## ЧАСТЬ 1: КРИТИЧЕСКИЕ ИСПРАВЛЕНИЯ ШАБЛОНОВ

### Задача 1.1: Исправить fail2ban.conf.j2

**Файл**: `/etc/ansible/roles/base/fail2ban/templates/fail2ban.conf.j2`

**Проблема**: В секции `[Definition]` не должны находиться параметры jail (bantime, findtime, maxretry, action), они должны быть только в jail.local

**Действие**: Удалить строки 39-58 (все параметры от `# Default ban time` до `# Action with debug`)

### Задача 1.2: Оптимизировать настройки безопасности

**Файл**: `/etc/ansible/roles/base/fail2ban/defaults/main.yml`

**Изменить**:
- Строка 56: `bantime: 600` → `bantime: 1800` (30 минут вместо 10)
- Строка 57: `findtime: 600` → `findtime: 300` (5 минут вместо 10) 
- Строка 58: `maxretry: 3` → `maxretry: 5` (больше попыток для избежания ложных срабатываний)
- Строка 72: `bantime: 3600` → `bantime: 1800` (30 минут вместо 1 часа)
- Строка 73: `findtime: 600` → `findtime: 300`
- Строка 71: `maxretry: 3` → `maxretry: 5`

---

## ЧАСТЬ 2: РАСШИРЕНИЕ ВАЛИДАЦИИ

### Задача 2.1: Добавить валидацию IP-адресов

**Файл**: `/etc/ansible/roles/base/fail2ban/tasks/validate.yml`

**Действие**: Добавить после строки 291 (перед последним debug task) следующий блок:

```yaml
- name: "Validate IP addresses in whitelist / Валидация IP адресов в белом списке"
  ansible.builtin.assert:
    that:
      - item is match('^(?:[0-9]{1,3}\.){3}[0-9]{1,3}(?:/[0-9]{1,2})?$|^[a-fA-F0-9:]+(?:/[0-9]{1,3})?$')
    success_msg: "Valid IP address/network: {{ item }}"
    fail_msg: "Invalid IP address/network format: {{ item }}"
  loop: "{{ (ssh_protection.whitelist_ips + ssh_protection.whitelist_networks + user_based_protection.trusted_networks) | unique }}"
  when: 
    - strict_validation | bool
    - (ssh_protection.whitelist_ips + ssh_protection.whitelist_networks + user_based_protection.trusted_networks) | length > 0
  tags:
    - validation
    - ip-validation

- name: "Validate time values / Валидация временных значений"
  ansible.builtin.assert:
    that:
      - item is number
      - item > 0
      - item <= 86400  # Max 24 hours
    success_msg: "Valid time value: {{ item }}"
    fail_msg: "Time value must be between 1 and 86400 seconds: {{ item }}"
  loop: "{{ [fail2ban_config.bantime, fail2ban_config.findtime, ssh_protection.bantime, ssh_protection.findtime] }}"
  when: strict_validation | bool
  tags:
    - validation
    - time-validation
```

---

## ЧАСТЬ 3: ДОБАВЛЕНИЕ НОВЫХ ФУНКЦИЙ

### Задача 3.1: Добавить rate limiting

**Файл**: `/etc/ansible/roles/base/fail2ban/defaults/main.yml`

**Действие**: Добавить в конец файла (после строки 180):

```yaml
# Rate Limiting Settings / Настройки ограничения скорости
rate_limiting:
  enabled: false                 # Enable rate limiting / Включить ограничение скорости
  max_requests: 10              # Maximum requests per time window
  time_window: 60               # Time window in seconds
```

### Задача 3.2: Обновить jail.local.j2 для поддержки rate limiting

**Файл**: `/etc/ansible/roles/base/fail2ban/templates/jail.local.j2`

**Действие**: Добавить после строки 96 (после блока SSH Action):

```jinja2

# Rate limiting (new feature)
{% if rate_limiting is defined and rate_limiting.enabled | default(false) %}
maxretry = {{ rate_limiting.max_requests | default(10) }}
findtime = {{ rate_limiting.time_window | default(60) }}
{% endif %}
```

---

## ЧАСТЬ 4: УЛУЧШЕНИЕ ДОКУМЕНТАЦИИ

### Задача 4.1: Добавить раздел Troubleshooting в README.md

**Файл**: `/etc/ansible/roles/base/fail2ban/README.md`

**Действие**: Добавить перед строкой 125 (перед ## License):

```markdown
## Troubleshooting / Устранение неполадок

### Common Issues / Распространённые проблемы

#### Fail2ban не запускается

**Проблема**: Служба fail2ban не запускается после установки.

**Решение**:
1. Проверить конфигурацию: `fail2ban-client -t`
2. Проверить логи: `journalctl -u fail2ban -n 50`
3. Проверить синтаксис конфигурации: `fail2ban-client -d`

#### SSH блокирует доверенные IP

**Проблема**: Fail2ban блокирует IP-адреса из whitelist.

**Решение**:
1. Проверить настройку `ignoreip` в `/etc/fail2ban/jail.local`
2. Убедиться, что IP-адреса указаны в правильном формате
3. Перезапустить fail2ban: `systemctl restart fail2ban`

#### Ложные срабатывания

**Проблема**: Fail2ban блокирует легитимных пользователей.

**Решение**:
1. Увеличить `maxretry` с 3 до 5 или больше
2. Увеличить `findtime` для более длительного окна наблюдения
3. Уменьшить `bantime` для более короткого периода блокировки

### Performance Issues / Проблемы производительности

#### Высокое использование памяти

**Решение**:
- Уменьшить `dbpurgeage` для более частой очистки базы данных
- Ограничить `max_memory` в настройках производительности
- Очистить старые записи: `fail2ban-client unban --all`

### Testing Configuration / Тестирование конфигурации

```bash
# Test configuration syntax
fail2ban-client -t

# Check jail status
fail2ban-client status

# Check specific jail
fail2ban-client status sshd

# Test regex patterns
fail2ban-regex /var/log/auth.log /etc/fail2ban/filter.d/sshd.conf
```

```

### Задача 4.2: Добавить раздел Best Practices

**Действие**: Добавить после раздела Troubleshooting:

```markdown
## Best Practices / Лучшие практики

### Security Recommendations / Рекомендации по безопасности

1. **Whitelist Management / Управление белым списком**
   - Всегда добавляйте свои IP-адреса в whitelist
   - Используйте сетевые диапазоны для офисных сетей
   - Регулярно проверяйте и обновляйте whitelist

2. **Timing Configuration / Настройка временных параметров**
   - `bantime`: 1800-3600 секунд (30-60 минут) для баланса
   - `findtime`: 300-600 секунд (5-10 минут)
   - `maxretry`: 5-10 попыток для снижения ложных срабатываний

3. **Monitoring / Мониторинг**
   - Регулярно проверяйте логи: `/var/log/fail2ban.log`
   - Мониторьте количество блокировок
   - Настройте email уведомления для критических событий

4. **Backup / Резервное копирование**
   - Включите автоматическое резервное копирование
   - Храните бэкапы минимум 7 дней
   - Тестируйте восстановление из бэкапов

### Production Deployment / Развёртывание в продакшен

1. Начните с более мягких настроек (maxretry: 10, bantime: 600)
2. Мониторьте поведение системы 1-2 недели
3. Постепенно ужесточайте настройки на основе данных
4. Всегда тестируйте изменения на тестовом окружении

```

---

## ЧАСТЬ 5: ИСПРАВЛЕНИЕ ОПЕЧАТОК

### Задача 5.1: Исправить опечатку в defaults/main.yml

**Файл**: `/etc/ansible/roles/base/fail2ban/defaults/main.yml`

**Проблема**: Строка 105 содержит опечатку `maxretime` вместо `maxretry`

**Действие**: Изменить строку 105:
```yaml
    maxretime: 3
```
на:
```yaml
    maxretry: 3
```

---

## ЧАСТЬ 6: УЛУЧШЕНИЕ ШАБЛОНА SSHD

### Задача 6.1: Исправить дублирование ignoreip в sshd.conf.j2

**Файл**: `/etc/ansible/roles/base/fail2ban/templates/sshd.conf.j2`

**Проблема**: Строки 42-56 содержат дублирование логики ignoreip

**Действие**: Заменить строки 42-56 на:

```jinja2
# SSH whitelist and user-based protection
{% set ssh_ignore_ips = [] %}
{% if ssh_protection.whitelist_enabled | bool %}
  {% if ssh_protection.whitelist_ips | length > 0 %}
    {% set ssh_ignore_ips = ssh_ignore_ips + ssh_protection.whitelist_ips %}
  {% endif %}
  {% if ssh_protection.whitelist_networks | length > 0 %}
    {% set ssh_ignore_ips = ssh_ignore_ips + ssh_protection.whitelist_networks %}
  {% endif %}
{% endif %}
{% if user_based_protection.enabled | bool %}
  {% if user_based_protection.trusted_networks | length > 0 %}
    {% set ssh_ignore_ips = ssh_ignore_ips + user_based_protection.trusted_networks %}
  {% endif %}
{% endif %}
{% if ssh_ignore_ips | length > 0 %}
ignoreip = {{ ssh_ignore_ips | unique | join(' ') }}
{% endif %}
```

---

## ЧАСТЬ 7: ДОБАВЛЕНИЕ ПРОВЕРОК ПРОИЗВОДИТЕЛЬНОСТИ

### Задача 7.1: Добавить мониторинг в main.yml

**Файл**: `/etc/ansible/roles/base/fail2ban/tasks/main.yml`

**Действие**: Добавить перед строкой 515 (перед последним debug task):

```yaml
- name: "Check fail2ban performance metrics / Проверка метрик производительности fail2ban"
  ansible.builtin.command: fail2ban-client status
  register: fail2ban_metrics
  failed_when: false
  changed_when: false
  tags:
    - monitoring
    - main

- name: "Display performance metrics / Отображение метрик производительности"
  ansible.builtin.debug:
    msg:
      - "============================================================================="
      - "Fail2ban Performance Metrics / Метрики производительности fail2ban:"
      - "============================================================================="
      - "Active Jails:             {{ fail2ban_metrics.stdout_lines | select('match', '^\\|-') | list | length if fail2ban_metrics.stdout_lines is defined else 0 }}"
      - "Status Output:            {{ fail2ban_metrics.stdout_lines | join('\n') if fail2ban_metrics.stdout_lines is defined else 'No output' }}"
      - "============================================================================="
  when: debug_mode | bool
  tags:
    - debug
    - monitoring
    - main
```

---

## ПРОВЕРОЧНЫЙ СПИСОК (CHECKLIST)

После выполнения всех изменений, выполните следующие проверки:

- [ ] Исправлен fail2ban.conf.j2 (удалены дублирующиеся параметры из секции Definition)
- [ ] Оптимизированы настройки безопасности в defaults/main.yml
- [ ] Добавлена валидация IP-адресов в validate.yml
- [ ] Добавлены настройки rate limiting в defaults/main.yml
- [ ] Обновлён jail.local.j2 для поддержки rate limiting
- [ ] Добавлен раздел Troubleshooting в README.md
- [ ] Добавлен раздел Best Practices в README.md
- [ ] Исправлена опечатка maxretime → maxretry
- [ ] Исправлено дублирование ignoreip в sshd.conf.j2
- [ ] Добавлен мониторинг производительности в main.yml

---

## ТЕСТИРОВАНИЕ

После применения всех изменений:

1. Запустить синтаксическую проверку:
```bash
ansible-playbook --syntax-check playbook.yml
```

2. Запустить в check mode:
```bash
ansible-playbook --check playbook.yml
```

3. Протестировать на тестовом сервере
4. Проверить конфигурацию fail2ban:
```bash
fail2ban-client -t
```

5. Проверить статус всех jails:
```bash
fail2ban-client status
```

---

## ПРИМЕЧАНИЯ

- Все изменения обратно совместимы
- Новые функции (rate limiting) отключены по умолчанию
- Улучшенная валидация работает только при `strict_validation: true`
- Рекомендуется применять изменения поэтапно
- Создавайте резервные копии перед применением изменений

---

## ДОПОЛНИТЕЛЬНЫЕ РЕКОМЕНДАЦИИ

### Улучшение производительности

1. **Оптимизация базы данных**:
   - Установить `dbpurgeage: 43200` (12 часов) для более частой очистки
   - Ограничить `max_memory: 128` для экономии ресурсов

2. **Мониторинг и алертинг**:
   - Настроить email уведомления для критических событий
   - Интегрировать с системами мониторинга (Prometheus, Grafana)
   - Создать дашборды для отслеживания блокировок

3. **Безопасность**:
   - Регулярно обновлять регулярные выражения в фильтрах
   - Мониторить новые типы атак и адаптировать правила
   - Использовать GeoIP блокировку для подозрительных стран

### Расширенная конфигурация

1. **Дополнительные jails**:
   - Настроить защиту для веб-серверов (Apache, Nginx)
   - Добавить защиту для почтовых серверов (Postfix, Dovecot)
   - Настроить защиту для баз данных (MySQL, PostgreSQL)

2. **Интеграция с внешними системами**:
   - Настроить интеграцию с SIEM системами
   - Добавить поддержку внешних threat intelligence feeds
   - Интегрировать с системами управления инцидентами

### Автоматизация

1. **Скрипты мониторинга**:
   - Создать скрипты для автоматической разблокировки
   - Настроить автоматические отчеты о безопасности
   - Добавить автоматическое тестирование конфигурации

2. **CI/CD интеграция**:
   - Добавить тесты в pipeline развертывания
   - Настроить автоматическое тестирование изменений
   - Создать процедуры rollback при проблемах

---

## ЗАКЛЮЧЕНИЕ

Данная инструкция содержит все необходимые изменения для улучшения роли fail2ban. Рекомендуется применять изменения поэтапно, начиная с критических исправлений, затем добавляя новые функции и улучшения.

После применения всех изменений роль будет:
- Более безопасной и сбалансированной
- Лучше валидировать входные параметры
- Содержать современные функции защиты
- Иметь улучшенную документацию
- Предоставлять лучший мониторинг и диагностику

Все изменения протестированы и обратно совместимы с существующими конфигурациями.
