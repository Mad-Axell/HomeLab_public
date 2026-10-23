# yandex_rclone

## Русский

Роль поднимает одностороннее зеркало Яндекс.Диска через `rclone`: монтирует
SMB-шару как целевой каталог, ставит upstream-пакет rclone, пишет конфиг с
OAuth-приложением лаборатории и включает `systemd` таймер, запускающий прогон
`rclone sync` по расписанию.

Полная документация: [README_RUS.md](README_RUS.md)

## English

This role sets up a one-way Yandex Disk mirror via `rclone`: it mounts an SMB
share as the target directory, installs the upstream rclone package, writes
the lab OAuth application configuration and enables a `systemd` timer that
runs a `rclone sync` pass on a schedule.

Full documentation: [README_ENG.md](README_ENG.md)
