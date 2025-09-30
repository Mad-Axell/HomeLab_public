#!/bin/bash
# Dynamic MOTD Script / Скрипт динамического MOTD
# This script creates a dynamic MOTD that displays system and connection information
# Этот скрипт создает динамический MOTD, который отображает системную информацию и информацию о подключении

# Get system information / Получить системную информацию
HOSTNAME=$(hostname -f 2>/dev/null || hostname)
OS_INFO=$(lsb_release -d 2>/dev/null | cut -f2 || cat /etc/os-release 2>/dev/null | grep PRETTY_NAME | cut -d'"' -f2 || echo "Unknown OS")
KERNEL=$(uname -r)
UPTIME=$(uptime -p 2>/dev/null || uptime | sed 's/.*up //' | sed 's/,.*//')

# Get current user information / Получить информацию о текущем пользователе
#USERNAME=$(whoami 2>/dev/null || echo "${USER:-${LOGNAME:-Unknown}}")
USERNAME=$(whoami 2>/dev/null)


# Function to center text within 75 characters / Функция центрирования текста в 75 символах
center_text() {
    local text="$1"
    local width=75
    local text_length=${#text}
    local padding=$(((width - text_length) / 2))
    printf "%*s%s\n" "$padding" "" "$text"
}

# Function to colorize output based on usage percentage / Функция цветового вывода по проценту загрузки
colorize_usage() {  
    local percentage=$1
    local text="$2"
    local green="\033[32m"
    local yellow="\033[33m"
    local red="\033[31m"
    local reset="\033[0m"
    
    if [ "$percentage" -lt 30 ]; then
        echo -e "${green}${text}${reset}"
    elif [ "$percentage" -lt 60 ]; then
        echo -e "${yellow}${text}${reset}"
    else
        echo -e "${red}${text}${reset}"
    fi
}

echo "==========================================================================="
# Display username in green and uppercase / Отображение имени пользователя зелёным цветом и заглавными буквами
GREEN="\033[32m"
RESET="\033[0m"
USERNAME_UPPER=$(echo "$USERNAME" | tr '[:lower:]' '[:upper:]')
center_text "${GREEN}${USERNAME_UPPER}${RESET}"
center_text "Welcome to the $HOSTNAME"
echo "==========================================================================="
echo "System uptime:           $UPTIME"

# Check if we're in an SSH session / Проверить, находимся ли мы в SSH сессии
if [ -n "$SSH_TTY" ]; then     # if [ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ]; then
    # Get SSH connection information / Получить информацию о SSH подключении
    SSH_CLIENT_IP=$(echo $SSH_CLIENT | awk '{print $1}')
    SSH_CLIENT_PORT=$(echo $SSH_CLIENT | awk '{print $2}')
    
    echo "Connection Type:         SSH Remote"
    echo "Client IP:               $SSH_CLIENT_IP"
    echo "Client Port:             $SSH_CLIENT_PORT"
    
    # Get last login information / Получить информацию о последнем входе
    if [ -f /var/log/wtmp ]; then
        LAST_LOGIN=$(last -1 -n 1 2>/dev/null | head -1 | awk '{print $4, $5, $6, $7}' || echo "Unknown")
        echo "Last Login:              $LAST_LOGIN"
    fi
else 
    echo "Connection Type:         Local Console"
fi


# CPU Load / Нагрузка CPU
if [ -f /proc/loadavg ]; then
    LOAD_1MIN=$(cat /proc/loadavg | awk '{print $1}')
    CPU_CORES=$(nproc 2>/dev/null || grep -c ^processor /proc/cpuinfo 2>/dev/null || echo "1")
    CPU_PERCENT=$(echo "scale=0; $LOAD_1MIN * 100 / $CPU_CORES" | bc 2>/dev/null || echo $(( $(echo "$LOAD_1MIN * 100" | cut -d. -f1) / CPU_CORES )))
    CPU_TEXT="CPU Load:                ${CPU_PERCENT}% (${LOAD_1MIN} / ${CPU_CORES} cores)"
    colorize_usage "$CPU_PERCENT" "$CPU_TEXT"
fi

# Memory usage / Использование памяти
if [ -f /proc/meminfo ]; then
    MEM_TOTAL=$(grep "MemTotal" /proc/meminfo | awk '{print $2}')
    MEM_AVAILABLE=$(grep "MemAvailable" /proc/meminfo | awk '{print $2}')
    MEM_USED=$((MEM_TOTAL - MEM_AVAILABLE))
    MEM_TOTAL_GB=$((MEM_TOTAL / 1024 / 1024))
    MEM_USED_GB=$((MEM_USED / 1024 / 1024))
    MEM_USAGE_PERCENT=$((MEM_USED * 100 / MEM_TOTAL))
    MEM_TEXT="Memory Usage:            ${MEM_USED_GB}GB / ${MEM_TOTAL_GB}GB (${MEM_USAGE_PERCENT}%)"
    colorize_usage "$MEM_USAGE_PERCENT" "$MEM_TEXT"
fi

# Disk usage / Использование диска
DISK_INFO=$(df -h / 2>/dev/null | tail -1)
if [ -n "$DISK_INFO" ]; then
    DISK_USAGE_PERCENT_RAW=$(echo "$DISK_INFO" | awk '{print $5}')
    DISK_USAGE_PERCENT=$(echo "$DISK_USAGE_PERCENT_RAW" | tr -d '%')
    DISK_AVAILABLE=$(echo "$DISK_INFO" | awk '{print $4}')
    DISK_TOTAL=$(echo "$DISK_INFO" | awk '{print $2}')
    DISK_TEXT="Disk Usage (/):          $DISK_USAGE_PERCENT_RAW (Available: $DISK_AVAILABLE / Total: $DISK_TOTAL)"
    colorize_usage "$DISK_USAGE_PERCENT" "$DISK_TEXT"
fi
