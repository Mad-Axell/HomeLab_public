# Proxmox Import Config Role

Роль для импорта и валидации конфигурационных переменных Proxmox LXC контейнеров из централизованного хранилища секретов и файлов переменных хостов.

## Краткий обзор

Эта роль выполняет следующие функции:
- Импорт секретов из централизованного файла
- Импорт переменных хоста из host_vars
- Валидация YAML синтаксиса и структуры данных
- Структурированное логирование всех операций

## Быстрый старт

```yaml
- name: Import Proxmox configuration
  ansible.builtin.include_role:
    name: proxmox_import_config
  vars:
    host_name: "my-server"
    host_vars: "my_server"
    debug_mode: true
```

## Основные переменные

| Переменная | Описание | По умолчанию |
|------------|----------|--------------|
| `host_name` | Имя хоста для загрузки host_vars | `some-server` |
| `host_vars` | Префикс переменных в secrets.yaml | `some_server` |
| `debug_mode` | Включить отладочный вывод | `false` |
| `log_file` | Путь к файлу лога | `/var/log/ansible-changes.log` |

## Документация

- [README_eng.md](README_eng.md) - Полная английская документация
- [README_rus.md](README_rus.md) - Полная русская документация

## Требования

- Ansible 2.14+
- Python 3.8+
- Доступ к файлам секретов и host_vars

## Лицензия

MIT

## Автор

Mad-Axell <mad.axell@gmail.com>
