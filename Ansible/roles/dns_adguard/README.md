# adguard_home

[English](readme_eng.md) | [Русский](readme_rus.md)

EN: Installs AdGuard Home as the public `:53` resolver of the DNS-stack LXC:
filtering/blocklists, private PTR resolution and an upstream to the local Unbound
(`127.0.0.1:{{ dns.unbound_local_port }}`). Manages a fully declarative
`AdGuardHome.yaml` and switches the container's own resolver to itself.

RU: Устанавливает AdGuard Home как публичный резолвер `:53` в LXC DNS-стека:
фильтрация/блок-листы, приватный PTR-резолвинг и upstream на локальный Unbound
(`127.0.0.1:{{ dns.unbound_local_port }}`). Управляет полностью декларативным
`AdGuardHome.yaml` и переключает резолвер контейнера на самого себя.
