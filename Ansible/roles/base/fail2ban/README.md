# Fail2Ban Configuration Role / Роль конфигурации Fail2Ban

This Ansible role configures Fail2Ban intrusion prevention system with security best practices to protect your system against brute force attacks and unauthorized access attempts.

**Данная роль Ansible настраивает систему предотвращения вторжений Fail2Ban с соблюдением лучших практик безопасности для защиты системы от брутфорс-атак и несанкционированных попыток доступа.**

## Version 2.0.0 - Enhanced Security & Best Practices / Версия 2.0.0 - Улучшенная безопасность и лучшие практики

This role has been completely updated to follow Ansible best practices with comprehensive validation, enhanced debugging, and bilingual documentation.

**Данная роль была полностью обновлена для следования лучшим практикам Ansible с комплексной валидацией, улучшенной отладкой и двуязычной документацией.**

## Overview / Обзор

Fail2Ban is an intrusion prevention software framework that protects computer servers from brute-force attacks. This role provides a comprehensive configuration that includes:

**Fail2Ban — это фреймворк для предотвращения вторжений, который защищает серверы от брутфорс-атак. Данная роль предоставляет комплексную конфигурацию, включающую:**

- SSH protection with customizable jail settings / Защиту SSH с настраиваемыми параметрами тюрем
- Configurable logging and monitoring / Настраиваемое логирование и мониторинг
- Integration with UFW firewall / Интеграцию с UFW firewall
- Support for additional service jails (nginx, apache, etc.) / Поддержку дополнительных тюрем для сервисов (nginx, apache и др.)
- Comprehensive validation and error handling / Комплексную валидацию и обработку ошибок
- Extensive debug information and bilingual comments / Обширную отладочную информацию и двуязычные комментарии

## Requirements / Требования

- Ansible 2.9 or higher / Ansible 2.9 или выше
- Debian-based Linux distribution (Ubuntu, Debian) / Linux на базе Debian (Ubuntu, Debian)
- Root or sudo privileges / Права root или sudo
- UFW firewall (recommended) / UFW firewall (рекомендуется)

## Quick Start / Быстрый старт

```yaml
---
- hosts: servers
  become: true
  roles:
    - role: base/fail2ban
      vars:
        ssh_port: 2222
        fail2ban_jails:
          ssh:
            enabled: true
            maxretry: 5
            findtime: 300
            bantime: 7200
```

## Key Features / Ключевые особенности

- ✅ **Comprehensive Validation** / **Комплексная валидация**: All parameters are validated before application / Все параметры валидируются перед применением
- ✅ **Enhanced Debug Information** / **Улучшенная отладочная информация**: Detailed execution logs for troubleshooting / Подробные логи выполнения для диагностики
- ✅ **Bilingual Support** / **Двуязычная поддержка**: Comments and messages in English and Russian / Комментарии и сообщения на английском и русском языках
- ✅ **Security Best Practices** / **Лучшие практики безопасности**: Follows industry standards for intrusion prevention / Следует отраслевым стандартам предотвращения вторжений
- ✅ **Easy Integration** / **Простая интеграция**: Works seamlessly with UFW and other security roles / Легко интегрируется с UFW и другими ролями безопасности
- ✅ **Tagged Tasks** / **Тегированные задачи**: All tasks are properly tagged for selective execution / Все задачи помечены тегами для выборочного выполнения
- ✅ **Improved Task Names** / **Улучшенные названия задач**: More descriptive and informative task names / Более описательные и информативные названия задач
- ✅ **Ansible Best Practices** / **Лучшие практики Ansible**: Fully compliant with Ansible best practices / Полностью соответствует лучшим практикам Ansible

## Documentation / Документация

For complete documentation, please refer to the following files:

**Для полной документации обратитесь к следующим файлам:**

- **[readme_eng.md](readme_eng.md)** - Complete English documentation / Полная документация на английском языке
- **[readme_rus.md](readme_rus.md)** - Complete Russian documentation / Полная документация на русском языке

### What's included in the full documentation / Что включено в полную документацию:

- **Detailed variable descriptions** / **Подробные описания переменных**
- **Advanced configuration examples** / **Примеры расширенной конфигурации**
- **Troubleshooting guide** / **Руководство по устранению неполадок**
- **Security best practices** / **Лучшие практики безопасности**
- **Performance optimization** / **Оптимизация производительности**
- **Integration examples** / **Примеры интеграции**
- **Tag usage guide** / **Руководство по использованию тегов**
- **Ansible best practices compliance** / **Соответствие лучшим практикам Ansible**
- **Comprehensive validation details** / **Детали комплексной валидации**
- **Debug information usage** / **Использование отладочной информации**

## Quick Troubleshooting / Быстрое устранение неполадок

```bash
# Check Fail2Ban status / Проверить статус Fail2Ban
fail2ban-client status

# Check specific jail / Проверить конкретную тюрьму
fail2ban-client status sshd

# Test configuration / Протестировать конфигурацию
fail2ban-client reload

# View logs / Просмотреть логи
tail -f /var/log/fail2ban.log
```

## Tags / Теги

The role supports selective execution using tags:

**Роль поддерживает выборочное выполнение с помощью тегов:**

- `validation` - configuration validation tasks / задачи валидации конфигурации
- `packages` - package installation tasks / задачи установки пакетов
- `configuration` - configuration tasks / задачи конфигурации
- `service` - service management tasks / задачи управления службами
- `ssh` - SSH configuration tasks / задачи конфигурации SSH
- `logging` - logging configuration tasks / задачи конфигурации логирования
- `debug` - debug information tasks / задачи отладочной информации
- `fail2ban` - all role tasks / все задачи роли

### Tag Usage Examples / Примеры использования тегов

```bash
# Run only validation / Выполнить только валидацию
ansible-playbook playbook.yml --tags validation

# Run only package installation / Выполнить только установку пакетов
ansible-playbook playbook.yml --tags packages

# Skip debug information / Пропустить отладочную информацию
ansible-playbook playbook.yml --skip-tags debug
```

## Dependencies / Зависимости

This role works best with:
**Данная роль лучше всего работает с:**

- `base/configure_ufw` role for firewall integration / ролью `base/configure_ufw` для интеграции с firewall
- `base/security` role for additional security hardening / ролью `base/security` для дополнительного усиления безопасности

## License / Лицензия

This role is part of the HomeLab project and follows the same licensing terms.
**Данная роль является частью проекта HomeLab и следует тем же условиям лицензирования.**

## Contributing / Вклад в развитие

When contributing to this role:
**При внесении изменений в роль:**

1. Follow Ansible best practices / Следуйте лучшим практикам Ansible
2. Add appropriate validation / Добавляйте соответствующую валидацию
3. Update documentation / Обновляйте документацию
4. Test thoroughly before submitting / Тщательно тестируйте перед отправкой
5. Add proper tags to tasks / Добавляйте соответствующие теги к задачам
