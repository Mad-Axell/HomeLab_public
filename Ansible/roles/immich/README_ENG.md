# immich

This role deploys Immich (photo library with machine-learning face and object
recognition) as a Docker Compose v2 project on a target host with Docker
already installed — in this project the `immich` host (172.25.40.92, LXC 422).
Bare-metal installation is not supported by upstream; the upstream-supported
path is Docker Compose, which is also the project convention for
container-only services (`uptime`, `frigate`). The stack consists of the
`immich-server` and `immich-machine-learning` containers fed by an `.env`
file. The role uses an external PostgreSQL (in this project 172.25.40.151)
and an external Redis (172.25.40.154) rather than the bundled compose
containers, matching the Docs catalog. By default the role creates its
database, role and the required extensions itself (`immich_manage_database`),
and secrets are passed by variable name through `*_password_var`.

## What it does

- Validates the Debian platform and the required inputs (`immich_db_host`,
  `immich_redis_host`, `immich_db_password_var`, plus
  `immich_db_admin_password_var` when `immich_manage_database` is enabled)
  with an early `ansible.builtin.assert`, then verifies the named secrets
  exist with a separate check - all before any changes.
- Installs `python3-psycopg2` (`immich_database_packages`) needed by the
  `community.postgresql` modules on the target host.
- With `immich_manage_database: true` creates the PostgreSQL role
  `immich_db_user` (LOGIN, password from `immich_db_password_var`), the
  database `immich_db_name` owned by `immich_db_user`, and the extensions in
  `immich_db_extensions` (`vchord`, `earthdistance`, with `cascade` so
  pgvector is pulled in for VectorChord). The connection is made as the
  privileged `immich_db_admin_user` account; all three tasks run with
  `no_log: true`.
- Creates the Compose project directory `immich_project_directory`, the
  library directory `immich_upload_dir` and the model cache
  `immich_ml_cache_dir`.
- Renders `compose.yml` (`Docker_Compose_Immich.j2`): `immich-server`
  publishes `immich_web_port` to container port 2283 and bind-mounts the
  library directory as `/data`; `immich-machine-learning` bind-mounts the
  model cache as `/cache`. Both containers read `env_file: .env` and run with
  `restart: unless-stopped`.
- Writes `.env` (`immich.env.j2`) with `TZ`, `UPLOAD_LOCATION=/data`, the
  `DB_*` connection variables including the password, `REDIS_HOSTNAME`,
  `REDIS_PORT` and optionally `REDIS_PASSWORD`; mode `0640`, the task runs
  with `no_log: true` and `diff: false`.
- Brings the project to `immich_state` through
  `community.docker.docker_compose_v2`. When `compose.yml` or `.env` changes,
  the module recreates the containers automatically, so no separate restart
  handler is used.
- Does not create the admin account, configure external libraries or set up
  reverse proxying: the account is created in the Immich onboarding wizard,
  and Traefik publishes the service through its own file provider — both are
  out of the role scope.

## Requirements

- Target OS: Debian 13 (asserted via `ansible_facts.os_family == 'Debian'`),
  an LXC in this project.
- Docker Engine and the Compose v2 plugin on the target host; they are
  installed by the `docker` role, `immich` does not install Docker.
- `become: true` to create directories and work with Docker.
- The `community.docker` and `community.postgresql` collections, pinned in
  the project-level `requirements.yml`.
- An external PostgreSQL server (project: `postgresql`, 172.25.40.151)
  reachable on `immich_db_port`. For the `vchord` extension the server must
  have VectorChord and pgvector installed and `vchord.so` listed in
  `shared_preload_libraries` — that is configured on the server side (the
  `postgresql` role's `postgresql_extra_settings`), not by this role.
- An external Redis server (project: `redis`, 172.25.40.154) reachable on
  `immich_redis_port`.
- `VARS/secrets.yml` loaded by the playbook through `vars_files` — the role
  does not load it itself.

## Managed resources

- Packages: `python3-psycopg2` from `immich_database_packages`.
- Files: `compose.yml` and `.env` in `immich_project_directory`, the
  directories `immich_upload_dir` and `immich_ml_cache_dir`.
- Services: the `immich-server` and `immich-machine-learning` containers via
  Docker Compose.
- Users/groups: none.
- Database objects: with `immich_manage_database: true` the PostgreSQL role
  `immich_db_user`, the database `immich_db_name` and the extensions
  `vchord` + `earthdistance` inside it.
- Firewall/API objects: the container-published port `immich_web_port`.

## Variables

| Variable | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `immich_debug_mode` | boolean | no | `false` | Change summary in debug output. |
| `immich_state` | string | no | `"present"` | Desired Compose project state: `present` or `absent`. |
| `immich_project_directory` | string | no | `"/opt/immich"` | Compose project directory holding `compose.yml` and `.env`. |
| `immich_upload_dir` | string | no | `"/opt/immich/library"` | Host directory mounted into the server container as `/data`; point it at the mounted photo storage before importing a real library. |
| `immich_ml_cache_dir` | string | no | `"/opt/immich/model-cache"` | Host directory mounted into the ML container as `/cache`. |
| `immich_server_image` | string | no | `"ghcr.io/immich-app/immich-server:release"` | Server image; pin `vX.Y.Z` for a fixed version. |
| `immich_ml_image` | string | no | `"ghcr.io/immich-app/immich-machine-learning:release"` | Machine-learning image; must match the server tag. |
| `immich_web_port` | integer | no | `2283` | Host port publishing the web interface. |
| `immich_timezone` | string | no | `"Europe/Moscow"` | IANA timezone for library timestamps. |
| `immich_db_host` | string | yes | `null` | PostgreSQL address; no default, asserted. |
| `immich_db_port` | integer | no | `5432` | PostgreSQL port. |
| `immich_db_name` | string | no | `"immich"` | Immich database; created by the role when `immich_manage_database` is `true`. |
| `immich_db_user` | string | no | `"immich"` | Immich login; created by the role when `immich_manage_database` is `true`. |
| `immich_db_password_var` | string or null | yes | `null` | Name of the variable holding the database password in `VARS/secrets.yml`; written to `.env` as `DB_PASSWORD`. |
| `immich_manage_database` | boolean | no | `true` | Create the database, role and extensions before the first start; `false` expects pre-created objects. |
| `immich_db_admin_user` | string | no | `"postgres"` | Privileged account used only to create the database, the role and the extensions. |
| `immich_db_admin_password_var` | string or null | in manage mode | `null` | Name of the variable holding the privileged password in `VARS/secrets.yml`; required when `immich_manage_database` is `true`. |
| `immich_db_extensions` | list | no | `["vchord", "earthdistance"]` | Internal: extensions created inside the Immich database with `cascade`. |
| `immich_database_packages` | list | no | `["python3-psycopg2"]` | Internal: packages the `community.postgresql` modules need. |
| `immich_redis_host` | string | yes | `null` | Redis address; no default, asserted. |
| `immich_redis_port` | integer | no | `6379` | Redis port. |
| `immich_redis_password_var` | string or null | no | `null` | Name of the variable holding the Redis password in `VARS/secrets.yml`; `null` omits `REDIS_PASSWORD` from `.env`. |

## Secrets

Secrets are not referenced by direct names but through `*_password_var`
variables pointing at keys of `VARS/secrets.yml` (the project convention,
same as `keycloak`, `zabbix_server` and `netbox`): the secret value lives
only in secrets.yml and never lands in host_vars. The playbook loads
`VARS/secrets.yml` via `vars_files`; `defaults/main.yml` declares only the
variable names. Early `ansible.builtin.assert` tasks check the names are set
and that the named secrets exist - both before the first system change.

| Variable | Type | Required | Purpose |
| --- | --- | --- | --- |
| secret named by `immich_db_password_var` | string | yes | Password of `immich_db_user`, e.g. the `immich_db_password` key; written to `.env` as `DB_PASSWORD`. |
| secret named by `immich_db_admin_password_var` | string | in manage mode | Password of the privileged `immich_db_admin_user` account on the PostgreSQL server, e.g. the shared `db_admin_password` key; used only to create the database, the role and the extensions. |
| secret named by `immich_redis_password_var` | string | no | Redis password, e.g. the shared Redis `requirepass` key; written to `.env` as `REDIS_PASSWORD` when the variable name is set. |

`.env` is the only place the role materialises secrets; its task runs with
`no_log: true` and `diff: false`. `compose.yml` holds no secrets.

## Usage

```yaml
---
- name: Deploy Immich
  hosts: immich
  become: true
  vars_files:
    - ../VARS/secrets.yml
  roles:
    - role: docker
    - role: immich
      vars:
        immich_db_host: "172.25.40.151"
        immich_db_password_var: "immich_db_password"
        immich_db_admin_password_var: "db_admin_password"
        immich_redis_host: "172.25.40.154"
        immich_redis_password_var: "redis_requirepass"
```

## Tags

- `debug` — the summary debug task when `immich_debug_mode: true`.

## Templates

- `Docker_Compose_Immich.j2` → `immich_project_directory/compose.yml`
- `immich.env.j2` → `immich_project_directory/.env` (secrets)

## Check mode and diff mode

The role supports `--check --diff`. Limitations:

- `ansible.builtin.file` and the compose template report diffs correctly;
  `.env` never shows a diff (`diff: false`) - expected, not a limitation.
- `community.docker.docker_compose_v2` supports check mode partially:
  predicted changes depend on the Docker daemon, so treat the deployment
  task's check-mode result as an estimate.
- `community.postgresql` modules create nothing in check mode; the database
  side is predicted, not applied.

## Dependencies

- The `community.docker` and `community.postgresql` collections
  (project-level `requirements.yml`).
- The `docker` role as a playbook-level prerequisite; no `meta` dependency is
  used, role order is set by the playbook.
- External: a PostgreSQL server with VectorChord + pgvector installed, a
  Redis server, and `VARS/secrets.yml`.

## Notes

- **VectorChord is mandatory on the PostgreSQL server.** Since Immich v1.133
  (and required since v3) upstream uses the `vchord` extension; it is not
  shipped by Debian packages — install VectorChord on the `postgresql` host
  and add `vchord.so` to `shared_preload_libraries` there (the `postgresql`
  role's `postgresql_extra_settings`), or override `immich_db_extensions`
  and provide equivalent extensions yourself. Without them
  `CREATE EXTENSION` fails.
- `immich_upload_dir` defaults to a local path. The intended target is the
  photo storage mounted into the LXC by the provisioning layer (the
  `behemoth`/`media` share per Docs 06); the mount itself is out of scope —
  override the variable to the mount point.
- Behind Traefik the service is published as
  `immich.dragons-nest.home.arpa`; publishing is the `traefik` role's job,
  this role only exposes `immich_web_port`.
- The `absent` state stops and removes the project containers but keeps
  `compose.yml`, `.env` and on-disk data.
- Reruns are idempotent: a project already in the desired state reports no
  changes.
