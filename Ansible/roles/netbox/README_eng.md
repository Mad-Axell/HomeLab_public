# netbox

## Native, not Docker

The repository used to carry `netbox_docker_local`, which dropped a compose file and
started the upstream stack. That stack brings its own PostgreSQL and its own Redis, so on
a host that already runs both it installs a second copy of each, with separate backups,
separate upgrades and separate failure modes. This role uses the ones that exist, and the
Docker role has been removed rather than left as a second way to do the same thing.

## Two services, not one

`netbox` serves requests. `netbox-rq` runs the background queue: webhooks, custom scripts,
housekeeping. Only the first is obvious, and its absence is not: without the worker the
site answers normally, jobs are accepted, and none of them ever run. Both units are
installed and enabled together for that reason.

## The Python floor is checked, not assumed

A NetBox release declares `requires-python`, and 4.6 wants 3.12 or newer — which Debian 12
does not have. Installing there does not fail with a message about the interpreter: pip
gets far enough to build a dependency and reports that dependency instead. The role reads
the interpreter version and refuses up front, naming the real reason.

Raise `netbox_minimum_python` along with `netbox_version` when moving to a release with a
higher floor.

## Upgrades are a symlink

The archive unpacks into `/opt/netbox-<version>` and `/opt/netbox` is a symlink to it, so
moving between releases swaps one link and rolling back swaps it once more. Nothing has to
be deleted to get back to where you were.

`MEDIA_ROOT` deliberately sits outside that tree: uploaded attachments and device images
would otherwise live inside a directory that an upgrade replaces.

## Two Redis databases

NetBox needs two and will not share one. The task queue and the cache have different
lifetimes; clearing the cache would discard queued jobs if they sat on the same number. The
role refuses a configuration that gives both the same value.

## ALLOWED_HOSTS

A request whose `Host` header is not listed is rejected by Django. The symptom is a site
that appears broken rather than an error that points at configuration, so list every name
and address the instance will be reached by, including the bare IP.
