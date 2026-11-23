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

## The two UniFi templates, and why there are two

UniFi access points and switches cannot be polled at all. Ubiquiti removed SNMP from the
UniFi Network interface — on 10.4.57 the setting does not exist — and the devices take
their configuration from the controller, so enabling `snmpd` on each one is overwritten at
the next provision. Zabbix ships no UniFi template either: `Ubiquiti AirOS by SNMP` is for
the firmware of radio bridges, not for UniFi gear.

Everything therefore comes from the controller, by two different routes. **Both templates
link to the controller host**, not to the devices, and both discover the fleet themselves.

| | `UniFi devices by controller DB` | `UniFi live metrics by HTTP` |
|---|---|---|
| Source | controller's MongoDB on loopback | controller API over HTTPS |
| Credentials | **none** | local controller admin |
| Gives | state, last seen, time since connect, firmware, model, address, adopted, EOL | clients, CPU, memory, device-reported uptime |
| Collector | agent on the controller (`unifi_monitoring` role) | script item on the Zabbix server |

**They share no metric on purpose.** Two records of one fact diverge the moment either
source fails, and the interface then shows two different answers to one question. Anything
the database holds is read from the database; the HTTP template carries only what the
database does not hold at all.

Use the database one alone if that is enough — it needs no account and no firewall opening,
and it keeps working when the API does not. Add the HTTP one when per-AP client counts
matter; that is the metric worth the account.

### What the HTTP template needs

The controller authenticates with a session cookie rather than a token: a POST to
`/api/login`, then a GET carrying the cookie. An HTTP agent item cannot carry a cookie
between items, so one **script item** performs both calls for the whole fleet and every
metric is a dependent item over that single result — one login per interval, not one per
device.

A Ubiquiti SSO account cannot be used: it answers `api.err.Ubic2faTokenRequired`, because
two-factor is enabled on it and nothing in an unattended poll can satisfy that. Create a
local, non-SSO, read-only admin.

Two things outside this role have to be in place, and both fail as an unsupported item
rather than as an obvious misconfiguration:

- **The Zabbix server must reach the controller on its HTTPS port** (8443 by default). The
  controller usually sits in a different segment from the monitoring server, and the rules
  written for agents open only the agent ports there. Check with
  `curl -sk -o /dev/null -w '%{http_code}' https://<controller>:8443/status` **from the
  Zabbix server**, not from a workstation.
- **The account must be local, must exist, and must not be pending a password change.** An
  admin created by another admin carries `requires_new_password` until its owner logs in
  once, and `/api/login` refuses it. `{$UNIFI.PASSWORD}` belongs in a host macro set by
  `zabbix_agent`, never in a template file.

Until both hold, exactly one item is unsupported — `unifi.live` on the controller host —
and the discovery below it finds nothing. Nothing else in the fleet is affected, and no
device host turns red.

## Templates are imported from files, and only when they differ

A template imported by hand exists only in the database: not reviewable, not in Git, and
gone with the container. The role imports every file named in
`zabbix_server_custom_templates` on each run, with `updateExisting` on, so editing the file
in Git is what changes the server.

The import deliberately reports no change, ever. `configuration.import` answers `true`
whether or not anything changed, and `configuration.importcompare` omits `delay` from its
before-snapshot for a script item, so it reports a difference where none exists whatever the
file contains. Neither can tell the truth, so the task says nothing rather than crying wolf
on every run — a permanent `changed` teaches people to stop reading the output. Call
`configuration.importcompare` by hand when you want to see the real difference.

Keep template and item descriptions to a **single line**. Zabbix stores multi-line text with
CRLF while the file holds LF, so a multi-line description differs from itself forever and
every run reports a change. Long explanations belong here, in this README, where they can
be read without an API call.
