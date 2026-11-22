# jellyfin

This role installs the Jellyfin media server on a Debian host from the
official `repo.jellyfin.org` APT repository, installs VAAPI hardware
transcoding packages and grants the service account `/dev/dri` access
through device groups.

A native APT install is chosen over Docker: the official Jellyfin repository
is the upstream-supported Debian path and has fewer moving parts inside an
LXC where the service stands alone. Passing `/dev/dri` into the container is
a Proxmox provisioning concern; the role only installs the drivers and adds
the `jellyfin` user to the device groups.

## What it does

- Validates the Debian platform and the input list structure with an early
  `ansible.builtin.assert` before any changes.
- Downloads the armored signing key into `/etc/apt/keyrings/jellyfin.asc` and
  registers the repository `deb [arch=amd64 signed-by=...]
  https://repo.jellyfin.org/debian <release> main` for the current Debian
  release.
- Installs `jellyfin_packages` (the `jellyfin` meta package pulling
  `jellyfin-server`, `jellyfin-web` and `jellyfin-ffmpeg`) and
  `jellyfin_transcoding_packages` (the VAAPI driver and diagnostics).
- Creates the directories listed in `jellyfin_media_dirs` as mount points;
  the bind-mounts and the media itself are provisioning's job, so the role
  does not manage their content or inner permissions.
- Creates the device groups in `jellyfin_device_groups` when missing and
  adds `jellyfin_service_user` to them; a group change restarts the service
  through a handler so the server picks up render access.
- Manages the `jellyfin` service (state and boot enablement).
- Does not manage Jellyfin configuration (`system.xml`, `encoding.xml`,
  libraries, users): selecting VAAPI and the remaining settings happen in
  the admin dashboard and are out of the role scope.

## Requirements

- Target OS: Debian 13 (LXC).
- `become: true` to install packages and manage users.
- Outbound HTTPS access to `repo.jellyfin.org`.
- For hardware transcoding, a `/dev/dri` device passed through by
  provisioning; the role only checks group membership, the device itself is
  not required.

## Managed resources

- Packages: `ca-certificates`, `python3-apt`, `jellyfin_packages`,
  `jellyfin_transcoding_packages`.
- Files: `/etc/apt/keyrings/jellyfin.asc`,
  `/etc/apt/sources.list.d/jellyfin.list`, the `jellyfin_media_dirs`
  directories.
- Services: `jellyfin` (the `jellyfin.service` systemd unit).
- Users/groups: `jellyfin_device_groups` groups (created when missing);
  `jellyfin_service_user` is added to those groups.
- Firewall/API objects: none (Jellyfin listens on port 8096 by default; the
  role does not manage port configuration).

## Variables

| Variable | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `jellyfin_debug_mode` | boolean | no | `false` | Enables debug output after significant changes. |
| `jellyfin_repository_url` | string | no | `"https://repo.jellyfin.org/debian"` | Official Jellyfin APT repository URL. |
| `jellyfin_repository_key_url` | string | no | `"https://repo.jellyfin.org/debian/jellyfin_team.gpg.key"` | URL of the armored repository signing key. |
| `jellyfin_repository_keyring` | string | no | `"/etc/apt/keyrings/jellyfin.asc"` | Local path of the signing key. |
| `jellyfin_repository_filename` | string | no | `"jellyfin"` | APT sources filename under `/etc/apt/sources.list.d`. |
| `jellyfin_repository_component` | string | no | `"main"` | Repository component. |
| `jellyfin_apt_architecture` | string | no | `"amd64"` | APT architecture of the packages. |
| `jellyfin_packages` | list | no | `["jellyfin"]` | Packages installed from the Jellyfin repository. |
| `jellyfin_transcoding_packages` | list | no | `["libva2", "libva-drm2", "mesa-va-drivers", "vainfo"]` | VAAPI drivers and diagnostics; the default targets the AMD iGPU (Ryzen 7 8700G), on Intel override with `intel-media-va-driver`. |
| `jellyfin_service_user` | string | no | `"jellyfin"` | Service account created by the package. |
| `jellyfin_device_groups` | list | no | `["render", "video"]` | Device groups for `/dev/dri` access. |
| `jellyfin_media_dirs` | list | no | `[]` | Media mount-point directories; real paths are private-repo values. |
| `jellyfin_service_name` | string | no | `"jellyfin"` | systemd unit name. |
| `jellyfin_service_state` | string | no | `"started"` | Desired stable state: `started` or `stopped`. |
| `jellyfin_service_enabled` | boolean | no | `true` | Enable the service at boot. |

The role has no secrets and no required variables without defaults.

## Usage

```yaml
---
- name: Deploy Jellyfin
  hosts: jellyfin
  become: true
  roles:
    - role: jellyfin
      vars:
        jellyfin_media_dirs:
          - "/media"
```

## Handlers

- `Restart Jellyfin server` — restarts the service when the service
  account's device groups changed.

## Check mode and diff mode

The role supports:

```bash
ansible-playbook playbook.yml --check --diff
```

On a host where the Jellyfin repository is not registered yet, the package
install task is skipped in check mode: a forecast-only repository cannot be
indexed. Steps depending on the package (the `jellyfin` user, the service)
may produce an imprecise forecast on the first check run; after a real run
check mode reflects the state correctly.

## Dependencies

- None (only `ansible.builtin` modules are used).

## Notes

- VAAPI selection, media libraries, users and network settings are
  configured in the Jellyfin admin dashboard; the role does not manage them.
- The `jellyfin_transcoding_packages` default matches the Ryzen 7 8700G AMD
  iGPU (`mesa-va-drivers`); `vainfo` is kept in the list to verify VAAPI
  manually (run `vainfo` as a user in the `render` group).
- Reruns are idempotent: already installed packages, groups and mount points
  report no changes.
