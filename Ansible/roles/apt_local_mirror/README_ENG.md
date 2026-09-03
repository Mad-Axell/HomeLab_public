# apt_local_mirror

The role copies a prepared APT repository tree from the Ansible controller to
the target host. It is meant for hosts that cannot reach the upstream
repository: an unreachable source, an isolated segment, or a geo block.

## What it does

- Validates that the source and destination directories are both set.
- Creates the destination directory.
- Copies the repository tree verbatim.

The role signs nothing and rebuilds no indexes: files are transferred as they
are, so the upstream signatures stay valid and APT verifies them normally. The
role does not register the repository either — that belongs to whichever role
declares the APT source and receives a `file://` URI.

## Requirements

- The repository tree already exists on the controller at
  `apt_local_mirror_src` and contains `dists/` and `pool/`.
- `become: true` on the target host.

## Managed resources

- Files: the `apt_local_mirror_dest` directory and the whole tree copied into it.
- Packages: none.
- Services: none.
- Users/groups: none.

## Variables

| Variable | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `apt_local_mirror_src` | string | yes | `null` | Mirror directory on the controller; a trailing slash copies its contents rather than the directory itself. |
| `apt_local_mirror_dest` | string | no | `"/opt/apt-local-mirror"` | Destination directory on the target host. |
| `apt_local_mirror_owner` | string | no | `"root"` | Tree owner. |
| `apt_local_mirror_group` | string | no | `"root"` | Tree group. |
| `apt_local_mirror_directory_mode` | string | no | `"0755"` | Directory mode. |
| `apt_local_mirror_file_mode` | string | no | `"0644"` | File mode. |
| `apt_local_mirror_debug_mode` | boolean | no | `false` | Reports that a change happened. |

## Secret external inputs

The role uses no secrets and does not read `VARS/secrets.yml`.

## Usage

```yaml
---
- name: Deliver a local APT mirror
  hosts: offline_host
  become: true
  roles:
    - role: apt_local_mirror
      vars:
        apt_local_mirror_src: "/home/ansible/mirrors/vendor/"
        apt_local_mirror_dest: "/opt/vendor-mirror"
```

The repository is then registered as usual, for example
`deb [signed-by=/opt/vendor-mirror/vendor.gpg] file:///opt/vendor-mirror/debian <suite> <component>`.

## Check mode and diff mode

`file` and `copy` support `--check --diff` natively. For large trees the diff is
noisy: `copy` compares every file by checksum.

## Dependencies

- None

## Handlers and tags

- Handlers: none.
- Tags: `debug` on the final debug task.
