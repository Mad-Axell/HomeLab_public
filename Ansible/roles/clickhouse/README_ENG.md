# clickhouse

The role installs the ClickHouse analytic database on LXC `172.25.40.152`.
Debian 13 carries no clickhouse packages, so the official vendor APT
repository `packages.clickhouse.com/deb` is used - the supported upstream
path, same as grafana/promtail in this project.

Configuration lives only in drop-ins: `config.d/90-ansible.xml` for network
and other settings, `users.d/90-ansible.xml` for accounts. The packaged
`config.xml`/`users.xml` stay untouched.

## What it does

- Validates the Debian platform, listen hosts, ports and types before any
  change.
- Validates that every account has a name and exactly one of `password_var` /
  `password_sha256_var` resolving to a variable from `VARS/secrets.yml`.
- When the server listens beyond loopback, requires a managed `default` entry
  in `clickhouse_users`: the packaged `default` user accepts remote
  connections with an empty password.
- Downloads the ASCII-armored signing key to
  `/etc/apt/keyrings/clickhouse.asc` and registers
  `deb [arch=amd64 signed-by=...] https://packages.clickhouse.com/deb stable
  main` in `/etc/apt/sources.list.d/clickhouse.list`.
- Verifies `clickhouse_data_directory` sits on its own filesystem (the bind
  mount of the `behemoth/databases/clickhouse` ZFS dataset) before installing
  the server; `clickhouse_require_separate_filesystem: false` disables the
  check.
- Installs `clickhouse-server` and `clickhouse-client`, hands the data
  directory to the `clickhouse` account.
- Writes the `config.d` drop-in (listen_host with `replace`, ports, extra
  settings); a change restarts the service through the handler.
- Writes the `users.d` drop-in with the accounts (or removes it when the list
  is empty); ClickHouse applies users.d on its own, no restart needed.
- Manages the `clickhouse-server` service.

## Requirements

- Debian (target platform Debian 13), `become: true`.
- Gathered facts: `ansible_facts.os_family`.
- Network access to `https://packages.clickhouse.com`.
- Account passwords live in `VARS/secrets.yml`, loaded by the playbook through
  `vars_files`; the role does not read that file itself.

## Managed resources

- Packages: `clickhouse_prerequisite_packages`, `clickhouse_packages`.
- Files: `/etc/apt/keyrings/clickhouse.asc`,
  `/etc/apt/sources.list.d/clickhouse.list`,
  `/etc/clickhouse-server/config.d/90-ansible.xml`,
  `/etc/clickhouse-server/users.d/90-ansible.xml`, the data directory.
- Services: `clickhouse-server`.
- Users/groups: none (the package creates the system user).
- Firewall/API objects: none.

## Variables

| Variable | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `clickhouse_debug_mode` | boolean | no | `false` | Summary after significant changes. |
| `clickhouse_repository_url` | string | no | `"https://packages.clickhouse.com/deb"` | Vendor APT repository URL. |
| `clickhouse_repository_suite` | string | no | `"stable"` | Repository suite. |
| `clickhouse_repository_component` | string | no | `"main"` | Repository component. |
| `clickhouse_repository_arch` | string | no | `"amd64"` | Pinned APT architecture. |
| `clickhouse_repository_key_url` | string | no | `"https://packages.clickhouse.com/rpm/lts/repodata/repomd.xml.key"` | Signing key URL. |
| `clickhouse_keyring_directory` | string | no | `"/etc/apt/keyrings"` | Directory of the signing key. |
| `clickhouse_keyring_file` | string | no | `"clickhouse.asc"` | Key file name (.asc = ASCII-armored). |
| `clickhouse_prerequisite_packages` | list | no | `["ca-certificates", "python3-apt"]` | Packages needed before the repository. |
| `clickhouse_packages` | list | no | `["clickhouse-server", "clickhouse-client"]` | Server and client packages. |
| `clickhouse_data_directory` | string | no | `"/var/lib/clickhouse"` | Data directory. |
| `clickhouse_require_separate_filesystem` | boolean | no | `true` | Require a separate filesystem for the data directory. |
| `clickhouse_config_path` | string | no | `"/etc/clickhouse-server/config.d/90-ansible.xml"` | Server settings drop-in. |
| `clickhouse_users_path` | string | no | `"/etc/clickhouse-server/users.d/90-ansible.xml"` | Accounts drop-in. |
| `clickhouse_listen_hosts` | list | no | `["127.0.0.1"]` | Listen addresses; the first replaces the packaged defaults. |
| `clickhouse_tcp_port` | integer | no | `9000` | Native TCP protocol port. |
| `clickhouse_http_port` | integer | no | `8123` | HTTP interface port. |
| `clickhouse_users` | list | cond. | `[]` | Accounts `{name, password_var|password_sha256_var, networks?, profile?}`; a `default` entry is required when listening beyond loopback. |
| `clickhouse_extra_settings` | dict | no | `{}` | Extra `<name>value</name>` elements in config.d. |
| `clickhouse_service_name` | string | no | `"clickhouse-server"` | systemd service name. |
| `clickhouse_service_state` | string | no | `"started"` | Steady state: `started`/`stopped`. |
| `clickhouse_service_enabled` | boolean | no | `true` | Start at boot. |

Secrets are not declared in defaults. `password_var` names a variable holding
a plaintext password, `password_sha256_var` names one holding the hex string
`sha256(password)`; both resolve from `VARS/secrets.yml` at run time.

## Usage

```yaml
---
- name: Run the analytic database
  hosts: clickhouse
  become: true
  vars_files:
    - ../VARS/secrets.yml
  roles:
    - role: clickhouse
      vars:
        clickhouse_listen_hosts:
          - "127.0.0.1"
          - "172.25.40.152"
        clickhouse_users:
          - name: "default"
            password_sha256_var: "vault_clickhouse_default_password_sha256"
            networks:
              - "127.0.0.1"
          - name: "analytics"
            password_var: "vault_clickhouse_analytics_password"
            networks:
              - "172.25.40.0/24"
```

## Check mode and diff mode

The role supports running:

```bash
ansible-playbook playbook.yml --check --diff
```

Limitations:

- The filesystem probe (`stat %d`) also runs in check mode - it is a
  read-only command.
- `users.d` is marked `no_log: true` and `diff: false`: the content with
  passwords is shown neither in the output nor in a diff.
- `get_url` does not download the key in check mode, so on a cold check run
  the key change is only predicted.

## Handlers

- `Restart ClickHouse` - restarts the service. ClickHouse applies `users.d`
  changes by itself; `listen_host` and port changes bind sockets only at
  start, so a `config.d` change restarts the service.

## Tags

- `debug` - the change summary when `clickhouse_debug_mode: true`.

## Dependencies

- None. Only `ansible.builtin` modules are used.

## Notes

- The `clickhouse-server` postinstall may ask for the `default` user password
  interactively; Ansible runs apt with `DEBIAN_FRONTEND=noninteractive`, so
  the prompt is skipped and the password is set declaratively through
  `clickhouse_users`.
- The data is real and must outlive the container: by default the role fails
  when `/var/lib/clickhouse` is not on its own filesystem (the bind mount of
  the `behemoth/databases/clickhouse` ZFS dataset is expected).
- `password` in users.d is a plaintext password readable by ClickHouse; the
  file is stored `0640 root:clickhouse`. `password_sha256_var` is the
  preferred form.
