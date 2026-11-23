# proxmox_vm

Создаёт KVM-виртуальную машину на ноде Proxmox, где запущена роль (`hosts:` —
нода, например `pve-main`). VM описывается записью инвентаря — той же формы,
что использует `proxmox_lxc`, с `proxmox.type: vm`.

## Что делает

- Разрешает запись, названную `proxmox_vm_target_host`, через `hostvars` и
  проверяет, что это запись `type: vm` на этой ноде с `ansible_host`,
  `network.bridge` и `network.mac`.
- Скачивает `proxmox_vm_image_url` в `proxmox_vm_image_dir` (пропуск, когда
  распакованный файл уже есть) и распаковывает `.xz` через `xz -df`
  (идемпотентно благодаря `creates`).
- Проверяет VM через `qm status`; при отсутствии выполняет `qm create` с
  заданными cores/memory/balloon, машиной `q35`, BIOS `ovmf`, EFI-диском,
  `virtio`-картой (MAC, мост и опциональный `vlan_tag` из инвентаря),
  последовательным сокетом и QEMU guest agent.
- Импортирует образ через `qm importdisk`, подключает том как `scsi0`
  (`discard=on,iothread=1,ssd=1`) и назначает его загрузочным.
- Увеличивает `scsi0` до `proxmox_vm_disk_size`, только если импортированный
  размер меньше; уменьшения не бывает.
- На существующей VM сверяет только `cores`, `memory`, `balloon`, `sockets`,
  `onboot` и `agent` одним `qm set`. Диск, NIC и прошивка — решения момента
  создания и не перезаписываются.
- Стартует VM, если `proxmox_vm_start` включён.

## Требования

- Запуск на самой ноде Proxmox (утилиты `qm`/`xz` живут там); права root.
- URL образа должен быть достижим с ноды.
- Внешних коллекций нет — только `ansible.builtin`.

## Переменные

| Variable | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `proxmox_vm_target_host` | string | да | `null` | Имя записи VM в инвентаре. |
| `proxmox_vm_cores` | int | нет | `2` | Ядра vCPU. |
| `proxmox_vm_sockets` | int | нет | `1` | Сокеты CPU. |
| `proxmox_vm_memory` | int | нет | `2048` | Память, МиБ. |
| `proxmox_vm_balloon` | int | нет | `0` | Цель balloon, МиБ; `0` — выкл. |
| `proxmox_vm_disk_size` | string | нет | `"32G"` | Целевой размер scsi0; только рост. |
| `proxmox_vm_disk_storage` | string | нет | `"local-lvm"` | Хранилище для импортированного и EFI дисков. |
| `proxmox_vm_image_url` | string | да | `null` | URL образа `.qcow2`/`.qcow2.xz`. |
| `proxmox_vm_image_dir` | string | нет | `"/var/lib/vz/template/iso"` | Каталог загрузки на ноде. |
| `proxmox_vm_bios` | string | нет | `"ovmf"` | Тип BIOS. |
| `proxmox_vm_machine` | string | нет | `"q35"` | Тип машины. |
| `proxmox_vm_scsihw` | string | нет | `"virtio-scsi-single"` | SCSI-контроллер. |
| `proxmox_vm_ostype` | string | нет | `"l26"` | Подсказка типа гостевой ОС. |
| `proxmox_vm_efidisk` | bool | нет | `true` | Создать EFI-диск. |
| `proxmox_vm_serial_socket` | bool | нет | `true` | Сокет последовательной консоли. |
| `proxmox_vm_agent_enabled` | bool | нет | `true` | Канал QEMU guest agent. |
| `proxmox_vm_onboot` | bool | нет | `true` | Старт при загрузке ноды. |
| `proxmox_vm_start` | bool | нет | `true` | Старт после создания. |
| `proxmox_vm_description` | string | нет | `""` | Заметки VM при создании. |
| `proxmox_vm_debug_mode` | bool | нет | `false` | Debug-вывод после изменений. |

## Пример

```yaml
- name: Provision the Home Assistant VM
  hosts: pve-main
  become: true
  roles:
    - role: proxmox_vm
      vars:
        proxmox_vm_target_host: homeassistant
        proxmox_vm_image_url: "https://example/haos_ova-18.4.qcow2.xz"
        proxmox_vm_disk_size: "64G"
```

## Handlers и теги

Handlers нет. Итоговая задача несёт тег `debug`.

## Check mode

Команды `qm` идут через `ansible.builtin.command` и в check mode пропускаются;
роль ведёт себя как dry-run и сообщает `WOULD CHANGE` в итоге. Читающие проверки
(`qm status`, `qm config`, `stat`) выполняются обычно.
