# DNS AdGuard Home Role

Ansible role for installing and configuring AdGuard Home - a network-wide ad blocking DNS server with web interface.

Ansible-роль для установки и настройки AdGuard Home - сетевого DNS-сервера для блокировки рекламы с веб-интерфейсом.

## Features / Возможности

- **Ad blocking** - Network-wide ad and tracker blocking
- **Web interface** - Easy-to-use administration panel
- **Custom filtering** - Blocklists, allowlists, and user rules
- **DNS rewrites** - Custom DNS responses
- **Query logging** - Detailed DNS query statistics
- **Safe browsing** - Malware and phishing protection
- **Parental control** - Optional adult content blocking

## Requirements / Требования

- Ansible >= 2.10
- Target OS: Debian 11/12, Ubuntu 20.04/22.04/24.04, RHEL/CentOS 8/9
- `community.general` collection (for `github_release` module)

## Role Variables / Переменные роли

### DNS Settings / Настройки DNS

| Variable | Default | Description |
|----------|---------|-------------|
| `adguard_dns_port` | `53` | DNS listen port |
| `adguard_upstream_dns` | `["127.0.0.1:5335"]` | Upstream DNS servers |
| `adguard_bootstrap_dns` | `["1.1.1.1", "8.8.8.8", "9.9.9.9"]` | Bootstrap DNS |
| `adguard_fallback_dns` | `[]` | Fallback DNS servers |
| `adguard_blocking_mode` | `default` | Blocking mode |
| `adguard_ratelimit` | `0` | Rate limit (0 = unlimited) |

### Web Interface / Веб-интерфейс

| Variable | Default | Description |
|----------|---------|-------------|
| `adguard_web_port` | `3000` | Web UI port |
| `adguard_web_bind` | `0.0.0.0` | Web UI bind address |
| `adguard_language` | `""` | UI language (empty = browser) |
| `adguard_theme` | `auto` | UI theme: auto, light, dark |

### Authentication / Аутентификация

| Variable | Default | Description |
|----------|---------|-------------|
| `adguard_admin_username` | `admin` | Admin username |
| `adguard_admin_password` | `""` | Admin password (plain text) |
| `adguard_admin_password_hash` | `""` | Admin password (bcrypt hash) |
| `adguard_session_ttl` | `720h` | Session TTL |
| `adguard_auth_attempts` | `5` | Auth attempts before block |

> **Important**: Use `ansible-vault` to encrypt `adguard_admin_password`!
>
> **Важно**: Используйте `ansible-vault` для шифрования `adguard_admin_password`!

### Filtering / Фильтрация

| Variable | Default | Description |
|----------|---------|-------------|
| `adguard_filtering_enabled` | `true` | Enable filtering |
| `adguard_safebrowsing_enabled` | `true` | Safe browsing |
| `adguard_parental_enabled` | `false` | Parental control |
| `adguard_safesearch_enabled` | `false` | Force safe search |

### Blocklists / Списки блокировки

```yaml
adguard_blocklists:
  - name: "AdGuard DNS filter"
    url: "https://adguardteam.github.io/AdGuardSDNSFilter/Filters/filter.txt"
    enabled: true
  - name: "AdAway Default Blocklist"
    url: "https://adaway.org/hosts.txt"
    enabled: true

adguard_extra_blocklists:
  - name: "OISD Big"
    url: "https://big.oisd.nl"
    enabled: true
```

### User Rules / Пользовательские правила

```yaml
adguard_user_rules:
  - "||ads.example.com^"           # Block domain
  - "@@||safe.example.com^"        # Allow domain
  - "/^ad[0-9]*\\./"               # Regex block
```

### DNS Rewrites / DNS перезаписи

```yaml
adguard_dns_rewrites:
  - domain: "*.home"
    answer: "192.168.1.100"
  - domain: "router.local"
    answer: "192.168.1.1"
```

### Logging & Statistics / Логирование и статистика

| Variable | Default | Description |
|----------|---------|-------------|
| `adguard_querylog_enabled` | `true` | Enable query log |
| `adguard_querylog_interval` | `168h` | Log retention (7 days) |
| `adguard_stats_enabled` | `true` | Enable statistics |
| `adguard_stats_interval` | `168h` | Stats retention (7 days) |

### Service Settings / Настройки сервиса

| Variable | Default | Description |
|----------|---------|-------------|
| `adguard_version` | `latest` | AdGuard Home version |
| `adguard_user` | `root` | Service user |
| `adguard_service_enable` | `true` | Enable systemd service |
| `adguard_service_start` | `true` | Start service |
| `adguard_deploy_config` | `true` | Deploy config template |
| `adguard_disable_systemd_dnsstubresolver` | `true` | Disable systemd-resolved stub |

## Example Playbook / Пример плейбука

### Standalone usage / Автономное использование

```yaml
- hosts: dns_servers
  become: true
  roles:
    - role: dns_adguard
      vars:
        adguard_admin_password: "{{ vault_adguard_password }}"
        adguard_upstream_dns:
          - "1.1.1.1"
          - "8.8.8.8"
```

### With Unbound backend / С бэкендом Unbound

```yaml
- hosts: dns_servers
  become: true
  roles:
    - role: dns_unbound
      vars:
        unbound_interface: "127.0.0.1"
        unbound_port: 5335

    - role: dns_adguard
      vars:
        adguard_admin_password: "{{ vault_adguard_password }}"
        adguard_upstream_dns:
          - "127.0.0.1:5335"
```

### Full configuration / Полная конфигурация

```yaml
- hosts: dns_servers
  become: true
  roles:
    - role: dns_adguard
      vars:
        adguard_admin_username: "admin"
        adguard_admin_password: "{{ vault_adguard_password }}"
        adguard_web_port: 8080
        adguard_dns_port: 53
        adguard_filtering_enabled: true
        adguard_safebrowsing_enabled: true
        adguard_extra_blocklists:
          - name: "OISD"
            url: "https://big.oisd.nl"
            enabled: true
        adguard_dns_rewrites:
          - domain: "nas.home"
            answer: "192.168.1.50"
```

## Files Created / Создаваемые файлы

- `/opt/adguardhome/bin/AdGuardHome` - Binary file
- `/opt/adguardhome/config/AdGuardHome.yaml` - Configuration
- `/etc/systemd/system/adguardhome.service` - Systemd unit

## Ports Used / Используемые порты

| Port | Protocol | Description |
|------|----------|-------------|
| 53 | TCP/UDP | DNS queries |
| 3000 | TCP | Web interface |

## Testing / Тестирование

```bash
# Check service status
systemctl status adguardhome

# Test DNS resolution
dig @localhost example.com

# Test ad blocking (should return 0.0.0.0 or NXDOMAIN)
dig @localhost ads.google.com

# Access web interface
curl http://localhost:3000/control/status
```

## Integration with Unbound / Интеграция с Unbound

For optimal performance and DNSSEC validation, use AdGuard Home with Unbound:

Для оптимальной производительности и валидации DNSSEC используйте AdGuard Home с Unbound:

```
Client → AdGuard Home (port 53) → Unbound (port 5335) → Internet
          ↓                         ↓
    Ad blocking              DNSSEC validation
    Filtering                Caching
    Statistics               Rate limiting
```

Benefits / Преимущества:
- AdGuard Home handles filtering, logging, and statistics
- Unbound handles DNSSEC validation and caching
- Separation of concerns for better maintainability

## License

MIT

## Author

Infrastructure Team
