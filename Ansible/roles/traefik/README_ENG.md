# traefik

This role installs the Traefik reverse proxy on Debian as a static binary from the official GitHub release: it creates a dedicated system account, a systemd unit, a static configuration with an HTTP to HTTPS redirect and a file provider directory for dynamic configuration. The TLS certificate and private key are supplied from outside; DNS records and certificate issuance are out of the role's scope.

## What it does

- Creates the `traefik` system group and user.
- Downloads the pinned Traefik release and unpacks the binary into `/usr/local/bin`; the installed version is recorded in a marker file, so upgrades driven by `traefik_version` are idempotent.
- Writes the static configuration: `web` (`:80`) with a permanent redirect to `websecure` (`:443`, TLS), and a file provider watching `/etc/traefik/dynamic`.
- With `traefik_tls_enabled`, writes the certificate, the private key and a dynamic file registering them as the default certificate; when disabled, removes that material.
- Writes the files from `traefik_dynamic_config_files` into the file provider directory (reloaded without a restart) and removes files from that directory which are no longer managed by the role.
- Installs a systemd unit and brings the `traefik` service to its requested state.

Limitation: TLS works only with an already issued certificate. The role implements neither an internal CA nor ACME/Let's Encrypt; the certificate and key are produced by an external process (for example the infrastructure's internal CA) and the role only installs them.

## Requirements

- Debian or Ubuntu (the project target platform is a Debian 13 LXC).
- `become: true`.
- Network access from the target host to `github.com` to download the release.
- With `traefik_tls_enabled` — the `traefik_tls_cert` variable and the `vault_traefik_tls_key` secret from `VARS/secrets.yml`, attached by the playbook through `vars_files`.

## Managed resources

- Packages: none (installed from the release archive, not via apt).
- Files: `/usr/local/bin/traefik`, `/etc/traefik/traefik.yml`, `/etc/traefik/.installed-version`, `/etc/traefik/dynamic/*` (dynamic files and removal of unmanaged `*.yml`/`*.yaml`), `/etc/traefik/tls/fullchain.pem`, `/etc/traefik/tls/privkey.pem` (when TLS is enabled), `/etc/systemd/system/traefik.service`; the temporary archive in `/tmp` is removed.
- Services: `traefik` (systemd).
- Users/groups: `traefik`/`traefik` (system, no home and no login shell).
- Firewall/API objects: none.

## Variables

| Variable | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `traefik_debug_mode` | boolean | no | `false` | Debug output after user-visible changes (`debug` tag). |
| `traefik_version` | string | no | `"3.7.19"` | Pinned release version without the leading `v`. |
| `traefik_arch` | string | no | `"amd64"` | Architecture as named in the release asset. |
| `traefik_download_url` | string | no | GitHub releases URL | Tarball URL; built from the version and architecture. |
| `traefik_archive_checksum` | string/null | no | `null` | Optional sha256 of the tarball from the `traefik_v<version>_checksums.txt` asset; `null` disables verification. |
| `traefik_archive_path` | string | no | `/tmp/traefik_v...tar.gz` | Temporary path of the downloaded archive. |
| `traefik_binary_path` | string | no | `"/usr/local/bin/traefik"` | Path of the installed binary. |
| `traefik_version_marker_path` | string | no | `"/etc/traefik/.installed-version"` | Installed-version marker file. |
| `traefik_user` | string | no | `"traefik"` | Service account name. |
| `traefik_group` | string | no | `"traefik"` | Service account group. |
| `traefik_config_dir` | string | no | `"/etc/traefik"` | Static configuration directory. |
| `traefik_dynamic_dir` | string | no | `"/etc/traefik/dynamic"` | Watched file provider directory. |
| `traefik_tls_dir` | string | no | `"/etc/traefik/tls"` | Certificate and key directory. |
| `traefik_config_path` | string | no | `"/etc/traefik/traefik.yml"` | Static configuration file. |
| `traefik_tls_dynamic_path` | string | no | `"/etc/traefik/dynamic/10-tls.yml"` | Dynamic file for the certificate store. |
| `traefik_tls_cert_path` | string | no | `"/etc/traefik/tls/fullchain.pem"` | PEM chain destination. |
| `traefik_tls_key_path` | string | no | `"/etc/traefik/tls/privkey.pem"` | PEM key destination. |
| `traefik_unit_path` | string | no | `"/etc/systemd/system/traefik.service"` | systemd unit file. |
| `traefik_http_port` | integer | no | `80` | `web` entry point port; redirects to HTTPS. |
| `traefik_https_port` | integer | no | `443` | `websecure` entry point port. |
| `traefik_domain` | string | no | `"example.internal"` | Base domain usable via Jinja inside dynamic file `content`; override with the real served zone. |
| `traefik_dynamic_config_files` | list of dict | no | `[]` | File provider configurations: `name` (file name; only its basename is used), `content` (YAML rendered as Jinja), optional `sensitive` (hides the item's output and diff). |
| `traefik_dashboard_enabled` | boolean | no | `false` | Dashboard and API on `:8080` via `api.insecure`. |
| `traefik_log_level` | string | no | `"INFO"` | Log level. |
| `traefik_tls_enabled` | boolean | no | `false` | Enable HTTPS with the external certificate and key. |
| `traefik_tls_cert` | string | yes, when `traefik_tls_enabled` | `null` | PEM certificate chain content; checked by `assert` before any change. |
| `traefik_service_name` | string | no | `"traefik"` | systemd service name. |
| `traefik_service_state` | string | no | `"started"` | Steady state (`started`/`stopped`). |
| `traefik_service_enabled` | boolean | no | `true` | Enable at boot. |

Secrets (from `VARS/secrets.yml` only, no defaults):

| Variable | Type | Required | Description |
| --- | --- | --- | --- |
| `vault_traefik_tls_key` | string | yes, when `traefik_tls_enabled` | PEM private key content. The writing task uses `no_log: true` and `diff: false`. |

## Usage

```yaml
---
- name: Configure the reverse proxy
  hosts: traefik
  become: true
  vars_files:
    - "VARS/secrets.yml"  # vault_traefik_tls_key
  roles:
    - role: traefik
      vars:
        traefik_domain: "example.internal"
        traefik_tls_enabled: true
        traefik_tls_cert: "{{ lookup('ansible.builtin.file', 'fullchain.pem') }}"
        traefik_dynamic_config_files:
          - name: "grafana.yml"
            content: |
              http:
                routers:
                  grafana:
                    rule: "Host(`grafana.{{ traefik_domain }}`)"
                    entryPoints: ["websecure"]
                    service: "grafana"
                    tls: {}
                services:
                  grafana:
                    loadBalancer:
                      servers:
                        - url: "http://10.0.0.52:3000"
          - name: "dashboard-auth.yml"
            sensitive: true
            content: |
              http:
                middlewares:
                  admin-auth:
                    basicAuth:
                      users: ["admin:$apr1$..."]
```

## Check mode and diff mode

The role supports `ansible-playbook --check --diff` with the following limitations:

- The tarball download is predicted, but the binary extraction (`unarchive`) is skipped in check mode: the archive does not exist on the host yet. The install decision is derived from the version marker.
- `diff` is hidden for the private key and for `traefik_dynamic_config_files` items with `sensitive: true`.
- The marker `slurp` is skipped on the first run — the install is still predicted correctly.

## Handlers

- `Reload systemd` — daemon-reload after unit file changes.
- `Restart Traefik` — after binary, static configuration or certificate/key changes, or their removal. Dynamic files are reloaded by the file provider without a restart.

## Tags

- `debug` — the aggregate debug task; skipped via `--skip-tags debug`.

## Templates

- `traefik.yml.j2` — static configuration.
- `dynamic_tls.yml.j2` — default certificate store.
- `traefik.service.j2` — systemd unit.

## Dependencies

- None (`ansible.builtin` only).

## Notes

- DNS records for the served names (a wildcard pointing at the proxy address) and firewall rules for ports 80/443/8080 are out of the role's scope and are configured separately (pfSense/Unbound in this infrastructure).
- `traefik_dashboard_enabled` exposes the API without authentication on `:8080` (`api.insecure`); restrict access at the firewall. Basic-auth protection is expressed as a middleware in `traefik_dynamic_config_files`.
- Without `traefik_tls_enabled` the `websecure` entry point answers with Traefik's built-in self-signed certificate, and the `web` to `websecure` redirect stays enabled.
- The systemd unit grants `CAP_NET_BIND_SERVICE`, so Traefik listens on 80/443 as an unprivileged account.
