# pfsense_config

Роль управляет полным XML-файлом конфигурации pfSense как одной транзакцией.
По умолчанию она только проверяет кандидат и показывает наличие расхождений;
рабочий `/conf/config.xml` не изменяется.

## Порядок работы

1. Получает XML из одного источника: `pfsense_config_source_file` на контроллере
   или `pfsense_config_xml`/`vault_pfsense_config_xml`.
2. Проверяет структуру XML и наличие версии конфигурации.
3. Прогоняет кандидат через штатный `pfSsh.php playback upgradeconfig`.
4. Сравнивает адрес management-интерфейса и блокирует его случайное изменение.
5. Сравнивает SHA-256 рабочего и подготовленного файлов.
6. В режиме применения сохраняет предыдущую конфигурацию на pfSense и на
   Ansible-контроллере, устанавливает boot-watchdog и только затем заменяет XML.
7. Перезагружает pfSense и проверяет новый boot, XML, контрольную сумму, SSH и
   WebGUI. При ошибке восстанавливает резервную копию. Если узел недоступен,
   boot-watchdog выполняет отложенный откат и повторную перезагрузку.

Одновременно может выполняться только одна транзакция. Наличие оставшегося
watchdog блокирует новый запуск до ручной проверки предыдущей операции.

## Основные переменные

| Переменная | По умолчанию | Назначение |
| --- | --- | --- |
| `pfsense_config_source_file` | `""` | Путь к полному `config.xml` на Ansible-контроллере. |
| `pfsense_config_xml` | `vault_pfsense_config_xml` или `""` | Полное содержимое XML. Нельзя задавать вместе с source file. |
| `pfsense_config_apply` | `false` | Разрешает изменение рабочей конфигурации. |
| `pfsense_config_apply_confirmation` | `""` | Для применения должно быть `APPLY_PFSENSE_CONFIG`. |
| `pfsense_config_management_interface` | `lan` | Логический интерфейс pfSense, через который идёт управление. |
| `pfsense_config_allow_management_change` | `false` | Разрешает кандидату изменить management-адрес. |
| `pfsense_config_management_change_confirmation` | `""` | При разрешённой смене адреса должно быть `CHANGE_PFSENSE_MANAGEMENT_ADDRESS`. |
| `pfsense_config_healthcheck_ports` | `[22, 443]` | TCP-порты, проверяемые после перезагрузки. |
| `pfsense_config_rollback_timeout` | `600` | Время до автономного отката watchdog, секунд. |
| `pfsense_config_local_backup_dir` | `~/.ansible/backups/pfsense` | Каталог резервных копий на контроллере. |
| `pfsense_config_debug_mode` | `false` | Выводит итог без содержимого XML. |

## Запуск playbook

Проверка и сравнение без изменения рабочей конфигурации:

```shell
ansible-playbook playbooks/pfsense-config.yml \
  -e pfsense_config_source_file=/secure/path/config.xml
```

Применение проверенного кандидата:

```shell
ansible-playbook playbooks/pfsense-config.yml \
  -e pfsense_config_source_file=/secure/path/config.xml \
  -e pfsense_config_apply=true \
  -e pfsense_config_apply_confirmation=APPLY_PFSENSE_CONFIG
```

Смена management-адреса — отдельная операция в сервисное окно. Помимо обычного
подтверждения применения, она требует двух дополнительных переменных:

```shell
-e pfsense_config_allow_management_change=true \
-e pfsense_config_management_change_confirmation=CHANGE_PFSENSE_MANAGEMENT_ADDRESS
```

## Требования и ограничения

- Доступ `become: true` и Python на pfSense.
- На pfSense должны быть доступны PHP и `/usr/local/sbin/pfSsh.php`.
- XML всегда обрабатывается с `no_log: true` и `diff: false`.
- Роль применяет полный XML и не редактирует firewall, DHCP или VLAN по частям.
- Для первого рабочего запуска необходима утверждённая полная конфигурация и
  окно обслуживания с доступом к консоли pfSense.

## Check mode

Обычный запуск уже является validation-only. `--check` также никогда не доходит
до блока применения, но создаёт и удаляет временные файлы кандидата на pfSense,
поскольку без этого невозможно выполнить штатную проверку формата и версии.
