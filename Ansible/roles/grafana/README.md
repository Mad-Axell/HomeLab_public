# grafana

## Русский

Устанавливает Grafana из официального APT-репозитория `apt.grafana.com` на
Debian-хост, пишет `grafana.ini` из шаблона с подключением к внешнему
PostgreSQL (базу и роль создаёт сама при `grafana_database_manage: true`) и
декларативно провизионирует источники данных и дашборды, а также ставит
плагины через `grafana-cli`.

Полная документация: [README_RUS.md](README_RUS.md)

## English

Installs Grafana on a Debian host from the official `apt.grafana.com` APT
repository, renders `grafana.ini` from a template with an external
PostgreSQL connection (creating the database and role itself when
`grafana_database_manage` is true), provisions datasources and dashboards
declaratively, and installs plugins via `grafana-cli`.

Full documentation: [README_ENG.md](README_ENG.md)
