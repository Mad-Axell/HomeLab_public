# netbox_seed

This role applies NetBox objects described in variables through the REST API. It
does not reason about topology: every element of a `netbox_seed_*` list is a
ready-made `data` dict for the matching module of the `netbox.netbox` collection.
The role only validates access, applies objects in dependency order, and handles
primary IPs in a second pass after the addresses exist.

## What it does

Validates the API URL and token, then applies in order: RIRs → sites → racks →
manufacturers → device roles and IPAM roles → device types → VLAN groups and
VLANs → cluster types and clusters → prefixes → devices → virtual machines →
device and VM interfaces → MAC addresses → IP addresses → primary IPs of devices and VMs.

## Requirements

- A reachable NetBox REST API (the role calls `netbox_seed_api_url` from the host
  the play runs on).
- The `netbox.netbox` collection and the `pynetbox` package in the interpreter
  Ansible executes modules with on that host.
- A write-enabled v2 API token (`nbt_<key>.<plaintext>`) — created by the
  `netbox` role when `netbox_api_token_var` is set.

## Managed resources

- NetBox objects listed in the `netbox_seed_*` lists; every object gets
  `netbox_seed_state` (`present` or `absent`).
- `netbox.netbox` does not delete objects absent from the lists: the role
  guarantees the declared state, it does not mirror the catalogue.

## Variables

| Variable | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `netbox_seed_debug_mode` | boolean | no | `false` | Object-count summary. |
| `netbox_seed_api_url` | string | yes | `null` | NetBox base URL, e.g. `http://172.25.40.15`. |
| `netbox_seed_api_token_var` | string | yes | `null` | Name of the variable holding the `nbt_<key>.<plaintext>` token. |
| `netbox_seed_validate_certs` | boolean | no | `true` | TLS certificate validation for https URLs. |
| `netbox_seed_state` | string | no | `present` | `present` or `absent` for all objects. |
| `netbox_seed_rirs` | list | no | `[]` | `data` for `netbox_rir`. |
| `netbox_seed_sites` | list | no | `[]` | `data` for `netbox_site`. |
| `netbox_seed_racks` | list | no | `[]` | `data` for `netbox_rack`. |
| `netbox_seed_manufacturers` | list | no | `[]` | `data` for `netbox_manufacturer`. |
| `netbox_seed_device_roles` | list | no | `[]` | `data` for `netbox_device_role`. |
| `netbox_seed_ipam_roles` | list | no | `[]` | `data` for `netbox_ipam_role`. |
| `netbox_seed_device_types` | list | no | `[]` | `data` for `netbox_device_type`. |
| `netbox_seed_vlan_groups` | list | no | `[]` | `data` for `netbox_vlan_group`. |
| `netbox_seed_vlans` | list | no | `[]` | `data` for `netbox_vlan`. |
| `netbox_seed_cluster_types` | list | no | `[]` | `data` for `netbox_cluster_type`. |
| `netbox_seed_clusters` | list | no | `[]` | `data` for `netbox_cluster`. |
| `netbox_seed_prefixes` | list | no | `[]` | `data` for `netbox_prefix`. |
| `netbox_seed_devices` | list | no | `[]` | `data` for `netbox_device`. `primary_ip4` is applied in a second pass after the addresses exist. |
| `netbox_seed_virtual_machines` | list | no | `[]` | `data` for `netbox_virtual_machine`. `primary_ip4` same as devices. |
| `netbox_seed_device_interfaces` | list | no | `[]` | `data` for `netbox_device_interface`. |
| `netbox_seed_vm_interfaces` | list | no | `[]` | `data` for `netbox_vm_interface`. |
| `netbox_seed_mac_addresses` | list | no | `[]` | `data` for `netbox_mac_address`; each item needs `mac_address` and `assigned_object` pointing at an existing interface. |
| `netbox_seed_ip_addresses` | list | no | `[]` | `data` for `netbox_ip_address`. |

## Usage

```yaml
---
- name: Seed NetBox from the network registry
  hosts: localhost
  gather_facts: false
  vars_files:
    - ../VARS/secrets.yml
  roles:
    - role: netbox_seed
      vars:
        netbox_seed_api_url: "http://172.25.40.15"
        netbox_seed_api_token_var: netbox_api_token
```

## Check mode and diff mode

`netbox.netbox` modules support `--check` and show a `diff` of object changes. A
first `--check` run is valid: objects to be created are reported as planned.
Limitation: `primary_ip4` is only forecast on the second pass and may not
resolve for addresses not yet created.

## Dependencies

- `netbox.netbox` collection (in the private repository's `requirements.yml`).
- `pynetbox` package in the Ansible interpreter on the executing host.
