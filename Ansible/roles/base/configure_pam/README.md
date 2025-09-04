# Роль настройки PAM (Pluggable Authentication Modules)

Эта Ansible роль предназначена для настройки и усиления безопасности системы аутентификации Linux через PAM модули. Роль обеспечивает комплексную защиту от атак методом перебора, улучшает качество паролей и ограничивает доступ к критическим функциям системы.

## 🎯 Назначение

Роль `configure_pam` реализует следующие меры безопасности:

- **Защита от блокировки аккаунтов** - предотвращает атаки методом перебора
- **Контроль качества паролей** - обеспечивает надежные пароли пользователей
- **Управление сессиями** - ограничивает количество одновременных входов
- **Контроль повышения привилегий** - ограничивает доступ к `su` и `sudo`
- **Ограничения доступа root** - защищает вход root и SSH доступ
- **Дополнительная безопасность** - реализует umask и MOTD

## 📋 Требования

### Системные требования
- **Ansible**: версия 2.9 или выше
- **Операционные системы**: 
  - Debian/Ubuntu (все версии)
  - RedHat/CentOS 7, 8, 9
  - Rocky Linux 8, 9
  - AlmaLinux 8, 9
- **Привилегии**: root или sudo права
- **PAM модули**: обычно предустановлены в системе

### Зависимости
- `ansible.builtin` - базовые модули Ansible
- `ansible.posix` - модули для работы с файлами и сервисами
- `ansible.utils` - утилиты для валидации

## 🚀 Быстрый старт

### 1. Базовая установка

```yaml
---
- hosts: servers
  become: yes
  roles:
    - role: base/configure_pam
```

### 2. С настройками по умолчанию

```yaml
---
- hosts: servers
  become: yes
  vars:
    debug_mode: true
    pam_backup_enabled: true
  
  roles:
    - role: base/configure_pam
```

### 3. С пользовательскими настройками

```yaml
---
- hosts: servers
  become: yes
  vars:
    # Настройки блокировки аккаунтов
    pam_faillock_deny: 5
    pam_unlock_time: 900  # 15 минут
    
    # Требования к паролям
    pam_pwquality_minlen: 16
    pam_pwquality_minclass: 4
    
    # Ограничения SSH
    ssh_security:
      max_auth_tries: 2
      permit_empty_passwords: "no"
  
  roles:
    - role: base/configure_pam
```

## ⚙️ Переменные роли

### Основные настройки

| Переменная | По умолчанию | Описание |
|------------|--------------|----------|
| `debug_mode` | `false` | Включить подробный вывод отладки |
| `pam_backup_enabled` | `true` | Создавать резервные копии перед изменениями |
| `pam_backup_suffix` | `.backup` | Суффикс резервного файла |

### Блокировка аккаунтов (pam_faillock)

| Переменная | По умолчанию | Описание |
|------------|--------------|----------|
| `pam_faillock_deny` | `3` | Количество неудачных попыток до блокировки (1-10) |
| `pam_unlock_time` | `1800` | Длительность блокировки в секундах (60-86400) |
| `pam_faillock_audit` | `true` | Включить аудит неудачных попыток |
| `pam_faillock_silent` | `false` | Тихий режим блокировки |

### Качество паролей

| Переменная | По умолчанию | Описание |
|------------|--------------|----------|
| `pam_pwquality_retry` | `3` | Количество попыток ввода пароля (1-5) |
| `pam_pwquality_minlen` | `12` | Минимальная длина пароля (8-32) |
| `pam_pwquality_difok` | `5` | Минимум разных символов от старого пароля (1-10) |
| `pam_pwquality_ucredit` | `-1` | Требовать заглавные буквы |
| `pam_pwquality_lcredit` | `-1` | Требовать строчные буквы |
| `pam_pwquality_dcredit` | `-1` | Требовать цифры |
| `pam_pwquality_ocredit` | `-1` | Требовать специальные символы |
| `pam_pwquality_minclass` | `3` | Требовать классы символов (1-4) |
| `pam_pwquality_maxrepeat` | `2` | Максимум последовательных повторяющихся символов (0-10) |
| `pam_pwquality_gecoscheck` | `true` | Проверять против информации GECOS |
| `pam_pwquality_reject_username` | `true` | Отклонять пароли с именем пользователя |

### Сессии и лимиты

| Переменная | По умолчанию | Описание |
|------------|--------------|----------|
| `pam_limits_enabled` | `true` | Включить PAM лимиты |
| `pam_limits_maxlogins` | `10` | Максимум одновременных входов на пользователя (1-100) |
| `pam_limits_maxsyslogins` | `50` | Максимум одновременных системных входов (10-1000) |

### Wheel и Sudo

| Переменная | По умолчанию | Описание |
|------------|--------------|----------|
| `pam_wheel_group` | `sudo` | Группа для функциональности wheel |
| `pam_wheel_use_uid` | `true` | Использовать UID вместо имени пользователя |

### Безопасность root

| Переменная | По умолчанию | Описание |
|------------|--------------|----------|
| `pam_root_console_only` | `true` | Ограничить root только консолью |
| `pam_root_securetty` | `true` | Использовать безопасный TTY для входа root |

### SSH безопасность

| Переменная | По умолчанию | Описание |
|------------|--------------|----------|
| `ssh_security.max_auth_tries` | `3` | Максимум попыток аутентификации SSH |
| `ssh_security.permit_empty_passwords` | `no` | Разрешить пустые пароли SSH |
| `ssh_security.password_authentication` | `yes` | Аутентификация по паролю SSH |
| `ssh_security.pubkey_authentication` | `yes` | Аутентификация по публичному ключу SSH |

## 📁 Структура роли

```
configure_pam/
├── defaults/
│   └── main.yaml          # Переменные по умолчанию
├── handlers/
│   └── main.yml           # Обработчики событий
├── tasks/
│   ├── main.yaml          # Основные задачи
│   ├── advanced.yml       # Расширенные настройки
│   ├── validate.yaml      # Валидация параметров
│   └── cleanup.yml        # Очистка и восстановление
└── README.md              # Документация
```

## 🔧 Примеры использования

### Пример 1: Базовая безопасность

```yaml
---
- name: Базовая настройка PAM безопасности
  hosts: webservers
  become: yes
  
  vars:
    # Стандартные настройки безопасности
    pam_faillock_deny: 3
    pam_unlock_time: 1800  # 30 минут
    pam_pwquality_minlen: 12
    
  roles:
    - role: base/configure_pam
```

### Пример 2: Высокая безопасность

```yaml
---
- name: Высокая безопасность PAM
  hosts: production_servers
  become: yes
  
  vars:
    # Строгие настройки блокировки
    pam_faillock_deny: 2
    pam_unlock_time: 3600  # 1 час
    
    # Строгие требования к паролям
    pam_pwquality_minlen: 16
    pam_pwquality_minclass: 4
    pam_pwquality_maxrepeat: 1
    
    # Ограничения SSH
    ssh_security:
      max_auth_tries: 2
      password_authentication: "no"  # Только ключи
  
  roles:
    - role: base/configure_pam
```

### Пример 3: Тестирование

```yaml
---
- name: Тестирование PAM конфигурации
  hosts: test_servers
  become: yes
  
  vars:
    # Безопасные настройки для тестирования
    pam_faillock_deny: 5
    pam_unlock_time: 300   # 5 минут
    pam_pwquality_minlen: 8
    
    # Включить отладку
    debug_mode: true
  
  roles:
    - role: base/configure_pam
```

## 📝 Изменяемые файлы

Роль изменяет следующие системные файлы:

- `/etc/pam.d/common-auth` - Основная аутентификация
- `/etc/pam.d/common-account` - Управление аккаунтами
- `/etc/pam.d/common-password` - Политика паролей
- `/etc/pam.d/common-session` - Управление сессиями
- `/etc/pam.d/su` - Конфигурация su
- `/etc/pam.d/sudo` - Конфигурация sudo
- `/etc/sudoers.d/` - Правила sudo
- `/etc/security/limits.conf` - Лимиты системы
- `/etc/securetty` - Безопасные TTY
- `/etc/ssh/sshd_config` - Конфигурация SSH

## ⚠️ Важные предупреждения

### Безопасность
1. **ВСЕГДА тестируйте** роль в безопасной среде сначала
2. **Включите резервное копирование** перед применением
3. **Убедитесь в наличии** альтернативных методов доступа
4. **Мониторьте логи** после применения изменений

### Критические настройки
- Не устанавливайте `pam_faillock_deny` меньше 3
- Не устанавливайте `pam_unlock_time` меньше 300 секунд
- Не отключайте `pam_backup_enabled`

## 🆘 Устранение неполадок

### Если доступ заблокирован

1. **Консольный доступ**: Используйте физическую консоль или IPMI
2. **Режим восстановления**: Загрузитесь в режиме восстановления
3. **Восстановление из резервной копии**:
   ```bash
   cp /etc/pam.d/common-auth.backup /etc/pam.d/common-auth
   cp /etc/pam.d/common-password.backup /etc/pam.d/common-password
   ```
4. **Перезапуск SSH**: `systemctl restart ssh`

### Команды диагностики

```bash
# Проверить статус блокировки
faillock --user username

# Просмотреть логи PAM
tail -f /var/log/auth.log

# Проверить конфигурацию
cat /etc/pam.d/common-auth

# Тестировать sudo доступ
sudo -l
```

### Общие проблемы

| Проблема | Решение |
|----------|---------|
| Заблокирован доступ | Использовать консоль или режим восстановления |
| Проблемы SSH | Проверить конфигурацию и перезапустить сервис |
| Проблемы с паролями | Проверить настройки политики паролей |
| Ошибки разрешений | Убедиться в правильных разрешениях файлов |

## 🔍 Мониторинг

### Логи для отслеживания
- `/var/log/auth.log` - Логи аутентификации (Debian/Ubuntu)
- `/var/log/secure` - Логи безопасности (RHEL/CentOS)
- `/var/log/faillog` - Логи неудачных попыток

### Метрики для мониторинга
- Количество заблокированных аккаунтов
- Частота неудачных попыток входа
- Время разблокировки аккаунтов

## 📚 Дополнительные ресурсы

- [PAM Documentation](https://man7.org/linux/man-pages/man7/pam.7.html)
- [Ansible Best Practices](https://docs.ansible.com/ansible/latest/user_guide/playbooks_best_practices.html)
- [Linux Security Hardening](https://wiki.archlinux.org/title/Security)
- [SSH Security](https://www.openssh.com/security.html)


## 📄 Лицензия

Эта роль предоставляется под лицензией MIT для образовательных целей и повышения безопасности.

---

**⚠️ ВНИМАНИЕ**: Эта роль изменяет критические системные файлы аутентификации. Неправильная конфигурация может заблокировать доступ к системе. Всегда тестируйте в безопасной среде и создавайте резервные копии.
