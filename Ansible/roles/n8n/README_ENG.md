# n8n

This role deploys n8n (workflow automation; in this project it routes Zabbix,
Prometheus, Home Assistant and Frigate notifications to Telegram per Docs 06)
as a Docker Compose v2 project on a target host with Docker already
installed — the `n8n` host (172.25.40.203, LXC 441). The containerized path
is the upstream-supported production deployment and matches the project
convention for container-only services (`uptime`, `frigate`, `immich`). The
role uses an external PostgreSQL (in this project 172.25.40.151) rather than
the default embedded SQLite, creates its database and role itself by default
(`n8n_manage_database`), and pins the credential encryption key through the
`n8n_encryption_key_var` indirection.

## What it does

- Validates the Debian platform and the required inputs (`n8n_db_host`,
  `n8n_db_password_var`, `n8n_encryption_key_var`, plus
  `n8n_db_admin_password_var` when `n8n_manage_database` is enabled) with an
  early `ansible.builtin.assert`, then verifies the named secrets exist with
  a separate check - all before any changes.
- Installs `python3-psycopg2` (`n8n_database_packages`) needed by the
  `community.postgresql` modules on the target host.
- With `n8n_manage_database: true` creates the PostgreSQL role
  `n8n_db_user` (LOGIN, password from `n8n_db_password_var`) and the database
  `n8n_db_name` owned by `n8n_db_user`; the connection is made as the
  privileged `n8n_db_admin_user` account. Both tasks run with `no_log: true`.
- Creates the Compose project directory `n8n_project_directory` and the data
  directory `n8n_data_dir` owned by uid/gid 1000 — the `node` account the n8n
  container runs as.
- Renders `compose.yml` (`Docker_Compose_N8n.j2`): the `n8n` container
  publishes `n8n_web_port` to container port 5678 and bind-mounts the data
  directory as `/home/node/.n8n`; it reads `env_file: .env` and runs with
  `restart: unless-stopped`.
- Writes `.env` (`n8n.env.j2`) with `GENERIC_TIMEZONE`/`TZ`, the
  `DB_POSTGRESDB_*` connection variables including the password,
  `N8N_ENCRYPTION_KEY`, `N8N_PROTOCOL`, `N8N_SECURE_COOKIE`, and optionally
  `N8N_HOST` and `WEBHOOK_URL`; mode `0640`, the task runs with
  `no_log: true` and `diff: false`.
- Brings the project to `n8n_state` through
  `community.docker.docker_compose_v2`. When `compose.yml` or `.env` changes,
  the module recreates the container automatically, so no separate restart
  handler is used.
- Does not create the owner account, import workflows or set up reverse
  proxying: the owner account is created in the n8n onboarding wizard, and
  Traefik publishes the service through its own file provider — all out of
  the role scope.

## Requirements

- Target OS: Debian 13 (asserted via `ansible_facts.os_family == 'Debian'`),
  an LXC in this project.
- Docker Engine and the Compose v2 plugin on the target host; they are
  installed by the `docker` role, `n8n` does not install Docker.
- `become: true` to create directories and work with Docker.
- The `community.docker` and `community.postgresql` collections, pinned in
  the project-level `requirements.yml`.
- An external PostgreSQL server (project: `postgresql`, 172.25.40.151)
  reachable on `n8n_db_port`; postgres is the only supported backend.
- `VARS/secrets.yml` loaded by the playbook through `vars_files` — the role
  does not load it itself.

## Managed resources

- Packages: `python3-psycopg2` from `n8n_database_packages`.
- Files: `compose.yml` and `.env` in `n8n_project_directory`, the directory
  `n8n_data_dir` (uid/gid 1000).
- Services: the `n8n` container via Docker Compose.
- Users/groups: none.
- Database objects: with `n8n_manage_database: true` the PostgreSQL role
  `n8n_db_user` and the database `n8n_db_name`.
- Firewall/API objects: the container-published port `n8n_web_port`.

## Variables

| Variable | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `n8n_debug_mode` | boolean | no | `false` | Change summary in debug output. |
| `n8n_state` | string | no | `"present"` | Desired Compose project state: `present` or `absent`. |
| `n8n_project_directory` | string | no | `"/opt/n8n"` | Compose project directory holding `compose.yml` and `.env`. |
| `n8n_data_dir` | string | no | `"/opt/n8n/data"` | Host directory mounted into the container as `/home/node/.n8n`; owned by uid/gid 1000. |
| `n8n_image` | string | no | `"docker.n8n.io/n8nio/n8n:stable"` | n8n image; pin `X.Y.Z` for a fixed version. |
| `n8n_container_name` | string | no | `"n8n"` | n8n container name. |
| `n8n_web_port` | integer | no | `5678` | Host port publishing the web interface. |
| `n8n_timezone` | string | no | `"Europe/Moscow"` | IANA timezone for workflow schedules. |
| `n8n_db_host` | string | yes | `null` | PostgreSQL address; no default, asserted. |
| `n8n_db_port` | integer | no | `5432` | PostgreSQL port. |
| `n8n_db_name` | string | no | `"n8n"` | n8n database; created by the role when `n8n_manage_database` is `true`. |
| `n8n_db_user` | string | no | `"n8n"` | n8n login; created by the role when `n8n_manage_database` is `true`. |
| `n8n_db_password_var` | string or null | yes | `null` | Name of the variable holding the database password in `VARS/secrets.yml`; written to `.env` as `DB_POSTGRESDB_PASSWORD`. |
| `n8n_manage_database` | boolean | no | `true` | Create the database and its role before the first start; `false` expects pre-created objects. |
| `n8n_db_admin_user` | string | no | `"postgres"` | Privileged account used only to create the database and the role. |
| `n8n_db_admin_password_var` | string or null | in manage mode | `null` | Name of the variable holding the privileged password in `VARS/secrets.yml`; required when `n8n_manage_database` is `true`. |
| `n8n_database_packages` | list | no | `["python3-psycopg2"]` | Internal: packages the `community.postgresql` modules need. |
| `n8n_encryption_key_var` | string or null | yes | `null` | Name of the variable holding `N8N_ENCRYPTION_KEY` in `VARS/secrets.yml`; asserted. |
| `n8n_hostname` | string or null | no | `null` | Public hostname rendered as `N8N_HOST`; `null` or empty omits the variable. |
| `n8n_protocol` | string | no | `"http"` | Listener protocol; `http` because Traefik terminates TLS. |
| `n8n_webhook_url` | string or null | no | `null` | External URL rendered as `WEBHOOK_URL`; `null` or empty omits the variable. |
| `n8n_secure_cookie` | boolean | no | `true` | `N8N_SECURE_COOKIE`; `true` behind Traefik/HTTPS, `false` only for direct HTTP access. |

## Secrets

Secrets are not referenced by direct names but through `*_var` variables
pointing at keys of `VARS/secrets.yml` (the project convention, same as
`keycloak`, `zabbix_server` and `netbox`): the secret value lives only in
secrets.yml and never lands in host_vars. The playbook loads
`VARS/secrets.yml` via `vars_files`; `defaults/main.yml` declares only the
variable names. Early `ansible.builtin.assert` tasks check the names are set
and that the named secrets exist - both before the first system change.

| Variable | Type | Required | Purpose |
| --- | --- | --- | --- |
| secret named by `n8n_db_password_var` | string | yes | Password of `n8n_db_user`, e.g. the `n8n_db_password` key; written to `.env` as `DB_POSTGRESDB_PASSWORD`. |
| secret named by `n8n_encryption_key_var` | string | yes | `N8N_ENCRYPTION_KEY`, e.g. the `n8n_encryption_key` key; encrypts the credentials stored by workflows. Without a pinned key a re-created data directory leaves all saved credentials unreadable. |
| secret named by `n8n_db_admin_password_var` | string | in manage mode | Password of the privileged `n8n_db_admin_user` account on the PostgreSQL server, e.g. the shared `db_admin_password` key; used only to create the database and the role. |

`.env` is the only place the role materialises secrets; its task runs with
`no_log: true` and `diff: false`. `compose.yml` holds no secrets.

## Usage

```yaml
---
- name: Deploy n8n
  hosts: n8n
  become: true
  vars_files:
    - ../VARS/secrets.yml
  roles:
    - role: docker
    - role: n8n
      vars:
        n8n_db_host: "172.25.40.151"
        n8n_db_password_var: "n8n_db_password"
        n8n_db_admin_password_var: "db_admin_password"
        n8n_encryption_key_var: "n8n_encryption_key"
        n8n_hostname: "n8n.dragons-nest.home.arpa"
        n8n_webhook_url: "https://n8n.dragons-nest.home.arpa/"
```

## Tags

- `debug` — the summary debug task when `n8n_debug_mode: true`.

## Templates

- `Docker_Compose_N8n.j2` → `n8n_project_directory/compose.yml`
- `n8n.env.j2` → `n8n_project_directory/.env` (secrets)

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
- External: a PostgreSQL server and `VARS/secrets.yml`.

## Notes

- The owner account is created in the n8n setup wizard on first login; the
  old env-based basic auth was removed upstream, so the role does not model
  it.
- Behind Traefik the service is published as
  `n8n.dragons-nest.home.arpa`; publishing is the `traefik` role's job. Set
  `n8n_hostname` and `n8n_webhook_url` to the external name so webhook nodes
  advertise reachable addresses.
- The `absent` state stops and removes the project container but keeps
  `compose.yml`, `.env` and on-disk data.
- Reruns are idempotent: a project already in the desired state reports no
  changes.
