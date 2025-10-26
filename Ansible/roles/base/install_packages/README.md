# Base Install Packages Role

Multi-platform package installation role supporting Debian, RedHat, and SUSE OS families with comprehensive validation, advanced debugging capabilities, and production-ready error handling.

## Quick Start

```yaml
- name: Install essential packages
  ansible.builtin.include_role:
    name: base.install_packages
  vars:
    essential_packages:
      - sudo
      - curl
      - wget
    autoupdates_enabled: true
```

## Documentation

- **[English Documentation](README_eng.md)** - Complete and detailed English documentation
- **[Русская Документация](README_rus.md)** - Полная и подробная русская документация

## Supported Platforms

- **Debian Family**: Ubuntu (focal, jammy, noble), Debian (bullseye, bookworm, trixie)
- **RedHat Family**: EL (7, 8, 9), CentOS (7), Rocky (8, 9), AlmaLinux (8, 9)
- **SUSE Family**: openSUSE (15.3, 15.4, 15.5, Tumbleweed), SLES (15.3, 15.4, 15.5)

## Key Features

- ✅ **Multi-platform support** - Debian, RedHat, SUSE families
- ✅ **Automatic security updates** - Configurable for all platforms
- ✅ **Structured logging** - JSON format for all operations
- ✅ **Package validation** - Comprehensive pre-installation checks
- ✅ **Error handling** - Block-rescue patterns with rollback
- ✅ **Performance optimization** - Async operations and caching

## License

MIT

## Author

Mad-Axell [mad.axell@gmail.com]
