#!/bin/sh
# Z2💜Vibecheck — полная установка одной командой

set -e

echo "=== Z2💜Vibecheck Setup ==="

# 1. Скачать репозиторий
echo "[1/4] Скачивание репозитория..."
cd /tmp
wget -q https://github.com/B1sher/Z2-Vibecheck/archive/refs/heads/main.tar.gz -O Z2Vibecheck.tar.gz
tar xzf Z2Vibecheck.tar.gz

# 2. Установить нужные файлы в /opt/Z2Vibecheck
echo "[2/4] Установка Z2Vibecheck..."
mkdir -p /opt/Z2Vibecheck

# Копируем только нужное (без install, README, LICENSE, setup.sh)
cp -r Z2-Vibecheck-main/Z2Vibecheck.sh /opt/Z2Vibecheck/
cp -r Z2-Vibecheck-main/config /opt/Z2Vibecheck/
cp -r Z2-Vibecheck-main/strategies /opt/Z2Vibecheck/
cp -r Z2-Vibecheck-main/lib /opt/Z2Vibecheck/

# 3. Установить blockcheckw
echo "[3/4] Установка blockcheckw..."
sh Z2-Vibecheck-main/install/install-blockcheckw.sh

# 4. Копировать files и ipset в zapret2
echo "[4/4] Копирование files и ipset в zapret2..."
cp -r Z2-Vibecheck-main/install/files/* /opt/zapret2/files/ 2>/dev/null
cp -r Z2-Vibecheck-main/install/ipset/* /opt/zapret2/ipset/ 2>/dev/null

# 5. Применить стратегии
echo "[5/5] Применение стратегий..."
sh Z2-Vibecheck-main/install/install.sh

# 6. Симлинк
ln -sf /opt/Z2Vibecheck/Z2Vibecheck.sh /usr/bin/Z2Vibecheck

# 7. Очистка
rm -rf Z2-Vibecheck-main
rm -f Z2Vibecheck.tar.gz

echo ""
echo "=== Готово! ==="
echo "Запуск: Z2Vibecheck"