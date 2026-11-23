# asterisk

The role installs the Asterisk SIP server from the Sangoma FreePBX package
repository (Debian ships no `asterisk` package since bookworm, see Debian bug
1031046) and
minimally manages its configuration through templates. In the project this is
the LXC `asterisk` (`172.30.150.41`) in the CAM network on pve-nvr — the
doorphone SIP server: pfSense forwards signaling `5060–5061` TCP/UDP and
media `10000–20000` UDP to it from the WAN3 interface (the doorphone
provider), and Asterisk answers the calls and routes them to internal phones.

## What it does

- Checks that the target is Debian, that at least one endpoint with `name`
  and `context` is defined and that at least one dialplan context carries
  `extensions` with `exten`, `priority` and `app`.
- Registers the Sangoma FreePBX APT repository (key from
  `deb.freepbx.org/gpg/aptly-pubkey.asc`, stored under
  `/etc/apt/keyrings/sangoma.asc`).
- Creates the `asterisk` system user and group expected by the packages.
- Installs the `asterisk22` package set.
- Renders `/etc/asterisk/pjsip.conf` from a template: transport sections
  (UDP/TCP with optional `external_signaling_address`,
  `external_media_address` and `local_net` for operation behind NAT) and a
  set of `endpoint`, `auth`, `aor`, `identify` and `registration` sections
  per `asterisk_endpoints` item.
- Renders `/etc/asterisk/rtp.conf` with the media port range.
- Renders `/etc/asterisk/extensions.conf` with the contexts from
  `asterisk_dialplan`.
- Manages the `asterisk` service (enabled at boot, steady state
  `started`/`stopped`).

## Limitations

- The role **does not configure NAT or the firewall on pfSense**. The
  `5060–5061 TCP/UDP` and `10000–20000 UDP` port-forward from WAN3 to
  `172.30.150.41` and the WAN3 rules are a mandatory external requirement
  described in `Docs/04_firewall_nat_security.md` (§3 "WAN3", §6 "Port
  Forward WAN3 → Asterisk").
- The role does not set up SIP-TLS (5061): certificates and the TLS
  transport are not managed, so the forwarded 5061 port stays unused until
  TLS is configured otherwise.
- The role owns three configuration files entirely; the rest of
  `/etc/asterisk` stays at the package state. Other sections (`[general]` of
  pjsip, modules.conf and so on) are not managed.
- The container's network identity (IP, gateway, DNS) lives in the inventory
  (`hosts.yml`), not in role variables.

## Requirements

- Target OS: Debian 12 (bookworm); the Sangoma `freepbx17-prod` repository
  only publishes a bookworm suite. Debian itself carries no `asterisk`
  package since bookworm.
- Privileges: `become: true`.
- Secrets: the playbook includes `VARS/secrets.yml` through `vars_files`;
  the role does not load the secrets file itself.
- Network: pfSense with the port-forward and WAN3 rules configured (see
  limitations).

## Managed resources

- Packages: `asterisk`.
- Files: `/etc/asterisk/pjsip.conf` (0640, root:asterisk);
  `/etc/asterisk/extensions.conf` (0640, root:asterisk);
  `/etc/asterisk/rtp.conf` (0640, root:asterisk).
- Services: `asterisk`.
- Users/groups: `asterisk` system user and group (created by the role)
- Firewall/API objects: none

## Variables

| Variable | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `asterisk_sip_port` | integer | no | `5060` | Bind port of the SIP transports on all addresses. |
| `asterisk_transports` | list of strings | no | `["udp", "tcp"]` | Protocols a transport section is rendered for: `udp`, `tcp`. |
| `asterisk_external_address` | string or null | no | `null` | Address advertised in SIP/SDP when behind NAT; normally the WAN3 address of pfSense. |
| `asterisk_local_nets` | list of strings | no | `[]` | Internal networks (one `local_net` line each) that get the real server address. |
| `asterisk_rtp_port_start` | integer | no | `10000` | First port of the RTP media range. |
| `asterisk_rtp_port_end` | integer | no | `20000` | Last port of the RTP media range. |
| `asterisk_endpoints` | list of dicts | yes | `[]` | Endpoint/trunk definitions (see below); at least one item or `assert` fails. |
| `asterisk_dialplan` | list of dicts | yes | `[]` | Dialplan contexts (see below); at least one item or `assert` fails. |
| `asterisk_service_name` | string | no | `"asterisk"` | Managed service name. |
| `asterisk_service_state` | string | no | `"started"` | Steady service state: `started` or `stopped`. |
| `asterisk_service_enabled` | boolean | no | `true` | Start the service at boot. |
| `asterisk_config_dir` | string | no | `"/etc/asterisk"` | Internal. Configuration directory. |
| `asterisk_unit_path` | string | no | `"/lib/systemd/system/asterisk.service"` | Internal. Unit path; checked before the service is managed. |
| `asterisk_user` | string | no | `"asterisk"` | Internal. Daemon user; created before the package install as documented by Sangoma. |
| `asterisk_group` | string | no | `"asterisk"` | Internal. Daemon group the configuration files are readable to. |
| `asterisk_repository_url` | string | no | `"http://deb.freepbx.org/freepbx17-prod"` | Sangoma FreePBX APT repository; Debian ships no asterisk package since bookworm (bug 1031046). |
| `asterisk_repository_suite` | string | no | `"bookworm"` | Distribution suite of the Sangoma repository (FreePBX 17 targets Debian 12). |
| `asterisk_repository_component` | string | no | `"main"` | Repository component. |
| `asterisk_repository_arch` | string | no | `"amd64"` | Repository architecture. |
| `asterisk_repository_key_url` | string | no | `"http://deb.freepbx.org/gpg/aptly-pubkey.asc"` | Sangoma signing key URL; fingerprint `991C 357C 8A35 9D03 82BC 6E87 C4DF E68F CE6D E186`. |
| `asterisk_keyring_directory` | string | no | `"/etc/apt/keyrings"` | Directory holding the repository signing key. |
| `asterisk_keyring_file` | string | no | `"sangoma.asc"` | ASCII-armored keyring file used via `signed-by`. |
| `asterisk_prerequisite_packages` | list of strings | no | `["ca-certificates", "python3-apt"]` | Packages needed before the signed repository can be used. |
| `asterisk_packages` | list of strings | no | `["asterisk22", "asterisk22-core", "asterisk22-configs"]` | Internal. Packages installed by the role; Sangoma names builds `asterisk<major>`. |
| `asterisk_debug_mode` | boolean | no | `false` | Enable debug output after significant changes. |

### Endpoint fields (`asterisk_endpoints`)

| Key | Type | Required | Description |
| --- | --- | --- | --- |
| `name` | string | yes | Name shared by the `endpoint`, `auth`, `aor` and `identify` sections. |
| `context` | string | yes | Dialplan context inbound calls enter. |
| `allowed_codecs` | list of strings | no | Codecs; defaults to `ulaw`, `alaw`. |
| `direct_media` | boolean | no | Let endpoints exchange media directly. |
| `auth_username` | string | no | Enables a `type = auth` section (userpass); requires `auth_password_var`. |
| `auth_password_var` | string | yes with `auth_username` | Name of the variable holding the SIP secret (conventionally `vault_asterisk_<endpoint>_password` from `VARS/secrets.yml`). A plain `auth_password` is rejected by `assert`. |
| `aors` | list of strings | no | Static `contact` URIs; with `auth_username` and an empty list an empty `aor` section is written for registrations to this server. |
| `identify_matches` | list of strings | no | IPs/CIDRs whose inbound signaling is matched to this endpoint without auth (trunk by source IP). |
| `registration` | dict | no | `server_uri`, `client_uri`, optional `retry_interval` — an outbound registration section. |
| `extra` | dict | no | Additional endpoint options, e.g. `force_rport`, `rtp_symmetric`, `rewrite_contact` for operation behind NAT. |

### Dialplan fields (`asterisk_dialplan`)

| Key | Type | Required | Description |
| --- | --- | --- | --- |
| `context` | string | yes | Context name `[context]`. |
| `extensions` | list of dicts | yes | Lines `exten = <exten>,<priority>,<app>`: `exten`, `priority` and `app` are required. |

### Secrets (VARS/secrets.yml, no defaults)

- `vault_asterisk_<endpoint>_password` — the endpoint SIP secret; its
  variable name is passed via `auth_password_var`.

The `pjsip.conf` task runs with `no_log: true` and `diff: false`, the file
mode is `0640` readable by the `asterisk` group; secret values never appear
in logs, diff or debug output.

## Usage

```yaml
---
- name: Run asterisk
  hosts: asterisk
  become: true
  vars_files:
    - ../VARS/secrets.yml
  roles:
    - role: asterisk
      vars:
        asterisk_external_address: "10.x.x.x"   # WAN3 address on pfSense
        asterisk_local_nets:
          - "172.30.150.0/24"
        asterisk_endpoints:
          - name: "doorphone"
            context: "doorphone-in"
            identify_matches:
              - "10.x.x.x"                      # doorphone network on WAN3
            extra:
              force_rport: "yes"
              rtp_symmetric: "yes"
              rewrite_contact: "yes"
          - name: "house-phone"
            context: "internal"
            auth_username: "phone1"
            auth_password_var: "vault_asterisk_house_phone_password"
        asterisk_dialplan:
          - context: "doorphone-in"
            extensions:
              - exten: "s"
                priority: 1
                app: "Answer"
              - exten: "s"
                priority: 2
                app: "Dial(PJSIP/house-phone,20)"
              - exten: "s"
                priority: 3
                app: "Hangup"
          - context: "internal"
            extensions:
              - exten: "_X."
                priority: 1
                app: "Hangup"
        asterisk_debug_mode: true
```

## Handlers

- `Restart Asterisk` — a full restart after a `pjsip.conf` or `rtp.conf`
  change; skipped when `asterisk_service_state` is not `started`.
- `Reload Asterisk` — `asterisk -rx 'core reload'` after an
  `extensions.conf` change; skipped when `asterisk_service_state` is not
  `started`.

> Two handlers are used on purpose: transport binds and the media port range
> are only read at daemon start — `core reload` would silently leave them
> unchanged, so `pjsip.conf` and `rtp.conf` go through a restart. The
> dialplan is re-read on the fly by `core reload`, and calls in progress
> survive.

## Tags

- `debug` — the summary debug task; disable with `--skip-tags debug`.

## Templates

- `pjsip.conf.j2` — `transport` sections per `asterisk_transports` and an
  `endpoint`/`auth`/`aor`/`identify`/`registration` set per
  `asterisk_endpoints` item.
- `extensions.conf.j2` — a `[general]` header and one context per
  `asterisk_dialplan` item.
- `rtp.conf.j2` — the `rtpstart`/`rtpend` range.

## Check mode and diff mode

The role runs as:

```bash
ansible-playbook playbook.yml --check --diff
```

Honest limitations:

- The service task is skipped when the `asterisk.service` unit is missing —
  on a fresh host in check mode the package is not installed and systemd has
  nothing to manage.
- The `pjsip.conf` diff is hidden (`diff: false`) because the file contains
  SIP secrets; the fact of change is still visible.
- The `Reload Asterisk` handler uses `ansible.builtin.command` and does not
  run in check mode (handlers only run on notify anyway).
- The secret resolution task is hidden by `no_log` and shows nothing.
- The package and the `extensions.conf`/`rtp.conf` template tasks fully
  support `--check --diff`.

## Dependencies

- None

## Notes

- Project ports: SIP `5060–5061` TCP/UDP, RTP `10000–20000` UDP
  (`Docs/06_services_catalog.md` §4.3, `Docs/04_firewall_nat_security.md`
  §6).
- For an endpoint behind NAT the `extra` options are useful:
  `force_rport: "yes"`, `rtp_symmetric: "yes"`, `rewrite_contact: "yes"` —
  depending on the doorphone side.
- Without `asterisk_external_address` Asterisk advertises its CAM address in
  SDP, which the doorphone on WAN3 cannot reach; set the variable for a trunk
  behind NAT.
- The rendered configuration syntax is validated by the first real run
  (`asterisk -rx 'core show config'` or a service failure); the role performs
  no separate configuration validation.
