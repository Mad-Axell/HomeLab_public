# UFW Configuration Role

This Ansible role configures Uncomplicated Firewall (UFW) with security best practices for Ubuntu/Debian systems.

## Features

- **Secure Default Configuration**: Deny incoming, allow outgoing by default
- **SSH Access Control**: Configurable SSH access from specific subnets
- **Rate Limiting**: Optional SSH rate limiting to prevent brute force attacks
- **Custom Rules**: Flexible custom firewall rules
- **Input Validation**: Comprehensive validation of all parameters
- **Logging Configuration**: Configurable logging levels
- **Idempotent**: Safe to run multiple times

## Requirements

- Ansible 2.9+
- Ubuntu/Debian target systems
- `community.general` collection

## Role Variables

### Basic Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `debug_mode` | `false` | Enable verbose output |
| `ssh_port` | `22` | SSH port number |
| `ssh_protocol` | `"tcp"` | SSH protocol (tcp/udp) |
| `allowed_ssh_subnets` | `["192.168.1.0/24", "10.20.30.0/24"]` | List of subnets allowed SSH access |

### UFW Policies

| Variable | Default | Description |
|----------|---------|-------------|
| `ufw_default_incoming` | `"deny"` | Default incoming policy |
| `ufw_default_outgoing` | `"allow"` | Default outgoing policy |
| `ufw_logging` | `"low"` | Logging level (off/low/medium/high/full) |
| `ufw_state` | `"enabled"` | UFW state (enabled/disabled/reset) |

### Security Features

| Variable | Default | Description |
|----------|---------|-------------|
| `ssh_rate_limit` | `true` | Enable SSH rate limiting |
| `ssh_rate_limit_attempts` | `6` | Number of attempts before rate limiting |
| `ssh_rate_limit_time` | `30` | Time window for rate limiting (seconds) |

### Custom Rules

| Variable | Default | Description |
|----------|---------|-------------|
| `ufw_rules` | `[{"rule": "allow", "port": "80", "proto": "tcp", "comment": "HTTP"}, {"rule": "allow", "port": "443", "proto": "tcp", "comment": "HTTPS"}]` | List of custom UFW rules |

### Validation

| Variable | Default | Description |
|----------|---------|-------------|
| `validate_configuration` | `true` | Enable input validation |
| `fail_on_validation_error` | `true` | Fail playbook on validation errors |

## Custom UFW Rules Format

```yaml
ufw_rules:
  - rule: "allow"           # allow, deny, reject, limit
    port: "80"              # port number or service name
    proto: "tcp"            # tcp or udp
    from_ip: "192.168.1.0/24"  # optional: restrict to specific IP/subnet
    comment: "HTTP access"  # optional: rule description
```

## Example Playbook

### Basic Usage

```yaml
- hosts: servers
  roles:
    - role: base/configure_ufw
```

### Advanced Configuration

```yaml
- hosts: servers
  vars:
    allowed_ssh_subnets:
      - "10.0.0.0/8"
      - "172.16.0.0/12"
    ssh_port: 2222
    ufw_rules:
      - rule: "allow"
        port: "80"
        proto: "tcp"
        comment: "HTTP"
      - rule: "allow"
        port: "443"
        proto: "tcp"
        comment: "HTTPS"
      - rule: "allow"
        port: "3306"
        proto: "tcp"
        from_ip: "10.0.0.0/8"
        comment: "MySQL from internal network"
    ssh_rate_limit: true
    ufw_logging: "medium"
  roles:
    - role: base/configure_ufw
```

### Production Environment

```yaml
- hosts: production_servers
  vars:
    allowed_ssh_subnets:
      - "10.1.0.0/16"  # Management network
    ufw_rules:
      - rule: "allow"
        port: "443"
        proto: "tcp"
        comment: "HTTPS only"
    ssh_rate_limit: true
    ssh_rate_limit_attempts: 3
    ssh_rate_limit_time: 60
    ufw_logging: "high"
    debug_mode: false
  roles:
    - role: base/configure_ufw
```

## Security Best Practices

1. **Restrict SSH Access**: Only allow SSH from trusted subnets
2. **Use Non-Standard SSH Port**: Consider changing from port 22
3. **Enable Rate Limiting**: Prevent brute force attacks
4. **Minimal Rule Set**: Only allow necessary ports
5. **Regular Logging**: Monitor firewall activity
6. **Test Configuration**: Always test in staging environment first

## Dependencies

This role has no dependencies on other roles.

## License

This role is licensed under the MIT License.

## Author Information

Created for HomeLab infrastructure management.
