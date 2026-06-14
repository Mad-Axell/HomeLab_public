# NS Server Role

DNS-сервер с блокировкой рекламы и защитой от атак на базе **Unbound** и **AdGuard Home**.

## Описание

Роль устанавливает и настраивает полноценный DNS-сервер с:
- Рекурсивным разрешением имён (Unbound)
- Блокировкой рекламы и трекеров (AdGuard Home)
- Защитой от DNS-атак (DDoS, cache poisoning, rebinding)
- Валидацией DNSSEC
- Сохранением кэша между перезагрузками

```
Клиент → AdGuard Home (порт 53) → Unbound (порт 5335) → Корневые DNS серверы
           │                          │
           ▼                          ▼
     Фильтрация рекламы         Рекурсивное разрешение
     Блокировка трекеров        DNSSEC валидация
     Safe Browsing              Кэширование
     Веб-интерфейс              Rate limiting
```

## Функции безопасности

### Защита от атак

| Механизм | Описание |
|----------|----------|
| **Rate Limiting** | Ограничение запросов на клиента (защита от DDoS) |
| **CAPS Randomization** | Рандомизация регистра (защита от cache poisoning) |
| **DNSSEC** | Валидация подписей DNS |
| **Aggressive NSEC** | Улучшенное кеширование NXDOMAIN |
| **QNAME Minimisation** | Минимизация утечки информации |
| **DNS Rebinding Protection** | Блокировка приватных адресов в ответах |

### Блокировка контента

| Функция | Описание |
|---------|----------|
| **Blocklists** | Предустановленные списки рекламы/трекеров |
| **Safe Browsing** | Защита от фишинга и малвари |
| **Parental Control** | Родительский контроль (опционально) |
| **Safe Search** | Принудительный безопасный поиск |

## Требования

- Ansible >= 2.10
- Debian/Ubuntu или RHEL/CentOS 8+
- Python `passlib` на control node (для хеширования паролей bcrypt)
- Python `github3.py` на целевых хостах (устанавливается автоматически при `adguardhome_version: latest`)

```bash
# Установка passlib
pip install passlib bcrypt
```

## Установка

```yaml
- hosts: dns_servers
  roles:
    - ns_server
```

## Переменные

### Unbound - Сеть

| Переменная | По умолчанию | Описание |
|------------|--------------|----------|
| `unbound_interface` | `127.0.0.1` | Интерфейс для прослушивания |
| `unbound_port` | `5335` | Порт Unbound |
| `unbound_do_ip4` | `true` | Поддержка IPv4 |
| `unbound_do_ip6` | `false` | Поддержка IPv6 |
| `unbound_do_udp` | `true` | Поддержка UDP |
| `unbound_do_tcp` | `true` | Поддержка TCP |

### Unbound - Производительность

| Переменная | По умолчанию | Описание |
|------------|--------------|----------|
| `unbound_num_threads` | `{{ ansible_processor_vcpus }}` | Количество потоков |
| `unbound_msg_cache_slabs` | `4` | Слоты кэша сообщений |
| `unbound_rrset_cache_slabs` | `4` | Слоты кэша записей |
| `unbound_so_rcvbuf` | `1m` | Буфер приёма сокета |
| `unbound_so_sndbuf` | `1m` | Буфер отправки сокета |

### Unbound - Кэширование

| Переменная | По умолчанию | Описание |
|------------|--------------|----------|
| `unbound_msg_cache_size` | `128m` | Размер кэша сообщений |
| `unbound_rrset_cache_size` | `256m` | Размер кэша записей |
| `unbound_cache_min_ttl` | `300` | Минимальный TTL (сек) |
| `unbound_cache_max_ttl` | `14400` | Максимальный TTL (4 часа) |
| `unbound_neg_cache_size` | `4m` | Размер негативного кэша |

### Unbound - Сохранение кэша в файл

| Переменная | По умолчанию | Описание |
|------------|--------------|----------|
| `unbound_cache_dump_enabled` | `true` | Включить сохранение кэша |
| `unbound_cache_dump_file` | `/var/lib/unbound/cache.dump` | Путь к файлу |
| `unbound_cache_dump_interval` | `30min` | Интервал сохранения |

### Unbound - DNSSEC

| Переменная | По умолчанию | Описание |
|------------|--------------|----------|
| `unbound_dnssec_enabled` | `true` | Включить DNSSEC |
| `unbound_harden_dnssec_stripped` | `true` | Отклонять без подписи |
| `unbound_harden_below_nxdomain` | `true` | Защита NXDOMAIN |
| `unbound_harden_glue` | `true` | Проверка глю-записей |

### Unbound - Безопасность

| Переменная | По умолчанию | Описание |
|------------|--------------|----------|
| `unbound_hide_identity` | `true` | Скрыть identity сервера |
| `unbound_hide_version` | `true` | Скрыть версию |
| `unbound_qname_minimisation` | `true` | Минимизация QNAME |
| `unbound_use_caps_for_id` | `true` | CAPS рандомизация |
| `unbound_harden_referral_path` | `true` | Проверка пути делегирования |
| `unbound_harden_algo_downgrade` | `true` | Запрет понижения алгоритма |
| `unbound_aggressive_nsec` | `true` | Агрессивный NSEC (RFC 8198) |

### Unbound - Rate Limiting (защита от DDoS)

| Переменная | По умолчанию | Описание |
|------------|--------------|----------|
| `unbound_rate_limit` | `100` | Запросов/сек на клиента (0 = выкл) |
| `unbound_rate_limit_size` | `4m` | Размер таблицы rate limit |
| `unbound_rate_limit_slabs` | `4` | Слоты rate limit |

### Unbound - Оптимизация

| Переменная | По умолчанию | Описание |
|------------|--------------|----------|
| `unbound_prefetch` | `true` | Предзагрузка кэша |
| `unbound_prefetch_key` | `true` | Предзагрузка DNSSEC ключей |
| `unbound_serve_expired` | `true` | Отдавать просроченные записи |
| `unbound_serve_expired_ttl` | `3600` | TTL просроченных записей |

### Unbound - Логирование

| Переменная | По умолчанию | Описание |
|------------|--------------|----------|
| `unbound_verbosity` | `1` | Уровень логирования (0-5) |
| `unbound_log_queries` | `false` | Логировать запросы |
| `unbound_log_replies` | `false` | Логировать ответы |
| `unbound_log_servfail` | `true` | Логировать SERVFAIL |

### Unbound - Контроль доступа

```yaml
unbound_access_control:
  - subnet: "127.0.0.0/8"
    action: "allow"
  - subnet: "192.168.0.0/16"
    action: "allow"
```

### Unbound - Локальные зоны

```yaml
unbound_local_zones:
  - name: "home."
    type: "static"

unbound_local_data:
  - "server.home. 3600 IN A 192.168.1.100"
  - "nas.home. 3600 IN A 192.168.1.101"

unbound_local_data_ptr:
  - "192.168.1.100 server.home."
```

### Unbound - Пересылка (Forward Zone)

| Переменная | По умолчанию | Описание |
|------------|--------------|----------|
| `unbound_use_forward_zone` | `false` | Использовать пересылку вместо рекурсии |
| `unbound_forward_tls` | `false` | Шифрование (DoT) |

```yaml
unbound_forward_servers:
  - addr: "1.1.1.1@853"
    name: "cloudflare-dns.com"
  - addr: "9.9.9.9@853"
    name: "dns.quad9.net"
```

### Unbound - Условная пересылка

```yaml
unbound_conditional_forward:
  - zone: "corp.local"
    forward_addr: "192.168.1.1"
  - zone: "10.in-addr.arpa"
    forward_addr: "192.168.1.1"
```

---

### AdGuard Home - Основные

| Переменная | По умолчанию | Описание |
|------------|--------------|----------|
| `ns_server_install_adguard` | `true` | Установить AdGuard Home |
| `adguard_deploy_config` | `true` | Развернуть конфиг |
| `adguard_dns_port` | `53` | Порт DNS |
| `adguard_blocking_mode` | `default` | Режим блокировки |
| `adguard_ratelimit` | `0` | Rate limit (0 = выкл) |

### AdGuard Home - Аутентификация ⭐

| Переменная | По умолчанию | Описание |
|------------|--------------|----------|
| `adguard_admin_username` | `admin` | Имя администратора |
| `adguard_admin_password` | `""` | Пароль (открытый текст) |
| `adguard_admin_password_hash` | `""` | Готовый bcrypt хеш пароля |
| `adguard_session_ttl` | `720h` | Время жизни сессии |
| `adguard_auth_attempts` | `5` | Попыток до блокировки |
| `adguard_block_auth_min` | `15` | Минут блокировки |

**Важно:** Если указан `adguard_admin_password` или `adguard_admin_password_hash`, 
веб-интерфейс будет доступен сразу без первичной настройки!

#### Генерация хеша пароля

```bash
# Вариант 1: htpasswd
htpasswd -bnBC 10 "" "your_password" | tr -d ':\n'

# Вариант 2: Python
python3 -c "import bcrypt; print(bcrypt.hashpw(b'your_password', bcrypt.gensalt(10)).decode())"
```

### AdGuard Home - Веб-интерфейс

| Переменная | По умолчанию | Описание |
|------------|--------------|----------|
| `adguard_web_port` | `3000` | Порт веб-интерфейса |
| `adguard_web_bind` | `0.0.0.0` | Адрес привязки |
| `adguard_language` | `""` | Язык (пусто = браузер) |
| `adguard_theme` | `auto` | Тема: auto, light, dark |

### AdGuard Home - Upstream DNS

```yaml
# Основной DNS (Unbound)
adguard_upstream_dns:
  - "127.0.0.1:5335"

# Bootstrap DNS (для DoH/DoT)
adguard_bootstrap_dns:
  - "1.1.1.1"
  - "8.8.8.8"
  - "9.9.9.9"

# Резервный DNS
adguard_fallback_dns: []
```

### AdGuard Home - Фильтрация

| Переменная | По умолчанию | Описание |
|------------|--------------|----------|
| `adguard_filtering_enabled` | `true` | Включить фильтрацию |
| `adguard_safebrowsing_enabled` | `true` | Safe Browsing |
| `adguard_parental_enabled` | `false` | Родительский контроль |
| `adguard_safesearch_enabled` | `false` | Безопасный поиск |

### AdGuard Home - Списки блокировки

```yaml
# Списки по умолчанию
adguard_blocklists:
  - name: "AdGuard DNS filter"
    url: "https://adguardteam.github.io/AdGuardSDNSFilter/Filters/filter.txt"
    enabled: true
  - name: "AdAway Default Blocklist"
    url: "https://adaway.org/hosts.txt"
    enabled: true
  - name: "Steven Black's Unified Hosts"
    url: "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts"
    enabled: true

# Дополнительные списки
adguard_extra_blocklists:
  - name: "OISD Big"
    url: "https://big.oisd.nl"
    enabled: true
```

### AdGuard Home - Пользовательские правила

```yaml
adguard_user_rules:
  - "||ads.example.com^"        # Блокировать домен
  - "@@||safe.example.com^"     # Разрешить домен
  - "/^ad[0-9]*\\./"            # Regex блокировка
```

### AdGuard Home - DNS перезаписи

```yaml
adguard_dns_rewrites:
  - domain: "*.home"
    answer: "192.168.1.100"
  - domain: "router.local"
    answer: "192.168.1.1"
```

### AdGuard Home - Логи и статистика

| Переменная | По умолчанию | Описание |
|------------|--------------|----------|
| `adguard_querylog_enabled` | `true` | Журнал запросов |
| `adguard_querylog_interval` | `7d` | Период хранения логов |
| `adguard_stats_enabled` | `true` | Статистика |
| `adguard_stats_interval` | `7d` | Период статистики |

---

### Мониторинг

| Переменная | По умолчанию | Описание |
|------------|--------------|----------|
| `ns_server_deploy_healthcheck` | `true` | Развернуть скрипт проверки |
| `ns_server_healthcheck_path` | `/usr/local/bin/dns-health-check.sh` | Путь к скрипту |

---

## Примеры использования

### Минимальная конфигурация (с автонастройкой AdGuard)

```yaml
- hosts: dns_server
  vars:
    # Учётные данные AdGuard Home
    adguard_admin_username: "admin"
    adguard_admin_password: "{{ vault_adguard_password }}"  # Из vault!
  roles:
    - ns_server
```

После установки сразу заходите на `http://<IP>:3000` с указанными credentials.

### С готовым хешем пароля (безопаснее)

```yaml
- hosts: dns_server
  vars:
    adguard_admin_username: "admin"
    # Сгенерировать: htpasswd -bnBC 10 "" "password" | tr -d ':\n'
    adguard_admin_password_hash: "$2y$10$ABC123..."
  roles:
    - ns_server
```

### Расширенная конфигурация для homelab

```yaml
- hosts: dns_server
  vars:
    # AdGuard Home credentials
    adguard_admin_username: "admin"
    adguard_admin_password: "{{ vault_adguard_password }}"
    
    # Разрешить доступ из локальной сети
    unbound_access_control:
      - subnet: "127.0.0.0/8"
        action: "allow"
      - subnet: "192.168.1.0/24"
        action: "allow"
    
    # Увеличенный кэш
    unbound_msg_cache_size: "256m"
    unbound_rrset_cache_size: "512m"
    
    # Локальные DNS записи
    unbound_local_zones:
      - name: "home."
        type: "static"
    
    unbound_local_data:
      - "router.home. 3600 IN A 192.168.1.1"
      - "dns.home. 3600 IN A 192.168.1.10"
      - "nas.home. 3600 IN A 192.168.1.20"
    
    # DNS rewrites для локальных сервисов
    adguard_dns_rewrites:
      - domain: "plex.home"
        answer: "192.168.1.30"
    
    # Дополнительные списки блокировки
    adguard_extra_blocklists:
      - name: "OISD Big"
        url: "https://big.oisd.nl"
        enabled: true
    
    # Родительский контроль
    adguard_parental_enabled: true
    adguard_safesearch_enabled: true
  
  roles:
    - ns_server
```

### Приватный DNS с DoT upstream

```yaml
- hosts: dns_server
  vars:
    # Использовать DoT вместо рекурсии
    unbound_use_forward_zone: true
    unbound_forward_tls: true
    unbound_forward_servers:
      - addr: "1.1.1.1@853"
        name: "cloudflare-dns.com"
      - addr: "9.9.9.9@853"
        name: "dns.quad9.net"
  roles:
    - ns_server
```

### Для Raspberry Pi (минимальные ресурсы)

```yaml
- hosts: raspberry_pi
  vars:
    unbound_num_threads: 1
    unbound_msg_cache_size: "32m"
    unbound_rrset_cache_size: "64m"
    unbound_rate_limit: 50
    adguard_querylog_interval: "24h"
  roles:
    - ns_server
```

---

## Проверка работы

### Скрипт проверки здоровья

```bash
# Запуск проверки
sudo /usr/local/bin/dns-health-check.sh

# Пример вывода:
# === Unbound DNS Resolver ===
# ✓ Unbound service is running
# ✓ Unbound resolves example.com
# ✓ DNSSEC validation is working
#   Cache hit rate: 85% (1234/1452)
#
# === AdGuard Home ===
# ✓ AdGuard Home service is running
# ✓ AdGuard Home resolves example.com
# ✓ AdGuard Home web interface is accessible
# ✓ Ad blocking is working (ads.google.com blocked)
```

### Ручные проверки

```bash
# Проверка Unbound
dig @127.0.0.1 -p 5335 example.com

# Проверка DNSSEC
dig @127.0.0.1 -p 5335 example.com +dnssec

# Проверка блокировки рекламы
dig @127.0.0.1 -p 53 ads.google.com

# Статистика Unbound
sudo unbound-control stats
```

---

## Troubleshooting

### Unbound не запускается

```bash
# Проверка конфигурации
sudo unbound-checkconf

# Логи
sudo journalctl -u unbound -f
```

### AdGuard не блокирует рекламу

1. Проверьте, что upstream DNS настроен на `127.0.0.1:5335`
2. Проверьте, что фильтр-листы загружены (Settings → Filters)
3. Убедитесь, что filtering_enabled = true

### Медленные запросы

```bash
# Проверка времени отклика
time dig @127.0.0.1 -p 5335 google.com

# Включить prefetch если отключен
unbound_prefetch: true
unbound_serve_expired: true
```

---

## Безопасность

### Рекомендации

1. **Используйте ansible-vault** для шифрования паролей
2. **Ограничьте доступ** к DNS через `unbound_access_control`
3. **Измените порт** веб-интерфейса AdGuard (не 3000)
4. **Используйте firewall** для ограничения доступа

### Шифрование пароля с ansible-vault

```bash
# Создать vault файл
ansible-vault create group_vars/dns_servers/vault.yml

# Содержимое:
vault_adguard_password: "your_secure_password"

# Использование в playbook:
adguard_admin_password: "{{ vault_adguard_password }}"
```

### Firewall (UFW)

```bash
# Разрешить DNS из локальной сети
sudo ufw allow from 192.168.1.0/24 to any port 53
sudo ufw allow from 192.168.1.0/24 to any port 3000
```

---

## Лицензия

MIT

## Автор

Infrastructure Team
