# redis

## What sharing one instance actually gets you

Several services on one Redis is a cost decision, and it is worth knowing exactly what it
does and does not separate.

**Numbered databases are a naming convention, not a boundary.** Any authenticated client
may `SELECT` any number, and a single `FLUSHALL` empties all of them. `redis_database_allocation`
exists so two services do not silently land on the same number and overwrite each other; it
is rendered into the configuration as comments, and it protects against accidents, not
against a compromised or misconfigured client.

**ACL users give separate credentials, not separate data.** Redis ACL filters commands, key
patterns and channels, and has no concept of a numbered database — a rule like `~netbox:*`
applies in every database at once. Most applications, NetBox included, do not prefix their
keys, so such a rule simply breaks them. Declare users in `redis_acl_users` when you want
to revoke one service's access without changing everyone's password; do not expect them to
keep services out of each other's keys.

If a service genuinely must be isolated, give it its own instance.

## Eviction on a shared instance

`redis_maxmemory_policy` defaults to `noeviction`, which is not the usual answer for a
cache. On a shared instance it is the right one: eviction cannot tell a cache entry from a
queued job. `allkeys-lru` will drop a pending NetBox webhook exactly as readily as a cached
template, and nothing reports the loss — the job is simply never run. With `noeviction` a
write past the limit fails loudly instead, which is recoverable.

Use `allkeys-lru` only on an instance that carries nothing but cache.

Leave memory headroom below the container limit. A background save forks the process, and
copy-on-write makes the copy grow towards the size of the dataset while the save runs, so a
`maxmemory` close to the container's memory turns every save into a possible kill.

## The include goes at the end

The role does not rewrite `/etc/redis/redis.conf`; it appends a single `include` line to
it and owns the included file. That line has to be at the **end**: Redis reads its
configuration top to bottom and applies the last assignment of a directive, so an include
placed at the top — which is where the Debian file shows the example — would be overridden
by every default beneath it, and the role would appear to have no effect.

## Restart, not reload

Redis has no reload that re-reads its configuration file. `CONFIG SET` changes a running
server without touching the file, and `SIGHUP` does nothing, so the handler restarts the
service. On an instance carrying queues, that is a visible interruption; on a cache it is
not.

## Passwords

The password of the default user is given as `redis_requirepass_var`, the *name* of a
variable holding the value, resolved when the role runs, as elsewhere in this repository.
The role refuses to configure a server that binds beyond loopback without one:
`protected-mode` only covers the case of no password *and* no explicit bind, so it stops
protecting anything the moment an address is bound.
