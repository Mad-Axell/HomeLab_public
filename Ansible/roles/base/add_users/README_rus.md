# add_users

Роль управляет локальными учетными записями Linux, дополнительными группами и членством в `sudo`. Она не настраивает PAM, политику паролей или SSH.

## Что делает

- Создает явно указанные группы и группы из описаний пользователей.
- Создает или обновляет локальные учетные записи и их домашние каталоги.
- Устанавливает `sudo` и добавляет в его группу только пользователей с `sudo: true`.

## Требования

- Целевая система Linux с доступным пакетным менеджером.
- Права `become: true`.
- Хэши паролей хранятся во внешнем `VARS/secrets.yml` под именами `vault_add_users_<name>_password_hash`.

## Изменяемые ресурсы

- Packages: `sudo`, только для привилегированных пользователей.
- Files: домашние каталоги управляемых пользователей.
- Services: none.
- Users/groups: локальные пользователи, дополнительные группы и группа `sudo`.
- Firewall/API objects: none.

## Переменные

| Variable | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `add_users_debug_mode` | boolean | no | `false` | Включает краткий debug-вывод после изменений. |
| `add_users_create_home` | boolean | no | `true` | Значение `create_home` по умолчанию. |
| `add_users_default_shell` | string | no | `"/bin/bash"` | Оболочка по умолчанию. |
| `add_users_home_prefix` | string | no | `"/home"` | Родительский каталог домашних каталогов. |
| `add_users_home_mode` | string | no | `"0750"` | Права домашних каталогов. |
| `add_users_groups` | list | no | `[]` | Дополнительные группы для создания. |
| `add_users_users` | list | no | `[]` | Список словарей с ключом `name`; поддерживает `groups`, `sudo`, `shell`, `home`, `create_home`, `uid`, `comment`, `password_hash_var`. |
| `vault_add_users_<name>_password_hash` | string | conditional | - | Внешний хэш пароля из `VARS/secrets.yml`, обязателен, если он указан через `password_hash_var`. |

## Использование

```yaml
---
- name: Manage local accounts
  hosts: linux
  become: true
  roles:
    - role: base/add_users
      vars:
        add_users_groups:
          - "developers"
        add_users_users:
          - name: "alice"
            groups: ["developers"]
            sudo: true
            password_hash_var: "vault_add_users_alice_password_hash"
```

## Check mode и diff mode

Большинство задач поддерживает `--check --diff`. Задачи, использующие хэши паролей, имеют `no_log: true` и `diff: false`, поэтому содержимое пароля и diff не отображаются.

## Зависимости

- None

## Примечания

- Перед изменениями роль проверяет имена пользователей и наличие указанных секретов.
- В `add_users_users` передавайте хэш пароля, а не открытый пароль.
