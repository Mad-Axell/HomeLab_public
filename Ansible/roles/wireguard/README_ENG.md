# wireguard

The role brings up an incoming WireGuard remote-access server inside a Debian
container. In the project this is the LXC `vpn` (`172.25.250.2/29`) in the
internal transit segment on `vmbr2` on pve-router: pfSense forwards UDP/51820
to it from WAN1/WAN2, and the tunnel subnet is `10.50.250.0/24` with the
server at `10.50.250.1`.

## What it does

- Checks that the target is Debian, that `/dev/net/tun` is available inside
  the container, that `wireguard_tunnel_address` and
  `wireguard_private_key_var` are set, and that every peer carries `name`,
  `allowed_ips` and `public_key`/`public_key_var`.
- Installs `wireguard-tools` (the `wg` and `wg-quick` utilities). The kernel
  module is provided by the container host, so the `wireguard` metapackage is
  not installed.
- Enables `net.ipv4.ip_forward` through the drop-in
  `/etc/sysctl.d/99-wireguard-forward.conf`.
- Creates `/etc/wireguard` with mode `0700` and renders
  `<wireguard_interface_name>.conf` into it with mode `0600` from a template.
- Manages the `wg-quick@<wireguard_interface_name>` instance (enabled at
  boot, steady state `started`/`stopped`).

## Limitations

- The role does **routing only, no NAT/masquerade** — this is the mandatory
  variant per `Docs/instructions/06_wireguard_vpn.md`: it preserves the real
  client addresses (`10.50.250.x`) in pfSense logs and rules. Return traffic
  is provided by the static route `10.50.250.0/24` via `172.25.250.2` on
  pfSense, which the role does not create.
- The role does not generate client configs or QR codes. Client DNS
  (`172.25.26.11`) and the list of reachable subnets live in the client
  config, not in `wg0.conf`.
- pfSense configuration (UDP/51820 port-forward on WAN1/WAN2, the `WG_LXC`
  gateway, the static route, the `VPN_NET`/`VPN_ADMIN_PEERS` rules on
  LAN_VPN_TRANSIT) is outside the role's scope and described in
  `Docs/instructions/06_wireguard_vpn.md`.
- The peer `group` field (`admin`/`user`) is an informational tag for the
  project peer-group split and the pfSense ACL design (`VPN_ADMIN_PEERS`);
  inside `wg0.conf` it is rendered only as a comment.
- The container's network identity (IP, gateway, DNS) lives in the inventory
  (`hosts.yml`), not in role variables.

## Requirements

- Ansible: the `ansible.posix` collection (the `sysctl` module), pinned in
  the project-level `requirements.yml`.
- Target OS: Debian.
- Privileges: `become: true`.
- Container: the unprivileged LXC must have `/dev/net/tun` available (a bind
  from the host, see `Docs/instructions/06_wireguard_vpn.md` §1) and the
  `wireguard` module loaded on the host (`modprobe wireguard`). Otherwise the
  role stops at `assert`.
- Secrets: the playbook includes `VARS/secrets.yml` through `vars_files`;
  the role does not load the secrets file itself.

## Managed resources

- Packages: `wireguard-tools`.
- Files: `/etc/sysctl.d/99-wireguard-forward.conf`;
  `/etc/wireguard/` (0700);
  `/etc/wireguard/<wireguard_interface_name>.conf` (0600).
- Services: `wg-quick@<wireguard_interface_name>`.
- Users/groups: none
- Firewall/API objects: none (no NAT on the LXC by design)

## Variables

| Variable | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `wireguard_interface_name` | string | no | `"wg0"` | Interface name; selects the `wg-quick@` instance and the config file name. |
| `wireguard_tunnel_address` | string | yes | `null` | Server tunnel address with prefix, e.g. `"10.50.250.1/24"`. The role fails at `assert` when unset. |
| `wireguard_listen_port` | integer | no | `51820` | UDP listen port; this is the port pfSense forwards. |
| `wireguard_peers` | list of dicts | no | `[]` | Peer definitions (see below). An empty list means a server with no clients. |
| `wireguard_private_key_var` | string | yes | `null` | Name of the variable holding the server private key (conventionally `vault_wireguard_server_private_key` from `VARS/secrets.yml`). The role fails at `assert` when unset or undefined. |
| `wireguard_service_state` | string | no | `"started"` | Steady service state: `started` or `stopped`. |
| `wireguard_service_enabled` | boolean | no | `true` | Start `wg-quick@` at boot. |
| `wireguard_config_dir` | string | no | `"/etc/wireguard"` | Internal. Interface configuration directory. |
| `wireguard_sysctl_file` | string | no | `"/etc/sysctl.d/99-wireguard-forward.conf"` | Internal. Drop-in holding the IPv4 forwarding setting. |
| `wireguard_unit_path` | string | no | `"/lib/systemd/system/wg-quick@.service"` | Internal. Template unit path; checked before the service is managed. |
| `wireguard_packages` | list of strings | no | `["wireguard-tools"]` | Internal. Packages installed by the role. |
| `wireguard_debug_mode` | boolean | no | `false` | Enable debug output after significant changes. |

### Peer fields (`wireguard_peers`)

| Key | Type | Required | Description |
| --- | --- | --- | --- |
| `name` | string | yes | Peer name; written as a comment above its `[Peer]` section. |
| `group` | string | no | Informational ACL tag (`admin`, `user`) used to group peer addresses on pfSense; inside the config it is only a comment. |
| `allowed_ips` | list of strings | yes | CIDRs routed to this peer; normally a single `/32` from the tunnel subnet. |
| `public_key` | string | one of two | The peer public key given directly. |
| `public_key_var` | string | one of two | Name of a variable holding the public key, resolved at run time. |
| `preshared_key_var` | string | no | Name of the variable holding the preshared key (conventionally `vault_wireguard_<peer>_preshared_key`). A plain `preshared_key` is rejected by `assert`. |
| `persistent_keepalive` | integer | no | Seconds between keepalive packets (project value: 25). |

### Secrets (VARS/secrets.yml, no defaults)

- `vault_wireguard_server_private_key` — the server private key; its variable
  name is passed via `wireguard_private_key_var`.
- `vault_wireguard_<peer>_public_key` — when `public_key_var` is used.
- `vault_wireguard_<peer>_preshared_key` — when `preshared_key_var` is used.

The `wg0.conf` task runs with `no_log: true` and `diff: false`, the file mode
is `0600`; secret values never appear in logs, diff or debug output.

## Usage

```yaml
---
- name: Run wireguard
  hosts: vpn-wireguard
  become: true
  vars_files:
    - ../VARS/secrets.yml
  roles:
    - role: wireguard
      vars:
        wireguard_tunnel_address: "10.50.250.1/24"
        wireguard_private_key_var: "vault_wireguard_server_private_key"
        wireguard_peers:
          - name: "admin-phone"
            group: "admin"
            public_key_var: "vault_wireguard_admin_phone_public_key"
            preshared_key_var: "vault_wireguard_admin_phone_preshared_key"
            allowed_ips:
              - "10.50.250.2/32"
            persistent_keepalive: 25
          - name: "user-laptop"
            group: "user"
            public_key: "<peer public key>"
            allowed_ips:
              - "10.50.250.3/32"
        wireguard_debug_mode: true
```

## Handlers

- `Restart WireGuard interface` — recreates the tunnel after a `wg0.conf`
  change; skipped when `wireguard_service_state` is not `started`.

> A full restart is used rather than `wg syncconf`: syncconf applies
> additions and changes but **never removes** peers dropped from the
> configuration, so deleted clients would keep their access. The restart
> takes the tunnel down for a moment — an acceptable price for guaranteed
> peer removal.

## Tags

- `debug` — the summary debug task; disable with `--skip-tags debug`.

## Templates

- `wg0.conf.j2` — an `[Interface]` section with address, listen port and the
  private key, plus one `[Peer]` section per `wireguard_peers` item with
  `PublicKey`, optional `PresharedKey`, `AllowedIPs` and
  `PersistentKeepalive`.

## Check mode and diff mode

The role runs as:

```bash
ansible-playbook playbook.yml --check --diff
```

Honest limitations:

- The service task is skipped when the `wg-quick@.service` unit is missing —
  on a fresh host in check mode the package is not installed and systemd has
  nothing to manage. The first real run installs the package and manages the
  service.
- The `wg0.conf` diff is hidden (`diff: false`) because the file contains the
  private and preshared keys; the fact of change is still visible.
- The secret resolution task is hidden by `no_log` and shows nothing.
- The package, sysctl, directory and template tasks fully support
  `--check --diff`.

## Dependencies

- The `ansible.posix` collection (`ansible.posix.sysctl`); pinned in the
  project-level `requirements.yml`.

## Notes

- Project tunnel parameters: server `10.50.250.1/24`, `ListenPort 51820`,
  keepalive 25, client-reachable subnets `172.25.26.0/24, 172.25.40.0/24,
  172.30.150.0/24, 172.20.10.0/24` — these go into client configs
  (`AllowedIPs`), not into the role (`Docs/04_firewall_nat_security.md` §9).
- Companion steps outside the role: the pfSense port-forward, the `WG_LXC`
  gateway and the route to `10.50.250.0/24`, and the `VPN_NET` rules — see
  `Docs/instructions/06_wireguard_vpn.md` §3.
- Container provisioning (timezone, IPv6 disabling, the `/dev/net/tun` bind)
  happens at LXC creation level and is not part of this role.
- Back up `/etc/wireguard/` (the keys!) to a protected location — the role
  does not create backups.
