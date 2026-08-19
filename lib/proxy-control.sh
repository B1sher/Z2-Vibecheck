#!/bin/sh
PROXY_SERVICES="nikki podkop"
DNS_BACKUP_FILE="${VAR_DIR:-/tmp}/resolv.conf.backup"

detect_proxy() {
    local detected=""
    for name in $PROXY_SERVICES; do
        if [ -x "/etc/init.d/$name" ]; then
            detected="$detected $name"
        fi
    done
    echo "$detected" | sed 's/^ //'
}

is_proxy_running() {
    local proxy="$1"
    [ -z "$proxy" ] && return 1
    if /etc/init.d/$proxy status 2>/dev/null | grep -q '^running'; then
        return 0
    fi
    return 1
}

save_proxy_state() {
    local state_file="${VAR_DIR:-/tmp}/proxy-state"
    local proxies=$(detect_proxy)
    local running=""
    for proxy in $proxies; do
        if is_proxy_running "$proxy"; then
            running="$running $proxy"
        fi
    done
    echo "$running" | sed 's/^ //' > "$state_file"
}

stop_all_proxies() {
    local proxies=$(detect_proxy)
    for proxy in $proxies; do
        if is_proxy_running "$proxy"; then
            /etc/init.d/$proxy stop 2>/dev/null
            sleep 3
        fi
    done
}

restore_proxies() {
    local state_file="${VAR_DIR:-/tmp}/proxy-state"
    if [ ! -f "$state_file" ]; then
        return 0
    fi
    local saved=$(cat "$state_file")
    for proxy in $saved; do
        /etc/init.d/$proxy start 2>/dev/null
        sleep 3
    done
    rm -f "$state_file"
}

backup_dns() {
    if [ -f /etc/resolv.conf ]; then
        cp /etc/resolv.conf "$DNS_BACKUP_FILE"
    fi
}

restore_dns() {
    if [ -f "$DNS_BACKUP_FILE" ]; then
        cp "$DNS_BACKUP_FILE" /etc/resolv.conf
        rm -f "$DNS_BACKUP_FILE"
    else
        printf 'search lan\nnameserver 127.0.0.1\nnameserver ::1\n' > /etc/resolv.conf
    fi
}

apply_test_dns() {
    backup_dns
    printf 'nameserver 8.8.8.8\nnameserver 1.1.1.1\n' > /etc/resolv.conf
}
