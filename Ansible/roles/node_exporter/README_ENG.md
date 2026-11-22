# node_exporter

The role installs `prometheus-node-exporter` from the Debian packages on any
monitored host and manages its arguments through
`/etc/default/prometheus-node-exporter`. It is the `zabbix_agent` counterpart
for the Prometheus stack: the server configured by the `prometheus` role
scrapes the `/metrics` endpoint on port 9100.

## What it does

- Installs the `prometheus-node-exporter` package from the Debian repository.
- Renders `/etc/default/prometheus-node-exporter` - the `$ARGS` environment
  file the packaged unit expands into `ExecStart` - from
  `templates/prometheus-node-exporter.j2` with the `--web.listen-address` flag
  built from `node_exporter_listen_address`/`node_exporter_listen_port` and the
  extra flags of `node_exporter_extra_args`.
- Manages the `prometheus-node-exporter` service; an argument change triggers
  the `Restart node exporter` handler.

## Requirements

- Debian-family OS (the role targets Debian 13).
- `become: true` - package installation, writing `/etc/default` and systemd
  management.

## Managed resources

- Packages: `prometheus-node-exporter`.
- Files: `/etc/default/prometheus-node-exporter`.
- Services: `prometheus-node-exporter`.
- Users/groups: none.
- Firewall/API objects: none.

## Variables

| Variable | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `node_exporter_debug_mode` | boolean | no | `false` | Show a summary after significant changes. |
| `node_exporter_packages` | list | no | `["prometheus-node-exporter"]` | Packages to install. |
| `node_exporter_defaults_path` | string | no | `"/etc/default/prometheus-node-exporter"` | `$ARGS` environment file the role owns as a whole. |
| `node_exporter_listen_address` | string | no | `"0.0.0.0"` | Listen address of the `/metrics` endpoint. |
| `node_exporter_listen_port` | integer | no | `9100` | TCP port of the `/metrics` endpoint. |
| `node_exporter_extra_args` | list | no | `[]` | Extra flags appended to `ARGS` (for example `--collector.systemd`). |
| `node_exporter_service_name` | string | no | `"prometheus-node-exporter"` | systemd service name. |
| `node_exporter_service_state` | string | no | `"started"` | Steady service state: `started` or `stopped`. |
| `node_exporter_service_enabled` | boolean | no | `true` | Start the service at boot. |

The role has no required variables without a default and no secrets.

## Usage

```yaml
---
- name: Install node_exporter on monitored hosts
  hosts: all
  become: true
  roles:
    - role: node_exporter
```

With a non-default port and extra collectors:

```yaml
    - role: node_exporter
      vars:
        node_exporter_listen_port: 19100
        node_exporter_extra_args:
          - "--collector.systemd"
```

## Check mode and diff mode

The role fully supports running:

```bash
ansible-playbook playbook.yml --check --diff
```

`/etc/default/prometheus-node-exporter` carries no secrets, so the file diff is
shown normally.

## Handlers

- `Restart node exporter` - restarts the service; `ARGS` is read at process
  start only, so there is no reload. Skipped when
  `node_exporter_service_state` is not `started`.

## Tags

- `debug` - the change summary when `node_exporter_debug_mode: true`.

## Dependencies

- None. Only `ansible.builtin` modules are used.

## Notes

- Network access from the Prometheus server to `node_exporter_listen_port` is
  outside the scope of this role (firewall rules are managed separately).
- `0.0.0.0` listens on every IPv4 interface; set
  `node_exporter_listen_address` to bind a specific one.
