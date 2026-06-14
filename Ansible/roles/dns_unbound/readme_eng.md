# unbound (English)

Installs and configures **Unbound** as the recursive, DNSSEC-validating resolver
of the DNS stack. It is the upstream for AdGuard Home and listens only on
loopback (`127.0.0.1:{{ dns.unbound_local_port }}`). See project doc
`05_dns_naming.md` §7 for the architecture.

## Responsibilities

- Install `unbound` and `unbound-anchor` (Debian/apt).
- Bootstrap the DNSSEC root trust anchor (`root.key`) and root hints, with a
  monthly cron refresh of the hints.
- Render `/etc/unbound/unbound.conf.d/10-server.conf` (validated by
  `unbound-checkconf` before activation):
  - loopback-only listener, IPv4-only by default;
  - DNSSEC hardening, QNAME minimisation, aggressive NSEC;
  - DoS/amplification ratelimits;
  - private-address / private-domain leak protection;
  - one parent **stub-zone** for `*.{{ network.base_domain }}` to pfSense;
  - per-segment **reverse stub-zones** generated strictly as `/24` from
    `segments` (a `/16` delegation would break recursion for neighbour subnets).
- Manage the `unbound` systemd unit and verify it is active/enabled.

## Layout

```
unbound/
├── defaults/main.yml      # overridable: performance, ratelimit, root-hints URL/cron, debug
├── vars/main.yml          # static: service name, packages, fixed paths, supported OS
├── tasks/
│   ├── main.yml           # entry point: assert OS → install → configure → service → debug
│   ├── install.yml        # packages, trust anchor, root hints, cron
│   ├── configure.yml      # 10-server.conf template (validated)
│   ├── service.yml        # systemd state + systemctl health check (block/rescue)
│   └── debug.yml          # bilingual summary under debug_mode
├── handlers/main.yml      # unbound_restart
└── templates/10-server.conf.j2
```

## Key variables

| Variable | Default | Meaning |
|---|---|---|
| `unbound_service_state` | `started` | systemd target state |
| `unbound_service_enabled` | `true` | enable on boot |
| `unbound_num_threads` | `2` | worker threads |
| `unbound_msg_cache_size` | `64m` | message cache |
| `unbound_rrset_cache_size` | `128m` | RRset cache |
| `unbound_ratelimit` | `1000` | global qps ratelimit |
| `unbound_ip_ratelimit` | `200` | per-IP ratelimit |
| `unbound_root_hints_url` | internic named.cache | root hints source |
| `unbound_root_hints_cron` | `17 4 1 * *` | hints refresh schedule |
| `debug_mode` / `debug_lang` / `debug_show_passwords` | `false` / `both` / `false` | debug output controls |

External variables consumed (from inventory/group_vars): `dns.unbound_local_port`,
`network.base_domain`, `pfsense_dns_ip`, `ipv6_enabled`, `segments`.

## Tags

`install`, `configure`, `service`, `debug` (plus `always` for the OS assert).

## Verify

```bash
unbound-checkconf
dig @127.0.0.1 -p {{ dns.unbound_local_port }} +short google.com
dig @127.0.0.1 -p {{ dns.unbound_local_port }} +short pve-router.mgmt.{{ network.base_domain }}
```
