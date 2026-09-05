# proxmox_lxc

Роль управляет одним Proxmox LXC через `community.proxmox.proxmox` и больше не
перезаписывает целиком `/etc/pve/lxc/<vmid>.conf`.

Обязательные параметры:

- `proxmox_lxc_target_host` — имя LXC в inventory;
- `proxmox_lxc_api_user` и `proxmox_lxc_api_password`;
- `proxmox_lxc_ostemplate` — шаблон ОС в хранилище Proxmox; не требуется, если
  включена загрузка шаблона из каталога.

## Загрузка шаблона из каталога appliance

При `proxmox_lxc_template_download: true` роль сама находит и загружает новейший
шаблон указанной ОС, а `proxmox_lxc_ostemplate` можно не задавать: он
переопределяется найденным volid вида `<storage>:vztmpl/<файл>`.

| Variable | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `proxmox_lxc_template_download` | boolean | no | `false` | Включает поиск и загрузку шаблона. |
| `proxmox_lxc_template_os` | string | при включённой загрузке | `null` | Префикс имени ОС в каталоге, например `debian-13`. |
| `proxmox_lxc_template_storage` | string | no | `"local"` | Хранилище для шаблона. |
| `proxmox_lxc_template_section` | string | no | `"system"` | Раздел каталога appliance. |
| `proxmox_lxc_template_arch` | string | no | `"amd64"` | Архитектура для фильтрации записей каталога. |
| `proxmox_lxc_template_timeout` | integer | no | `600` | Секунды на загрузку шаблона. |

Каталог читается командой `pveam` на самом узле Proxmox (`pveam update`, затем
`pveam available --section <раздел>`); обе задачи не меняют состояние и помечены
`changed_when: false`. Из записей отбираются подходящие ОС и архитектура, версии
сортируются фильтром `community.general.version_sort`, берётся наибольшая. Сама
загрузка выполняется идемпотентным модулем `community.proxmox.proxmox_template`:
если шаблон уже лежит в хранилище, задача возвращает `ok`.

Если каталог не предлагает ни одной записи для `proxmox_lxc_template_os`, роль
останавливается на общем `assert` до создания контейнера.

## Зависимости

- `community.proxmox` — модули `proxmox` и `proxmox_template`;
- `community.general` — фильтр `version_sort`, нужен только при включённой
  загрузке шаблона.

В inventory целевого объекта требуются `proxmox.node`, `proxmox.type`,
`proxmox.vmid`, `ansible_host` и объект `network` из `hosts.yml`. Роль запускается
на узле Proxmox, которому принадлежит контейнер. Сам API-модуль делегируется на
Ansible-контроллер, где нужны `proxmoxer >= 2.0` и `requests`.
Если inventory-алиас отличается от реального имени узла в Proxmox API, укажите
реальное имя в `proxmox.api_node` у объекта гипервизора.

> **`proxmox_lxc_cpus` — это не количество ядер** (ядра — `proxmox_lxc_cores`)
> и по умолчанию `null`. Задавать ему значение не следует.
>
> В `community.proxmox` 1.6.0 этот параметр отображается на **две разные**
> настройки Proxmox в зависимости от ветки кода:
>
> | Ветка | Строка `proxmox.py` | Во что превращается |
> |---|---|---|
> | Создание LXC | 1194 | `kwargs["cpuunits"] = kwargs.pop("cpus")` |
> | Обновление | 1051 | `kwargs["cpulimit"] = kwargs.pop("cpus")` |
>
> Роль передаёт и `cpuunits`, поэтому **при создании `cpus` его затирает**.
> С прежним дефолтом `0` каждый новый контейнер получал `cpuunits: 0`, что
> запрещено в cgroup v2 (`cpu.weight` — от 1 до 10000): контейнер создавался,
> но не стартовал, а `pct start` уходил в таймаут с
> `cgfsng_setup_limits: Numerical result out of range`.
>
> Одно значение не может одновременно означать и `cpulimit`, и `cpuunits`,
> поэтому роль `cpulimit` не управляет. Вес CPU задаётся через
> `proxmox_lxc_cpuunits`.

`proxmox_lxc_mount_volumes` задаёт полный список точек монтирования Proxmox.
`proxmox_lxc_extra_config_lines` используется только для параметров, которых нет
в API-модуле. Модуль Proxmox не поддерживает check mode, поэтому при `--check`
API-задачи пропускаются; syntax-check и lint доступны полностью.
