# base/set_locale

System locale configuration role for Ansible.

## Overview

This Ansible role provides comprehensive system locale configuration for Linux systems, supporting Debian/Ubuntu, RedHat/CentOS, and SUSE families. The role ensures proper locale, timezone, keyboard layout, and console font configuration with extensive validation, structured logging, and automatic rollback capabilities.

## Quick Links

- [English Documentation](README_eng.md) - Complete English documentation
- [Russian Documentation](README_rus.md) - Полная документация на русском языке

## Features

- **Cross-platform Support**: Debian, RedHat, and SUSE families
- **Comprehensive Validation**: Pre-flight checks and parameter validation
- **Structured Logging**: JSON-formatted logs for log aggregators
- **Automatic Rollback**: Backup and restore on failure
- **Bilingual Support**: English and Russian documentation
- **Debug Mode**: Detailed troubleshooting output
- **Idempotent**: Safe to run multiple times
- **Modular Design**: OS-specific tasks for optimal compatibility

## Requirements

- **Ansible**: 2.14+
- **Python**: 3.6+
- **Supported OS**: Debian 9+, Ubuntu 18.04+, RHEL 7+, CentOS 7+, Rocky Linux 8+, AlmaLinux 8+, SUSE 15+

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