# base/set_locale

System locale configuration role for Ansible.

## Description
This Ansible role provides system locale configuration for Debian/Ubuntu systems. The role ensures proper locale, timezone, keyboard layout, and console font configuration with validation and debugging capabilities.

## Features

- **Debian/Ubuntu Support**: Optimized for Debian and Ubuntu systems
- **Comprehensive Validation**: Pre-flight checks and parameter validation
- **Debug Mode**: Detailed output for troubleshooting
- **Idempotent**: Safe to run multiple times
- **Simplified Design**: Clean, maintainable code without unnecessary complexity
- **System Facts Gathering**: Automatic collection of system information
- **Optimized Performance**: Streamlined handlers and package installation

## Requirements

### Ansible
- **Minimum Version**: 2.14+
- **Python**: 3.6+

### Supported Operating Systems

#### Debian Family
- Debian: 9, 10, 11, 12
- Ubuntu: 18.04, 20.04, 22.04, 24.04

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
| `timezone` | str | `"Europe/Moscow"` | System timezone |
| `timezone_manage` | bool | `true` | Whether to manage timezone configuration |

### Locale Configuration

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `locale_primary` | str | `"en_US.UTF-8"` | Primary system locale |
| `locale_additional` | list | `["ru_RU.UTF-8", "en_GB.UTF-8"]` | Additional locales to generate |
| `locale_variables` | dict | See defaults | System locale environment variables |

### Console Font Configuration

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `console_font` | str | `"Lat2-Terminus16"` | Console font name |
| `console_font_manage` | bool | `true` | Whether to manage console font configuration |

### Keyboard Configuration

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `keyboard_layout` | str | `"us"` | Keyboard layout |
| `keyboard_variant` | str | `""` | Keyboard variant |
| `keyboard_options` | str | `""` | Additional keyboard options |

### Validation Settings

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `validate_parameters` | bool | `true` | Enable parameter validation |
| `strict_validation` | bool | `true` | Enable strict validation mode |

### Logging and Rollback Controls

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `log_file` | str | `"/var/log/ansible-changes.log"` | Path to log file for changes |
| `enable_rollback` | bool | `true` | Auto-rollback on failure |

### Handler Commands

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `locale_reload_command` | str | `"locale-gen"` | Locale reload command |
| `console_reload_command` | str | `"setupcon"` | Console reload command |

## Dependencies

None. This role is designed to be independent and self-contained.

## Example Playbook

```yaml
---
- name: Configure system locale
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
        timezone_manage: true
        
        # Keyboard
        keyboard_layout: "us"
        keyboard_variant: ""
        keyboard_options: ""
        
        # Console font
        console_font: "Lat2-Terminus16"
        console_font_manage: true
        
        # Debug and logging
        debug_mode: true
        log_file: "/var/log/ansible-locale-changes.log"
        
        # Validation
        validate_parameters: true
        strict_validation: true
        
        # Backup and rollback
        backup_enabled: true
        enable_rollback: true
```

## Advanced Configuration

### Custom Locale Variables

```yaml
locale_variables:
  LANG: "{{ locale_primary }}"
  LANGUAGE: "{{ locale_primary | regex_replace('\\..*', '') }}"
  LC_ALL: "{{ locale_primary }}"
  LC_COLLATE: "{{ locale_primary }}"
  LC_CTYPE: "{{ locale_primary }}"
  LC_MESSAGES: "{{ locale_primary }}"
  LC_MONETARY: "{{ locale_primary }}"
  LC_NUMERIC: "{{ locale_primary }}"
  LC_TIME: "{{ locale_primary }}"
```

### Debian Package Configuration

```yaml
debian_packages:
  - locales
  - console-setup
  - keyboard-configuration
```

### Handler Commands Configuration

```yaml
locale_reload_command: "locale-gen"
console_reload_command: "setupcon"
```

## Role Structure

```
roles/base/set_locale/
├── defaults/main.yml          # Default variables
├── handlers/main.yml          # Handlers
├── meta/
│   ├── main.yml              # Role metadata
│   └── argument_specs.yml    # Input validation specs
├── tasks/
│   ├── main.yml              # Main role tasks
│   ├── preflight.yml         # Pre-flight checks
│   ├── validate.yml          # Parameter validation
│   └── debian.yml            # Debian/Ubuntu specific tasks
├── README.md                 # Brief overview
├── README_eng.md            # Complete English documentation
└── README_rus.md            # Complete Russian documentation
```

## Task Flow

1. **System Facts Gathering**: Collect system information
2. **Pre-flight Checks**: Validate Ansible version, OS compatibility, Python version, disk space
3. **Parameter Validation**: Validate locale format, timezone format, keyboard layouts, console fonts
4. **Backup Creation**: Create backups of existing configuration files
5. **Primary Locale Generation**: Generate primary locale
6. **Additional Locales**: Generate additional locales for multi-language support
7. **Locale Variables Configuration**: Configure system locale environment variables
8. **Timezone Configuration**: Set system timezone
9. **Debian/Ubuntu Tasks**: Execute Debian/Ubuntu specific configuration tasks
10. **Final Summary**: Display comprehensive configuration summary

## Error Handling

The role implements comprehensive error handling:

- **Pre-flight Checks**: Validates Ansible version, OS compatibility, Python version, and disk space
- **Parameter Validation**: Validates locale format, timezone format, keyboard layouts, and console fonts
- **Block-Rescue Pattern**: Uses structured error handling with automatic rollback
- **Backup and Restore**: Creates backups before changes and restores on failure

## Debian/Ubuntu Behavior

- Uses `apt` for package management
- Generates primary locale using `community.general.locale_gen`
- Configures `/etc/default/locale` and `/etc/locale.gen`
- Uses `debconf` for keyboard configuration
- Console font in `/etc/default/console-setup`

## Validation Patterns

The role validates inputs using regex patterns:

- **Locale Pattern**: `^[a-z]{2}_[A-Z]{2}\.[A-Z0-9-]+$`
- **Timezone Pattern**: `^[A-Za-z0-9/_-]+$`
- **Keyboard Layouts**: Predefined list of valid layouts
- **Console Fonts**: Predefined list of valid fonts

## Logging

The role implements basic logging for configuration changes:

- Configuration changes are logged to `/var/log/ansible-changes.log`
- Debug mode provides detailed output for troubleshooting
- Simple error messages for failed operations

## License

MIT

## Author

Mad-Axell [mad.axell@gmail.com]