# Роль настройки системной локализации base.set_locale

## Описание

Роль `base.set_locale` предназначена для комплексной настройки системной локализации, часового пояса, раскладки клавиатуры и консольного шрифта на системах Debian/Ubuntu и RedHat/CentOS. Роль обеспечивает надежную конфигурацию с валидацией параметров, резервным копированием и подробной отладочной информацией.

## Возможности

- ✅ Настройка системной локализации (LANG, LC_*, LANGUAGE)
- ✅ Конфигурация часового пояса
- ✅ Настройка раскладки клавиатуры (Debian/Ubuntu и RedHat/CentOS)
- ✅ Конфигурация консольного шрифта
- ✅ Генерация дополнительных локалей
- ✅ Валидация входных параметров
- ✅ Резервное копирование конфигурационных файлов
- ✅ Подробная отладочная информация
- ✅ Обработка ошибок и уведомления
- ✅ Поддержка множественных платформ
- ✅ OS-специфичные настройки

## Поддерживаемые платформы

### Debian/Ubuntu
- Debian 9, 10, 11, 12
- Ubuntu 18.04, 20.04, 22.04, 24.04

### RedHat/CentOS
- CentOS 7, 8, 9
- Rocky Linux 8, 9
- AlmaLinux 8, 9

## Требования

### Системные требования
- Ansible >= 2.9
- Python >= 3.6
- Права root или sudo

### Коллекции Ansible
```yaml
collections:
  - community.general
  - ansible.builtin
```

### Пакеты (устанавливаются автоматически)
**Debian/Ubuntu:**
- locales
- console-setup
- keyboard-configuration

**RedHat/CentOS:**
- glibc-locale-source
- glibc-langpack-en
- kbd

## Переменные роли

### Основные настройки

| Переменная | По умолчанию | Описание |
|------------|--------------|----------|
| `locale_primary` | `"en_US.UTF-8"` | Основная локаль системы |
| `locale_language` | `"en_US"` | Язык локали |
| `locale_encoding` | `"UTF-8"` | Кодировка локали |
| `timezone` | `"Europe/Moscow"` | Часовой пояс |
| `keyboard_layout` | `"us"` | Раскладка клавиатуры |
| `console_font` | `"Lat2-Terminus16"` | Консольный шрифт |

### Дополнительные настройки

| Переменная | По умолчанию | Описание |
|------------|--------------|----------|
| `locale_additional` | `["en_US.UTF-8", "ru_RU.UTF-8"]` | Дополнительные локали |
| `backup_enabled` | `true` | Включить резервное копирование |
| `debug_mode` | `false` | Включить отладочный режим |
| `validate_parameters` | `true` | Включить валидацию параметров |
| `strict_validation` | `true` | Строгая валидация |

### Настройки клавиатуры

| Переменная | По умолчанию | Описание |
|------------|--------------|----------|
| `keyboard_variant` | `""` | Вариант раскладки клавиатуры |
| `keyboard_options` | `""` | Дополнительные опции клавиатуры |

## Примеры использования

### Базовое использование

```yaml
- hosts: servers
  roles:
    - role: base.set_locale
      vars:
        locale_primary: "ru_RU.UTF-8"
        timezone: "Europe/Moscow"
        keyboard_layout: "ru"
```

### Расширенная конфигурация

```yaml
- hosts: servers
  roles:
    - role: base.set_locale
      vars:
        # Локализация
        locale_primary: "en_US.UTF-8"
        locale_language: "en_US"
        locale_encoding: "UTF-8"
        locale_additional:
          - "en_US.UTF-8"
          - "ru_RU.UTF-8"
          - "de_DE.UTF-8"
        
        # Часовой пояс
        timezone: "UTC"
        timezone_manage: true
        
        # Клавиатура
        keyboard_layout: "us"
        keyboard_variant: "dvorak"
        keyboard_options: "compose:rctrl"
        
        # Консоль
        console_font: "Lat2-Terminus14"
        console_font_manage: true
        
        # Настройки роли
        backup_enabled: true
        debug_mode: true
        validate_parameters: true
        strict_validation: true
```

### Отключение компонентов

```yaml
- hosts: servers
  roles:
    - role: base.set_locale
      vars:
        timezone_manage: false      # Не настраивать часовой пояс
        console_font_manage: false  # Не настраивать консольный шрифт
        keyboard_layout: ""         # Не настраивать клавиатуру
```

## Теги

Роль поддерживает следующие теги для выборочного выполнения:

| Тег | Описание |
|-----|----------|
| `locale` | Все операции с локализацией |
| `timezone` | Настройка часового пояса |
| `keyboard` | Настройка клавиатуры |
| `console` | Настройка консоли |
| `backup` | Резервное копирование |
| `validation` | Валидация параметров |
| `debug` | Отладочная информация |
| `system` | Системные операции |
| `packages` | Установка пакетов |
| `debian` | Операции для Debian/Ubuntu |
| `redhat` | Операции для RedHat/CentOS |

### Пример использования тегов

```bash
# Выполнить только настройку локализации
ansible-playbook playbook.yml --tags locale

# Выполнить настройку без резервного копирования
ansible-playbook playbook.yml --skip-tags backup

# Выполнить с отладочной информацией
ansible-playbook playbook.yml --tags debug

# Выполнить только для Debian/Ubuntu
ansible-playbook playbook.yml --tags debian

# Выполнить только установку пакетов
ansible-playbook playbook.yml --tags packages
```

## Валидация параметров

Роль включает комплексную валидацию входных параметров:

### Валидация локали
- Формат: `ll_CC.ENCODING` (например, `en_US.UTF-8`)
- Поддерживаемые кодировки: UTF-8, ISO-8859-1, и др.

### Валидация часового пояса
- Формат: `Region/City` (например, `Europe/Moscow`)
- Поддерживаются все стандартные часовые пояса

### Валидация клавиатуры
- Поддерживаемые раскладки: us, ru, de, fr, es, it, pt, nl, sv, no, da, fi, pl, cs, hu, tr, ja, ko, zh, ar, he
- Варианты: dvorak, phonetic, nodeadkeys, deadkeys, mac, altgr-intl, euro, euro2

### Валидация консольного шрифта
- Поддерживаются все стандартные шрифты Terminus
- Размеры: 10, 12, 14, 16
- Стили: обычный, жирный
- Кодировки: Lat2, Lat15, Lat7, Uni1, Uni2, Uni3, CyrSlav, Grk, ArmPit, Arab, Heb, Thai, Lao

## Резервное копирование

Роль автоматически создает резервные копии конфигурационных файлов:

- `/etc/default/locale.backup`
- `/etc/environment.backup`
- `/etc/locale.gen.backup`
- `/etc/default/console-setup.backup` (Debian/Ubuntu)
- `/etc/vconsole.conf.backup` (RedHat/CentOS)

Резервное копирование можно отключить установкой `backup_enabled: false`.

## Отладка

Для включения подробной отладочной информации установите `debug_mode: true`. Это выведет:

- Системную информацию
- Результаты валидации
- Детали операций резервного копирования
- Результаты конфигурации
- Итоговую сводку

## Обработка ошибок

Роль включает надежную обработку ошибок:

- Валидация параметров перед выполнением
- Обработка отсутствующих файлов
- Игнорирование некритичных ошибок
- Подробные сообщения об ошибках

## Файлы роли

```
roles/base/set_locale/
├── defaults/main.yml      # Переменные по умолчанию
├── handlers/main.yml      # Обработчики уведомлений
├── meta/main.yml          # Метаданные роли
├── tasks/
│   ├── main.yml           # Основные задачи
│   ├── debian.yml         # Задачи для Debian/Ubuntu
│   ├── redhat.yml         # Задачи для RedHat/CentOS
│   └── validate.yml       # Валидация параметров
└── README.md              # Документация
```

## Зависимости

Роль не имеет внешних зависимостей от других ролей.

## Лицензия

MIT

## Автор

Mad-Axell
