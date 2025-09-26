# PAM Configuration Output Guide
# Руководство по выводу конфигурации PAM

## Overview / Обзор

The PAM role now displays the contents of all critical configuration files after completion when `debug_mode: true` is set.

Роль PAM теперь отображает содержимое всех критических конфигурационных файлов после завершения, когда установлен `debug_mode: true`.

## How to Enable / Как включить

Add the following variable to your playbook or inventory:

Добавьте следующую переменную в ваш playbook или inventory:

```yaml
vars:
  debug_mode: true
```

## What Files Are Displayed / Какие файлы отображаются

### SSH Configuration / Конфигурация SSH
- `/etc/ssh/sshd_config` - SSH server configuration

### PAM Configuration Files / Файлы конфигурации PAM
- `/etc/pam.d/common-auth` - Common authentication configuration
- `/etc/pam.d/sshd` - SSH-specific PAM configuration
- `/etc/pam.d/common-password` - Password policy configuration
- `/etc/pam.d/common-account` - Account management configuration
- `/etc/pam.d/common-session` - Session management configuration
- `/etc/pam.d/su` - SU command configuration
- `/etc/pam.d/sudo` - Sudo configuration

### PAM Security Files / Файлы безопасности PAM
- `/etc/security/access.conf` - Network access control (when enabled)
- `/etc/security/ssh_users` - Allowed SSH users (when enabled)
- `/etc/security/denied_users` - Denied users (when enabled)
- `/etc/security/limits.conf` - Resource limits (when enabled)
- `/etc/security/pwquality.conf` - Password quality settings
- `/etc/securetty` - Secure TTY configuration (when enabled)

### System Information / Системная информация
- Hostname, OS family, version, architecture
- Current user, SSH service status
- Active users and system uptime

## Example Output / Пример вывода

```
===============================================
SSH CONFIGURATION / КОНФИГУРАЦИЯ SSH
File: /etc/ssh/sshd_config
===============================================
# SSH Server Configuration
Port 22
PermitRootLogin no
MaxAuthTries 3
PasswordAuthentication yes
PubkeyAuthentication yes
...
===============================================

===============================================
PAM COMMON-AUTH CONFIGURATION / КОНФИГУРАЦИЯ PAM COMMON-AUTH
File: /etc/pam.d/common-auth
===============================================
auth required pam_faillock.so preauth audit deny=3 unlock_time=1800
auth sufficient pam_unix.so nullok_secure
auth required pam_faillock.so authfail audit deny=3 unlock_time=1800
auth required pam_access.so accessfile=/etc/security/access.conf
auth required pam_listfile.so item=user sense=allow file=/etc/security/ssh_users onerr=succeed
...
===============================================
```

## Benefits / Преимущества

1. **Complete Visibility** - See exactly what was configured
   **Полная видимость** - Видите точно, что было настроено

2. **Troubleshooting** - Easily identify configuration issues
   **Диагностика** - Легко выявлять проблемы конфигурации

3. **Documentation** - Self-documenting configuration
   **Документация** - Самодокументирующаяся конфигурация

4. **Audit Trail** - Complete record of changes
   **Аудит** - Полная запись изменений

## Usage Tips / Советы по использованию

1. **Always use debug_mode: true** during initial configuration
   **Всегда используйте debug_mode: true** при первоначальной конфигурации

2. **Save the output** to a file for reference:
   **Сохраните вывод** в файл для справки:
   ```bash
   ansible-playbook playbook.yml -v > pam_config_output.log
   ```

3. **Compare configurations** before and after changes
   **Сравнивайте конфигурации** до и после изменений

4. **Use for troubleshooting** when access issues occur
   **Используйте для диагностики** при возникновении проблем с доступом

## Security Note / Примечание по безопасности

The debug output may contain sensitive information. Ensure proper access controls when saving or sharing the output.

Отладочный вывод может содержать конфиденциальную информацию. Обеспечьте надлежащий контроль доступа при сохранении или обмене выводом.
