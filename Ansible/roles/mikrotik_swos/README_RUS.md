# mikrotik_swos

Роль сверяет и настраивает коммутатор MikroTik CSS326 через неофициальный HTTP-протокол SwOS. Перед любым реальным исправлением drift она проверяет модель, точную версию SwOS и количество портов, создаёт локальную бинарную `.swb`-копию и применяет конфигурацию в порядке `VLANs → VLAN → Link → System`.

## Что делает

- Проверяет точное совпадение модели, версии SwOS и количества портов.
- Сравнивает целевые секции `System`, `Link`, `VLAN` и `VLANs` с устройством.
- В check mode только читает состояние и сообщает о планируемом изменении.
- Перед реальным изменением сохраняет `.swb` на Ansible-контроллере с режимом файла `0600`.
- Применяет таблицу VLAN, настройки VLAN портов, состояние портов и параметры управления именно в таком порядке.
- После изменения повторно читает устройство и завершает play с ошибкой при оставшемся drift.
- Требует оба подтверждения безопасности для любого реального запуска.

Автоматический rollback не выполняется: при потере управления восстановление делается физически из предварительно сохранённой `.swb`-копии.

## Требования

- Ansible запускается на контроллере с Python 3 и библиотекой `mikrotik-swos==1.3.2`.
- Библиотека устанавливается из project-level `requirements-controller.txt` с проверкой hash.
- Коммутатор доступен контроллеру по HTTP в доверенной management-сети; закреплённая библиотека выполняет HTTP Digest с переданными именем пользователя и паролем.
- Пользователь контроллера может создавать файлы в `mikrotik_swos_backup_directory`; каталог находится на зашифрованном хранилище вне Git.
- Целевая платформа по умолчанию: `CSS326-24G-2S+`, SwOS `2.18`, 26 портов.
- До реального запуска нужен ручной backup, проверенный физический recovery-доступ и окно обслуживания.

## Изменяемые ресурсы

- Packages: none; controller dependency устанавливается отдельно.
- Files: бинарная `.swb`-копия в каталоге контроллера перед реальным drift.
- Services: none.
- Users/groups: none.
- Network objects: таблица VLAN, VLAN-параметры портов, включение портов и System management settings SwOS.

## Переменные

| Variable | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `mikrotik_swos_host` | string | yes | `null` | IPv4-адрес или HTTP URL коммутатора. |
| `mikrotik_swos_username` | string | no | `"admin"` | Административный пользователь SwOS. |
| `mikrotik_swos_configuration` | dictionary | yes | `null` | Полная внешняя целевая конфигурация `system`, `ports`, `port_vlans`, `vlans`; реальные значения не входят в defaults роли. |
| `mikrotik_swos_expected_model` | string | no | `"CSS326-24G-2S+"` | Точная допустимая модель. |
| `mikrotik_swos_expected_version` | string | no | `"2.18"` | Точная допустимая версия SwOS. |
| `mikrotik_swos_expected_port_count` | integer | no | `26` | Точное количество портов. |
| `mikrotik_swos_allow_network_changes` | boolean | no | `false` | Явно разрешить реальное сетевое изменение. |
| `mikrotik_swos_recovery_access_confirmed` | boolean | no | `false` | Подтвердить проверенный физический recovery-доступ. |
| `mikrotik_swos_backup_directory` | string | no | `"/var/backups/mikrotik-swos"` | Каталог контроллера на зашифрованном хранилище вне Git для `.swb`. |
| `mikrotik_swos_debug_mode` | boolean | no | `false` | Включить безопасные английские debug-сводки. |

Обязательный секрет `vault_mikrotik_swos_passwords` не объявляется в defaults. Вызывающий проект передаёт словарь, где ключ равен inventory alias коммутатора, а значение является его паролем SwOS. Роль проверяет наличие непустого значения и передаёт имя пользователя и пароль библиотеке для HTTP Digest.

## Использование

Inventory определяет `ansible_host`. Реальную конфигурацию конкретного коммутатора следует хранить отдельно от универсальной роли, например в `host_vars/<inventory_alias>.yml`; Ansible загрузит её автоматически. Playbook явно подключает project-level файл секретов:

```yaml
---
- name: Configure MikroTik SwOS switches
  hosts: mikrotik_switches_group
  gather_facts: false
  vars_files:
    - ../VARS/secrets.yml
  roles:
    - role: mikrotik_swos
      vars:
        mikrotik_swos_host: "{{ ansible_host }}"
```

Check mode:

```bash
ansible-playbook -i hosts.yml playbooks/network/mikrotik_swos.yml \
  --check --diff --limit MgmtLanSwitch
```

Реальный запуск дополнительно требует оба флага:

```bash
ansible-playbook -i hosts.yml playbooks/network/mikrotik_swos.yml \
  --limit MgmtLanSwitch \
  -e mikrotik_swos_allow_network_changes=true \
  -e mikrotik_swos_recovery_access_confirmed=true
```

## Check mode и diff mode

В `--check` роль выполняет HTTP-чтение и валидацию, но не создаёт backup и не отправляет POST-запросы. Из-за чувствительной HTTP-аутентификации задача всегда использует `no_log: true` и `diff: false`; наружу выводится только безопасный факт планируемого изменения.

## Безопасность

- Роль не содержит пароль и не загружает файл секретов самостоятельно.
- Способ хранения внешнего `vault_mikrotik_swos_passwords` определяет вызывающий проект; секрет не должен попадать в inventory, host vars, defaults или вывод задач.
- Backup создаётся до первого POST-запроса; ошибка backup останавливает изменение.
- Оба gate-флага по умолчанию `false`.
- HTTP следует использовать только в изолированной management-сети.

## Tags

- `debug` — безопасные сводки после фактического или планируемого изменения.

## Зависимости

- `mikrotik-swos==1.3.2` на Ansible-контроллере.
- `requests>=2.25.0` как runtime-зависимость библиотеки.
- Role-local module `library/mikrotik_swos_config.py`.
