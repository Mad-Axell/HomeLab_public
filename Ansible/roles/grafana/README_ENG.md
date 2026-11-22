# grafana

This role installs Grafana on a Debian host from the official
`apt.grafana.com` APT repository, renders `/etc/grafana/grafana.ini` from a
template (HTTP port, domain/root_url, built-in administrator, database
connection), provisions datasources and dashboards declaratively, and
installs plugins via `grafana-cli`. By default Grafana runs on an external
PostgreSQL instance and the role creates its database and role there itself
(`grafana_database_manage`); the embedded sqlite3 backend is selected via
`grafana_database_type`. Passwords come from external secrets referenced by
variable name; SSO via Keycloak is a deliberate later phase and is not part
of this role.

## What it does

- Validates the Debian platform, the structure of the input lists and the
  secret variable names (`grafana_admin_password_var`, plus
  `grafana_database_host` and `grafana_database_password_var` in postgres
  mode, and `grafana_database_admin_password_var` when
  `grafana_database_manage` is enabled) with an early
  `ansible.builtin.assert`, then verifies the named secrets exist with a
  separate check - all before any changes.
- Downloads the armored signing key into `/etc/apt/keyrings/grafana.asc` and
  registers the repository
  `deb [arch=amd64 signed-by=...] https://apt.grafana.com stable main`.
- Installs the `grafana` package and, when `grafana_database_type` is
  `"postgres"`, the packages in `grafana_database_packages`
  (`python3-psycopg2`) needed by the `community.postgresql` modules on the
  target host.
- With `grafana_database_type: "postgres"` and
  `grafana_database_manage: true` creates the PostgreSQL role
  `grafana_database_user` (LOGIN, password from
  `grafana_database_password_var`) and the database
  `grafana_database_name` owned by `grafana_database_user`; the connection
  is made as the privileged `grafana_database_admin_user` account. Both
  tasks run with `no_log: true`.
- Renders `grafana.ini` from a template, including the `[database]` section
  when `grafana_database_type` is `"postgres"`. The file carries passwords,
  so the task uses `no_log: true` and `diff: false`.
- Renders `/etc/grafana/provisioning/datasources/datasources.yaml` from the
  `grafana_datasources` list and the provider
  `/etc/grafana/provisioning/dashboards/dashboards.yaml` pointing at
  `grafana_dashboards_path`.
- Copies the dashboard JSON files listed in `grafana_dashboards` into
  `grafana_dashboards_path`; the provider rescans the directory on its
  interval, without a restart.
- Installs the plugins in `grafana_plugins` (default
  `alexanderzobnin-zabbix-app`) via `grafana-cli plugins install`, but only
  those missing from `grafana-cli plugins ls` - which makes the installation
  idempotent.
- Manages the `grafana-server` service; configuration changes and plugin
  installations restart it through a handler.

## Requirements

- Debian (the project's target platform is Debian 13, LXC); `become: true`.
- Outbound HTTPS access to `apt.grafana.com`.
- With `grafana_database_type: "postgres"`: a network-reachable PostgreSQL.
  With `grafana_database_manage: true` (the default) the role creates the
  database and role itself as `grafana_database_admin_user`; with `false`
  it expects them pre-created (see "Notes").
- Secrets from `VARS/secrets.yml` named by `grafana_admin_password_var` and
  `grafana_database_password_var` (plus `grafana_database_admin_password_var`
  when managing the database), wired in by the playbook (see "Secrets").

## Managed resources

- Packages: `ca-certificates`, `python3-apt`, the packages in
  `grafana_packages` (`grafana`) and, for the postgres backend,
  `python3-psycopg2` from `grafana_database_packages`.
- Files: `/etc/apt/keyrings/grafana.asc`,
  `/etc/apt/sources.list.d/grafana.list`, `/etc/grafana/grafana.ini`,
  `/etc/grafana/provisioning/datasources/datasources.yaml`,
  `/etc/grafana/provisioning/dashboards/dashboards.yaml`, the
  `/var/lib/grafana/dashboards` directory and the dashboard JSON files in it,
  plugins under `/var/lib/grafana/plugins`.
- Services: `grafana-server`.
- Database objects: with `grafana_database_manage: true` the PostgreSQL role
  `grafana_database_user` and the database `grafana_database_name`.
- Users/groups, firewall/API objects: not managed. Access to
  `grafana_http_port` is configured by a separate firewall role.

## Variables

| Variable | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `grafana_debug_mode` | boolean | no | `false` | Enable a debug summary after significant changes. |
| `grafana_repository_url` | string | no | `"https://apt.grafana.com"` | Grafana APT repository URL. |
| `grafana_repository_key_url` | string | no | `"https://apt.grafana.com/gpg.key"` | Armored signing-key URL. |
| `grafana_repository_keyring` | string | no | `"/etc/apt/keyrings/grafana.asc"` | Local path of the signing key (the `.asc` extension is required for an armored key). |
| `grafana_repository_filename` | string | no | `"grafana"` | Source filename under `/etc/apt/sources.list.d`. |
| `grafana_repository_suite` | string | no | `"stable"` | Repository suite. |
| `grafana_repository_component` | string | no | `"main"` | Repository component. |
| `grafana_apt_architecture` | string | no | `"amd64"` | APT architecture of the packages. |
| `grafana_packages` | list | no | `["grafana"]` | Packages to install. |
| `grafana_config_path` | string | no | `"/etc/grafana/grafana.ini"` | Path of the main configuration file. |
| `grafana_http_port` | integer | no | `3000` | HTTP port Grafana listens on. |
| `grafana_domain` | string | no | `"localhost"` | Public domain name of the instance (`domain` in grafana.ini). |
| `grafana_root_url` | string or null | no | `null` | Full root URL used in generated links; `null` lets Grafana derive it from protocol/domain/http_port. |
| `grafana_admin_user` | string | no | `"admin"` | Login of the built-in administrator. |
| `grafana_admin_password_var` | string or null | yes | `null` | Name of the variable holding the admin password in `VARS/secrets.yml`; referenced by name so the value stays out of host_vars. |
| `grafana_database_type` | string | no | `"postgres"` | Database backend: `"postgres"` or `"sqlite3"`. |
| `grafana_database_host` | string or null | in postgres mode | `null` | PostgreSQL host; asserted when `grafana_database_type` is `"postgres"`. |
| `grafana_database_port` | integer | no | `5432` | PostgreSQL port. |
| `grafana_database_name` | string | no | `"grafana"` | Database name Grafana connects to. |
| `grafana_database_user` | string | no | `"grafana"` | Database login. |
| `grafana_database_password_var` | string or null | in postgres mode | `null` | Name of the variable holding the database password in `VARS/secrets.yml`; required when `grafana_database_type` is `"postgres"`. |
| `grafana_database_manage` | boolean | no | `true` | Create the database and its role before the first start; `false` expects pre-created objects. |
| `grafana_database_admin_user` | string | no | `"postgres"` | Privileged account used only to create the database and the role. |
| `grafana_database_admin_password_var` | string or null | in postgres+manage mode | `null` | Name of the variable holding the privileged password in `VARS/secrets.yml`; required when `grafana_database_type` is `"postgres"` and `grafana_database_manage` is `true`. |
| `grafana_database_packages` | list | no | `["python3-psycopg2"]` | Internal: packages the `community.postgresql` modules need on the target host. |
| `grafana_datasources_config_path` | string | no | `"/etc/grafana/provisioning/datasources/datasources.yaml"` | Path of the datasource provisioning file. |
| `grafana_datasources` | list | no | `[]` | Datasources: each entry requires `name`, `type`, `url`; optional `access` (default `"proxy"`) and `is_default` (default `false`). |
| `grafana_dashboards_provider_path` | string | no | `"/etc/grafana/provisioning/dashboards/dashboards.yaml"` | Path of the dashboards provider file. |
| `grafana_dashboards_path` | string | no | `"/var/lib/grafana/dashboards"` | Directory scanned by the provider. |
| `grafana_dashboards` | list | no | `[]` | Dashboard JSON files; relative names are resolved in the role's `files/` directory. |
| `grafana_homepath` | string | no | `"/usr/share/grafana"` | Grafana installation home; the working directory the grafana-cli commands run in. |
| `grafana_plugins_path` | string | no | `"/var/lib/grafana/plugins"` | Plugin directory; the role creates it before `grafana-cli plugins ls`, which fails without it. |
| `grafana_plugins` | list | no | `["alexanderzobnin-zabbix-app"]` | Plugin IDs for `grafana-cli plugins install`. |
| `grafana_service_name` | string | no | `"grafana-server"` | systemd unit name. |
| `grafana_service_state` | string | no | `"started"` | Stable service state (`started`/`stopped`). |
| `grafana_service_enabled` | boolean | no | `true` | Enable the service at boot. |

## Secrets

Secrets are not referenced by direct names but through `*_password_var`
variables pointing at keys of `VARS/secrets.yml` (the project convention,
same as `zabbix_server` and `netbox`): the secret value lives only in
secrets.yml and never lands in host_vars. The playbook loads
`VARS/secrets.yml` via `vars_files`.

| Variable | Type | Required | Description |
| --- | --- | --- | --- |
| secret named by `grafana_admin_password_var` | string | yes | Password of the built-in administrator, e.g. the `grafana_admin_password` key. Checked by the early `assert`; the role fails before making changes if the variable does not exist. |
| secret named by `grafana_database_password_var` | string | in postgres mode | PostgreSQL connection password, e.g. the `grafana_db_password` key. Required when `grafana_database_type` is `"postgres"`. |
| secret named by `grafana_database_admin_password_var` | string | in postgres+manage mode | Password of the privileged `grafana_database_admin_user` account on the PostgreSQL server, e.g. the shared `db_admin_password` key. Required when `grafana_database_type` is `"postgres"` and `grafana_database_manage` is `true`; used only to create the database and the role. |

The task that renders `grafana.ini` uses `no_log: true` and `diff: false`:
the secrets land only in the file on the target host and are never shown in
the output or the diff. The admin password is applied once, when Grafana
creates the admin account on first start (the file is written before the
first service start). Changing the password of an existing administrator is
not performed by the role; do it manually with
`grafana-cli admin reset-admin-password` or through the UI/API.

## Handlers

- `Restart Grafana server` - `systemd restart grafana-server`. Triggered when
  `grafana.ini`, the provisioning files (`datasources.yaml`,
  `dashboards.yaml`) or the plugin set change. Dashboard JSON copies do not
  notify it: the provider rescans its directory every
  `updateIntervalSeconds`.

## Usage

```yaml
---
- name: Configure Grafana
  hosts: grafana
  become: true
  vars_files:
    - "../VARS/secrets.yml"
  roles:
    - role: grafana
      vars:
        grafana_admin_password_var: "grafana_admin_password"
        grafana_database_host: "postgresql.example.internal"
        grafana_database_password_var: "grafana_db_password"
        grafana_database_admin_password_var: "db_admin_password"
        grafana_domain: "grafana.example.internal"
        grafana_root_url: "http://grafana.example.internal:3000/"
        grafana_datasources:
          - name: "Prometheus"
            type: "prometheus"
            url: "http://prometheus.example.internal:9090"
            is_default: true
          - name: "Loki"
            type: "loki"
            url: "http://loki.example.internal:3100"
          - name: "Zabbix"
            type: "alexanderzobnin-zabbix-datasource"
            url: "http://zabbix.example.internal/api_jsonrpc.php"
```

## Check mode and diff mode

The role supports `--check --diff` with the following limitations:

- `diff` is disabled for `grafana.ini` (`diff: false`) because the file
  contains a secret.
- On a first `--check` run the `grafana` package installation is skipped: a
  forecast repository cannot be indexed by APT. Once the repository exists,
  the package check runs normally.
- `grafana-cli plugins ls` also runs in check mode (`check_mode: false`,
  read-only), but only when the binary already exists. Plugin installation -
  an `ansible.builtin.command` task - is skipped in check mode by Ansible
  itself.
- `--tags debug` and `--skip-tags debug` are safe: the summary checks
  `result is defined` for every register.

## Dependencies

- The `community.postgresql` collection (the `postgresql_user` and
  `postgresql_db` modules that create the database and the role); all other
  modules are `ansible.builtin`.

## Notes

- With `grafana_database_manage: true` (the default) the role creates its
  database and role in PostgreSQL itself - per the project convention the
  application owns its schema. This requires the password of the privileged
  `grafana_database_admin_user` account, named by
  `grafana_database_admin_password_var` (for example the shared
  `db_admin_password` secret). With `grafana_database_manage: false` the
  role expects the database and role to be already created externally.
- Switching an existing instance from sqlite3 to PostgreSQL does not migrate
  data: after changing `grafana_database_type` Grafana starts with an empty
  database and applies its schema itself; content migration is a manual
  operation outside the role.
- The repository key is stored as an armored `.asc`: APT accepts an armored
  keyring via `signed-by` only under the `.asc` extension, so no separate
  `gpg --dearmor` step is needed - the same approach as the `docker` and
  `yandex_disk` roles.
- SSO/OIDC via Keycloak is a planned second phase; this role intentionally
  configures only a local administrator.
- `grafana_datasources` is empty by default: the concrete Prometheus, Loki
  and Zabbix addresses are private-repository values.
- Dashboard JSON files for `grafana_dashboards` go into this role's `files/`
  directory; absolute paths in the list are copied as given.
