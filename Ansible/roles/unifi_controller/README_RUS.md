# unifi_controller

Роль разворачивает полный стек UniFi Network Server на Debian: среда Java, сервер
MongoDB и сам пакет UniFi из двух явно заданных подписанных APT-репозиториев.

## Что делает

- Проверяет платформу Debian и заданные URI и ключи обоих репозиториев.
- Проверяет наличие флага CPU `avx`, без которого MongoDB 5.0 и новее не стартует.
- Устанавливает `ca-certificates`, `curl` и `gnupg`, создаёт общий каталог keyring.
- Подключает ключ и репозиторий MongoDB, затем ключ и репозиторий UniFi.
- Устанавливает JRE и сервер MongoDB, приводит пакетный юнит `mongod` к
  устойчивому состоянию (по умолчанию — остановлен, см. ниже).
- Устанавливает пакет UniFi без `recommends` и приводит его сервис к устойчивому
  состоянию.

Порядок важен: пакет `unifi` объявляет зависимость `mongodb-org-server`, поэтому
MongoDB подключается и ставится до UniFi. Флаг `install_recommends: false`
не даёт APT подтянуть debian-пакеты `mongodb`.

## Требования

- Debian, `become: true` и сетевой доступ к обоим репозиториям.
- Собранные facts: роль читает `ansible_facts.os_family`. Флаги CPU
  Ansible фактом не отдаёт, поэтому роль читает `/proc/cpuinfo` через `slurp`.
- CPU с AVX, если `unifi_controller_require_avx` оставлен включённым.
- Пакет JRE из `unifi_controller_java_package` должен удовлетворять зависимости
  Java конкретной версии UniFi. Требуемая версия Java меняется между релизами
  UniFi; при смене suite репозитория её нужно перепроверить в поле `Depends`
  пакета `unifi`.

## Изменяемые ресурсы

- Packages: `ca-certificates`, `curl`, `gnupg`, `unifi_controller_java_package`,
  `unifi_controller_mongodb_package`, `unifi_controller_package_name`.
- Files: каталог `unifi_controller_keyring_directory`, файлы ключей
  `unifi_controller_mongodb_keyring_file` и `unifi_controller_keyring_file`,
  `/etc/apt/sources.list.d/mongodb-org.list` и
  `/etc/apt/sources.list.d/unifi-controller.list`.
- Services: `unifi_controller_mongodb_service_name`,
  `unifi_controller_service_name`.
- Users/groups: none.
- Firewall/API objects: порты UniFi разрешает отдельная роль firewall.

## Переменные

| Variable | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `unifi_controller_require_avx` | boolean | no | `true` | Требовать флаг CPU `avx` до установки. |
| `unifi_controller_keyring_directory` | string | no | `"/etc/apt/keyrings"` | Каталог ключей подписи. |
| `unifi_controller_java_package` | string | no | `"openjdk-25-jre-headless"` | Пакет JRE для зависимости UniFi. |
| `unifi_controller_mongodb_repository` | string | yes | `null` | URI репозитория MongoDB с suite и компонентом. |
| `unifi_controller_mongodb_repository_key_url` | string | yes | `null` | URL ASCII-armored ключа MongoDB. |
| `unifi_controller_mongodb_keyring_file` | string | no | `"mongodb-server.asc"` | Имя файла ключа MongoDB. |
| `unifi_controller_mongodb_package` | string | no | `"mongodb-org"` | Пакет сервера MongoDB. |
| `unifi_controller_mongodb_service_name` | string | no | `"mongod"` | Пакетный сервис MongoDB. |
| `unifi_controller_mongodb_service_state` | string | no | `"stopped"` | Состояние пакетного сервиса MongoDB. |
| `unifi_controller_mongodb_service_enabled` | boolean | no | `false` | Автозапуск пакетного сервиса MongoDB. |
| `unifi_controller_repository` | string | yes | `null` | URI репозитория UniFi с suite и компонентом. |
| `unifi_controller_repository_key_url` | string | yes | `null` | URL бинарного ключа UniFi. |
| `unifi_controller_keyring_file` | string | no | `"unifi-repo.gpg"` | Имя файла ключа UniFi. |
| `unifi_controller_package_name` | string | no | `"unifi"` | Пакет UniFi. |
| `unifi_controller_service_name` | string | no | `"unifi"` | Сервис UniFi. |
| `unifi_controller_service_state` | string | no | `"started"` | Состояние сервиса UniFi. |
| `unifi_controller_service_enabled` | boolean | no | `true` | Автозапуск сервиса UniFi. |
| `unifi_controller_debug_mode` | boolean | no | `false` | Показывает факт изменения. |

### Почему пакетный `mongod` остановлен

UniFi Network Server сам запускает и контролирует свой процесс `mongod` с
`--dbpath /usr/lib/unifi/data/db` и `--port 27117`, используя тот же бинарь из
`mongodb-org-server`. Пакет `unifi` требует `mongodb-org-server` только как
зависимость, а пакетный юнит `mongod` (порт 27017) в standalone-установке не
используется. Запускать его — значит держать лишний экземпляр СУБД, а на ядрах
6.19 и новее он к тому же падает по
[SERVER-121912](https://jira.mongodb.org/browse/SERVER-121912) и оставляет юнит
в состоянии `failed`.

Если пакетный юнит уже успел упасть (например, при первой установке на ядре
6.19+), роль дополнительно сбрасывает запись об отказе через
`systemctl reset-failed`: без этого остановленный и отключённый юнит
продолжает висеть в `systemctl --failed` и создаёт ложную тревогу.

Поднимайте пакетный сервис только если UniFi намеренно переводится на внешнюю
общую MongoDB; тогда задайте `unifi_controller_mongodb_service_state: "started"`
и `unifi_controller_mongodb_service_enabled: true`.

Расширение файла ключа значимо: ключ MongoDB публикуется в ASCII-armored виде и
именуется `.asc`, ключ UniFi — бинарный OpenPGP и именуется `.gpg`.

## Секретные внешние входы

Роль не использует секретов и не читает `VARS/secrets.yml`.

## Использование

```yaml
---
- name: Install UniFi Network Server
  hosts: unifi
  become: true
  roles:
    - role: unifi_controller
      vars:
        unifi_controller_mongodb_repository: "https://repository.example.invalid/apt/debian bookworm/mongodb-org/8.0 main"
        unifi_controller_mongodb_repository_key_url: "https://repository.example.invalid/static/pgp/server-8.0.asc"
        unifi_controller_repository: "https://repository.example.invalid/unifi/debian unifi-10.4 ubiquiti"
        unifi_controller_repository_key_url: "https://repository.example.invalid/unifi/unifi-repo.gpg"
```

## Check mode и diff mode

Роль поддерживает `--check --diff` частично, и это ограничение APT, а не дефект:

- в check mode репозитории фактически не добавляются, поэтому задачи установки
  `unifi_controller_java_package`, `unifi_controller_mongodb_package` и
  `unifi_controller_package_name` на чистом хосте сообщают об отсутствии
  пакета-кандидата;
- по этой причине полноценный `--check` осмыслен только на хосте, где
  репозитории уже подключены предыдущим реальным прогоном;
- задачи ключа, каталога keyring и сервисов в check mode отрабатывают корректно.

## Зависимости

- None

## Handlers и tags

- Handlers: отсутствуют, роль хранит только устойчивое состояние сервисов.
- Tags: `debug` на итоговой debug-задаче.
