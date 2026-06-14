# dns_stack_base (English)

Base OS preparation for the adguard container. Runs **first** in the DNS-stack play,
before `unbound` and `adguard_home`. See project doc `05_dns_naming.md` §7–8.

## Responsibilities

- `apt` update, optional `full-upgrade`, install base packages
  (`dnsutils`, `bind9-host`, `curl`, `jq`, …).
- Disable IPv6 via sysctl (when `ipv6_enabled` is false).
- Set timezone and ensure `systemd-timesyncd` is active/enabled — DNSSEC is
  clock-sensitive.
- Set hostname and register the host in `/etc/hosts`.
- **Free port 53**: stop, disable and mask `systemd-resolved`.
- **Protect `/etc/resolv.conf`**: install a dhclient enter-hook that neutralises
  `make_resolv_conf` (in unprivileged LXC `chattr +i` is unavailable). The actual
  switch to `127.0.0.1` is done later by the `adguard_home` role, so apt can reach
  pfSense during bootstrap.

## Layout

```
dns_stack_base/
├── defaults/main.yml      # overridable: packages, full-upgrade, timesync state, debug
├── vars/main.yml          # static: timesync service name, fixed paths, supported OS
└── tasks/
    ├── main.yml           # entry point: assert OS → install → configure → service → debug
    ├── install.yml        # apt update / full-upgrade / base packages
    ├── configure.yml      # IPv6, timezone, hostname/hosts, mask resolved, dhclient hook
    ├── service.yml        # systemd-timesyncd state + systemctl health check (block/rescue)
    └── debug.yml          # bilingual summary under debug_mode
```

## Key variables

| Variable | Default | Meaning |
|---|---|---|
| `dns_stack_base_packages` | list | base packages to install |
| `dns_stack_base_full_upgrade` | `true` | run `apt full-upgrade` on first run |
| `dns_stack_base_timesync_state` | `started` | systemd-timesyncd state |
| `dns_stack_base_timesync_enabled` | `true` | enable timesync on boot |
| `debug_mode` / `debug_lang` / `debug_show_passwords` | `false` / `both` / `false` | debug output controls |

External variables consumed: `ipv6_enabled`, `dns_stack_timezone`, `pve_lxc_name`,
`adguard_ip`, `adguard_fqdn`.

## Tags

`install`, `configure`, `service`, `debug` (plus `always` for the OS assert).
