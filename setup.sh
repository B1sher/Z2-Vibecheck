#!/bin/sh
# Z2💜Vibecheck — полная установка одной командой

set -e

C_RESET="\033[0m"
C_BOLD="\033[1m"
C_RED="\033[31m"
C_GREEN="\033[32m"
C_YELLOW="\033[33m"
PURPLE="\033[38;2;139;92;246m"

echo ""
printf "${PURPLE}${C_BOLD}"
printf "╔══════════════════════════════════════════════════════════╗\n"
printf "║                    Z2💜VIBECHECK SETUP                    ║\n"
printf "╚══════════════════════════════════════════════════════════╝\n"
printf "${C_RESET}\n"

printf "${YELLOW}[1/5] Скачивание репозитория...${C_RESET}\n"
cd /tmp
wget -q https://github.com/B1sher/Z2-Vibecheck/archive/refs/heads/main.tar.gz -O Z2Vibecheck.tar.gz
tar xzf Z2Vibecheck.tar.gz
printf "${GREEN}  └─ Репозиторий скачан ✓${C_RESET}\n\n"

printf "${YELLOW}[2/5] Установка Z2Vibecheck...${C_RESET}\n"
mkdir -p /opt/Z2Vibecheck
cp -r Z2-Vibecheck-main/Z2Vibecheck.sh /opt/Z2Vibecheck/
cp -r Z2-Vibecheck-main/config /opt/Z2Vibecheck/
cp -r Z2-Vibecheck-main/strategies /opt/Z2Vibecheck/
cp -r Z2-Vibecheck-main/lib /opt/Z2Vibecheck/
chmod +x /opt/Z2Vibecheck/Z2Vibecheck.sh
chmod +x /opt/Z2Vibecheck/lib/*.sh 2>/dev/null
printf "${GREEN}  └─ Файлы скопированы ✓${C_RESET}\n\n"

printf "${YELLOW}[3/5] Установка blockcheckw...${C_RESET}\n"
sh Z2-Vibecheck-main/install/install-blockcheckw.sh > /dev/null 2>&1
printf "${GREEN}  └─ blockcheckw установлен ✓${C_RESET}\n\n"

printf "${YELLOW}[4/5] Копирование files и ipset...${C_RESET}\n"
cp -r Z2-Vibecheck-main/install/files/* /opt/zapret2/files/ 2>/dev/null
cp -r Z2-Vibecheck-main/install/ipset/* /opt/zapret2/ipset/ 2>/dev/null
printf "${GREEN}  └─ files и ipset скопированы ✓${C_RESET}\n\n"

printf "${YELLOW}[5/5] Применение стратегий...${C_RESET}\n"
sh Z2-Vibecheck-main/install/install.sh > /dev/null 2>&1
printf "${GREEN}  └─ Стратегии применены ✓${C_RESET}\n\n"

ln -sf /opt/Z2Vibecheck/Z2Vibecheck.sh /usr/bin/Z2Vibecheck

rm -rf Z2-Vibecheck-main
rm -f Z2Vibecheck.tar.gz

echo ""
printf "${PURPLE}${C_BOLD}"
printf "╔══════════════════════════════════════════════════════════╗\n"
printf "║                    УСТАНОВКА ЗАВЕРШЕНА                    ║\n"
printf "╚══════════════════════════════════════════════════════════╝\n"
printf "${C_RESET}\n\n"

printf "${GREEN}  Запускаю Z2Vibecheck...${C_RESET}\n"
sleep 2
exec /opt/Z2Vibecheck/Z2Vibecheck.sh
