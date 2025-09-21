# Ansible Role: set_locale

Роль для настройки локализации, часового пояса, раскладки клавиатуры и консольного шрифта в системах Debian/Ubuntu и RedHat/CentOS.

## Описание

Эта роль автоматизирует настройку системной локализации, включая:
- Установку и генерацию локалей
- Настройку переменных окружения для локализации
- Конфигурацию часового пояса
- Настройку раскладки клавиатуры (только для Debian/Ubuntu)
- Конфигурацию консольного шрифта
- Создание резервных копий конфигурационных файлов

## Поддерживаемые платформы

- **Debian/Ubuntu** - полная поддержка всех функций
- **RedHat/CentOS** - базовая поддержка локализации и часового пояса

## Требования

### Ansible
- Ansible >= 2.9
- Python >= 3.6

### Коллекции
- `community.general` - для модулей `locale_gen` и `timezone`

### Права доступа
- Роль требует права root (`become: true`)

## Переменные роли

### Основные настройки

| Переменная | По умолчанию | Описание |
|------------|--------------|----------|
| `debug_mode` | `false` | Включить отладочный вывод |
| `backup_enabled` | `true` | Создавать резервные копии файлов |
| `backup_suffix` | `".backup"` | Суффикс для резервных копий |

### Локализация

| Переменная | По умолчанию | Описание |
|------------|--------------|----------|
| `locale_primary` | `"en_US.UTF-8"` | Основная локаль системы |
| `locale_language` | `"en_US"` | Язык системы |
| `locale_encoding` | `"UTF-8"` | Кодировка |
| `locale_additional` | `["en_US.UTF-8", "ru_RU.UTF-8"]` | Дополнительные локали для генерации |

### Переменные окружения

| Переменная | По умолчанию | Описание |
|------------|--------------|----------|
| `locale_variables` | См. ниже | Словарь переменных окружения для локализации |

По умолчанию `locale_variables` содержит:
```yaml
locale_variables:
  LANG: "{{ locale_primary }}"
  LANGUAGE: "{{ locale_language }}"
  LC_ALL: "{{ locale_primary }}"
  LC_COLLATE: "{{ locale_primary }}"
  LC_CTYPE: "{{ locale_primary }}"
  LC_MESSAGES: "{{ locale_primary }}"
  LC_MONETARY: "{{ locale_primary }}"
  LC_NUMERIC: "{{ locale_primary }}"
  LC_TIME: "{{ locale_primary }}"
```

### Часовой пояс

| Переменная | По умолчанию | Описание |
|------------|--------------|----------|
| `timezone` | `"Europe/Moscow"` | Часовой пояс системы |
| `timezone_manage` | `true` | Управлять настройкой часового пояса |

### Клавиатура (только Debian/Ubuntu)

| Переменная | По умолчанию | Описание |
|------------|--------------|----------|
| `keyboard_layout` | `"us"` | Раскладка клавиатуры |
| `keyboard_variant` | `""` | Вариант раскладки |
| `keyboard_options` | `""` | Дополнительные опции клавиатуры |

#### Примеры значений для клавиатуры:

**Раскладки (`keyboard_layout`):**
- `"us"` - английская
- `"ru"` - русская
- `"de"` - немецкая
- `"fr"` - французская

**Варианты (`keyboard_variant`):**
- `""` - стандартный
- `"dvorak"` - раскладка Дворака (для US)
- `"phonetic"` - фонетическая (для RU)
- `"nodeadkeys"` - без мертвых клавиш (для DE)

**Опции (`keyboard_options`):**
- `"ctrl:nocaps"` - Caps Lock как Ctrl
- `"compose:rctrl"` - правый Ctrl как Compose

### Консольный шрифт

| Переменная | По умолчанию | Описание |
|------------|--------------|----------|
| `console_font` | `"Lat2-Terminus16"` | Шрифт консоли |
| `console_font_manage` | `true` | Управлять настройкой шрифта |

## Примеры использования

### Базовое использование

```yaml
- hosts: servers
  become: true
  roles:
    - role: base.set_locale
```

### Настройка русской локализации

```yaml
- hosts: servers
  become: true
  roles:
    - role: base.set_locale
      vars:
        locale_primary: "ru_RU.UTF-8"
        locale_language: "ru_RU"
        timezone: "Europe/Moscow"
        keyboard_layout: "ru"
        keyboard_variant: "phonetic"
```

### Настройка для разработчика

```yaml
- hosts: dev_servers
  become: true
  roles:
    - role: base.set_locale
      vars:
        locale_primary: "en_US.UTF-8"
        timezone: "UTC"
        keyboard_layout: "us"
        keyboard_variant: "dvorak"
        keyboard_options: "ctrl:nocaps"
        debug_mode: true
```

### Мультиязычная среда

```yaml
- hosts: servers
  become: true
  roles:
    - role: base.set_locale
      vars:
        locale_primary: "en_US.UTF-8"
        locale_additional:
          - "en_US.UTF-8"
          - "ru_RU.UTF-8"
          - "de_DE.UTF-8"
          - "fr_FR.UTF-8"
```

## Структура роли

```
+set_locale/
├── defaults/
│   └── main.yaml          # Переменные по умолчанию
├── handlers/
│   └── main.yml           # Обработчики событий
├── tasks/
│   └── main.yaml          # Основные задачи
└── README.md              # Документация
```

## Задачи роли

1. **Gather system facts** - сбор информации о системе
2. **Debug system information** - отладочный вывод (при `debug_mode: true`)
3. **Backup existing locale configuration** - создание резервных копий
4. **Install locale packages** - установка пакетов локализации
5. **Generate additional locales** - генерация дополнительных локалей
6. **Configure system locale variables** - настройка переменных в `/etc/default/locale`
7. **Configure environment locale variables** - настройка переменных в `/etc/environment`
8. **Configure system timezone** - настройка часового пояса
9. **Configure keyboard layout/variant/options** - настройка клавиатуры (Debian/Ubuntu)
10. **Configure console font** - настройка консольного шрифта
11. **Update locale database** - обновление базы данных локалей

## Обработчики

- `reload locale` - перезагрузка локалей
- `reload timezone` - применение настроек часового пояса
- `reload console` - применение настроек консоли
- `restart timesyncd` - перезапуск службы синхронизации времени
- `restart ssh` - перезапуск SSH служб
- `flush locale cache` - очистка кэша локалей

## Файлы, которые изменяет роль

### Конфигурационные файлы:
- `/etc/default/locale` - системные переменные локализации
- `/etc/environment` - переменные окружения
- `/etc/locale.gen` - генерация локалей
- `/etc/default/console-setup` - настройки консоли

### Резервные копии (при `backup_enabled: true`):
- `/etc/default/locale.backup`
- `/etc/environment.backup`
- `/etc/locale.gen.backup`

## Требования к системе

### Debian/Ubuntu:
- Пакеты: `locales`, `locales-all`, `tzdata`, `keyboard-configuration`, `console-setup`

### RedHat/CentOS:
- Пакеты: `glibc-locale-source`, `glibc-langpack-en`, `tzdata`, `kbd`

## Ограничения

1. **Клавиатура**: Настройка клавиатуры работает только на системах Debian/Ubuntu
2. **Права доступа**: Роль требует права root для всех операций
3. **Коллекции**: Требуется установка коллекции `community.general`

## Устранение неполадок

### Проблема: "The value '.backup' is not a valid boolean"
**Решение**: Убедитесь, что используется исправленная версия роли с правильными boolean значениями для параметра `backup`.

### Проблема: Локали не применяются
**Решение**: 
1. Проверьте, что `locale_primary` существует в `locale_additional`
2. Убедитесь, что пакеты локализации установлены
3. Запустите роль с правами root

### Проблема: Клавиатура не настраивается
**Решение**: 
1. Убедитесь, что система Debian/Ubuntu
2. Проверьте, что `keyboard_layout` не пустая
3. Убедитесь, что пакет `keyboard-configuration` установлен

## Лицензия

MIT

## Автор

Ansible Role для настройки локализации системы
