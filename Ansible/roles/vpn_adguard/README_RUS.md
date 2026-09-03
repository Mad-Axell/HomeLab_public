# vpn_adguard

Роль устанавливает официальный клиент AdGuard VPN CLI в Debian-контейнер,
приводит его конфигурацию к состоянию, пригодному для работы без оператора, и
готовит контейнер к роли исходящего шлюза для других хостов сети.

AdGuard VPN — исходящий (egress) туннель к серверам AdGuard. Роль не поднимает
VPN-сервер и не принимает входящие подключения удалённых клиентов: для удалённого
доступа в лабораторию нужен отдельный сервис.

## Что делает

- Проверяет, что целевая система — Debian и что в контейнере доступен
  `/dev/net/tun`; без этого устройства режим TUN не работает.
- Устанавливает `ca-certificates` и `curl`, а при включённом шлюзе ещё и
  `nftables`.
- Скачивает официальный скрипт установки в файл и запускает его неинтерактивно
  (`-a y`), вместо передачи `curl` напрямую в `sh`.
- Ставит клиент только когда он отсутствует либо когда задана
  `vpn_adguard_version` и установленная версия ей не соответствует.
- Применяет настройки клиента: режим работы, режим маршрутизации TUN,
  запрет на перезапись системного резолвера, DNS туннеля и отключение
  интерактивных подсказок.
- При включённом шлюзе включает `net.ipv4.ip_forward`, пишет таблицу
  маскарадинга nftables для заданных подсетей и подключает её из
  `/etc/nftables.conf`.
- Создаёт systemd-юнит, который поднимает туннель при загрузке и после
  подключения восстанавливает маршруты для подсетей, которые не должны уходить
  в туннель.

## Ограничения

- Роль **не выполняет вход в аккаунт AdGuard**. Официальный клиент авторизуется
  интерактивно (ввод учётных данных или переход по ссылке в браузере), поэтому
  `adguardvpn-cli login` выполняется один раз вручную до первого запуска сервиса
  туннеля. Пока вход не выполнен, `connect` завершится ошибкой и юнит перейдёт в
  `failed`.
- Роль не ограничивает форвардинг: маскарадинг применяется только к подсетям из
  `vpn_adguard_lan_subnets`, но сам форвардинг разрешён политикой ядра по
  умолчанию. Фильтрация выполняется вышестоящим межсетевым экраном.
- Клиент хранит конфигурацию и сессию для пользователя, от имени которого он
  запущен. Роль работает и создаёт юнит от `root`, поэтому вход также нужно
  выполнять от `root`.

## Требования

- Ansible: коллекция `ansible.posix` (модуль `sysctl`), зафиксирована в
  project-level `requirements.yml`.
- Целевая ОС: Debian.
- Права: `become: true`.
- Контейнер: в unprivileged LXC устройство `/dev/net/tun` должно быть проброшено
  с хоста, иначе роль остановится на `assert`.
- Сеть: доступ к `raw.githubusercontent.com` для загрузки скрипта установки и к
  серверам AdGuard для работы туннеля.

## Изменяемые ресурсы

- Packages: `ca-certificates`, `curl`; `nftables` при
  `vpn_adguard_gateway_enabled: true`.
- Files: `vpn_adguard_installer_path`; файлы, которые установщик вендора
  создаёт в `/opt/adguardvpn_cli` и симлинк в `/usr/local/bin`;
  `/etc/sysctl.d/99-vpn-adguard-forward.conf`;
  `/etc/nftables.d/vpn-adguard.nft`; управляемый блок в `/etc/nftables.conf`;
  `/etc/systemd/system/<vpn_adguard_service_name>.service`.
- Services: `nftables` при включённом шлюзе;
  `<vpn_adguard_service_name>`.
- Users/groups: none
- Firewall/API objects: таблица nftables `ip vpn_adguard_nat` с цепочкой
  `postrouting`.

## Переменные

| Variable | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `vpn_adguard_installer_url` | string | no | официальный URL канала release | URL скрипта установки; сегмент пути выбирает канал. |
| `vpn_adguard_installer_path` | string | no | `"/usr/local/src/adguardvpn-cli-install.sh"` | Куда скачивается скрипт установки. |
| `vpn_adguard_install_parent_directory` | string | no | `"/opt"` | Каталог, передаваемый установщику через `-o`. |
| `vpn_adguard_version` | string or null | no | `null` | Фиксация версии через `-V`; `null` — последняя сборка канала. |
| `vpn_adguard_mode` | string | no | `"TUN"` | Режим клиента: `TUN` или `SOCKS`. |
| `vpn_adguard_tun_routing_mode` | string | no | `"AUTO"` | Режим маршрутизации TUN: `NONE`, `AUTO` или `SCRIPT`. |
| `vpn_adguard_dns_server` | string or null | no | `null` | DNS туннеля; `null` оставляет значение клиента. |
| `vpn_adguard_change_system_dns` | string | no | `"off"` | Разрешить клиенту переписывать системный резолвер: `on` или `off`. |
| `vpn_adguard_show_hints` | string | no | `"off"` | Интерактивные подсказки клиента: `on` или `off`. |
| `vpn_adguard_location` | string or null | no | `null` | Локация для `connect -l`; `null` — быстрейшая или последняя. |
| `vpn_adguard_service_name` | string | no | `"adguardvpn-tunnel"` | Имя создаваемого systemd-юнита. |
| `vpn_adguard_service_state` | string | no | `"started"` | Устойчивое состояние сервиса: `started` или `stopped`. |
| `vpn_adguard_service_enabled` | boolean | no | `true` | Запускать сервис туннеля при загрузке. |
| `vpn_adguard_gateway_enabled` | boolean | no | `true` | Готовить контейнер к работе шлюзом. |
| `vpn_adguard_lan_subnets` | list of strings | yes при включённом шлюзе | `[]` | Исходные CIDR, чей трафик маскарадится в туннель. |
| `vpn_adguard_tunnel_interface` | string | no | `"tun0"` | Интерфейс туннеля, создаваемый клиентом. |
| `vpn_adguard_bypass_networks` | list of strings | no | `[]` | CIDR, выведенные из туннеля ради сохранения управляемости. |
| `vpn_adguard_bypass_gateway` | string or null | yes при непустом списке выше | `null` | Следующий узел для обходных маршрутов. |
| `vpn_adguard_binary_path` | string | no | `"/opt/adguardvpn_cli/adguardvpn-cli"` | Внутреннее. Путь исполняемого файла клиента. |
| `vpn_adguard_ip_command` | string | no | `"/usr/sbin/ip"` | Внутреннее. Путь `ip` для обходных маршрутов в юните. |
| `vpn_adguard_nft_command` | string | no | `"/usr/sbin/nft"` | Внутреннее. Путь `nft` для валидации набора правил. |
| `vpn_adguard_sysctl_file` | string | no | `"/etc/sysctl.d/99-vpn-adguard-forward.conf"` | Внутреннее. Файл sysctl с форвардингом. |
| `vpn_adguard_nftables_file` | string | no | `"/etc/nftables.d/vpn-adguard.nft"` | Внутреннее. Файл таблицы маскарадинга. |
| `vpn_adguard_nftables_main_config` | string | no | `"/etc/nftables.conf"` | Внутреннее. Основная конфигурация nftables. |
| `vpn_adguard_packages` | list of strings | no | `["ca-certificates", "curl"]` | Внутреннее. Пакеты для установщика. |
| `vpn_adguard_gateway_packages` | list of strings | no | `["nftables"]` | Внутреннее. Пакеты только для шлюза. |
| `vpn_adguard_debug_mode` | boolean | no | `false` | Включить debug-вывод после значимых изменений. |

Секретов роль не принимает: учётные данные AdGuard вводятся вручную при
`adguardvpn-cli login` и не хранятся в inventory.

## Использование

```yaml
---
- name: Run vpn_adguard
  hosts: vpn
  become: true
  roles:
    - role: vpn_adguard
      vars:
        vpn_adguard_lan_subnets:
          - "172.20.20.0/24"
        vpn_adguard_bypass_networks:
          - "172.20.10.0/24"
        vpn_adguard_bypass_gateway: "172.25.250.1"
        vpn_adguard_dns_server: "172.25.26.11"
        vpn_adguard_debug_mode: true
```

## Handlers

- `Reload nftables` — перезагружает набор правил после изменения таблицы
  маскарадинга или подключающего блока.
- `Restart AdGuard VPN tunnel` — пересоздаёт туннель после изменения юнита;
  пропускается, если `vpn_adguard_service_state` не равно `started`.

## Tags

- `debug` — итоговая debug-задача; отключается через `--skip-tags debug`.

## Templates

- `vpn-adguard.nft.j2` — таблица `ip vpn_adguard_nat`. Файл начинается с
  объявления и удаления таблицы, поэтому его можно перечитывать многократно без
  дублирования правил и без влияния на чужие таблицы.
- `adguardvpn-tunnel.service.j2` — юнит типа `oneshot` с `RemainAfterExit`,
  потому что `connect` уходит в фон и возвращает управление.

## Check mode и diff mode

Роль запускается так:

```bash
ansible-playbook playbook.yml --check --diff
```

Честные ограничения:

- Установка клиента и применение его настроек выполняются через
  `ansible.builtin.command`, поэтому в check mode они не запускаются. На хосте
  без установленного клиента check-прогон покажет только шаги с пакетами,
  файлами и сервисами.
- Задача применения настроек дополнительно ограничена условием
  `when: not ansible_check_mode`.
- Факт изменения конфигурации определяется сравнением вывода
  `adguardvpn-cli config show` до и после применения. Если вендор добавит в этот
  вывод изменяющиеся поля, задача начнёт сообщать `changed` при каждом прогоне;
  проверяйте это при первом реальном запуске.
- Задачи с файлами, sysctl, шаблонами и сервисами полноценно поддерживают
  `--check --diff`.

## Зависимости

- Коллекция `ansible.posix` (модуль `ansible.posix.sysctl`); зафиксирована в
  project-level `requirements.yml`.

## Примечания

- Порядок первого запуска: прогнать роль, затем один раз выполнить
  `adguardvpn-cli login` внутри контейнера, затем
  `systemctl start <vpn_adguard_service_name>` либо повторить прогон роли.
- `vpn_adguard_change_system_dns` по умолчанию `off`, чтобы клиент не переписал
  `/etc/resolv.conf` контейнера и не увёл его с резолвера проекта.
- `vpn_adguard_bypass_networks` решает практическую проблему: при
  `vpn_adguard_tun_routing_mode: AUTO` клиент устанавливает маршруты туннеля, и
  ответы на входящие подключения из других подсетей могут уйти в туннель. Юнит
  после `connect` возвращает такие подсети на исходный шлюз. Всегда указывайте
  здесь сеть, из которой вы администрируете контейнер, кроме сети, к которой он
  подключён напрямую.
- Обновление клиента роль не выполняет автоматически: при отсутствии
  `vpn_adguard_version` установщик запускается только когда клиента нет. Чтобы
  обновиться, задайте новое значение `vpn_adguard_version` или выполните
  штатную команду обновления клиента.
