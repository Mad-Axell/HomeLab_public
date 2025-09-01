# HomeLab Ansible Roles

Репозиторий для хранения ролей Ansible, предназначенных для настройки и автоматизации домашней лаборатории.

## 📋 Описание

Этот проект содержит набор ролей Ansible для автоматизации настройки различных компонентов домашней лаборатории. Роли разработаны с учетом лучших практик безопасности и автоматизации.

## 🏗️ Структура проекта

```
HomeLab_public/
├── Ansible/
│   └── roles/
│       └── base/
│           └── security/
│               ├── defaults/
│               │   └── main.yaml
│               ├── tasks/
│               │   ├── access_rights_to_file_system_objects.yaml
│               │   ├── harden_os.yaml
│               │   ├── linux-kernel_protection.yaml
│               │   ├── main.yaml
│               │   ├── reducing_the_attack_perimeter.yaml
│               │   └── user_space_protection.yaml
└── README.md
```

## 🔒 Доступные роли

### Base Security Role
Роль для базовой настройки безопасности операционной системы:

- **Доступ к файловой системе** - управление правами доступа к файлам и директориям
- **Защита ОС** - общие меры по защите операционной системы
- **Защита ядра Linux** - настройка параметров безопасности ядра
- **Сокращение атакуемой поверхности** - отключение ненужных сервисов и функций
- **Защита пользовательского пространства** - настройка пользовательских ограничений

## 🚀 Быстрый старт

### Предварительные требования

- Ansible 2.9+
- Python 3.6+
- Доступ к целевым хостам по SSH

### Установка

1. Клонируйте репозиторий:
```bash
git clone https://github.com/your-username/HomeLab_public.git
cd HomeLab_public
```

2. Создайте inventory файл с вашими хостами:
```ini
[homelab]
server1 ansible_host=192.168.1.100
server2 ansible_host=192.168.1.101
```

3. Создайте playbook для применения ролей:
```yaml
---
- name: Apply security hardening
  hosts: homelab
  become: yes
  
  roles:
    - base/security
```

4. Запустите playbook:
```bash
ansible-playbook -i inventory playbook.yml
```

## ⚙️ Настройка

### Переменные роли security

Роль использует переменные по умолчанию, которые можно переопределить в вашем playbook:

```yaml
---
- name: Custom security settings
  hosts: homelab
  become: yes
  
  vars:
    # Переопределение переменных по умолчанию
    security_ssh_port: 2222
    security_firewall_enabled: true
  
  roles:
    - base/security
```

## 📚 Документация

Подробная документация по каждой роли находится в соответствующих директориях:
- `Ansible/roles/base/security/README.md` - документация по роли безопасности

## 🤝 Вклад в проект

Мы приветствуем вклад в развитие проекта! Для этого:

1. Создайте fork репозитория
2. Создайте feature branch
3. Внесите изменения
4. Создайте Pull Request

## 📄 Лицензия

Этот проект распространяется под лицензией MIT.

## 📞 Поддержка

Если у вас есть вопросы или предложения:
- Создайте Issue в GitHub
- Свяжитесь с авторами проекта

## 🔄 Версии

- **v1.0.0** - Базовая роль безопасности

---
