# apt_local_mirror

Роль копирует готовое дерево APT-репозитория с Ansible-контроллера на целевой
хост. Она нужна там, где хост не может достучаться до апстрим-репозитория:
недоступный источник, изолированный сегмент или блокировка по географии.

## Что делает

- Проверяет, что источник и каталог назначения заданы.
- Создаёт каталог назначения.
- Копирует дерево репозитория побайтово.

Роль ничего не подписывает и не пересобирает индексы: файлы переносятся как
есть, поэтому исходные подписи апстрима остаются валидными и APT проверяет их
обычным образом. Роль также не подключает репозиторий — это делает та роль,
которая объявляет источник APT, получая `file://`-URI.

## Требования

- Дерево репозитория заранее лежит на контроллере по пути
  `apt_local_mirror_src` и содержит `dists/` и `pool/`.
- `become: true` на целевом хосте.

## Изменяемые ресурсы

- Files: каталог `apt_local_mirror_dest` и всё скопированное в него дерево.
- Packages: none.
- Services: none.
- Users/groups: none.

## Переменные

| Variable | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `apt_local_mirror_src` | string | yes | `null` | Каталог зеркала на контроллере; завершающий слэш копирует содержимое, а не сам каталог. |
| `apt_local_mirror_dest` | string | no | `"/opt/apt-local-mirror"` | Каталог назначения на целевом хосте. |
| `apt_local_mirror_owner` | string | no | `"root"` | Владелец дерева. |
| `apt_local_mirror_group` | string | no | `"root"` | Группа дерева. |
| `apt_local_mirror_directory_mode` | string | no | `"0755"` | Права каталогов. |
| `apt_local_mirror_file_mode` | string | no | `"0644"` | Права файлов. |
| `apt_local_mirror_debug_mode` | boolean | no | `false` | Показывает факт изменения. |

## Секретные внешние входы

Роль не использует секретов и не читает `VARS/secrets.yml`.

## Использование

```yaml
---
- name: Deliver a local APT mirror
  hosts: offline_host
  become: true
  roles:
    - role: apt_local_mirror
      vars:
        apt_local_mirror_src: "/home/ansible/mirrors/vendor/"
        apt_local_mirror_dest: "/opt/vendor-mirror"
```

Затем репозиторий подключается обычным образом, например
`deb [signed-by=/opt/vendor-mirror/vendor.gpg] file:///opt/vendor-mirror/debian <suite> <component>`.

## Check mode и diff mode

`file` и `copy` поддерживают `--check --diff` штатно. Для крупных деревьев diff
шумный: `copy` сравнивает каждый файл по контрольной сумме.

## Зависимости

- None

## Handlers и tags

- Handlers: отсутствуют.
- Tags: `debug` на итоговой debug-задаче.
