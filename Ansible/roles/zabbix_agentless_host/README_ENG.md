# zabbix_agentless_host

Registers a host object on the Zabbix server for devices that cannot run an
agent. All work happens through the Zabbix API delegated to localhost; nothing
is installed on the device itself.

Use it for appliances such as Home Assistant OS, where the guest takes no SSH,
no agent and no SNMP. The created interface is type `agent` with nothing
listening behind it: its only job is to carry the IP address so that
server-side simple checks (ICMP ping, `net.tcp.service` probes, web
scenarios) have something to bind to.

## What it does

- Asserts `zabbix_agentless_host_api_url`,
  `zabbix_agentless_host_api_password_var` and at least one group.
- Asserts the variable named by `zabbix_agentless_host_api_password_var`
  exists (the value is never logged).
- Creates each group in `zabbix_agentless_host_groups` if missing (throttled).
- Registers/updates the host with the given groups, templates, description,
  status and optional macros, plus one `agent`-type interface pointing at the
  resolved address.
- Prints a short debug summary when `zabbix_agentless_host_debug_mode` is on.

## Variables

| Variable | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `zabbix_agentless_host_debug_mode` | bool | no | `false` | Debug output. |
| `zabbix_agentless_host_api_url` | string | yes | `null` | Zabbix frontend base URL. |
| `zabbix_agentless_host_api_user` | string | no | `"Admin"` | API login. |
| `zabbix_agentless_host_api_password_var` | string | yes | `null` | Name of the variable holding the API password (resolved via `vars` lookup, never logged). |
| `zabbix_agentless_host_name` | string | no | `inventory_hostname` | Host object name on the server. |
| `zabbix_agentless_host_address` | string | no | target `ansible_host` | Address the server probes; defaults to the target record's `ansible_host` or the running host's. |
| `zabbix_agentless_host_target_host` | string | no | `null` | Inventory record the object describes; `null` = `inventory_hostname`. |
| `zabbix_agentless_host_groups` | list | yes | `[]` | Host groups; created when missing. |
| `zabbix_agentless_host_templates` | list | no | `[]` | Linked template names (must match the server). |
| `zabbix_agentless_host_macros` | list | no | `[]` | `{macro, value}` dicts; values ending in `_var` are resolved as variable names. |
| `zabbix_agentless_host_description` | string | no | `""` | Host description. |
| `zabbix_agentless_host_status` | bool | no | `true` | `false` creates the host disabled. |

## Example

```yaml
- name: Register Home Assistant as an agentless host
  hosts: localhost
  gather_facts: false
  vars_files:
    - ../VARS/secrets.yml
  roles:
    - role: zabbix_agentless_host
      vars:
        zabbix_agentless_host_api_url: "http://zabbix.example"
        zabbix_agentless_host_api_password_var: "zabbix_api_password"
        zabbix_agentless_host_target_host: homeassistant
        zabbix_agentless_host_name: homeassistant
        zabbix_agentless_host_groups:
          - "Smart home"
        zabbix_agentless_host_templates:
          - "ICMP Ping"
```

## Handlers and tags

No handlers. The summary task carries the `debug` tag.

## Check mode

The `community.zabbix` modules run unchanged in check mode; treat the role as
not check-mode safe.
