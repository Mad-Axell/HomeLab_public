# vpn_adguard

The role installs the official AdGuard VPN CLI client into a Debian container,
brings its configuration to a state suitable for unattended operation and
prepares the container to act as an egress gateway for other hosts on the
network.

AdGuard VPN is an egress tunnel to AdGuard servers. The role does not run a VPN
server and does not accept inbound connections from remote clients: remote
access into the lab requires a separate service.

## What it does

- Asserts that the target system is Debian and that `/dev/net/tun` is available
  inside the container; TUN mode does not work without that device.
- Installs `ca-certificates` and `curl`, plus `nftables` when the gateway part
  is enabled.
- Downloads the official install script to a file and runs it non-interactively
  (`-a y`) instead of piping `curl` straight into `sh`.
- Installs the client only when it is missing, or when `vpn_adguard_version` is
  set and the installed version does not match it.
- Applies the client settings: operating mode, TUN routing mode, the ban on
  rewriting the system resolver, the tunnel DNS server and the suppression of
  interactive hints.
- When the gateway part is enabled, turns on `net.ipv4.ip_forward`, writes an
  nftables masquerade table for the given subnets and includes it from
  `/etc/nftables.conf`.
- Creates a systemd unit that raises the tunnel at boot and, after connect,
  restores the routes of the subnets that must stay off the tunnel.

## Limitations

- The role **does not log in to an AdGuard account**. The official client
  authenticates interactively (credentials or a browser link), so
  `adguardvpn-cli login` is performed manually once before the tunnel service is
  first started. Until the login is done, `connect` fails and the unit enters
  `failed`.
- The role does not restrict forwarding: masquerading applies only to the
  subnets in `vpn_adguard_lan_subnets`, but forwarding itself is allowed by the
  default kernel policy. Filtering is the job of the upstream firewall.
- The client stores its configuration and session per user. The role runs and
  installs the unit as `root`, so the login must also be performed as `root`.

## Requirements

- Ansible: the `ansible.posix` collection (the `sysctl` module), pinned in the
  project-level `requirements.yml`.
- Target OS: Debian.
- Privileges: `become: true`.
- Container: in an unprivileged LXC the `/dev/net/tun` device must be bound from
  the host, otherwise the role stops at the `assert`.
- Network: access to `raw.githubusercontent.com` to download the install script
  and to the AdGuard servers for the tunnel itself.

## Managed resources

- Packages: `ca-certificates`, `curl`; `nftables` when
  `vpn_adguard_gateway_enabled: true`.
- Files: `vpn_adguard_installer_path`; the files the vendor installer creates in
  `/opt/adguardvpn_cli` and the symlink in `/usr/local/bin`;
  `/etc/sysctl.d/99-vpn-adguard-forward.conf`;
  `/etc/nftables.d/vpn-adguard.nft`; a managed block in `/etc/nftables.conf`;
  `/etc/systemd/system/<vpn_adguard_service_name>.service`.
- Services: `nftables` when the gateway part is enabled;
  `<vpn_adguard_service_name>`.
- Users/groups: none
- Firewall/API objects: the nftables table `ip vpn_adguard_nat` with a
  `postrouting` chain.

## Variables

| Variable | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `vpn_adguard_installer_url` | string | no | official release channel URL | Install script URL; the path segment selects the channel. |
| `vpn_adguard_installer_path` | string | no | `"/usr/local/src/adguardvpn-cli-install.sh"` | Where the install script is downloaded to. |
| `vpn_adguard_install_parent_directory` | string | no | `"/opt"` | Directory passed to the installer with `-o`. |
| `vpn_adguard_version` | string or null | no | `null` | Version pin passed with `-V`; `null` installs the latest build. |
| `vpn_adguard_mode` | string | no | `"TUN"` | Client mode: `TUN` or `SOCKS`. |
| `vpn_adguard_tun_routing_mode` | string | no | `"AUTO"` | TUN routing mode: `NONE`, `AUTO` or `SCRIPT`. |
| `vpn_adguard_dns_server` | string or null | no | `null` | Tunnel DNS server; `null` keeps the client default. |
| `vpn_adguard_change_system_dns` | string | no | `"off"` | Allow the client to rewrite the system resolver: `on` or `off`. |
| `vpn_adguard_show_hints` | string | no | `"off"` | Interactive client hints: `on` or `off`. |
| `vpn_adguard_location` | string or null | no | `null` | Location for `connect -l`; `null` uses the fastest or last one. |
| `vpn_adguard_service_name` | string | no | `"adguardvpn-tunnel"` | Name of the systemd unit the role creates. |
| `vpn_adguard_service_state` | string | no | `"started"` | Steady service state: `started` or `stopped`. |
| `vpn_adguard_service_enabled` | boolean | no | `true` | Start the tunnel service on boot. |
| `vpn_adguard_gateway_enabled` | boolean | no | `true` | Prepare the container to act as a gateway. |
| `vpn_adguard_lan_subnets` | list of strings | yes when the gateway is enabled | `[]` | Source CIDRs whose traffic is masqueraded into the tunnel. |
| `vpn_adguard_tunnel_interface` | string | no | `"tun0"` | Tunnel interface created by the client. |
| `vpn_adguard_bypass_networks` | list of strings | no | `[]` | CIDRs kept off the tunnel to preserve manageability. |
| `vpn_adguard_bypass_gateway` | string or null | yes when the list above is not empty | `null` | Next hop for the bypass routes. |
| `vpn_adguard_binary_path` | string | no | `"/opt/adguardvpn_cli/adguardvpn-cli"` | Internal. Path of the client executable. |
| `vpn_adguard_ip_command` | string | no | `"/usr/sbin/ip"` | Internal. Path of `ip` used by the bypass routes in the unit. |
| `vpn_adguard_nft_command` | string | no | `"/usr/sbin/nft"` | Internal. Path of `nft` used to validate the ruleset. |
| `vpn_adguard_sysctl_file` | string | no | `"/etc/sysctl.d/99-vpn-adguard-forward.conf"` | Internal. Sysctl file enabling forwarding. |
| `vpn_adguard_nftables_file` | string | no | `"/etc/nftables.d/vpn-adguard.nft"` | Internal. File holding the masquerade table. |
| `vpn_adguard_nftables_main_config` | string | no | `"/etc/nftables.conf"` | Internal. Main nftables configuration. |
| `vpn_adguard_packages` | list of strings | no | `["ca-certificates", "curl"]` | Internal. Packages needed by the installer. |
| `vpn_adguard_gateway_packages` | list of strings | no | `["nftables"]` | Internal. Packages needed only by the gateway part. |
| `vpn_adguard_debug_mode` | boolean | no | `false` | Enable debug output after significant changes. |

The role takes no secrets: AdGuard account credentials are entered manually
during `adguardvpn-cli login` and are not stored in the inventory.

## Usage

```yaml
---
- name: Run vpn_adguard
  hosts: vpn
  become: true
  roles:
    - role: vpn_adguard
      vars:
        vpn_adguard_lan_subnets:
          - "172.20.20.0/24"
        vpn_adguard_bypass_networks:
          - "172.20.10.0/24"
        vpn_adguard_bypass_gateway: "172.25.250.1"
        vpn_adguard_dns_server: "172.25.26.11"
        vpn_adguard_debug_mode: true
```

## Handlers

- `Reload nftables` — reloads the ruleset after the masquerade table or the
  include block changes.
- `Restart AdGuard VPN tunnel` — rebuilds the tunnel after a unit change; it is
  skipped when `vpn_adguard_service_state` is not `started`.

## Tags

- `debug` — the final debug task; disable it with `--skip-tags debug`.

## Templates

- `vpn-adguard.nft.j2` — the `ip vpn_adguard_nat` table. The file starts by
  declaring and deleting the table, so it can be reloaded repeatedly without
  duplicating rules and without touching tables owned by anything else.
- `adguardvpn-tunnel.service.j2` — a `oneshot` unit with `RemainAfterExit`,
  because `connect` daemonises and returns.

## Check mode and diff mode

The role is meant to be run as:

```bash
ansible-playbook playbook.yml --check --diff
```

Honest limitations:

- Installing the client and applying its settings use
  `ansible.builtin.command`, so they do not run in check mode. On a host without
  the client, a check run only reports the package, file and service steps.
- The settings task is additionally guarded by `when: not ansible_check_mode`.
- A configuration change is detected by comparing the output of
  `adguardvpn-cli config show` before and after the settings are applied. If the
  vendor adds volatile fields to that output, the task will start reporting
  `changed` on every run; verify this during the first real run.
- The package, sysctl, template, block and service tasks fully support
  `--check --diff`.

## Dependencies

- The `ansible.posix` collection (the `ansible.posix.sysctl` module), pinned in
  the project-level `requirements.yml`.

## Notes

- First-run order: run the role, then run `adguardvpn-cli login` once inside the
  container, then `systemctl start <vpn_adguard_service_name>` or run the role
  again.
- `vpn_adguard_change_system_dns` defaults to `off` so that the client does not
  rewrite the container `/etc/resolv.conf` and move it away from the project
  resolver.
- `vpn_adguard_bypass_networks` solves a practical problem: with
  `vpn_adguard_tun_routing_mode: AUTO` the client installs the tunnel routes,
  and replies to inbound connections from other subnets may leave through the
  tunnel. After `connect`, the unit returns such subnets to the original
  gateway. Always list here the network you administer the container from,
  except the network it is directly attached to.
- The role does not upgrade the client automatically: without
  `vpn_adguard_version`, the installer runs only when the client is absent. To
  upgrade, set a new `vpn_adguard_version` or run the client's own update
  command.
