# yandex_disk

The role deploys the Yandex Disk console client (`yandex-disk`) on Debian:
it registers the vendor's official APT repository, mounts an SMB share as the
local copy of the Disk, writes the client configuration and the OAuth token
file and runs the sync daemon through a systemd unit under a service account.

In the lab the role applies to the `yandex` container on pve-main: the `yandex`
share of the samba container (backed by the `behemoth/yandex` dataset) is
mounted via CIFS at `/mnt/yandex`, and the daemon syncs it with the cloud.

## What it does

- Validates its input (`ansible.builtin.assert`) before the first change.
- Reads the uid/gid of the service account and group via `getent` — the CIFS
  mount options take numbers.
- Downloads the `YANDEX-DISK-KEY.GPG` signing key into `/etc/apt/keyrings/`
  and registers the `repo.yandex.ru/yandex-disk` repository (no `apt-key`).
  The vendor key is ASCII-armored and is stored with the `.asc` extension.
- On Debian 13+ switches apt signature verification from `sqv` to `gpgv`
  (`APT::Key::GPGVCommand`, package `gpgv`, host-wide): `sqv` rejects the
  vendor key's SHA1 binding signature as of 2026-02-01. Disable with
  `yandex_disk_apt_gpgv_fallback: false`.
- Installs the `yandex-disk` and `cifs-utils` packages.
- Writes `/etc/yandex-disk/smbcredentials` (0600, root) — the SMB login and
  password.
- Mounts the share through an `/etc/fstab` entry (`_netdev`, `nofail`,
  uid/gid of the service account).
- Writes `/etc/yandex-disk/config.cfg` (`auth`, `dir`, optional
  `exclude-dirs`).
- Writes `/etc/yandex-disk/passwd` (0600, owned by the service account) with
  the token file content - the single opaque blob that `yandex-disk token`
  generates (the same format as `~/.config/yandex-disk/passwd`).
- Installs the `yandex-disk.service` systemd unit (`Type=forking`,
  `RequiresMountsFor` on the mount point, `Restart=on-failure`) and manages
  its state.

## Requirements

- Target OS: Debian (verified on a Debian 13 LXC on Proxmox).
- `become: true` — the role needs root.
- The service account and its group must exist before the role runs (in this
  project `base_add_users` creates them).
- The SMB share must be reachable during the run; the role does not inspect
  its contents.
- `python3-apt` for `apt_repository` (installed by `base_install_packages` in
  this project).

## Managed resources

- Packages: `yandex-disk`, `cifs-utils` (from `yandex_disk_packages`).
- Files: `/etc/apt/keyrings/yandex-disk.asc`,
  `/etc/apt/sources.list.d/yandex-disk.list`,
  `/etc/apt/apt.conf.d/99-yandex-disk-gpgv` (Debian 13+ only),
  `/etc/yandex-disk/` containing
  `smbcredentials`, `config.cfg`, `passwd`,
  `/etc/systemd/system/yandex-disk.service`.
- Mounts: a CIFS entry in `/etc/fstab` and the mounted
  `yandex_disk_mount_point`.
- Services: `yandex-disk.service` (systemd).
- Users/groups: not created and not modified; the role only reads their ids.

## Variables

| Variable | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `yandex_disk_mount_source` | string | yes | `null` | UNC path of the share (`//host/share`). The role fails on assert without it. |
| `vault_yandex_disk_oauth_token` | string | yes | — | Client token file content (the whole blob). `VARS/secrets.yml` only. |
| `yandex_disk_mount_point` | string | no | `"/mnt/yandex"` | Share mount point. |
| `yandex_disk_samba_username` | string | no | `"yandex"` | SMB account used for the mount. |
| `yandex_disk_samba_password_var` | string | yes | `"yandex_disk_samba_password"` | Name of the variable holding the SMB password; the value is looked up in `VARS/secrets.yml` by name. |
| `yandex_disk_samba_domain` | string | no | `"WORKGROUP"` | Workgroup written to the credentials file. |
| `yandex_disk_mount_fstype` | string | no | `"cifs"` | Mount filesystem type. |
| `yandex_disk_smb_version` | string | no | `"3.0"` | SMB dialect. |
| `yandex_disk_credentials_path` | string | no | `"/etc/yandex-disk/smbcredentials"` | Credentials file read by mount.cifs. |
| `yandex_disk_mount_file_mode` | string | no | `"0664"` | File mode presented by the share. |
| `yandex_disk_mount_dir_mode` | string | no | `"2775"` | Directory mode presented by the share. |
| `yandex_disk_mount_static_options` | list | no | `[iocharset=utf8, _netdev, nofail]` | Static CIFS mount options. |
| `yandex_disk_service_user` | string | no | `"yandex"` | Account the daemon runs as (created outside the role). |
| `yandex_disk_service_group` | string | no | `"nas"` | Daemon group. |
| `yandex_disk_config_dir` | string | no | `"/etc/yandex-disk"` | Configuration directory. |
| `yandex_disk_config_path` | string | no | `"/etc/yandex-disk/config.cfg"` | Path of config.cfg. |
| `yandex_disk_auth_path` | string | no | `"/etc/yandex-disk/passwd"` | OAuth token file (the `auth` key). |
| `yandex_disk_sync_dir` | string | no | mount point | Local copy of the Disk (the `dir` key). |
| `yandex_disk_exclude_dirs` | list | no | `[]` | Directories excluded from sync (`exclude-dirs`). |
| `yandex_disk_service_name` | string | no | `"yandex-disk"` | systemd unit name. |
| `yandex_disk_service_state` | string | no | `"started"` | Steady state (`started`/`stopped`). |
| `yandex_disk_service_enabled` | boolean | no | `true` | Start the unit on boot. |
| `yandex_disk_binary_path` | string | no | `"/usr/bin/yandex-disk"` | Client binary path. |
| `yandex_disk_restart_sec` | int | no | `30` | `RestartSec` of the unit. |
| `yandex_disk_repository_*` | string | no | see defaults | APT repository URL/key/name. |
| `yandex_disk_architecture` | string | no | `"amd64"` | Architecture pinned in the deb line. |
| `yandex_disk_packages` | list | no | `[yandex-disk, cifs-utils]` | Packages to install. |
| `yandex_disk_debug_mode` | boolean | no | `false` | Debug output after significant changes. |

## Usage

```yaml
---
- name: Configure Yandex Disk sync
  hosts: yandex
  become: true
  vars_files:
    - ../VARS/secrets.yml   # vault_yandex_disk_* and the SMB password
  roles:
    - role: yandex_disk
      vars:
        yandex_disk_mount_source: "//172.25.40.44/yandex"
        yandex_disk_samba_password_var: "nas_server_samba_password"
```

The full scenario including LXC provisioning is
`playbooks/lxc.install.yandex_disk.yml` in the private repository.

## Check mode and diff mode

The role supports `--check --diff`: every task either predicts the change or
is marked `no_log`/`diff: false`. `getent` is read-only. Note: on a `--check`
run against a fresh system the mount task relies on uid/gid from `getent`, so
the service account must already exist (in this project `base_add_users`
creates it earlier in the same playbook).

## Dependencies

- Roles: the daemon account and group are expected from `base_add_users`.
- Collections: `ansible.posix` (the `mount` module), pinned in the project-level `requirements.yml`.
- External services: the `repo.yandex.ru` APT repository, an SMB server
  publishing the share.
- Secrets: `vault_yandex_disk_oauth_token` and
  the variable named by `yandex_disk_samba_password_var` — from
  `VARS/secrets.yml` loaded through `vars_files` in the play.

## Handlers

- `Restart yandex-disk` — `daemon_reload` plus a unit restart; fired by
  `notify` from changes to `config.cfg`, `passwd` and the unit file. Skipped
  when `yandex_disk_service_state: "stopped"`.

## Tags

- `debug` — on every debug task (`--skip-tags debug`).

## Notes

- The OAuth token cannot be issued non-interactively: `yandex-disk token`
  asks you to open `https://ya.ru/device` and enter the shown code (valid for
  about 300 seconds). The token file is encrypted against the client's
  per-user iid, so it must be issued on the target host as the service
  account: `sudo -u yandex yandex-disk token`. Copy the whole content of the
  generated `~/.config/yandex-disk/passwd` (a single line) into
  `vault_yandex_disk_oauth_token`. A token issued as a different user or on a
  different machine cannot be decrypted by the daemon and shows up as an
  authorization failure (`User info GET 400` in `.sync/core.log`). Fallback:
  run `yandex-disk token` inside the container as the service account and copy
  the file over `yandex_disk_auth_path`.
- The tasks writing the SMB password and the token run with `no_log: true`
  and `diff: false`; the values must never be printed through debug.
- The daemon is restarted only by the handler on change; the steady state is
  set by `yandex_disk_service_state`.
- `RequiresMountsFor` in the systemd unit guarantees the daemon never starts
  against an empty mount point.
