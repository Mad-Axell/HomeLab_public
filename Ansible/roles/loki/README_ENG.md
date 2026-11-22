# loki

The role installs Grafana Loki on Debian from the official Grafana APT
repository (`apt.grafana.com`) and configures a single-binary deployment:
local filesystem storage, old log deletion by the compactor and a managed
systemd service. Debian ships no `loki` package, so the vendor repository is
the installation source.

## What it does

- Checks that the target system belongs to the Debian family.
- Installs `ca-certificates` and `python3-apt`, needed for HTTPS and
  `apt_repository`.
- Downloads the ASCII-armored Grafana signing key to
  `/etc/apt/keyrings/grafana.asc` without using `apt-key` and registers
  `deb [arch=amd64 signed-by=...] https://apt.grafana.com stable main` in
  `/etc/apt/sources.list.d/grafana.list`.
- Installs the `loki` package (the package postinstall itself creates the
  `loki` user and the `loki.service` unit and starts the service on the
  shipped configuration).
- Creates the persistent data directory `/var/lib/loki` owned by `loki`: the
  packaged configuration keeps all data in `/tmp/loki` and loses it on
  reboot.
- Fully replaces `/etc/loki/config.yml` with the role template:
  `auth_enabled: false`, filesystem storage with the `tsdb`/`v13` schema, a
  compactor with `retention_enabled` and `deletion_mode: filter-and-delete`,
  and disabled anonymous statistics reporting. The file is checked with
  `loki -verify-config` before being put in place.
- Brings the `loki` service to its steady state and applies the pending
  restart at once through `meta: flush_handlers`.

## Requirements

- Debian (target platform: Debian 13 LXC), `become: true`.
- Gathered facts: the role reads `ansible_facts.os_family`.
- Network access to `https://apt.grafana.com`.

## Managed resources

- Packages: `loki_prerequisite_packages`, `loki_packages`.
- Files: `/etc/apt/keyrings/grafana.asc`,
  `/etc/apt/sources.list.d/grafana.list`, `/etc/loki/config.yml`, the
  `loki_data_dir` directory.
- Services: `loki`.
- Users/groups: none (the `loki` user is created by the package postinstall).
- Firewall/API objects: none.

## Variables

| Variable | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `loki_repository_url` | string | no | `"https://apt.grafana.com"` | Grafana APT repository URL. |
| `loki_repository_suite` | string | no | `"stable"` | Grafana repository suite. |
| `loki_repository_component` | string | no | `"main"` | Grafana repository component. |
| `loki_repository_arch` | string | no | `"amd64"` | Pinned APT architecture. |
| `loki_repository_key_url` | string | no | `"https://apt.grafana.com/gpg-full.key"` | URL of the ASCII-armored signing key. |
| `loki_keyring_directory` | string | no | `"/etc/apt/keyrings"` | Signing key directory. |
| `loki_keyring_file` | string | no | `"grafana.asc"` | Signing key file name. |
| `loki_prerequisite_packages` | list | no | `["ca-certificates", "python3-apt"]` | Packages needed before the repository can be used. |
| `loki_packages` | list | no | `["loki"]` | Packages installed from the Grafana repository. |
| `loki_auth_enabled` | boolean | no | `false` | Tenant authentication. |
| `loki_http_listen_address` | string | no | `"0.0.0.0"` | HTTP API address. |
| `loki_http_listen_port` | integer | no | `3100` | HTTP API port. |
| `loki_grpc_listen_address` | string | no | `"0.0.0.0"` | gRPC interface address. |
| `loki_grpc_listen_port` | integer | no | `9095` | gRPC interface port. |
| `loki_log_level` | string | no | `"info"` | Server log level. |
| `loki_data_dir` | string | no | `"/var/lib/loki"` | Loki data directory. |
| `loki_retention_period` | string | no | `"744h"` | How long logs are kept (31 days). |
| `loki_config_path` | string | no | `"/etc/loki/config.yml"` | Managed configuration file. |
| `loki_service_name` | string | no | `"loki"` | systemd service name. |
| `loki_service_state` | string | no | `"started"` | Steady service state. |
| `loki_service_enabled` | boolean | no | `true` | Service boot start. |
| `loki_debug_mode` | boolean | no | `false` | Debug output after significant changes. |

## Secret external inputs

The role uses no secrets and does not read `VARS/secrets.yml`.

## Usage

```yaml
---
- name: Install Grafana Loki
  hosts: loki
  become: true
  roles:
    - role: loki
```

## Check mode and diff mode

The role supports `--check --diff` partially, and this is an APT limitation
rather than a defect:

- in check mode the repository is not actually added, so on a clean host the
  task installing `loki_packages` reports a missing candidate package; a
  meaningful `--check` requires a host where an earlier real run already
  registered the repository;
- the template `validate` command does not run in check mode;
- every other task behaves correctly in check/diff mode.

## Dependencies

- None

## Handlers and tags

- Handlers: `Restart Loki` fires when `/etc/loki/config.yml` changes.
- Tags: `debug` on the final debug task.

## Notes

- `auth_enabled: false` assumes a trusted network: any client able to reach
  port 3100 can push and read logs. Restricting access is the firewall's job,
  not this role's.
- The configuration targets a single node: `replication_factor: 1` and an
  `inmemory` ring. A cluster needs a different template.
- The package postinstall starts the service on the shipped configuration
  with `/tmp/loki`; the role replaces the configuration in the same run and
  restarts the service through the handler, so `/tmp/loki` never goes into
  real use.
