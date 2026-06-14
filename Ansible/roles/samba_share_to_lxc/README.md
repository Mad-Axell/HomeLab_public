# samba_share_to_lxc

Ansible role for mounting SMB/CIFS shares on Proxmox host and binding them to LXC containers.

## Quick Links

- [English Documentation](README_eng.md) - Complete English documentation
- [Русская Документация](README_rus.md) - Полная русская документация

## Overview

This role automates the process of:
- Mounting SMB/CIFS shares on Proxmox host
- Creating credentials file for SMB authentication
- Adding mount entries to `/etc/fstab`
- Binding mounted shares to LXC containers via bind-mount

## Requirements

- Ansible 2.9+
- Proxmox VE host with LXC containers
- Debian/Ubuntu family OS
- Root or sudo access

## Quick Start

```yaml
- hosts: proxmox_host
  roles:
    - role: samba_share_to_lxc
      vars:
        samba_lxc_id: 101
        samba_smb_user: "username"
        samba_smb_password: "password"
        samba_smb_server: "10.20.30.200"
        samba_smb_share: "share_name"
```

## License

MIT

## Author

Mad-Axell [mad.axell@gmail.com]

