# pfsense_config

## Русский

Проверяет и, только после явного подтверждения, применяет полный `config.xml`
pfSense. Перед применением создаёт две резервные копии, перезагружает firewall,
проверяет доступность управления и автоматически откатывает неуспешную транзакцию.

Полная документация: [README_RUS.md](README_RUS.md)

## English

Validates and, only after explicit confirmation, applies a complete pfSense
`config.xml`. Before applying, it creates two backups, reboots the firewall,
checks management health, and automatically rolls back a failed transaction.

Full documentation: [README_ENG.md](README_ENG.md)
