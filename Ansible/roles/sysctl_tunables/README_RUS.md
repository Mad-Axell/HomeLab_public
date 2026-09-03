# sysctl_tunables

Роль управляет произвольным набором параметров ядра: сохраняет их в один файл
под `/etc/sysctl.d` и применяет к работающей системе.

## Что делает

- Проверяет, что у каждого объявленного параметра есть `name` и `value`.
- Записывает параметры в `sysctl_tunables_file` и применяет их.

Роль не знает про конкретные параметры и ничего не задаёт по умолчанию: пустой
`sysctl_tunables_settings` является допустимым состоянием и означает, что
управлять нечем.

## Требования

- `become: true`.
- Коллекция `ansible.posix`.
- Работающий контейнер должен иметь право менять указанные параметры. В
  unprivileged LXC часть параметров ядра доступна только на чтение, и такая
  задача завершится ошибкой — это ограничение среды, а не роли.

## Изменяемые ресурсы

- Files: `sysctl_tunables_file`.
- Прочее: значения параметров ядра в работающей системе.
- Packages, Services, Users/groups: none.

## Переменные

| Variable | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `sysctl_tunables_settings` | list | no | `[]` | Список словарей с `name` и `value`; пустой список допустим. |
| `sysctl_tunables_file` | string | no | `"/etc/sysctl.d/99-ansible-tunables.conf"` | Файл хранения параметров. |
| `sysctl_tunables_reload` | boolean | no | `true` | Применять значения немедленно. |
| `sysctl_tunables_debug_mode` | boolean | no | `false` | Показывает изменившиеся параметры. |

## Секретные внешние входы

Роль не использует секретов и не читает `VARS/secrets.yml`.

## Использование

```yaml
---
- name: Disable IPv6
  hosts: all
  become: true
  roles:
    - role: sysctl_tunables
      vars:
        sysctl_tunables_file: "/etc/sysctl.d/99-disable-ipv6.conf"
        sysctl_tunables_settings:
          - name: "net.ipv6.conf.all.disable_ipv6"
            value: 1
          - name: "net.ipv6.conf.default.disable_ipv6"
            value: 1
```

## Check mode и diff mode

`ansible.posix.sysctl` поддерживает `--check --diff` и показывает изменение
файла естественным образом.

## Зависимости

- `ansible.posix`

## Handlers и tags

- Handlers: отсутствуют.
- Tags: `debug` на итоговой debug-задаче.
