# zabbix_server

## The schema is loaded exactly once

Re-running the import against a populated database does not fail cleanly. It applies
partially and leaves a schema that neither the old nor the new version recognises, and the
server then fails to start with an error about a table rather than about the import. The
role guards on the presence of a core table instead of on a marker file, because a marker
file lies as soon as the database is restored from a backup.

## The setup wizard never appears

`zabbix.conf.php` is written before the frontend is first reachable. That file is what the
wizard produces, so writing it in advance means nobody is asked to configure anything by
hand — and a configuration produced by a wizard exists nowhere in this repository, cannot
be reviewed, and is lost with the container.

## The shipped password replaces itself

Zabbix creates `Admin` with the password `zabbix`, which is not a secret in any sense on a
server reachable from the network. The role logs in with the intended password first: on a
server already configured that succeeds and nothing happens. Only a server still holding
the shipped password falls through to changing it. That ordering is what makes the task
idempotent without storing state anywhere.

If neither password is accepted the role fails rather than continuing, because a third
password means someone changed it outside this repository and further automation would be
guessing.

## Debian packages, not the vendor repository

The vendor repository publishes no amd64 packages for Debian 13. Its own sources file says
`Architectures: all`, and `dists/trixie/main/binary-amd64/Packages.gz` is a 404 — the
release exists as an index and as arch-independent files only. Its 7.0 LTS branch has no
trixie suite at all.

Debian 13 meanwhile ships Zabbix 7.0.22: the same LTS line, with Debian security updates
and no third party in the trust path. The role removes the vendor repository if it finds
it, because leaving it configured means apt fetching indexes for packages that are not
there while the real ones come from elsewhere.

There is no version variable for that reason. Pinning one would promise something the
archive cannot deliver.

## The schema is three files, in order

Debian splits what upstream ships as a single file into `schema`, `images` and `data`, and
the split is not cosmetic. `schema` builds the tables, `data` seeds the Admin account and
every stock template, `images` fills the icon tables. Loading only the first leaves a
structurally valid database that nobody can log into and no template can be linked from —
which reads as a broken frontend rather than as an incomplete import.

## Pollers do not fail, they delay

Too few pollers never produce an error. The queue backs up, every check on every host is
served late, and hosts start reporting as unavailable in waves — which reads as a flapping
network rather than as a capacity limit. Size `zabbix_server_start_pollers` for the fleet
and revisit it when the fleet grows.
