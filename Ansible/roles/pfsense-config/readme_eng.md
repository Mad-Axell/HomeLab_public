# pfsense-config (English)

Declaratively brings a **pfSense** router/firewall to a desired state, rebuilt
from variables — **without restoring a config.xml backup**.

## Engine — hybrid

| Concern | Mechanism |
|---|---|
| System (hostname, domain, DNS, time, language) | `pfsensible.core.pfsense_setup` |
| Interfaces (addressing, MAC, MTU, block priv/bogons) | `pfsensible.core.pfsense_interface` |
| Static gateways | `pfsensible.core.pfsense_gateway` |
| Aliases | `pfsensible.core.pfsense_alias` |
| Firewall rules (incl. floating / policy-routing / ports) | `pfsensible.core.pfsense_rule` |
| VLANs on a parent NIC | `pfsensible.core.pfsense_vlan` |
| DHCP **static mappings** (single host list) | `pfsensible.core.pfsense_dhcp_static` |
| DNS Resolver **host overrides** (single host list) | `pfsensible.core.pfsense_dns_resolver` |
| **Force-DNS** NAT redirect → AdGuard | `pfsensible.core.pfsense_nat_port_forward` |
| Dynamic gateway, gateway groups, default gateway | PHP playback `pfsense_gateways.php` |
| DHCP server (kea pools, DNS, enable) | PHP playback `pfsense_dhcp.php` |
| SNMP, Unbound resolver, outbound NAT mode | PHP playback `pfsense_services.php` |
| System tunables + Web GUI presentation | PHP playback `pfsense_advanced.php` |
| GUI TLS certificate (refid kept) + admin bcrypt hash | PHP playback `pfsense_cert_admin.php` |

Settings that have no `pfsensible.core` module are applied by small, idempotent
PHP scripts rendered from Jinja2 and executed with the pfSense `php` interpreter.
Each script compares desired vs. current state, writes the config **only when
something differs**, runs the right `*_configure()` apply function, and prints
`PFSENSE_CHANGED` / `PFSENSE_UNCHANGED` so Ansible reports an accurate
`changed` state.

## Requirements

```bash
ansible-galaxy collection install -r requirements.yml   # pfsensible.core
```

The router must be reachable over SSH by a user with shell access (default
`admin`) and expose Python (`/usr/local/bin/python3.11` on pfSense 24.x).

## Safety switch — check vs enforce

`pfsense_apply` (default `false`):

* `false` — **check-only**. Module tasks run in `check_mode`; PHP scripts run in
  dry-run (compute diff, print `PFSENSE_CHANGED`, do **not** write).
* `true` — **enforce**. Changes are written and applied.

```bash
# Dry run (report drift)
ansible-playbook playbooks/pfsense-config.yml -l pfsense

# Enforce
ansible-playbook playbooks/pfsense-config.yml -l pfsense -e pfsense_apply=true
```

## Tags

`system`, `certificate`, `admin`, `vlans`, `interfaces`, `gateways`, `aliases`,
`rules`/`firewall`, `nat`/`force-dns`, `dhcp`, `static`/`hosts`,
`services`/`snmp`/`unbound`, `dns`/`overrides`, `advanced`, `debug`.

```bash
ansible-playbook playbooks/pfsense-config.yml -l pfsense -e pfsense_apply=true --tags interfaces,rules
# only the single-host-list parts (static mappings + DNS overrides):
ansible-playbook playbooks/pfsense-config.yml -l pfsense -e pfsense_apply=true --tags hosts
```

## Single host list (one source of truth for names)

`pfsense_hosts` is **one list** that the role fans out to BOTH:

* **DHCP static mappings** (`pfsense_dhcp_static`) — for entries that carry a `mac`;
* **DNS Resolver host overrides** (`pfsense_dns_resolver`) — for **every** entry (A + PTR).

Each entry has `name`, `segment`, `ip` and optional `mac`, `descr`, `aliases`,
`static_arp`. `pfsense_segments` maps a `segment` to a pfSense interface id and a
DNS zone. Under the **Kea** backend pfSense has no "Register DHCP static" toggle
in the Resolver, so host overrides are what reliably puts names into DNS — every
host gets a forward/reverse name regardless of the DHCP backend. Add a device in
one place; both its reservation and its DNS name follow.

`pfsense_dns_overrides_extra` holds host overrides not tied to a segment (e.g.
flat service names published by Traefik). **Force-DNS** (`pfsense_force_dns`)
redirects client `:53` to the DNS stack via `pfsense_nat_port_forward`.

## Out of scope — separate playbook

Captive Portal (Guest) and pfBlockerNG-devel have **no** `pfsensible.core` module
and are intentionally **not** in this role. See
`playbooks/pfsense-portal-pfblocker.yml` (package install + a reviewed checklist).

## Variables

* **`defaults/main.yml`** — apply/debug switches, section toggles
  (`pfsense_manage_*`), and empty placeholders.
* **`host_vars/pfsense.yml`** — the actual desired state (system, interfaces,
  gateways, gateway groups, aliases, rules, DHCP, SNMP, Unbound, advanced/webgui).
* **`VARS/secrets.yaml`** — `pfsense_*` secrets: connection user/password, admin
  bcrypt hash, GUI cert (base64 crt/prv + refid), SNMP community.

## Notes on the current router state (kept 1:1)

* Interface **`opt5` (cam_network)** has no `enable` flag in the live config and
  is reproduced **disabled**.
* DHCP pools: `opt5` **enabled**, `opt6` **disabled**, `lan` **enabled** — exactly
  as in the live config (even though `opt5` interface is disabled).
* **SNMP** keeps `rocommunity` but the daemon is **disabled** (no `enable` flag).
* **VLANs 10/20/30** on `igc0` — the role *can* create them (`pfsense_vlan`), but
  `pfsense_vlans` is kept **empty** to match the live flat-LAN state; populate it
  only when migrating TRUST/IoT/Guest (02 §3.1), in a maintenance window.
* GUI **certificate** and **admin** password (bcrypt) are applied **as-is** from
  `secrets.yaml`, preserving the original `refid`.
* Default cron jobs are pfSense built-ins (auto-created) and are not managed here.

## Caveat — interface numbering (greenfield only)

When applied against a **fresh** pfSense, `pfsense_interface` assigns the next
free `optX` slot, so the exact numbers (`opt1/opt5/opt6`) may differ. Against the
existing router (matched by interface description) numbering is preserved. Rules,
gateways and DHCP reference interfaces by their pfSense id as in the live config.
