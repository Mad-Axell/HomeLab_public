# DNS Unbound Role

Ansible role for installing and configuring Unbound DNS resolver with DNSSEC validation, caching, and security hardening.

Ansible-роль для установки и настройки DNS-резолвера Unbound с валидацией DNSSEC, кэшированием и усилением безопасности.

## Features / Возможности

- **DNSSEC validation** - Validates DNS responses using DNSSEC
- **Caching** - High-performance DNS caching with configurable sizes
- **Cache persistence** - Saves cache to disk for faster startup
- **Security hardening** - Multiple security options enabled by default
- **Rate limiting** - Protection against DDoS attacks
- **Forward zone support** - Optional DNS-over-TLS forwarding
- **Local zones** - Support for local DNS records

## Requirements / Требования

- Ansible >= 2.10
- Target OS: Debian 11/12, Ubuntu 20.04/22.04/24.04, RHEL/CentOS 8/9

## Role Variables / Переменные роли

### Network / Сеть

| Variable | Default | Description |
|----------|---------|-------------|
| `unbound_interface` | `127.0.0.1` | Listen interface |
| `unbound_port` | `5335` | Listen port |
| `unbound_do_ip4` | `yes` | Enable IPv4 |
| `unbound_do_ip6` | `no` | Enable IPv6 |

### Cache / Кэширование

| Variable | Default | Description |
|----------|---------|-------------|
| `unbound_msg_cache_size` | `128m` | Message cache size |
| `unbound_rrset_cache_size` | `256m` | RRset cache size |
| `unbound_cache_min_ttl` | `300` | Minimum TTL (seconds) |
| `unbound_cache_max_ttl` | `14400` | Maximum TTL (seconds) |
| `unbound_cache_dump_enabled` | `true` | Enable cache persistence |
| `unbound_cache_dump_interval` | `30min` | Cache dump interval |

### DNSSEC

| Variable | Default | Description |
|----------|---------|-------------|
| `unbound_dnssec_enabled` | `true` | Enable DNSSEC validation |
| `unbound_harden_dnssec_stripped` | `true` | Require DNSSEC data |
| `unbound_harden_below_nxdomain` | `true` | Harden below NXDOMAIN |

### Security / Безопасность

| Variable | Default | Description |
|----------|---------|-------------|
| `unbound_hide_identity` | `true` | Hide server identity |
| `unbound_hide_version` | `true` | Hide server version |
| `unbound_qname_minimisation` | `true` | QNAME minimisation (RFC 7816) |
| `unbound_use_caps_for_id` | `true` | CAPS randomization |
| `unbound_rate_limit` | `100` | Rate limit (0 = disabled) |

### Access Control / Контроль доступа

```yaml
unbound_access_control:
  - subnet: "127.0.0.0/8"
    action: "allow"
  - subnet: "192.168.1.0/24"
    action: "allow"
```

### Forward Zone / Зона пересылки

```yaml
unbound_use_forward_zone: true
unbound_forward_tls: true
unbound_forward_servers:
  - addr: "1.1.1.1@853"
    name: "cloudflare-dns.com"
  - addr: "9.9.9.9@853"
    name: "dns.quad9.net"
```

### Local Zones / Локальные зоны

```yaml
unbound_local_zones:
  - name: "home."
    type: "static"

unbound_local_data:
  - "server.home. 3600 IN A 192.168.1.100"
  - "nas.home. 3600 IN A 192.168.1.101"

unbound_local_data_ptr:
  - "192.168.1.100 server.home."
  - "192.168.1.101 nas.home."
```

## Example Playbook / Пример плейбука

### Basic usage / Базовое использование

```yaml
- hosts: dns_servers
  become: true
  roles:
    - role: dns_unbound
```

### With custom settings / С настройками

```yaml
- hosts: dns_servers
  become: true
  roles:
    - role: dns_unbound
      vars:
        unbound_interface: "0.0.0.0"
        unbound_port: 53
        unbound_access_control:
          - subnet: "127.0.0.0/8"
            action: "allow"
          - subnet: "192.168.0.0/16"
            action: "allow"
        unbound_rate_limit: 200
```

### With AdGuard Home / С AdGuard Home

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
        adguard_upstream_dns:
          - "127.0.0.1:5335"
```

## Bug Fixes / Исправления ошибок

### root.key duplication fix / Исправление дублирования root.key

This role includes a fix for the `/var/lib/unbound/root.key` duplication bug. The issue occurs when:
1. The `unbound-anchor` package creates `root.key` during installation
2. Subsequent runs of `unbound-anchor` append data instead of replacing

The fix:
- Checks for duplicate DNSKEY entries in `root.key`
- Removes corrupted file if duplicates are found
- Regenerates the trust anchor using `unbound-anchor`

Эта роль включает исправление бага с дублированием в `/var/lib/unbound/root.key`. Проблема возникает когда:
1. Пакет `unbound-anchor` создаёт `root.key` при установке
2. Повторные запуски `unbound-anchor` добавляют данные вместо замены

Исправление:
- Проверяет наличие дублирующихся записей DNSKEY в `root.key`
- Удаляет повреждённый файл при обнаружении дубликатов
- Регенерирует якорь доверия с помощью `unbound-anchor`

## Files Created / Создаваемые файлы

- `/etc/unbound/unbound.conf.d/dns-unbound.conf` - Main configuration
- `/var/lib/unbound/root.hints` - Root hints file
- `/var/lib/unbound/root.key` - DNSSEC trust anchor
- `/var/lib/unbound/cache.dump` - Cache dump file (if enabled)
- `/etc/systemd/system/unbound-cache-dump.service` - Cache dump service
- `/etc/systemd/system/unbound-cache-dump.timer` - Cache dump timer
- `/etc/systemd/system/unbound-cache-load.service` - Cache load service

## Testing / Тестирование

```bash
# Check configuration
unbound-checkconf /etc/unbound/unbound.conf.d/dns-unbound.conf

# Test DNS resolution
dig @127.0.0.1 -p 5335 example.com

# Test DNSSEC (should return SERVFAIL)
dig @127.0.0.1 -p 5335 dnssec-failed.org

# Check cache statistics
unbound-control stats_noreset
```

## License

MIT

## Author

Infrastructure Team
