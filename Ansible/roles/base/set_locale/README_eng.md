# set_locale

This role generates the selected locale and configures it in `/etc/default/locale` on Debian/Ubuntu.

## What it does

- Installs the `locales` package.
- Generates the selected locale.
- Sets `LANG` and `LC_ALL` in `/etc/default/locale`.

## Requirements

- Debian or Ubuntu.
- `become: true`.
- The `community.general` collection pinned in the project-level `requirements.yml`.

## Managed resources

- Packages: `locales`.
- Files: `/etc/default/locale`.
- Services: none.
- Users/groups: none.
- Firewall/API objects: none.

## Variables

| Variable | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `set_locale_debug_mode` | boolean | no | `false` | Reports whether the locale changed. |
| `set_locale_name` | string | no | `"en_US.UTF-8"` | Locale to generate and configure. |

## Usage

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

## Check mode and diff mode

Changing `/etc/default/locale` supports `--check --diff`; locale-generation support depends on `community.general.locale_gen` capabilities on the target system.

## Dependencies

- `community.general`
