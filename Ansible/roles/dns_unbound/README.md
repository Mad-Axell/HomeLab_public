# unbound

[English](readme_eng.md) | [Русский](readme_rus.md)

EN: Installs and configures Unbound as a validating, recursive, caching DNS
resolver bound to `127.0.0.1:{{ dns.unbound_local_port }}` inside the DNS-stack
LXC. Provides DNSSEC validation, QNAME minimisation, ratelimiting and stub-zones
to pfSense for local forward/reverse zones.

RU: Устанавливает и настраивает Unbound как валидирующий рекурсивный кэширующий
DNS-резолвер на `127.0.0.1:{{ dns.unbound_local_port }}` внутри LXC DNS-стека.
Обеспечивает DNSSEC-валидацию, QNAME-минимизацию, ratelimit и stub-зоны к pfSense
для локальных прямых/обратных зон.
