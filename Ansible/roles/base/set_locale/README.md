# System Locale Configuration Role / Роль настройки системной локализации

## Description / Описание

**English:** The `base.set_locale` role provides comprehensive configuration of system locale, timezone, keyboard layout, and console font for Debian/Ubuntu and RedHat/CentOS systems with advanced validation and debugging capabilities.

**Русский:** Роль `base.set_locale` обеспечивает комплексную настройку системной локализации, часового пояса, раскладки клавиатуры и консольного шрифта для систем Debian/Ubuntu и RedHat/CentOS с расширенными возможностями валидации и отладки.

## Key Features / Основные возможности

- ✅ **Multi-platform support** / **Поддержка множественных платформ**
- ✅ **Parameter validation** / **Валидация параметров**
- ✅ **Backup functionality** / **Функции резервного копирования**
- ✅ **Debug mode** / **Режим отладки**
- ✅ **Error handling** / **Обработка ошибок**
- ✅ **Selective execution** / **Выборочное выполнение**
- ✅ **OS-specific configurations** / **OS-специфичные настройки**

## Supported Platforms / Поддерживаемые платформы

- **Debian/Ubuntu:** 9, 10, 11, 12 / 18.04, 20.04, 22.04, 24.04
- **RedHat/CentOS:** 7, 8, 9
- **Rocky Linux:** 8, 9
- **AlmaLinux:** 8, 9
- **SUSE/openSUSE:** Leap 15.x, SLES 12, 15

## Quick Start / Быстрый старт

```yaml
- hosts: servers
  roles:
    - role: base.set_locale
      vars:
        locale_primary: "en_US.UTF-8"
        timezone: "UTC"
        keyboard_layout: "us"
```

## Documentation / Документация

For complete documentation, please refer to:

Для полной документации обратитесь к:

- **[English Documentation](readme_eng.md)** / **[Документация на английском](readme_eng.md)**
- **[Русская документация](readme_rus.md)** / **[Russian Documentation](readme_rus.md)**

## Requirements / Требования

- Ansible >= 2.9
- Python >= 3.6
- Root or sudo privileges / Права root или sudo

## License / Лицензия

MIT

## Автор

Mad-Axell
