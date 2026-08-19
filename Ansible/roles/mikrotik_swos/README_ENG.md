# mikrotik_swos

This role compares and configures a MikroTik CSS326 switch through the unofficial SwOS HTTP protocol. Before remediating real drift, it verifies the model, exact SwOS version, and port count, creates a local binary `.swb` backup, and applies configuration in `VLANs → VLAN → Link → System` order.

## What it does

- Verifies the exact switch model, SwOS version, and port count.
- Compares desired `System`, `Link`, `VLAN`, and `VLANs` sections with the device.
- Reads state and reports predicted changes without writing in check mode.
- Saves a controller-side `.swb` file with mode `0600` before a real change.
- Applies the VLAN table, per-port VLAN settings, port state, and management settings in that order.
- Reads the switch again after applying changes and fails if drift remains.
- Requires both safety confirmations for every real run.

There is no automatic rollback. If management access is lost, recovery is physical and uses the independently stored `.swb` backup.

## Requirements

- Ansible runs on a controller with Python 3 and `mikrotik-swos==1.3.2`.
- The library is installed from the project-level `requirements-controller.txt` with hash verification.
- The controller can reach the switch over HTTP on a trusted management network; the pinned library performs HTTP Digest with the supplied username and password.
- The controller user can create files in `mikrotik_swos_backup_directory`, which resides on encrypted storage outside Git.
- Default target platform: `CSS326-24G-2S+`, SwOS `2.18`, 26 ports.
- A manual backup, tested physical recovery access, and a maintenance window are required before a real run.

## Managed resources

- Packages: none; the controller dependency is installed separately.
- Files: a binary `.swb` backup in the controller directory before real drift remediation.
- Services: none.
- Users/groups: none.
- Network objects: VLAN table, per-port VLAN settings, port enabled state, and SwOS System management settings.

## Variables

| Variable | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `mikrotik_swos_host` | string | yes | `null` | Switch IPv4 address or HTTP URL. |
| `mikrotik_swos_username` | string | no | `"admin"` | SwOS administrative user. |
| `mikrotik_swos_configuration` | dictionary | yes | `null` | Complete caller-supplied `system`, `ports`, `port_vlans`, and `vlans` configuration; real values never belong in role defaults. |
| `mikrotik_swos_expected_model` | string | no | `"CSS326-24G-2S+"` | Exact allowed model. |
| `mikrotik_swos_expected_version` | string | no | `"2.18"` | Exact allowed SwOS version. |
| `mikrotik_swos_expected_port_count` | integer | no | `26` | Exact port count. |
| `mikrotik_swos_allow_network_changes` | boolean | no | `false` | Explicitly allow a real network change. |
| `mikrotik_swos_recovery_access_confirmed` | boolean | no | `false` | Confirm tested physical recovery access. |
| `mikrotik_swos_backup_directory` | string | no | `"/var/backups/mikrotik-swos"` | Controller directory on encrypted storage outside Git for `.swb` files. |
| `mikrotik_swos_debug_mode` | boolean | no | `false` | Enable safe English debug summaries. |

The required `vault_mikrotik_swos_passwords` secret is intentionally absent from defaults. The calling project supplies a dictionary whose keys are switch inventory aliases and whose values are SwOS passwords. The role validates a non-empty value and passes the username and password to the library for HTTP Digest.

## Usage

Inventory defines `ansible_host`. Store each switch's real desired configuration outside the generic role, for example in `host_vars/<inventory_alias>.yml`; Ansible loads it automatically. The playbook explicitly loads the project-level secrets file:

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

A real run additionally requires both flags:

```bash
ansible-playbook -i hosts.yml playbooks/network/mikrotik_swos.yml \
  --limit MgmtLanSwitch \
  -e mikrotik_swos_allow_network_changes=true \
  -e mikrotik_swos_recovery_access_confirmed=true
```

## Check mode and diff mode

In `--check`, the role performs HTTP reads and validation but does not create a backup or send POST requests. Because HTTP authentication is sensitive, the task always uses `no_log: true` and `diff: false`; only a safe predicted-change summary can be displayed.

## Security

- The role contains no password and never loads a secrets file itself.
- The calling project controls storage of the external `vault_mikrotik_swos_passwords`; the secret must not appear in inventory, host vars, role defaults, or task output.
- The backup is created before the first POST request, and a backup failure stops the change.
- Both gate flags default to `false`.
- HTTP must be restricted to an isolated management network.

## Tags

- `debug` — safe summaries after an actual or predicted change.

## Dependencies

- `mikrotik-swos==1.3.2` on the Ansible controller.
- `requests>=2.25.0` as the library runtime dependency.
- Role-local `library/mikrotik_swos_config.py` module.
