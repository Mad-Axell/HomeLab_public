# base/set_locale

System locale configuration role for Ansible.

## Overview

This role configures system locale, timezone, keyboard layout and console font for Debian/Ubuntu, RedHat/CentOS, and SUSE systems with comprehensive validation and debugging capabilities.

## Quick Start

```yaml
- hosts: all
  roles:
    - role: base/set_locale
      vars:
        locale_primary: "en_US.UTF-8"
        timezone: "Europe/Moscow"
        keyboard_layout: "us"
```

## Documentation

- **[README_eng.md](README_eng.md)** - Complete English documentation
- **[README_rus.md](README_rus.md)** - Полная документация на русском языке

## Supported Systems

- **Debian/Ubuntu**: 9, 10, 11, 12 / 18.04, 20.04, 22.04, 24.04
- **RedHat/CentOS**: 7, 8, 9
- **Rocky Linux**: 8, 9
- **AlmaLinux**: 8, 9
- **SUSE/openSUSE**: Latest versions

## Features

- ✅ Cross-platform support (Debian, RedHat, SUSE families)
- ✅ Comprehensive parameter validation
- ✅ Structured JSON logging
- ✅ Automatic rollback on failure
- ✅ Bilingual documentation (English/Russian)
- ✅ Debug mode with detailed output
- ✅ Backup configuration files
- ✅ Idempotent operations
- ✅ Primary locale generation for Debian/Ubuntu
- ✅ Multi-language locale support

## License

MIT

## Author

Mad-Axell [mad.axell@gmail.com]
