# unbound (Русский)

Устанавливает и настраивает **Unbound** как рекурсивный, валидирующий DNSSEC
резолвер DNS-стека. Является upstream'ом для AdGuard Home и слушает только
loopback (`127.0.0.1:{{ dns.unbound_local_port }}`). Архитектура описана в
документе проекта `05_dns_naming.md` §7.

## Зона ответственности

- Установка `unbound` и `unbound-anchor` (Debian/apt).
- Инициализация корневого DNSSEC trust anchor (`root.key`) и root hints с
  ежемесячным обновлением hints через cron.
- Генерация `/etc/unbound/unbound.conf.d/10-server.conf` (проверяется
  `unbound-checkconf` до активации):
  - слушатель только на loopback, по умолчанию только IPv4;
  - DNSSEC-hardening, QNAME-минимизация, aggressive NSEC;
  - ratelimit'ы против DoS/amplification;
  - защита от утечки приватных адресов/доменов;
  - один родительский **stub-zone** для `*.{{ network.base_domain }}` на pfSense;
  - посегментные **обратные stub-зоны**, генерируемые строго как `/24` из
    `segments` (делегирование `/16` сломало бы рекурсию для соседних подсетей).
- Управление systemd-юнитом `unbound` и проверка active/enabled.

## Структура

```
unbound/
├── defaults/main.yml      # настраиваемое: производительность, ratelimit, URL/cron root-hints, debug
├── vars/main.yml          # статика: имя сервиса, пакеты, фиксированные пути, поддерживаемые ОС
├── tasks/
│   ├── main.yml           # точка входа: assert OS → install → configure → service → debug
│   ├── install.yml        # пакеты, trust anchor, root hints, cron
│   ├── configure.yml      # шаблон 10-server.conf (с валидацией)
│   ├── service.yml        # состояние systemd + проверка systemctl (block/rescue)
│   └── debug.yml          # двуязычная сводка под debug_mode
├── handlers/main.yml      # unbound_restart
└── templates/10-server.conf.j2
```

## Ключевые переменные

| Переменная | По умолчанию | Назначение |
|---|---|---|
| `unbound_service_state` | `started` | целевое состояние systemd |
| `unbound_service_enabled` | `true` | автозапуск |
| `unbound_num_threads` | `2` | рабочие потоки |
| `unbound_msg_cache_size` | `64m` | кэш сообщений |
| `unbound_rrset_cache_size` | `128m` | кэш RRset |
| `unbound_ratelimit` | `1000` | глобальный ratelimit (qps) |
| `unbound_ip_ratelimit` | `200` | ratelimit на IP |
| `unbound_root_hints_url` | internic named.cache | источник root hints |
| `unbound_root_hints_cron` | `17 4 1 * *` | расписание обновления hints |
| `debug_mode` / `debug_lang` / `debug_show_passwords` | `false` / `both` / `false` | управление отладкой |

Внешние переменные (из inventory/group_vars): `dns.unbound_local_port`,
`network.base_domain`, `pfsense_dns_ip`, `ipv6_enabled`, `segments`.

## Теги

`install`, `configure`, `service`, `debug` (плюс `always` для assert ОС).

## Проверка

```bash
unbound-checkconf
dig @127.0.0.1 -p {{ dns.unbound_local_port }} +short google.com
dig @127.0.0.1 -p {{ dns.unbound_local_port }} +short pve-router.mgmt.{{ network.base_domain }}
```
