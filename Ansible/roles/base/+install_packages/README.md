# install_packages

## English

An enterprise-grade Ansible role for installing essential packages on Ubuntu/Debian and RedHat/CentOS systems with comprehensive validation, advanced debugging capabilities, and production-ready error handling.

**Purpose**: This role provides a robust, enterprise-grade solution for installing essential packages on Debian/Ubuntu and RedHat/CentOS systems. It includes comprehensive parameter validation, advanced error handling with retry mechanisms, detailed debugging output, system resource monitoring, and thorough verification of successful installation. The role is designed for production environments with extensive logging and performance monitoring capabilities.

**Key Features**:
- ✅ Advanced parameter validation with detailed error messages
- ✅ Enterprise-grade error handling with retry mechanisms
- ✅ Advanced debug output with system resources and performance metrics
- ✅ Multi-platform support for Debian/Ubuntu and RedHat/CentOS systems
- ✅ System compatibility verification and package availability checks
- ✅ Flexible configuration for essential and optional packages
- ✅ Intelligent APT/YUM/DNF cache management with repository analysis
- ✅ Optional system package upgrades with impact analysis
- ✅ Performance monitoring and execution time tracking
- ✅ Resource monitoring for capacity planning

**Quick Start**:
```yaml
---
- name: Install essential packages
  hosts: all
  become: yes
  roles:
    - install_packages
  vars:
    debug_mode: true
    essential_packages:
      - htop
      - curl
      - wget
    optional_packages:
      - vim
      - git
```

**Documentation**: For complete documentation, examples, and advanced usage, see [README_eng.md](README_eng.md)

---

## Русский

Корпоративная Ansible роль для установки основных пакетов на системах Ubuntu/Debian и RedHat/CentOS с комплексной валидацией, расширенными возможностями отладки и обработкой ошибок корпоративного уровня.

**Назначение**: Эта роль предоставляет надежное, корпоративное решение для установки основных пакетов на системах Debian/Ubuntu и RedHat/CentOS. Она включает комплексную валидацию параметров, расширенную обработку ошибок с механизмами повтора, подробный отладочный вывод, мониторинг системных ресурсов и тщательную проверку успешной установки. Роль разработана для производственных сред с расширенным логированием и возможностями мониторинга производительности.

**Основные возможности**:
- ✅ Расширенная валидация параметров с детальными сообщениями об ошибках
- ✅ Корпоративная обработка ошибок с механизмами повтора
- ✅ Расширенный отладочный вывод с системными ресурсами и метриками производительности
- ✅ Мультиплатформенная поддержка систем Debian/Ubuntu и RedHat/CentOS
- ✅ Проверка совместимости системы и доступности пакетов
- ✅ Гибкая конфигурация для основных и дополнительных пакетов
- ✅ Интеллектуальное управление кэшем APT/YUM/DNF с анализом репозиториев
- ✅ Опциональные обновления системных пакетов с анализом воздействия
- ✅ Мониторинг производительности и отслеживание времени выполнения
- ✅ Мониторинг ресурсов для планирования мощностей

**Быстрый старт**:
```yaml
---
- name: Установка основных пакетов
  hosts: all
  become: yes
  roles:
    - install_packages
  vars:
    debug_mode: true
    essential_packages:
      - htop
      - curl
      - wget
    optional_packages:
      - vim
      - git
```

**Документация**: Для полной документации, примеров и расширенного использования см. [README_rus.md](README_rus.md)

---

## Requirements / Требования

- Ansible 2.9 or higher / Ansible 2.9 или выше
- Debian/Ubuntu based systems / Системы на базе Debian/Ubuntu
- APT package manager / Менеджер пакетов APT
- Python 3 (for Ansible execution) / Python 3 (для выполнения Ansible)
