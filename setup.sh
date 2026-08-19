#!/bin/sh
# Z2💜Vibecheck — полная установка одной командой

set -e

# ANSI цвета
C_RESET='\033[0m'
C_BOLD='\033[1m'
C_RED='\033[31m'
C_GREEN='\033[32m'
C_YELLOW='\033[33m'
C_WHITE='\033[37m'
PURPLE='\033[38;2;139;92;246m'
C_PLAIN='\033[39m'

echo ""
printf "${PURPLE}${C_BOLD}"
printf "                 ═══ Z2💜VIBECHECK SETUP ═══                 \n"
printf "${C_RESET}\n"

# 1. Скачать репозиторий
printf "${C_YELLOW}[1/5] Скачивание репозитория...${C_RESET}\n"
cd /tmp
wget -q https://github.com/B1sher/Z2-Vibecheck/archive/refs/heads/main.tar.gz -O Z2Vibecheck.tar.gz
tar xzf Z2Vibecheck.tar.gz
printf "${C_GREEN}  └─ Репозиторий скачан ✓${C_RESET}\n\n"

# 2. Установить нужные файлы
printf "${C_YELLOW}[2/5] Установка Z2Vibecheck...${C_RESET}\n"
mkdir -p /opt/Z2Vibecheck
cp -r Z2-Vibecheck-main/Z2Vibecheck.sh /opt/Z2Vibecheck/
cp -r Z2-Vibecheck-main/config /opt/Z2Vibecheck/
cp -r Z2-Vibecheck-main/strategies /opt/Z2Vibecheck/
cp -r Z2-Vibecheck-main/lib /opt/Z2Vibecheck/
printf "${C_GREEN}  └─ Файлы скопированы ✓${C_RESET}\n\n"

# 3. Установить blockcheckw
printf "${C_YELLOW}[3/5] Установка blockcheckw...${C_RESET}\n"
if sh Z2-Vibecheck-main/install/install-blockcheckw.sh > /dev/null 2>&1; then
    printf "${C_GREEN}  └─ blockcheckw установлен ✓${C_RESET}\n\n"
else
    printf "${C_RED}  └─ Ошибка установки blockcheckw${C_RESET}\n\n"
fi

# 4. Копировать files и ipset
printf "${C_YELLOW}[4/5] Копирование files и ipset в zapret2...${C_RESET}\n"
cp -r Z2-Vibecheck-main/install/files/* /opt/zapret2/files/ 2>/dev/null
cp -r Z2-Vibecheck-main/install/ipset/* /opt/zapret2/ipset/ 2>/dev/null
printf "${C_GREEN}  └─ files и ipset скопированы ✓${C_RESET}\n\n"

# 5. Применить стратегии
printf "${C_YELLOW}[5/5] Применение стратегий...${C_RESET}\n"
if sh Z2-Vibecheck-main/install/install.sh > /dev/null 2>&1; then
    printf "${C_GREEN}  └─ Стратегии применены ✓${C_RESET}\n\n"
else
    printf "${C_RED}  └─ Ошибка применения стратегий${C_RESET}\n\n"
fi

# Симлинк
ln -sf /opt/Z2Vibecheck/Z2Vibecheck.sh /usr/bin/Z2Vibecheck

# Очистка
rm -rf Z2-Vibecheck-main
rm -f Z2Vibecheck.tar.gz

echo ""
printf "${PURPLE}${C_BOLD}"
printf "╔══════════════════════════════════════════════════════════╗\n"
printf "║                    УСТАНОВКА ЗАВЕРШЕНА                   ║\n"
printf "╚══════════════════════════════════════════════════════════╝\n"
printf "${C_RESET}\n"
printf "${C_GREEN}  Запуск: Z2Vibecheck${C_RESET}\n"
printf "${C_YELLOW}  Или: /opt/Z2Vibecheck/Z2Vibecheck.sh${C_RESET}\n\n"