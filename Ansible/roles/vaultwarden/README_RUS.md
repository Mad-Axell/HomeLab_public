# vaultwarden

Роль разворачивает Vaultwarden — реализацию API Bitwarden на Rust — как проект
Docker Compose v2 на целевом хосте с уже установленным Docker и приводит
контейнер к требуемому состоянию.

Выбран контейнер, а не бинарная установка: у Vaultwarden нет пакета в Debian, а
сборка из исходников требует полной цепочки Rust, которая в LXC тяжелее самого
сервиса. Образ `vaultwarden/server` — поддерживаемый upstream-путь
развертывания с одним постоянным томом `/data`, поэтому он даёт меньше
подвижных частей при той же функциональности.

## Что делает

- Проверяет платформу Debian и структуру входов ранним
  `ansible.builtin.assert`, затем отдельной задачей под `no_log` проверяет, что
  переменная, названная в `vaultwarden_admin_token_var`, существует в
  `VARS/secrets.yml` - обе проверки до первого изменения.
- Создает каталог проекта Compose и каталог постоянных данных
  `vaultwarden_data_dir` (база SQLite, вложения, sends, кэш иконок).
- Генерирует `compose.yml` из шаблона: образ, имя контейнера, публикация порта,
  bind-монтирование данных, `ADMIN_TOKEN` из именованного секрета,
  `SIGNUPS_ALLOWED`, опциональный `DOMAIN` и произвольные
  `vaultwarden_extra_env`. Файл содержит токен, поэтому задача работает с
  `no_log: true` и `diff: false`.
- Приводит проект к состоянию `vaultwarden_state` через
  `community.docker.docker_compose_v2`. При изменении `compose.yml` модуль
  пересоздает контейнер автоматически, поэтому handler для restart не
  используется.
- Не создает организации, коллекции и учетные записи пользователей: они
  заводятся в веб-интерфейсе или через админ-панель и выходят за рамки роли.

## Требования

- Целевая ОС: Debian 13 (LXC).
- Docker Engine и Compose v2 plugin на целевом хосте; их ставит роль `docker`,
  роль `vaultwarden` Docker не устанавливает.
- `become: true` для создания каталогов и работы с Docker.
- Коллекция `community.docker`, зафиксированная в project-level
  `requirements.yml`.
- Подключенный playbook'ом `VARS/secrets.yml` с переменной, названной в
  `vaultwarden_admin_token_var`.

## Изменяемые ресурсы

- Packages: none.
- Files: `compose.yml` в `vaultwarden_project_directory`, каталог данных
  `vaultwarden_data_dir`.
- Services: контейнер Vaultwarden через Docker Compose.
- Users/groups: none.
- Firewall/API objects: публикуемый контейнером порт `vaultwarden_port`.

## Переменные

| Variable | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `vaultwarden_debug_mode` | boolean | no | `false` | Включает debug-вывод после значимых изменений. |
| `vaultwarden_state` | string | no | `"present"` | Требуемое состояние проекта Compose: `present` или `absent`. |
| `vaultwarden_project_directory` | string | no | `"/opt/vaultwarden"` | Каталог проекта Compose с `compose.yml`. |
| `vaultwarden_data_dir` | string | no | `"/opt/vaultwarden/data"` | Каталог хоста, монтируемый в контейнер как `/data`. |
| `vaultwarden_image` | string | no | `"vaultwarden/server:latest"` | Образ контейнера Vaultwarden. |
| `vaultwarden_container_name` | string | no | `"vaultwarden"` | Имя контейнера Vaultwarden. |
| `vaultwarden_port` | integer | no | `8222` | Порт хоста, публикующий веб-интерфейс (внутри контейнера порт 80). |
| `vaultwarden_admin_token_var` | string | yes | `null` | Имя переменной из `VARS/secrets.yml` с токеном админ-панели. |
| `vaultwarden_domain` | string | no | `null` | Публичный URL инстанса; при null переменная `DOMAIN` не задаётся. |
| `vaultwarden_signups_allowed` | boolean | no | `false` | Разрешить открытую саморегистрацию пользователей. |
| `vaultwarden_extra_env` | dict | no | `{}` | Дополнительные переменные окружения контейнера (например `SMTP_*`). |

## Секреты (VARS/secrets.yml)

| Variable | Required | Description |
| --- | --- | --- |
| Переменная, названная в `vaultwarden_admin_token_var` (например `vault_vaultwarden_admin_token`) | yes | Токен админ-панели `/admin`. Значение читается из `VARS/secrets.yml` во время прогона и попадает только в `compose.yml`; задача рендера использует `no_log: true` и `diff: false`. |

## Использование

```yaml
---
- name: Deploy Vaultwarden
  hosts: vaultwarden
  become: true
  vars_files:
    - ../VARS/secrets.yml
  roles:
    - role: docker
    - role: vaultwarden
      vars:
        vaultwarden_admin_token_var: "vault_vaultwarden_admin_token"
        vaultwarden_domain: "https://vaultwarden.dragons-nest.home.arpa"
        vaultwarden_port: 8222
```

## Check mode и diff mode

Роль поддерживает запуск:

```bash
ansible-playbook playbook.yml --check --diff
```

`ansible.builtin.file` корректно показывает изменения. Задача рендера
`compose.yml` использует `no_log: true` и `diff: false` из-за токена, поэтому
ее diff скрыт намеренно. `community.docker.docker_compose_v2` поддерживает
check mode частично: достоверность прогнозируемых изменений зависит от Docker
daemon, поэтому итог check-прогона для задачи развертывания следует считать
оценкой.

## Зависимости

- Коллекция `community.docker` (project-level `requirements.yml`).
- Роль `docker` как предусловие на уровне playbook; `meta`-зависимость не
  используется, порядок ролей задает playbook.
- `VARS/secrets.yml` с секретом, названным в `vaultwarden_admin_token_var`.

## Примечания

- `ADMIN_TOKEN` открывает админ-панель `/admin`: управление пользователями,
  приглашениями и общими настройками. Vaultwarden рекомендует Argon2-хэш токена;
  роль передает значение как есть - формат выбирает подаваемый секрет.
- `vaultwarden_domain` нужен для корректной работы WebAuthn/passkey и ссылок
  приглашений; без него вход по passkey не работает.
- `vaultwarden_extra_env` принимает любые переменные окружения, например
  `SMTP_HOST`/`SMTP_FROM` для почты приглашений; секретные значения передавайте
  через секреты приватного репозитория - содержимое `compose.yml` не
  логируется.
- Повторный прогон идемпотентен: проект, уже находящийся в требуемом
  состоянии, не дает изменений.
- Состояние `absent` останавливает и удаляет контейнеры проекта, но файлы
  `compose.yml` и данные на диске сохраняются.
