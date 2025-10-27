# set_locale

System locale configuration role for Debian/Ubuntu systems.

## Overview

This role configures system locale, timezone, keyboard layout and console font for Debian/Ubuntu systems with comprehensive validation and debugging capabilities.

## Documentation

- [Complete English Documentation](README_eng.md)
- [Полная документация на русском](README_rus.md)

## Quick Start

```yaml
- hosts: all
  roles:
    - role: base.set_locale
      vars:
        locale_primary: "en_US.UTF-8"
        timezone: "Europe/Moscow"
        keyboard_layout: "us"
        console_font: "Lat2-Terminus16"
```

## Requirements

- Ansible 2.14+
- Debian/Ubuntu systems
- Python 3.6+

## License

MIT

## Author

Mad-Axell [mad.axell@gmail.com]
