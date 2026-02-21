# Практические примеры конфигураций Unbound + AdGuard Home

## Быстрый старт

### Пример 1: Базовая конфигурация для Debian/Ubuntu

#### Установка необходимых пакетов:

```bash
sudo apt update
sudo apt install unbound unbound-anchor curl dnsutils net-tools -y
```

#### Создание конфигурации Unbound:

```bash
sudo nano /etc/unbound/unbound.conf.d/local.conf
```

**Содержание файла:**

```unbound
server:
  # Интерфейсы - слушать только локально для AdGuard
  interface: 127.0.0.1
  interface: ::1
  port: 5335
  
  # Протоколы
  do-ip4: yes
  do-ip6: no
  do-udp: yes
  do-tcp: yes
  
  # Безопасность и производительность
  num-threads: 4
  prefetch: yes
  serve-expired: yes
  serve-expired-ttl: 3600
  
  # Кеширование
  msg-cache-size: 128m
  rrset-cache-size: 256m
  cache-min-ttl: 300
  cache-max-ttl: 14400
  
  # DNSSEC
  auto-trust-anchor-file: "/var/lib/unbound/root.key"
  harden-dnssec-stripped: yes
  
  # Скрытие информации
  hide-identity: yes
  hide-version: yes
  
  # Корневые серверы
  root-hints: "/var/lib/unbound/root.hints"
```

#### Инициализация DNSSEC:

```bash
sudo /usr/lib/unbound/package-helper root_trust_anchor_update
```

#### Запуск сервиса:

```bash
sudo systemctl restart unbound
sudo systemctl enable unbound

# Проверка работы
dig @127.0.0.1 -p 5335 example.com
```

---

### Пример 2: AdGuard Home в Docker с Unbound

#### Структура директорий:

```
dns-stack/
├── docker-compose.yml
├── unbound/
│   └── config/
│       └── local.conf
├── adguard/
│   ├── work/
│   └── conf/
└── redis/
    └── data/
```

#### Создание docker-compose.yml:

```yaml
version: '3.8'

services:
  # Redis для кеша Unbound
  redis:
    image: redis:7-alpine
    container_name: dns-redis
    networks:
      dns-net:
        ipv4_address: 172.16.81.5
    volumes:
      - ./redis/data:/data
    restart: unless-stopped
    command: redis-server --appendonly yes

  # Unbound DNS resolver
  unbound:
    image: klutchell/unbound:latest
    container_name: dns-unbound
    networks:
      dns-net:
        ipv4_address: 172.16.81.10
    ports:
      - "533:53/udp"
      - "533:53/tcp"
    volumes:
      - ./unbound/config/local.conf:/etc/unbound/custom.conf.d/local.conf:ro
    restart: unless-stopped
    depends_on:
      - redis
    healthcheck:
      test: ["CMD", "dig", "@127.0.0.1", "example.com"]
      interval: 30s
      timeout: 5s
      retries: 3

  # AdGuard Home
  adguardhome:
    image: adguard/adguardhome:latest
    container_name: dns-adguard
    networks:
      dns-net:
        ipv4_address: 172.16.81.20
    ports:
      - "53:53/tcp"
      - "53:53/udp"
      - "3000:3000/tcp"      # Web UI
      - "853:853/tcp"        # DoT
      - "853:853/udp"
      - "8443:443/tcp"       # DoH
    volumes:
      - ./adguard/work:/opt/adguardhome/work
      - ./adguard/conf:/opt/adguardhome/conf
    restart: unless-stopped
    depends_on:
      - unbound
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost:3000"]
      interval: 30s
      timeout: 5s
      retries: 3

networks:
  dns-net:
    driver: bridge
    ipam:
      config:
        - subnet: 172.16.81.0/24
```

#### Конфигурация Unbound (unbound/config/local.conf):

```unbound
server:
  interface: 0.0.0.0
  port: 53
  
  # Производительность
  num-threads: 4
  do-ip4: yes
  do-ip6: no
  do-udp: yes
  do-tcp: yes
  
  # Кеширование
  msg-cache-size: 128m
  rrset-cache-size: 256m
  cache-min-ttl: 300
  cache-max-ttl: 14400
  
  # DNSSEC
  auto-trust-anchor-file: "/var/lib/unbound/root.key"
  harden-dnssec-stripped: yes
  harden-glue: yes
  
  # Redis для сохранения кеша
  cachedb:
    backend: redis
    redis-server-host: redis
    redis-server-port: 6379
    redis-timeout: 100
    redis-expire-records: yes

  # Безопасность
  hide-identity: yes
  hide-version: yes
  qname-minimisation: yes
  use-caps-for-id: yes
  
  # Оптимизация
  prefetch: yes
  prefetch-key: yes
  serve-expired: yes
  serve-expired-ttl: 3600
  edns-buffer-size: 1232
```

#### Запуск стека:

```bash
cd dns-stack

# Создание необходимых директорий
mkdir -p adguard/work adguard/conf redis/data

# Запуск контейнеров
docker-compose up -d

# Проверка статуса
docker-compose ps

# Логи
docker-compose logs -f unbound
docker-compose logs -f adguardhome

# Остановка
docker-compose down
```

---

### Пример 3: Конфигурация AdGuard Home с Unbound upstream

#### Перейти в веб-интерфейс:

```
http://192.168.1.100:3000
```

#### Начальная конфигурация:

1. **Установка пароля администратора** (при первом запуске)

2. **DNS Settings:**

```
Порт: 53
Интерфейсы: All interfaces
```

#### Добавление Unbound как upstream:

1. Перейдите: **Settings** → **DNS settings**

2. В разделе **Upstream DNS servers:**

Добавьте строку:
```
127.0.0.1:5335
```

или (для Docker):
```
tcp://172.16.81.10:53
172.16.81.10:53
```

3. **Apply** и **Save**

#### Отключение дублирования кеширования:

1. **Settings** → **DNS settings**
2. Отключить: **"Cache DNS responses"**
3. Отключить: **"Optimize cache size"**

#### Добавление фильтр-листов:

1. **Settings** → **Filters** → **DNS blocklists**

2. Добавьте следующие URL:

```
# AdGuard Base Filter
https://adguardteam.github.io/AdGuardSDNSFilter/Filters/filter.txt

# EasyList
https://easylist-downloads.adblockplus.org/easylist.txt

# uBlock Origin - Ad Servers
https://raw.githubusercontent.com/uBlockOrigin/uAssets/master/filters/filters.txt

# Malware & Phishing
https://raw.githubusercontent.com/DandelionSprout/adfilt/master/Alternate%20versions%20of%20hosts%20files/AdBlock%20Plus%202.0.txt

# NoCoin Filter List
https://raw.githubusercontent.com/hoshsadiq/adblock-nocoin-list/master/nocoin.txt
```

---

## Примеры настроек для разных сценариев

### Сценарий 1: Минимальная footprint (Raspberry Pi)

**Unbound конфиг:**

```unbound
server:
  interface: 127.0.0.1
  port: 5335
  do-ip4: yes
  do-ip6: no
  do-udp: yes
  do-tcp: yes
  
  # Уменьшить требования к памяти
  num-threads: 1
  msg-cache-size: 64m
  rrset-cache-size: 128m
  cache-min-ttl: 300
  cache-max-ttl: 3600
  
  # Основные параметры безопасности
  auto-trust-anchor-file: "/var/lib/unbound/root.key"
  hide-identity: yes
  hide-version: yes
  
  # Минимальное логирование
  verbosity: 0
```

**AdGuard Home:**
- 2-3 основных фильтра
- Отключить логирование по умолчанию
- Включить: Safe Browsing, Parental Control

---

### Сценарий 2: Высокопроизводительный homelab (100+ устройств)

**Unbound конфиг:**

```unbound
server:
  interface: 0.0.0.0
  interface: ::0
  port: 5335
  
  # Максимальная производительность
  num-threads: 8           # Или количество ядер процессора
  msg-cache-size: 256m
  rrset-cache-size: 512m
  cache-min-ttl: 300
  cache-max-ttl: 14400
  
  # Масштабируемость
  msg-cache-slabs: 16
  rrset-cache-slabs: 16
  infra-cache-slabs: 16
  key-cache-slabs: 16
  
  # Оптимизация сокетов
  so-rcvbuf: 2m
  so-sndbuf: 2m
  outgoing-port-permit: 10000-65535
  
  # DNSSEC с предварительной загрузкой
  auto-trust-anchor-file: "/var/lib/unbound/root.key"
  harden-dnssec-stripped: yes
  
  # Agressive caching
  prefetch: yes
  prefetch-key: yes
  serve-expired: yes
  serve-expired-ttl: 7200
  
  # Защита от атак
  rate-limit: 100
  rate-limit-slabs: 4
  unwanted-reply-threshold: 10000000
```

**AdGuard Home:**
- 5-10 фильтр-листов
- Включить все защиты
- Настроить Parental Control по расписанию
- Использовать высокую точность резервного dns

---

### Сценарий 3: Приватность (DoH/DoT)

**Unbound с upstream DoT:**

```unbound
server:
  interface: 127.0.0.1
  port: 5335
  
  # Стандартные параметры
  num-threads: 4
  msg-cache-size: 128m
  rrset-cache-size: 256m
  
  # DNSSEC обязателен
  auto-trust-anchor-file: "/var/lib/unbound/root.key"
  harden-dnssec-stripped: yes
  
  # Минимизация информации
  qname-minimisation: yes
  use-caps-for-id: yes

# Upstream серверы с шифрованием
forward-zone:
  name: "."
  forward-addr: 1.1.1.1@853           # Cloudflare DoT
  forward-addr: 1.0.0.1@853           # Cloudflare DoT
  forward-addr: 9.9.9.9@853           # Quad9 DoT
  forward-tls-upstream: yes
```

**AdGuard Home:**
- Включить DoT на порту 853
- Включить DoH на порту 8443
- Добавить сертификат SSL (Self-signed или Let's Encrypt)
- Отключить сохранение логов (для приватности)

---

## Скрипты для управления

### Скрипт мониторинга:

```bash
#!/bin/bash
# dns-monitor.sh

echo "=== Unbound Status ==="
dig @127.0.0.1 -p 5335 example.com +short
dig @127.0.0.1 -p 5335 example.com +dnssec

echo ""
echo "=== AdGuard Home Status ==="
curl -s http://localhost:3000/control/status | jq '.stats'

echo ""
echo "=== Cache Size ==="
unbound-control -c /etc/unbound/unbound.conf stats | grep cache

echo ""
echo "=== Upstream Check ==="
dig @127.0.0.1 -p 53 example.com +short
```

### Скрипт обновления фильтров (cron job):

```bash
#!/bin/bash
# update-filters.sh

# Обновить фильтры AdGuard Home
curl -s -X POST http://localhost:3000/control/filtering/refresh \
  -H "Content-Type: application/json"

echo "Filters updated at $(date)"
```

Добавить в crontab (каждый день в 3 AM):
```bash
0 3 * * * /home/admin/update-filters.sh >> /var/log/dns-updates.log 2>&1
```

---

## Проверка и тестирование

### Проверка разрешения:

```bash
# Тест Unbound напрямую
dig @127.0.0.1 -p 5335 google.com

# Тест через AdGuard
dig @127.0.0.1 -p 53 google.com

# Проверка DNSSEC
dig @127.0.0.1 -p 5335 dnssec-enabled.org +dnssec

# Проверка времени отклика
time dig @127.0.0.1 -p 5335 example.com

# Проверка разных типов записей
dig @127.0.0.1 -p 5335 example.com MX
dig @127.0.0.1 -p 5335 example.com TXT
dig @127.0.0.1 -p 5335 example.com NS
```

### Проверка фильтрации:

```bash
# Должна быть заблокирована
dig @127.0.0.1 -p 53 ads.example.com

# Должна разрешиться
dig @127.0.0.1 -p 53 google.com

# Проверка в логах AdGuard
tail -f /opt/adguardhome/work/logs/querylog.json | jq '.questions'
```

---

## Troubleshooting

### Проблема: Unbound не запускается

```bash
# Проверка синтаксиса конфигурации
unbound-checkconf -f /etc/unbound/unbound.conf

# Запуск с отладкой
sudo unbound -d -c /etc/unbound/unbound.conf

# Проверка логов
journalctl -u unbound -xe
```

### Проблема: DNS запросы медленные

```bash
# Проверить размеры кешей
unbound-control stats | grep "total.requestlist.length"

# Увеличить размеры в конфиге
msg-cache-size: 256m
rrset-cache-size: 512m

# Перезагрузить Unbound
sudo systemctl restart unbound
```

### Проблема: AdGuard не может соединиться с Unbound

```bash
# Проверить доступность Unbound
nc -zv 127.0.0.1 5335
nc -zv 172.16.81.10 53 (в Docker)

# Проверить firewall
sudo ufw status
sudo ufw allow 5335/tcp
sudo ufw allow 5335/udp

# Проверить docker сеть
docker network ls
docker network inspect dns_net
```

---

## Ресурсы и ссылки

- Unbound Documentation: https://unbound.docs.nlnetlabs.nl/
- AdGuard Home: https://github.com/AdguardTeam/AdGuardHome
- Filter Lists: https://filterlists.com/
- DNSSEC Tools: https://www.dnssec-debugger.com/