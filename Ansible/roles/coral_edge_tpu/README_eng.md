# coral-edge-tpu

Ansible role for installing and configuring Google Coral EDGE TPU support in Proxmox LXC containers.

## Description

This role automates the installation of Google Coral EDGE TPU runtime libraries and configures Proxmox LXC containers to enable USB device forwarding for Coral TPU accelerators. It adds the official Google repository, installs the required libraries, and configures the LXC container configuration file to forward USB devices and GPU devices.

## Requirements

### Control Node Requirements

- Ansible 2.14 or higher
- Python 3.9 or higher

### Managed Node Requirements

- Debian family distribution (Debian, Ubuntu)
- Proxmox VE environment
- Root or sudo access
- Internet connectivity for package installation

### Dependencies

None

## Role Variables

### Required Variables

| Variable | Type | Description |
|----------|------|-------------|
| `pve_lxc_vmid` | string | Proxmox LXC container VM ID. Used to identify the container configuration file at `/etc/pve/lxc/{{ pve_lxc_vmid }}.conf` |

### Optional Variables

None

## Example Playbook

### Basic Usage

```yaml
---
- name: Configure Coral EDGE TPU for LXC container
  hosts: proxmox_hosts
  become: true
  vars:
    pve_lxc_vmid: "100"
  roles:
    - coral-edge-tpu
```

### Multiple Containers

```yaml
---
- name: Configure Coral EDGE TPU for multiple containers
  hosts: proxmox_hosts
  become: true
  vars:
    pve_lxc_vmid: "{{ item }}"
  roles:
    - coral-edge-tpu
  loop:
    - "100"
    - "101"
    - "102"
```

## What This Role Does

1. **Adds Coral EDGE TPU Repository**
   - Adds Google's official Coral EDGE TPU repository to the system's APT sources

2. **Adds GPG Key**
   - Imports the GPG key for the Coral EDGE TPU repository

3. **Updates Package Cache**
   - Updates the APT package cache to include packages from the new repository

4. **Installs Coral EDGE TPU Library**
   - Installs `libedgetpu1-std` package (standard runtime library for Coral EDGE TPU)

5. **Configures LXC Container**
   - Configures device forwarding in the Proxmox LXC container configuration file
   - Enables forwarding of USB devices (Coral TPU devices on /dev/bus/usb/001/ and /dev/bus/usb/004/)
   - Enables forwarding of GPU devices (/dev/dri/renderD128 and /dev/dri)
   - Sets device permissions (cgroup2.devices.allow)

## Device Forwarding Configuration

The role configures the following device forwards in the LXC container:

- **USB Devices**: `/dev/bus/usb/001/` and `/dev/bus/usb/004/` (Coral TPU devices)
- **GPU Devices**: `/dev/dri/renderD128` and `/dev/dri` (for GPU acceleration)
- **Device Permissions**: `lxc.cgroup2.devices.allow = a` (allows all devices)

## Notes

- This role is specifically designed for Proxmox VE LXC containers
- The role modifies the LXC container configuration file directly
- USB device paths (001, 004) are hardcoded and may need adjustment based on your hardware configuration
- The role uses check mode for initial validation before applying changes
- After configuration, the LXC container may need to be restarted for changes to take effect

## Troubleshooting

### USB Device Not Found

If your Coral TPU device is on a different USB bus, you may need to:
1. Identify the correct USB bus: `lsusb | grep Coral`
2. Check the device path: `ls -la /dev/bus/usb/`
3. Modify the role tasks to use the correct device path

### Permission Denied Errors

Ensure that:
- The playbook runs with `become: true`
- The user has permissions to modify `/etc/pve/lxc/` directory
- The LXC container configuration file exists and is writable

### Package Installation Fails

Verify:
- Internet connectivity is available
- DNS resolution works correctly
- The GPG key import was successful
- The repository URL is accessible

## License

MIT

## Author

Mad-Axell [mad.axell@gmail.com]

## Support

For issues and questions, please contact the author or open an issue in the repository.

