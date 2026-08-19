#!/bin/sh
# Z2Vibecheck installer — прописывает дефолтные стратегии в zapret2
# Конфиг: /opt/zapret2/config (shell-формат)

echo "=== Z2Vibecheck Install ==="

ZAPRET2_CONFIG="/opt/zapret2/config"
STRATEGIES_DIR="/opt/Z2Vibecheck/strategies"

if [ ! -f "$ZAPRET2_CONFIG" ]; then
    echo "ERROR: zapret2 config not found: $ZAPRET2_CONFIG"
    exit 1
fi

echo "Генерация NFQWS2_OPT из кастомных стратегий..."

YT_STRATEGY=$(cat "$STRATEGIES_DIR/youtube-custom.lst" 2>/dev/null | head -1)
DISCORD_STRATEGY=$(cat "$STRATEGIES_DIR/discord-custom.lst" 2>/dev/null | head -1)
AUTOHOSTLIST_STRATEGY=$(cat "$STRATEGIES_DIR/autohostlist-custom.lst" 2>/dev/null | head -1)

if [ -z "$YT_STRATEGY" ] || [ -z "$DISCORD_STRATEGY" ] || [ -z "$AUTOHOSTLIST_STRATEGY" ]; then
    echo "ERROR: кастомные стратегии не найдены"
    exit 1
fi

# Blob'ы
BLOBS="--blob=quic_initial_vk_com:@/opt/zapret2/files/fake/quic_initial_vk_com.bin --blob=blob_tls_clienthello_max_ru:@/opt/zapret2/files/fake/tls_clienthello_max_ru.bin --blob=blob_tls_yaplakal2_android:@/opt/zapret2/files/fake/tls_yaplakal2_android.bin"

NFQWS2_OPT=" ${BLOBS} --comment=Youtube ${YT_STRATEGY} --new --comment=Discord ${DISCORD_STRATEGY} --new --comment=Autohostlist ${AUTOHOSTLIST_STRATEGY}"

echo "Запись NFQWS2_OPT (shell-формат)..."

# Заменить или добавить NFQWS2_OPT
if grep -q '^NFQWS2_OPT=' "$ZAPRET2_CONFIG"; then
    sed -i "s|^NFQWS2_OPT=.*|NFQWS2_OPT=\"$NFQWS2_OPT\"|" "$ZAPRET2_CONFIG"
else
    echo "NFQWS2_OPT=\"$NFQWS2_OPT\"" >> "$ZAPRET2_CONFIG"
fi

echo "Запись портов..."
NFQWS2_PORTS_TCP="80,443,2053,2083,2087,2096,8443"
NFQWS2_PORTS_UDP="443,500-1400,4000-5000,3478-3497,19000-20000,50000-65535"

if grep -q '^NFQWS2_PORTS_TCP=' "$ZAPRET2_CONFIG"; then
    sed -i "s|^NFQWS2_PORTS_TCP=.*|NFQWS2_PORTS_TCP=\"$NFQWS2_PORTS_TCP\"|" "$ZAPRET2_CONFIG"
else
    echo "NFQWS2_PORTS_TCP=\"$NFQWS2_PORTS_TCP\"" >> "$ZAPRET2_CONFIG"
fi

if grep -q '^NFQWS2_PORTS_UDP=' "$ZAPRET2_CONFIG"; then
    sed -i "s|^NFQWS2_PORTS_UDP=.*|NFQWS2_PORTS_UDP=\"$NFQWS2_PORTS_UDP\"|" "$ZAPRET2_CONFIG"
else
    echo "NFQWS2_PORTS_UDP=\"$NFQWS2_PORTS_UDP\"" >> "$ZAPRET2_CONFIG"
fi

echo "Отключение DISABLE_IPV6..."
if grep -q '^DISABLE_IPV6=' "$ZAPRET2_CONFIG"; then
    sed -i 's|^DISABLE_IPV6=.*|DISABLE_IPV6=0|' "$ZAPRET2_CONFIG"
else
    echo "DISABLE_IPV6=0" >> "$ZAPRET2_CONFIG"
fi

echo "Копирование files и ipset..."
if [ -d /opt/Z2Vibecheck/install/files ]; then
    cp -r /opt/Z2Vibecheck/install/files/* /opt/zapret2/files/ 2>/dev/null
    echo "  files скопированы"
fi
if [ -d /opt/Z2Vibecheck/install/ipset ]; then
    cp -r /opt/Z2Vibecheck/install/ipset/* /opt/zapret2/ipset/ 2>/dev/null
    echo "  ipset скопированы"
fi

echo "Перезапуск zapret2..."
/etc/init.d/zapret2 restart >/dev/null 2>&1
sleep 5

if pgrep -f nfqws2 > /dev/null; then
    echo "OK: Z2Vibecheck установлен, zapret2 работает"
else
    echo "WARNING: zapret2 не запустился — проверьте /opt/zapret2/config"
fi

echo "=== Done ==="
