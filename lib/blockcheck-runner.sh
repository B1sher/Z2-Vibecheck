#!/bin/sh
BLOCKCHECKW="/opt/Z2Vibecheck/bin/blockcheckw"
BLOCKCHECKW_WORKERS=64
STRATEGIES_DIR="$VAR_DIR/strategies"

check_blockcheckw() {
    [ -x "$BLOCKCHECKW" ]
}

run_blockcheckw_status() {
    local domains_file="$1"
    local output_file="$2"
    $BLOCKCHECKW --auto status --domain-list "$domains_file" --dns doh > "$output_file" 2>&1
}

run_blockcheckw_scan() {
    local domain="$1"
    local output_file="$2"
    $BLOCKCHECKW -w $BLOCKCHECKW_WORKERS --auto scan -d "$domain" --dns doh --top 33 > "$output_file" 2>&1
}

run_blockcheckw_check() {
    local scan_file="$1"
    local domain="$2"
    local output_file="$3"
    cat "$scan_file" | $BLOCKCHECKW --auto check -d "$domain" --take 5 > "$output_file" 2>&1
}

# Сохранить ТОЛЬКО TLS-стратегии
save_strategies() {
    local domain="$1"
    local scan_file="$2"
    local strategy_file="$STRATEGIES_DIR/strategies-${domain}.txt"

    mkdir -p "$STRATEGIES_DIR"

    # Извлекаем только HTTPS/TLS блоки (после "HTTPS/TLS1.2" и "HTTPS/TLS1.3")
    awk '/Top strategies for HTTPS\/TLS/{flag=1} flag && /nfqws2 --/{print}' "$scan_file" | sed 's/^.*nfqws2 //; s/  *$//' > "$strategy_file"

    # Если TLS пусто — берём все
    if [ ! -s "$strategy_file" ]; then
        grep -A 40 'Top strategies' "$scan_file" | grep 'nfqws2 --' | sed 's/^.*nfqws2 //; s/  *$//' > "$strategy_file"
    fi

    echo "Saved $(wc -l < "$strategy_file") strategies to $strategy_file"
}

get_sni_blocked() {
    local status_file="$1"
    grep -i 'SNI blocked' "$status_file" | awk '$2 == "x" && $1 ~ /\./ {print $1}'
}
