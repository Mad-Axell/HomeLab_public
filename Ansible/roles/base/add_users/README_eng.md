# add_users

This role manages local Linux accounts, supplementary groups, and `sudo` membership. It does not configure PAM, password policy, or SSH.

## What it does

- Creates explicitly declared groups and groups referenced by users.
- Creates or updates local accounts and their home directories.
- Installs `sudo` and adds only users with `sudo: true` to its group.

## Requirements

- A Linux target with an available package manager.
- `become: true` privileges.
- Password hashes stored in external `VARS/secrets.yml` variables named `vault_add_users_<name>_password_hash`.

## Managed resources

- Packages: `sudo`, only when privileged users are declared.
- Files: managed users' home directories.
- Services: none.
- Users/groups: local users, supplementary groups, and the `sudo` group.
- Firewall/API objects: none.

## Variables

| Variable | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `add_users_debug_mode` | boolean | no | `false` | Enables a concise debug message after changes. |
| `add_users_create_home` | boolean | no | `true` | Default `create_home` value. |
| `add_users_default_shell` | string | no | `"/bin/bash"` | Default login shell. |
| `add_users_home_prefix` | string | no | `"/home"` | Parent directory for home directories. |
| `add_users_home_mode` | string | no | `"0750"` | Home-directory permissions. |
| `add_users_groups` | list | no | `[]` | Supplementary groups to create. |
| `add_users_users` | list | no | `[]` | List of dictionaries with `name`; supports `groups`, `sudo`, `shell`, `home`, `create_home`, `uid`, `comment`, `password_hash_var`. |
| `vault_add_users_<name>_password_hash` | string | conditional | - | External password hash from `VARS/secrets.yml`, required if referenced by `password_hash_var`. |

## Usage

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

## Check mode and diff mode

Most tasks support `--check --diff`. Tasks that use password hashes have `no_log: true` and `diff: false`, so password values and diffs are not displayed.

## Dependencies

- None

## Notes

- The role validates account names and referenced secrets before making changes.
- Supply password hashes, never plaintext passwords, in `add_users_users`.
