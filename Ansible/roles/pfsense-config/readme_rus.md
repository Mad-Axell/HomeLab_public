# pfsense-config (Русский)

Декларативно приводит роутер/файрвол **pfSense** к желаемому состоянию,
пересобирая его из переменных — **без восстановления бэкапа config.xml**.

## Движок — гибрид

| Область | Механизм |
|---|---|
| Система (hostname, домен, DNS, время, язык) | `pfsensible.core.pfsense_setup` |
| Интерфейсы (адресация, MAC, MTU, block priv/bogons) | `pfsensible.core.pfsense_interface` |
| Статические шлюзы | `pfsensible.core.pfsense_gateway` |
| Алиасы | `pfsensible.core.pfsense_alias` |
| Правила файрвола (вкл. floating / policy-routing / порты) | `pfsensible.core.pfsense_rule` |
| VLAN на родительском NIC | `pfsensible.core.pfsense_vlan` |
| DHCP **static mappings** (единый список хостов) | `pfsensible.core.pfsense_dhcp_static` |
| **Host overrides** DNS Resolver (единый список хостов) | `pfsensible.core.pfsense_dns_resolver` |
| **Force-DNS** NAT-redirect → AdGuard | `pfsensible.core.pfsense_nat_port_forward` |
| Динамический шлюз, группы шлюзов, шлюз по умолчанию | PHP playback `pfsense_gateways.php` |
| DHCP-сервер (пулы kea, DNS, enable) | PHP playback `pfsense_dhcp.php` |
| SNMP, резолвер Unbound, режим исходящего NAT | PHP playback `pfsense_services.php` |
| Системные тюнеры + внешний вид Web GUI | PHP playback `pfsense_advanced.php` |
| GUI TLS-сертификат (refid сохраняется) + bcrypt-хеш admin | PHP playback `pfsense_cert_admin.php` |

Настройки без модуля `pfsensible.core` применяются маленькими идемпотентными
PHP-скриптами: они рендерятся из Jinja2 и выполняются интерпретатором `php`
pfSense. Каждый скрипт сравнивает желаемое и текущее состояние, пишет конфиг
**только при отличии**, вызывает нужную функцию применения `*_configure()` и
печатает `PFSENSE_CHANGED` / `PFSENSE_UNCHANGED`, чтобы Ansible корректно
показывал статус `changed`.

## Требования

```bash
ansible-galaxy collection install -r requirements.yml   # pfsensible.core
```

Роутер должен быть доступен по SSH под пользователем с shell-доступом (по
умолчанию `admin`) и иметь Python (`/usr/local/bin/python3.11` на pfSense 24.x).

## Переключатель безопасности — проверка vs применение

`pfsense_apply` (по умолчанию `false`):

* `false` — **только проверка**. Модульные таски идут в `check_mode`; PHP-скрипты
  работают в режиме dry-run (считают разницу, печатают `PFSENSE_CHANGED`, но
  **не** пишут конфиг).
* `true` — **применение**. Изменения записываются и применяются.

```bash
# Сухой прогон (отчёт о расхождениях)
ansible-playbook playbooks/pfsense-config.yml -l pfsense

# Применение
ansible-playbook playbooks/pfsense-config.yml -l pfsense -e pfsense_apply=true
```

## Теги

`system`, `certificate`, `admin`, `vlans`, `interfaces`, `gateways`, `aliases`,
`rules`/`firewall`, `nat`/`force-dns`, `dhcp`, `static`/`hosts`,
`services`/`snmp`/`unbound`, `dns`/`overrides`, `advanced`, `debug`.

```bash
ansible-playbook playbooks/pfsense-config.yml -l pfsense -e pfsense_apply=true --tags interfaces,rules
# только части из единого списка хостов (static mappings + DNS overrides):
ansible-playbook playbooks/pfsense-config.yml -l pfsense -e pfsense_apply=true --tags hosts
```

## Единый список хостов (один источник истины для имён)

`pfsense_hosts` — **один список**, который роль разворачивает сразу в ОБА механизма:

* **static mappings DHCP** (`pfsense_dhcp_static`) — для записей с `mac`;
* **host overrides DNS Resolver** (`pfsense_dns_resolver`) — для **каждой** записи (A + PTR).

Поля записи: `name`, `segment`, `ip` и опц. `mac`, `descr`, `aliases`,
`static_arp`. `pfsense_segments` сопоставляет `segment` с id интерфейса pfSense и
зоной DNS. При бэкенде **Kea** в Resolver нет галки «Register DHCP static»,
поэтому именно host overrides надёжно дают имена в DNS — каждый хост получает
прямое/обратное имя независимо от бэкенда DHCP. Добавляете устройство в одном
месте — и резервация, и DNS-имя следуют за ним.

`pfsense_dns_overrides_extra` — host overrides вне сегментов (напр. плоские имена
сервисов за Traefik). **Force-DNS** (`pfsense_force_dns`) заворачивает клиентский
`:53` на DNS-стек через `pfsense_nat_port_forward`.

## Вне области роли — отдельный плейбук

У Captive Portal (Guest) и pfBlockerNG-devel **нет** модуля `pfsensible.core`, и
они намеренно **не** входят в эту роль. См. `playbooks/pfsense-portal-pfblocker.yml`
(установка пакета + проверяемый чек-лист).

## Переменные

* **`defaults/main.yml`** — переключатели apply/debug, тумблеры секций
  (`pfsense_manage_*`) и пустые заготовки.
* **`host_vars/pfsense.yml`** — фактическое желаемое состояние (система,
  интерфейсы, шлюзы, группы шлюзов, алиасы, правила, DHCP, SNMP, Unbound,
  advanced/webgui).
* **`VARS/secrets.yaml`** — секреты `pfsense_*`: пользователь/пароль подключения,
  bcrypt-хеш admin, GUI-сертификат (base64 crt/prv + refid), SNMP community.

## Особенности текущего состояния роутера (сохранены 1:1)

* Интерфейс **`opt5` (cam_network)** в живом конфиге без флага `enable` —
  воспроизводится **выключенным**.
* DHCP-пулы: `opt5` **включён**, `opt6` **выключен**, `lan` **включён** — ровно
  как в живом конфиге (хотя интерфейс `opt5` выключен).
* **SNMP** сохраняет `rocommunity`, но демон **выключен** (нет флага `enable`).
* **VLAN 10/20/30** на `igc0` — роль *умеет* их создавать (`pfsense_vlan`), но
  `pfsense_vlans` оставлен **пустым** под живое плоское состояние LAN; заполняйте
  только при миграции TRUST/IoT/Guest (02 §3.1), в окно обслуживания.
* GUI-**сертификат** и пароль **admin** (bcrypt) применяются **как есть** из
  `secrets.yaml`, с сохранением исходного `refid`.
* Стандартные cron-задачи — встроенные в pfSense (создаются автоматически) и
  ролью не управляются.

## Оговорка — нумерация интерфейсов (только greenfield)

При применении к **чистому** pfSense `pfsense_interface` назначает следующий
свободный слот `optX`, поэтому точные номера (`opt1/opt5/opt6`) могут отличаться.
На существующем роутере (сопоставление по описанию интерфейса) нумерация
сохраняется. Правила, шлюзы и DHCP ссылаются на интерфейсы по их id pfSense, как
в живом конфиге.
