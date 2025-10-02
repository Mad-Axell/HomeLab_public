# Proxmox Import Config - Full Documentation (English)

## Table of Contents

1. [Overview](#overview)
2. [Features](#features)
3. [Requirements](#requirements)
4. [Role Variables](#role-variables)
5. [File Structure](#file-structure)
6. [Usage Examples](#usage-examples)
7. [Validation Process](#validation-process)
8. [Security](#security)
9. [Debug Modes](#debug-modes)
10. [Error Handling](#error-handling)
11. [Tags](#tags)
12. [Troubleshooting](#troubleshooting)

---

## Overview

The `proxmox_import_config` role is designed to import and validate configuration variables for Proxmox LXC container deployment. It provides a centralized way to manage secrets and host-specific configurations while ensuring data integrity and security.

### Purpose

- Import secrets from centralized storage (`secrets.yaml`)
- Load host-specific variables from `host_vars/`
- Validate all parameters before proceeding
- Verify host existence in inventory
- Provide comprehensive debug output
- Handle errors gracefully with detailed messages
- Perform preflight checks for system compatibility
- Track execution metrics and timestamps

---

## Features

### ✓ Automatic Argument Validation (NEW in v2.0)

- Automatic validation using `meta/argument_specs.yml` (Ansible 2.14+)
- Type checking for all input parameters
- Required parameter enforcement
- Default value validation

### ✓ Preflight Checks (NEW in v2.0)

- Ansible version check (>= 2.14)
- Python version check (>= 3.8)
- System compatibility verification
- Early failure detection

### ✓ Comprehensive Validation

- Required parameter validation
- File existence checks (secrets, host_vars, inventory)
- Host presence verification in inventory
- File readability checks
- Configurable strict validation mode

### ✓ Security First

- Sensitive data protected with `no_log: true`
- Passwords hidden in debug output by default
- Separate debug mode for sensitive data (`debug_sensitive`)
- Secure variable handling throughout the role

### ✓ Bilingual Debug Output (Enhanced in v2.0)

- Dual-language messages (English/Russian)
- Language selection via `debug_lang` parameter
- Structured output with clear separators
- Step-by-step execution tracking
- Final configuration summary
- Status indicators (✓/✗) for easy reading
- Execution metrics and timestamps

### ✓ Error Handling

- Block/rescue structure for critical operations
- Detailed error messages with troubleshooting hints
- Graceful failure with descriptive output
- Separate error messages for each language
- Easy debugging with comprehensive logs

### ✓ Flexible Configuration

- Multiple debug modes and languages
- Optional validation
- Configurable paths
- Tag-based execution control
- Performance tuning options

---

## Requirements

### Ansible Version

- **Ansible >= 2.14** (required for automatic argument validation)

### Python Version

- **Python >= 3.8**

### System Requirements

- Proxmox VE environment (for actual deployment)
- Access to inventory file
- Read access to secrets and host_vars files

### File Dependencies

- `secrets.yaml` file with encrypted or plain credentials
- Host-specific YAML file in `host_vars/` directory
- Inventory file with target host definition

---

## Role Variables

### Debug and Validation Settings

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `debug_mode` | bool | `false` | Enable debug output for all operations |
| `debug_lang` | string | `'both'` | Debug language: 'english', 'russian', or 'both' |
| `debug_sensitive` | bool | `false` | Enable debug output with passwords in plain text (INSECURE) |
| `backup_enabled` | bool | `true` | Enable configuration backups (reserved for future use) |
| `validate_parameters` | bool | `true` | Enable parameter validation before execution |
| `strict_validation` | bool | `true` | Enable strict validation mode with all checks |

### Host Configuration

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `host_name` | string | `"some-server"` | Hostname for loading host_vars file (REQUIRED) |
| `host_vars` | string | `"some_server"` | Prefix for variables in secrets.yaml (REQUIRED) |

### Path Configuration

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `ansible_base_dir` | string | `"/etc/ansible"` | Base directory for Ansible configuration |
| `ansible_host_vars_dir` | string | `"{{ ansible_base_dir }}/host_vars"` | Directory for host variables |
| `ansible_vars_dir` | string | `"{{ ansible_base_dir }}/VARS"` | Directory for secrets and vault files |
| `secrets_file_path` | string | `"{{ ansible_vars_dir }}/secrets.yaml"` | Path to secrets file |
| `ansible_inventory_file` | string | `"{{ ansible_base_dir }}/hosts.yml"` | Path to inventory file |

### Performance and Rollback Settings (NEW in v2.0)

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `enable_rollback` | bool | `true` | Enable automatic rollback on failure |
| `async_timeout` | int | `300` | Async task timeout in seconds |
| `retries` | int | `3` | Number of retries for failed tasks |
| `retry_delay` | int | `5` | Delay between retries in seconds |

### Variables Set by Role

These variables are set by the role after importing configurations:

#### Proxmox Server Variables

- `pve_node` - Proxmox node name
- `pve_api_host` - Proxmox API host address
- `pve_api_user` - Proxmox API username
- `pve_api_password` - Proxmox API password

#### LXC Container Variables

- `pve_lxc_root_password` - Root password for LXC container
- `pve_lxc_root_authorized_pubkey` - SSH public key for root user
- `pve_lxc_name` - LXC container name
- `pve_lxc_vmid` - LXC container VMID
- `pve_lxc_ostemplate_name` - OS template name
- `pve_lxc_ip_address` - Container IP address
- `pve_lxc_ip_mask` - Network mask
- `pve_lxc_ip_gateway` - Default gateway
- `pve_lxc_nameserver` - DNS nameserver
- `pve_lxc_searchdomain` - DNS search domain
- `pve_lxc_description` - Container description

#### Admin User Variables

- `admin_name` - Admin username
- `admin_password` - Admin password

---

## File Structure

```
roles/proxmox_import_config/
├── defaults/
│   └── main.yml               # Default variables
├── meta/
│   ├── main.yml               # Galaxy metadata (NEW in v2.0)
│   └── argument_specs.yml     # Argument specifications (NEW in v2.0)
├── tasks/
│   ├── main.yml               # Main tasks
│   ├── preflight.yml          # Preflight checks (NEW in v2.0)
│   └── validate.yml           # Validation tasks
├── README.md                  # Brief description (bilingual)
├── readme_eng.md              # Full English documentation
├── readme_rus.md              # Full Russian documentation
└── example-playbook.yml       # Usage examples
```

### Required External Files

```
/etc/ansible/
├── VARS/
│   └── secrets.yaml           # Centralized secrets file
├── host_vars/
│   └── <host_name>.yml        # Host-specific variables
└── hosts.yml                  # Inventory file
```

---

## Usage Examples

See [example-playbook.yml](example-playbook.yml) for detailed examples.

### Basic Usage

```yaml
- hosts: localhost
  roles:
    - role: proxmox_import_config
      vars:
        host_name: "web-server-01"
        host_vars: "web_server_01"
```

### With Debug Output (English Only)

```yaml
- hosts: localhost
  roles:
    - role: proxmox_import_config
      vars:
        host_name: "web-server-01"
        host_vars: "web_server_01"
        debug_mode: true
        debug_lang: 'english'
```

### With Custom Paths

```yaml
- hosts: localhost
  roles:
    - role: proxmox_import_config
      vars:
        host_name: "db-server-01"
        host_vars: "db_server_01"
        ansible_base_dir: "/opt/ansible"
        secrets_file_path: "/opt/ansible/secrets/prod.yaml"
```

### With Debug Sensitive Mode (Development Only)

```yaml
- hosts: localhost
  roles:
    - role: proxmox_import_config
      vars:
        host_name: "test-server"
        host_vars: "test_server"
        debug_mode: true
        debug_lang: 'english'
        debug_sensitive: true  # WARNING: Shows passwords!
```

### Without Validation (Not Recommended)

```yaml
- hosts: localhost
  roles:
    - role: proxmox_import_config
      vars:
        host_name: "quick-test"
        host_vars: "quick_test"
        validate_parameters: false
```

---

## Validation Process

The role performs comprehensive validation before importing configurations:

### 0. Automatic Argument Validation (NEW in v2.0)

- Validates all input parameters against `meta/argument_specs.yml`
- Type checking for all variables
- Required parameter enforcement
- Fails early if parameters are invalid

### 1. Preflight Checks (NEW in v2.0)

- Ansible version >= 2.14
- Python version >= 3.8
- System compatibility verification

### 2. Required Parameters Check

- Validates that `host_name` and `host_vars` are defined
- Ensures parameter values are not empty

### 3. Secrets File Validation

- Checks file existence at specified path
- Verifies file is readable
- Validates file size

### 4. Host Variables File Validation

- Checks `host_vars/<host_name>.yml` existence
- Verifies file is readable
- Validates file size

### 5. Inventory File Validation

- Checks inventory file existence
- Verifies file is readable

### 6. Host in Inventory Check

- Searches for host in inventory file
- Validates host entry format
- Confirms host is configured

### Validation Summary

After all checks, a comprehensive summary is displayed showing:
- Status of each validation check (✓/✗)
- Validation mode (STRICT/NORMAL)
- Overall validation result

---

## Security

### Sensitive Data Protection

1. **no_log Protection**: All tasks handling passwords use `no_log: true` to prevent logging sensitive data

2. **Default Hidden Output**: Passwords are replaced with `***HIDDEN***` in debug output by default

3. **Separate Sensitive Mode**: Use `debug_sensitive: true` only when absolutely necessary

4. **SSH Key Handling**: Public keys are loaded securely from files

### Best Practices

- Keep `debug_sensitive: false` in production
- Use Ansible Vault for `secrets.yaml`
- Restrict file permissions on sensitive files:
  ```bash
  chmod 600 /etc/ansible/VARS/secrets.yaml
  chmod 600 /etc/ansible/host_vars/*.yml
  ```
- Use dedicated service accounts with minimal permissions
- Regularly rotate passwords and API tokens

---

## Debug Modes

### Standard Debug Mode (`debug_mode: true`)

Shows:
- Execution steps
- Configuration paths
- Variable status (passwords hidden)
- Validation results
- Final summary
- Execution metrics (duration, timestamp)

Passwords displayed as: `***HIDDEN***`

### Language Selection (`debug_lang`)

Choose debug output language:
- `'english'` - English only
- `'russian'` - Russian only
- `'both'` - Both languages (default)

### Sensitive Debug Mode (`debug_sensitive: true`)

**WARNING**: Only use in secure environments!

Shows everything from standard mode PLUS:
- Actual password values
- API credentials in plain text
- All sensitive configuration data

Use only for:
- Troubleshooting in isolated environments
- Initial setup verification
- Development (never in production)

---

## Error Handling

The role uses block/rescue structure for robust error handling:

### Secrets Import Error

If secrets file import fails:
- Detailed error message displayed in selected language(s)
- Troubleshooting hints provided:
  - Check file existence and readability
  - Validate YAML syntax
  - Verify required variables presence
- Role execution fails with descriptive message

### Host Variables Import Error

If host_vars file import fails:
- Detailed error message displayed in selected language(s)
- Troubleshooting hints provided:
  - Check file existence and readability
  - Validate YAML syntax
  - Verify hostname is correct
- Role execution fails with descriptive message

---

## Tags

The role supports the following tags for flexible execution:

### Core Tags

- `always` - Tasks that always run (including preflight and validation)
- `validate` - Argument validation task
- `preflight` - Preflight compatibility checks (NEW in v2.0)
- `validation` - Parameter and file validation tasks
- `import` - All import operations
- `debug` - Debug output tasks
- `summary` - Final summary output

### Specific Tags

- `secrets` - Secrets-related tasks
- `host_vars` - Host variables tasks
- `set_facts` - Variable setting tasks
- `files` - File operation tasks
- `inventory` - Inventory-related tasks
- `sensitive` - Tasks with sensitive data
- `error` - Error handling tasks

### Usage Examples

Run only validation:
```bash
ansible-playbook playbook.yml --tags validation
```

Skip preflight checks:
```bash
ansible-playbook playbook.yml --skip-tags preflight
```

Run only import without debug:
```bash
ansible-playbook playbook.yml --tags import --skip-tags debug
```

---

## Troubleshooting

### Problem: Ansible version too old

**Error**: `This role requires Ansible 2.14 or higher`

**Solutions**:
1. Upgrade Ansible: `pip install --upgrade ansible-core`
2. Check current version: `ansible --version`
3. Ensure you have at least Ansible 2.14

### Problem: Python version too old

**Error**: `Python 3.8+ is required`

**Solutions**:
1. Upgrade Python to 3.8 or higher
2. Use a virtual environment with correct Python version
3. Update system Python installation

### Problem: Secrets file not found

**Error**: `Secrets file does not exist or is not readable`

**Solutions**:
1. Verify file path: `ls -la /etc/ansible/VARS/secrets.yaml`
2. Check file permissions: `chmod 600 /etc/ansible/VARS/secrets.yaml`
3. Verify path in `secrets_file_path` variable

### Problem: Host variables file not found

**Error**: `Host variables file does not exist or is not readable`

**Solutions**:
1. Check filename matches: `/etc/ansible/host_vars/<host_name>.yml`
2. Verify `host_name` variable is correct
3. Check file permissions

### Problem: Host not found in inventory

**Error**: `Host 'xxx' not found in inventory file`

**Solutions**:
1. Verify host exists in inventory: `grep <host_name> /etc/ansible/hosts.yml`
2. Check hostname spelling
3. Ensure inventory file path is correct

### Problem: Variable not found in secrets

**Error**: Variable `xxx_pve_node` is undefined

**Solutions**:
1. Check `host_vars` prefix matches variables in secrets.yaml
2. Verify all required variables are defined:
   - `<prefix>_pve_node`
   - `<prefix>_pve_api_user`
   - `<prefix>_pve_api_password`
   - `<prefix>_pve_lxc_root_password`
   - `<prefix>_pve_lxc_root_authorized_pubkey`
   - `<prefix>_admin_user`
   - `<prefix>_admin_password`

### Problem: YAML syntax error

**Error**: `YAML syntax error in file`

**Solutions**:
1. Validate YAML syntax: `yamllint <file>`
2. Check for proper indentation
3. Ensure quotes are balanced
4. Verify no tabs are used (use spaces)

### Problem: Argument validation failed

**Error**: `validate_argument_spec failed`

**Solutions**:
1. Check that all required variables are provided
2. Verify variable types match specifications
3. Review `meta/argument_specs.yml` for requirements
4. Ensure variable values are within allowed ranges/choices

---

## What's New in Version 2.0

### Added

- ✨ **Automatic argument validation** using `meta/argument_specs.yml`
- ✨ **Preflight checks** for Ansible >= 2.14 and Python >= 3.8
- ✨ **Bilingual logging** with `debug_lang` parameter ('english', 'russian', 'both')
- ✨ **Execution metrics** (duration tracking, timestamps)
- ✨ **Galaxy metadata** in `meta/main.yml`
- ✨ **Performance tuning** variables (retries, delays, timeouts)
- ✨ **Rollback support** configuration

### Changed

- 🔄 **Minimum Ansible version**: 2.9 → **2.14**
- 🔄 **Minimum Python version**: Any → **3.8**
- 🔄 **File extensions**: `.yaml` → `.yml`
- 🔄 **Default debug_mode**: `true` → `false` (more production-friendly)
- 🔄 **Inventory path**: `/etc/ansible/inventory/hosts.ini` → `/etc/ansible/hosts.yml`
- 🔄 **Task names**: Now English only (bilingual comments remain)
- 🔄 **Debug output**: Separated by language via `debug_lang`

### Enhanced

- 📈 Better error handling with language-specific rescue blocks
- 📈 Improved security with consistent `no_log` usage
- 📈 More structured logging output
- 📈 Comprehensive validation workflow

---

## Support

For issues, questions, or contributions:

1. Check this documentation thoroughly
2. Review [example-playbook.yml](example-playbook.yml)
3. Enable `debug_mode: true` for detailed output
4. Check Ansible logs
5. Verify Ansible >= 2.14 and Python >= 3.8

---

## License

MIT

## Author

**Mad-Axell**  
DevOps Team

---

**Last Updated**: 2025-10-01 (Version 2.0)
