# set_timezone

The role brings the host system timezone to the requested value.

## What it does

- Validates that a timezone name is set.
- Applies the timezone through `community.general.timezone`.

## Requirements

- `become: true`.
- The `community.general` collection.

## Managed resources

- Files: `/etc/localtime` and `/etc/timezone`, written by the module.
- Services: the module restarts `cron` when the system requires it.
- Packages: none.
- Users/groups: none.

## Variables

| Variable | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `set_timezone_name` | string | yes | `null` | IANA timezone name, for example `Europe/Moscow`. |
| `set_timezone_debug_mode` | boolean | no | `false` | Reports that a change happened. |

## Secret external inputs

The role uses no secrets and does not read `VARS/secrets.yml`.

## Usage

```yaml
---
- name: Set the host timezone
  hosts: all
  become: true
  roles:
    - role: set_timezone
      vars:
        set_timezone_name: "Europe/Moscow"
```

## Check mode and diff mode

`community.general.timezone` supports check mode; under `--check` the timezone is
not changed and the change is only predicted.

## Dependencies

- `community.general`

## Handlers and tags

- Handlers: none.
- Tags: `debug` on the final debug task.
