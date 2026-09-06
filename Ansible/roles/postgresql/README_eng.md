# postgresql

## The cluster must not land on the container disk

`postgresql_data_root` is where every cluster of the host lives, and on Debian it is also
the home of the `postgres` user. In this project it is a bind mount of a ZFS dataset from
the hypervisor, so the database does not consume the container root disk and survives the
container itself.

That intent fails silently. If the bind mount is missing from the container definition, or
the hypervisor path did not exist when the container started, the path is simply an
ordinary directory on the root disk — and PostgreSQL initialises into it without a word.
Everything looks correct until the 8 GB root disk fills and the server stops mid-write.

The role therefore checks twice:

- before installing the server, that `postgresql_data_root` is on a different filesystem
  than `/` (`postgresql_require_separate_filesystem`, default true);
- after installation, that the cluster the distribution created really sits under that
  root, read back from `pg_lsclusters` rather than assumed.

## Order of installation

`postgresql-common` is installed on its own first. It creates the `postgres` system user
without creating a cluster, which lets the data directory be handed over before anything
initialises inside it. Installing the server in the same step would run `initdb` against a
directory still owned by root.

## Settings go in a drop-in, authentication does not

Tuning is written to `conf.d/10-ansible.conf`. `postgresql.conf` belongs to the Debian
packaging: it carries the defaults of the running version and is rewritten on upgrades, so
owning it would mean fighting the package on every release. Debian ships
`include_dir = 'conf.d'` for exactly this, and the drop-in is applied after the main file,
so a setting here always wins.

`pg_hba.conf` has no such mechanism, so the role writes it whole from
`postgresql_hba_entries`. The defaults cover only local and loopback access; add the
networks that need to reach the server. Order is significant — the **first** matching line
decides, and a broad rule placed early silently disables everything below it.

## Passwords

Role passwords are given as `password_var`, the *name* of a variable holding the value,
resolved when the role runs. This keeps secrets out of `host_vars` and matches
`password_hash_var` in `base_add_users` and `password_var` in `nas_server`.

## full_page_writes on ZFS

The option can safely be turned off when the data directory is on ZFS: the filesystem never
writes a block in place, so a torn page cannot occur, and disabling it removes a large
amount of WAL traffic. It stays on by default because the role cannot verify the filesystem
of every future host. Set `postgresql_full_page_writes: false` per host when the storage is
known to be ZFS.
