# mosquitto

## Русский

Устанавливает MQTT-брокер Mosquitto из пакетов Debian и управляет им через
drop-in в `/etc/mosquitto/conf.d`: обычный listener 1883, опциональный
TLS-listener 8883, декларативные аккаунты (`password_file`, хэшируется
`mosquitto_passwd -U`) и `acl_file`. Соответствует плану защиты A-35: 1883
остаётся до миграции клиентов на TLS.

Полная документация: [README_RUS.md](README_RUS.md)

## English

Installs the Mosquitto MQTT broker from the Debian packages and manages it
through a `conf.d` drop-in: plaintext listener 1883, optional TLS listener
8883, declarative accounts (`password_file` hashed with `mosquitto_passwd -U`)
and an `acl_file`. Follows hardening plan A-35: 1883 stays until the clients
have migrated to TLS.

Full documentation: [README_ENG.md](README_ENG.md)
