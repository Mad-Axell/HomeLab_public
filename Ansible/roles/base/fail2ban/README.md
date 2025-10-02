# Fail2ban Ansible Role / Роль Ansible для Fail2ban

[![Ansible Role](https://img.shields.io/badge/ansible%20role-fail2ban-blue.svg)](https://galaxy.ansible.com/fail2ban)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)](CHANGELOG.md)

## Description / Описание

This Ansible role provides comprehensive installation and configuration of Fail2ban intrusion prevention system across multiple Linux distributions. The role ensures SSH access protection while maintaining access for authorized users from trusted networks.

Эта роль Ansible обеспечивает комплексную установку и настройку системы предотвращения вторжений Fail2ban на различных дистрибутивах Linux. Роль обеспечивает защиту SSH доступа, сохраняя при этом доступ для авторизованных пользователей из доверенных сетей.

## Features / Особенности

- **Cross-platform support** / **Кроссплатформенная поддержка**: Debian, Ubuntu, RedHat, CentOS, Rocky Linux, AlmaLinux, SUSE, openSUSE
- **SSH protection** / **Защита SSH**: Configurable SSH brute-force protection with whitelist support
- **User-based protection** / **Защита на основе пользователей**: Integration with user management systems
- **Firewall integration** / **Интеграция с файрволом**: Support for iptables, firewalld, UFW
- **Email notifications** / **Уведомления по почте**: Configurable email alerts
- **Comprehensive logging** / **Комплексное логирование**: Detailed logging and log rotation
- **Security hardening** / **Усиление безопасности**: SELinux, AppArmor support
- **Backup and recovery** / **Резервное копирование и восстановление**: Automatic configuration backups

## Supported Operating Systems / Поддерживаемые операционные системы

| OS Family | Distributions | Package Manager | Firewall |
|-----------|---------------|-----------------|----------|
| Debian    | Debian, Ubuntu, Linux Mint | apt | UFW, iptables |
| RedHat    | RHEL, CentOS, Rocky Linux, AlmaLinux, Fedora | yum/dnf | firewalld, iptables |
| SUSE      | openSUSE, SLES | zypper | iptables, SuSEfirewall2 |

## Requirements / Требования

- Ansible 2.9 or higher
- Python 3.6 or higher
- Root or sudo privileges
- Internet access for package installation

## Role Variables / Переменные роли

### Main Configuration / Основная конфигурация

```yaml
# Enable/disable fail2ban installation
fail2ban_install: true

# Service management
fail2ban_service_enabled: true
fail2ban_service_state: started

# Debug and validation
debug_mode: true
backup_enabled: true
validate_parameters: true
strict_validation: true
```

### SSH Protection / Защита SSH

```yaml
ssh_protection:
  enabled: true
  port: "22"
  protocol: tcp
  maxretry: 3
  bantime: 3600
  findtime: 600
  whitelist_enabled: true
  whitelist_ips: []
  whitelist_networks: []
```

### User-based Protection / Защита на основе пользователей

```yaml
user_based_protection:
  enabled: true
  trusted_users: []
  trusted_networks: []
```

## Dependencies / Зависимости

None

## Example Playbook / Пример Playbook

```yaml
---
- hosts: servers
  become: yes
  roles:
    - fail2ban
  vars:
    ssh_protection:
      enabled: true
      whitelist_networks:
        - "192.168.1.0/24"
        - "10.0.0.0/8"
    user_based_protection:
      enabled: true
      trusted_users:
        - admin
        - deploy
```

## Integration with host_vars/dashboard.yml / Интеграция с host_vars/dashboard.yml

The role automatically integrates with the `dashboard_users_to_add` variable from `host_vars/dashboard.yml`:

```yaml
# From host_vars/dashboard.yml
dashboard_users_to_add:
  - username: "admin"
    allowed_subnets:
      - "192.168.1.0/24"
      - "10.20.30.0/24"
```

The role will automatically:
- Extract trusted users from `dashboard_users_to_add`
- Extract trusted networks from `allowed_subnets`
- Configure fail2ban to whitelist these users and networks

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
   - Настройте логирование критических событий

4. **Backup / Резервное копирование**
   - Включите автоматическое резервное копирование
   - Храните бэкапы минимум 7 дней
   - Тестируйте восстановление из бэкапов

### Production Deployment / Развёртывание в продакшен

1. Начните с более мягких настроек (maxretry: 5-10, bantime: 600)
2. Мониторьте поведение системы 1-2 недели
3. Постепенно ужесточайте настройки на основе данных
4. Всегда тестируйте изменения на тестовом окружении

### Useful Commands / Полезные команды

```bash
# Status commands
fail2ban-client status
fail2ban-client status sshd

# Unban IP address
fail2ban-client unban <IP>
fail2ban-client set sshd unbanip <IP>

# Check banned IPs
fail2ban-client get sshd banip

# Reload configuration
fail2ban-client reload
```

## License / Лицензия

MIT

## Author Information / Информация об авторе

This role was created following the ansible-rule standards for enterprise-grade Ansible role development.

## Documentation / Документация

- [English Documentation](readme_eng.md)
- [Russian Documentation](readme_rus.md)

## Changelog / Журнал изменений

See [CHANGELOG.md](CHANGELOG.md) for detailed version history.
