# nas_server

Publishes a declared set of directories over Samba, and optionally NFS, and creates the
Samba accounts that can reach them.

## The role owns smb.conf

`/etc/samba/smb.conf` is written in full from `nas_server_shares` and the global variables.
Local edits are replaced, not merged, and the file is validated with `testparm` before it
is installed.

It deliberately does **not** include the Samba configuration registry. A share created
through Cockpit File Sharing or `net conf` lives in `registry.tdb`, where Ansible cannot
see it, diff it, or restore it — and it stops being published the moment this file is
written without an `include = registry` line. Because that failure is silent, the role
reads the registry and names any share still defined there, so the operator can move it
into the declaration and delete it with `net conf delshare`.

## Shares and accounts are two separate things

Samba keeps its own password database layered on top of the system accounts. A user
created by `base/add_users` still cannot log in until an account exists here as well, and
a share that declares `valid_users` accepts nobody until then. That combination looks like
a working configuration and refuses every login, so the role asserts up front that every
name appearing in `valid_users` or `write_list` has an entry in `nas_server_samba_users`.
Names starting with `@` are groups and are resolved by Samba at connect time.

Passwords are written only for accounts that do not exist yet. Samba owns the database and
a user may have changed the password since — through `smbpasswd` or through the
`unix password sync` this role enables — so forcing the declared value on every run would
silently revert that. `nas_server_samba_force_password: true` resets them deliberately.

## Ownership of the exported directories

The role creates the share directories but does not touch their owner. In this project the
paths are ZFS datasets whose ownership belongs to `pve_storage_zfs`; claiming them here
would make two roles fight over the same attribute on every run.

Use `force_user` and `force_group` on a share to normalise the owner of files written
through it. Without them a shared directory accumulates files owned by whoever wrote them,
and the next user cannot overwrite them.

## Required variables

`nas_server_shares` — list of shares, each with at least `name` and `path`.
`nas_server_samba_users` — accounts, each with `name` and `password`.
NFS additionally requires `nas_server_nfs_clients`.

See `defaults/main.yml` for the full list.
