# promtail

The role installs Promtail on Debian from the official Grafana APT repository
(`apt.grafana.com`) and configures it as a log collection agent: the systemd
journal and the `/var/log/*.log` files are pushed to Loki through the push
API. Debian ships no `promtail` package, so the vendor repository is the
installation source.

Promtail is deprecated upstream in favor of Grafana Alloy (Grafana declared
it EOL in March 2026), but it remains the simple classic Loki agent. The
project deliberately keeps promtail as the chosen log shipping mechanism;
moving to Alloy is a separate architectural decision.

## What it does

- Checks the Debian platform and the required `promtail_loki_url` before any
  change.
- Installs `ca-certificates` and `python3-apt`.
- Downloads the ASCII-armored Grafana signing key to
  `/etc/apt/keyrings/grafana.asc` without `apt-key` and registers
  `deb [arch=amd64 signed-by=...] https://apt.grafana.com stable main` in
  `/etc/apt/sources.list.d/grafana.list`.
- Installs the `promtail` package (the postinstall creates the `promtail`
  user and the `promtail.service` unit).
- Creates the `/var/log/journal` directory owned `root:systemd-journal` with
  mode `2755` when missing, and the `/var/lib/promtail` state directory owned
  by `promtail` for the positions file.
- Adds the `promtail` user to the `adm` and `systemd-journal` groups: without
  them the agent can read neither the `/var/log` files nor the journal. The
  package grants none of this itself.
- Fully replaces `/etc/promtail/config.yml` with the role template: a
  positions file, `clients.url` from `promtail_loki_url`, a `journal` job for
  `/var/log/journal` with a `__journal__systemd_unit` -> `unit` relabel and a
  static `varlogs` job for `/var/log/*.log`. The file is checked with
  `promtail -check-syntax` before being put in place.
- Brings the `promtail` service to its steady state and applies the pending
  restart at once through `meta: flush_handlers` — the new group membership
  only takes effect after a process restart.

## Requirements

- Debian (target platform: Debian 13), `become: true`.
- Gathered facts: `ansible_facts.os_family`, `ansible_facts.nodename`.
- Network access to `https://apt.grafana.com` and to the endpoint given in
  `promtail_loki_url`.

## Managed resources

- Packages: `promtail_prerequisite_packages`, `promtail_packages`.
- Files: `/etc/apt/keyrings/grafana.asc`,
  `/etc/apt/sources.list.d/grafana.list`, `/etc/promtail/config.yml`, the
  `/var/log/journal` and `dirname promtail_positions_file` directories.
- Services: `promtail`.
- Users/groups: the `adm` and `systemd-journal` supplementary groups on the
  `promtail` user (the user itself is created by the package postinstall).
- Firewall/API objects: none.

## Variables

| Variable | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `promtail_loki_url` | string | yes | `null` | Loki push API endpoint, e.g. `http://loki.example.invalid:3100/loki/api/v1/push`. |
| `promtail_repository_url` | string | no | `"https://apt.grafana.com"` | Grafana APT repository URL. |
| `promtail_repository_suite` | string | no | `"stable"` | Grafana repository suite. |
| `promtail_repository_component` | string | no | `"main"` | Grafana repository component. |
| `promtail_repository_arch` | string | no | `"amd64"` | Pinned APT architecture. |
| `promtail_repository_key_url` | string | no | `"https://apt.grafana.com/gpg-full.key"` | URL of the ASCII-armored signing key. |
| `promtail_keyring_directory` | string | no | `"/etc/apt/keyrings"` | Signing key directory. |
| `promtail_keyring_file` | string | no | `"grafana.asc"` | Signing key file name. |
| `promtail_prerequisite_packages` | list | no | `["ca-certificates", "python3-apt"]` | Packages needed before the repository can be used. |
| `promtail_packages` | list | no | `["promtail"]` | Packages installed from the Grafana repository. |
| `promtail_http_listen_address` | string | no | `"0.0.0.0"` | Agent metrics endpoint address. |
| `promtail_http_listen_port` | integer | no | `9080` | Agent metrics endpoint port. |
| `promtail_grpc_listen_address` | string | no | `"0.0.0.0"` | gRPC interface address. |
| `promtail_grpc_listen_port` | integer | no | `0` | gRPC interface port; `0` disables it. |
| `promtail_positions_file` | string | no | `"/var/lib/promtail/positions.yaml"` | File recording read positions. |
| `promtail_journal_path` | string | no | `"/var/log/journal"` | journald files directory. |
| `promtail_journal_max_age` | string | no | `"12h"` | How far back the journal is first read. |
| `promtail_varlog_path` | string | no | `"/var/log/*.log"` | Glob matched by the varlogs job. |
| `promtail_instance_label` | string | no | `"{{ ansible_facts.nodename }}"` | `instance` label value on every stream. |
| `promtail_extra_scrape_configs` | list | no | `[]` | Extra `scrape_configs` entries appended verbatim. |
| `promtail_service_user` | string | no | `"promtail"` | Service account created by the package. |
| `promtail_user_groups` | list | no | `["adm", "systemd-journal"]` | Supplementary groups for reading the sources. |
| `promtail_config_path` | string | no | `"/etc/promtail/config.yml"` | Managed configuration file. |
| `promtail_service_name` | string | no | `"promtail"` | systemd service name. |
| `promtail_service_state` | string | no | `"started"` | Steady service state. |
| `promtail_service_enabled` | boolean | no | `true` | Service boot start. |
| `promtail_debug_mode` | boolean | no | `false` | Debug output after significant changes. |

## Secret external inputs

The role uses no secrets and does not read `VARS/secrets.yml`. The Loki URL
is a non-secret required input.

## Usage

```yaml
---
- name: Install Promtail
  hosts: all
  become: true
  roles:
    - role: promtail
      vars:
        promtail_loki_url: "http://loki.example.invalid:3100/loki/api/v1/push"
```

With an extra log file on a specific host:

```yaml
promtail_extra_scrape_configs:
  - job_name: app
    static_configs:
      - targets:
          - localhost
        labels:
          job: app
          instance: "{{ ansible_facts.nodename }}"
          __path__: "/var/log/app/app.log"
```

## Check mode and diff mode

The role supports `--check --diff` partially, and this is an APT limitation
rather than a defect:

- in check mode the repository is not actually added, so on a clean host the
  task installing `promtail_packages` reports a missing candidate package; a
  meaningful `--check` requires a host where an earlier real run already
  registered the repository;
- the template `validate` command does not run in check mode;
- every other task behaves correctly in check/diff mode.

## Dependencies

- None

## Handlers and tags

- Handlers: `Restart Promtail` fires when `/etc/promtail/config.yml` changes
  and when the `promtail` user's groups change.
- Tags: `debug` on the final debug task.

## Notes

- On a host with a volatile journal (`Storage=volatile`/auto without
  `/var/log/journal`) the `journal` job returns nothing until
  `systemd-journald` is restarted; Debian keeps a persistent journal by
  default, so a stock install is unaffected. For a volatile journal set
  `promtail_journal_path: "/run/log/journal"`.
- The package postinstall enables and restarts the service on the shipped
  configuration; the role replaces it in the same run and restarts the
  service through the handler.
