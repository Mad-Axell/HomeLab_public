# proxmox_lxc

Роль управляет одним Proxmox LXC через `community.proxmox.proxmox` и больше не
перезаписывает целиком `/etc/pve/lxc/<vmid>.conf`.

Обязательные параметры:

- `proxmox_lxc_target_host` — имя LXC в inventory;
- `proxmox_lxc_api_user` и `proxmox_lxc_api_password`;
- `proxmox_lxc_ostemplate` — шаблон ОС в хранилище Proxmox.

В inventory целевого объекта требуются `proxmox.node`, `proxmox.type`,
`proxmox.vmid`, `ansible_host` и объект `network` из `hosts.yml`. Роль запускается
на узле Proxmox, которому принадлежит контейнер. Сам API-модуль делегируется на
Ansible-контроллер, где нужны `proxmoxer >= 2.0` и `requests`.
Если inventory-алиас отличается от реального имени узла в Proxmox API, укажите
реальное имя в `proxmox.api_node` у объекта гипервизора.

`proxmox_lxc_mount_volumes` задаёт полный список точек монтирования Proxmox.
`proxmox_lxc_extra_config_lines` используется только для параметров, которых нет
в API-модуле. Модуль Proxmox не поддерживает check mode, поэтому при `--check`
API-задачи пропускаются; syntax-check и lint доступны полностью.
