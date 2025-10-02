# Ansible Role: proxmox_import_config

[![Ansible Version](https://img.shields.io/badge/ansible-%3E%3D2.14-blue.svg)](https://docs.ansible.com/)
[![License](https://img.shields.io/badge/license-MIT-brightgreen.svg)](LICENSE)

## English

**Purpose:** This role imports and validates configuration variables for Proxmox LXC container deployment from centralized secret storage and host-specific variable files.

**Key Features:**
- ✅ Imports secrets from centralized YAML file
- ✅ Loads host-specific variables from `host_vars`
- ✅ Validates all parameters and file existence with `argument_specs.yml`
- ✅ Verifies host presence in inventory
- ✅ Secure handling of sensitive data with `no_log`
- ✅ Comprehensive debug output with bilingual messages (EN/RU)
- ✅ Error handling with detailed rescue blocks
- ✅ Automatic argument validation (Ansible 2.14+)
- ✅ Preflight checks for Ansible and Python versions
- ✅ Execution metrics and timestamps

**Quick Start:**
```yaml
- hosts: localhost
  roles:
    - role: proxmox_import_config
      vars:
        host_name: "my-lxc-server"
        host_vars: "my_lxc_server"
        debug_mode: true
        debug_lang: 'english'
```

📖 **Full Documentation:** [English Documentation](readme_eng.md)

---

## Русский

**Назначение:** Эта роль импортирует и валидирует конфигурационные переменные для развертывания LXC контейнеров Proxmox из централизованного хранилища секретов и файлов переменных хостов.

**Ключевые возможности:**
- ✅ Импорт секретов из централизованного YAML файла
- ✅ Загрузка переменных конкретного хоста из `host_vars`
- ✅ Валидация всех параметров и существования файлов через `argument_specs.yml`
- ✅ Проверка наличия хоста в инвентори
- ✅ Безопасная обработка чувствительных данных с `no_log`
- ✅ Подробный отладочный вывод с двуязычными сообщениями (EN/RU)
- ✅ Обработка ошибок с детальными rescue-блоками
- ✅ Автоматическая валидация аргументов (Ansible 2.14+)
- ✅ Предварительные проверки версий Ansible и Python
- ✅ Метрики выполнения и временные метки

**Быстрый старт:**
```yaml
- hosts: localhost
  roles:
    - role: proxmox_import_config
      vars:
        host_name: "my-lxc-server"
        host_vars: "my_lxc_server"
        debug_mode: true
        debug_lang: 'russian'
```

📖 **Полная документация:** [Документация на русском](readme_rus.md)

---

## Requirements / Требования

- **Ansible:** >= 2.14
- **Python:** >= 3.8
- **Proxmox VE** environment
- Properly configured `secrets.yaml` file
- Host-specific variables in `host_vars/`
- Host entry in inventory file

---

## Role Variables / Переменные роли

### Required Variables / Обязательные переменные

| Variable | Type | Description |
|----------|------|-------------|
| `host_name` | string | Host name for loading host_vars (must match file name without .yml) |
| `host_vars` | string | Prefix for variables in secrets.yaml |

### Optional Variables / Опциональные переменные

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `debug_mode` | bool | `false` | Enable detailed debug output |
| `debug_lang` | string | `'both'` | Debug language: 'english', 'russian', 'both' |
| `debug_sensitive` | bool | `false` | Show passwords in debug (INSECURE) |
| `validate_parameters` | bool | `true` | Enable parameter validation |
| `strict_validation` | bool | `true` | Enable strict validation mode |
| `backup_enabled` | bool | `true` | Enable configuration backups |
| `enable_rollback` | bool | `true` | Enable automatic rollback on failure |
| `ansible_base_dir` | string | `"/etc/ansible"` | Base directory for Ansible configuration |
| `async_timeout` | int | `300` | Async task timeout in seconds |
| `retries` | int | `3` | Number of retries for failed tasks |
| `retry_delay` | int | `5` | Delay between retries in seconds |

See [defaults/main.yml](defaults/main.yml) and [meta/argument_specs.yml](meta/argument_specs.yml) for complete list.

---

## Dependencies / Зависимости

None / Отсутствуют

---

## Example Playbook / Пример плейбука

### Basic Usage / Базовое использование

```yaml
---
- name: Import Proxmox configuration
  hosts: localhost
  connection: local
  gather_facts: true
  
  roles:
    - role: proxmox_import_config
      vars:
        host_name: "my-lxc-server"
        host_vars: "my_lxc_server"
```

### With Debug Output / С отладочным выводом

```yaml
---
- name: Import Proxmox configuration with debug
  hosts: localhost
  connection: local
  gather_facts: true
  
  roles:
    - role: proxmox_import_config
      vars:
        host_name: "my-lxc-server"
        host_vars: "my_lxc_server"
        debug_mode: true
        debug_lang: 'both'
        validate_parameters: true
```

### With Sensitive Data Display (Development Only) / С отображением секретных данных (только для разработки)

```yaml
---
- name: Import with sensitive debug (INSECURE - DEV ONLY)
  hosts: localhost
  connection: local
  gather_facts: true
  
  roles:
    - role: proxmox_import_config
      vars:
        host_name: "my-lxc-server"
        host_vars: "my_lxc_server"
        debug_mode: true
        debug_sensitive: true  # WARNING: Shows passwords!
        debug_lang: 'english'
```

---

## Tags / Теги

| Tag | Description |
|-----|-------------|
| `always` | Always executed tasks |
| `validate` | Validation tasks |
| `preflight` | Preflight checks |
| `import` | Import tasks |
| `secrets` | Secrets import tasks |
| `host_vars` | Host variables import tasks |
| `debug` | Debug output tasks |
| `sensitive` | Sensitive data display tasks |
| `summary` | Summary output tasks |

**Example usage:**
```bash
# Run only validation
ansible-playbook playbook.yml --tags validate

# Skip preflight checks
ansible-playbook playbook.yml --skip-tags preflight

# Run only import without debug
ansible-playbook playbook.yml --tags import --skip-tags debug
```

---

## File Structure / Структура файлов

```
proxmox_import_config/
├── defaults/
│   └── main.yml              # Default variables
├── meta/
│   ├── main.yml              # Galaxy metadata
│   └── argument_specs.yml    # Argument specifications
├── tasks/
│   ├── main.yml              # Main tasks
│   ├── preflight.yml         # Preflight checks
│   └── validate.yml          # Validation tasks
├── README.md                 # This file
├── readme_eng.md             # English documentation
├── readme_rus.md             # Russian documentation
└── example-playbook.yml      # Example playbook
```

---

## Documentation / Документация

- 🇬🇧 [Full English Documentation](readme_eng.md)
- 🇷🇺 [Полная документация на русском](readme_rus.md)
- 📝 [Example Playbook](example-playbook.yml)

---

## What's New in v2.0 / Что нового в версии 2.0

### Added / Добавлено
- ✨ **Automatic argument validation** with `meta/argument_specs.yml` (Ansible 2.14+)
- ✨ **Preflight checks** for Ansible/Python versions
- ✨ **Bilingual logging** with `debug_lang` parameter
- ✨ **Execution metrics** and timestamps
- ✨ **Galaxy metadata** for Ansible Galaxy publishing
- ✨ **Improved error handling** with separate EN/RU rescue blocks

### Changed / Изменено
- 🔄 Updated minimum Ansible version to **2.14**
- 🔄 All files renamed from `.yaml` to `.yml`
- 🔄 Task names are now **English only** (as per best practices)
- 🔄 Improved debug output formatting
- 🔄 Enhanced variable validation

---

## License / Лицензия

MIT

---

## Author / Автор

**Mad-Axell**  
DevOps Team

---

## Support / Поддержка

For issues, questions, or contributions, please:
- Open an issue in the repository
- Check the full documentation in `readme_eng.md` or `readme_rus.md`

Для вопросов, проблем или предложений:
- Откройте issue в репозитории
- Проверьте полную документацию в `readme_eng.md` или `readme_rus.md`
