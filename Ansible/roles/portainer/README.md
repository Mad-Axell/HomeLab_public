# portainer

Ansible role for deploying and configuring Portainer - a web interface for managing Docker containers.

## Description

This role automates the deployment of Portainer as a Docker container on managed nodes. The role supports installation of Portainer from the official Docker image, configuration of persistent data storage, network settings management, container restart policy configuration, and verification of web interface availability after deployment.

## Quick Start

```yaml
---
- name: Deploy Portainer
  hosts: all
  become: true
  roles:
    - docker
    - portainer
```

## Requirements

- Ansible 2.12 or higher
- Python 3.9 or higher
- Docker installed and running (recommended: use `docker` role)
- Root or sudo access
- Internet connectivity for Docker image download
- Port 9000 (or other specified port) available for web interface

## Dependencies

- `docker` role (recommended for Docker installation)
- `community.docker` collection: `ansible-galaxy collection install community.docker`

## Documentation

For complete documentation, see:

- **[README_eng.md](README_eng.md)** - Full English documentation
- **[README_rus.md](README_rus.md)** - Полная документация на русском языке

## License

MIT

## Author

Mad-Axell [mad.axell@gmail.com]

