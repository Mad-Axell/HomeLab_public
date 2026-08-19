# set_locale

Роль генерирует выбранную локаль и устанавливает ее в `/etc/default/locale` на Debian/Ubuntu.

## Что делает

- Устанавливает пакет `locales`.
- Генерирует указанную локаль.
- Устанавливает `LANG` и `LC_ALL` в `/etc/default/locale`.

## Требования

- Debian или Ubuntu.
- `become: true`.
- Коллекция `community.general`, зафиксированная в project-level `requirements.yml`.

## Изменяемые ресурсы

- Packages: `locales`.
- Files: `/etc/default/locale`.
- Services: none.
- Users/groups: none.
- Firewall/API objects: none.

## Переменные

| Variable | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `set_locale_debug_mode` | boolean | no | `false` | Показывает факт изменения локали. |
| `set_locale_name` | string | no | `"en_US.UTF-8"` | Локаль для генерации и установки. |

## Использование

```yaml
---
- name: Configure locale
  hosts: debian
  become: true
  roles:
    - role: base/set_locale
      vars:
        set_locale_name: "ru_RU.UTF-8"
```

## Check mode и diff mode

Изменение `/etc/default/locale` поддерживает `--check --diff`; поддержка генерации локали зависит от возможностей `community.general.locale_gen` на целевой системе.

## Зависимости

- `community.general`
