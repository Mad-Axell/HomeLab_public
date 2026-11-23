# asterisk

Роль устанавливает SIP-сервер Asterisk из репозитория Sangoma FreePBX (в
Debian пакета `asterisk` нет начиная с bookworm, см. баг 1031046) и минимально
управляет его конфигурацией через шаблоны. В проекте это LXC `asterisk`
(`172.30.150.41`) в сети CAM на pve-nvr — SIP-сервер домофона: pfSense
пробрасывает на него сигнализацию 5060–5061 TCP/UDP и медиа 10000–20000 UDP
с интерфейса WAN3 (домофон УК), а Asterisk отвечает на вызовы и направляет их
на внутренние телефоны.

## Что делает

- Проверяет, что целевая система — Debian, что задан хотя бы один endpoint с
  `name` и `context` и хотя бы один контекст диалплана с `extensions`,
  содержащими `exten`, `priority` и `app`.
- Регистрирует APT-репозиторий Sangoma FreePBX (ключ с
  `deb.freepbx.org/gpg/aptly-pubkey.asc`, сохраняется в
  `/etc/apt/keyrings/sangoma.asc`).
- Создаёт системных пользователя и группу `asterisk`, ожидаемых пакетами.
- Устанавливает набор пакетов `asterisk22`.
- Пишет `/etc/asterisk/pjsip.conf` из шаблона: секции транспортов (UDP/TCP с
  опциональными `external_signaling_address`, `external_media_address` и
  `local_net` для работы за NAT) и по набору секций `endpoint`, `auth`,
  `aor`, `identify` и `registration` на каждый элемент `asterisk_endpoints`.
- Пишет `/etc/asterisk/rtp.conf` с диапазоном портов медиа.
- Пишет `/etc/asterisk/extensions.conf` с контекстами из `asterisk_dialplan`.
- Управляет сервисом `asterisk` (старт при загрузке, устойчивое состояние
  `started`/`stopped`).

## Ограничения

- Роль **не настраивает NAT и файрвол на pfSense**. Port-forward
  `5060–5061 TCP/UDP` и `10000–20000 UDP` с WAN3 на `172.30.150.41` и правила
  WAN3 — обязательное внешнее требование, описанное в
  `Docs/04_firewall_nat_security.md` (§3 «WAN3», §6 «Port Forward WAN3 →
  Asterisk»).
- Роль не поднимает SIP-TLS (5061): сертификаты и транспорт TLS не
  управляются, проброшенный порт 5061 остаётся неиспользуемым, пока TLS не
  настроен иначе.
- Роль пишет три файла конфигурации целиком; остальные файлы `/etc/asterisk`
  остаются в состоянии пакета. Прочие секции (`[general]` pjsip, modules.conf
  и т.п.) не управляются.
- Сетевая идентичность контейнера (IP, шлюз, DNS) живёт в inventory
  (`hosts.yml`), а не в переменных роли.

## Требования

- Целевая ОС: Debian 12 (bookworm); репозиторий `freepbx17-prod` Sangoma
  публикует только suite bookworm. В самом Debian пакета `asterisk` нет
  начиная с bookworm.
- Права: `become: true`.
- Секреты: playbook подключает `VARS/secrets.yml` через `vars_files`; роль
  сама файл секретов не загружает.
- Сеть: pfSense с настроенным port-forward и правилами WAN3 (см. ограничения).

## Изменяемые ресурсы

- Packages: `asterisk`.
- Files: `/etc/asterisk/pjsip.conf` (0640, root:asterisk);
  `/etc/asterisk/extensions.conf` (0640, root:asterisk);
  `/etc/asterisk/rtp.conf` (0640, root:asterisk).
- Services: `asterisk`.
- Users/groups: системные пользователь и группа `asterisk` (создаются ролью)
- Firewall/API objects: none

## Переменные

| Variable | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `asterisk_sip_port` | integer | no | `5060` | Порт привязки SIP-транспортов на всех адресах. |
| `asterisk_transports` | list of strings | no | `["udp", "tcp"]` | Протоколы, для которых пишутся секции транспорта: `udp`, `tcp`. |
| `asterisk_external_address` | string or null | no | `null` | Адрес, объявляемый в SIP/SDP при работе за NAT; обычно адрес WAN3 на pfSense. |
| `asterisk_local_nets` | list of strings | no | `[]` | Внутренние сети (по одной строке `local_net`), которым отдаётся реальный адрес сервера. |
| `asterisk_rtp_port_start` | integer | no | `10000` | Первый порт диапазона RTP-медиа. |
| `asterisk_rtp_port_end` | integer | no | `20000` | Последний порт диапазона RTP-медиа. |
| `asterisk_endpoints` | list of dicts | yes | `[]` | Определения конечных точек/транков (см. ниже); минимум один элемент, иначе `assert`. |
| `asterisk_dialplan` | list of dicts | yes | `[]` | Контексты диалплана (см. ниже); минимум один элемент, иначе `assert`. |
| `asterisk_service_name` | string | no | `"asterisk"` | Имя управляемого сервиса. |
| `asterisk_service_state` | string | no | `"started"` | Устойчивое состояние сервиса: `started` или `stopped`. |
| `asterisk_service_enabled` | boolean | no | `true` | Запускать сервис при загрузке. |
| `asterisk_config_dir` | string | no | `"/etc/asterisk"` | Внутреннее. Каталог конфигурации. |
| `asterisk_unit_path` | string | no | `"/lib/systemd/system/asterisk.service"` | Внутреннее. Путь юнита; проверяется перед управлением сервисом. |
| `asterisk_user` | string | no | `"asterisk"` | Внутреннее. Пользователь демона; создаётся до установки пакета по документации Sangoma. |
| `asterisk_group` | string | no | `"asterisk"` | Внутреннее. Группа демона, которой читаемы файлы конфигурации. |
| `asterisk_repository_url` | string | no | `"http://deb.freepbx.org/freepbx17-prod"` | APT-репозиторий Sangoma FreePBX; в Debian пакета asterisk нет начиная с bookworm (баг 1031046). |
| `asterisk_repository_suite` | string | no | `"bookworm"` | Дистрибутивный suite репозитория Sangoma (FreePBX 17 ориентирован на Debian 12). |
| `asterisk_repository_component` | string | no | `"main"` | Компонент репозитория. |
| `asterisk_repository_arch` | string | no | `"amd64"` | Архитектура репозитория. |
| `asterisk_repository_key_url` | string | no | `"http://deb.freepbx.org/gpg/aptly-pubkey.asc"` | URL ключа подписи Sangoma; отпечаток `991C 357C 8A35 9D03 82BC 6E87 C4DF E68F CE6D E186`. |
| `asterisk_keyring_directory` | string | no | `"/etc/apt/keyrings"` | Каталог с ключом подписи репозитория. |
| `asterisk_keyring_file` | string | no | `"sangoma.asc"` | ASCII-armored файл ключа, используемый через `signed-by`. |
| `asterisk_prerequisite_packages` | list of strings | no | `["ca-certificates", "python3-apt"]` | Пакеты, необходимые до подключения подписанного репозитория. |
| `asterisk_packages` | list of strings | no | `["asterisk22", "asterisk22-core", "asterisk22-configs"]` | Внутреннее. Устанавливаемые пакеты; Sangoma именует сборки `asterisk<major>`. |
| `asterisk_debug_mode` | boolean | no | `false` | Включить debug-вывод после значимых изменений. |

### Поля endpoint (`asterisk_endpoints`)

| Key | Type | Required | Description |
| --- | --- | --- | --- |
| `name` | string | yes | Имя секций `endpoint`, `auth`, `aor`, `identify`. |
| `context` | string | yes | Контекст диалплана для входящих вызовов. |
| `allowed_codecs` | list of strings | no | Кодеки; по умолчанию `ulaw`, `alaw`. |
| `direct_media` | boolean | no | Прямой обмен медиа между точками. |
| `auth_username` | string | no | Включает секцию `type = auth` (userpass); требует `auth_password_var`. |
| `auth_password_var` | string | yes при `auth_username` | Имя переменной с SIP-паролем (по конвенции `vault_asterisk_<endpoint>_password` из `VARS/secrets.yml`). Открытый `auth_password` отвергается `assert`. |
| `aors` | list of strings | no | Статические `contact` URI; при `auth_username` и пустом списке пишется пустая секция `aor` для регистраций к нам. |
| `identify_matches` | list of strings | no | IP/CIDR источников, сопоставляемых точке без аутентификации (транк по адресу источника). |
| `registration` | dict | no | `server_uri`, `client_uri`, опционально `retry_interval` — секция исходящей регистрации. |
| `extra` | dict | no | Дополнительные опции endpoint, например `force_rport`, `rtp_symmetric`, `rewrite_contact` для работы за NAT. |

### Поля диалплана (`asterisk_dialplan`)

| Key | Type | Required | Description |
| --- | --- | --- | --- |
| `context` | string | yes | Имя контекста `[context]`. |
| `extensions` | list of dicts | yes | Строки `exten = <exten>,<priority>,<app>`: `exten`, `priority`, `app` обязательны. |

### Секреты (VARS/secrets.yml, без defaults)

- `vault_asterisk_<endpoint>_password` — SIP-пароль endpoint; имя переменной
  передаётся в `auth_password_var`.

Таска записи `pjsip.conf` выполняется с `no_log: true` и `diff: false`, режим
файла — `0640` и читаемость группой `asterisk`; значения секретов не
выводятся в логи, diff и debug.

## Использование

```yaml
---
- name: Run asterisk
  hosts: asterisk
  become: true
  vars_files:
    - ../VARS/secrets.yml
  roles:
    - role: asterisk
      vars:
        asterisk_external_address: "10.x.x.x"   # адрес WAN3 на pfSense
        asterisk_local_nets:
          - "172.30.150.0/24"
        asterisk_endpoints:
          - name: "doorphone"
            context: "doorphone-in"
            identify_matches:
              - "10.x.x.x"                      # сеть домофона на WAN3
            extra:
              force_rport: "yes"
              rtp_symmetric: "yes"
              rewrite_contact: "yes"
          - name: "house-phone"
            context: "internal"
            auth_username: "phone1"
            auth_password_var: "vault_asterisk_house_phone_password"
        asterisk_dialplan:
          - context: "doorphone-in"
            extensions:
              - exten: "s"
                priority: 1
                app: "Answer"
              - exten: "s"
                priority: 2
                app: "Dial(PJSIP/house-phone,20)"
              - exten: "s"
                priority: 3
                app: "Hangup"
          - context: "internal"
            extensions:
              - exten: "_X."
                priority: 1
                app: "Hangup"
        asterisk_debug_mode: true
```

## Handlers

- `Restart Asterisk` — полный рестарт после изменения `pjsip.conf` или
  `rtp.conf`; пропускается, если `asterisk_service_state` не равно `started`.
- `Reload Asterisk` — `asterisk -rx 'core reload'` после изменения
  `extensions.conf`; пропускается, если `asterisk_service_state` не равно
  `started`.

> Два handler'а разделены осознанно: привязки транспортов и диапазон
> медиапортов читаются только при запуске демона — `core reload` молча
> оставил бы их без изменений, поэтому для `pjsip.conf` и `rtp.conf`
> выполняется рестарт. Диалплан `core reload` перечитывает на лету, и
> текущие вызовы не обрываются.

## Tags

- `debug` — итоговая debug-задача; отключается через `--skip-tags debug`.

## Templates

- `pjsip.conf.j2` — секции `transport` по `asterisk_transports` и набор
  `endpoint`/`auth`/`aor`/`identify`/`registration` на каждый элемент
  `asterisk_endpoints`.
- `extensions.conf.j2` — заголовок `[general]` и по контексту на элемент
  `asterisk_dialplan`.
- `rtp.conf.j2` — диапазон `rtpstart`/`rtpend`.

## Check mode и diff mode

Роль запускается так:

```bash
ansible-playbook playbook.yml --check --diff
```

Честные ограничения:

- Сервисный таск пропускается, если юнит `asterisk.service` отсутствует —
  на чистом хосте в check mode пакет не ставится, и systemd нечем управлять.
- Diff файла `pjsip.conf` скрыт (`diff: false`), так как он содержит
  SIP-пароли; сам факт изменения виден.
- Handler `Reload Asterisk` выполняется через `ansible.builtin.command` и в
  check mode не запускается (handlers в любом случае выполняются только по
  notify).
- Таска разрешения секретов скрыта `no_log` и ничего не показывает.
- Задачи пакетов и шаблонов `extensions.conf`/`rtp.conf` полноценно
  поддерживают `--check --diff`.

## Зависимости

- None

## Примечания

- Порты проекта: SIP `5060–5061` TCP/UDP, RTP `10000–20000` UDP
  (`Docs/06_services_catalog.md` §4.3, `Docs/04_firewall_nat_security.md` §6).
- Для endpoint за NAT полезны опции `extra`: `force_rport: "yes"`,
  `rtp_symmetric: "yes"`, `rewrite_contact: "yes"` — по ситуации на стороне
  домофона.
- Без `asterisk_external_address` Asterisk объявляет в SDP свой адрес CAM,
  недоступный домофону на WAN3; для транка через NAT переменную стоит задать.
- Валидность синтаксиса шаблонов проверяется первым реальным прогоном
  (`asterisk -rx 'core show config'` или ошибкой сервиса); роль не выполняет
  отдельную валидацию конфигурации.
