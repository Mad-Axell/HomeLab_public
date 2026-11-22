# clickhouse

## Русский

Устанавливает сервер ClickHouse из официального APT-репозитория вендора
(в Debian 13 своих пакетов нет) и управляет им через drop-in'ы
`config.d`/`users.d`: адреса прослушивания, порты, аккаунты с паролями по
имени переменной и проверку того, что каталог данных — отдельное хранилище.

Полная документация: [README_RUS.md](README_RUS.md)

## English

Installs the ClickHouse server from the official vendor APT repository
(Debian 13 carries no packages of its own) and manages it through
`config.d`/`users.d` drop-ins: listen addresses, ports, accounts whose
passwords come by variable name, and a check that the data directory is on
separate storage.

Full documentation: [README_ENG.md](README_ENG.md)
