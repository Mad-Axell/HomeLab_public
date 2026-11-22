# homepage

This role deploys gethomepage — the single service showcase dashboard — as a
Docker Compose v2 project on a target host with Docker already installed and
renders its YAML configuration files from input variables.

Docker is chosen over a `git clone` + `pnpm build` install: the dashboard
lives in a dedicated LXC, and a ready image has fewer moving parts (no
Node.js/pnpm toolchain on the target, an update is a tag change). All
Homepage configuration is plain YAML, which the role writes into a directory
mounted at `/app/config`.

## What it does

- Validates the Debian platform and the input structure with an early
  `ansible.builtin.assert` before any changes.
- Creates the Compose project directory and the configuration directory
  `homepage_config_dir`.
- Renders `compose.yml` from a template: image, container name, port
  publishing, the `homepage_config_dir` bind mount at `/app/config`, an
  optional `HOMEPAGE_ALLOWED_HOSTS` and arbitrary `homepage_env`. The
  template may carry `HOMEPAGE_VAR_*` secrets, so the task uses
  `diff: false`.
- Renders `services.yaml`, `widgets.yaml` and `settings.yaml` into
  `homepage_config_dir` via `to_nice_yaml` - the inputs match the upstream
  file format verbatim, the role invents no schema of its own.
- Brings the project to `homepage_state` through
  `community.docker.docker_compose_v2`. When `compose.yml` or configuration
  files change, the module recreates/restarts the container automatically,
  so no restart handler is used.
- Does not fill the service catalog itself: the groups and widgets are
  private-repo data fed through `homepage_services`, `homepage_widgets` and
  `homepage_settings`.

## Requirements

- Target OS: Debian 13 (LXC).
- Docker Engine and the Compose v2 plugin on the target host; they are
  installed by the `docker` role, `homepage` does not install Docker.
- `become: true` to create directories and work with Docker.
- The `community.docker` collection, pinned in the project-level
  `requirements.yml`.

## Managed resources

- Packages: none.
- Files: `compose.yml` in `homepage_project_directory`; `services.yaml`,
  `widgets.yaml`, `settings.yaml` in `homepage_config_dir`.
- Services: the Homepage container via Docker Compose.
- Users/groups: none.
- Firewall/API objects: the container-published port `homepage_port`.

## Variables

| Variable | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `homepage_debug_mode` | boolean | no | `false` | Enables debug output after significant changes. |
| `homepage_state` | string | no | `"present"` | Desired Compose project state: `present` or `absent`. |
| `homepage_project_directory` | string | no | `"/opt/homepage"` | Compose project directory holding `compose.yml`. |
| `homepage_config_dir` | string | no | `"/opt/homepage/config"` | Host directory mounted into the container as `/app/config`. |
| `homepage_image` | string | no | `"ghcr.io/gethomepage/homepage:latest"` | Homepage container image. |
| `homepage_container_name` | string | no | `"homepage"` | Homepage container name. |
| `homepage_port` | integer | no | `3000` | Host port publishing the web interface (container listens on port 3000). |
| `homepage_allowed_hosts` | string | no | `null` | Comma-separated names for `HOMEPAGE_ALLOWED_HOSTS`; null allows only localhost. |
| `homepage_env` | dict | no | `{}` | Additional environment variables, including `HOMEPAGE_VAR_*` secrets. |
| `homepage_services` | list | no | `[]` | Service groups in the verbatim upstream `services.yaml` format. |
| `homepage_widgets` | list | no | `[]` | Top-level widgets in the verbatim upstream `widgets.yaml` format. |
| `homepage_settings` | dict | no | `{}` | Global settings rendered into `settings.yaml`. |

The role has no required variables without defaults and no secrets; secret
widget API keys are passed through `homepage_env` as `HOMEPAGE_VAR_*` from
the private repo.

## Usage

```yaml
---
- name: Deploy Homepage
  hosts: homepage
  become: true
  roles:
    - role: docker
    - role: homepage
      vars:
        homepage_allowed_hosts: "homepage.dragons-nest.home.arpa,172.25.40.14"
        homepage_settings:
          title: "Dragons Nest"
          theme: "dark"
        homepage_services:
          - Monitoring:
              - Uptime Kuma:
                  href: "https://uptime.dragons-nest.home.arpa"
                  icon: "uptime-kuma.png"
        homepage_widgets:
          - uptimekuma:
              url: "https://uptime.dragons-nest.home.arpa"
              slug: "status"
```

## Check mode and diff mode

The role supports:

```bash
ansible-playbook playbook.yml --check --diff
```

`ansible.builtin.file` and the configuration templates report diffs
correctly. The `compose.yml` render task uses `diff: false` because
`homepage_env` may carry `HOMEPAGE_VAR_*` secrets.
`community.docker.docker_compose_v2` supports check mode partially:
predicted changes depend on the Docker daemon, so treat the deployment
task's check-mode result as an estimate.

## Dependencies

- The `community.docker` collection (project-level `requirements.yml`).
- The `docker` role as a playbook-level prerequisite; no `meta` dependency
  is used, role order is set by the playbook.

## Notes

- `homepage_services`, `homepage_widgets` and `homepage_settings` render in
  the verbatim upstream format: group, service and option keys follow the
  gethomepage documentation; the role performs no structure transformation.
- Do not write secret API keys (Sonarr, Plex, WUD, ...) into the YAML
  directly: declare them in `homepage_env` as `HOMEPAGE_VAR_<name>` and
  reference them from the YAML files with the `{{HOMEPAGE_VAR_<name>}}`
  placeholder - the configuration files then stay non-secret and readable
  in diffs.
- `HOMEPAGE_ALLOWED_HOSTS` is required by upstream for host-name access:
  without it Homepage answers "host not allowed" for any name except
  localhost.
- Reruns are idempotent: a project and files already in the desired state
  report no changes.
- The `absent` state stops and removes the project containers but keeps
  `compose.yml` and the on-disk configuration.
