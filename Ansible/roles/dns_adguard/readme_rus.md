# adguard_home (Русский)

Устанавливает и настраивает **AdGuard Home** как клиентский DNS-сервер стека.
Слушает `:53`, применяет блок-листы, резолвит имена клиентов через приватный PTR
и форвардит всё на локальный Unbound. Архитектура — в документе проекта
`05_dns_naming.md` §8.

## Зона ответственности

- Скачивание релиза AdGuard Home (`latest` или закреплённый `adguard_version`) и
  регистрация его как systemd-сервиса.
- Генерация полного декларативного `AdGuardHome.yaml` (роль владеет файлом
  целиком), с валидацией `AdGuardHome --check-config` до активации:
  - upstream `127.0.0.1:{{ dns.unbound_local_port }}` (Unbound);
  - приватный обратный DNS (`use_private_ptr_resolvers`, `local_ptr_upstreams`);
  - блок-листы из `adguard_filters`, DNSSEC, ratelimit;
  - DHCP отключён (DHCP — исключительно на pfSense).
- Управление systemd-юнитом `AdGuardHome` и проверка active/enabled.
- После запуска — ожидание `:53` и переключение `/etc/resolv.conf` на `127.0.0.1`.

Шаблон конфига содержит хэш пароля администратора, поэтому таска деплоя использует
`no_log: true`, а отладочная сводка скрывает хэш, если не задано
`debug_show_passwords: true`.

## Структура

```
adguard_home/
├── defaults/main.yml      # настраиваемое: каталоги, URL, фильтры, ratelimit, приватные сети, debug
├── vars/main.yml          # статика: имя сервиса, производные пути, поддерживаемые ОС
├── tasks/
│   ├── main.yml           # точка входа: assert OS → install → configure → service → debug
│   ├── install.yml        # каталоги, скачивание/распаковка, установка systemd
│   ├── configure.yml      # шаблон AdGuardHome.yaml (валидация, no_log)
│   ├── service.yml        # состояние systemd + проверка + переключение resolv.conf (block/rescue)
│   └── debug.yml          # двуязычная сводка под debug_mode (пароль скрыт)
├── handlers/main.yml      # adguard_restart
└── templates/AdGuardHome.yaml.j2
```

## Ключевые переменные

| Переменная | По умолчанию | Назначение |
|---|---|---|
| `adguard_service_state` | `started` | целевое состояние systemd |
| `adguard_service_enabled` | `true` | автозапуск |
| `adguard_install_dir` | `/opt/AdGuardHome` | каталог установки |
| `adguard_log_dir` | `/var/log/AdGuardHome` | каталог логов |
| `adguard_ratelimit` | `50` | ratelimit (qps) на клиента |
| `adguard_filters` | 5 списков | блок-листы (id/url/name) |
| `adguard_bootstrap_dns` | Quad9/Cloudflare | bootstrap для DoH/DoT upstream'ов |
| `adguard_private_networks` | RFC1918 | сети для PTR-резолвинга |
| `debug_mode` / `debug_lang` / `debug_show_passwords` | `false` / `both` / `false` | управление отладкой |

Внешние переменные: `adguard_version`, `adguard_web_port`, `adguard_admin_user`,
`adguard_admin_password_hash`, `adguard_schema_version`, `dns.unbound_local_port`,
`adguard_segment`, `network.base_domain`. Секреты — из `ansible/VARS/secrets.yaml`.

## Теги

`install`, `configure`, `service`, `debug` (плюс `always` для assert ОС).

## Проверка

```bash
dig @127.0.0.1 -p 53 +short google.com
dig @127.0.0.1 -p 53 +short doubleclick.net    # блок → '' или 0.0.0.0
```
