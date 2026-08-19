# coral_edge_tpu

Роль подключает репозиторий Coral, устанавливает runtime и добавляет заданные строки проброса устройств в существующий конфигурационный файл Proxmox LXC.

## Что делает

- Добавляет ключ и APT-репозиторий Coral.
- Устанавливает `libedgetpu1-std` на хосте Proxmox.
- Добавляет только явно переданные строки в `/etc/pve/lxc/<vmid>.conf`.

## Требования

- Debian-based хост Proxmox VE.
- `become: true`.
- Существующий LXC-контейнер.

## Изменяемые ресурсы

- Packages: `libedgetpu1-std`.
- Files: `/etc/apt/keyrings/coral-edge-tpu.gpg`, файл репозитория APT и `/etc/pve/lxc/<vmid>.conf`.
- Services: none.
- Users/groups: none.
- Firewall/API objects: none.

## Переменные

| Variable | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `coral_edge_tpu_debug_mode` | boolean | no | `false` | Показывает факт изменения. |
| `coral_edge_tpu_repository_url` | string | no | URL Google | URL репозитория Coral. |
| `coral_edge_tpu_repository_key_url` | string | no | URL Google | URL ключа подписи. |
| `coral_edge_tpu_package_name` | string | no | `"libedgetpu1-std"` | Пакет runtime. |
| `coral_edge_tpu_lxc_vmid` | integer | yes | `null` | VMID существующего LXC. |
| `coral_edge_tpu_lxc_device_lines` | list | yes | `null` | Конкретные строки проброса устройств LXC. |

## Использование

```yaml
---
- name: Configure Coral USB pass-through
  hosts: proxmox
  become: true
  roles:
    - role: coral_edge_tpu
      vars:
        coral_edge_tpu_lxc_vmid: 101
        coral_edge_tpu_lxc_device_lines:
          - "lxc.cgroup2.devices.allow: c 189:* rwm"
          - "lxc.mount.entry: /dev/bus/usb/001 dev/bus/usb/001 none bind,optional,create=dir 0 0"
```

## Check mode и diff mode

Скачивание ключа, репозиторий и пакет поддерживают `--check --diff` в пределах модулей Ansible. Файл конфигурации LXC меняется предсказуемым модулем `lineinfile`; перезапуск контейнера роль не выполняет.

## Зависимости

- None

## Примечания

- Указывайте только точные строки для нужных устройств. Доступ `lxc.cgroup2.devices.allow: a` намеренно не является значением по умолчанию.
