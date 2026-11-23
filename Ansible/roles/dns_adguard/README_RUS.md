# dns_adguard

Роль устанавливает AdGuard Home, создает минимальную DNS-конфигурацию и управляет его systemd-сервисом на Debian.

## Что делает

- Загружает и устанавливает AdGuard Home.
- **Создаёт начальную** конфигурацию DNS и веб-интерфейса — только если её ещё нет.
- Управляет сервисом `AdGuardHome`; изменение конфигурации вызывает handler перезапуска.

> ⚠ **Роль не управляет конфигурацией работающего экземпляра, и это осознанно.**
> После первого старта файлом `AdGuardHome.yaml` владеет сам AdGuard Home: он
> переписывает его своим полным состоянием — блок-листы, allowlist, DNS rewrites,
> список клиентов, правила фильтрации, хэш пароля администратора. Шаблон роли
> содержит лишь минимум для первого запуска, поэтому его повторная запись
> **удалила бы всё перечисленное**. Задача записи защищена
> `force: {{ dns_adguard_config_force }}` со значением `false` по умолчанию.
>
> Следствие: переменные `dns_adguard_dns_port`, `dns_adguard_web_port`,
> `dns_adguard_admin_user` и `dns_adguard_upstream_dns` применяются **только при
> создании**. На работающем экземпляре меняйте их через API или веб-интерфейс
> AdGuard Home. Прогон роли сообщит об этом отдельным сообщением, чтобы прогон
> без изменений не приняли за применённый.
>
> Сбросить экземпляр до голой конфигурации можно осознанно:
> `-e dns_adguard_config_force=true`. Это уничтожит его текущее состояние.

## Требования

- Debian или Ubuntu, `become: true` и доступ к URL архива.
- Обязательный секрет `vault_dns_adguard_admin_password_hash` из `VARS/secrets.yml`.

## Изменяемые ресурсы

- Packages: none.
- Files: `/opt/AdGuardHome`, systemd unit и `AdGuardHome.yaml` (последний — только при создании, см. предупреждение выше).
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
| `dns_adguard_config_force` | boolean | no | `false` | Перезаписать существующий `AdGuardHome.yaml`. **Уничтожает состояние экземпляра**; только для осознанного сброса. |
| `dns_adguard_dns_port` | integer | no | `53` | Порт DNS. Только при создании конфигурации. |
| `dns_adguard_web_port` | integer | no | `3000` | Порт веб-интерфейса. Только при создании конфигурации. |
| `dns_adguard_admin_user` | string | no | `"admin"` | Пользователь веб-интерфейса. Только при создании конфигурации. |
| `dns_adguard_upstream_dns` | list | no | `["127.0.0.1:5335"]` | Вышестоящие DNS-серверы. Только при создании конфигурации. |
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
