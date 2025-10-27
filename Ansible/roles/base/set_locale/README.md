# base/set_locale

System locale configuration role for Ansible.

## Overview

This Ansible role provides system locale configuration for Debian/Ubuntu systems. The role ensures proper locale, timezone, keyboard layout, and console font configuration with validation and debugging capabilities.

## Quick Links

- [English Documentation](README_eng.md) - Complete English documentation
- [Russian Documentation](README_rus.md) - Полная документация на русском языке

## Features

- **Debian/Ubuntu Support**: Optimized for Debian and Ubuntu systems
- **Comprehensive Validation**: Pre-flight checks and parameter validation
- **Debug Mode**: Detailed troubleshooting output
- **Idempotent**: Safe to run multiple times
- **Simplified Design**: Clean, maintainable code without unnecessary complexity

## Requirements

- **Ansible**: 2.14+
- **Python**: 3.6+
- **Supported OS**: Debian 9+, Ubuntu 18.04+

## Quick Start

```yaml
---
- name: Configure system locale
  hosts: all
  roles:
    - role: base/set_locale
      vars:
        locale_primary: "en_US.UTF-8"
        timezone: "Europe/Moscow"
        keyboard_layout: "us"
        console_font: "Lat2-Terminus16"
```

## License

MIT

## Author

Mad-Axell [mad.axell@gmail.com]