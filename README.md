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

```bash
sudo apt update
sudo apt install -y hping3 nmap netcat-openbsd openssl dnsutils curl
