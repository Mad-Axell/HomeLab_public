# vpn_adguard

## Русский

Роль устанавливает официальный клиент AdGuard VPN CLI в Debian-контейнер,
настраивает его для работы без оператора в режиме TUN и готовит контейнер к роли
исходящего шлюза: включает форвардинг IPv4, создаёт таблицу маскарадинга nftables
для заданных подсетей и systemd-юнит, поднимающий туннель при загрузке. Вход в
аккаунт AdGuard роль не выполняет: он делается один раз вручную.

Полная документация: [README_RUS.md](README_RUS.md)

## English

The role installs the official AdGuard VPN CLI client into a Debian container,
configures it for unattended operation in TUN mode and prepares the container to
act as an egress gateway: it enables IPv4 forwarding, creates an nftables
masquerade table for the given subnets and a systemd unit that raises the tunnel
at boot. The role does not log in to an AdGuard account: that is a one-time
manual step.

Full documentation: [README_ENG.md](README_ENG.md)
