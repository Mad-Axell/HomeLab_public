# sysctl_tunables

The role manages an arbitrary set of kernel parameters: it stores them in a
single file under `/etc/sysctl.d` and applies them to the running system.

## What it does

- Validates that every declared tunable has both `name` and `value`.
- Writes the tunables into `sysctl_tunables_file` and applies them.

The role knows nothing about specific parameters and sets no defaults: an empty
`sysctl_tunables_settings` is a valid state meaning there is nothing to manage.

## Requirements

- `become: true`.
- The `ansible.posix` collection.
- The host must be allowed to change the listed parameters. Inside an
  unprivileged LXC some kernel parameters are read-only and such a task fails —
  that is an environment limitation, not a role defect.

## Managed resources

- Files: `sysctl_tunables_file`.
- Other: the kernel parameter values on the running system.
- Packages, Services, Users/groups: none.

## Variables

| Variable | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `sysctl_tunables_settings` | list | no | `[]` | List of dictionaries with `name` and `value`; an empty list is allowed. |
| `sysctl_tunables_file` | string | no | `"/etc/sysctl.d/99-ansible-tunables.conf"` | File that stores the tunables. |
| `sysctl_tunables_reload` | boolean | no | `true` | Apply the values immediately. |
| `sysctl_tunables_debug_mode` | boolean | no | `false` | Reports the tunables that changed. |

## Secret external inputs

The role uses no secrets and does not read `VARS/secrets.yml`.

## Usage

```yaml
---
- name: Disable IPv6
  hosts: all
  become: true
  roles:
    - role: sysctl_tunables
      vars:
        sysctl_tunables_file: "/etc/sysctl.d/99-disable-ipv6.conf"
        sysctl_tunables_settings:
          - name: "net.ipv6.conf.all.disable_ipv6"
            value: 1
          - name: "net.ipv6.conf.default.disable_ipv6"
            value: 1
```

## Check mode and diff mode

`ansible.posix.sysctl` supports `--check --diff` and shows the file change
naturally.

## Dependencies

- `ansible.posix`

## Handlers and tags

- Handlers: none.
- Tags: `debug` on the final debug task.
