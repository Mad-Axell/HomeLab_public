# prometheus

## Русский

Устанавливает сервер Prometheus из пакетов Debian на хост мониторинга и целиком
управляет `/etc/prometheus/prometheus.yml`: задания опроса либо выводятся
дословно из `prometheus_scrape_configs`, либо генерируются из групп инвентаря
по `ansible_host` на порту `prometheus_node_exporter_port` (по умолчанию 9100).

Полная документация: [README_RUS.md](README_RUS.md)

## English

Installs the Prometheus server from the Debian packages on the monitoring host
and owns `/etc/prometheus/prometheus.yml` as a whole: scrape jobs either render
verbatim from `prometheus_scrape_configs` or are generated from inventory groups
by `ansible_host` on `prometheus_node_exporter_port` (9100 by default).

Full documentation: [README_ENG.md](README_ENG.md)
