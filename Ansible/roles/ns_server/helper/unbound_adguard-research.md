# Исследование применения и настройки Unbound DNS совместно с AdGuard Home

## Оглавление
1. [Введение](#введение)
2. [Архитектурные конфигурации](#архитектурные-конфигурации)
3. [Установка и базовая настройка](#установка-и-базовая-настройка)
4. [Интеграция Unbound с AdGuard Home](#интеграция-unbound-с-adguard-home)
5. [Оптимизация производительности](#оптимизация-производительности)
6. [Безопасность и функции](#безопасность-и-функции)
7. [Docker и контейнеризация](#docker-и-контейнеризация)
8. [Мониторинг и управление](#мониторинг-и-управление)
9. [Рекомендации для homelab](#рекомендации-для-homelab)

---

## Введение

**Unbound** — это современный валидирующий рекурсивный DNS-резолвер с кешированием, разработанный NLnet Labs. Он предназначен для быстрой и безопасной работы с открытыми стандартами.

**AdGuard Home** — это сетевое приложение для блокировки объявлений и трекеров на уровне DNS с поддержкой DNS-over-HTTPS (DoH) и DNS-over-TLS (DoT), обеспечивающее защиту всех устройств в сети.

### Преимущества использования комбинации:

- **Конфиденциальность**: Рекурсивное разрешение через Unbound без полагания на публичные DNS-серверы
- **Фильтрация**: AdGuard Home блокирует объявления и трекеры
- **DNSSEC**: Valидация подписей для защиты от спуфинга
- **Безопасность**: Оба инструмента имеют встроенные механизмы защиты от атак
- **Производительность**: Локальное кеширование ускоряет разрешение доменов
- **Гибкость**: Поддержка зашифрованных протоколов (DoH, DoT)

---

## Архитектурные конфигурации

### Конфигурация 1: AdGuard Home → Unbound (рекомендуется)

```
Клиент → AdGuard Home (53/udp, 53/tcp) → Unbound (127.0.0.1:5335 или 192.168.x.x:5335)
         ↓ Фильтрация                    ↓ Рекурсивное разрешение
       Блокировка                      Корневые серверы
```

**Преимущества:**
- Фильтрация трафика на уровне AdGuard
- Рекурсивное разрешение через Unbound
- Локальное кеширование в Unbound
- Лучшая приватность

**Поток:**
1. DNS-запросы поступают в AdGuard Home
2. AdGuard проверяет против фильтр-листов
3. Разрешенные запросы отправляются в Unbound
4. Unbound выполняет рекурсивное разрешение от корневых серверов

### Конфигурация 2: Независимые инстансы (Unbound как upstream)

```
Клиент → AdGuard Home (фильтрация) → Unbound (рекурсия) → Интернет
```

**Используется когда:**
- Требуется отдельный инстанс Unbound на другом хосте
- Необходимо масштабирование
- Реализация отказоустойчивости

### Конфигурация 3: Только AdGuard Home с публичными upstream

```
Клиент → AdGuard Home → Cloudflare/Google (рекурсия) → Интернет
```

**Минусы:**
- Меньше приватности (логирование на стороне провайдера)
- Зависимость от публичных DNS-провайдеров
- Эффект CNAME-маскирования сложнее блокировать

---

## Установка и базовая настройка

### Установка Unbound (Linux)

#### На Debian/Ubuntu:

```bash
sudo apt update
sudo apt install unbound unbound-anchor curl dnsutils -y
```

#### Загрузка корневых хинтов:

```bash
sudo curl -o /var/lib/unbound/root.hints https://www.internic.net/domain/named.root
sudo chown unbound:unbound /var/lib/unbound/root.hints
sudo chmod 644 /var/lib/unbound/root.hints
```

### Базовая конфигурация Unbound

Создайте файл `/etc/unbound/unbound.conf.d/local.conf`:

```unbound
server:
  # Сетевые интерфейсы
  interface: 127.0.0.1
  interface: ::1
  port: 5335
  
  # Поддержка протоколов
  do-ip4: yes
  do-ip6: no
  do-udp: yes
  do-tcp: yes
  
  # Производительность
  num-threads: 4  # Установите на количество ядер процессора
  
  # DNSSEC
  auto-trust-anchor-file: "/var/lib/unbound/root.key"
  harden-dnssec-stripped: yes
  harden-glue: yes
  
  # Безопасность
  hide-identity: yes
  hide-version: yes
  qname-minimisation: yes
  use-caps-for-id: yes
  
  # Кеширование
  cache-min-ttl: 300
  cache-max-ttl: 14400
  msg-cache-size: 128m
  rrset-cache-size: 256m
  serve-expired: yes
  serve-expired-ttl: 3600
  
  # Оптимизация
  prefetch: yes
  prefetch-key: yes
  edns-buffer-size: 1232
  so-rcvbuf: 1m
  
  # Приватные сети
  private-address: 192.168.0.0/16
  private-address: 169.254.0.0/16
  private-address: 172.16.0.0/12
  private-address: 10.0.0.0/8
  private-address: fd00::/8
  private-address: fe80::/10
```

### Запуск Unbound:

```bash
sudo systemctl enable unbound
sudo systemctl start unbound
sudo systemctl status unbound
```

### Тестирование Unbound:

```bash
# Локальный тест
dig @127.0.0.1 -p 5335 example.com

# Проверка DNSSEC
dig @127.0.0.1 -p 5335 example.com +dnssec

# Проверка DNSSEC валидации
dig @127.0.0.1 -p 5335 example.com +short
```

### Установка AdGuard Home

#### Скачивание и установка:

```bash
# Создание директории
mkdir -p /opt/adguardhome
cd /opt/adguardhome

# Скачивание последней версии (замените URL на актуальный)
wget https://github.com/AdguardTeam/AdGuardHome/releases/download/v0.107.52/AdGuardHome_linux_amd64.tar.gz

# Распаковка
tar xvzf AdGuardHome_linux_amd64.tar.gz

# Создание юзера
sudo useradd -r -s /bin/false adguardhome || true
sudo chown -R adguardhome:adguardhome /opt/adguardhome

# Создание systemd сервиса
sudo cat > /etc/systemd/system/adguardhome.service << 'EOF'
[Unit]
Description=AdGuard Home
After=network.target

[Service]
Type=simple
User=adguardhome
Group=adguardhome
WorkingDirectory=/opt/adguardhome
ExecStart=/opt/adguardhome/AdGuardHome -w /opt/adguardhome
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable adguardhome
sudo systemctl start adguardhome
```

---

## Интеграция Unbound с AdGuard Home

### Метод 1: Локальное разрешение (Рекомендуется)

#### Конфигурация Unbound на localhost:

Используйте конфиг выше с `interface: 127.0.0.1` и `port: 5335`

#### Конфигурация AdGuard Home:

1. Откройте веб-интерфейс `http://localhost:3000`
2. Перейдите в **Settings** → **DNS settings**
3. В разделе **Upstream DNS servers** добавьте:
   ```
   127.0.0.1:5335
   ```
4. **Apply** и **Save**

#### Отключение кеширования в AdGuard:

В AdGuard Settings → DNS settings:
- Отключите "Cache DNS responses" (кеширование выполнит Unbound)

### Метод 2: Удаленное разрешение

Если Unbound на другом хосте (192.168.1.100):

```
172.16.81.10:533  # IP и порт контейнера Unbound
```

или

```
192.168.1.100:5335  # IP локальной машины
```

### Тестирование интеграции:

```bash
# Проверка разрешения через AdGuard
dig @127.0.0.1 -p 53 example.com

# Проверка в логах AdGuard
# Settings → Logs → Check DNS Queries

# Проверка статистики
# Dashboard → посмотрите "Blocked requests"
```

---

## Оптимизация производительности

### Кеширование

**Рекомендации:**

1. **В Unbound:**
   - `msg-cache-size: 128m` для большинства сетей
   - `rrset-cache-size: 256m` для кеша записей
   - `cache-min-ttl: 300` минимальный TTL в кеше
   - `cache-max-ttl: 14400` максимальный TTL (4 часа)

2. **В AdGuard Home:**
   - Отключите встроенное кеширование, если используете Unbound
   - Включите логирование для анализа паттернов

### Оптимизация потоков и сокетов

```unbound
server:
  num-threads: 4          # Подстройте на количество ядер
  so-rcvbuf: 1m           # Буфер приема сокета
  so-sndbuf: 1m           # Буфер передачи сокета
  outgoing-port-permit: 10000-65535
  msg-cache-slabs: 8      # Должна быть степень 2
  rrset-cache-slabs: 8
  infra-cache-slabs: 8
  key-cache-slabs: 8
```

### Предварительная загрузка (Prefetch)

```unbound
server:
  prefetch: yes           # Перезагрузка кеша перед истечением TTL
  prefetch-key: yes       # Предварительная загрузка DNSSEC ключей
```

### Обслуживание истекших записей

```unbound
server:
  serve-expired: yes      # Отправлять истекшие записи пока обновляется
  serve-expired-ttl: 3600 # На какое время延长 истекшая запись
```

### Размер буфера EDNS

```unbound
server:
  edns-buffer-size: 1232  # Оптимальный размер для большинства сетей
```

---

## Безопасность и функции

### DNSSEC в Unbound

```unbound
server:
  auto-trust-anchor-file: "/var/lib/unbound/root.key"
  harden-dnssec-stripped: yes        # Отклоняй без подписи для подписанных зон
  harden-glue: yes                    # Проверяй глю-записи
  harden-referral-path: yes           # Проверяй путь делегирования
  harden-algo-downgrade: no           # Не переходи на слабые алгоритмы
  unwanted-reply-threshold: 10000000  # Защита от спама
```

### Минимизация QNAME

```unbound
server:
  qname-minimisation: yes             # Отправляй минимум информации upstream
```

### Защита идентификации

```unbound
server:
  hide-identity: yes      # Скрывай version.bind и id.server запросы
  hide-version: yes       # Скрывай номер версии
  use-caps-for-id: yes    # Используй CAPS для ID рандомизации
```

### Ограничение частоты запросов (Rate Limiting)

```unbound
server:
  rate-limit: 0           # 0 = отключено, рекомендуется 50-100 для защиты
  rate-limit-slabs: 4
  ratelimit-for-log: yes
```

### Фильтрация в AdGuard Home

#### Встроенные защиты:
- **Safe Browsing** — блокировка фишинга и малвера
- **Parental Control** — блокировка взрослого контента
- **Safe Search** — принудительный безопасный поиск

#### Список фильтров AdGuard Home:

1. Добавьте популярные фильтр-листы:
   - AdGuard DNS filter
   - EasyList
   - Fanboy's Annoyance List
   - uBlock Origin filters

2. Через Settings → Filters → DNS blocklists → Add blocklist

#### Собственные правила:

```
! Блокировать домен
||example.com^

! Разрешить поддомен
@@||safe.example.com^

! Использовать regex
/.*ads\..*$/

! Правило с условиями
||ads.example.com^$dnstype=A
```

---

## Docker и контейнеризация

### Docker Compose для Unbound + AdGuard Home

```yaml
version: '3.8'

services:
  unbound:
    image: klutchell/unbound:latest
    container_name: unbound
    networks:
      dns_net:
        ipv4_address: 172.16.81.10
    ports:
      - "533:53/udp"
      - "533:53/tcp"
    volumes:
      - ./unbound/config:/etc/unbound/custom.conf.d:ro
      - unbound_cache:/var/cache/unbound
    restart: unless-stopped
    deploy:
      resources:
        limits:
          memory: 1G
    depends_on:
      - unbound_redis

  unbound_redis:
    image: redis:latest
    container_name: unbound_redis
    networks:
      - dns_net
    hostname: redis
    volumes:
      - redis_data:/data
    restart: unless-stopped

  adguardhome:
    image: adguard/adguardhome:latest
    container_name: adguardhome
    networks:
      dns_net:
        ipv4_address: 172.16.81.11
    ports:
      - "53:53/udp"
      - "53:53/tcp"
      - "3000:3000/tcp"     # Web UI
      - "853:853/tcp"       # DoT
      - "853:853/udp"       # DoT
      - "8443:443/tcp"      # DoH
    volumes:
      - ./adguard/work:/opt/adguardhome/work
      - ./adguard/conf:/opt/adguardhome/conf
    restart: unless-stopped
    depends_on:
      - unbound

networks:
  dns_net:
    driver: bridge
    ipam:
      config:
        - subnet: 172.16.81.0/24

volumes:
  unbound_cache:
  redis_data:
```

### Запуск контейнеров:

```bash
docker-compose up -d

# Проверка состояния
docker-compose ps

# Логи
docker-compose logs -f unbound
docker-compose logs -f adguardhome
```

### Конфигурация Unbound в Docker

Создайте `./unbound/config/cachedb.conf`:

```unbound
server:
  # Основные настройки
  interface: 0.0.0.0
  port: 53
  do-ip4: yes
  do-ip6: no
  do-udp: yes
  do-tcp: yes
  
  # Производительность
  num-threads: 4
  msg-cache-size: 128m
  rrset-cache-size: 256m
  
  # Redis кеш (для сохранения кеша между перезагрузками)
  cachedb:
    backend: redis
    redis-server-host: redis
    redis-server-port: 6379
    redis-timeout: 100
    redis-expire-records: yes
    
remote-control:
  control-enable: yes
  control-interface: 127.0.0.1
```

---

## Мониторинг и управление

### Утилита unbound-control

```bash
# Статистика
sudo unbound-control stats

# Активные запросы
sudo unbound-control stats_noreset

# Управление кешем
sudo unbound-control dump_cache

# Перезагрузка конфига без перезагрузки
sudo unbound-control reload

# Очистка кеша
sudo unbound-control flush_zone example.com
```

### Логирование Unbound

Для увеличения verbosity:

```unbound
server:
  verbosity: 1  # 0-5, где 5 = максимум деталей
```

Смотрите логи:
```bash
journalctl -u unbound -f
```

### Мониторинг AdGuard Home

AdGuard предоставляет встроенный Dashboard:

1. Откройте `http://localhost:3000`
2. **Dashboard** → просмотрите статистику:
   - Total queries
   - Blocked requests
   - Replaced SAFEBROWSING
   - Blocked by filtering
   - Top blocked domains
   - Top clients

### Проверка разрешения доменов

```bash
# Через Unbound (напрямую)
dig @127.0.0.1 -p 5335 example.com

# Через AdGuard Home
dig @127.0.0.1 -p 53 example.com

# С DNSSEC проверкой
dig @127.0.0.1 -p 5335 example.com +dnssec +short

# Проверка статуса DNSSEC
dig @127.0.0.1 -p 5335 DNSKEY example.com +short
```

---

## Рекомендации для homelab

### Рекомендуемая архитектура

```
┌─────────────────────────────────────────┐
│         Router / Firewall               │
│    (OPNsense / Proxmox / etc)           │
└──────────────────┬──────────────────────┘
                   │
        ┌──────────┴──────────┐
        │                     │
    ┌───▼────┐            ┌──▼────┐
    │Unbound │            │AdGuard│  <- Все устройства точка в DNS
    │(5335)  │────────────│ (53)  │     к IP маршрутизатора
    └────────┘            └───┬───┘
                              │
                    ┌─────────┴─────────┐
                    │                   │
                  ┌─▼──┐            ┌──▼──┐
                  │Dev1│            │Dev2 │
                  └────┘            └─────┘
```

### Параметры для homelab (< 100 устройств)

**Unbound:**
```unbound
server:
  num-threads: 2-4              # В зависимости от хоста
  msg-cache-size: 128m          # 128-256 MB
  rrset-cache-size: 256m        # 256-512 MB
  cache-min-ttl: 300
  cache-max-ttl: 14400
  serve-expired: yes
```

**AdGuard Home:**
- Включите фильтрацию объявлений
- 2-5 основных фильтр-листов (не более 10)
- Включите Safe Browsing и Parental Control

### Настройка DHCP

В маршрутизаторе/DHCP сервере установите DNS на IP хоста с AdGuard Home:
- Primary DNS: `192.168.1.100` (IP AdGuard Home)
- Secondary DNS: `8.8.8.8` (fallback)

Или через systemd-resolved на Linux хосте:

```bash
sudo mkdir -p /etc/systemd/resolved.conf.d/
sudo nano /etc/systemd/resolved.conf.d/adguardhome.conf
```

Добавьте:
```ini
[Resolve]
DNS=127.0.0.1
DNSStubListener=no
FallbackDNS=1.1.1.1
```

Перезагрузите:
```bash
sudo systemctl restart systemd-resolved
```

### Безопасность в homelab

1. **Ограничьте доступ:**
   ```unbound
   access-control: 127.0.0.0/8 allow
   access-control: 192.168.0.0/16 allow
   access-control: 0.0.0.0/0 deny
   ```

2. **Защитите AdGuard Home:**
   - Установите сильный пароль
   - Измените порт web-интерфейса (не 3000)
   - Используйте HTTPS (Settings → Encryption)

3. **Мониторинг:**
   - Включите логирование всех запросов
   - Регулярно проверяйте статистику
   - Используйте alerting (например, через Home Assistant)

### Отказоустойчивость

Конфигурация с резервным DNS:

```unbound
forward-zone:
  name: "."
  forward-addr: 1.1.1.1@853  # Cloudflare DoT
  forward-addr: 8.8.8.8       # Google DNS (fallback)
```

В AdGuard Home можно добавить несколько upstream серверов:

```
127.0.0.1:5335
1.1.1.1
```

---

## Заключение

Комбинация Unbound + AdGuard Home предоставляет мощный, гибкий и приватный DNS-сервис для homelab-а:

- **Unbound** обеспечивает рекурсивное разрешение, кеширование и DNSSEC валидацию
- **AdGuard Home** добавляет фильтрацию, блокировку объявлений и встроенный веб-интерфейс
- **Локальное разрешение** повышает приватность и производительность
- **Контейнеризация** упрощает развертывание и управление

Рекомендуемая конфигурация для homelab:
- Unbound на порту 5335 (локально)
- AdGuard Home на порту 53 (для всех устройств)
- Отключение кеширования в AdGuard (Unbound кеширует)
- 2-5 фильтр-листов в AdGuard
- DNSSEC включен в обоих сервисах

Это обеспечит быстрое, безопасное и приватное разрешение доменов для всей сети.