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

## Version choice is constrained by the distribution

Zabbix ships `X.0` releases as long term support and everything else for about six months.
The repository does not offer every release for every Debian: at the time of writing 7.0
LTS has no packages for Debian 13 at all, while 8.0 LTS does. Check the repository before
pinning a version, rather than assuming the newest LTS covers the newest Debian.

## Pollers do not fail, they delay

Too few pollers never produce an error. The queue backs up, every check on every host is
served late, and hosts start reporting as unavailable in waves — which reads as a flapping
network rather than as a capacity limit. Size `zabbix_server_start_pollers` for the fleet
and revisit it when the fleet grows.
