# samba_share_to_lxc - English Documentation

Ansible role for mounting SMB/CIFS shares on Proxmox host and binding them to LXC containers.

## Description

This role automates the complete process of mounting SMB/CIFS network shares on a Proxmox VE host and making them available inside LXC containers through bind-mounts. It handles:

- Installation of required packages (`cifs-utils`)
- Creation of secure credentials file for SMB authentication
- Configuration of `/etc/fstab` for persistent mounts
- Mounting of SMB shares on the host
- Binding mounted shares to LXC containers
- Optional container restart to apply changes

The role is idempotent and can be safely run multiple times. It validates the environment before making changes and provides clear error messages.

## Requirements

### Control Node

- Ansible 2.9 or higher
- Python 3.6+

### Managed Node

- Proxmox VE host
- Debian or Ubuntu (Debian family distributions)
- Root or sudo access
- Network connectivity to SMB server
- Existing LXC container (specified by `samba_lxc_id`)

## Role Variables

### Required Variables

These variables must be set in your playbook or host_vars:

| Variable | Type | Description |
|----------|------|-------------|
| `samba_lxc_id` | Integer | LXC container ID (e.g., 101, 102) |
| `samba_smb_user` | String | SMB username for authentication |
| `samba_smb_password` | String | SMB password for authentication |

### Optional Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `samba_smb_server` | String | `"10.20.30.200"` | IP address or hostname of SMB server |
| `samba_smb_share` | String | `"frigate"` | Name of the SMB share |
| `samba_mount_point` | String | `"/mnt/frigate_host"` | Mount point on Proxmox host |
| `samba_container_mount` | String | `"/mnt/frigate"` | Mount point inside LXC container |
| `samba_cred_file` | String | `"/root/.smb-frigate"` | Path to credentials file |
| `samba_cifs_version` | String | `"3.0"` | CIFS protocol version |
| `samba_cifs_options` | List | `["iocharset=utf8", "nofail", "_netdev"]` | Additional CIFS mount options |
| `samba_lxc_mp_id` | String | `"mp0"` | LXC mount point ID (mp0, mp1, etc.) |
| `samba_lxc_restart` | Boolean | `true` | Restart LXC container after configuration |

## Dependencies

None. This role is independent and does not require other roles.

## Example Playbook

### Basic Usage

```yaml
---
- name: Mount SMB share to LXC container
  hosts: proxmox_host
  become: true
  vars:
    samba_lxc_id: 101
    samba_smb_user: "frigate_user"
    samba_smb_password: "SecurePassword123"
    samba_smb_server: "10.20.30.200"
    samba_smb_share: "frigate"
    samba_mount_point: "/mnt/frigate_host"
    samba_container_mount: "/mnt/frigate"
  
  roles:
    - samba_share_to_lxc
```

### Advanced Usage with Custom Options

```yaml
---
- name: Mount SMB share with custom configuration
  hosts: proxmox_host
  become: true
  vars:
    samba_lxc_id: 102
    samba_smb_user: "backup_user"
    samba_smb_password: "{{ vault_smb_password }}"
    samba_smb_server: "192.168.1.100"
    samba_smb_share: "backups"
    samba_mount_point: "/mnt/backup_host"
    samba_container_mount: "/mnt/backup"
    samba_lxc_mp_id: "mp1"
    samba_cifs_version: "2.1"
    samba_cifs_options:
      - "iocharset=utf8"
      - "nofail"
      - "_netdev"
      - "uid=1000"
      - "gid=1000"
    samba_lxc_restart: false
  
  roles:
    - samba_share_to_lxc
```

### Using Ansible Vault for Secrets

```yaml
---
- name: Mount SMB share with vault-encrypted password
  hosts: proxmox_host
  become: true
  vars:
    samba_lxc_id: 101
    samba_smb_user: "{{ vault_smb_user }}"
    samba_smb_password: "{{ vault_smb_password }}"
    samba_smb_server: "10.20.30.200"
    samba_smb_share: "frigate"
  
  roles:
    - samba_share_to_lxc
```

## Task Tags

The role supports the following tags for selective execution:

| Tag | Description |
|-----|-------------|
| `validation` | Validation tasks (environment checks) |
| `packages` | Package installation tasks |
| `setup` | Setup tasks (directories, credentials) |
| `credentials` | Credentials file creation |
| `fstab` | `/etc/fstab` configuration |
| `mount` | Mount operations |
| `lxc` | LXC configuration tasks |
| `restart` | Container restart |

### Example: Run only mount tasks

```bash
ansible-playbook playbook.yml --tags mount
```

### Example: Skip container restart

```bash
ansible-playbook playbook.yml --skip-tags restart
```

## How It Works

1. **Validation**: Checks if running on Proxmox host and if LXC container exists
2. **Package Installation**: Installs `cifs-utils` if not already present
3. **Directory Creation**: Creates mount point directory on host
4. **Credentials**: Creates secure credentials file (`/root/.smb-frigate` by default)
5. **Fstab Configuration**: Adds mount entry to `/etc/fstab` for persistence
6. **Mounting**: Mounts the SMB share on the host
7. **Verification**: Verifies that the share is successfully mounted
8. **LXC Configuration**: Adds or updates bind-mount entry in LXC container config
9. **Container Restart**: Optionally reboots the container to apply changes

## Security Considerations

- Credentials file is created with `0600` permissions (readable only by root)
- Password is stored in credentials file, not passed as command-line arguments
- Use Ansible Vault for storing passwords in playbooks
- The role uses `no_log: false` for credentials task (can be changed to `true` for extra security)

## Troubleshooting

### Container restart fails

If `pct reboot` fails, ensure:
- Container ID is correct
- You have proper permissions
- Container is not locked

### Mount fails

Check:
- SMB server is reachable from Proxmox host
- Credentials are correct
- SMB share name is correct
- Firewall allows CIFS traffic (ports 445, 139)

### LXC bind-mount not working

Verify:
- Container config file exists at `/etc/pve/lxc/{id}.conf`
- Mount point directory exists on host
- Container has been restarted after configuration

## Limitations

- Only supports Debian/Ubuntu family distributions
- Requires Proxmox VE host (not compatible with other virtualization platforms)
- SMB credentials are stored in plain text file (use filesystem permissions for security)
- Only one mount point per container ID can be configured per role execution

## License

MIT

## Author Information

**Author**: Mad-Axell  
**Email**: mad.axell@gmail.com

## Support

For issues, questions, or contributions, please refer to the project repository or contact the author.

