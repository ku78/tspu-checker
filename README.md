# TSPU Diagnostic Tool

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Bash](https://img.shields.io/badge/Bash-4.0+-green.svg)](https://www.gnu.org/software/bash/)
[![Version](https://img.shields.io/badge/version-4.3-blue.svg)]()

**Диагностика блокировок и белых списков ТСПУ из командной строки**

Инструмент для быстрого анализа работы ТСПУ (Технических средств противодействия угрозам) в российских сетях. Позволяет определить режим блокировок, проверить доступность портов, выявить SNI-фильтрацию, DNS Spoofing и HTTP-заглушки.

## 📋 Требования

- **Bash 4.0+**
- Установленные утилиты: `ping`, `nc`, `curl`, `openssl`, `dig`, `hping3` (опционально), `nmap` (опционально)

### Установка зависимостей (Linux/WSL)
Bash
sudo apt update
sudo apt install -y hping3 nmap netcat-openbsd openssl dnsutils curl


🚀 Быстрый старт
bash
# Скачать скрипт
git clone https://github.com/ku78/tspu-checker.git
cd tspu-checker

# Сделать исполняемым
chmod +x tspu_check.sh

# Запустить
sudo ./tspu_check.sh
🖥️ Работа на Android (Termux)
bash
pkg update && pkg install -y openssl-tool netcat-openbsd curl tsu nano git
git clone https://github.com/ku78/tspu-checker.git
cd tspu-checker
chmod +x tspu_check.sh
./tspu_check.sh
📊 Функциональность
Основные проверки
Пункт	Назначение
1	Определение режима ТСПУ (белые/чёрные списки)
2	Проверка активности ТСПУ (HTTP + Telegram)
3	Проверка доступности TCP-портов
4	Проверка SNI-фильтрации на L7
5	Проверка UDP-портов (с пояснениями)
6	Проверка внешних DNS
7	Запуск временного веб-сервера на порту 443
8	Полная проверка сервера
9	Детальный анализ портов
10	Определение вашего IP
11	Расширенная диагностика блокировок (4 слоя)
12	Проверка Split DNS / утечки WebRTC
Диагностика 4 слоёв блокировок (пункт 11)
Слой	Что проверяем	Вердикт
1	DNS (системный vs DoH)	DNS Spoofing
2	TCP-соединение на 443	TCP RST / Timeout
3	TLS Handshake с SNI	SNI Block (DPI)
4	HTTP-заглушка	HTTP Stub
🧪 Пример вывода
text
========================================
     TSPU Диагностический инструмент    
              v4.3                      
========================================

🎯 Текущий целевой сервер: 178.154.212.182

Выберите действие:

  0) 🔧 Сменить IP сервера
  1) 🧪 Определить режим ТСПУ
  ...


  
