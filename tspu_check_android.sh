#!/bin/bash

# ============================================
# TSPU Диагностика для Termux (урезанная)
# Только работающие функции
# ============================================

# Цвета
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Конфигурация
CONFIG_DIR="$HOME/.config/tspu_checker"
CONFIG_FILE="$CONFIG_DIR/server.conf"
mkdir -p "$CONFIG_DIR"

# Загрузка IP
load_server_ip() {
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
        echo -e "${GREEN}✓ IP: $SERVER_IP${NC}"
    else
        SERVER_IP="178.154.212.182"
        echo -e "${YELLOW}⚠ IP по умолчанию: $SERVER_IP${NC}"
    fi
    echo ""
}

save_server_ip() {
    echo "SERVER_IP=\"$1\"" > "$CONFIG_FILE"
    echo -e "${GREEN}✓ IP сохранён${NC}"
}

clear_screen() { clear; }
pause() { echo -e "\n${YELLOW}Нажмите Enter...${NC}"; read; }

print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}     TSPU Диагностика (Termux)         ${NC}"
    echo -e "${BLUE}========================================${NC}\n"
    echo -e "${CYAN}🎯 Сервер: ${GREEN}$SERVER_IP${NC}\n"
}

check_port() {
    nc -zv -w 3 "$1" "$2" 2>&1 | grep -q "open\|succeeded"
    return $?
}

# ========== ПУНКТЫ МЕНЮ ==========

configure_ip() {
    clear_screen
    print_header
    echo -e "${YELLOW}[0] Сменить IP${NC}\n"
    echo -e "Текущий: ${GREEN}$SERVER_IP${NC}"
    read -p "Новый IP: " new_ip
    if [ -n "$new_ip" ]; then
        save_server_ip "$new_ip"
        SERVER_IP="$new_ip"
    fi
    pause
}

# 1. Режим ТСПУ
mode_tspu() {
    clear_screen
    print_header
    echo -e "${YELLOW}[1] Режим ТСПУ${NC}\n"
    
    BLOCKED_IP="173.194.222.113"
    echo -e "Тест: $BLOCKED_IP\n"
    
    echo -n "  ICMP: "
    ping -c 2 -W 2 "$BLOCKED_IP" > /dev/null 2>&1 && echo -e "${GREEN}OK${NC}" || echo -e "${RED}FAIL${NC}"
    
    echo -n "  TCP 443: "
    check_port "$BLOCKED_IP" 443 && echo -e "${GREEN}OK${NC}" || echo -e "${RED}FAIL${NC}"
    pause
}

# 2. Доступ к сайтам
check_sites() {
    clear_screen
    print_header
    echo -e "${YELLOW}[2] Доступ к сайтам${NC}\n"
    
    sites=("ya.ru:Яндекс" "google.com:Google" "youtube.com:YouTube" "telegram.org:Telegram")
    
    for site in "${sites[@]}"; do
        url="${site%:*}"
        name="${site#*:}"
        echo -n "  $name: "
        code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "https://$url" 2>/dev/null)
        [[ "$code" =~ ^[23] ]] && echo -e "${GREEN}ДОСТУПЕН ($code)${NC}" || echo -e "${RED}НЕТ${NC}"
    done
    pause
}

# 3. TCP порты сервера
check_ports() {
    clear_screen
    print_header
    echo -e "${YELLOW}[3] TCP порты $SERVER_IP${NC}\n"
    
    for port in 22 80 443 8080 8443; do
        echo -n "  Порт $port: "
        check_port "$SERVER_IP" "$port" && echo -e "${GREEN}ОТКРЫТ${NC}" || echo -e "${YELLOW}ЗАКРЫТ${NC}"
    done
    pause
}

# 4. SNI фильтрация
check_sni() {
    clear_screen
    print_header
    echo -e "${YELLOW}[4] SNI фильтрация${NC}\n"
    
    TEST_IP="77.88.55.242"
    sni_list=("ya.ru:Яндекс" "google.com:Google" "twitter.com:Twitter")
    
    for item in "${sni_list[@]}"; do
        sni="${item%:*}"
        name="${item#*:}"
        echo -n "  $name ($sni): "
        result=$(timeout 5 openssl s_client -connect "$TEST_IP:443" -servername "$sni" 2>&1)
        echo "$result" | grep -q "BEGIN CERTIFICATE" && echo -e "${GREEN}ПРОПУЩЕН${NC}" || echo -e "${RED}БЛОК${NC}"
    done
    pause
}

# 5. DNS серверы
check_dns() {
    clear_screen
    print_header
    echo -e "${YELLOW}[5] DNS серверы${NC}\n"
    
    for dns in 8.8.8.8 1.1.1.1; do
        echo -n "  $dns: "
        timeout 3 dig @"$dns" ya.ru +short 2>/dev/null | grep -q "[0-9]" && echo -e "${GREEN}РАБОТАЕТ${NC}" || echo -e "${RED}НЕТ${NC}"
    done
    pause
}

# 6. Ваш IP
my_ip() {
    clear_screen
    print_header
    echo -e "${YELLOW}[6] Ваш IP${NC}\n"
    
    external=$(curl -s --max-time 5 ifconfig.me 2>/dev/null)
    [ -n "$external" ] && echo -e "  Внешний IP: ${GREEN}$external${NC}" || echo -e "  ${YELLOW}Внешний IP: не определён${NC}"
    pause
}

# 7. Тест UDP (клиент-сервер)
udp_test() {
    clear_screen
    print_header
    echo -e "${YELLOW}[7] UDP тест${NC}\n"
    
    echo "Выберите режим:"
    echo "  1) СЕРВЕР (жду пакеты)"
    echo "  2) КЛИЕНТ (отправляю)"
    read -p "> " mode
    
    if [ "$mode" = "1" ]; then
        read -p "Порт (9999): " port
        port=${port:-9999}
        echo -e "\n${GREEN}Слушаю порт $port...${NC}"
        nc -lu -p "$port" -v
    elif [ "$mode" = "2" ]; then
        read -p "IP сервера: " target
        read -p "Порт (9999): " port
        port=${port:-9999}
        echo -n "Сообщение: "
        read msg
        msg=${msg:-TEST}
        echo -e "\nОтправляю..."
        echo "$msg" | nc -u -w 3 "$target" "$port" && echo -e "${GREEN}ОТПРАВЛЕНО${NC}" || echo -e "${RED}ОШИБКА${NC}"
    fi
    pause
}

# 8. Полная проверка
full_check() {
    clear_screen
    print_header
    echo -e "${YELLOW}[8] Полная проверка${NC}\n"
    
    echo -n "  Пинг $SERVER_IP: "
    ping -c 2 -W 2 "$SERVER_IP" > /dev/null 2>&1 && echo -e "${GREEN}OK${NC}" || echo -e "${RED}FAIL${NC}"
    
    echo -e "\n  ${CYAN}TCP порты:${NC}"
    for port in 22 80 443; do
        echo -n "    $port: "
        check_port "$SERVER_IP" "$port" && echo -e "${GREEN}ОТКРЫТ${NC}" || echo -e "${YELLOW}ЗАКРЫТ${NC}"
    done
    pause
}

# ========== МЕНЮ ==========
show_menu() {
    clear_screen
    print_header
    echo -e "${GREEN}Выберите действие:${NC}\n"
    echo "  0) 🔧 Сменить IP"
    echo "  1) 🧪 Режим ТСПУ"
    echo "  2) 📡 Доступ к сайтам"
    echo "  3) 🔍 TCP порты сервера"
    echo "  4) 🎭 SNI фильтрация"
    echo "  5) 🌐 DNS серверы"
    echo "  6) 🌍 Ваш IP"
    echo "  7) 📦 UDP тест (клиент/сервер)"
    echo "  8) 🖥️ Полная проверка"
    echo "  q) Выход"
    echo
}

# ========== ЗАПУСК ==========
load_server_ip

while true; do
    show_menu
    read -p "Ваш выбор: " choice
    
    case "$choice" in
        0) configure_ip ;;
        1) mode_tspu ;;
        2) check_sites ;;
        3) check_ports ;;
        4) check_sni ;;
        5) check_dns ;;
        6) my_ip ;;
        7) udp_test ;;
        8) full_check ;;
        q|Q) 
            clear_screen
            echo -e "${GREEN}До свидания!${NC}"
            exit 0
            ;;
        *) echo -e "${RED}Неверный выбор${NC}"; sleep 1 ;;
    esac
done
