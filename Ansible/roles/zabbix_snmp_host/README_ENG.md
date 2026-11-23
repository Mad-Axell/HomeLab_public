# zabbix_snmp_host

## Nothing is installed on the device

A switch or an access point runs firmware that takes no agent, so there is only one half to
manage here: the host object on the server and its SNMP interface. Everything the role does
is an API call delegated to the controller — the device is never touched, and it does not
need to be reachable by Ansible at all, only by the Zabbix server on UDP 161.

## The community goes in a macro, not in the interface

Zabbix lets an SNMP interface carry either a literal community string or a macro reference.
Both poll correctly, and only one of them works.

Every stock SNMP template reads the macro. An interface holding the literal string therefore
answers a manual test perfectly while every templated item stays unsupported — a failure
that looks like the template is wrong rather than like the community is in the wrong place.
The role writes the community into the macro and points the interface at it.

## The address is frozen before the API call

The registration tasks override `ansible_host` in their own vars to aim the httpapi
connection at the Zabbix server. That override shadows `ansible_host` for everything else
evaluated in the same scope, so the polled address is resolved into a fact first. Without
that, every device is registered with the Zabbix server's own address — it registers
cleanly and polls the wrong machine.

## Template names must exist

A template name that the server does not have is an error, not a warning. Check what is
actually installed before declaring one; the stock set is large and the names are specific,
down to the hardware model.
