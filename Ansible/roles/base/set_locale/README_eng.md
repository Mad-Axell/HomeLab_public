# System Locale Configuration Role

## Overview

This Ansible role configures system locale, timezone, keyboard layout and console font for Debian/Ubuntu systems with comprehensive validation and debugging capabilities.

## Features

- **System Locale Configuration**: Sets primary and additional locales
- **Timezone Management**: Configures system timezone
- **Keyboard Layout**: Sets keyboard layout, variant, and options
- **Console Font**: Configures console font for better display
- **Comprehensive Validation**: Validates all parameters before configuration
- **Structured Logging**: Logs all changes in JSON format
- **Rollback Support**: Automatic rollback on configuration failures
- **Backup Creation**: Creates backups before making changes
- **Debug Mode**: Detailed output for troubleshooting

## Requirements

### Ansible Requirements
- Ansible 2.14 or higher
- Python 3.6 or higher

### System Requirements
- Debian 9, 10, 11, 12
- Ubuntu 18.04, 20.04, 22.04, 24.04
- Root or sudo privileges

### Required Collections
- `ansible.builtin`
- `community.general`

## Role Variables

### Debug and Backup Settings
| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `debug_mode` | bool | `true` | Enable detailed debug output |
| `backup_enabled` | bool | `true` | Enable backup of configuration files before changes |
| `backup_suffix` | str | `".backup"` | Suffix for backup files |

### Timezone Configuration
| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `timezone` | str | `"Europe/Moscow"` | System timezone (e.g., UTC, Europe/Moscow, America/New_York) |
| `timezone_manage` | bool | `true` | Whether to manage timezone configuration |

### Locale Configuration
| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `locale_primary` | str | `"en_US.UTF-8"` | Primary system locale (format: language_COUNTRY.ENCODING) |
| `locale_additional` | list | `["ru_RU.UTF-8", "en_GB.UTF-8"]` | Additional locales to generate for multi-language support |
| `locale_variables` | dict | See defaults | System locale environment variables |

### Console Font Configuration
| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `console_font` | str | `"Lat2-Terminus16"` | Console font name (e.g., Lat2-Terminus16, Uni3-Terminus14) |
| `console_font_manage` | bool | `true` | Whether to manage console font configuration |

### Keyboard Configuration
| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `keyboard_layout` | str | `"us"` | Keyboard layout (e.g., us, ru, de, fr) |
| `keyboard_variant` | str | `""` | Keyboard variant (e.g., dvorak, phonetic, nodeadkeys) |
| `keyboard_options` | str | `""` | Additional keyboard options |

### Validation Settings
| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `validate_parameters` | bool | `true` | Enable parameter validation before configuration |
| `strict_validation` | bool | `true` | Enable strict validation mode with comprehensive checks |

### Logging and Rollback
| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `log_file` | str | `"/var/log/ansible-changes.log"` | Path to log file for changes |
| `enable_rollback` | bool | `true` | Enable automatic rollback on failure |

## Dependencies

None

## Example Playbook

### Basic Usage
```yaml
---
- hosts: all
  become: true
  roles:
    - role: base.set_locale
      vars:
        locale_primary: "en_US.UTF-8"
        timezone: "UTC"
        keyboard_layout: "us"
        console_font: "Lat2-Terminus16"
```

### Advanced Configuration
```yaml
---
- hosts: all
  become: true
  roles:
    - role: base.set_locale
      vars:
        # Debug settings
        debug_mode: true
        backup_enabled: true
        
        # Locale configuration
        locale_primary: "en_US.UTF-8"
        locale_additional:
          - "ru_RU.UTF-8"
          - "en_GB.UTF-8"
          - "de_DE.UTF-8"
        
        # Timezone
        timezone: "Europe/Moscow"
        timezone_manage: true
        
        # Keyboard
        keyboard_layout: "us"
        keyboard_variant: "dvorak"
        keyboard_options: "compose:rctrl"
        
        # Console
        console_font: "Lat2-Terminus16"
        console_font_manage: true
        
        # Validation
        validate_parameters: true
        strict_validation: true
        
        # Logging
        log_file: "/var/log/ansible-changes.log"
        enable_rollback: true
```

### Multi-language Environment
```yaml
---
- hosts: all
  become: true
  roles:
    - role: base.set_locale
      vars:
        locale_primary: "en_US.UTF-8"
        locale_additional:
          - "ru_RU.UTF-8"
          - "en_GB.UTF-8"
          - "de_DE.UTF-8"
          - "fr_FR.UTF-8"
          - "es_ES.UTF-8"
        timezone: "Europe/Moscow"
        keyboard_layout: "us"
        console_font: "Uni2-Terminus16"
```

## Task Tags

The role supports the following tags for selective execution:

- `facts` - System facts gathering
- `preflight` - Pre-execution checks
- `validation` - Parameter validation
- `backup` - Backup operations
- `locale` - Locale configuration
- `timezone` - Timezone configuration
- `keyboard` - Keyboard configuration
- `console` - Console font configuration
- `debug` - Debug output
- `handlers` - Handler execution

### Example: Run only validation
```bash
ansible-playbook playbook.yml --tags validation
```

### Example: Skip backup operations
```bash
ansible-playbook playbook.yml --skip-tags backup
```

## Structured Logging

The role implements comprehensive structured logging in JSON format. All configuration changes are logged to `/var/log/ansible-changes.log` by default.

### Log Events
- `CONFIG_CHANGE` - Configuration file changes
- `SERVICE_CHANGE` - Service state changes
- `PACKAGE_INSTALL` - Package installation
- `PERMISSION_CHANGE` - File permission changes
- `KEYBOARD_CONFIGURED` - Keyboard configuration
- `CONSOLE_FONT_CONFIGURED` - Console font configuration
- `PRIMARY_LOCALE_GEN_FAILED` - Primary locale generation failures
- `ADDITIONAL_LOCALES_ROLLBACK_ATTEMPTED` - Rollback attempts
- `LOCALE_VARS_ROLLBACK_ATTEMPTED` - Locale variables rollback
- `TIMEZONE_CONFIG_FAILED` - Timezone configuration failures
- `KEYBOARD_CONFIG_FAILED` - Keyboard configuration failures
- `PACKAGE_INSTALL_FAILED` - Package installation failures

### Log Format
```json
{
  "timestamp": "2024-01-15T10:30:45.123456Z",
  "level": "INFO",
  "event_type": "CONFIG_CHANGE",
  "service_name": "locale",
  "status": "SUCCESS",
  "user": "root",
  "host": "server01",
  "playbook": "locale_setup",
  "correlation_id": "1705312245",
  "message": "Configuration change applied",
  "metadata": {
    "config_file": "/etc/default/locale",
    "backup_created": true
  }
}
```

## Error Handling and Rollback

The role implements comprehensive error handling with automatic rollback capabilities:

### Rollback Features
- Automatic backup creation before changes
- Rollback on configuration failures
- Structured error logging
- Graceful degradation on non-critical failures

### Error Recovery
- Continues execution with available locales if some fail
- Restores previous configuration on critical failures
- Logs all rollback attempts for audit purposes

## Validation

### Parameter Validation
- Locale format validation (ll_CC.ENCODING)
- Timezone format validation
- Keyboard layout validation against supported layouts
- Console font validation against supported fonts
- Additional locales format validation

### Supported Keyboard Layouts
- us, ru, de, fr, es, it, pt, nl, sv, no, da, fi, pl, cs, hu, tr, ja, ko, zh, ar, he

### Supported Console Fonts
- Lat2-Terminus16, Lat2-Terminus14, Lat2-Terminus12, Lat2-Terminus10
- Lat15-Terminus16, Lat15-Terminus14, Lat15-Terminus12, Lat15-Terminus10
- Lat7-Terminus16, Lat7-Terminus14, Lat7-Terminus12, Lat7-Terminus10
- Uni1-Terminus16, Uni1-Terminus14, Uni1-Terminus12, Uni1-Terminus10
- Uni2-Terminus16, Uni2-Terminus14, Uni2-Terminus12, Uni2-Terminus10
- Uni3-Terminus16, Uni3-Terminus14, Uni3-Terminus12, Uni3-Terminus10
- CyrSlav-Terminus16, CyrSlav-Terminus14, CyrSlav-Terminus12, CyrSlav-Terminus10
- And many more...

## Files Modified

The role modifies the following system files:
- `/etc/default/locale` - System locale variables
- `/etc/environment` - Environment variables
- `/etc/locale.gen` - Locale generation configuration
- `/etc/default/console-setup` - Console font configuration
- `/etc/default/keyboard` - Keyboard configuration

## Troubleshooting

### Common Issues

1. **Permission Denied**
   - Ensure the playbook runs with `become: true`
   - Check that the user has sudo privileges

2. **Invalid Locale Format**
   - Use format: `language_COUNTRY.ENCODING` (e.g., `en_US.UTF-8`)
   - Check that the locale is available in the system

3. **Timezone Not Found**
   - Verify timezone exists: `timedatectl list-timezones`
   - Use proper format: `Continent/City` (e.g., `Europe/Moscow`)

4. **Keyboard Layout Not Supported**
   - Check supported layouts in `valid_keyboard_layouts`
   - Use standard layout codes (us, ru, de, etc.)

### Debug Mode
Enable debug mode for detailed output:
```yaml
vars:
  debug_mode: true
```

### Check Logs
View structured logs:
```bash
tail -f /var/log/ansible-changes.log | jq .
```

## License

MIT

## Author

Mad-Axell [mad.axell@gmail.com]

## Support

For issues and questions, please contact the author or create an issue in the project repository.
