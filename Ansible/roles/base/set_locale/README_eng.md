# base/set_locale

System locale configuration role for Ansible.

## Description
This Ansible role provides comprehensive system locale configuration for Linux systems, supporting Debian/Ubuntu, RedHat/CentOS, and SUSE families. The role ensures proper locale, timezone, keyboard layout, and console font configuration with extensive validation, structured logging, and automatic rollback capabilities.

## Features

- **Cross-platform Support**: Works with Debian, RedHat, and SUSE families
- **Comprehensive Validation**: Pre-flight checks and parameter validation
- **Structured Logging**: JSON-formatted logs for integration with log aggregators
- **Automatic Rollback**: Backup and restore capabilities on failure
- **Bilingual Support**: English and Russian documentation
- **Debug Mode**: Detailed output for troubleshooting
- **Idempotent**: Safe to run multiple times
- **Modular Design**: OS-specific tasks for optimal compatibility
- **System Facts Gathering**: Automatic collection of system information
- **Optimized Performance**: Unified handlers and bulk package installation
- **Modular Components**: Reusable debug and rollback components

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
| `timezone` | str | `"Europe/Moscow"` | System timezone |
| `timezone_manage` | bool | `true` | Whether to manage timezone configuration |

### Locale Configuration

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `locale_language` | str | `"en_US"` | Primary locale language code |
| `locale_encoding` | str | `"UTF-8"` | Locale encoding |
| `locale_primary` | str | `"{{ locale_language }}.{{ locale_encoding }}"` | Primary system locale |
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
| `locale_reload_commands` | dict | See defaults | OS-specific locale reload commands |
| `console_reload_commands` | dict | See defaults | OS-specific console reload commands |

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
  LANGUAGE: "{{ locale_language }}"
  LC_ALL: "{{ locale_primary }}"
  LC_COLLATE: "{{ locale_primary }}"
  LC_CTYPE: "{{ locale_primary }}"
  LC_MESSAGES: "{{ locale_primary }}"
  LC_MONETARY: "{{ locale_primary }}"
  LC_NUMERIC: "{{ locale_primary }}"
  LC_TIME: "{{ locale_primary }}"
```

### OS-Specific Package Mapping

```yaml
package_mappings:
  debian:
    locales: locales
    console_setup: console-setup
    keyboard_config: keyboard-configuration
    additional: []
  redhat:
    locales: glibc-locale-source
    console_setup: kbd
    keyboard_config: kbd
    additional:
      - glibc-langpack-en
  suse:
    locales: glibc-locale
    console_setup: kbd
    keyboard_config: kbd
    additional:
      - glibc-i18ndata
```

### Handler Commands Configuration

```yaml
locale_reload_commands:
  Debian: "locale-gen"
  RedHat: "localectl set-locale LANG={{ locale_primary }}"
  Suse: "localectl set-locale LANG={{ locale_primary }}"

console_reload_commands:
  Debian: "setupcon"
  RedHat: "systemctl restart systemd-vconsole-setup"
  Suse: "systemctl restart systemd-vconsole-setup"
```

## Role Structure

```
roles/base/set_locale/
├── defaults/main.yml          # Default variables
├── handlers/main.yml          # Universal handlers
├── meta/
│   ├── main.yml              # Role metadata
│   └── argument_specs.yml    # Input validation specs
├── tasks/
│   ├── main.yml              # Main role tasks
│   ├── preflight.yml         # Pre-flight checks
│   ├── validate.yml          # Parameter validation
│   ├── debug.yml             # Common debug messages
│   ├── rollback.yml          # Common rollback logic
│   ├── debian.yml            # Debian/Ubuntu specific tasks
│   ├── redhat.yml            # RedHat/CentOS specific tasks
│   └── suse.yml              # SUSE specific tasks
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
9. **OS-Specific Tasks**: Execute OS-specific configuration tasks
10. **Final Summary**: Display comprehensive configuration summary

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

## Structured Logging

The role implements comprehensive structured logging with JSON format:

```json
{
  "timestamp": "2024-01-15T10:30:45.123456Z",
  "level": "INFO",
  "event_type": "LOCALE_CONFIGURATION",
  "user": "ansible_user",
  "host": "target_host",
  "playbook": "locale_setup",
  "correlation_id": 1705312245,
  "message": "Locale configuration applied",
  "metadata": {
    "locale_primary": "en_US.UTF-8",
    "timezone": "Europe/Moscow",
    "keyboard_layout": "us",
    "console_font": "Lat2-Terminus16",
    "os_family": "Debian",
    "os_version": "12"
  }
}
```

## License

MIT

## Author

Mad-Axell [mad.axell@gmail.com]