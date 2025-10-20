# base/set_locale - System Locale Configuration Role

## Description

This Ansible role configures system locale, timezone, keyboard layout and console font for Linux systems. It provides comprehensive support for Debian/Ubuntu, RedHat/CentOS, and SUSE families with extensive validation, debugging capabilities, and structured logging.

## Features

- **Cross-platform Support**: Works with Debian, RedHat, and SUSE families
- **Comprehensive Validation**: Pre-flight checks and parameter validation
- **Structured Logging**: JSON-formatted logs for integration with log aggregators
- **Automatic Rollback**: Backup and restore capabilities on failure
- **Bilingual Support**: English and Russian documentation
- **Debug Mode**: Detailed output for troubleshooting
- **Idempotent**: Safe to run multiple times
- **Modular Design**: OS-specific tasks for optimal compatibility
- **Primary Locale Generation**: Ensures primary locale is generated before configuration
- **Multi-language Support**: Configures additional locales for internationalization

## Requirements

### Ansible
- **Minimum Version**: 2.14+
- **Python**: 3.6+

### Supported Operating Systems

#### Debian Family
- Debian: 9, 10, 11, 12
- Ubuntu: 18.04, 20.04, 22.04, 24.04

#### RedHat Family
- RedHat Enterprise Linux: 7, 8, 9
- CentOS: 7, 8, 9
- Rocky Linux: 8, 9
- AlmaLinux: 8, 9

#### SUSE Family
- SUSE Linux Enterprise Server: Latest versions
- openSUSE: Latest versions

## Role Variables

### Debug and Backup Settings

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `debug_mode` | bool | `true` | Enable detailed debug output |
| `backup_enabled` | bool | `true` | Enable backup of configuration files |
| `backup_suffix` | str | `".backup"` | Suffix for backup files |

### Timezone Configuration

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `timezone` | str | `"Europe/Moscow"` | System timezone (e.g., UTC, Europe/Moscow) |
| `timezone_manage` | bool | `true` | Whether to manage timezone configuration |

### Locale Configuration

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `locale_language` | str | `"en_US"` | Primary locale language code |
| `locale_encoding` | str | `"UTF-8"` | Locale encoding |
| `locale_primary` | str | `"en_US.UTF-8"` | Primary system locale |
| `locale_additional` | list | `["ru_RU.UTF-8"]` | Additional locales for multi-language support |
| `locale_variables` | dict | See defaults | System locale environment variables |

### Console Font Configuration

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `console_font` | str | `"Lat2-Terminus16"` | Console font name |
| `console_font_manage` | bool | `true` | Whether to manage console font |

### Keyboard Configuration

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `keyboard_layout` | str | `"us"` | Keyboard layout (e.g., us, ru, de) |
| `keyboard_variant` | str | `""` | Keyboard variant (e.g., dvorak, phonetic) |
| `keyboard_options` | str | `""` | Additional keyboard options |

### Validation Settings

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `validate_parameters` | bool | `true` | Enable parameter validation |
| `strict_validation` | bool | `true` | Enable strict validation mode |

### Performance and Logging

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `log_file` | str | `"/var/log/ansible-changes.log"` | Path to log file for changes |
| `async_timeout` | int | `300` | Async task timeout (seconds) |
| `retries` | int | `3` | Retry count for failed tasks |
| `retry_delay` | int | `5` | Delay between retries (seconds) |
| `enable_rollback` | bool | `true` | Auto-rollback on failure |

## Dependencies

None.

## Example Playbook

### Basic Usage

```yaml
---
- name: Configure system locale
  hosts: all
  become: yes
  roles:
    - role: base/set_locale
      vars:
        locale_primary: "en_US.UTF-8"
        timezone: "UTC"
        keyboard_layout: "us"
        console_font: "Lat2-Terminus16"
```

### Advanced Configuration

```yaml
---
- name: Configure system locale with advanced settings
  hosts: all
  become: yes
  roles:
    - role: base/set_locale
      vars:
        # Locale settings
        locale_primary: "en_US.UTF-8"
        locale_additional:
          - "ru_RU.UTF-8"
          - "de_DE.UTF-8"
        
        # Timezone
        timezone: "Europe/Moscow"
        
        # Keyboard
        keyboard_layout: "us"
        keyboard_variant: "dvorak"
        
        # Console
        console_font: "Lat2-Terminus16"
        
        # Debug and logging
        debug_mode: true
        log_file: "/var/log/locale-changes.log"
        
        # Validation
        strict_validation: true
        validate_parameters: true
```

### Multi-OS Configuration

```yaml
---
- name: Configure locale for different OS families
  hosts: all
  become: yes
  roles:
    - role: base/set_locale
      vars:
        locale_primary: "en_US.UTF-8"
        timezone: "UTC"
        keyboard_layout: "us"
      when: ansible_os_family in ['Debian', 'RedHat', 'Suse']
```

## Locale Generation Process

The role implements a comprehensive locale generation process for Debian/Ubuntu systems:

### Primary Locale Generation
1. **Automatic Generation**: The role automatically generates the primary locale (`locale_primary`) using `community.general.locale_gen`
2. **Pre-configuration**: Primary locale is generated before setting system locale variables
3. **Error Handling**: If generation fails, the role logs the error and continues with available locales
4. **Idempotent**: Safe to run multiple times - won't regenerate existing locales

### Additional Locales
1. **Multi-language Support**: Configures additional locales from `locale_additional` list
2. **Batch Processing**: Generates all additional locales in a single operation
3. **Validation**: Ensures all locales are properly formatted before generation

### Process Flow
```
1. Validate locale parameters
2. Generate primary locale (Debian/Ubuntu only)
3. Generate additional locales
4. Configure system locale variables
5. Set timezone and keyboard layout
6. Apply console font settings
```

## Structured Logging

The role implements structured JSON logging for all configuration changes. Log entries include:

```json
{
  "timestamp": "2024-01-15T10:30:45.123456Z",
  "level": "INFO",
  "event_type": "PRIMARY_LOCALE_GENERATED",
  "locale_primary": "en_US.UTF-8",
  "user": "ansible_user",
  "host": "target_host",
  "playbook": "locale_setup",
  "correlation_id": "1705312245",
  "message": "Primary locale generated successfully",
  "metadata": {
    "changed": true,
    "os_family": "Debian",
    "os_version": "12",
    "generation_method": "locale_gen"
  }
}
```

### Error Logging Example
```json
{
  "timestamp": "2024-01-15T10:30:45.123456Z",
  "level": "ERROR",
  "event_type": "PRIMARY_LOCALE_GEN_FAILED",
  "locale_primary": "en_US.UTF-8",
  "user": "ansible_user",
  "host": "target_host",
  "playbook": "locale_setup",
  "correlation_id": "1705312245",
  "message": "Primary locale generation failed",
  "metadata": {
    "rollback_enabled": true,
    "os_family": "Debian",
    "os_version": "12",
    "error_type": "PRIMARY_LOCALE_GENERATION_ERROR"
  }
}
```

## Error Handling

The role implements comprehensive error handling:

- **Pre-flight Checks**: Validates Ansible version, OS compatibility, Python version, and disk space
- **Parameter Validation**: Validates locale format, timezone format, keyboard layouts, and console fonts
- **Block-Rescue Pattern**: Uses structured error handling with automatic rollback
- **Backup and Restore**: Creates backups before changes and restores on failure

## OS-Specific Behavior

### Debian/Ubuntu
- Uses `apt` for package management
- Generates primary locale using `community.general.locale_gen`
- Configures `/etc/default/locale` and `/etc/locale.gen`
- Uses `debconf` for keyboard configuration
- Console font in `/etc/default/console-setup`

### RedHat/CentOS
- Uses `yum`/`dnf` for package management
- Uses `localectl` for locale and keyboard configuration
- Console font in `/etc/vconsole.conf`

### SUSE
- Uses `zypper` for package management
- Uses `localectl` for locale and keyboard configuration
- Console font in `/etc/vconsole.conf`

## Validation Patterns

The role validates inputs using regex patterns:

- **Locale Pattern**: `^[a-z]{2}_[A-Z]{2}\.[A-Z0-9-]+$`
- **Timezone Pattern**: `^[A-Za-z0-9/_-]+$`
- **Keyboard Layouts**: Predefined list of valid layouts
- **Console Fonts**: Predefined list of valid fonts

## License

MIT

## Author

Mad-Axell [mad.axell@gmail.com]
