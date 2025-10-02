# Proxmox LXC Container Management Role

[![Ansible](https://img.shields.io/badge/ansible-2.14%2B-blue.svg)](https://www.ansible.com/)
[![License](https://img.shields.io/badge/license-MIT-brightgreen.svg)](LICENSE)

[English Documentation](README_eng.md) | [Русская документация](README_rus.md)

## Quick Start

### English

This Ansible role provides automated creation and management of LXC containers in Proxmox Virtual Environment (PVE). It supports container creation, template management, network configuration, and resource allocation with comprehensive validation and error handling.

**Key Features:**
- Automated LXC container deployment
- OS template management and caching
- Network interface configuration
- Resource allocation (CPU, Memory, Disk)
- Bilingual debug output (English/Russian)
- Comprehensive validation and preflight checks
- Retry logic for critical operations

**Basic Usage:**

```yaml
- hosts: proxmox_hosts
  roles:
    - role: proxmox_lxc
      vars:
        pve_api_host: "proxmox.example.com"
        pve_node: "pve-node1"
        pve_api_user: "root@pam"
        pve_api_password: "{{ vault_pve_password }}"
        pve_hostname: "test-container"
        pve_lxc_ostemplate_name: "debian-12-standard_12.2-1_amd64.tar.zst"
        pve_lxc_root_password: "{{ vault_container_password }}"
        pve_lxc_cpu_cores: 2
        pve_lxc_memory: 2048
        pve_lxc_disk: 20
```

### Русский

Данная роль Ansible обеспечивает автоматизированное создание и управление LXC контейнерами в Proxmox Virtual Environment (PVE). Поддерживает создание контейнеров, управление шаблонами, настройку сети и выделение ресурсов с комплексной валидацией и обработкой ошибок.

**Ключевые возможности:**
- Автоматическое развертывание LXC контейнеров
- Управление шаблонами ОС и кэширование
- Настройка сетевых интерфейсов
- Выделение ресурсов (CPU, Память, Диск)
- Двуязычный вывод отладки (Английский/Русский)
- Комплексная валидация и предварительные проверки
- Логика повторных попыток для критических операций

**Базовое использование:**

```yaml
- hosts: proxmox_hosts
  roles:
    - role: proxmox_lxc
      vars:
        pve_api_host: "proxmox.example.com"
        pve_node: "pve-node1"
        pve_api_user: "root@pam"
        pve_api_password: "{{ vault_pve_password }}"
        pve_hostname: "test-container"
        pve_lxc_ostemplate_name: "debian-12-standard_12.2-1_amd64.tar.zst"
        pve_lxc_root_password: "{{ vault_container_password }}"
        pve_lxc_cpu_cores: 2
        pve_lxc_memory: 2048
        pve_lxc_disk: 20
```

## Requirements

- Ansible >= 2.14
- Python >= 3.8
- Proxmox VE 7.x or 8.x
- Collection: `community.general`

## Documentation

For complete documentation, please refer to:
- [English Documentation](README_eng.md) - Complete guide with examples
- [Русская документация](README_rus.md) - Полное руководство с примерами

## Role Variables

See [defaults/main.yml](defaults/main.yml) and [meta/argument_specs.yml](meta/argument_specs.yml) for all available variables.

## Dependencies

- `community.general` collection (for Proxmox modules)

## Example Playbook

```yaml
---
- name: Deploy LXC containers
  hosts: proxmox_nodes
  become: true
  
  roles:
    - role: proxmox_lxc
      vars:
        debug_mode: true
        debug_lang: both
        pve_api_host: "{{ inventory_hostname }}"
        pve_node: "{{ inventory_hostname }}"
        pve_hostname: "web-server-01"
        pve_lxc_ostemplate_name: "ubuntu-22.04-standard_22.04-1_amd64.tar.zst"
        pve_lxc_cpu_cores: 4
        pve_lxc_memory: 4096
        pve_lxc_disk: 50
        pve_onboot: true
        pve_lxc_unprivileged: true
```

## Testing

This role includes comprehensive validation and preflight checks:

```bash
# Run with validation enabled
ansible-playbook playbook.yml -e "validate_parameters=true strict_validation=true"

# Run with debug output
ansible-playbook playbook.yml -e "debug_mode=true debug_lang=both"
```

## License

MIT

## Author Information

DevOps Team - Internal Infrastructure Team

---

**Note:** This role requires proper authentication to Proxmox API. Use Ansible Vault to secure sensitive credentials.

**Примечание:** Данная роль требует правильной аутентификации в Proxmox API. Используйте Ansible Vault для защиты конфиденциальных данных.

