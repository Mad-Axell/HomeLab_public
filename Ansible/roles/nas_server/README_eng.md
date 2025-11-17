# NAS Server Role - English Documentation

Automated Ansible role for NAS server installation and configuration in Proxmox LXC container.

## Description

This role installs and configures a full-featured NAS server with the following components:

- **Cockpit** - Web-based server management interface with 45Drives modules (file-sharing, navigator, identities)
- **Samba** - File sharing for Windows/Linux/Mac with Cockpit integration
- **NFS** - Network file access for Linux clients (optional)
- **Storage Management** - System storage preparation and package management

## Requirements

### Prerequisites

- Debian 11 or higher (Debian 12 recommended)
- LXC container on Proxmox VE
- Network connectivity to the internet
- Root or sudo access
- systemd-resolved available

### Minimum Requirements

- 100 GB free disk space
- Privileged LXC container (if required)
- Network access to Proxmox host (for ZFS management)

## Role Variables

### Debug Configuration

```yaml
debug_mode: false                      # Boolean. Enable debug output
                                        # Логическое значение. Включить отладочный вывод
```

### Cockpit Configuration

```yaml
cockpit_port: 9090                     # Integer. Port for Cockpit web interface
                                        # Целое число. Порт веб-интерфейса Cockpit
cockpit_listen_address: "0.0.0.0"      # String. IP address for Cockpit to listen on
                                        # Строка. IP-адрес для прослушивания Cockpit
cockpit_configure_listener: false      # Boolean. Configure Cockpit listener in cockpit.conf (may cause problems)
                                        # Логическое значение. Настроить прослушиватель Cockpit в cockpit.conf (может вызвать проблемы)
cockpit_modules:                       # List. List of Cockpit modules to install from 45Drives repository
                                        # Список. Список модулей Cockpit для установки из репозитория 45Drives
  - "cockpit-file-sharing"
  - "cockpit-navigator"
  - "cockpit-identities"
```

### Samba Configuration

```yaml
samba_workgroup: "WORKGROUP"           # String. Samba workgroup name
                                        # Строка. Имя рабочей группы Samba
samba_security: "user"                 # String. Samba security mode (user, share, domain, ads)
                                        # Строка. Режим безопасности Samba (user, share, domain, ads)
samba_share_method: "registry"         # String. Method for adding shares: 'samba' (config files) or 'registry' (net conf commands)
                                        # Строка. Метод добавления шаров: 'samba' (файлы конфигурации) или 'registry' (команды net conf)
samba_users: []                        # List. List of Samba users to create
                                        # Список. Список пользователей Samba для создания
samba_groups: []                       # List. List of Samba groups to create
                                        # Список. Список групп Samba для создания
samba_shares: []                       # List. List of Samba shares to create
                                        # Список. Список шаров Samba для создания
```

#### Samba Users Structure

```yaml
samba_users:
  - name: "nasuser"                    # String. Username
                                        # Строка. Имя пользователя
    password: "secure_password"         # String. User password (use Ansible Vault)
                                        # Строка. Пароль пользователя (используйте Ansible Vault)
    groups: ["nas-group"]              # List. List of groups user belongs to
                                        # Список. Список групп, к которым принадлежит пользователь
    shell: "/bin/bash"                  # String. User shell
                                        # Строка. Оболочка пользователя
    system_user: false                 # Boolean. Create as system user
                                        # Логическое значение. Создать как системного пользователя
    create_home: true                   # Boolean. Create home directory
                                        # Логическое значение. Создать домашнюю директорию
```

#### Samba Groups Structure

```yaml
samba_groups:
  - name: "nas-group"                  # String. Group name
                                        # Строка. Имя группы
    gid: 2000                          # Integer. Group ID (optional)
                                        # Целое число. Идентификатор группы (необязательно)
```

#### Samba Shares Structure

```yaml
samba_shares:
  - name: "nas-storage"                # String. Share name
                                        # Строка. Имя шара
    comment: "NAS Storage Share"       # String. Share description
                                        # Строка. Описание шара
    path: "/mnt/nas-storage"           # String. Path to share directory
                                        # Строка. Путь к директории шара
    browsable: true                    # Boolean. Allow browsing in network neighborhood
                                        # Логическое значение. Разрешить просмотр в сетевом окружении
    writable: true                     # Boolean. Allow write access
                                        # Логическое значение. Разрешить запись
    read_only: false                   # Boolean. Read-only share
                                        # Логическое значение. Шар только для чтения
    public: true                       # Boolean. Public share
                                        # Логическое значение. Публичный шар
    guest_ok: false                    # Boolean. Allow guest access
                                        # Логическое значение. Разрешить гостевой доступ
    create_mask: "0664"                # String. File creation mask
                                        # Строка. Маска создания файлов
    directory_mask: "0775"              # String. Directory creation mask
                                        # Строка. Маска создания директорий
    force_user: "nasuser"              # String. Force file ownership to user
                                        # Строка. Принудительное владение файлами пользователем
    force_group: "nas-group"           # String. Force file ownership to group
                                        # Строка. Принудительное владение файлами группой
    valid_users: ["nasuser", "@nas-group"]  # List. List of allowed users/groups
                                            # Список. Список разрешенных пользователей/групп
    write_list: ["nasuser", "@nas-group"]  # List. List of users/groups with write access
                                            # Список. Список пользователей/групп с правом записи
    setgid: true                       # Boolean. Set setgid bit on directories
                                        # Логическое значение. Установить бит setgid на директориях
```

### NFS Configuration

```yaml
nfs_enabled: false                     # Boolean. Enable NFS server
                                        # Логическое значение. Включить NFS сервер
nfs_exports: []                        # List. List of NFS exports
                                        # Список. Список NFS экспортов
```

#### NFS Exports Structure

```yaml
nfs_exports:
  - path: "/mnt/nas-storage"           # String. Path to export
                                        # Строка. Путь для экспорта
    clients: "*(rw,sync,no_subtree_check,no_root_squash)"  # String. Client access specification
                                                            # Строка. Спецификация доступа клиентов
```

### System Configuration

```yaml
backports_enabled: false                # Boolean. Enable Debian backports repository
                                        # Логическое значение. Включить репозиторий Debian backports
essential_packages:                    # List. List of essential packages to install
                                        # Список. Список основных пакетов для установки
  - curl
  - wget
  - net-tools
```

## Share Methods

The role supports two methods for adding Samba shares:

### Samba Method (config files)

Creates configuration files in `/etc/samba/smb.conf.d/share-<name>.conf`. This method uses standard Samba configuration files and is suitable for traditional setup.

**Advantages:**
- Standard Samba configuration files
- Easy to edit manually
- Version control friendly

**Disadvantages:**
- Not fully integrated with Cockpit file-sharing module

### Registry Method (net conf commands)

Adds shares directly to Samba registry using `net conf addshare` and `net conf setparm` commands. This method provides full integration with Cockpit file-sharing module, as Cockpit uses registry for share management.

**Advantages:**
- Full Cockpit integration
- Shares visible and manageable in Cockpit UI
- Dynamic share management

**Disadvantages:**
- Requires registry include in smb.conf
- Less traditional approach

**Recommendation:** Use `registry` method when working with Cockpit.

## Dependencies

None.

## Example Playbook

### Basic Usage

```yaml
---
- name: Deploy NAS Server
  hosts: nas_container
  become: true
  roles:
    - nas_server
```

### With Custom Variables

```yaml
---
- name: Deploy NAS Server
  hosts: nas_container
  become: true
  vars:
    cockpit_port: 9090
    cockpit_listen_address: "0.0.0.0"
    samba_users:
      - name: "storage"
        password: "{{ vault_storage_pass }}"
        groups: ["nas", "samba"]
        shell: "/bin/bash"
      - name: "backup"
        password: "{{ vault_backup_pass }}"
        groups: ["nas", "samba"]
        shell: "/bin/bash"
    samba_groups:
      - name: "nas"
        gid: 2000
    samba_shares:
      - name: "media"
        path: "/mnt/nas-storage/media"
        comment: "Media Storage"
        force_user: "storage"
        force_group: "nas"
        valid_users: ["storage", "@nas"]
        write_list: ["storage", "@nas"]
      - name: "backups"
        path: "/mnt/nas-storage/backups"
        comment: "Backup Storage"
        force_user: "backup"
        force_group: "nas"
        valid_users: ["backup", "@nas"]
        write_list: ["backup", "@nas"]
    nfs_enabled: true
    nfs_exports:
      - path: "/mnt/nas-storage"
        clients: "192.168.1.0/24(rw,sync,no_subtree_check)"
  roles:
    - nas_server
```

### With Registry Method for Cockpit Integration

```yaml
---
- name: Deploy NAS Server with Registry Method
  hosts: nas_container
  become: true
  vars:
    samba_share_method: "registry"
    samba_users:
      - name: "storage"
        password: "{{ vault_storage_pass }}"
        groups: ["nas", "samba"]
    samba_shares:
      - name: "media"
        path: "/mnt/nas-storage/media"
        comment: "Media Storage"
        browsable: true
        writable: true
        force_user: "storage"
        force_group: "nas"
        create_mask: "0664"
        directory_mask: "0775"
  roles:
    - nas_server
```

## Role Structure

```
nas_server/
├── defaults/
│   └── main.yml           # Default variables
├── handlers/
│   └── main.yml           # Handlers (restart samba, etc.)
├── meta/
│   └── main.yml           # Role metadata
├── tasks/
│   ├── main.yml           # Main entry point
│   ├── cockpit.yml        # Cockpit installation
│   ├── samba.yml          # Samba configuration
│   ├── nfs.yml            # NFS configuration (optional)
│   └── storage.yml        # Storage preparation
├── templates/
│   ├── samba-global.j2    # Samba global configuration template
│   ├── samba-share.j2     # Samba share configuration template
│   └── nfs-exports.j2     # NFS exports configuration template
├── README.md              # Brief overview
├── README_eng.md          # Complete English documentation
└── README_rus.md         # Complete Russian documentation
```

## Tags

The role supports the following tags for selective execution:

- `checks` - Pre-execution checks
- `storage` - Storage setup
- `packages` - Package installation
- `cockpit` - Cockpit installation and configuration
- `samba` - Samba installation and configuration
- `nfs` - NFS installation and configuration
- `users` - User management
- `shares` - Share management
- `config` - Configuration tasks
- `services` - Service management
- `verification` - Status verification

### Tag Usage Examples

```bash
# Install only Cockpit
ansible-playbook playbook.yml --tags cockpit

# Configure only Samba
ansible-playbook playbook.yml --tags samba

# Skip checks
ansible-playbook playbook.yml --skip-tags checks

# Install packages and configure Samba
ansible-playbook playbook.yml --tags packages,samba
```

## Installation Process

### Stage 1: Storage Setup

1. Add backports repository (if enabled)
2. Update apt cache
3. Upgrade system packages
4. Install essential packages

### Stage 2: Cockpit Installation

1. Install Cockpit package
2. Setup 45Drives repository
3. Update apt cache after repository addition
4. Install Cockpit modules from 45Drives
5. Configure Cockpit listener (if enabled)
6. Ensure Cockpit socket is enabled and started
7. Wait for Cockpit service to be available
8. Verify Cockpit is running

### Stage 3: Samba Configuration

1. Initialize group collections from users
2. Create Samba groups
3. Create Samba users
4. Set Samba passwords
5. Enable Samba users
6. Add registry include to Samba config (for Cockpit integration)
7. Ensure Samba config directory exists
8. Backup original Samba config
9. Generate Samba global configuration
10. Add include directive for share configs (if using samba method)
11. Create Samba share directories
12. Set setgid bit on share directories (if configured)
13. Generate Samba share configurations (samba method) or add to registry (registry method)
14. Test Samba configuration syntax
15. Verify Samba configuration
16. Ensure Samba services are enabled and started
17. Verify Samba services are running

### Stage 4: NFS Configuration (Optional)

1. Install NFS kernel server (if enabled)
2. Generate NFS exports configuration
3. Create NFS export directories
4. Export NFS shares
5. Ensure NFS services are enabled and started
6. Verify NFS service is running

## Implementation Features

### Idempotency

All operations check for existence before making changes. The role uses built-in Ansible modules to ensure idempotency.

### Security

- User passwords are handled with `no_log: true` where appropriate
- Configuration files have proper permissions
- Support for Ansible Vault for secret storage
- Samba security mode configurable

### Error Handling

- Configuration syntax validation before applying changes
- Informative error messages
- Fallback options when external resources are unavailable

## Troubleshooting

### Cockpit Not Accessible

1. Check service status: `systemctl status cockpit.socket`
2. Check port: `netstat -tlnp | grep 9090` or `ss -tlnp | grep 9090`
3. Check logs: `journalctl -u cockpit.socket`
4. Verify firewall rules allow port 9090

### Samba Not Working

1. Check configuration syntax: `testparm -s`
2. Check service status: `systemctl status smbd nmbd`
3. Check logs: `tail -f /var/log/samba/log.*`
4. Verify share directories exist and have correct permissions
5. Check Samba users exist: `pdbedit -L`

### NFS Not Working

1. Check service status: `systemctl status nfs-kernel-server`
2. Check exports: `exportfs -v`
3. Check logs: `journalctl -u nfs-kernel-server`
4. Verify firewall rules allow NFS ports (111, 2049)

### Share Method Issues

**Registry Method:**
- Ensure `include = registry` is present in `/etc/samba/smb.conf`
- Check registry shares: `net conf list`
- Verify Cockpit file-sharing module is installed

**Samba Method:**
- Check share config files in `/etc/samba/smb.conf.d/`
- Verify include directive in main config: `include = /etc/samba/smb.conf.d/*.conf`

## License

MIT

## Author

Mad-Axell [mad.axell@gmail.com]

