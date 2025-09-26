# install_apts

## English

An Ansible role for installing essential packages on Ubuntu/Debian systems with comprehensive validation and debugging capabilities.

**Purpose**: This role provides a robust solution for installing essential packages on Debian/Ubuntu systems. It includes parameter validation, comprehensive error handling, detailed debugging output, and verification of successful installation.

**Key Features**:
- ✅ Parameter validation and error handling
- ✅ Detailed debugging output
- ✅ System verification and package availability checks
- ✅ Flexible configuration for essential and optional packages
- ✅ Configurable APT cache management
- ✅ Optional system package upgrades

**Quick Start**:
```yaml
---
- name: Install essential packages
  hosts: all
  become: yes
  roles:
    - install_apts
```

**Documentation**: For complete documentation, examples, and advanced usage, see [README_eng.md](README_eng.md)

---

## Русский

Ansible роль для установки основных пакетов на системах Ubuntu/Debian с комплексной валидацией и возможностями отладки.

**Назначение**: Эта роль предоставляет надежное решение для установки основных пакетов на системах Debian/Ubuntu. Она включает валидацию параметров, комплексную обработку ошибок, подробный отладочный вывод и проверку успешной установки.

**Основные возможности**:
- ✅ Валидация параметров и обработка ошибок
- ✅ Подробный отладочный вывод
- ✅ Проверка системы и доступности пакетов
- ✅ Гибкая конфигурация для основных и дополнительных пакетов
- ✅ Настраиваемое управление кэшем APT
- ✅ Опциональные обновления системных пакетов

**Быстрый старт**:
```yaml
---
- name: Установка основных пакетов
  hosts: all
  become: yes
  roles:
    - install_apts
```

**Документация**: Для полной документации, примеров и расширенного использования см. [README_rus.md](README_rus.md)

---

## Requirements / Требования

- Ansible 2.9 or higher / Ansible 2.9 или выше
- Debian/Ubuntu based systems / Системы на базе Debian/Ubuntu
- APT package manager / Менеджер пакетов APT
- Python 3 (for Ansible execution) / Python 3 (для выполнения Ansible)
