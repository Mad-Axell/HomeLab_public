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

## The UniFi template, and why it exists

`files/template_unifi_device_by_http.yaml` polls UniFi access points and switches through
the controller API, because the devices themselves cannot be polled at all.

Ubiquiti removed SNMP from the UniFi Network interface — on 10.4.57 the setting does not
exist — and the devices take their configuration from the controller, so enabling `snmpd`
on each one is overwritten at the next provision. Zabbix ships no UniFi template either:
`Ubiquiti AirOS by SNMP` is for the firmware of radio bridges, not for UniFi gear.

The controller authenticates with a session cookie rather than a token: a POST to
`/api/login`, then a GET carrying the cookie. An HTTP agent item cannot carry a cookie
between items, so one **script item** performs both calls and returns the device entry, and
every metric is a dependent item over that single result — one request per interval per
device rather than two per metric.

A Ubiquiti SSO account cannot be used: it answers `api.err.Ubic2faTokenRequired`, because
two-factor is enabled on it and nothing in an unattended poll can satisfy that. Create a
local, non-SSO, read-only admin in the controller and put it in `{$UNIFI.USER}` and
`{$UNIFI.PASSWORD}`.

## Templates are imported from files, and only when they differ

A template imported by hand exists only in the database: not reviewable, not in Git, and
gone with the container. The role imports every file named in
`zabbix_server_custom_templates` on each run, with `updateExisting` on, so editing the file
in Git is what changes the server.

`configuration.import` answers `true` whether or not anything changed, so it cannot report
honestly on its own. The role calls `configuration.importcompare` first and imports only
the files whose diff is non-empty.

Keep template and item descriptions to a **single line**. Zabbix stores multi-line text with
CRLF while the file holds LF, so a multi-line description differs from itself forever and
every run reports a change. Long explanations belong here, in this README, where they can
be read without an API call.
