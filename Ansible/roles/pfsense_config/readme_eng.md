# pfsense_config

This role manages a complete pfSense XML configuration as one transaction. By
default it only validates the candidate and reports drift; it does not change
the live `/conf/config.xml`.

## Transaction flow

1. Read XML from exactly one source: controller-side
   `pfsense_config_source_file`, or `pfsense_config_xml`/
   `vault_pfsense_config_xml`.
2. Validate the XML structure and configuration version.
3. Process the candidate with the native
   `pfSsh.php playback upgradeconfig` command.
4. Compare the management-interface address and block accidental changes.
5. Compare SHA-256 checksums of the live and prepared files.
6. In apply mode, save the previous configuration on both pfSense and the
   Ansible controller, install a boot watchdog, and then replace the XML.
7. Reboot pfSense and verify the new boot, XML, checksum, SSH, and WebGUI. On
   failure, restore the backup. If the node is unreachable, the boot watchdog
   performs a delayed rollback and another reboot.

Only one transaction may run at a time. A leftover watchdog blocks a new run
until the previous operation has been inspected manually.

## Main variables

| Variable | Default | Purpose |
| --- | --- | --- |
| `pfsense_config_source_file` | `""` | Path to a complete `config.xml` on the Ansible controller. |
| `pfsense_config_xml` | `vault_pfsense_config_xml` or `""` | Complete XML content. Mutually exclusive with the source file. |
| `pfsense_config_apply` | `false` | Allows the live configuration to be changed. |
| `pfsense_config_apply_confirmation` | `""` | Must be `APPLY_PFSENSE_CONFIG` for apply mode. |
| `pfsense_config_management_interface` | `lan` | Logical pfSense management interface. |
| `pfsense_config_allow_management_change` | `false` | Allows the candidate to change the management address. |
| `pfsense_config_management_change_confirmation` | `""` | Must be `CHANGE_PFSENSE_MANAGEMENT_ADDRESS` when a management change is allowed. |
| `pfsense_config_healthcheck_ports` | `[22, 443]` | TCP ports checked after reboot. |
| `pfsense_config_rollback_timeout` | `600` | Autonomous watchdog rollback delay in seconds. |
| `pfsense_config_local_backup_dir` | `~/.ansible/backups/pfsense` | Controller-side backup directory. |
| `pfsense_config_debug_mode` | `false` | Prints a result without exposing XML. |

## Running the playbook

Validate and compare without changing the live configuration:

```shell
ansible-playbook playbooks/pfsense-config.yml \
  -e pfsense_config_source_file=/secure/path/config.xml
```

Apply a validated candidate:

```shell
ansible-playbook playbooks/pfsense-config.yml \
  -e pfsense_config_source_file=/secure/path/config.xml \
  -e pfsense_config_apply=true \
  -e pfsense_config_apply_confirmation=APPLY_PFSENSE_CONFIG
```

A management-address change is a separate maintenance-window operation. In
addition to normal apply confirmation, it requires:

```shell
-e pfsense_config_allow_management_change=true \
-e pfsense_config_management_change_confirmation=CHANGE_PFSENSE_MANAGEMENT_ADDRESS
```

## Requirements and limits

- `become: true` access and Python on pfSense.
- PHP and `/usr/local/sbin/pfSsh.php` must be available on pfSense.
- XML is always handled with `no_log: true` and `diff: false`.
- The role applies a complete XML document; it does not edit firewall, DHCP, or
  VLAN objects separately.
- The first live run requires an approved full configuration and a maintenance
  window with pfSense console access.

## Check mode

A normal run is already validation-only. `--check` also never reaches the apply
block, but it creates and removes temporary candidate files on pfSense because
native format and version validation require them.
