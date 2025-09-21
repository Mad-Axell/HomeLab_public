#!/bin/bash

# =============================================================
# Скрипт автоматизации создания Proxmox CT для Ansible и HomeLab
# =============================================================

# Переменные для создания Proxmox CT
# ================================================

# Основные параметры контейнера
CONTAINER_NAME="ansible-ct"
CONTAINER_ID="200"
CONTAINER_OS="debian"              # Предпочтительная ОС, но не обязательная
CONTAINER_VERSION=""               # Оставляем пустым для поиска самой свежей версии
CONTAINER_ARCH="amd64"

# Ресурсы контейнера
CONTAINER_CORES="2"
CONTAINER_MEMORY="2048"
CONTAINER_SWAP="512"
CONTAINER_DISK_SIZE="20"  # размер диска в GB
CONTAINER_DISK_STORAGE="local-lvm"

# Сетевые настройки
CONTAINER_NETWORK="vmbr0"
CONTAINER_IP="**.**.**.**/24"
CONTAINER_GATEWAY="**.**.**.**"
CONTAINER_DNS="8.8.8.8 8.8.4.4"

# SSH настройки
SSH_PORT="22"
SSH_USER="SSH_USER"
SSH_PASSWORD="SSH_PASSWORD"

# Пути и директории
TEMPLATE_DIR="/var/lib/vz/template/cache"

# Git репозитории
PUBLIC_GIT_DIR="HomeLab_public"
PRIVATE_GIT_DIR="HomeLab_private"
GIT_REPO_USER="********"
# Токен для доступа к приватному репозиторию (Personal Access Token)
GIT_REPO_TOKEN="**********"

GIT_REPO_PUBLIC="https://github.com/$GIT_REPO_USER/$PUBLIC_GIT_DIR.git"
GIT_REPO_PRIVATE="https://$GIT_REPO_TOKEN@github.com/$GIT_REPO_USER/$PRIVATE_GIT_DIR.git"


# Пути к директориям в контейнере
AUTOMATE_DIR="/etc/automate"
ANSIBLE_DIR="/etc/ansible"

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Функции для вывода
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Проверка переменных окружения
check_variables() {
    print_info "Проверка переменных окружения..."
    
    if [ -z "$CONTAINER_NAME" ]; then
        print_error "CONTAINER_NAME не установлен"
        return 1
    fi
    
    if [ -z "$CONTAINER_ID" ]; then
        print_error "CONTAINER_ID не установлен"
        return 1
    fi
    
    if [ -z "$CONTAINER_ARCH" ]; then
        print_error "CONTAINER_ARCH не установлен"
        return 1
    fi
    
    if [ -z "$SSH_USER" ]; then
        print_error "SSH_USER не установлен"
        return 1
    fi
    
    if [ -z "$SSH_PASSWORD" ]; then
        print_error "SSH_PASSWORD не установлен"
        return 1
    fi
    
    if [ -z "$GIT_REPO_TOKEN" ]; then
        print_error "GIT_REPO_TOKEN не установлен"
        return 1
    fi
    
    print_success "Все переменные установлены корректно"
    return 0
}

# Функция очистки консоли
clear_screen() {
    clear
    echo "=========================================="
    echo "  Настройка контейнера Proxmox LXC"
    echo "=========================================="
    echo
}

# Функция проверки прав root
check_root() {
    print_info "Проверка прав доступа..."
    
    if [[ $EUID -ne 0 ]]; then
        print_error "Этот скрипт должен быть запущен с правами root"
        echo "Используйте: sudo $0"
        exit 1
    fi
    
    print_success "Права root подтверждены"
}

# Функция проверки Proxmox
check_proxmox() {
    print_info "Проверка окружения Proxmox..."
    
    # Проверка наличия pveversion
    if ! command -v pveversion &> /dev/null; then
        print_error "pveversion не найден. Возможно, это не Proxmox сервер"
        exit 1
    fi
    
    # Проверка версии Proxmox
    PVE_VERSION=$(pveversion -v | grep "pve-manager" | awk '{print $2}')
    if [ -n "$PVE_VERSION" ]; then
        print_success "Proxmox версии: $PVE_VERSION"
    else
        print_warning "Не удалось определить версию Proxmox"
    fi
    
    # Проверка статуса PVE кластера
    if systemctl is-active --quiet pve-cluster; then
        print_success "PVE кластер активен"
    else
        print_warning "PVE кластер не активен"
    fi
}

# Функция проверки LXC
check_lxc() {
    print_info "Проверка LXC окружения..."
    
    # Проверка наличия lxc-create
    if ! command -v lxc-create &> /dev/null; then
        print_error "LXC не установлен"
        exit 1
    fi
    
    # Проверка версии LXC
    LXC_VERSION=$(lxc-create --version)
    print_success "LXC версии: $LXC_VERSION"
    
    # Проверка статуса LXC
    if systemctl is-active --quiet lxc; then
        print_success "LXC сервис активен"
    else
        print_warning "LXC сервис не активен"
    fi
}

# Функция обновления списка шаблонов
update_templates() {
    print_info "Обновление списка доступных шаблонов..."
    
    # Обновление списка шаблонов
    if pveam update; then
        print_success "Список шаблонов обновлен"
    else
        print_error "Не удалось обновить список шаблонов"
        return 1
    fi
    
    # Ожидание завершения обновления
    sleep 2
}

# Функция поиска самого свежего OS Template
find_latest_os_template() {
    print_info "Поиск самого свежего доступного OS Template  --  $CONTAINER_OS"
    
    # Показать все доступные шаблоны для понимания доступности
    print_info "Все доступные шаблоны в репозитории:"
    pveam available | grep -i "system" | grep -i "$CONTAINER_OS" | head -20 
    
    
    # Поиск самого свежего шаблона для предпочтительной ОС
    if [ -n "$CONTAINER_OS" ]; then
        print_info "Поиск самого свежего шаблона для $CONTAINER_OS..."
        
        # Поиск по предпочтительной ОС и архитектуре с максимальным числом версии
        # sort -V сортирует по версии, tail -1 берет последний (максимальный)
        LATEST_TEMPLATE=$(pveam available | grep -i "system" | grep -i "$CONTAINER_OS" | grep -i "$CONTAINER_ARCH" | sort -V | tail -1 | awk '{print $2}')
        
        if [ -n "$LATEST_TEMPLATE" ]; then
            print_success "Найден шаблон для $CONTAINER_OS: $LATEST_TEMPLATE"
            TEMPLATE_NAME="$LATEST_TEMPLATE"
            DETECTED_OS="$CONTAINER_OS"
            return 0
        else
            print_warning "Не найден шаблон для $CONTAINER_OS, ищем альтернативы..."
        fi
    fi
    
    # Если ничего не найдено, берем первый доступный шаблон
    print_warning "Не найдены шаблоны популярных ОС, берем первый доступный..."
    
    FIRST_TEMPLATE=$(pveam available | grep -i "system" | grep -i "$CONTAINER_ARCH" | sort -V | tail -1 | awk '{print $2}')
    
    if [ -n "$FIRST_TEMPLATE" ]; then
        print_success "Выбран шаблон: $FIRST_TEMPLATE"
        TEMPLATE_NAME="$FIRST_TEMPLATE"
        
        # Определяем ОС из имени шаблона
        DETECTED_OS=$(echo "$FIRST_TEMPLATE" | sed 's/-.*//' | tr '[:upper:]' '[:lower:]')
        CONTAINER_OS="$DETECTED_OS"
        
        return 0
    else
        print_error "Не найдено ни одного подходящего шаблона"
        return 1
    fi
}

# Функция проверки локального шаблона
check_local_template() {
    if [ -z "$TEMPLATE_NAME" ]; then
        print_error "TEMPLATE_NAME не установлен"
        return 1
    fi
    
    print_info "Проверка локального наличия шаблона: $TEMPLATE_NAME"
    
    # Проверка наличия в локальном хранилище
    if pveam list local | grep -q "$TEMPLATE_NAME"; then
        print_success "Шаблон $TEMPLATE_NAME уже загружен локально"
        return 0
    else
        print_warning "Шаблон $TEMPLATE_NAME не найден локально"
        return 1
    fi
}

# Функция скачивания OS Template
download_template() {
    if [ -z "$TEMPLATE_NAME" ]; then
        print_error "TEMPLATE_NAME не установлен"
        return 1
    fi
    
    print_info "=== Скачивание Template ==="
    
    # Проверка локального наличия шаблона
    print_info "Проверка локального наличия шаблона: $TEMPLATE_NAME"
    
    if pveam list local | grep -q "$TEMPLATE_NAME"; then
        print_success "Шаблон $TEMPLATE_NAME уже загружен локально"
        return 0
    else
        print_warning "Шаблон $TEMPLATE_NAME не найден локально, начинаем скачивание..."
        
        # Скачивание шаблона
        print_info "Скачивание шаблона $TEMPLATE_NAME..."
        
        if pveam download local "$TEMPLATE_NAME"; then
            print_success "Шаблон $TEMPLATE_NAME успешно скачан"
            
            # Проверяем, что шаблон действительно появился локально
            if pveam list local | grep -q "$TEMPLATE_NAME"; then
                print_success "Шаблон $TEMPLATE_NAME подтвержден в локальном хранилище"
                return 0
            else
                print_error "Шаблон не появился в локальном хранилище после скачивания"
                return 1
            fi
        else
            print_error "Не удалось скачать шаблон $TEMPLATE_NAME"
            return 1
        fi
    fi
}

# Функция создания контейнера
create_container() {
    print_info "=== Создание контейнера ==="
    
    print_info "Создание контейнера $CONTAINER_NAME с ID $CONTAINER_ID..."
    
    # Показываем доступные локальные шаблоны
    print_info "Доступные локальные шаблоны:"
    pveam list local | head -10
    
    # Получаем полный путь к шаблону в локальном хранилище
    local template_path=$(pveam list local | grep "$TEMPLATE_NAME" | awk '{print $1}')
    
    if [ -z "$template_path" ]; then
        print_error "Не удалось найти путь к шаблону $TEMPLATE_NAME в локальном хранилище"
        print_info "Попробуйте найти похожие шаблоны:"
        pveam list local | grep -i "$CONTAINER_OS" | head -5
        return 1
    fi
    
    # Отладочная информация
    print_info "Параметры создания:"
    echo "  ID: $CONTAINER_ID"
    echo "  Шаблон: $TEMPLATE_NAME"
    echo "  Путь к шаблону: $template_path"
    echo "  Имя: $CONTAINER_NAME"
    echo "  Ядра: $CONTAINER_CORES"
    echo "  RAM: $CONTAINER_MEMORY MB"
    echo "  Swap: $CONTAINER_SWAP MB"
    echo "  Диск: $CONTAINER_DISK_STORAGE:$CONTAINER_DISK_SIZE"
    echo "  Сеть: $CONTAINER_NETWORK"
    echo "  IP: $CONTAINER_IP"
    echo "  Шлюз: $CONTAINER_GATEWAY"
    echo
    
    # Создание контейнера с правильным путем к шаблону
    if pct create "$CONTAINER_ID" "$template_path" \
        --hostname "$CONTAINER_NAME" \
        --cores "$CONTAINER_CORES" \
        --memory "$CONTAINER_MEMORY" \
        --swap "$CONTAINER_SWAP" \
        --rootfs "$CONTAINER_DISK_STORAGE:$CONTAINER_DISK_SIZE" \
        --net0 "name=eth0,bridge=$CONTAINER_NETWORK,ip=$CONTAINER_IP,gw=$CONTAINER_GATEWAY"; then
        
        print_success "Контейнер $CONTAINER_NAME успешно создан"
        return 0
    else
        print_error "Не удалось создать контейнер $CONTAINER_NAME"
        return 1
    fi
}

# Функция запуска контейнера
start_container() {
    print_info "=== Запуск контейнера ==="
    
    print_info "Запуск контейнера $CONTAINER_NAME..."
    
    if pct start "$CONTAINER_ID"; then
        print_success "Контейнер $CONTAINER_NAME успешно запущен"
        return 0
    else
        print_error "Не удалось запустить контейнер $CONTAINER_NAME"
        return 1
    fi
}

# Функция установки базовых пакетов
install_base_packages() {
    print_info "=== Установка базовых пакетов ==="
    
    print_info "Установка базовых пакетов в контейнер $CONTAINER_NAME..."
    
    if pct exec "$CONTAINER_ID" -- apt update && apt upgrade -y; then
        if pct exec "$CONTAINER_ID" -- apt install -y curl wget python3 git htop software-properties-common; then
            print_success "Базовые пакеты установлены"
            return 0
        else
            print_error "Не удалось установить базовые пакеты"
            return 1
        fi
    else
        print_error "Не удалось обновить список пакетов в контейнере"
        return 1
    fi
}

# Функция установки Ansible
install_ansible() {
    print_info "=== Установка Ansible ==="
    
    print_info "Установка Ansible в контейнер $CONTAINER_NAME..."
    
    # Установка Ansible
    print_info "Установка Ansible..."
    if pct exec "$CONTAINER_ID" -- apt install -y ansible; then
        print_success "Ansible успешно установлен"
        
        # Проверка версии Ansible
        local ansible_version=$(pct exec "$CONTAINER_ID" -- ansible --version | head -1)
        print_success "Установлена версия: $ansible_version"
        return 0
    else
        print_error "Не удалось установить Ansible"
        return 1
    fi
}

# Функция настройки пользователя и пароля
setup_user_access() {
    print_info "=== Настройка доступа пользователя ==="
    
    print_info "Настройка пользователя $SSH_USER в контейнере $CONTAINER_NAME..."
    
    # Проверяем, существует ли пользователь
    if pct exec "$CONTAINER_ID" -- id "$SSH_USER" &>/dev/null; then
        print_info "Пользователь $SSH_USER уже существует, обновляем пароль..."
        
        # Устанавливаем пароль для существующего пользователя
        if echo "$SSH_USER:$SSH_PASSWORD" | pct exec "$CONTAINER_ID" -- chpasswd; then
            print_success "Пароль для пользователя $SSH_USER обновлен"
        else
            print_error "Не удалось обновить пароль для пользователя $SSH_USER"
            return 1
        fi
    else
        print_info "Создаем нового пользователя $SSH_USER..."
        
        # Создаем пользователя с домашней директорией и shell
        if pct exec "$CONTAINER_ID" -- useradd -m -s /bin/bash "$SSH_USER"; then
            print_success "Пользователь $SSH_USER создан"
            
            # Устанавливаем пароль
            if echo "$SSH_USER:$SSH_PASSWORD" | pct exec "$CONTAINER_ID" -- chpasswd; then
                print_success "Пароль для пользователя $SSH_USER установлен"
            else
                print_error "Не удалось установить пароль для пользователя $SSH_USER"
                return 1
            fi
        else
            print_error "Не удалось создать пользователя $SSH_USER"
            return 1
        fi
    fi
    
    # Добавляем пользователя в группу sudo (если группа существует)
    if pct exec "$CONTAINER_ID" -- getent group sudo &>/dev/null; then
        if pct exec "$CONTAINER_ID" -- usermod -aG sudo "$SSH_USER"; then
            print_success "Пользователь $SSH_USER добавлен в группу sudo"
        else
            print_warning "Не удалось добавить пользователя $SSH_USER в группу sudo"
        fi
    elif pct exec "$CONTAINER_ID" -- getent group wheel &>/dev/null; then
        # Для некоторых дистрибутивов используется группа wheel
        if pct exec "$CONTAINER_ID" -- usermod -aG wheel "$SSH_USER"; then
            print_success "Пользователь $SSH_USER добавлен в группу wheel"
        else
            print_warning "Не удалось добавить пользователя $SSH_USER в группу wheel"
        fi
    else
        print_warning "Группа sudo/wheel не найдена, пользователь не получил права администратора"
    fi
    
    # Настройка SSH для доступа по паролю
    print_info "Настройка SSH для доступа по паролю..."
    
    # Проверяем, установлен ли SSH сервер
    if ! pct exec "$CONTAINER_ID" -- command -v sshd &>/dev/null; then
        print_info "Устанавливаем SSH сервер..."
        if pct exec "$CONTAINER_ID" -- apt install -y openssh-server; then
            print_success "SSH сервер установлен"
        else
            print_error "Не удалось установить SSH сервер"
            return 1
        fi
    fi
    
    # Создаем директорию для SSH конфигурации
    pct exec "$CONTAINER_ID" -- mkdir -p /etc/ssh
    
    # Настраиваем SSH для доступа по паролю
    if pct exec "$CONTAINER_ID" -- test -f /etc/ssh/sshd_config; then
        # Резервная копия конфигурации
        pct exec "$CONTAINER_ID" -- cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup
        
        # Настройка SSH для доступа по паролю
        pct exec "$CONTAINER_ID" -- sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
        pct exec "$CONTAINER_ID" -- sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
        pct exec "$CONTAINER_ID" -- sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
        pct exec "$CONTAINER_ID" -- sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
        
        print_success "SSH настроен для доступа по паролю"
    else
        print_warning "Файл конфигурации SSH не найден"
    fi
    
    # Перезапускаем SSH сервер
    if pct exec "$CONTAINER_ID" -- systemctl restart ssh; then
        print_success "SSH сервер перезапущен"
    else
        print_warning "Не удалось перезапустить SSH сервер"
    fi
    
    print_success "Доступ пользователя настроен успешно"
    return 0
}

# Функция вывода информации о доступе
show_access_info() {
    print_info "=== ИНФОРМАЦИЯ О ДОСТУПЕ ==="
    echo
    print_success "Контейнер $CONTAINER_NAME готов к работе!"
    echo
    echo "Данные для подключения:"
    echo "  Имя контейнера: $CONTAINER_NAME"
    echo "  ID контейнера: $CONTAINER_ID"
    echo "  IP адрес: $CONTAINER_IP"
    echo "  SSH порт: $SSH_PORT"
    echo "  Логин: $SSH_USER"
    echo "  Пароль: $SSH_PASSWORD"
    echo
    echo "Команды для подключения:"
    echo "  SSH: ssh $SSH_USER@$CONTAINER_IP"
    echo "  Консоль: pct enter $CONTAINER_ID"
    echo "  Статус: pct status $CONTAINER_ID"
    echo
    print_info "Для подключения по SSH используйте:"
    echo "  ssh $SSH_USER@$(echo $CONTAINER_IP | cut -d'/' -f1)"
    echo
    print_info "Настроенные директории:"
    echo "  Ansible: $ANSIBLE_DIR/"
    echo "  HomeLab Public: $AUTOMATE_DIR/$PUBLIC_GIT_DIR/"
    echo "  HomeLab Private: $AUTOMATE_DIR/$PRIVATE_GIT_DIR/"
    echo "  Роли (симлинки): $ANSIBLE_DIR/roles/"
    echo "  Group Vars: $ANSIBLE_DIR/group_vars/"
    echo "  Host Vars: $ANSIBLE_DIR/host_vars/"
    echo "  Keys: $ANSIBLE_DIR/Keys/"
    echo "  Playbooks: $ANSIBLE_DIR/playbooks/"
    echo "  Vars: $ANSIBLE_DIR/vars/"
    echo
    print_info "Git настройки:"
    echo "  Пользователь: $GIT_REPO_USER"
    echo "  Токен: ${GIT_REPO_TOKEN:0:10}... (скрыт для безопасности)"
    echo
}

# Функция клонирования репозитория и настройки ролей
setup_home_automation() {
    print_info "=== Настройка Home Automation ==="
    
    print_info "Настройка директории $AUTOMATE_DIR в контейнере $CONTAINER_NAME..."
    
    # Создаем директорию /etc/home_automate
    if pct exec "$CONTAINER_ID" -- mkdir -p "$AUTOMATE_DIR"; then
        print_success "Директория $AUTOMATE_DIR создана"
    else
        print_error "Не удалось создать директорию $AUTOMATE_DIR"
        return 1
    fi
    
    # Переходим в директорию и клонируем первый репозиторий
    print_info "Клонирование репозитория $PUBLIC_GIT_DIR..."
    
    if pct exec "$CONTAINER_ID" -- bash -c "cd $AUTOMATE_DIR && git clone $GIT_REPO_PUBLIC"; then
        print_success "Репозиторий $PUBLIC_GIT_DIR успешно клонирован"
    else
        print_error "Не удалось клонировать репозиторий $PUBLIC_GIT_DIR"
        return 1
    fi
    
    # Клонируем второй репозиторий (приватный с токеном)
    print_info "Клонирование приватного репозитория $PRIVATE_GIT_DIR с токеном..."
    
    if pct exec "$CONTAINER_ID" -- bash -c "cd $AUTOMATE_DIR && git clone $GIT_REPO_PRIVATE"; then
        print_success "Приватный репозиторий $PRIVATE_GIT_DIR успешно клонирован"
    else
        print_error "Не удалось клонировать приватный репозиторий $PRIVATE_GIT_DIR"
        print_error "Проверьте правильность токена и права доступа"
        return 1
    fi
    
    # Проверяем, что оба репозитория склонированы
    if pct exec "$CONTAINER_ID" -- test -d "$AUTOMATE_DIR/$PUBLIC_GIT_DIR"; then
        print_success "Репозиторий $PUBLIC_GIT_DIR подтвержден в $AUTOMATE_DIR/$PUBLIC_GIT_DIR"
    else
        print_error "Репозиторий $PUBLIC_GIT_DIR не найден после клонирования"
        return 1
    fi
    
    if pct exec "$CONTAINER_ID" -- test -d "$AUTOMATE_DIR/$PRIVATE_GIT_DIR"; then
        print_success "Репозиторий $PRIVATE_GIT_DIR подтвержден в $AUTOMATE_DIR/$PRIVATE_GIT_DIR"
    else
        print_error "Репозиторий $PRIVATE_GIT_DIR не найден после клонирования"
        return 1
    fi
    
    # Устанавливаем правильные права доступа
    pct exec "$CONTAINER_ID" -- chown -R root:root "$AUTOMATE_DIR"
    pct exec "$CONTAINER_ID" -- chmod -R 755 "$AUTOMATE_DIR"
    
    print_success "Home Automation настроен успешно"
    return 0
}


# Функция настройки Ansible
setup_ansible_config() {
    print_info "=== Настройка Ansible ==="
    
    print_info "Настройка директории $ANSIBLE_DIR в контейнере $CONTAINER_NAME..."
    
    # Создаем директорию /etc/ansible
    if pct exec "$CONTAINER_ID" -- mkdir -p "$ANSIBLE_DIR"; then
        print_success "Директория $ANSIBLE_DIR создана"
    else
        print_error "Не удалось создать директорию $ANSIBLE_DIR"
        return 1
    fi
    
    # Создаем директорию для ролей
    print_info "Создание директории для ролей в $ANSIBLE_DIR/roles..."
    
    if pct exec "$CONTAINER_ID" -- mkdir -p "$ANSIBLE_DIR/roles"; then
        print_success "Директория $ANSIBLE_DIR/roles создана"
    else
        print_error "Не удалось создать директорию $ANSIBLE_DIR/roles"
        return 1
    fi
    
    # Создаем директорию для group_vars
    print_info "Создание директории для group_vars в $ANSIBLE_DIR/group_vars..."
    
    if pct exec "$CONTAINER_ID" -- mkdir -p "$ANSIBLE_DIR/group_vars"; then
        print_success "Директория $ANSIBLE_DIR/group_vars создана"
    else
        print_error "Не удалось создать директорию $ANSIBLE_DIR/group_vars"
        return 1
    fi

    # Создаем директорию для host_vars
    print_info "Создание директории для host_vars в $ANSIBLE_DIR/host_vars..."
    
    if pct exec "$CONTAINER_ID" -- mkdir -p "$ANSIBLE_DIR/host_vars"; then
        print_success "Директория $ANSIBLE_DIR/host_vars создана"
    else
        print_error "Не удалось создать директорию $ANSIBLE_DIR/host_vars"
        return 1
    fi

    # Создаем директорию для keys
    print_info "Создание директории для keys в $ANSIBLE_DIR/Keys..."
    
    if pct exec "$CONTAINER_ID" -- mkdir -p "$ANSIBLE_DIR/Keys"; then
        print_success "Директория $ANSIBLE_DIR/Keys создана"
    else
        print_error "Не удалось создать директорию $ANSIBLE_DIR/Keys"
        return 1
    fi

    # Создаем директорию для playbooks
    print_info "Создание директории для playbooks в $ANSIBLE_DIR/playbooks..."
    
    if pct exec "$CONTAINER_ID" -- mkdir -p "$ANSIBLE_DIR/playbooks"; then
        print_success "Директория $ANSIBLE_DIR/playbooks создана"
    else
        print_error "Не удалось создать директорию $ANSIBLE_DIR/playbooks"
        return 1
    fi

    # Создаем директорию для vars
    print_info "Создание директории для vars в $ANSIBLE_DIR/vars..."
    
    if pct exec "$CONTAINER_ID" -- mkdir -p "$ANSIBLE_DIR/vars"; then
        print_success "Директория $ANSIBLE_DIR/vars создана"
    else
        print_error "Не удалось создать директорию $ANSIBLE_DIR/vars"
        return 1
    fi

    # Создаем симлинки на роли из публичного репозитория
    print_info "Создание симлинков на роли из $PUBLIC_GIT_DIR..."
    
    if pct exec "$CONTAINER_ID" -- test -d "$AUTOMATE_DIR/$PUBLIC_GIT_DIR/Ansible/roles"; then
        # Создаем симлинки для каждой роли из публичного репозитория
        pct exec "$CONTAINER_ID" -- bash -c "cd $ANSIBLE_DIR/roles && for role in $AUTOMATE_DIR/$PUBLIC_GIT_DIR/Ansible/roles/*; do if [ -d \"\$role\" ]; then ln -sf \"\$role\" .; fi; done"
        
        print_success "Симлинки на роли из $PUBLIC_GIT_DIR созданы"
    else
        print_warning "Директория ролей не найдена в $PUBLIC_GIT_DIR"
    fi
    
    # Создаем симлинки на group_vars из приватного репозитория
    print_info "Создание симлинков group_vars из $PRIVATE_GIT_DIR..."
    
    if pct exec "$CONTAINER_ID" -- test -d "$AUTOMATE_DIR/$PRIVATE_GIT_DIR/Ansible/group_vars"; then
        # Создаем симлинки для каждой роли из приватного репозитория
        pct exec "$CONTAINER_ID" -- bash -c "cd $ANSIBLE_DIR/group_vars && for role in $AUTOMATE_DIR/$PRIVATE_GIT_DIR/Ansible/group_vars/*; do if [ -d \"\$role\" ]; then ln -sf \"\$role\" .; fi; done"
        
        print_success "Симлинки на роли из $PRIVATE_GIT_DIR созданы"
    else
        print_warning "Директория ролей не найдена в $PRIVATE_GIT_DIR"
    fi

    # Создаем симлинки на host_vars из приватного репозитория
    print_info "Создание симлинков host_vars из $PRIVATE_GIT_DIR..."
    
    if pct exec "$CONTAINER_ID" -- test -d "$AUTOMATE_DIR/$PRIVATE_GIT_DIR/Ansible/host_vars"; then
        # Создаем симлинки для каждой роли из приватного репозитория
        pct exec "$CONTAINER_ID" -- bash -c "cd $ANSIBLE_DIR/host_vars && for role in $AUTOMATE_DIR/$PRIVATE_GIT_DIR/Ansible/host_vars/*; do if [ -d \"\$role\" ]; then ln -sf \"\$role\" .; fi; done"
        
        print_success "Симлинки на host_vars из $PRIVATE_GIT_DIR созданы"
    else
        print_warning "Директория host_vars не найдена в $PRIVATE_GIT_DIR"
    fi

    # Создаем симлинки на keys из приватного репозитория
    print_info "Создание симлинков keys из $PRIVATE_GIT_DIR..."
    
    if pct exec "$CONTAINER_ID" -- test -d "$AUTOMATE_DIR/$PRIVATE_GIT_DIR/Ansible/Keys"; then
        # Создаем симлинки для каждой роли из приватного репозитория
        pct exec "$CONTAINER_ID" -- bash -c "cd $ANSIBLE_DIR/Keys && for role in $AUTOMATE_DIR/$PRIVATE_GIT_DIR/Ansible/Keys/*; do if [ -d \"\$role\" ]; then ln -sf \"\$role\" .; fi; done"
        
        print_success "Симлинки на keys из $PRIVATE_GIT_DIR созданы"
    else
        print_warning "Директория keys не найдена в $PRIVATE_GIT_DIR"
    fi

    # Создаем симлинки на playbooks из приватного репозитория
    print_info "Создание симлинков playbooks из $PRIVATE_GIT_DIR..."
    
    if pct exec "$CONTAINER_ID" -- test -d "$AUTOMATE_DIR/$PRIVATE_GIT_DIR/Ansible/playbooks"; then
        # Создаем симлинки для каждой роли из приватного репозитория
        pct exec "$CONTAINER_ID" -- bash -c "cd $ANSIBLE_DIR/playbooks && for role in $AUTOMATE_DIR/$PRIVATE_GIT_DIR/Ansible/playbooks/*; do if [ -d \"\$role\" ]; then ln -sf \"\$role\" .; fi; done"
        
        print_success "Симлинки на playbooks из $PRIVATE_GIT_DIR созданы"
    else
        print_warning "Директория playbooks не найдена в $PRIVATE_GIT_DIR"
    fi

    # Создаем симлинки на vars из приватного репозитория
    print_info "Создание симлинков vars из $PRIVATE_GIT_DIR..."
    
    if pct exec "$CONTAINER_ID" -- test -d "$AUTOMATE_DIR/$PRIVATE_GIT_DIR/Ansible/vars"; then
        # Создаем симлинки для каждой роли из приватного репозитория
        pct exec "$CONTAINER_ID" -- bash -c "cd $ANSIBLE_DIR/vars && for role in $AUTOMATE_DIR/$PRIVATE_GIT_DIR/Ansible/vars/*; do if [ -d \"\$role\" ]; then ln -sf \"\$role\" .; fi; done"
        
        print_success "Симлинки на vars из $PRIVATE_GIT_DIR созданы"
    else
        print_warning "Директория vars не найдена в $PRIVATE_GIT_DIR"
    fi
    
    # Показываем список доступных ролей
    print_info "Доступные роли (симлинки):"
    pct exec "$CONTAINER_ID" -- ls -la "$ANSIBLE_ROLES_DIR"
    
    # Устанавливаем правильные права доступа
    pct exec "$CONTAINER_ID" -- chown -R root:root "$ANSIBLE_DIR"
    pct exec "$CONTAINER_ID" -- chmod -R 755 "$ANSIBLE_DIR"
    
    print_success "Ansible настроен успешно"
    return 0
}



# Основная функция
main() {
    clear_screen
    print_info "============================================================================="
    print_info "=== Начинаем настройку контейнера $CONTAINER_NAME для Ansible и HomeLab ==="
    print_info "============================================================================="
    echo
    
    # Инициализация и проверки
    print_info "=== Инициализация и проверки ==="
    check_variables
    check_root
    check_proxmox
    check_lxc
    echo
    
    # Поиск OS Template
    print_info "=== Поиск OS Template ==="
    update_templates
    find_latest_os_template
    
    if [ $? -eq 0 ]; then
        echo
        
        # Скачивание Template
        download_template
        
        if [ $? -eq 0 ]; then
            echo
            
            # Создание контейнера
            create_container
            
            if [ $? -eq 0 ]; then
                echo
                
                # Запуск контейнера
                start_container
                
                if [ $? -eq 0 ]; then
                    echo
                    
                    # Установка базовых пакетов
                    install_base_packages
                    
                    if [ $? -eq 0 ]; then
                        echo
                        
                        # Установка Ansible
                        install_ansible
                        
                        if [ $? -eq 0 ]; then
                            echo
                            
                            # Настройка доступа пользователя
                            setup_user_access
                            
                            if [ $? -eq 0 ]; then
                                echo
                                
                                # Настройка Ansible
                                setup_home_automation
                                
                                if [ $? -eq 0 ]; then
                                    echo
                                    
                                    # Настройка Home Automation
                                    setup_ansible_config
                                    
                                    if [ $? -eq 0 ]; then
                                        echo
                                        print_success "Все основные задачи выполнены успешно!"
                                        print_info "Контейнер $CONTAINER_NAME готов к работе с Ansible и HomeLab ролями"
                                        echo
                                        
                                        # Вывод информации о доступе
                                        show_access_info
                                    else
                                        print_error "Не удалось настроить Home Automation"
                                        exit 1
                                    fi
                                else
                                    print_error "Не удалось настроить Ansible"
                                    exit 1
                                fi
                            else
                                print_error "Не удалось настроить доступ пользователя"
                                exit 1
                            fi
                        else
                            print_error "Не удалось установить Ansible"
                            exit 1
                        fi
                    else
                        print_error "Не удалось установить базовые пакеты"
                        exit 1
                    fi
                else
                    print_error "Не удалось запустить контейнер"
                    exit 1
                fi
            else
                print_error "Не удалось создать контейнер"
                exit 1
            fi
        else
            print_error "Не удалось скачать OS Template"
            exit 1
        fi
    else
        print_error "Не удалось выполнить поиск OS Template"
        exit 1
    fi
}

# Запуск основной функции
main "$@"
