# Proxmox Import Config Role - English Documentation

## Overview

The `proxmox_import_config` role is designed to import and validate configuration variables for Proxmox LXC container deployment from centralized secret storage and host-specific variable files. This role provides comprehensive validation, structured logging, and automatic rollback capabilities.

## Features

- **Centralized Secret Management**: Import secrets from a centralized YAML file
- **Host Variables Import**: Load host-specific configuration variables
- **YAML Syntax Validation**: Validate YAML syntax of all configuration files
- **Structured JSON Logging**: Log all operations in structured JSON format
- **Comprehensive Validation**: Validate file existence, syntax, and structure

## Requirements

### System Requirements
- Ansible 2.14 or higher
- Python 3.8 or higher
- Access to secrets and host_vars files

### File Structure Requirements
```
/etc/ansible/
├── VARS/
│   └── secrets.yaml          # Centralized secrets file
├── host_vars/
│   └── {host_name}.yml       # Host-specific variables
└── hosts.yml                 # Inventory file
```

## Role Variables

### Required Variables

| Variable | Type | Description |
|----------|------|-------------|
| `host_name` | string | Host name for loading host_vars (must match host_vars file name without .yml extension) |
| `host_vars` | string | Prefix for variables in secrets.yaml (used to construct variable names) |

### Optional Variables

#### Debug and Validation Settings

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `debug_mode` | boolean | `false` | Enable detailed debug output |
| `debug_sensitive` | boolean | `false` | Show passwords in debug (INSECURE) |
| `validate_parameters` | boolean | `true` | Enable parameter validation |
| `strict_validation` | boolean | `true` | Enable strict validation mode |

#### Path Configuration

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `ansible_base_dir` | string | `"/etc/ansible"` | Base directory for Ansible configuration |
| `ansible_host_vars_dir` | string | `"{{ ansible_base_dir }}/host_vars"` | Directory for host variables |
| `ansible_vars_dir` | string | `"{{ ansible_base_dir }}/VARS"` | Directory for secrets and vault files |
| `secrets_file_path` | string | `"{{ ansible_vars_dir }}/secrets.yaml"` | Path to secrets file |
| `ansible_inventory_file` | string | `"{{ ansible_base_dir }}/hosts.yml"` | Path to inventory file |


#### Performance Configuration

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `async_timeout` | integer | `300` | Async task timeout in seconds |
| `retries` | integer | `3` | Number of retries for failed tasks |
| `retry_delay` | integer | `5` | Delay between retries in seconds |

#### Logging Configuration

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `log_file` | string | `"/var/log/ansible-changes.log"` | Path to log file for structured logging |

## Usage Examples

### Basic Usage

```yaml
- name: Import Proxmox configuration
  ansible.builtin.include_role:
    name: proxmox_import_config
  vars:
    host_name: "web-server-01"
    host_vars: "web_server_01"
```

### Advanced Usage with Debug

```yaml
- name: Import Proxmox configuration with debug
  ansible.builtin.include_role:
    name: proxmox_import_config
  vars:
    host_name: "web-server-01"
    host_vars: "web_server_01"
    debug_mode: true
    log_file: "/var/log/proxmox-import.log"
    strict_validation: true
```

### Custom Paths

```yaml
- name: Import Proxmox configuration with custom paths
  ansible.builtin.include_role:
    name: proxmox_import_config
  vars:
    host_name: "web-server-01"
    host_vars: "web_server_01"
    ansible_base_dir: "/opt/ansible"
    secrets_file_path: "/opt/secrets/proxmox-secrets.yaml"
    backup_dir: "/opt/backups/ansible"
```

## Secrets File Structure

The secrets file should contain variables with the specified prefix:

```yaml
# secrets.yaml
web_server_01_pve_node: "pve-node-01"
web_server_01_pve_api_user: "root@pam"
web_server_01_pve_api_password: "secure_password"
web_server_01_pve_lxc_root_password: "root_password"
web_server_01_pve_lxc_root_authorized_pubkey: "/path/to/ssh/key"
web_server_01_admin_user: "admin"
web_server_01_admin_password: "admin_password"
```

## Host Variables File Structure

The host variables file should contain LXC container configuration:

```yaml
# host_vars/web-server-01.yml
pve_lxc_name: "web-server-01"
pve_lxc_vmid: 100
pve_lxc_ostemplate_name: "ubuntu-22.04-standard_22.04-1_amd64.tar.zst"
pve_lxc_ip_address: "192.168.1.100"
pve_lxc_ip_mask: "24"
pve_lxc_ip_gateway: "192.168.1.1"
pve_lxc_nameserver: "8.8.8.8"
pve_lxc_searchdomain: "local"
pve_lxc_description: "Web server container"
```

## Structured Logging

The role logs all operations in structured JSON format to the specified log file. Each log entry contains:

- `timestamp`: ISO 8601 timestamp
- `level`: Log level (INFO, WARN, ERROR)
- `event_type`: Type of operation
- `service_name`: Role name
- `status`: Operation status
- `user`: User executing the role
- `host`: Target host
- `playbook`: Playbook name
- `task`: Task name
- `correlation_id`: Unique identifier for tracing
- `message`: Human-readable message
- `metadata`: Additional context information

### Example Log Entry

```json
{
  "timestamp": "2024-01-15T10:30:45.123456Z",
  "level": "INFO",
  "event_type": "SECRETS_IMPORT",
  "service_name": "proxmox_import_config",
  "status": "SUCCESS",
  "user": "ansible",
  "host": "web-server-01",
  "playbook": "deploy-containers",
  "task": "Import secrets from file",
  "correlation_id": "1705312245",
  "message": "Secrets file imported successfully",
  "metadata": {
    "secrets_file_path": "/etc/ansible/VARS/secrets.yaml",
    "variables_loaded": 15,
    "host_vars_prefix": "web_server_01"
  }
}
```

## Error Handling

The role implements comprehensive error handling:

1. **Error Detection**: Failed operations are caught and logged
2. **Detailed Logging**: All error operations are logged with full context
3. **Graceful Failure**: Operations fail gracefully with descriptive error messages

### Error Scenarios

- **Secrets Import Failure**: Log error details and fail gracefully
- **Host Variables Import Failure**: Log error details and fail gracefully
- **YAML Syntax Errors**: Log error details and fail gracefully
- **Missing Variables**: Validate and report missing required variables

## Validation Features

### File Validation
- Check file existence and readability
- Validate YAML syntax using Python's yaml module
- Verify file permissions and ownership

### Structure Validation
- Validate required variables are present
- Check variable naming conventions
- Verify data types and formats

### Strict Validation Mode
When `strict_validation: true`:
- All YAML files must have valid syntax
- All required variables must be present
- File permissions are validated
- Inventory host existence is verified

## Tags

The role supports the following tags for selective execution:

- `always`: Always executed tasks
- `validate`: Validation tasks
- `preflight`: Pre-execution checks
- `import`: Import operations
- `secrets`: Secrets-related tasks
- `host_vars`: Host variables tasks
- `logging`: Logging tasks
- `debug`: Debug output tasks
- `summary`: Summary tasks

### Example: Run only validation

```bash
ansible-playbook playbook.yml --tags validate
```

### Example: Run with debug output

```bash
ansible-playbook playbook.yml --tags debug
```

## Troubleshooting

### Common Issues

1. **File Not Found**
   - Verify file paths are correct
   - Check file permissions
   - Ensure files exist before running the role

2. **YAML Syntax Errors**
   - Use `debug_mode: true` to see detailed error messages
   - Validate YAML syntax manually
   - Check for indentation issues

3. **Missing Variables**
   - Verify variable names match the expected prefix
   - Check secrets file structure
   - Ensure all required variables are defined

4. **Permission Issues**
   - Check file permissions on secrets and host_vars files
   - Verify backup directory is writable
   - Ensure log file directory exists and is writable

### Debug Mode

Enable debug mode for detailed output:

```yaml
vars:
  debug_mode: true
```

### Log Analysis

Check the structured log file for detailed operation information:

```bash
tail -f /var/log/ansible-changes.log | jq .
```

## Security Considerations

- **Sensitive Data**: Use `debug_sensitive: false` in production
- **File Permissions**: Ensure secrets files have restricted permissions (600)
- **Log Security**: Log files may contain sensitive information

## Performance Optimization

- **Async Operations**: Long-running operations use async with configurable timeouts
- **Minimal Facts**: Only required facts are gathered
- **Efficient Validation**: Validation is performed only when needed
- **Selective Execution**: Use tags to run only required tasks

## Integration

This role is designed to work with other Proxmox-related roles:

1. **Configuration Import**: This role (imports configuration)
2. **Container Creation**: Create LXC containers using imported configuration
3. **Container Configuration**: Configure container settings
4. **Service Deployment**: Deploy services to containers

## License

MIT

## Author

Mad-Axell <mad.axell@gmail.com>

