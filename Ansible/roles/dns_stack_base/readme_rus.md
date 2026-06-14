# dns_stack_base (Русский)

Базовая подготовка ОС контейнера adguard. Выполняется **первой** в плее DNS-стека,
до `unbound` и `adguard_home`. См. документ проекта `05_dns_naming.md` §7–8.

## Зона ответственности

- `apt` update, опциональный `full-upgrade`, установка базовых пакетов
  (`dnsutils`, `bind9-host`, `curl`, `jq`, …).
- Отключение IPv6 через sysctl (когда `ipv6_enabled` = false).
- Установка таймзоны и проверка active/enabled для `systemd-timesyncd` — DNSSEC
  чувствителен к часам.
- Установка hostname и запись хоста в `/etc/hosts`.
- **Освобождение порта 53**: остановка, отключение и маскирование
  `systemd-resolved`.
- **Защита `/etc/resolv.conf`**: установка dhclient enter-hook, нейтрализующего
  `make_resolv_conf` (в unprivileged LXC `chattr +i` недоступен). Само
  переключение на `127.0.0.1` выполняется позже ролью `adguard_home`, чтобы на
  bootstrap apt мог достучаться до pfSense.

## Структура

```
dns_stack_base/
├── defaults/main.yml      # настраиваемое: пакеты, full-upgrade, состояние timesync, debug
├── vars/main.yml          # статика: имя сервиса timesync, фиксированные пути, поддерживаемые ОС
└── tasks/
    ├── main.yml           # точка входа: assert OS → install → configure → service → debug
    ├── install.yml        # apt update / full-upgrade / базовые пакеты
    ├── configure.yml      # IPv6, timezone, hostname/hosts, маскирование resolved, хук dhclient
    ├── service.yml        # состояние systemd-timesyncd + проверка systemctl (block/rescue)
    └── debug.yml          # двуязычная сводка под debug_mode
```

## Ключевые переменные

| Переменная | По умолчанию | Назначение |
|---|---|---|
| `dns_stack_base_packages` | список | базовые пакеты для установки |
| `dns_stack_base_full_upgrade` | `true` | запускать `apt full-upgrade` при первом прогоне |
| `dns_stack_base_timesync_state` | `started` | состояние systemd-timesyncd |
| `dns_stack_base_timesync_enabled` | `true` | автозапуск timesync |
| `debug_mode` / `debug_lang` / `debug_show_passwords` | `false` / `both` / `false` | управление отладкой |

Внешние переменные: `ipv6_enabled`, `dns_stack_timezone`, `pve_lxc_name`,
`adguard_ip`, `adguard_fqdn`.

## Теги

`install`, `configure`, `service`, `debug` (плюс `always` для assert ОС).
