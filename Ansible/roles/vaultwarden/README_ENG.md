# vaultwarden

This role deploys Vaultwarden — a Rust implementation of the Bitwarden API —
as a Docker Compose v2 project on a target host with Docker already installed
and brings the container to the desired state.

A container is chosen over a binary install: Vaultwarden has no Debian package,
and building from source requires a full Rust toolchain that weighs more than
the service itself inside an LXC. The `vaultwarden/server` image is the
upstream-supported deployment path with a single persistent `/data` volume, so
it has fewer moving parts for the same functionality.

## What it does

- Validates the Debian platform and the input structure with an early
  `ansible.builtin.assert`, then verifies - under `no_log` - that the variable
  named by `vaultwarden_admin_token_var` exists in `VARS/secrets.yml`; both
  checks run before any changes.
- Creates the Compose project directory and the persistent data directory
  `vaultwarden_data_dir` (SQLite database, attachments, sends, icon cache).
- Renders `compose.yml` from a template: image, container name, port
  publishing, a data bind mount, `ADMIN_TOKEN` from the named secret,
  `SIGNUPS_ALLOWED`, an optional `DOMAIN` and arbitrary
  `vaultwarden_extra_env`. The file carries the token, so the task uses
  `no_log: true` and `diff: false`.
- Brings the project to `vaultwarden_state` through
  `community.docker.docker_compose_v2`. When `compose.yml` changes, the module
  recreates the container automatically, so no restart handler is used.
- Does not create organizations, collections or user accounts: these are set
  up in the web UI or the admin panel and are out of the role scope.

## Requirements

- Target OS: Debian 13 (LXC).
- Docker Engine and the Compose v2 plugin on the target host; they are
  installed by the `docker` role, `vaultwarden` does not install Docker.
- `become: true` to create directories and work with Docker.
- The `community.docker` collection, pinned in the project-level
  `requirements.yml`.
- `VARS/secrets.yml` included by the playbook with the variable named by
  `vaultwarden_admin_token_var`.

## Managed resources

- Packages: none.
- Files: `compose.yml` in `vaultwarden_project_directory`, the data directory
  `vaultwarden_data_dir`.
- Services: the Vaultwarden container via Docker Compose.
- Users/groups: none.
- Firewall/API objects: the container-published port `vaultwarden_port`.

## Variables

| Variable | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `vaultwarden_debug_mode` | boolean | no | `false` | Enables debug output after significant changes. |
| `vaultwarden_state` | string | no | `"present"` | Desired Compose project state: `present` or `absent`. |
| `vaultwarden_project_directory` | string | no | `"/opt/vaultwarden"` | Compose project directory holding `compose.yml`. |
| `vaultwarden_data_dir` | string | no | `"/opt/vaultwarden/data"` | Host directory mounted into the container as `/data`. |
| `vaultwarden_image` | string | no | `"vaultwarden/server:latest"` | Vaultwarden container image. |
| `vaultwarden_container_name` | string | no | `"vaultwarden"` | Vaultwarden container name. |
| `vaultwarden_port` | integer | no | `8222` | Host port publishing the web interface (container listens on port 80). |
| `vaultwarden_admin_token_var` | string | yes | `null` | Name of the `VARS/secrets.yml` variable holding the admin panel token. |
| `vaultwarden_domain` | string | no | `null` | Public URL of this instance; null leaves `DOMAIN` unset. |
| `vaultwarden_signups_allowed` | boolean | no | `false` | Allow open user self-registration. |
| `vaultwarden_extra_env` | dict | no | `{}` | Additional container environment variables (for example `SMTP_*`). |

## Secrets (VARS/secrets.yml)

| Variable | Required | Description |
| --- | --- | --- |
| The variable named by `vaultwarden_admin_token_var` (for example `vault_vaultwarden_admin_token`) | yes | Admin panel `/admin` token. The value is read from `VARS/secrets.yml` at run time and lands only in `compose.yml`; the render task uses `no_log: true` and `diff: false`. |

## Usage

```yaml
---
- name: Deploy Vaultwarden
  hosts: vaultwarden
  become: true
  vars_files:
    - ../VARS/secrets.yml
  roles:
    - role: docker
    - role: vaultwarden
      vars:
        vaultwarden_admin_token_var: "vault_vaultwarden_admin_token"
        vaultwarden_domain: "https://vaultwarden.dragons-nest.home.arpa"
        vaultwarden_port: 8222
```

## Check mode and diff mode

The role supports:

```bash
ansible-playbook playbook.yml --check --diff
```

`ansible.builtin.file` reports changes correctly. The `compose.yml` render task
uses `no_log: true` and `diff: false` because of the token, so its diff is
hidden deliberately. `community.docker.docker_compose_v2` supports check mode
partially: predicted changes depend on the Docker daemon, so treat the
deployment task's check-mode result as an estimate.

## Dependencies

- The `community.docker` collection (project-level `requirements.yml`).
- The `docker` role as a playbook-level prerequisite; no `meta` dependency is
  used, role order is set by the playbook.
- `VARS/secrets.yml` with the secret named by `vaultwarden_admin_token_var`.

## Notes

- `ADMIN_TOKEN` opens the `/admin` panel: user, invitation and global settings
  management. Vaultwarden recommends an Argon2 hash of the token; the role
  passes the value through as is - the supplied secret chooses the format.
- `vaultwarden_domain` is required for WebAuthn/passkey login and invite
  links; without it passkey sign-in does not work.
- `vaultwarden_extra_env` accepts any environment variables, for example
  `SMTP_HOST`/`SMTP_FROM` for invitation mail; feed secret values through the
  private repo secrets - the `compose.yml` content is never logged.
- Reruns are idempotent: a project already in the desired state reports no
  changes.
- The `absent` state stops and removes the project containers but keeps
  `compose.yml` and on-disk data.
