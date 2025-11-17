# NAS Server Role

Automated Ansible role for NAS server installation and configuration in Proxmox LXC container.

## Overview

This role installs and configures a full-featured NAS server with the following components:

- **Cockpit** - Web-based server management interface with 45Drives modules
- **Samba** - File sharing for Windows/Linux/Mac with Cockpit integration
- **NFS** - Network file access for Linux clients (optional)
- **Storage Management** - System storage preparation and package management

## Quick Start

```yaml
---
- name: Deploy NAS Server
  hosts: nas_container
  become: true
  roles:
    - nas_server
```

## Documentation

- **[README_eng.md](README_eng.md)** - Complete English documentation
- **[README_rus.md](README_rus.md)** - Полная русская документация

## Requirements

- Debian 11 or higher (Debian 12 recommended)
- LXC container on Proxmox VE
- Network connectivity
- Root or sudo access

## License

MIT

## Author

Mad-Axell [mad.axell@gmail.com]
