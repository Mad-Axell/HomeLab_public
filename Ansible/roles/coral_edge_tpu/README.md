# coral-edge-tpu

Ansible role for installing and configuring Google Coral EDGE TPU support in Proxmox LXC containers.

## Quick Links

- **[English Documentation](README_eng.md)** - Complete English documentation
- **[Русская Документация](README_rus.md)** - Полная русская документация

## Overview

This role automates the installation of Coral EDGE TPU libraries and configuration of Proxmox LXC containers to enable USB device forwarding for Coral TPU accelerators.

## Quick Start

```yaml
- hosts: proxmox_hosts
  roles:
    - role: coral-edge-tpu
      vars:
        pve_lxc_vmid: 100
```

## License

MIT

## Author

Mad-Axell [mad.axell@gmail.com]

