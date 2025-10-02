# System Locale Configuration Role base.set_locale

## Description

The `base.set_locale` role is designed for comprehensive configuration of system locale, timezone, keyboard layout, and console font on Debian/Ubuntu and RedHat/CentOS systems. The role provides reliable configuration with parameter validation, backup functionality, and detailed debugging information.

## Features

- ✅ System locale configuration (LANG, LC_*, LANGUAGE)
- ✅ Timezone configuration
- ✅ Keyboard layout setup (Debian/Ubuntu and RedHat/CentOS)
- ✅ Console font configuration
- ✅ Additional locale generation
- ✅ Input parameter validation
- ✅ Configuration file backup
- ✅ Detailed debugging information
- ✅ Error handling and notifications
- ✅ Multi-platform support
- ✅ OS-specific configurations

## Supported Platforms

### Debian/Ubuntu
- Debian 9, 10, 11, 12
- Ubuntu 18.04, 20.04, 22.04, 24.04

### RedHat/CentOS
- CentOS 7, 8, 9
- Rocky Linux 8, 9
- AlmaLinux 8, 9

## Requirements

### System Requirements
- Ansible >= 2.9
- Python >= 3.6
- Root or sudo privileges

### Ansible Collections
```yaml
collections:
  - community.general
  - ansible.builtin
```

### Packages (installed automatically)
**Debian/Ubuntu:**
- locales
- console-setup
- keyboard-configuration

**RedHat/CentOS:**
- glibc-locale-source
- glibc-langpack-en
- kbd

## Role Variables

### Main Settings

| Variable | Default | Description |
|----------|---------|-------------|
| `locale_primary` | `"en_US.UTF-8"` | Primary system locale |
| `locale_language` | `"en_US"` | Locale language |
| `locale_encoding` | `"UTF-8"` | Locale encoding |
| `timezone` | `"Europe/Moscow"` | System timezone |
| `keyboard_layout` | `"us"` | Keyboard layout |
| `console_font` | `"Lat2-Terminus16"` | Console font |

### Additional Settings

| Variable | Default | Description |
|----------|---------|-------------|
| `locale_additional` | `["en_US.UTF-8", "ru_RU.UTF-8"]` | Additional locales |
| `backup_enabled` | `true` | Enable backup functionality |
| `debug_mode` | `false` | Enable debug mode |
| `validate_parameters` | `true` | Enable parameter validation |
| `strict_validation` | `true` | Strict validation mode |

### Keyboard Settings

| Variable | Default | Description |
|----------|---------|-------------|
| `keyboard_variant` | `""` | Keyboard layout variant |
| `keyboard_options` | `""` | Additional keyboard options |

## Usage Examples

### Basic Usage

```yaml
- hosts: servers
  roles:
    - role: base.set_locale
      vars:
        locale_primary: "ru_RU.UTF-8"
        timezone: "Europe/Moscow"
        keyboard_layout: "ru"
```

### Advanced Configuration

```yaml
- hosts: servers
  roles:
    - role: base.set_locale
      vars:
        # Localization
        locale_primary: "en_US.UTF-8"
        locale_language: "en_US"
        locale_encoding: "UTF-8"
        locale_additional:
          - "en_US.UTF-8"
          - "ru_RU.UTF-8"
          - "de_DE.UTF-8"
        
        # Timezone
        timezone: "UTC"
        timezone_manage: true
        
        # Keyboard
        keyboard_layout: "us"
        keyboard_variant: "dvorak"
        keyboard_options: "compose:rctrl"
        
        # Console
        console_font: "Lat2-Terminus14"
        console_font_manage: true
        
        # Role settings
        backup_enabled: true
        debug_mode: true
        validate_parameters: true
        strict_validation: true
```

### Disabling Components

```yaml
- hosts: servers
  roles:
    - role: base.set_locale
      vars:
        timezone_manage: false      # Don't configure timezone
        console_font_manage: false  # Don't configure console font
        keyboard_layout: ""         # Don't configure keyboard
```

## Tags

The role supports the following tags for selective execution:

| Tag | Description |
|-----|-------------|
| `locale` | All locale operations |
| `timezone` | Timezone configuration |
| `keyboard` | Keyboard configuration |
| `console` | Console configuration |
| `backup` | Backup operations |
| `validation` | Parameter validation |
| `debug` | Debug information |
| `system` | System operations |
| `packages` | Package installation |
| `debian` | Debian/Ubuntu operations |
| `redhat` | RedHat/CentOS operations |

### Tag Usage Examples

```bash
# Execute only locale configuration
ansible-playbook playbook.yml --tags locale

# Execute without backup operations
ansible-playbook playbook.yml --skip-tags backup

# Execute with debug information
ansible-playbook playbook.yml --tags debug

# Execute only for Debian/Ubuntu
ansible-playbook playbook.yml --tags debian

# Execute only package installation
ansible-playbook playbook.yml --tags packages
```

## Parameter Validation

The role includes comprehensive input parameter validation:

### Locale Validation
- Format: `ll_CC.ENCODING` (e.g., `en_US.UTF-8`)
- Supported encodings: UTF-8, ISO-8859-1, etc.

### Timezone Validation
- Format: `Region/City` (e.g., `Europe/Moscow`)
- All standard timezones supported

### Keyboard Validation
- Supported layouts: us, ru, de, fr, es, it, pt, nl, sv, no, da, fi, pl, cs, hu, tr, ja, ko, zh, ar, he
- Variants: dvorak, phonetic, nodeadkeys, deadkeys, mac, altgr-intl, euro, euro2

### Console Font Validation
- All standard Terminus fonts supported
- Sizes: 10, 12, 14, 16
- Styles: normal, bold
- Encodings: Lat2, Lat15, Lat7, Uni1, Uni2, Uni3, CyrSlav, Grk, ArmPit, Arab, Heb, Thai, Lao

## Backup Functionality

The role automatically creates backup copies of configuration files:

- `/etc/default/locale.backup`
- `/etc/environment.backup`
- `/etc/locale.gen.backup`
- `/etc/default/console-setup.backup` (Debian/Ubuntu)
- `/etc/vconsole.conf.backup` (RedHat/CentOS)

Backup can be disabled by setting `backup_enabled: false`.

## Debugging

To enable detailed debugging information, set `debug_mode: true`. This will output:

- System information
- Validation results
- Backup operation details
- Configuration results
- Final summary

## Error Handling

The role includes robust error handling:

- Parameter validation before execution
- Handling of missing files
- Ignoring non-critical errors
- Detailed error messages

## Role Files

```
roles/base/set_locale/
├── defaults/main.yml      # Default variables
├── handlers/main.yml      # Notification handlers
├── meta/main.yml          # Role metadata
├── tasks/
│   ├── main.yml           # Main tasks
│   ├── debian.yml         # Debian/Ubuntu tasks
│   ├── redhat.yml         # RedHat/CentOS tasks
│   └── validate.yml       # Parameter validation
└── README.md              # Documentation
```

## Dependencies

The role has no external dependencies on other roles.

## License

MIT

## Author

Mad-Axell
