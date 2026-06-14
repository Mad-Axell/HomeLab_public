# dns_stack_base

[English](readme_eng.md) | [Русский](readme_rus.md)

EN: Prepares the adguard container OS before Unbound and AdGuard Home are installed:
base packages, IPv6 off, time sync, hostname/`/etc/hosts`, freeing port 53
(disabling `systemd-resolved`) and protecting `/etc/resolv.conf` from dhclient.

RU: Готовит ОС контейнера adguard перед установкой Unbound и AdGuard Home: базовые
пакеты, отключение IPv6, синхронизация времени, hostname/`/etc/hosts`,
освобождение порта 53 (отключение `systemd-resolved`) и защита `/etc/resolv.conf`
от dhclient.
