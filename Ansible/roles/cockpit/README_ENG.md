# cockpit

This role installs Cockpit and `cockpit-storaged`, enables socket activation for the web interface, and when `cockpit_45drives_packages` is not empty it configures the 45Drives APT repository and installs extra modules from it (the `cockpit-navigator` file manager by default). Samba/NFS exports remain the responsibility of `nas_server`.

## What it does

- Installs Cockpit and the disk-management interface from configured Debian repositories.
- Enables and starts `cockpit.socket`.
- Downloads the 45Drives signing key to `/usr/share/keyrings/45drives-archive-keyring.gpg`.
- Creates `/etc/apt/sources.list.d/45drives.sources` (deb822, verified via `signed-by` with the key above) and installs the packages in `cockpit_45drives_packages` — by default `cockpit-navigator`, a file manager in the Cockpit web interface.

## Requirements

- Debian/Ubuntu with gathered Ansible facts.
- `become: true`.
- Available, trusted APT repositories that provide the declared packages.
- When `cockpit_45drives_packages` is not empty: outbound HTTPS access to `repo.45drives.com`; Ansible core >= 2.15 (`deb822_repository` module).

## Managed resources

- Packages: `cockpit`, `cockpit-storaged`, plus packages in `cockpit_packages` and `cockpit_45drives_packages`.
- Files: `/usr/share/keyrings/45drives-archive-keyring.gpg`, `/etc/apt/sources.list.d/45drives.sources`, the APT index in `/var/lib/apt/lists`.
- Services: `cockpit.socket`.
- Users/groups, firewall/API objects: not managed. TCP 9090 must be allowed by a separate firewall role.

## Variables

| Variable | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `cockpit_debug_mode` | boolean | no | `false` | Reports whether the role changed anything. |
| `cockpit_packages` | list | no | `['cockpit', 'cockpit-storaged']` | Cockpit packages from configured APT repositories. |
| `cockpit_cache_valid_time` | integer | no | `3600` | APT index cache lifetime in seconds. |
| `cockpit_socket_name` | string | no | `"cockpit.socket"` | Managed systemd socket unit. |
| `cockpit_45drives_packages` | list | no | `['cockpit-navigator']` | Extra Cockpit modules from the 45Drives repository; an empty list disables the repository setup and module installation. |
| `cockpit_45drives_repo_key_url` | string | internal | `"https://repo.45drives.com/key/gpg.asc"` | URL of the 45Drives repository signing key. |
| `cockpit_45drives_repo_key_path` | string | internal | `"/usr/share/keyrings/45drives-archive-keyring.gpg"` | Local path of the signing key file. |
| `cockpit_45drives_repo_uri` | string | internal | `"https://repo.45drives.com/debian"` | APT repository URI. |
| `cockpit_45drives_repo_suites` | list | internal | `['focal']` | 45Drives repository suites. |
| `cockpit_45drives_repo_components` | list | internal | `['main']` | 45Drives repository components. |

## Usage

```yaml
---
- name: Configure Cockpit storage management
  hosts: samba
  become: true
  roles:
    - role: cockpit
```

Without extra 45Drives modules:

```yaml
  roles:
    - role: cockpit
      vars:
        cockpit_45drives_packages: []
```

## Check mode and diff mode

Package installation, `get_url`, `deb822_repository`, and socket management support `--check`; no meaningful content diff is available. The role does not make HTTP health requests or open a firewall port.

## Dependencies

- None.

## Notes

- The 45Drives repository is configured declaratively: the key is fetched over HTTPS with `get_url`, and the source is defined via `deb822_repository` with `signed-by`. The former unverified `curl | bash` setup script is not used.
- The repository suite is `focal`: 45Drives packages are architecture-independent (`all`) and officially support Debian 13/Proxmox trixie.
- `cockpit-navigator` is only a file manager; it does not modify `smb.conf` or affect the shares owned by `nas_server`.
