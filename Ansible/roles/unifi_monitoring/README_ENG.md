# unifi_monitoring

Installs one script and one `UserParameter` on a self-hosted UniFi controller so the Zabbix
agent already running there answers with the controller's entire device inventory as JSON.

Runs **on the controller host**, after `zabbix_agent`.

## Why not poll the devices, and why not the API

UniFi access points and switches answer nothing on SNMP. Ubiquiti removed the setting from
UniFi Network — on 10.4.57 it does not exist — and because the devices take their whole
configuration from the controller, enabling `snmpd` on each one by hand is overwritten at
the next provision. Verified by probe: they are silent on 161 even from their own L2.

The controller's own API works, but it authenticates a **local** administrator, and a
Ubiquiti SSO account cannot stand in: it answers `api.err.Ubic2faTokenRequired`, and nothing
in an unattended poll can satisfy two-factor. That leaves the deployment blocked on a manual
step in a web interface.

The database behind the controller has no such requirement. It listens on `127.0.0.1:27117`
without authentication, so running the query **on the controller host** is the entire
authorisation story — which is why this is a role for that host and not an HTTP template.

## What it gives, and what it does not

From `ace.device`: name, address, MAC, model, type, firmware version, required version,
serial, adopted, internet, unsupported, end-of-life, `last_seen`, `connected_at`,
`disconnected_at`, `provisioned_at`.

There is **no live telemetry**: CPU, memory, uptime as the device reports it, and the client
count are not written to the database at all. They exist only in the controller's memory and
come out through the API. If those matter, create the local account and use
`UniFi Device by HTTP` instead — both templates can coexist.

Connection state is not stored either; it is derived. The controller keeps the two
timestamps it follows from, and the later one wins: a device reconnected after a drop has
`connected_at` newer than `disconnected_at`.

## The trap worth knowing

`mongosh` is a Node program. It chdirs into the working directory and wants a writable
`HOME`, and the Zabbix agent runs as a system user that may be able to do neither. Node then
dies with `EACCES` before a single query goes out. The script sets both itself rather than
inheriting whatever the caller had — root proving the command works proves nothing about the
agent, which is why `unifi_monitoring_verify` runs the finished script **as the agent user**.

## Variables

| Variable | Default | Meaning |
|---|---|---|
| `unifi_monitoring_mongosh_path` | `/usr/bin/mongosh` | Shipped with the controller package |
| `unifi_monitoring_mongo_port` | `27117` | Loopback-only port of the bundled MongoDB |
| `unifi_monitoring_mongo_database` | `ace` | Where the controller keeps its inventory |
| `unifi_monitoring_script_path` | `/usr/local/bin/unifi_facts.sh` | Collector |
| `unifi_monitoring_userparameter_path` | `/etc/zabbix/zabbix_agent2.d/20-unifi.conf` | Numbered after the `zabbix_agent` drop-in |
| `unifi_monitoring_item_key` | `unifi.devices` | Must match the template's master item |
| `unifi_monitoring_agent_user` | `zabbix` | Who the verification runs as |
| `unifi_monitoring_verify` | `true` | Check the agent user really gets data |

## The template that consumes it

`UniFi devices by controller DB`, in the `zabbix_server` role's `files/`, imported from Git
like every other custom template. One agent item returns the whole inventory; a dependent
discovery rule creates the per-device items, so one database query per interval covers the
fleet however large it grows.

Link it to the **controller host**, not to the devices. The devices stay as their own hosts
with `ICMP Ping` on them: reachability belongs to the device's own address, and everything
else is what the controller knows about it.
