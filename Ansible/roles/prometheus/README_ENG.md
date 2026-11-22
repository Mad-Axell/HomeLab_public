# prometheus

The role installs the Prometheus server from the Debian packages and owns
`/etc/prometheus/prometheus.yml` as a whole. It is meant for the monitoring
host (`prometheus`, 172.25.40.54 in the services catalog); the exporters on the
scraped hosts are installed by the separate `node_exporter` role.

## What it does

- Installs the `prometheus` package from the Debian repository.
- Renders `/etc/prometheus/prometheus.yml` from `templates/prometheus.yml.j2`:
  a `global` section with the intervals and `scrape_configs`, which either
  renders verbatim from `prometheus_scrape_configs` or is generated - a
  `prometheus` job for the server itself (`localhost:9090`) and a `nodes` job
  whose targets are collected from the members of `prometheus_target_groups`
  by `ansible_host` (falling back to the inventory name) on
  `prometheus_node_exporter_port`.
- Manages the `prometheus` service; a configuration change triggers the
  `Reload prometheus` handler (SIGHUP via `systemctl reload`).

## Requirements

- Debian-family OS (the role targets Debian 13).
- `become: true` - package installation, writing `/etc/prometheus` and systemd
  management.
- The hosts in `prometheus_target_groups` exist in the inventory; for correct
  targets they carry `ansible_host`.
- node_exporter runs on the targets at `prometheus_node_exporter_port`
  (the `node_exporter` role).

## Managed resources

- Packages: `prometheus`.
- Files: `/etc/prometheus/prometheus.yml` (owned whole, `prometheus:prometheus`, `0640`).
- Services: `prometheus`.
- Users/groups: none (the `prometheus` account is created by the package).
- Firewall/API objects: none.

## Variables

| Variable | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `prometheus_debug_mode` | boolean | no | `false` | Show a summary after significant changes. |
| `prometheus_packages` | list | no | `["prometheus"]` | Packages to install. |
| `prometheus_config_path` | string | no | `"/etc/prometheus/prometheus.yml"` | Configuration file the role owns as a whole. |
| `prometheus_scrape_interval` | string | no | `"15s"` | Global scrape interval. |
| `prometheus_evaluation_interval` | string | no | `"15s"` | Global rule evaluation interval. |
| `prometheus_scrape_configs` | list | no | `[]` | Complete `scrape_configs` content; when empty the `prometheus` and `nodes` jobs are generated. |
| `prometheus_extra_scrape_configs` | list | no | `[]` | Extra jobs appended after the generated `prometheus`/`nodes` jobs; ignored when `prometheus_scrape_configs` is set. |
| `prometheus_target_groups` | list | no | `["all"]` | Inventory groups scanned for `nodes` job targets. |
| `prometheus_node_exporter_port` | integer | no | `9100` | node_exporter port on generated targets. |
| `prometheus_service_name` | string | no | `"prometheus"` | systemd service name. |
| `prometheus_service_state` | string | no | `"started"` | Steady service state: `started` or `stopped`. |
| `prometheus_service_enabled` | boolean | no | `true` | Start the service at boot. |

The role has no required variables without a default and no secrets. Scrape
credentials (`basic_auth`, `bearer_token`) may be passed inside
`prometheus_scrape_configs`; their values belong to the private repository's
`VARS/secrets.yml` and are substituted by the playbook rather than declared in
defaults.

## Usage

```yaml
---
- name: Install the Prometheus server
  hosts: prometheus
  become: true
  roles:
    - role: prometheus
```

With manually described scrape jobs:

```yaml
    - role: prometheus
      vars:
        prometheus_scrape_configs:
          - job_name: "nodes"
            static_configs:
              - targets: ["172.25.40.54:9100"]
```

## Check mode and diff mode

The role supports running:

```bash
ansible-playbook playbook.yml --check --diff
```

Limitation: the template task sets `diff: false`, because `scrape_configs` may
carry scrape credentials, so the content of `prometheus.yml` is not shown in
the diff - only the fact that the file changes is visible.

## Handlers

- `Reload prometheus` - `systemctl reload prometheus` (SIGHUP), triggered when
  `prometheus.yml` changes; skipped when `prometheus_service_state` is not
  `started`.

## Tags

- `debug` - the change summary when `prometheus_debug_mode: true`.

## Dependencies

- None. Only `ansible.builtin` modules are used; the `node_exporter` role
  covers the exporters on the scraped hosts.

## Notes

- The role does not touch `/etc/default/prometheus`: Debian patched the binary
  defaults (config `/etc/prometheus/prometheus.yml`, storage
  `/var/lib/prometheus/metrics2`), so the packaged `ARGS` stays empty. The web
  listen address (`0.0.0.0:9090` by default), retention and other startup flags
  are set through `ARGS` in `/etc/default/prometheus` and are outside the scope
  of this role.
- Generated targets get the standard `instance` label of the `address:port`
  form; the inventory hostname is not carried into labels.
