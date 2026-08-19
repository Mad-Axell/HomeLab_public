# install_packages

This role brings a list of system packages to `present` or `absent` through the target operating system's package manager.

## What it does

- Validates that the package list and requested state were explicitly supplied.
- Installs or removes the declared packages.

## Requirements

- Linux with an Ansible-supported package manager.
- `become: true` to change system packages.

## Managed resources

- Packages: packages in `install_packages_names`.
- Files: none.
- Services: none.
- Users/groups: none.
- Firewall/API objects: none.

## Variables

| Variable | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `install_packages_debug_mode` | boolean | no | `false` | Reports whether the package list changed. |
| `install_packages_names` | list | yes | `null` | Non-empty list of package names. |
| `install_packages_state` | string | no | `"present"` | `present` to install or `absent` to remove. |

## Usage

```yaml
---
- name: Install base utilities
  hosts: linux
  become: true
  roles:
    - role: base/install_packages
      vars:
        install_packages_names:
          - "curl"
          - "htop"
```

## Check mode and diff mode

The task uses `ansible.builtin.package` and supports `--check --diff` within the target package manager's capabilities.

## Dependencies

- None
