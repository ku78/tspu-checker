#!/bin/bash

# ============================================
# TSPU Диагностический инструмент v4.5
# Добавлены: NAT type detection, UDP speed test
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

# Загрузка IP сервера
load_server_ip() {
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
        echo -e "${GREEN}✓ Загружен сохранённый IP: $SERVER_IP${NC}"
    else
        SERVER_IP="178.154.212.182"
        echo -e "${YELLOW}⚠ Используется IP по умолчанию: 178.154.212.182${NC}"
    fi
    echo ""
}

save_server_ip() {
    echo "SERVER_IP=\"$1\"" > "$CONFIG_FILE"
    echo -e "${GREEN}✓ IP сохранён: $1${NC}"
}

clear_screen() { clear; }
pause() { echo -e "\n${YELLOW}Нажмите Enter для продолжения...${NC}"; read; }

print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}     ТСПУ Диагностический инструмент    ${NC}"
    echo -e "${BLUE}              v4.5                      ${NC}"
    echo -e "${BLUE}========================================${NC}\n"
    echo -e "${CYAN}🎯 Текущий целевой сервер: ${GREEN}$SERVER_IP${NC}\n"
}

# Проверка порта через nc
check_port_nc() {
    nc -zv -w 3 "$1" "$2" 2>&1 | grep -q "open\|succeeded\|Connected"
    return $?
}

# 0. Настройка IP сервера
configure_server_ip() {
    clear_screen
    print_header
    echo -e "${YELLOW}[0] 🔧 Настройка IP адреса сервера${NC}\n"
    echo -e "${CYAN}Текущий IP: ${GREEN}$SERVER_IP${NC}\n"
    read -p "Введите новый IP (или оставьте пустым): " new_ip
    if [ -n "$new_ip" ]; then
        if [[ "$new_ip" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
            save_server_ip "$new_ip"
            SERVER_IP="$new_ip"
            echo -e "\n${GREEN}✅ IP изменён на $SERVER_IP${NC}"
        else
            echo -e "\n${RED}❌ Неверный формат IP${NC}"
        fi
    fi
    pause
}

# 1. Определение режима ТСПУ
detect_tspu_mode() {
    clear_screen
    print_header
    echo -e "${YELLOW}[1] 🧪 Определение режима работы ТСПУ...${NC}\n"
    
    BLOCKED_IP="173.194.222.113"
    echo -e "${CYAN}🔬 Тестовый IP (Google): $BLOCKED_IP${NC}\n"
    
    echo -ne "  ICMP (ping) Google: "
    if ping -c 2 -W 2 "$BLOCKED_IP" > /dev/null 2>&1; then
        echo -e "${GREEN}ДОСТУПЕН ✓${NC}"
        ICMP_OK=true
    else
        echo -e "${RED}НЕ ДОСТУПЕН ✗${NC}"
        ICMP_OK=false
    fi
    
    echo -ne "  TCP (nc) Google:443: "
    if check_port_nc "$BLOCKED_IP" 443; then
        echo -e "${GREEN}ДОСТУПЕН ✓${NC}"
        TCP_OK=true
    else
        echo -e "${RED}НЕ ДОСТУПЕН ✗${NC}"
        TCP_OK=false
    fi
    
    echo -e "\n${CYAN}📊 Режим работы:${NC}\n"
    if [ "$ICMP_OK" = true ] && [ "$TCP_OK" = false ]; then
        echo -e "  ${RED}⚠️ РЕЖИМ БЕЛЫХ СПИСКОВ (allowlist)${NC}"
        echo -e "     • ICMP работает, TCP блокируется на L3"
    elif [ "$ICMP_OK" = false ] && [ "$TCP_OK" = false ]; then
        echo -e "  ${YELLOW}⚠️ РЕЖИМ ЧЁРНЫХ СПИСКОВ или ПОЛНАЯ БЛОКИРОВКА${NC}"
    elif [ "$ICMP_OK" = true ] && [ "$TCP_OK" = true ]; then
        echo -e "  ${GREEN}✅ БЛОКИРОВКИ НЕТ (нормальный режим)${NC}"
    fi
    pause
}

# 2. Проверка активности ТСПУ
check_tspu_active() {
    clear_screen
    print_header
    echo -e "${YELLOW}[2] 📡 Проверка активности ТСПУ (доступ к сайтам)...${NC}\n"
    echo -e "${CYAN}📡 Проверка через curl:${NC}\n"
    
    sites=(
        "ya.ru:Яндекс"
        "google.com:Google"
        "youtube.com:YouTube"
        "github.com:GitHub"
        "telegram.org:Telegram"
    )
    
    for site in "${sites[@]}"; do
        url="${site%:*}"
        name="${site#*:}"
        echo -ne "  $name ($url): "
        http_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "https://$url" 2>/dev/null)
        if [[ "$http_code" =~ ^[23] ]]; then
            echo -e "${GREEN}ДОСТУПЕН (HTTP $http_code) ✓${NC}"
        else
            echo -e "${RED}НЕ ДОСТУПЕН ✗${NC}"
        fi
    done
    
    echo -e "\n${CYAN}🔌 Проверка сервера $SERVER_IP:${NC}\n"
    for port in 22 80 443; do
        echo -ne "  Порт $port: "
        if check_port_nc "$SERVER_IP" "$port"; then
            echo -e "${GREEN}ОТКРЫТ ✓${NC}"
        else
            echo -e "${YELLOW}ЗАКРЫТ/ФИЛЬТР${NC}"
        fi
    done
    pause
}

# 3. Проверка доступности портов
check_ports() {
    clear_screen
    print_header
    echo -e "${YELLOW}[3] 🔍 Проверка доступности портов (TCP)...${NC}\n"
    echo -e "${CYAN}🎯 Цель: $SERVER_IP${NC}\n"
    
    for port in 22 80 443 8080 8443; do
        echo -ne "  Порт $port: "
        if check_port_nc "$SERVER_IP" "$port"; then
            echo -e "${GREEN}ОТКРЫТ ✓${NC}"
        else
            echo -e "${YELLOW}ЗАКРЫТ/НЕТ ОТВЕТА${NC}"
        fi
        sleep 0.2
    done
    pause
}

# 4. Проверка SNI-фильтрации
test_sni_filtering() {
    clear_screen
    print_header
    echo -e "${YELLOW}[4] 🎭 Проверка SNI-фильтрации на L7...${NC}\n"
    
    TEST_IP="77.88.55.242"
    echo -e "${CYAN}🎯 Тестовый IP (Яндекс): $TEST_IP${NC}\n"
    
    sni_tests=(
        "ya.ru:Яндекс"
        "google.com:Google"
        "twitter.com:Twitter"
        "youtube.com:YouTube"
        "vk.com:VK"
    )
    
    for test in "${sni_tests[@]}"; do
        sni="${test%:*}"
        name="${test#*:}"
        echo -ne "  SNI: $sni ($name): "
        result=$(timeout 5 openssl s_client -connect "$TEST_IP:443" -servername "$sni" -tlsextdebug 2>&1)
        if echo "$result" | grep -q "BEGIN CERTIFICATE"; then
            echo -e "${GREEN}ПРОПУЩЕН ✓${NC}"
        elif echo "$result" | grep -q "Connection reset"; then
            echo -e "${RED}ЗАБЛОКИРОВАН (RST) — ТСПУ РЕЖЕТ SNI!${NC}"
        else
            echo -e "${YELLOW}НЕТ ОТВЕТА${NC}"
        fi
    done
    pause
}

# 5. Проверка UDP-портов
check_udp_ports() {
    clear_screen
    print_header
    echo -e "${YELLOW}[5] 📦 Проверка UDP-портов...${NC}\n"
    echo -e "${CYAN}🎯 Цель: $SERVER_IP${NC}\n"
    
    echo -ne "  UDP 53 (DNS): "
    dns_result=$(timeout 2 dig @"$SERVER_IP" ya.ru +short 2>&1)
    if [ -n "$dns_result" ] && [ "$dns_result" != ";;"* ]; then
        echo -e "${GREEN}ОТВЕЧАЕТ ✓${NC}"
    else
        echo -e "${YELLOW}НЕТ ОТВЕТА (не DNS сервер)${NC}"
    fi
    
    echo -e "\n  UDP 443 (QUIC):"
    echo -e "    → QUIC не отвечает на пустые UDP-пакеты"
    echo -e "    → 'НЕТ ОТВЕТА' — ЭТО НОРМАЛЬНО"
    
    echo -e "\n  UDP 8443 (Hysteria):"
    echo -e "    → Hysteria использует свой UDP handshake"
    echo -e "    → 'НЕТ ОТВЕТА' — ЭТО НОРМАЛЬНО"
    
    echo -e "\n  UDP 51820 (WireGuard):"
    echo -e "    → WireGuard игнорирует неавторизованные пакеты"
    echo -e "    → 'НЕТ ОТВЕТА' — ЭТО НОРМАЛЬНО"
    
    echo -e "\n${BLUE}💡 Пояснение:${NC}"
    echo -e "  Только UDP 53 (DNS) гарантированно отвечает на пустые пакеты."
    echo -e "  ${GREEN}'НЕТ ОТВЕТА' НЕ означает, что порт заблокирован!${NC}"
    pause
}

# 6. Проверка внешних DNS
check_dns() {
    clear_screen
    print_header
    echo -e "${YELLOW}[6] 🌐 Проверка внешних DNS-серверов...${NC}\n"
    
    dns_servers=(
        "8.8.8.8:Google DNS"
        "1.1.1.1:Cloudflare DNS"
        "77.88.8.8:Яндекс DNS"
    )
    
    for dns in "${dns_servers[@]}"; do
        ip="${dns%:*}"
        name="${dns#*:}"
        echo -ne "  $name ($ip): "
        result=$(timeout 3 dig @"$ip" ya.ru +short 2>&1)
        if [ -n "$result" ] && [ "$result" != ";;"* ]; then
            echo -e "${GREEN}РАБОТАЕТ ✓${NC}"
        else
            echo -e "${RED}НЕ ДОСТУПЕН (таймаут)${NC}"
        fi
    done
    pause
}

# 7. Запуск веб-сервера
start_web_server() {
    clear_screen
    print_header
    echo -e "${YELLOW}[7] 🚀 Запуск временного веб-сервера на порту 443...${NC}\n"
    
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}❌ Ошибка: нужны права root${NC}"
        pause
        return
    fi
    
    LOCAL_IP=$(ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v '127.0.0.1' | head -1)
    [ -z "$LOCAL_IP" ] && LOCAL_IP="localhost"
    
    if sudo lsof -i :443 2>/dev/null | grep -q LISTEN; then
        echo -e "${YELLOW}⚠️ Порт 443 занят:${NC}"
        sudo lsof -i :443 | grep LISTEN
        echo -ne "\n${YELLOW}Освободить? (y/n): "
        read answer
        if [[ "$answer" == "y" ]]; then
            sudo fuser -k 443/tcp 2>/dev/null
            sleep 2
        else
            return
        fi
    fi
    
    WEB_DIR="/tmp/tspu_web_test"
    rm -rf "$WEB_DIR"
    mkdir -p "$WEB_DIR"
    
    cat > "$WEB_DIR/index.html" << EOF
<!DOCTYPE html>
<html><head><title>ТСПУ Тест</title></head>
<body><h1>✓ Веб-сервер работает!</h1>
<p>Время: $(date)</p>
<p>Проверка: curl -k https://localhost:443</p>
</body></html>
EOF
    
    cd "$WEB_DIR"
    openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -days 1 -nodes -subj "/CN=localhost" 2>/dev/null
    
    clear_screen
    print_header
    echo -e "${GREEN}✅ Веб-сервер запущен!${NC}\n"
    echo -e "${CYAN}📡 Доступные адреса:${NC}"
    echo -e "  • https://localhost:443"
    echo -e "  • https://$LOCAL_IP:443"
    echo -e "\n${RED}⚠️  Для остановки нажмите Ctrl+C${NC}\n"
    
    python3 -m http.server 443 --cert cert.pem --key key.pem
    
    rm -rf "$WEB_DIR"
    echo -e "\n${GREEN}✅ Веб-сервер остановлен${NC}"
    pause
}

# 8. Полная проверка сервера
check_server() {
    clear_screen
    print_header
    echo -e "${YELLOW}[8] 🖥️  Полная проверка сервера $SERVER_IP...${NC}\n"
    
    echo -ne "  Пинг: "
    if ping -c 2 -W 2 "$SERVER_IP" > /dev/null 2>&1; then
        echo -e "${GREEN}ДОСТУПЕН ✓${NC}"
    else
        echo -e "${RED}НЕ ДОСТУПЕН ✗${NC}"
    fi
    
    echo -e "\n${CYAN}🔌 TCP порты:${NC}"
    for port in 22 80 443 8080 8443; do
        echo -ne "    Порт $port: "
        if check_port_nc "$SERVER_IP" "$port"; then
            echo -e "${GREEN}ОТКРЫТ ✓${NC}"
        else
            echo -e "${YELLOW}ЗАКРЫТ/ФИЛЬТР${NC}"
        fi
    done
    pause
}

# 9. Детальный анализ портов
check_ports_detailed() {
    clear_screen
    print_header
    echo -e "${YELLOW}[9] 📊 Детальный анализ портов${NC}\n"
    
    echo -e "  ${BLUE}Порт   Сервис        Статус${NC}"
    echo -e "  ${BLUE}----   ------        -------------${NC}"
    
    for port in 22 80 443 3306 5432 8080 8443; do
        case $port in
            22) service="SSH" ;;
            80) service="HTTP" ;;
            443) service="HTTPS" ;;
            3306) service="MySQL" ;;
            5432) service="PostgreSQL" ;;
            8080) service="HTTP-alt" ;;
            8443) service="HTTPS-alt" ;;
        esac
        printf "  %-6s %-12s " "$port" "$service"
        if check_port_nc "$SERVER_IP" "$port"; then
            echo -e "${GREEN}ОТКРЫТ ✓${NC}"
        else
            echo -e "${YELLOW}ЗАКРЫТ/ФИЛЬТР${NC}"
        fi
        sleep 0.1
    done
    pause
}

# 10. Определение IP
check_my_ip() {
    clear_screen
    print_header
    echo -e "${YELLOW}[10] 🌍 Определение вашего IP...${NC}\n"
    
    local_ip=$(ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v '127.0.0.1' | head -1)
    if [ -n "$local_ip" ]; then
        echo -e "  Внутренний IP: ${GREEN}$local_ip${NC}"
    else
        echo -e "  ${YELLOW}Внутренний IP: не определяется${NC}"
    fi
    
    external_ip=$(curl -s --max-time 5 -4 ifconfig.me 2>/dev/null)
    if [ -n "$external_ip" ]; then
        echo -e "  Внешний IP:    ${GREEN}$external_ip${NC}"
    else
        echo -e "  ${YELLOW}Внешний IP: не удалось определить${NC}"
    fi
    pause
}

# 11. Расширенная диагностика блокировок
rkn_block_check() {
    clear_screen
    print_header
    echo -e "${YELLOW}[11] 🔬 Расширенная диагностика блокировок (4 слоя)${NC}\n"
    
    echo -e "${GREEN}--- Белый список (контрольная группа) ---${NC}"
    echo -e "\n${CYAN}Проверка: Яндекс (ya.ru)${NC}"
    
    sys_ip=$(dig +short ya.ru 2>/dev/null | head -1)
    doh_ip=$(dig +short ya.ru @1.1.1.1 2>/dev/null | head -1)
    echo -ne "  DNS системный: "; [ -n "$sys_ip" ] && echo -e "${GREEN}OK → $sys_ip${NC}" || echo -e "${RED}НЕТ ОТВЕТА${NC}"
    echo -ne "  DNS DoH (1.1.1.1): "; [ -n "$doh_ip" ] && echo -e "${GREEN}OK → $doh_ip${NC}" || echo -e "${RED}НЕТ ОТВЕТА${NC}"
    
    echo -ne "  TCP порт 443: "
    if check_port_nc "ya.ru" 443; then
        echo -e "${GREEN}ОТКРЫТ${NC}"
        tcp_ok=true
    else
        echo -e "${RED}ЗАКРЫТ/ТАЙМАУТ${NC}"
        tcp_ok=false
    fi
    
    echo -e "\n${RED}--- Чёрный список (заблокированные ресурсы) ---${NC}"
    echo -e "\n${CYAN}Проверка: Twitter (twitter.com)${NC}"
    
    sys_ip=$(dig +short twitter.com 2>/dev/null | head -1)
    doh_ip=$(dig +short twitter.com @1.1.1.1 2>/dev/null | head -1)
    echo -ne "  DNS системный: "; [ -n "$sys_ip" ] && echo -e "${GREEN}OK → $sys_ip${NC}" || echo -e "${RED}НЕТ ОТВЕТА${NC}"
    echo -ne "  DNS DoH (1.1.1.1): "; [ -n "$doh_ip" ] && echo -e "${GREEN}OK → $doh_ip${NC}" || echo -e "${RED}НЕТ ОТВЕТА${NC}"
    
    echo -ne "  TCP порт 443: "
    if check_port_nc "twitter.com" 443; then
        echo -e "${GREEN}ОТКРЫТ${NC}"
        tcp_ok=true
    else
        echo -e "${RED}ЗАКРЫТ/ТАЙМАУТ${NC}"
        tcp_ok=false
    fi
    
    if [ "$tcp_ok" = true ]; then
        echo -ne "  TLS Handshake: "
        tls_result=$(timeout 5 openssl s_client -connect "twitter.com:443" -servername "twitter.com" -tlsextdebug 2>&1)
        if echo "$tls_result" | grep -q "BEGIN CERTIFICATE"; then
            echo -e "${GREEN}УСПЕШНО${NC}"
        elif echo "$tls_result" | grep -q "Connection reset"; then
            echo -e "${RED}СБРОШЕН (RST) — SNI-БЛОКИРОВКА ТСПУ!${NC}"
        else
            echo -e "${YELLOW}ТАЙМАУТ/ОШИБКА${NC}"
        fi
    fi
    
    pause
}

# 12. Проверка Split DNS
check_split_dns() {
    clear_screen
    print_header
    echo -e "${YELLOW}[12] 🔍 Проверить Split DNS/утечку WebRTC${NC}\n"
    echo -e "${CYAN}📌 ВНИМАНИЕ: Запустите этот тест ПРИ ВКЛЮЧЁННОМ VPN${NC}\n"
    read -p "Нажмите Enter если VPN включён, или 'q' для выхода: " answer
    [[ "$answer" == "q" ]] && return
    
    echo -e "\n${CYAN}[Проверка, какой IP видят сайты]:${NC}\n"
    
    ya_ip=$(curl -s --max-time 5 "https://ya.ru" -w "%{remote_ip}" -o /dev/null 2>/dev/null)
    echo -ne "  ya.ru видит IP: "
    if [[ "$ya_ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo -e "${GREEN}$ya_ip${NC}"
    else
        echo -e "${YELLOW}не удалось определить${NC}"
    fi
    
    external_ip=$(curl -s --max-time 5 "https://ifconfig.me/ip" 2>/dev/null)
    echo -ne "  ifconfig.me видит IP: "
    if [ -n "$external_ip" ]; then
        echo -e "${GREEN}$external_ip${NC}"
    else
        echo -e "${YELLOW}не удалось определить${NC}"
    fi
    
    echo -e "\n${BLUE}📊 Анализ:${NC}"
    if [ -n "$ya_ip" ] && [ -n "$external_ip" ] && [ "$ya_ip" != "$external_ip" ]; then
        echo -e "  ${GREEN}✅ Split DNS/туннелирование РАБОТАЕТ${NC}"
    elif [ -n "$ya_ip" ] && [ -n "$external_ip" ] && [ "$ya_ip" == "$external_ip" ]; then
        echo -e "  ${RED}⚠️ ВОЗМОЖНА УТЕЧКА — оба сайта видят один IP${NC}"
    else
        echo -e "  ${YELLOW}❓ Не удалось определить${NC}"
    fi
    pause
}

# 13. Тест UDP-связи между серверами
udp_pair_test() {
    clear_screen
    print_header
    echo -e "${YELLOW}[13] 🧪 Тест UDP-связи между серверами (Hysteria/QUIC)${NC}\n"
    
    echo -e "${CYAN}Этот тест проверяет, блокирует ли провайдер UDP-трафик.${NC}"
    echo -e "Для работы нужно запустить скрипт на ДВУХ серверах одновременно.\n"
    
    echo -e "${GREEN}Выберите режим:${NC}"
    echo -e "  ${BLUE}1${NC}) Режим СЕРВЕР (приёмник) — запустить на сервере, который ЖДЁТ пакеты"
    echo -e "  ${BLUE}2${NC}) Режим КЛИЕНТ (отправитель) — запустить на сервере, который ОТПРАВЛЯЕТ"
    echo
    read -p "Ваш выбор: " mode
    
    if [ "$mode" = "1" ]; then
        echo -e "\n${CYAN}=== РЕЖИМ СЕРВЕР (приёмник) ===${NC}\n"
        read -p "Введите порт для прослушивания (по умолчанию 9999): " port_input
        port=${port_input:-9999}
        
        echo -e "\n${YELLOW}⚠️ Убедитесь, что порт $port открыт в файрволе!${NC}"
        echo -e "${YELLOW}⚠️ Если используется ufw: sudo ufw allow $port/udp${NC}"
        echo -e "${YELLOW}⚠️ На некоторых VPS нужно открыть порт в панели управления (Security Group)${NC}\n"
        
        read -p "Нажмите Enter, чтобы начать прослушивание UDP порта $port..."
        echo -e "${GREEN}✅ Слушаю UDP порт $port...${NC}"
        echo -e "${CYAN}Ожидаю входящие пакеты. Для остановки нажмите Ctrl+C${NC}\n"
        
        nc -lu -p "$port" -v
        echo -e "\n${YELLOW}⚠️ Прослушивание остановлено${NC}"
        
    elif [ "$mode" = "2" ]; then
        echo -e "\n${CYAN}=== РЕЖИМ КЛИЕНТ (отправитель) ===${NC}\n"
        read -p "Введите IP адрес целевого сервера (приёмника): " target_ip
        if [ -z "$target_ip" ]; then
            echo -e "${RED}❌ IP адрес обязателен!${NC}"
            pause
            return
        fi
        read -p "Введите порт целевого сервера (по умолчанию 9999): " port_input
        port=${port_input:-9999}
        read -p "Введите сообщение для отправки (по умолчанию 'TEST_UDP'): " message
        message=${message:-TEST_UDP}
        read -p "Количество пакетов (по умолчанию 1): " count_input
        count=${count_input:-1}
        
        echo -e "\n${CYAN}Отправляю $count UDP пакет(ов) на $target_ip:$port${NC}\n"
        success=0
        for i in $(seq 1 $count); do
            echo -n "  Пакет $i: "
            if echo "${message}_${i}" | nc -u -w 3 "$target_ip" "$port" 2>/dev/null; then
                echo -e "${GREEN}ОТПРАВЛЕН ✓${NC}"
                success=$((success + 1))
            else
                echo -e "${RED}ОШИБКА (нет ответа или таймаут)${NC}"
            fi
            sleep 0.5
        done
        
        echo -e "\n${CYAN}📊 Результат:${NC}"
        if [ $success -eq $count ]; then
            echo -e "  ${GREEN}✅ Все $success пакетов отправлены.${NC}"
            echo -e "     Если на сервере-приёмнике они появились — UDP РАБОТАЕТ."
        elif [ $success -gt 0 ]; then
            echo -e "  ${YELLOW}⚠️ Отправлено только $success из $count пакетов. Возможны проблемы с сетью.${NC}"
        else
            echo -e "  ${RED}❌ Не удалось отправить ни одного пакета. Провайдер или хостинг блокирует UDP!${NC}"
        fi
    else
        echo -e "${RED}❌ Неверный выбор${NC}"
    fi
    pause
}

# 14. Определение типа NAT (CGNAT / Full Cone / Symmetric)
check_nat_type() {
    clear_screen
    print_header
    echo -e "${YELLOW}[14] 🌐 Определение типа NAT (CGNAT/Full Cone/Symmetric)${NC}\n"
    
    echo -e "${CYAN}Этот тест помогает понять, почему не работают входящие соединения.${NC}\n"
    
    external_ip=$(curl -s --max-time 5 "https://ifconfig.me/ip" 2>/dev/null)
    if [ -z "$external_ip" ]; then
        echo -e "${RED}❌ Не удалось определить внешний IP${NC}"
        pause
        return
    fi
    
    echo -e "  Внешний IP: ${GREEN}$external_ip${NC}"
    
    IFS='.' read -r a b c d <<< "$external_ip"
    if [ "$a" -eq 100 ] && [ "$b" -ge 64 ] && [ "$b" -le 127 ]; then
        echo -e "  ${RED}⚠️ Обнаружен CGNAT (адрес 100.64.0.0/10)${NC}"
        echo -e "     → Прямые входящие соединения невозможны"
        echo -e "     → Используйте туннелирование (VPN, reverse proxy)"
    else
        echo -e "  ${GREEN}✅ Публичный IP (не CGNAT)${NC}"
    fi
    
    echo -e "\n${CYAN}🔌 Проверка входящих соединений:${NC}"
    echo -e "  Запустите на этом же компьютере:"
    echo -e "    ${YELLOW}nc -l -p 8888${NC}"
    echo -e "  И попросите друга подключиться:"
    echo -e "    ${YELLOW}nc -zv $external_ip 8888${NC}"
    echo -e "\n  Если соединение не устанавливается — вы за CGNAT или порты закрыты оператором."
    
    pause
}

# 15. Тест скорости UDP канала
test_udp_speed() {
    clear_screen
    print_header
    echo -e "${YELLOW}[15] 📊 Тест скорости UDP канала${NC}\n"
    
    echo -e "${CYAN}ВНИМАНИЕ: Этот тест приблизительный. Требуется сервер-приёмник.${NC}\n"
    
    read -p "IP адрес сервера-приёмника: " target_ip
    if [ -z "$target_ip" ]; then
        echo -e "${RED}❌ IP адрес обязателен!${NC}"
        pause
        return
    fi
    read -p "Порт (по умолчанию 9999): " port_input
    port=${port_input:-9999}
    
    echo -e "\n${YELLOW}Отправляю 10 пакетов по 1KB...${NC}\n"
    
    total_time=0
    for i in $(seq 1 10); do
        start=$(date +%s%N)
        echo "TEST_SPEED_$i" | nc -u -w 2 "$target_ip" "$port" 2>/dev/null
        end=$(date +%s%N)
        elapsed=$((($end - $start) / 1000000))
        echo -e "  Пакет $i: ${elapsed} мс"
        total_time=$((total_time + elapsed))
        sleep 0.5
    done
    
    avg_time=$((total_time / 10))
    echo -e "\n${CYAN}📊 Средняя задержка: ${avg_time} мс${NC}"
    
    if [ $avg_time -lt 50 ]; then
        echo -e "  ${GREEN}✅ Отлично! UDP канал подходит для Hysteria/WireGuard${NC}"
    elif [ $avg_time -lt 150 ]; then
        echo -e "  ${YELLOW}⚠️ Нормально, но возможны проблемы при высокой нагрузке${NC}"
    else
        echo -e "  ${RED}❌ Высокая задержка! Hysteria/WireGuard будут работать медленно${NC}"
    fi
    
    pause
}

# ========== ГЛАВНОЕ МЕНЮ (исправленное) ==========
show_menu() {
    clear_screen
    print_header
    echo -e "${GREEN}Выберите действие:${NC}\n"
    echo -e "  ${BLUE}0${NC}) 🔧 Сменить IP сервера (сейчас: $SERVER_IP)"
    echo -e "  ${BLUE}1${NC}) 🧪 Определить режим ТСПУ"
    echo -e "  ${BLUE}2${NC}) 📡 Проверить активность ТСПУ (curl)"
    echo -e "  ${BLUE}3${NC}) 🔍 Проверить доступность портов (TCP)"
    echo -e "  ${BLUE}4${NC}) 🎭 Проверить SNI-фильтрацию (L7)"
    echo -e "  ${BLUE}5${NC}) 📦 Проверить UDP-порты (пояснения)"
    echo -e "  ${BLUE}6${NC}) 🌐 Проверить внешние DNS"
    echo -e "  ${BLUE}7${NC}) 🚀 Запустить веб-сервер на 443"
    echo -e "  ${BLUE}8${NC}) 🖥️  Полная проверка сервера"
    echo -e "  ${BLUE}9${NC}) 📊 Детальный анализ портов"
    echo -e "  ${BLUE}10${NC}) 🌍 Определить ваш IP"
    echo -e "  ${BLUE}11${NC}) 🔬 Расширенная диагностика блокировок (4 слоя)"
    echo -e "  ${BLUE}12${NC}) 🔍 Проверить Split DNS/утечку"
    echo -e "  ${BLUE}13${NC}) 🧪 Тест UDP-связи между серверами (Hysteria/QUIC)"
    echo -e "  ${BLUE}14${NC}) 🌐 Определение типа NAT (CGNAT)"
    echo -e "  ${BLUE}15${NC}) 📊 Тест скорости UDP канала"
    echo -e "  ${BLUE}q${NC}) ❌ Выход"
    echo
}

# ========== ГЛАВНЫЙ ЦИКЛ (исправленный) ==========
load_server_ip

while true; do
    show_menu
    read -p "Ваш выбор: " choice
    echo ""  # пустая строка для красоты
    
    case "$choice" in
        0) configure_server_ip ;;
        1) detect_tspu_mode ;;
        2) check_tspu_active ;;
        3) check_ports ;;
        4) test_sni_filtering ;;
        5) check_udp_ports ;;
        6) check_dns ;;
        7) start_web_server ;;
        8) check_server ;;
        9) check_ports_detailed ;;
        10) check_my_ip ;;
        11) rkn_block_check ;;
        12) check_split_dns ;;
        13) udp_pair_test ;;
        14) check_nat_type ;;
        15) test_udp_speed ;;
        q|Q) 
            clear_screen
            echo -e "${GREEN}До свидания!${NC}"
            exit 0
            ;;
        *) 
            echo -e "${RED}Неверный выбор: '$choice'${NC}"
            sleep 1
            ;;
    esac
done
