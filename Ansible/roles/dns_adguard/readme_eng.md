# adguard_home (English)

Installs and configures **AdGuard Home** as the client-facing DNS server of the
stack. It listens on `:53`, applies blocklists, resolves client names via private
PTR, and forwards everything to the local Unbound resolver. See project doc
`05_dns_naming.md` §8 for the architecture.

## Responsibilities

- Download the AdGuard Home release (`latest` or pinned `adguard_version`) and
  register it as a systemd service.
- Render the full declarative `AdGuardHome.yaml` (the role owns the whole file),
  validated with `AdGuardHome --check-config` before activation:
  - upstream `127.0.0.1:{{ dns.unbound_local_port }}` (Unbound);
  - private reverse DNS (`use_private_ptr_resolvers`, `local_ptr_upstreams`);
  - blocklists from `adguard_filters`, DNSSEC, ratelimiting;
  - DHCP disabled (DHCP lives only on pfSense).
- Manage the `AdGuardHome` systemd unit and verify active/enabled.
- After bring-up, wait for `:53` and switch `/etc/resolv.conf` to `127.0.0.1`.

The config template embeds the admin password hash, so the deploy task uses
`no_log: true`, and the debug summary masks the hash unless
`debug_show_passwords: true`.

## Layout

```
adguard_home/
├── defaults/main.yml      # overridable: install dirs, URLs, filters, ratelimit, private nets, debug
├── vars/main.yml          # static: service name, derived paths, supported OS
├── tasks/
│   ├── main.yml           # entry point: assert OS → install → configure → service → debug
│   ├── install.yml        # directories, download/unpack, systemd install
│   ├── configure.yml      # AdGuardHome.yaml template (validated, no_log)
│   ├── service.yml        # systemd state + health check + resolv.conf switch (block/rescue)
│   └── debug.yml          # bilingual summary under debug_mode (password masked)
├── handlers/main.yml      # adguard_restart
└── templates/AdGuardHome.yaml.j2
```

## Key variables

| Variable | Default | Meaning |
|---|---|---|
| `adguard_service_state` | `started` | systemd target state |
| `adguard_service_enabled` | `true` | enable on boot |
| `adguard_install_dir` | `/opt/AdGuardHome` | install directory |
| `adguard_log_dir` | `/var/log/AdGuardHome` | log directory |
| `adguard_ratelimit` | `50` | per-client qps ratelimit |
| `adguard_filters` | 5 lists | blocklists (id/url/name) |
| `adguard_bootstrap_dns` | Quad9/Cloudflare | bootstrap for DoH/DoT upstreams |
| `adguard_private_networks` | RFC1918 | networks for PTR resolution |
| `debug_mode` / `debug_lang` / `debug_show_passwords` | `false` / `both` / `false` | debug output controls |

External variables consumed: `adguard_version`, `adguard_web_port`,
`adguard_admin_user`, `adguard_admin_password_hash`, `adguard_schema_version`,
`dns.unbound_local_port`, `adguard_segment`, `network.base_domain`. Secrets come
from `ansible/VARS/secrets.yaml`.

## Tags

`install`, `configure`, `service`, `debug` (plus `always` for the OS assert).

## Verify

```bash
dig @127.0.0.1 -p 53 +short google.com
dig @127.0.0.1 -p 53 +short doubleclick.net    # blocked → '' or 0.0.0.0
```
