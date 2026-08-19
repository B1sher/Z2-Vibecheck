#!/bin/sh
# Применение с объединением (shell-формат /opt/zapret2/config)

backup_config() {
    local timestamp=$(date +%Y%m%d-%H%M%S)
    cp "$ZAPRET_CONFIG" "$BACKUP_DIR/config-$timestamp"
    echo "$BACKUP_DIR/config-$timestamp"
}

save_last_good() {
    mkdir -p "$LAST_GOOD_DIR"
    cp "$ZAPRET_CONFIG" "$LAST_GOOD_DIR/config"
}

update_ports_in_config() {
    if grep -q "^NFQWS2_PORTS_TCP=" "$ZAPRET_CONFIG"; then
        sed -i "s|^NFQWS2_PORTS_TCP=.*|NFQWS2_PORTS_TCP=\"$NFQWS2_PORTS_TCP\"|" "$ZAPRET_CONFIG"
    else
        echo "NFQWS2_PORTS_TCP=\"$NFQWS2_PORTS_TCP\"" >> "$ZAPRET_CONFIG"
    fi
    if grep -q "^NFQWS2_PORTS_UDP=" "$ZAPRET_CONFIG"; then
        sed -i "s|^NFQWS2_PORTS_UDP=.*|NFQWS2_PORTS_UDP=\"$NFQWS2_PORTS_UDP\"|" "$ZAPRET_CONFIG"
    else
        echo "NFQWS2_PORTS_UDP=\"$NFQWS2_PORTS_UDP\"" >> "$ZAPRET_CONFIG"
    fi
}

merge_opt() {
    local old_opt="$1"
    local new_opt="$2"
    if [ -z "$old_opt" ]; then
        echo "$new_opt"
        return
    fi
    new_opt_clean=$(echo "$new_opt" | sed 's/ --comment=[^ ]*//')
    echo "${old_opt} --new ${new_opt_clean}"
}

apply_nfqws2_opt() {
    local new_opt_file="$1"
    local backup_file=$(backup_config)

    # Читаем текущий NFQWS2_OPT (shell-формат)
    local old_opt=$(grep '^NFQWS2_OPT=' "$ZAPRET_CONFIG" | sed 's/^NFQWS2_OPT="//; s/"$//')

    local new_opt=$(cat "$new_opt_file")

    local merged_opt=$(merge_opt "$old_opt" "$new_opt")

    # Заменяем
    if grep -q '^NFQWS2_OPT=' "$ZAPRET_CONFIG"; then
        sed -i "s|^NFQWS2_OPT=.*|NFQWS2_OPT=\"$merged_opt\"|" "$ZAPRET_CONFIG"
    else
        echo "NFQWS2_OPT=\"$merged_opt\"" >> "$ZAPRET_CONFIG"
    fi

    update_ports_in_config

    $ZAPRET_INIT restart >/dev/null 2>&1
    sleep 5

    if pgrep -f nfqws2 > /dev/null; then
        return 0
    else
        rollback_config "$backup_file"
        return 1
    fi
}

rollback_config() {
    local backup_file="$1"
    if [ -f "$backup_file" ]; then
        cp "$backup_file" "$ZAPRET_CONFIG"
        $ZAPRET_INIT restart >/dev/null 2>&1
        return 0
    fi
    return 1
}

rollback_last_good() {
    if [ -f "$LAST_GOOD_DIR/config" ]; then
        cp "$LAST_GOOD_DIR/config" "$ZAPRET_CONFIG"
        $ZAPRET_INIT restart >/dev/null 2>&1
        return 0
    fi
    return 1
}
