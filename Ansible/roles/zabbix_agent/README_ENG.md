# zabbix_agent

## Both halves or neither

Installing the agent does not make a host monitored. Until the server holds a host object
pointing at it, nothing is collected and the host is simply invisible — no error, no
warning, just absence. Registering a host without an agent is the mirror image: the host
appears in the interface and every item goes unsupported. The role owns both halves for
that reason.

## Hostname is the join key

`Hostname` in the agent configuration must equal the host name on the server, letter for
letter. Active checks are matched by that string and nothing else.

A mismatch is the worst kind of failure to diagnose, because it looks partial. Passive
checks — the ones the server opens itself, by address — keep working, so the host shows as
available and some data arrives. Everything active stays unsupported, and no message
anywhere connects the two facts. The role derives both from the same variable so they
cannot drift.

## Registration runs from the controller

The API calls are delegated to the controller rather than run on the monitored host. A
monitored machine has no reason to reach the Zabbix API, and handing API credentials to
every machine being watched would invert the point of watching them.

## Templates and groups must already exist

Template names are matched exactly, and a template that does not exist on the server is an
error, not a warning. Host groups are created by the role if missing, because Zabbix
rejects a host with no group at all.

## The drop-in, not the shipped file

Settings are written to `zabbix_agent2.d/`, which the packaged `zabbix_agent2.conf` already
includes. The distribution file is never rewritten, so it keeps whatever the next package
version changes in it.
