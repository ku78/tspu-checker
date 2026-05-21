# TSPU Diagnostic Tool

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Bash](https://img.shields.io/badge/Bash-4.0+-green.svg)](https://www.gnu.org/software/bash/)
[![Version](https://img.shields.io/badge/version-4.3-blue.svg)]()

**Диагностика блокировок и белых списков ТСПУ из командной строки**

Инструмент для быстрого анализа работы ТСПУ (Технических средств противодействия угрозам) в российских сетях. Позволяет определить режим блокировок, проверить доступность портов, выявить SNI-фильтрацию, DNS Spoofing и HTTP-заглушки.

---

## Требования

- **Bash 4.0+**
- Установленные утилиты: `ping`, `nc`, `curl`, `openssl`, `dig`, `hping3` (опционально), `nmap` (опционально)

### Установка зависимостей (Linux/WSL)

```bash
sudo apt update
sudo apt install -y hping3 nmap netcat-openbsd openssl dnsutils curl
```
#### [🚀] Быстрый старт
```bash
# Скачать скрипт
git clone https://github.com/ku78/tspu-checker.git
cd tspu-checker

# Сделать исполняемым
chmod +x tspu_check.sh

# Запустить
sudo ./tspu_check.sh
```
Android (Termux)
```bash
# Установка зависимостей
pkg update && pkg install -y openssl-tool netcat-openbsd curl tsu nano git

# Скачать и запустить
git clone https://github.com/ku78/tspu-checker.git
cd tspu-checker
chmod +x tspu_check.sh
./tspu_check.sh
```
[📊] Функциональность
```bash
========================================
     ТСПУ Диагностический инструмент    
              v1.0                      
========================================

🎯 Текущий целевой сервер: 192.168.1.1

Выберите действие:

  0) 🔧 Сменить IP сервера (сейчас: 192.168.1.1)
  1) 🧪 Определить режим ТСПУ
  2) 📡 Проверить активность ТСПУ (curl)
  3) 🔍 Проверить доступность портов (TCP)
  4) 🎭 Проверить SNI-фильтрацию (L7)
  5) 📦 Проверить UDP-порты
  6) 🌐 Проверить внешние DNS
  7) 🚀 Запустить веб-сервер на 443
  8) 🖥️  Полная проверка сервера
  9) 📊 Детальный анализ портов
  10) 🌍 Определить ваш IP
  11) 🔬 Расширенная диагностика блокировок
  12) 🔍 Проверить Split DNS/утечку
  q) ❌ Выход

Ваш выбор: 
```

[🔬] Диагностика 4 слоёв блокировок (пункт 11)
```bash
=======================================
     ТСПУ Диагностический инструмент    
              v1.0                      
========================================

🎯 Текущий целевой сервер: 192.168.1.1

[11] Расширенная диагностика блокировок (4 слоя)

--- Белый список (контрольная группа) ---

Проверка: Яндекс (ya.ru)
  DNS системный: OK → 5.255.255.242
  DNS DoH (1.1.1.1): OK → 77.88.44.242
  TCP порт 443: ОТКРЫТ

--- Чёрный список (заблокированные ресурсы) ---

Проверка: Twitter (twitter.com)
  DNS системный: OK → 172.66.0.227
  DNS DoH (1.1.1.1): OK → 162.159.140.229
  TCP порт 443: ОТКРЫТ
  TLS Handshake: УСПЕШНО

Нажмите Enter для продолжения...
```
##### [📁] Конфигурация
Скрипт сохраняет настройки в файл:
```bash
~/.config/tspu_checker/server.conf
```
Содержимое файла:
```bash
SERVER_IP="192.168.1.1"
```
###### [🔧] Устранение неполадок
```bash
Ошибка: nc: command not found
```
```bash
sudo apt install netcat-openbsd
```
Ошибка: hping3: command not found

```bash
sudo apt install hping3
```
Меню не отображается или битые символы

```bash
reset
export TERM=xterm-256color
./tspu_check.sh
```
Ошибка: dig: command not found

```bash
sudo apt install dnsutils
```
[🤝] Как внести вклад

1. Форкните репозиторий
2. Создайте ветку (git checkout -b feature/AmazingFeature)
3. Закоммитьте изменения (git commit -m 'Add some AmazingFeature')
4. Запушьте ветку (git push origin feature/AmazingFeature)
5. Откройте Pull Request

[📄] Лицензия
MIT License — свободное использование, модификация и распространение.
Подробнее в файле LICENSE.

[📧] Контакты
Автор: ku78
Проект на GitHub: github.com/ku78/tspu-checker

[⭐] Если проект полезен
Поставьте звезду на GitHub — это поможет другим найти инструмент.
