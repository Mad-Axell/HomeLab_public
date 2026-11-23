# proxmox_vm

Creates a KVM virtual machine on the Proxmox node the role runs on: downloads a
qcow2 (or `.qcow2.xz`) appliance image, imports it as the VM disk and reconciles
the basic compute parameters. Used for appliance guests like Home Assistant OS.

Создаёт KVM-виртуальную машину на ноде Proxmox, где запущена роль: скачивает
образ qcow2 (или `.qcow2.xz`), импортирует его как диск VM и сверяет базовые
вычислительные параметры. Применяется для appliance-гостей вроде Home Assistant OS.

- [English documentation](README_ENG.md)
- [Русская документация](README_RUS.md)
