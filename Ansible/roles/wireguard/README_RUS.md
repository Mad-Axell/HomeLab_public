# wireguard

Роль поднимает входящий сервер удалённого доступа WireGuard в Debian-контейнере.
В проекте это LXC `vpn` (`172.25.250.2/29`) во внутреннем transit-сегменте
`vmbr2` на pve-router: pfSense пробрасывает на него UDP/51820 с WAN1/WAN2, а
туннельная подсеть — `10.50.250.0/24` с сервером `10.50.250.1`.

## Что делает

- Проверяет, что целевая система — Debian, что в контейнере доступен
  `/dev/net/tun`, что заданы `wireguard_tunnel_address` и
  `wireguard_private_key_var`, и что каждый пир несёт `name`, `allowed_ips` и
  `public_key`/`public_key_var`.
- Устанавливает `wireguard-tools` (утилиты `wg` и `wg-quick`). Модуль ядра
  предоставляет хост контейнера, поэтому метапакет `wireguard` не ставится.
- Включает `net.ipv4.ip_forward` через drop-in
  `/etc/sysctl.d/99-wireguard-forward.conf`.
- Создаёт `/etc/wireguard` с правами `0700` и пишет в него
  `<wireguard_interface_name>.conf` с правами `0600` из шаблона.
- Управляет инстансом `wg-quick@<wireguard_interface_name>` (старт при
  загрузке, устойчивое состояние `started`/`stopped`).

## Ограничения

- Роль делает **только маршрутизацию, без NAT/маскарадинга** — это
  обязательный вариант по `Docs/instructions/06_wireguard_vpn.md`: он
  сохраняет реальные адреса клиентов (`10.50.250.x`) в логах и правилах
  pfSense. Возврат трафика обеспечивает статический маршрут
  `10.50.250.0/24` через `172.25.250.2` на pfSense — его роль не создаёт.
- Роль не генерирует клиентские конфиги и QR-коды. DNS клиентам (`172.25.26.11`)
  и список доступных подсетей задаются в клиентском конфиге, а не в `wg0.conf`.
- Настройка pfSense (port-forward UDP/51820 на WAN1/WAN2, шлюз `WG_LXC`,
  статический маршрут, правила `VPN_NET`/`VPN_ADMIN_PEERS` на LAN_VPN_TRANSIT)
  вне зоны ответственности роли и описана в
  `Docs/instructions/06_wireguard_vpn.md`.
- Поле `group` пира (`admin`/`user`) — информационная метка для проектного
  разделения peer-групп и дизайна ACL на pfSense (`VPN_ADMIN_PEERS`); в
  `wg0.conf` она попадает только комментарием.
- Сетевая идентичность контейнера (IP, шлюз, DNS) живёт в inventory
  (`hosts.yml`), а не в переменных роли.

## Требования

- Ansible: коллекция `ansible.posix` (модуль `sysctl`), зафиксирована в
  project-level `requirements.yml`.
- Целевая ОС: Debian.
- Права: `become: true`.
- Контейнер: в unprivileged LXC должно быть доступно `/dev/net/tun` (bind с
  хоста, см. `Docs/instructions/06_wireguard_vpn.md` §1), а модуль `wireguard`
  загружен на хосте (`modprobe wireguard`). Иначе роль остановится на `assert`.
- Секреты: playbook подключает `VARS/secrets.yml` через `vars_files`; роль
  сама файл секретов не загружает.

## Изменяемые ресурсы

- Packages: `wireguard-tools`.
- Files: `/etc/sysctl.d/99-wireguard-forward.conf`;
  `/etc/wireguard/` (0700);
  `/etc/wireguard/<wireguard_interface_name>.conf` (0600).
- Services: `wg-quick@<wireguard_interface_name>`.
- Users/groups: none
- Firewall/API objects: none (NAT на LXC осознанно отсутствует)

## Переменные

| Variable | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `wireguard_interface_name` | string | no | `"wg0"` | Имя интерфейса; определяет инстанс `wg-quick@` и имя файла конфигурации. |
| `wireguard_tunnel_address` | string | yes | `null` | Туннельный адрес сервера с префиксом, например `"10.50.250.1/24"`. Роль падает на `assert`, если не задан. |
| `wireguard_listen_port` | integer | no | `51820` | UDP-порт интерфейса; именно его пробрасывает pfSense. |
| `wireguard_peers` | list of dicts | no | `[]` | Определения пиров (см. ниже). Пустой список — сервер без клиентов. |
| `wireguard_private_key_var` | string | yes | `null` | Имя переменной с приватным ключом сервера (по конвенции `vault_wireguard_server_private_key` из `VARS/secrets.yml`). Роль падает на `assert`, если не задана или переменная не определена. |
| `wireguard_service_state` | string | no | `"started"` | Устойчивое состояние сервиса: `started` или `stopped`. |
| `wireguard_service_enabled` | boolean | no | `true` | Запускать `wg-quick@` при загрузке. |
| `wireguard_config_dir` | string | no | `"/etc/wireguard"` | Внутреннее. Каталог конфигурации интерфейсов. |
| `wireguard_sysctl_file` | string | no | `"/etc/sysctl.d/99-wireguard-forward.conf"` | Внутреннее. Drop-in с форвардингом IPv4. |
| `wireguard_unit_path` | string | no | `"/lib/systemd/system/wg-quick@.service"` | Внутреннее. Путь шаблонного юнита; проверяется перед управлением сервисом. |
| `wireguard_packages` | list of strings | no | `["wireguard-tools"]` | Внутреннее. Устанавливаемые пакеты. |
| `wireguard_debug_mode` | boolean | no | `false` | Включить debug-вывод после значимых изменений. |

### Поля пира (`wireguard_peers`)

| Key | Type | Required | Description |
| --- | --- | --- | --- |
| `name` | string | yes | Имя пира; пишется комментарием над секцией `[Peer]`. |
| `group` | string | no | Информационная ACL-метка (`admin`, `user`) для группировки адресов пиров на pfSense; в конфиге — только комментарий. |
| `allowed_ips` | list of strings | yes | CIDR, маршрутизируемые к пиру; обычно один `/32` из туннельной подсети. |
| `public_key` | string | одно из двух | Публичный ключ пира напрямую. |
| `public_key_var` | string | одно из двух | Имя переменной с публичным ключом, разрешаемой во время прогона. |
| `preshared_key_var` | string | no | Имя переменной с preshared-ключом (по конвенции `vault_wireguard_<peer>_preshared_key`). Открытый `preshared_key` отвергается `assert`. |
| `persistent_keepalive` | integer | no | Секунды между keepalive-пакетами (по проекту — 25). |

### Секреты (VARS/secrets.yml, без defaults)

- `vault_wireguard_server_private_key` — приватный ключ сервера; имя переменной
  передаётся в `wireguard_private_key_var`.
- `vault_wireguard_<peer>_public_key` — при использовании `public_key_var`.
- `vault_wireguard_<peer>_preshared_key` — при использовании
  `preshared_key_var`.

Таска записи `wg0.conf` выполняется с `no_log: true` и `diff: false`, режим
файла — `0600`; значения секретов не выводятся в логи, diff и debug.

## Использование

```yaml
---
- name: Run wireguard
  hosts: vpn-wireguard
  become: true
  vars_files:
    - ../VARS/secrets.yml
  roles:
    - role: wireguard
      vars:
        wireguard_tunnel_address: "10.50.250.1/24"
        wireguard_private_key_var: "vault_wireguard_server_private_key"
        wireguard_peers:
          - name: "admin-phone"
            group: "admin"
            public_key_var: "vault_wireguard_admin_phone_public_key"
            preshared_key_var: "vault_wireguard_admin_phone_preshared_key"
            allowed_ips:
              - "10.50.250.2/32"
            persistent_keepalive: 25
          - name: "user-laptop"
            group: "user"
            public_key: "<публичный ключ пира>"
            allowed_ips:
              - "10.50.250.3/32"
        wireguard_debug_mode: true
```

## Handlers

- `Restart WireGuard interface` — пересоздаёт туннель после изменения
  `wg0.conf`; пропускается, если `wireguard_service_state` не равно `started`.

> Используется полный рестарт, а не `wg syncconf`: syncconf применяет
> добавления и изменения, но **не удаляет** пиров, убранных из конфигурации,
> поэтому удалённые клиенты сохранили бы доступ. Рестарт на мгновение роняет
> туннель — приемлемая цена за гарантированное удаление пиров.

## Tags

- `debug` — итоговая debug-задача; отключается через `--skip-tags debug`.

## Templates

- `wg0.conf.j2` — секция `[Interface]` с адресом, портом и приватным ключом и
  по одной секции `[Peer]` на элемент `wireguard_peers` с `PublicKey`,
  опциональным `PresharedKey`, `AllowedIPs` и `PersistentKeepalive`.

## Check mode и diff mode

Роль запускается так:

```bash
ansible-playbook playbook.yml --check --diff
```

Честные ограничения:

- Сервисный таск пропускается, если юнит `wg-quick@.service` отсутствует —
  на чистом хосте в check mode пакет не ставится, и systemd нечем управлять.
  Первый реальный прогон устанавливает пакет и управляет сервисом.
- Diff файла `wg0.conf` скрыт (`diff: false`), так как он содержит приватный
  и preshared-ключи; сам факт изменения виден.
- Таска разрешения секретов скрыта `no_log` и ничего не показывает.
- Задачи пакетов, sysctl, каталога и шаблона полноценно поддерживают
  `--check --diff`.

## Зависимости

- Коллекция `ansible.posix` (модуль `ansible.posix.sysctl`); зафиксирована в
  project-level `requirements.yml`.

## Примечания

- Сетевые параметры туннеля в проекте: сервер `10.50.250.1/24`,
  `ListenPort 51820`, keepalive 25, доступные клиентам подсети
  `172.25.26.0/24, 172.25.40.0/24, 172.30.150.0/24, 172.20.10.0/24` —
  задаются в клиентских конфигах (`AllowedIPs`), не в роли
  (`Docs/04_firewall_nat_security.md` §9).
- Порядок сопутствующих шагов вне роли: port-forward на pfSense, шлюз
  `WG_LXC` и маршрут к `10.50.250.0/24`, правила `VPN_NET` — см.
  `Docs/instructions/06_wireguard_vpn.md` §3.
- Провижининг контейнера (часовой пояс, отключение IPv6, bind `/dev/net/tun`)
  выполняется на уровне создания LXC и не входит в задачу роли.
- Бэкап `/etc/wireguard/` (ключи!) выполняйте в защищённое место — роль
  резервных копий не делает.
