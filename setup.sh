#!/bin/sh
# Z2💜Vibecheck — полная установка одной командой
# Использование:
# curl -fsSL https://raw.githubusercontent.com/B1sher/Z2-Vibecheck/main/setup.sh -o /tmp/setup.sh && sh /tmp/setup.sh

set -e

echo "=== Z2💜Vibecheck Setup ==="

# 1. Скачать репозиторий
echo "[1/3] Скачивание репозитория..."
cd /tmp
wget -q https://github.com/B1sher/Z2-Vibecheck/archive/refs/heads/main.tar.gz -O Z2Vibecheck.tar.gz
tar xzf Z2Vibecheck.tar.gz

# 2. Установить в /opt
echo "[2/3] Установка в /opt/Z2Vibecheck..."
if [ -d /opt/Z2Vibecheck ]; then
    cp -r Z2-Vibecheck-main/* /opt/Z2Vibecheck/
else
    mv Z2-Vibecheck-main /opt/Z2Vibecheck
fi
rm -f Z2Vibecheck.tar.gz

# 3. Установить blockcheckw + применить стратегии
echo "[3/3] Установка blockcheckw и стратегий..."
sh /opt/Z2Vibecheck/install/install-blockcheckw.sh
sh /opt/Z2Vibecheck/install/install.sh

# Симлинк
ln -sf /opt/Z2Vibecheck/Z2Vibecheck.sh /usr/bin/Z2Vibecheck

echo ""
echo "=== Готово! ==="
echo "Запуск: Z2Vibecheck"
