# yandex_rclone

This role deploys a one-way (cloud → share) Yandex Disk mirror via `rclone`.
It replaces the `yandex-disk` console daemon, which stopped receiving files
after the October 2026 Yandex datacenter incident (mass HTTP 503 on
downloads). The role mounts an SMB share, installs the upstream rclone
package, writes the lab OAuth application configuration and enables a
systemd timer that runs `rclone sync` on a schedule.

## What it does

- Installs `cifs-utils` from Debian and a pinned `.deb` rclone package
  (`yandex_rclone_deb_url`). Debian 13's own rclone build predates the Yandex
  backend token layout this role writes.
- Writes `/etc/rclone/smbcredentials` (0600, root) and mounts the CIFS share.
- Writes `/etc/rclone/rclone.conf` (0600, service account) with `client_id`,
  `client_secret` and the OAuth token JSON blob. By default the file is only
  seeded when absent (`yandex_rclone_config_overwrite: false`): rclone
  rewrites the token itself on refresh, and overwriting the config with a
  stale refresh token would break authorization.
- Creates `/var/log/rclone` owned by the service account.
- Installs `yandex-rclone.service` (oneshot `rclone sync`,
  `RequiresMountsFor` on the mount point) and `yandex-rclone.timer`
  (recurring runs). The service is enabled to run at boot; the timer is
  enabled and started.

## Requirements

- Target OS: Debian (tested on Debian 13).
- Privileges: `become` to root.
- The service account and group (`yandex`/`nas` in HomeLab) must exist before
  the role — normally created by `base_add_users`.
- The `ansible.posix` collection for the mount module (pinned by the
  project-level `requirements.yml`).
- Secrets in `VARS/secrets.yml`: `vault_yandex_rclone_client_secret`,
  `vault_yandex_rclone_token`, plus the variable named by
  `yandex_rclone_samba_password_var` (the Samba password).

## Managed resources

- Packages: `cifs-utils` (apt), `rclone` (downloaded deb via get_url + apt).
- Files: `/etc/rclone/smbcredentials`, `/etc/rclone/rclone.conf`,
  `/etc/systemd/system/yandex-rclone.service`,
  `/etc/systemd/system/yandex-rclone.timer`, `/var/log/rclone/`, the mount
  point directory.
- Mounts: CIFS `yandex_rclone_mount_source` at `yandex_rclone_mount_point`.
- Services: `yandex-rclone.service` (enabled), `yandex-rclone.timer`
  (enabled, started).
- Handlers: `Reload systemd` on unit file changes.

## Variables

| Variable | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `yandex_rclone_mount_source` | string | yes | `null` | UNC path of the SMB share that becomes the mirror target. |
| `yandex_rclone_samba_password_var` | string | yes | `null` | Name of the secrets.yml variable holding the Samba password. |
| `yandex_rclone_client_id` | string | yes | `null` | OAuth client id of the lab's own Yandex OAuth application. |
| `vault_yandex_rclone_client_secret` | string | yes (secrets.yml) | - | OAuth application secret; keep in secrets.yml only. |
| `vault_yandex_rclone_token` | string | yes (secrets.yml) | - | rclone token JSON blob (`access_token`, `refresh_token`, `expiry`). |
| `yandex_rclone_mount_point` | string | no | `"/mnt/yandex"` | Share mount point. |
| `yandex_rclone_mount_fstype` | string | no | `"cifs"` | Mount filesystem type. |
| `yandex_rclone_smb_version` | string | no | `"3.0"` | Negotiated SMB dialect. |
| `yandex_rclone_credentials_path` | string | no | `"/etc/rclone/smbcredentials"` | mount.cifs credentials file path. |
| `yandex_rclone_samba_username` | string | no | `"yandex"` | Samba account name. |
| `yandex_rclone_samba_domain` | string | no | `"WORKGROUP"` | NetBIOS workgroup. |
| `yandex_rclone_mount_file_mode` | string | no | `"0664"` | File mode presented by the share. |
| `yandex_rclone_mount_dir_mode` | string | no | `"02775"` | Directory mode presented by the share. |
| `yandex_rclone_mount_static_options` | list | no | `["iocharset=utf8","_netdev","nofail"]` | Extra CIFS mount options. |
| `yandex_rclone_service_user` | string | no | `"yandex"` | Service account name. |
| `yandex_rclone_service_group` | string | no | `"nas"` | Service group name. |
| `yandex_rclone_config_dir` | string | no | `"/etc/rclone"` | rclone config directory. |
| `yandex_rclone_config_path` | string | no | `"/etc/rclone/rclone.conf"` | rclone config path. |
| `yandex_rclone_config_overwrite` | bool | no | `false` | Overwrite rclone.conf when it exists. |
| `yandex_rclone_remote_name` | string | no | `"yandex"` | rclone remote section name. |
| `yandex_rclone_deb_url` | string | no | upstream v1.75.2 | rclone .deb download URL. |
| `yandex_rclone_deb_path` | string | no | `"/tmp/rclone-v1.75.2-linux-amd64.deb"` | Local .deb path. |
| `yandex_rclone_apt_packages` | list | no | `["cifs-utils"]` | Packages from Debian. |
| `yandex_rclone_backup_dir` | string | no | `<mount>/.rclone-backup` | Parking dir for files deleted/changed in the cloud. |
| `yandex_rclone_excludes` | list | no | `["/.rclone-backup/**","/.sync/**"]` | Sync exclusion patterns. |
| `yandex_rclone_transfers` | int | no | `4` | Parallel transfers. |
| `yandex_rclone_checkers` | int | no | `8` | Parallel checkers. |
| `yandex_rclone_buffer_size` | string | no | `"8M"` | Per-transfer buffer size. |
| `yandex_rclone_contimeout` | string | no | `"15s"` | Connect timeout. |
| `yandex_rclone_timeout` | string | no | `"45s"` | Transfer idle timeout. |
| `yandex_rclone_retries` | int | no | `2` | Whole-operation retries. |
| `yandex_rclone_low_level_retries` | int | no | `3` | Per-request retries. |
| `yandex_rclone_log_dir` | string | no | `"/var/log/rclone"` | Log directory. |
| `yandex_rclone_log_file` | string | no | `<log_dir>/sync.log` | Sync log file. |
| `yandex_rclone_log_level` | string | no | `"INFO"` | rclone log level. |
| `yandex_rclone_service_name` | string | no | `"yandex-rclone"` | Base name of the units. |
| `yandex_rclone_service_enabled` | bool | no | `true` | Enable service at boot. |
| `yandex_rclone_timer_enabled` | bool | no | `true` | Enable and start the timer. |
| `yandex_rclone_timer_oncalendar` | string | no | `"hourly"` | Timer schedule. |
| `yandex_rclone_timer_randomized_sec` | int | no | `300` | Timer random delay. |
| `yandex_rclone_binary_path` | string | no | `"/usr/bin/rclone"` | rclone binary path. |
| `yandex_rclone_debug_mode` | bool | no | `false` | Debug output for changes. |

## Usage

```yaml
---
- name: Configure the Yandex Disk mirror
  hosts: yandex
  become: true
  vars_files:
    - ../VARS/secrets.yml
  roles:
    - role: yandex_rclone
      vars:
        yandex_rclone_mount_source: "//172.25.40.44/yandex"
        yandex_rclone_samba_password_var: "nas_server_samba_password"
        yandex_rclone_client_id: "<lab-oauth-app-client-id>"
```

## Check mode and diff mode

The role supports `--check --diff`. Secret-writing tasks use `no_log: true`
and `diff: false`, so diff never shows the contents of smbcredentials or
rclone.conf. In check mode `ansible.builtin.apt deb=` may not predict the
change precisely; `ansible.posix.mount` does not perform the actual mount in
check mode.

## Dependencies

- The `ansible.posix` collection (`mount` module).
- `base_add_users` for the service account and group before this role.

## Notes

- `rclone sync` mirrors the cloud one way: files deleted in the cloud are
  moved into `yandex_rclone_backup_dir` rather than deleted outright.
- The rclone token is obtained interactively (`rclone authorize yandex
  <id> <secret>` or the manual `oauth.yandex.ru/verification_code` code
  exchange) and stored as a single JSON blob in
  `vault_yandex_rclone_token`. The access token lives about a year; the
  refresh token renews it automatically.
- After the October 2026 Yandex datacenter incident some files live on
  unavailable storage nodes and cannot be downloaded by any client. The
  short `yandex_rclone_contimeout`/`yandex_rclone_timeout` keep a run from
  stalling; unreachable files arrive in later passes as Yandex restores
  them.
