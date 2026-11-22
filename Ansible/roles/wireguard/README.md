# wireguard

## Русский

Роль настраивает входящий сервер удалённого доступа WireGuard в
Debian-контейнере: ставит `wireguard-tools`, включает форвардинг IPv4, пишет
`/etc/wireguard/wg0.conf` из шаблона с пирами из `wireguard_peers` и управляет
`wg-quick@wg0`. Маршрутизация без NAT; клиентские конфиги и QR-коды роль не
генерирует.

Полная документация: [README_RUS.md](README_RUS.md)

## English

The role configures an incoming WireGuard remote-access server inside a
Debian container: it installs `wireguard-tools`, enables IPv4 forwarding,
renders `/etc/wireguard/wg0.conf` from a template with the peers from
`wireguard_peers` and manages `wg-quick@wg0`. Routing only, no NAT; the role
does not generate client configs or QR codes.

Full documentation: [README_ENG.md](README_ENG.md)
