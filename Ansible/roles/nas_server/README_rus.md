# nas_server

Роль создает один каталог NAS и экспортирует его через Samba, NFS или оба протокола.

## Что делает

- Создает каталог общего ресурса.
- Устанавливает и настраивает Samba, если включена.
- Устанавливает и настраивает NFS, если включен.

## Требования

- Debian или Ubuntu и `become: true`.

## Изменяемые ресурсы

- Packages: `samba`, `nfs-kernel-server` по включенным протоколам.
- Files: каталог ресурса, `/etc/samba/smb.conf`, `/etc/exports.d/<share>.exports`.
- Services: `smbd`, `nfs-server`.
- Users/groups: none.
- Firewall/API objects: SMB и NFS должны быть разрешены отдельной настройкой файрвола.

## Переменные

| Variable | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `nas_server_debug_mode` | boolean | no | `false` | Показывает факт изменения. |
| `nas_server_share_path` | string | yes | `null` | Путь экспортируемого каталога. |
| `nas_server_share_name` | string | no | `"data"` | Имя Samba/NFS ресурса. |
| `nas_server_samba_enabled` | boolean | no | `true` | Включает Samba. |
| `nas_server_samba_guest_ok` | boolean | no | `false` | Разрешает гостевой доступ Samba. |
| `nas_server_nfs_enabled` | boolean | no | `false` | Включает NFS. |
| `nas_server_nfs_clients` | list | conditional | `[]` | Разрешенные клиенты; обязателен при NFS. |

## Использование

```yaml
---
- name: Publish a NAS share
  hosts: nas
  become: true
  roles:
    - role: nas_server
      vars:
        nas_server_share_path: "/srv/data"
        nas_server_nfs_enabled: true
        nas_server_nfs_clients: ["192.168.1.0/24"]
```

## Check mode и diff mode

Шаблоны конфигурации поддерживают `--check --diff`; handler NFS запускает `exportfs -ra` только после изменения экспорта.

## Зависимости

- None
