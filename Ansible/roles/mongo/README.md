# mongo

## Русский

Устанавливает MongoDB 8.0 из вендорного репозитория `mongodb-org`
(в Debian 13 своего пакета нет из-за лицензирования), владеет
`/etc/mongod.conf` целиком и управляет пользователями через
`community.mongodb`: авторизация опциональна и обязательна при прослушивании
вне loopback, пароли приходят по имени переменной.

Полная документация: [README_RUS.md](README_RUS.md)

## English

Installs MongoDB 8.0 from the `mongodb-org` vendor repository (Debian 13
ships no package for licensing reasons), owns `/etc/mongod.conf` as a whole
and manages users through `community.mongodb`: authorization is optional and
mandatory when binding beyond loopback; passwords come by variable name.

Full documentation: [README_ENG.md](README_ENG.md)
