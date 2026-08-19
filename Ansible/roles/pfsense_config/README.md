# pfsense_config

## Русский

Проверяет и, только после явного подтверждения, применяет полный `config.xml`
pfSense. Перед применением создаёт две резервные копии, перезагружает firewall,
проверяет доступность управления и автоматически откатывает неуспешную транзакцию.

Полная документация: [readme_rus.md](readme_rus.md)

## English

Validates and, only after explicit confirmation, applies a complete pfSense
`config.xml`. Before applying, it creates two backups, reboots the firewall,
checks management health, and automatically rolls back a failed transaction.

Full documentation: [readme_eng.md](readme_eng.md)
