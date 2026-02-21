# Углубленное руководство: Безопасность и оптимизация Unbound + AdGuard Home

## Содержание

1. [Механизмы безопасности Unbound](#механизмы-безопасности-unbound)
2. [Защита от атак DNS](#защита-от-атак-dns)
3. [Оптимизация для homelab](#оптимизация-для-homelab)
4. [Мониторинг и аналитика](#мониторинг-и-аналитика)
5. [Интеграция с другими сервисами](#интеграция-с-другими-сервисами)

---

## Механизмы безопасности Unbound

### 1. DNSSEC Validation

DNSSEC защищает от подделки DNS-ответов через криптографические подписи.

**Конфигурация:**

```unbound
server:
  # Автоматическое управление корневым ключом доверия
  auto-trust-anchor-file: "/var/lib/unbound/root.key"
  
  # Отклоняй ответы без подписей для подписанных зон
  harden-dnssec-stripped: yes
  
  # Проверяй DNSSEC даже для локальных ответов
  harden-referral-path: yes
  
  # Используй CAPS для DNSSEC
  use-caps-for-id: yes
  
  # Не понижай алгоритм (отключено для совместимости)
  harden-algo-downgrade: no
```

**Проверка DNSSEC:**

```bash
# Проверить статус DNSSEC для домена
dig @127.0.0.1 -p 5335 example.com +dnssec +short

# Полный ответ с DNSSEC данными
dig @127.0.0.1 -p 5335 example.com +dnssec

# Проверить наличие подписей
dig @127.0.0.1 -p 5335 example.com RRSIG

# Проверить DNSSEC chain
dig @127.0.0.1 -p 5335 example.com DS
```

### 2. Хардение и защита идентификации

```unbound
server:
  # Скрывать информацию о сервере
  hide-identity: yes       # Отклоняй "id.server" запросы
  hide-version: yes        # Отклоняй "version.server" запросы
  hide-trustanchor: yes    # Отклоняй "trustanchor.unbound" запросы
  
  # Идентификация вместо стандартных значений
  identity: "MyDNS"        # Вместо hostname
  version: "1.0"           # Вместо версии Unbound
  
  # Аппаратные параметры безопасности
  harden-glue: yes         # Проверяй глю-записи
  harden-dnssec-stripped: yes
  harden-referral-path: yes
  harden-below-nxdomain: yes  # Защита от fake nxdomain
  harden-short-bufsize: yes   # Отклоняй маленькие буферы
```

### 3. Rate Limiting (ограничение частоты запросов)

Защита от DDoS и DNS amplification атак:

```unbound
server:
  # Основное ограничение частоты (запросы/сек)
  rate-limit: 100              # 100 запросов в секунду (0 = отключено)
  rate-limit-slabs: 4          # Шарды для масштабирования
  ratelimit-for-log: yes       # Логировать ограниченные
  
  # Размер очереди для ограничения
  rate-limit-size: 4m
  
  # Дополнительная защита
  unwanted-reply-threshold: 10000000  # Защита от спама
```

**Рекомендуемые значения:**

- Домашняя сеть (< 20 устройств): 100 запросов/сек
- Средняя сеть (20-100 устройств): 50 запросов/сек
- Большая сеть (> 100 устройств): 20-30 запросов/сек

### 4. Минимизация QNAME

Отправлять минимум информации upstream серверам:

```unbound
server:
  # Отправлять только необходимые части доменного имени
  qname-minimisation: yes
  qname-minimisation-strict: no  # Допускать NOERROR без полного QNAME
```

**Как это работает:**

```
Стандартный запрос: example.com A → отправляет "example.com"
С минимизацией: example.com A → отправляет "." или "com" upstream
```

### 5. Доступ по IP адресам (Access Control)

```unbound
server:
  # По умолчанию запрещено всем
  access-control: 0.0.0.0/0 deny
  
  # Разрешить для localhost
  access-control: 127.0.0.0/8 allow
  access-control: ::1/128 allow
  
  # Разрешить для локальной сети
  access-control: 192.168.0.0/16 allow
  access-control: 10.0.0.0/8 allow
  access-control: 172.16.0.0/12 allow
  
  # Разрешить для IPv6
  access-control: fc00::/7 allow
  access-control: fe80::/10 allow
  
  # Другие действия:
  # allow       - разрешить обычные запросы
  # allow_snoop - разрешить AXFR и другие
  # deny        - отклонить
  # refuse      - отправить REFUSED
  # refuse_non_local  - отклонить non-local
  # transparent - проверить для локальных
```

### 6. Предотвращение DNS Rebinding атак

```unbound
server:
  # Отклоняй ответы, указывающие на приватные адреса
  private-address: 192.168.0.0/16
  private-address: 169.254.0.0/16
  private-address: 172.16.0.0/12
  private-address: 10.0.0.0/8
  private-address: fd00::/8
  private-address: fe80::/10
  private-address: 127.0.0.0/8     # Loopback
  
  # Включить проверку rebinding
  private-domain: "local"
  private-domain: "home"
  private-domain: "internal"
```

---

## Защита от атак DNS

### 1. DNS Amplification Attack

Атака, где запросы используются для усиления трафика к целевому IP.

**Защита:**

```unbound
server:
  # Уменьшить ответ для рекурсивных запросов
  do-not-query-address: 0.0.0.0/0
  
  # Не отвечать на запросы от non-clients
  access-control: 0.0.0.0/0 deny
  
  # Размер буфера (не слишком большой)
  edns-buffer-size: 1232
```

### 2. DNS Cache Poisoning

Атака внедрения поддельных ответов в кеш.

**Защита:**

```unbound
server:
  # DNSSEC валидация (основная защита)
  auto-trust-anchor-file: "/var/lib/unbound/root.key"
  harden-dnssec-stripped: yes
  
  # Рандомизация портов
  outgoing-range: 50000           # Диапазон портов для outgoing
  outgoing-port-permit: 10000-65535
  
  # Использование CAPS
  use-caps-for-id: yes
  
  # Случайные ID
  caps-randomized-drop-response: yes
  caps-whitelist: yes
```

### 3. DNS Flood / DDoS

Множество быстрых запросов от одного источника.

**Защита:**

```unbound
server:
  # Rate limiting
  rate-limit: 100
  rate-limit-size: 4m
  
  # Увеличить размер буферов
  so-rcvbuf: 2m
  so-sndbuf: 2m
  
  # Оптимизировать для пиков
  outgoing-port-permit: 10000-65535
  outgoing-range: 50000
```

### 4. NULL DNS (NXDOMAIN Flood)

Запросы на несуществующие домены.

**Защита:**

```unbound
server:
  # Ограничивать ответы NXDOMAIN
  harden-below-nxdomain: yes
  
  # Кешировать отрицательные ответы
  cache-min-ttl: 300
  
  # Защита от раскрытия информации
  harden-referral-path: yes
```

---

## Оптимизация для homelab

### 1. Оптимизация памяти

Для систем с ограниченной памятью (Raspberry Pi):

```unbound
server:
  # Уменьшить размеры кешей
  msg-cache-size: 32m        # 32 MB вместо 128 MB
  rrset-cache-size: 64m      # 64 MB вместо 256 MB
  
  # Уменьшить количество потоков
  num-threads: 1             # Одиночный поток
  
  # Минимальное количество слоев
  msg-cache-slabs: 1
  rrset-cache-slabs: 1
  infra-cache-slabs: 1
  key-cache-slabs: 1
```

### 2. Оптимизация для быстрого отклика

```unbound
server:
  # Большие кеши
  msg-cache-size: 256m
  rrset-cache-size: 512m
  
  # Много потоков
  num-threads: 8
  
  # Агрессивный prefetch
  prefetch: yes
  prefetch-key: yes
  
  # Обслуживание истекших записей
  serve-expired: yes
  serve-expired-ttl: 7200    # Подавай на 2 часа дольше
  
  # Быстрый TTL
  cache-min-ttl: 300
  cache-max-ttl: 21600       # 6 часов
```

### 3. Оптимизация для множества устройств (50+)

```unbound
server:
  # Масштабируемость
  num-threads: 4-8            # По ядрам
  
  # Большие размеры
  msg-cache-size: 256m
  rrset-cache-size: 512m
  infra-cache-size: 100m
  
  # Много слоев (степень 2)
  msg-cache-slabs: 16
  rrset-cache-slabs: 16
  infra-cache-slabs: 8
  key-cache-slabs: 8
  
  # Буферы
  so-rcvbuf: 2m
  so-sndbuf: 2m
  
  # Внешние порты
  outgoing-range: 65000
  outgoing-port-permit: 1000-65535
```

### 4. Конфигурация для локальных доменов

Разрешение внутренних доменов (.home, .local):

```unbound
server:
  # Локальные зоны
  local-zone: "home." static
  local-zone: "local." static
  local-zone: "internal." static
  
  # Локальные записи
  local-data: "myserver.home. 3600 IN A 192.168.1.100"
  local-data: "plex.home. 3600 IN A 192.168.1.101"
  local-data: "nas.home. 3600 IN A 192.168.1.102"
  
  # Reverse DNS
  local-data-ptr: "192.168.1.100 3600 myserver.home."
  local-data-ptr: "192.168.1.101 3600 plex.home."
```

### 5. Интеграция с DHCP (динамические хосты)

Если у вас есть DHCP, регистрирующий хосты:

```unbound
server:
  # Автоматическая регистрация DHCP (OPNsense, pfSense)
  # На маршрутизаторе включить "Register DHCP leases in DNS"
  
  # Или вручную добавлять при добавлении устройства
  local-data: "iphone.home. 3600 IN A 192.168.1.50"
  local-data: "laptop.home. 3600 IN A 192.168.1.51"
```

---

## Мониторинг и аналитика

### 1. Сбор статистики Unbound

```bash
# Получить все статистики
sudo unbound-control stats

# Вывод статистики в интервалы
sudo unbound-control stats_noreset | grep -E "total|num"

# Непрерывный мониторинг
watch -n 1 'sudo unbound-control stats | head -20'
```

**Важные метрики:**

```
total.num.queries - общее количество запросов
total.num.cachehits - попадания в кеш
total.num.cachemiss - промахи кеша
total.num.prefetch - переиспользованные
total.recursion.time.avg - среднее время рекурсии
```

### 2. Анализ логов в AdGuard Home

**Варианты 1: Встроенный Dashboard**

```
Settings → General → Admin interface
→ Dashboard → Query log, Statistics
```

**Вариант 2: API запросы**

```bash
# Получить последние логи (JSON)
curl "http://localhost:3000/control/querylog?limit=100" | jq

# Статистика по доменам
curl "http://localhost:3000/control/stats/top_domains?length=10" | jq

# Статистика по клиентам
curl "http://localhost:3000/control/stats/top_clients?length=10" | jq

# Общая статистика
curl "http://localhost:3000/control/status" | jq '.stats'
```

### 3. Prometheus метрики для Unbound

Для интеграции с Prometheus/Grafana:

```bash
# Установить exporter
git clone https://github.com/prometheus-community/unbound_exporter.git
cd unbound_exporter
go build

# Запустить exporter
./unbound_exporter -unbound.address="127.0.0.1:8953"
```

Конфигурация Prometheus:

```yaml
scrape_configs:
  - job_name: 'unbound'
    static_configs:
      - targets: ['localhost:9167']
```

### 4. Кастомные скрипты мониторинга

**Скрипт проверки здоровья:**

```bash
#!/bin/bash
# health-check.sh

UNBOUND_PORT=5335
ADGUARD_PORT=3000

# Проверка Unbound
echo "Checking Unbound..."
dig @127.0.0.1 -p $UNBOUND_PORT example.com +short > /dev/null
if [ $? -eq 0 ]; then
  echo "✓ Unbound OK"
else
  echo "✗ Unbound FAILED"
  systemctl restart unbound
fi

# Проверка AdGuard
echo "Checking AdGuard Home..."
curl -s http://localhost:$ADGUARD_PORT/control/status > /dev/null
if [ $? -eq 0 ]; then
  echo "✓ AdGuard OK"
else
  echo "✗ AdGuard FAILED"
  systemctl restart adguardhome
fi

# Проверка кеша
CACHEHITS=$(unbound-control stats | grep "total.num.cachehits" | awk '{print $2}')
QUERIES=$(unbound-control stats | grep "total.num.queries" | awk '{print $2}')
HITRATE=$((CACHEHITS * 100 / QUERIES))
echo "Cache hit rate: $HITRATE%"
```

---

## Интеграция с другими сервисами

### 1. Интеграция с OPNsense/pfSense

**OPNsense как маршрутизатор с Unbound:**

1. **Services → Unbound DNS:**
   - Enable Unbound ✓
   - Enable DNSSEC ✓
   - Listen interfaces: LAN
   - Advanced: Хардирование параметры

2. **Services → DHCPv4:**
   - DNS Servers: `192.168.1.1` (Unbound на OPNsense)

3. **Запустить AdGuard Home в Docker контейнере**
4. **Перенаправить через Unbound:**
   ```
   OPNsense (Unbound) → AdGuard Home → Unbound → Internet
   ```

### 2. Интеграция с Home Assistant

**Компонент AdGuard Home:**

```yaml
# configuration.yaml
adguard:
  host: 192.168.1.100
  port: 3000
```

**Автоматизация:**

```yaml
automation:
  - alias: "Strict filtering during school hours"
    trigger:
      platform: time
      at: "08:00:00"
    action:
      service: switch.turn_on
      target:
        entity_id: switch.adguard_safe_browsing
  
  - alias: "Relaxed filtering in evening"
    trigger:
      platform: time
      at: "18:00:00"
    action:
      service: switch.turn_off
      target:
        entity_id: switch.adguard_safe_browsing
```

### 3. Интеграция с Prometheus/Grafana

**docker-compose для мониторинга:**

```yaml
prometheus:
  image: prom/prometheus:latest
  ports:
    - "9090:9090"
  volumes:
    - ./prometheus.yml:/etc/prometheus/prometheus.yml

grafana:
  image: grafana/grafana:latest
  ports:
    - "3001:3000"
  environment:
    - GF_SECURITY_ADMIN_PASSWORD=admin
```

**Dashboards для Grafana:**

- Unbound DNS Dashboard: https://grafana.com/grafana/dashboards/...
- AdGuard Home Dashboard: https://github.com/...

### 4. Резервная копия конфигурации

**Автоматическое резервное копирование:**

```bash
#!/bin/bash
# backup-dns.sh

BACKUP_DIR="/mnt/backup/dns"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR

# Unbound
cp -r /etc/unbound $BACKUP_DIR/unbound_$DATE
cp -r /var/lib/unbound $BACKUP_DIR/unbound_data_$DATE

# AdGuard Home
docker exec adguardhome tar czf - /opt/adguardhome/conf \
  > $BACKUP_DIR/adguard_conf_$DATE.tar.gz
docker exec adguardhome tar czf - /opt/adguardhome/work \
  > $BACKUP_DIR/adguard_work_$DATE.tar.gz

# Держать только последние 10 копий
find $BACKUP_DIR -type f -mtime +30 -delete
```

Добавить в crontab (ежедневно в 2 AM):
```bash
0 2 * * * /usr/local/bin/backup-dns.sh
```

---

## Рекомендуемые конфигурации для разных типов homelab

### Минимальный (Raspberry Pi Zero)

```unbound
server:
  interface: 127.0.0.1
  port: 5335
  num-threads: 1
  msg-cache-size: 32m
  rrset-cache-size: 64m
  cache-min-ttl: 300
  cache-max-ttl: 3600
  hide-identity: yes
  hide-version: yes
  auto-trust-anchor-file: "/var/lib/unbound/root.key"
```

### Малый (Raspberry Pi 4, 2-4 ядра)

```unbound
server:
  interface: 127.0.0.1
  port: 5335
  num-threads: 2
  msg-cache-size: 64m
  rrset-cache-size: 128m
  prefetch: yes
  serve-expired: yes
  serve-expired-ttl: 3600
  auto-trust-anchor-file: "/var/lib/unbound/root.key"
```

### Средний (x86, 4-8 ядер)

```unbound
server:
  interface: 0.0.0.0
  port: 5335
  num-threads: 4
  msg-cache-size: 128m
  rrset-cache-size: 256m
  prefetch: yes
  prefetch-key: yes
  serve-expired: yes
  serve-expired-ttl: 7200
  rate-limit: 100
  auto-trust-anchor-file: "/var/lib/unbound/root.key"
```

### Большой (мощный сервер, 8+ ядер)

```unbound
server:
  interface: 0.0.0.0
  port: 5335
  num-threads: 8
  msg-cache-size: 256m
  rrset-cache-size: 512m
  msg-cache-slabs: 16
  rrset-cache-slabs: 16
  infra-cache-slabs: 8
  key-cache-slabs: 8
  so-rcvbuf: 2m
  so-sndbuf: 2m
  prefetch: yes
  prefetch-key: yes
  serve-expired: yes
  serve-expired-ttl: 7200
  rate-limit: 50
  auto-trust-anchor-file: "/var/lib/unbound/root.key"
  harden-dnssec-stripped: yes
  qname-minimisation: yes
```

---

## Заключение

Комбинация Unbound + AdGuard Home с правильной конфигурацией безопасности и оптимизацией обеспечивает:

- **Безопасность**: DNSSEC валидация, защита от атак
- **Приватность**: Рекурсивное разрешение без логирования ISP
- **Производительность**: Локальное кеширование с минимальной задержкой
- **Управляемость**: Встроенные интерфейсы и API
- **Масштабируемость**: От Pi Zero до мощных серверов