# dns_adguard

Роль устанавливает AdGuard Home, создает минимальную DNS-конфигурацию и управляет его systemd-сервисом на Debian.

## Что делает

- Загружает и устанавливает AdGuard Home.
- Создает конфигурацию DNS и веб-интерфейса.
- Управляет сервисом `AdGuardHome`; изменение конфигурации вызывает handler перезапуска.

## Требования

- Debian или Ubuntu, `become: true` и доступ к URL архива.
- Обязательный секрет `vault_dns_adguard_admin_password_hash` из `VARS/secrets.yml`.

## Изменяемые ресурсы

- Packages: none.
- Files: `/opt/AdGuardHome`, systemd unit и `AdGuardHome.yaml`.
- Services: `AdGuardHome`.
- Users/groups: none.
- Firewall/API objects: none.

## Переменные

| Variable | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `dns_adguard_debug_mode` | boolean | no | `false` | Показывает факт изменения. |
| `dns_adguard_archive_url` | string | no | официальный URL | Архив AdGuard Home. |
| `dns_adguard_install_dir` | string | no | `"/opt/AdGuardHome"` | Каталог установки. |
| `dns_adguard_service_name` | string | no | `"AdGuardHome"` | Имя systemd-сервиса. |
| `dns_adguard_service_state` | string | no | `"started"` | Устойчивое состояние сервиса. |
| `dns_adguard_service_enabled` | boolean | no | `true` | Включает сервис при загрузке. |
| `dns_adguard_dns_port` | integer | no | `53` | Порт DNS. |
| `dns_adguard_web_port` | integer | no | `3000` | Порт веб-интерфейса. |
| `dns_adguard_admin_user` | string | no | `"admin"` | Пользователь веб-интерфейса. |
| `dns_adguard_upstream_dns` | list | no | `["127.0.0.1:5335"]` | Вышестоящие DNS-серверы. |
| `vault_dns_adguard_admin_password_hash` | string | yes | - | Хэш пароля администратора из Vault. |

## Использование

```yaml
---
- name: Configure AdGuard Home
  hosts: dns
  become: true
  roles:
    - role: dns_adguard
      vars:
        dns_adguard_upstream_dns: ["127.0.0.1:5335"]
```

## Check mode и diff mode

Скачивание архива и регистрация сервиса имеют ограничения check mode. Шаблон конфигурации использует `no_log: true` и `diff: false`, поэтому секретный хэш не выводится.

## Зависимости

- None
