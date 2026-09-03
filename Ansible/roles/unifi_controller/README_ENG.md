# unifi_controller

The role deploys the full UniFi Network Server stack on Debian: a Java runtime,
a MongoDB server and the UniFi package itself, from two explicitly declared
signed APT repositories.

## What it does

- Validates the Debian platform and the supplied URIs and keys of both repositories.
- Validates the `avx` CPU flag, without which MongoDB 5.0 and newer fails to start.
- Installs `ca-certificates`, `curl` and `gnupg`, and creates the shared keyring directory.
- Registers the MongoDB key and repository, then the UniFi key and repository.
- Installs the JRE and the MongoDB server and brings the packaged `mongod` unit
  to its steady state (stopped by default, see below).
- Installs the UniFi package without recommends and brings its service to its
  steady state.
- On request installs `rsync` and schedules a cron job that copies the UniFi
  autobackups into a directory outside the application tree.

Order matters: the `unifi` package declares a `mongodb-org-server` dependency, so
MongoDB is registered and installed before UniFi. The `install_recommends: false`
flag keeps APT from pulling in the Debian `mongodb` packages.

## Requirements

- Debian, `become: true` and network access to both repositories.
- Gathered facts: the role reads `ansible_facts.os_family`. Ansible exposes no
  CPU flag fact, so the role reads `/proc/cpuinfo` with `slurp`.
- A CPU with AVX while `unifi_controller_require_avx` stays enabled.
- The JRE package in `unifi_controller_java_package` must satisfy the Java
  dependency of the specific UniFi release. The required Java version changes
  between UniFi releases; re-check the `Depends` field of the `unifi` package
  whenever the repository suite changes.

## Managed resources

- Packages: `ca-certificates`, `curl`, `gnupg`, `unifi_controller_java_package`,
  `unifi_controller_mongodb_package`, `unifi_controller_package_name`.
- Files: the `unifi_controller_keyring_directory` directory, the
  `unifi_controller_mongodb_keyring_file` and `unifi_controller_keyring_file`
  key files, `/etc/apt/sources.list.d/mongodb-org.list` and
  `/etc/apt/sources.list.d/unifi-controller.list`.
- Cron: the `/etc/cron.d/unifi-backup` file and the
  `unifi_controller_backup_copy_dest` directory when the copy is enabled.
- Services: `unifi_controller_mongodb_service_name`,
  `unifi_controller_service_name`.
- Users/groups: none.
- Firewall/API objects: UniFi ports are opened by a separate firewall role.

## Variables

| Variable | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `unifi_controller_require_avx` | boolean | no | `true` | Require the `avx` CPU flag before installing. |
| `unifi_controller_keyring_directory` | string | no | `"/etc/apt/keyrings"` | Signing key directory. |
| `unifi_controller_java_package` | string | no | `"openjdk-25-jre-headless"` | JRE package for the UniFi dependency. |
| `unifi_controller_mongodb_repository` | string | yes | `null` | MongoDB repository URI with suite and component. |
| `unifi_controller_mongodb_repository_key_url` | string | yes | `null` | URL of the ASCII-armored MongoDB key. |
| `unifi_controller_mongodb_keyring_file` | string | no | `"mongodb-server.asc"` | MongoDB key file name. |
| `unifi_controller_mongodb_package` | string | no | `"mongodb-org"` | MongoDB server package. |
| `unifi_controller_mongodb_service_name` | string | no | `"mongod"` | Packaged MongoDB service. |
| `unifi_controller_mongodb_service_state` | string | no | `"stopped"` | Packaged MongoDB service state. |
| `unifi_controller_mongodb_service_enabled` | boolean | no | `false` | Packaged MongoDB boot start. |
| `unifi_controller_repository` | string | yes | `null` | UniFi repository URI with suite and component. |
| `unifi_controller_repository_key_url` | string | yes | `null` | URL of the binary UniFi key. |
| `unifi_controller_keyring_file` | string | no | `"unifi-repo.gpg"` | UniFi key file name. |
| `unifi_controller_package_name` | string | no | `"unifi"` | UniFi package. |
| `unifi_controller_service_name` | string | no | `"unifi"` | UniFi service. |
| `unifi_controller_service_state` | string | no | `"started"` | UniFi service state. |
| `unifi_controller_service_enabled` | boolean | no | `true` | UniFi service boot start. |
| `unifi_controller_backup_copy_enabled` | boolean | no | `false` | Copy autobackups on a schedule. |
| `unifi_controller_backup_copy_source` | string | no | `"/usr/lib/unifi/data/backup/autobackup/"` | UniFi autobackup directory. |
| `unifi_controller_backup_copy_dest` | string | no | `"/var/backups/unifi"` | Directory receiving the copy. |
| `unifi_controller_backup_copy_hour` | string | no | `"4"` | Copy job hour. |
| `unifi_controller_backup_copy_minute` | string | no | `"30"` | Copy job minute. |
| `unifi_controller_debug_mode` | boolean | no | `false` | Reports that a change happened. |

### Why the packaged `mongod` stays stopped

UniFi Network Server starts and supervises its own `mongod` process with
`--dbpath /usr/lib/unifi/data/db` and `--port 27117`, using the same binary from
`mongodb-org-server`. The `unifi` package requires `mongodb-org-server` only as a
dependency; the packaged `mongod` unit (port 27017) is unused in a standalone
install. Running it means keeping a second database instance alive, and on kernel
6.19 and newer it additionally fails with
[SERVER-121912](https://jira.mongodb.org/browse/SERVER-121912), leaving the unit
in a `failed` state.

When the packaged unit has already failed once (for example during the first
install on kernel 6.19+), the role also clears the recorded failure with
`systemctl reset-failed`: without that a stopped and disabled unit keeps showing
up in `systemctl --failed` and raises a false alarm.

Start the packaged service only when UniFi is deliberately pointed at an external
shared MongoDB; then set `unifi_controller_mongodb_service_state: "started"` and
`unifi_controller_mongodb_service_enabled: true`.

The key file extension is meaningful: the MongoDB key is published ASCII-armored
and is named `.asc`, while the UniFi key is binary OpenPGP and is named `.gpg`.

## Secret external inputs

The role uses no secrets and does not read `VARS/secrets.yml`.

## Usage

```yaml
---
- name: Install UniFi Network Server
  hosts: unifi
  become: true
  roles:
    - role: unifi_controller
      vars:
        unifi_controller_mongodb_repository: "https://repository.example.invalid/apt/debian bookworm/mongodb-org/8.0 main"
        unifi_controller_mongodb_repository_key_url: "https://repository.example.invalid/static/pgp/server-8.0.asc"
        unifi_controller_repository: "https://repository.example.invalid/unifi/debian unifi-10.4 ubiquiti"
        unifi_controller_repository_key_url: "https://repository.example.invalid/unifi/unifi-repo.gpg"
```

## Check mode and diff mode

The role supports `--check --diff` partially, and this is an APT limitation
rather than a defect:

- in check mode the repositories are not actually added, so the tasks installing
  `unifi_controller_java_package`, `unifi_controller_mongodb_package` and
  `unifi_controller_package_name` report a missing candidate package on a clean host;
- for that reason a full `--check` is only meaningful on a host where the
  repositories were already registered by an earlier real run;
- the key, keyring directory and service tasks behave correctly in check mode.

## Dependencies

- None

## Handlers and tags

- Handlers: none, the role stores only the steady service state.
- Tags: `debug` on the final debug task.
