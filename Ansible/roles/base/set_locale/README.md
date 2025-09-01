# Locale Configuration Role

This Ansible role configures comprehensive system locale settings for internationalization on Linux systems.

## Overview

The Locale Configuration role provides a complete solution for setting up system internationalization:

- **System Locale**: Configure primary and additional locales with proper encoding
- **Timezone Management**: Set and validate system timezone
- **Keyboard Layout**: Configure keyboard layout, variant, and options
- **Console Font**: Set console font for better readability
- **NTP Configuration**: Configure NTP servers for time synchronization
- **Environment Variables**: Set locale-related environment variables
- **Multi-Platform Support**: Works with Debian/Ubuntu and RedHat/CentOS systems

## Requirements

- Ansible 2.9+
- Target system: Debian/Ubuntu or RedHat/CentOS
- Root or sudo privileges
- `community.general` collection (>=3.0.0)

## Role Variables

### Debug and Backup Settings

| Variable | Default | Description |
|----------|---------|-------------|
| `debug_mode` | `false` | Enable verbose debug output |
| `backup_enabled` | `true` | Create backups before modifications |
| `backup_suffix` | `.backup` | Backup file suffix |

### Primary Locale Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `locale_primary` | `en_US.UTF-8` | Primary system locale |
| `locale_language` | `en_US` | Language code for locale |
| `locale_encoding` | `UTF-8` | Character encoding |

### Additional Locales

| Variable | Default | Description |
|----------|---------|-------------|
| `locale_additional` | `["en_US.UTF-8", "en_GB.UTF-8", "ru_RU.UTF-8", "de_DE.UTF-8", "fr_FR.UTF-8"]` | List of additional locales to generate |

### System Locale Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `locale_variables` | See defaults | Dictionary of locale environment variables (LANG, LC_ALL, etc.) |

### Timezone Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `timezone` | `UTC` | System timezone |
| `timezone_manage` | `true` | Whether to manage timezone settings |

### Keyboard Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `keyboard_layout` | `us` | Keyboard layout (2-letter code) |
| `keyboard_variant` | `""` | Keyboard variant |
| `keyboard_options` | `""` | Keyboard options |

### Console and NTP

| Variable | Default | Description |
|----------|---------|-------------|
| `console_font` | `Lat2-Terminus16` | Console font |
| `console_font_manage` | `false` | Whether to manage console font |
| `ntp_enabled` | `true` | Enable NTP configuration |
| `ntp_servers` | `["0.pool.ntp.org", "1.pool.ntp.org", "2.pool.ntp.org"]` | NTP server list |

### Validation Settings

| Variable | Default | Description |
|----------|---------|-------------|
| `validate_locale` | `true` | Validate locale settings |
| `validate_timezone` | `true` | Validate timezone settings |

## Dependencies

This role depends on the `community.general` collection for:
- `community.general.locale_gen` - Locale generation
- `community.general.timezone` - Timezone management

## Example Playbook

### Basic Usage

```yaml
---
- hosts: servers
  become: yes
  roles:
    - role: base/set_locale
```

### Advanced Configuration

```yaml
---
- hosts: servers
  become: yes
  vars:
    locale_primary: "ru_RU.UTF-8"
    timezone: "Europe/Moscow"
    keyboard_layout: "ru"
    keyboard_variant: "winkeys"
    locale_additional:
      - "ru_RU.UTF-8"
      - "en_US.UTF-8"
      - "de_DE.UTF-8"
    ntp_servers:
      - "pool.ntp.org"
      - "ru.pool.ntp.org"
  roles:
    - role: base/set_locale
```

### Multi-Language Environment

```yaml
---
- hosts: servers
  become: yes
  vars:
    locale_primary: "en_US.UTF-8"
    locale_additional:
      - "en_US.UTF-8"
      - "en_GB.UTF-8"
      - "de_DE.UTF-8"
      - "fr_FR.UTF-8"
      - "es_ES.UTF-8"
      - "it_IT.UTF-8"
      - "pt_PT.UTF-8"
      - "nl_NL.UTF-8"
    timezone: "Europe/London"
    keyboard_layout: "gb"
    debug_mode: true
  roles:
    - role: base/set_locale
```

## File Structure

```
set_locale/
├── defaults/
│   └── main.yaml          # Default variables
├── handlers/
│   └── main.yml           # Service restart handlers
├── meta/
│   └── main.yml           # Role metadata
├── tasks/
│   ├── main.yaml          # Main tasks
│   └── validate.yaml      # Validation tasks
└── README.md              # This file
```

## Supported Platforms

- **Debian/Ubuntu**: Full support with apt package management
- **RedHat/CentOS 7/8/9**: Full support with yum/dnf package management
- **Fedora**: Full support with dnf package management

## Security Considerations

- Role creates backups before making changes
- Validates all input parameters
- Uses proper file permissions
- Supports audit logging through debug mode

## Troubleshooting

### Common Issues

1. **Locale not generated**: Ensure `locales` package is installed
2. **Timezone not set**: Verify timezone name with `timedatectl list-timezones`
3. **Keyboard not working**: Check if `keyboard-configuration` package is installed

### Debug Mode

Enable debug mode to see detailed information:

```yaml
debug_mode: true
```

### Validation

The role includes comprehensive validation:
- Locale format validation
- Timezone availability check
- Keyboard layout validation
- NTP server format validation

## Contributing

When contributing to this role:
1. Follow Ansible best practices
2. Add proper validation for new variables
3. Update documentation for new features
4. Test on multiple platforms

## License

MIT License - see LICENSE file for details.
