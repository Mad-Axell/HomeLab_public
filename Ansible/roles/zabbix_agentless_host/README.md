# zabbix_agentless_host

Registers a host object on the Zabbix server for devices that cannot run an
agent (appliances like Home Assistant OS). The interface is type `agent` with
no listener — it exists so server-side simple checks (ICMP ping, TCP service
probes) have an address to work with.

Регистрирует объект хоста на сервере Zabbix для устройств, не принимающих агент
(appliance вроде Home Assistant OS). Интерфейс типа `agent` без слушателя — он
существует, чтобы серверные простые проверки (ICMP ping, проверки TCP-сервисов)
имели адрес для работы.

- [English documentation](README_ENG.md)
- [Русская документация](README_RUS.md)
