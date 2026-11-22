# mosquitto

The role installs the Mosquitto MQTT broker from the Debian packages and
configures it entirely through the `/etc/mosquitto/conf.d/90-ansible.conf`
drop-in: listeners, authentication and authorization. It is the central smart
home broker (`172.25.40.155`): its clients are spruthub, Home Assistant,
Frigate and WirenBoard 7.

The target state per hardening plan A-35: a TLS listener on 8883 and
per-client credentials with ACLs; plaintext 1883 is switched off only after
every client has migrated. The role keeps 1883 enabled by default and makes
TLS optional and fully declarative.

## What it does

- Validates the Debian platform, the ports and that at least one listener is
  enabled.
- Requires at least one account when `mosquitto_allow_anonymous: false`, and
  verifies that every `password_var` resolves to a variable from
  `VARS/secrets.yml` - before touching the host.
- With `mosquitto_tls_enabled: true` it asserts that `cafile`/`certfile`/
  `keyfile` are set and exist on the host (certificates are delivered by an
  external CA process).
- Installs the `mosquitto` package.
- Writes the `/etc/mosquitto/conf.d/90-ansible.conf` drop-in: listeners,
  `allow_anonymous`, `password_file`, `acl_file`, `mosquitto_extra_settings`.
- Writes `/etc/mosquitto/acl` from `mosquitto_acl_entries` (or removes the file
  when the list is empty).
- Writes `/etc/mosquitto/passwd.defs` (plaintext `name:password`, `0600 root`)
  and, when it changes, rebuilds `/etc/mosquitto/passwd`: a staged copy hashed
  in place by `mosquitto_passwd -U`. The two-step build makes the run
  idempotent - the broker only ever stores hashed passwords.
- Manages the `mosquitto` service; configuration, ACL and password changes
  restart it through the handler.

## Requirements

- Debian (target platform Debian 13), `become: true`.
- Gathered facts: `ansible_facts.os_family`.
- With `mosquitto_tls_enabled: true` - the certificate files already on the
  host.
- Account passwords live in `VARS/secrets.yml`, loaded by the playbook through
  `vars_files`; the role does not read that file itself.

## Managed resources

- Packages: `mosquitto`.
- Files: `/etc/mosquitto/conf.d/90-ansible.conf`, `/etc/mosquitto/acl`,
  `/etc/mosquitto/passwd.defs`, `/etc/mosquitto/passwd`.
- Services: `mosquitto`.
- Users/groups: none (the package creates the system user).
- Firewall/API objects: none.

## Variables

| Variable | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `mosquitto_debug_mode` | boolean | no | `false` | Summary after significant changes. |
| `mosquitto_packages` | list | no | `["mosquitto"]` | Packages to install. |
| `mosquitto_managed_config` | string | no | `"/etc/mosquitto/conf.d/90-ansible.conf"` | Drop-in the role owns. |
| `mosquitto_password_definitions` | string | no | `"/etc/mosquitto/passwd.defs"` | Plaintext source of the password file (`0600 root`). |
| `mosquitto_password_file` | string | no | `"/etc/mosquitto/passwd"` | Hashed broker `password_file`. |
| `mosquitto_acl_file` | string | no | `"/etc/mosquitto/acl"` | Broker `acl_file`. |
| `mosquitto_listener_enabled` | boolean | no | `true` | Plaintext listener (A-35: off after client migration). |
| `mosquitto_port` | integer | no | `1883` | Plaintext listener port. |
| `mosquitto_listener_address` | string/null | no | `null` | Optional bind address of the plaintext listener. |
| `mosquitto_tls_enabled` | boolean | no | `false` | Enable the TLS listener. |
| `mosquitto_tls_port` | integer | no | `8883` | TLS listener port. |
| `mosquitto_tls_cafile` | string/null | cond. | `null` | CA certificate path on the host; required for TLS. |
| `mosquitto_tls_certfile` | string/null | cond. | `null` | Broker certificate; required for TLS. |
| `mosquitto_tls_keyfile` | string/null | cond. | `null` | Broker private key; required for TLS. |
| `mosquitto_tls_require_certificate` | boolean | no | `false` | Require client certificates on the TLS listener. |
| `mosquitto_allow_anonymous` | boolean | no | `false` | Allow clients without credentials. |
| `mosquitto_users` | list | cond. | `[]` | Accounts `{name, password_var}`; a non-empty list is required when `allow_anonymous: false`. |
| `mosquitto_acl_entries` | list | no | `[]` | ACL `{name, topics}`; a topic is a dict `{access, topic}` or a raw string. |
| `mosquitto_extra_settings` | dict | no | `{}` | Extra `name value` directives in the drop-in. |
| `mosquitto_service_name` | string | no | `"mosquitto"` | systemd service name. |
| `mosquitto_service_state` | string | no | `"started"` | Steady state: `started`/`stopped`. |
| `mosquitto_service_enabled` | boolean | no | `true` | Start at boot. |

Secrets are not declared in defaults. Each `password_var` is the *name* of a
variable (for example `vault_mosquitto_spruthub_password`) provided by
`VARS/secrets.yml`; the role resolves it at run time through
`lookup('ansible.builtin.vars', ...)`.

## Usage

```yaml
---
- name: Run the central MQTT broker
  hosts: mosquitto
  become: true
  vars_files:
    - ../VARS/secrets.yml
  roles:
    - role: mosquitto
      vars:
        mosquitto_users:
          - name: "spruthub"
            password_var: "vault_mosquitto_spruthub_password"
          - name: "homeassistant"
            password_var: "vault_mosquitto_homeassistant_password"
          - name: "wirenboard"
            password_var: "vault_mosquitto_wirenboard_password"
        mosquitto_acl_entries:
          - name: "wirenboard"
            topics:
              - { access: "readwrite", topic: "devices/#" }
        mosquitto_tls_enabled: false
```

## Check mode and diff mode

The role supports running:

```bash
ansible-playbook playbook.yml --check --diff
```

Limitations:

- The certificate `stat` check also runs in check mode (`check_mode: false`);
  it is a read-only probe.
- The `mosquitto_passwd -U` command task is skipped in check mode; the
  `passwd.defs` template predicts the change.
- Password files are marked `no_log: true` and `diff: false` - their content
  is shown neither in the output nor in a diff.

## Handlers

- `Restart Mosquitto` - restarts the service. SIGHUP reloads only part of the
  configuration; listener, password and TLS changes apply only through a
  restart.

## Tags

- `debug` - the change summary when `mosquitto_debug_mode: true`.

## Dependencies

- None. Only `ansible.builtin` modules are used.

## Notes

- `passwd.defs` holds plaintext passwords and stays on the host as
  `0600 root:root` - a necessary stage of the idempotent build; the broker only
  reads the hashed `passwd`.
- Removing a name from `mosquitto_users` rebuilds the password file without it
  - accounts are revoked declaratively.
- The ACL only binds authenticated clients; with `allow_anonymous: true`
  anonymous clients are not restricted by `user` entries.
- The authentication directives are global (no `per_listener_settings`) and
  apply to both listeners - 1883 and 8883 require the same credentials.
