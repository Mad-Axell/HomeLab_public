# keycloak

Installs a Keycloak server from the upstream tarball on a Debian 13 LXC
(in this project 172.25.40.42, LXC 402): Java runtime, a system account, a
versioned `/opt/keycloak-<version>` tree with the `/opt/keycloak` symlink,
`conf/keycloak.conf` for an external PostgreSQL and operation behind the
Traefik reverse proxy, a systemd unit and a bootstrap administrator through
the `KC_BOOTSTRAP_ADMIN_*` environment variables. By default the role creates
its database and role in PostgreSQL itself (`keycloak_manage_database`), and
secrets are passed by variable name through `*_password_var`. The result is a
working Keycloak serving HTTP on the internal port 8080, ready to be
terminated by Traefik at `https://keycloak.dragons-nest.home.arpa`.

## What it does

- Validates the Debian platform and the required inputs (`keycloak_db_host`,
  `keycloak_hostname`, `keycloak_db_password_var`,
  `keycloak_admin_password_var`, plus `keycloak_db_admin_password_var` when
  `keycloak_manage_database` is enabled) with an early
  `ansible.builtin.assert`, then verifies the named secrets exist with a
  separate check - all before any changes.
- Installs the Java package `keycloak_java_package` (default
  `default-jre-headless`, OpenJDK 21 on Debian 13) and the packages in
  `keycloak_database_packages` (`python3-psycopg2`) needed by the
  `community.postgresql` modules on the target host.
- With `keycloak_manage_database: true` creates the PostgreSQL role
  `keycloak_db_user` (LOGIN, password from `keycloak_db_password_var`) and
  the database `keycloak_db_name` owned by `keycloak_db_user`; the
  connection is made as the privileged `keycloak_db_admin_user` account.
  Both tasks run with `no_log: true`.
- Creates the `keycloak` system group and user.
- Downloads `keycloak-<version>.tar.gz` and unpacks it into `/opt`;
  `/opt/keycloak` is a symlink to the versioned directory, so an upgrade and
  a rollback both swap a single link.
- Renders `conf/keycloak.conf`: `db=postgres`, `db-url` built from
  `keycloak_db_host`/`keycloak_db_port`/`keycloak_db_name`, `hostname`,
  `hostname-strict`, `http-enabled`, `http-port`, `proxy-headers`, plus
  `keycloak_extra_options`.
- Writes `/etc/keycloak/keycloak.env` with the secrets (`KC_DB_PASSWORD`,
  `KC_BOOTSTRAP_ADMIN_USERNAME`, `KC_BOOTSTRAP_ADMIN_PASSWORD`), mode
  `0640 root:keycloak`; the values are resolved via `lookup` from the names
  in `*_password_var`, and the task runs with `no_log: true` and
  `diff: false`.
- Installs the `keycloak.service` systemd unit (`kc.sh start --optimized`)
  and runs `kc.sh build` whenever the release or the configuration changed,
  so `--optimized` always starts on a current build.
- Starts and enables the service; restarts on configuration, environment or
  unit changes are performed by the `Restart Keycloak` handler.

## Requirements

- Target OS: Debian 13 (asserted via `ansible_facts.os_family == 'Debian'`).
- Privileges: `become: true`; the build runs as `become_user: keycloak`.
- An external PostgreSQL: in this project the `postgresql` host
  (172.25.40.151). With `keycloak_manage_database: true` (the default) the
  role creates the database and role itself as `keycloak_db_admin_user`;
  with `false` it expects them pre-created.
- `VARS/secrets.yml` loaded by the playbook through `vars_files` — the role
  does not load it itself.
- Connectivity from the target host to `keycloak_download_url` (github.com by
  default) — the tarball is downloaded on the target host.
- The secrets named by `keycloak_db_password_var`,
  `keycloak_admin_password_var` and (when managing the database)
  `keycloak_db_admin_password_var` are required and checked by early
  `ansible.builtin.assert` tasks.

## Managed resources

- Packages: the package named by `keycloak_java_package`
  (`default-jre-headless`) and `python3-psycopg2` from
  `keycloak_database_packages`.
- Files: `/tmp/keycloak-<version>.tar.gz`, `/opt/keycloak-<version>/`,
  the `/opt/keycloak` symlink, `/opt/keycloak/conf/keycloak.conf`,
  `/etc/keycloak/keycloak.env`, `/etc/systemd/system/keycloak.service`.
- Services: `keycloak.service`.
- Users/groups: `keycloak` (system, `/usr/sbin/nologin`).
- Database objects: with `keycloak_manage_database: true` the PostgreSQL role
  `keycloak_db_user` and the database `keycloak_db_name`.

## Variables

| Variable | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `keycloak_debug_mode` | boolean | no | `false` | Change summary in debug output. |
| `keycloak_java_package` | string | no | `"default-jre-headless"` | Java package; pin `openjdk-21-jre-headless` for a fixed runtime. |
| `keycloak_version` | string | no | `"26.8.2"` | Keycloak version to install. |
| `keycloak_download_url` | string | no | GitHub releases URL | URL of the release tarball. |
| `keycloak_download_checksum` | string or null | no | `null` | Tarball verification in get_url format, e.g. `"sha256:<hex>"`; `null` omits the parameter. |
| `keycloak_archive_path` | string | no | `"/tmp/keycloak-{{ keycloak_version }}.tar.gz"` | Where the tarball is stored. |
| `keycloak_release_dir` | string | no | `"/opt/keycloak-{{ keycloak_version }}"` | Internal: unpacked release directory. |
| `keycloak_install_root` | string | no | `"/opt/keycloak"` | Symlink to the active release. |
| `keycloak_system_user` | string | no | `"keycloak"` | Service system user. |
| `keycloak_system_group` | string | no | `"keycloak"` | Service primary group. |
| `keycloak_db_host` | string | yes | `null` | PostgreSQL address; no default, asserted. |
| `keycloak_db_port` | integer | no | `5432` | PostgreSQL port. |
| `keycloak_db_name` | string | no | `"keycloak"` | Keycloak database; created by the role when `keycloak_manage_database` is `true`. |
| `keycloak_db_user` | string | no | `"keycloak"` | Keycloak login; created by the role when `keycloak_manage_database` is `true`. |
| `keycloak_db_password_var` | string or null | yes | `null` | Name of the variable holding the database password in `VARS/secrets.yml`; written to `keycloak.env` as `KC_DB_PASSWORD`. |
| `keycloak_manage_database` | boolean | no | `true` | Create the database and its role before the first start; `false` expects pre-created objects. |
| `keycloak_db_admin_user` | string | no | `"postgres"` | Privileged account used only to create the database and the role. |
| `keycloak_db_admin_password_var` | string or null | in manage mode | `null` | Name of the variable holding the privileged password in `VARS/secrets.yml`; required when `keycloak_manage_database` is `true`. |
| `keycloak_database_packages` | list | no | `["python3-psycopg2"]` | Internal: packages the `community.postgresql` modules need on the target host. |
| `keycloak_hostname` | string | yes | `null` | Public base URL, e.g. `"https://keycloak.dragons-nest.home.arpa"`; asserted. |
| `keycloak_hostname_strict` | boolean | no | `true` | `hostname-strict` of hostname v2. |
| `keycloak_http_enabled` | boolean | no | `true` | HTTP listener; true behind Traefik. |
| `keycloak_http_port` | integer | no | `8080` | HTTP listener port. |
| `keycloak_proxy_headers` | string | no | `"xforwarded"` | Trusted forwarding headers from the proxy. |
| `keycloak_extra_options` | dict | no | `{}` | Extra `option=value` pairs appended to keycloak.conf. |
| `keycloak_admin_user` | string | no | `"admin"` | Bootstrap administrator name. |
| `keycloak_admin_password_var` | string or null | yes | `null` | Name of the variable holding the bootstrap administrator password in `VARS/secrets.yml`; written to `keycloak.env` as `KC_BOOTSTRAP_ADMIN_PASSWORD`. |
| `keycloak_env_file` | string | no | `"/etc/keycloak/keycloak.env"` | Secret environment file read by the unit. |
| `keycloak_service_name` | string | no | `"keycloak"` | systemd unit name. |
| `keycloak_service_state` | string | no | `"started"` | Steady service state: `started` or `stopped`. |
| `keycloak_service_enabled` | boolean | no | `true` | Start the service at boot. |

## Secrets

Secrets are not referenced by direct names but through `*_password_var`
variables pointing at keys of `VARS/secrets.yml` (the project convention,
same as `zabbix_server` and `netbox`): the secret value lives only in
secrets.yml and never lands in host_vars. The playbook loads
`VARS/secrets.yml` via `vars_files`; `defaults/main.yml` declares only the
variable names. An early `ansible.builtin.assert` checks the names are set,
and a separate `Validate the Keycloak secrets` check verifies the named
secrets exist - both before the first system change.

| Variable | Type | Required | Purpose |
| --- | --- | --- | --- |
| secret named by `keycloak_db_password_var` | string | yes | Password of `keycloak_db_user`, e.g. the `keycloak_db_password` key; written to `keycloak.env` as `KC_DB_PASSWORD`. |
| secret named by `keycloak_admin_password_var` | string | yes | Bootstrap administrator password, e.g. the `keycloak_admin_password` key; `KC_BOOTSTRAP_ADMIN_PASSWORD`. |
| secret named by `keycloak_db_admin_password_var` | string | in manage mode | Password of the privileged `keycloak_db_admin_user` account on the PostgreSQL server, e.g. the shared `db_admin_password` key. Required when `keycloak_manage_database` is `true`; used only to create the database and the role. |

`keycloak.env` is the only place the role materialises secrets; its task runs
with `no_log: true` and `diff: false`. `keycloak.conf` holds no secrets.

## Usage

```yaml
---
- name: Install Keycloak
  hosts: keycloak
  become: true
  vars_files:
    - ../VARS/secrets.yml
  roles:
    - role: keycloak
      vars:
        keycloak_db_host: "172.25.40.151"
        keycloak_db_password_var: "keycloak_db_password"
        keycloak_db_admin_password_var: "db_admin_password"
        keycloak_admin_password_var: "keycloak_admin_password"
        keycloak_hostname: "https://keycloak.dragons-nest.home.arpa"
```

## Handlers

- `Restart Keycloak` — notified by the `keycloak.conf`, `keycloak.env` and
  unit tasks.

## Tags

- `debug` — the summary debug task when `keycloak_debug_mode: true`.

## Templates

- `keycloak.conf.j2` → `/opt/keycloak/conf/keycloak.conf`
- `keycloak.service.j2` → `/etc/systemd/system/keycloak.service`
- `keycloak.env.j2` → `/etc/keycloak/keycloak.env` (secrets)

## Check mode and diff mode

The role supports `--check --diff`. Limitations:

- `kc.sh build` is an `ansible.builtin.command` task and does not run in check
  mode (it only runs after a release or configuration change anyway), so the
  build is predicted but not performed.
- The service is not started or restarted in check mode.
- `keycloak.env` never shows a diff (`diff: false`) — expected, not a
  limitation.

## Dependencies

- The `community.postgresql` collection (the `postgresql_user` and
  `postgresql_db` modules that create the database and the role); all other
  modules are `ansible.builtin`. External: a PostgreSQL server and
  `VARS/secrets.yml`.

## Notes

- **Out of scope:** creating the `dragons-nest` realm, the MFA/OTP policy and
  the Grafana OIDC client — that is phase 2 after installation (per
  `PLAN_observability.md`, the stage after Traefik).
- With `keycloak_manage_database: true` (the default) the role creates its
  database and role in PostgreSQL itself - per the project convention the
  application owns its schema. This requires the password of the privileged
  `keycloak_db_admin_user` account, named by
  `keycloak_db_admin_password_var` (for example the shared
  `db_admin_password` secret). With `keycloak_manage_database: false` the
  role expects the database and role to be already created externally.
- The bootstrap administrator via `KC_BOOTSTRAP_ADMIN_*` is created on the
  first start while the master realm has no administrator; create a permanent
  admin account in the console afterwards.
- The instance is meant to run behind Traefik: `http-enabled=true`,
  `proxy-headers=xforwarded`, and `keycloak_hostname` is the external HTTPS
  name.
- Version upgrade: bump `keycloak_version` — the new tarball downloads and
  unpacks alongside, the symlink switches, `kc.sh build` runs, and the handler
  restarts the service.
