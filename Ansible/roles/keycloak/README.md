# keycloak

## Русский

Устанавливает Keycloak из апстримного tar-архива в `/opt` на Debian 13 LXC:
Java-окружение, системная учётная запись, `keycloak.conf` для внешнего
PostgreSQL и работы за Traefik, systemd-юнит и начальный администратор через
переменные окружения. Создание realm, MFA и OIDC-клиенты вне области роли.

Полная документация: [README_RUS.md](README_RUS.md)

## English

Installs Keycloak from the upstream tarball into `/opt` on a Debian 13 LXC:
Java runtime, system account, `keycloak.conf` for an external PostgreSQL and
operation behind Traefik, a systemd unit and a bootstrap administrator through
environment variables. Realm creation, MFA and OIDC clients are out of scope.

Full documentation: [README_ENG.md](README_ENG.md)
