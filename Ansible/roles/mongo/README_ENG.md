# mongo

The role installs the MongoDB 9.0 document database on LXC `172.25.40.153`.
Debian 13 ships no mongodb package for licensing reasons (SSPL), so the
vendor APT repository `repo.mongodb.org` is used - the supported upstream
path; the `trixie/mongodb-org/9.0` suite is published upstream.

`mongod.conf` has no drop-in mechanism, so the role owns the whole file -
the package does not rewrite it after installation.

## What it does

- Validates the Debian platform, the port, the bind address and types before
  any change.
- Refuses to bind beyond loopback without `mongo_authorization: enabled` and
  `mongo_admin_password_var`.
- Validates that `mongo_admin_password_var` and every `password_var` in
  `mongo_users` resolve to variables from `VARS/secrets.yml`.
- Downloads the ASCII-armored signing key to
  `/etc/apt/keyrings/mongodb-server-9.0.asc` and registers
  `deb [arch=amd64 signed-by=...] https://repo.mongodb.org/apt/debian
  trixie/mongodb-org/9.0 main` in
  `/etc/apt/sources.list.d/mongodb-org.list`.
- Installs `mongodb-org` (the vendor meta-package) and `python3-pymongo`,
  required by the `community.mongodb` modules.
- Writes `/etc/mongod.conf` as a whole: `storage.dbPath`, `systemLog`,
  `net.port`/`net.bindIp`, `security.authorization` when authorization is
  enabled, and `mongo_extra_settings`; a change restarts `mongod` through
  the handler.
- Creates the `mongo_admin_user` administrative account (`root` role in the
  `admin` database) - on the first run through the MongoDB localhost
  exception.
- Creates the application users of `mongo_users` with `update_password:
  on_create` - idempotent on reruns.

## Requirements

- Debian (target platform Debian 13), `become: true`.
- Gathered facts: `ansible_facts.os_family`.
- Network access to `https://repo.mongodb.org` and
  `https://www.mongodb.org/static/pgp/`.
- The `community.mongodb` collection on the controller (pinned in the
  project-level `requirements.yml`).
- A CPU with AVX: MongoDB >= 5.0 requires AVX (the pve-main hosts have it -
  see `Docs/instructions/05_unifi_wifi.md` section 0.1).
- Passwords live in `VARS/secrets.yml`, loaded by the playbook through
  `vars_files`; the role does not read that file itself.

## Managed resources

- Packages: `mongo_prerequisite_packages`, `mongo_packages`.
- Files: `/etc/apt/keyrings/mongodb-server-9.0.asc`,
  `/etc/apt/sources.list.d/mongodb-org.list`, `/etc/mongod.conf`.
- Services: `mongod`.
- Users/groups: none at OS level (the `mongodb` user comes from the
  package); DB objects: the admin account and the `mongo_users` users.
- Firewall/API objects: none.

## Variables

| Variable | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `mongo_debug_mode` | boolean | no | `false` | Summary after significant changes. |
| `mongo_repository_url` | string | no | `"https://repo.mongodb.org/apt/debian"` | Vendor APT repository URL. |
| `mongo_repository_suite` | string | no | `"trixie/mongodb-org/9.0"` | Suite: Debian release + MongoDB series. |
| `mongo_repository_component` | string | no | `"main"` | Repository component. |
| `mongo_repository_arch` | string | no | `"amd64"` | Pinned APT architecture. |
| `mongo_repository_key_url` | string | no | `"https://pgp.mongodb.com/server-9.0.asc"` | Signing key URL for the 9.0 series. |
| `mongo_keyring_directory` | string | no | `"/etc/apt/keyrings"` | Directory of the signing key. |
| `mongo_keyring_file` | string | no | `"mongodb-server-9.0.asc"` | Key file name (.asc = ASCII-armored). |
| `mongo_prerequisite_packages` | list | no | `["ca-certificates", "python3-apt"]` | Packages needed before the repository. |
| `mongo_packages` | list | no | `["mongodb-org", "python3-pymongo"]` | Server and pymongo for community.mongodb. |
| `mongo_config_path` | string | no | `"/etc/mongod.conf"` | Configuration file (owned as a whole). |
| `mongo_db_path` | string | no | `"/var/lib/mongodb"` | Database directory. |
| `mongo_log_path` | string | no | `"/var/log/mongodb/mongod.log"` | Log file. |
| `mongo_bind_ip` | string | no | `"127.0.0.1"` | Listen addresses, comma-separated. |
| `mongo_port` | integer | no | `27017` | mongod TCP port. |
| `mongo_authorization` | string | no | `"disabled"` | `security.authorization`: `enabled`/`disabled`. |
| `mongo_admin_user` | string | no | `"admin"` | Administrative account name (`admin` db, `root` role). |
| `mongo_admin_password_var` | string/null | cond. | `null` | Variable name holding the admin password; required with `authorization: enabled`. |
| `mongo_users` | list | no | `[]` | Users `{name, password_var, database?, roles?}`. |
| `mongo_extra_settings` | dict | no | `{}` | Extra top-level YAML keys merged into mongod.conf. |
| `mongo_service_name` | string | no | `"mongod"` | systemd service name. |
| `mongo_service_state` | string | no | `"started"` | Steady state: `started`/`stopped`. |
| `mongo_service_enabled` | boolean | no | `true` | Start at boot. |

Secrets are not declared in defaults. `mongo_admin_password_var` and
`password_var` are *names* of variables (for example
`vault_mongo_admin_password`) provided by `VARS/secrets.yml`; the role
resolves them at run time through `lookup('ansible.builtin.vars', ...)`.

## Usage

```yaml
---
- name: Run the document database
  hosts: mongo
  become: true
  vars_files:
    - ../VARS/secrets.yml
  roles:
    - role: mongo
      vars:
        mongo_bind_ip: "127.0.0.1,172.25.40.153"
        mongo_authorization: "enabled"
        mongo_admin_password_var: "vault_mongo_admin_password"
        mongo_users:
          - name: "app"
            password_var: "vault_mongo_app_password"
            database: "appdb"
            roles:
              - { db: "appdb", role: "readWrite" }
```

## Check mode and diff mode

The role supports running:

```bash
ansible-playbook playbook.yml --check --diff
```

Limitations:

- `get_url` does not download the key in check mode - on a cold run the
  change is only predicted.
- `community.mongodb.mongodb_user` supports check mode; the user tasks are
  marked `no_log: true`, so account details do not reach the output.
- `mongod.conf` carries no secrets - the file diff is shown normally.

## Handlers

- `Restart MongoDB` - restarts `mongod`; the server has no configuration
  reload, so bind/authorization changes apply only through a restart. The
  handler is applied through `flush_handlers` before the user creation
  tasks.

## Tags

- `debug` - the change summary when `mongo_debug_mode: true`.

## Dependencies

- The `community.mongodb` collection (`mongodb_user` module, requires
  `python3-pymongo` on the host - installed by the role). Pin it in the
  project-level `requirements.yml` at the Ansible project root.

## Notes

- `update_password: on_create` means the role does not track password
  changes of an existing user - recreate the user when a rotation is
  needed.
- On the first run with authorization enabled the admin is created through
  the MongoDB localhost exception: a local connection may create the first
  account while no users exist.
- The default (`authorization: disabled`, bind `127.0.0.1`) is safe: the
  server is unreachable from the network. Opening a network interface
  without authorization is rejected by an assert.
