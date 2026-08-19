#!/bin/sh
# Проверка важных доменов

DISCORD_UPDATE_URL="https://discord.com/api/v9/updates?platform=win32"
CLOUDFLARE_URL="https://cloudflare.com"
GITHUB_URL="https://github.com"
GITHUB_CONTENT_URL="https://githubusercontent.com"

check_discord() {
    local code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 8 --tlsv1.3 "$DISCORD_UPDATE_URL" 2>/dev/null)
    case "$code" in
        200|301|302|401|403|404) return 0 ;;
        *) return 1 ;;
    esac
}

check_cloudflare() {
    local code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 8 --tlsv1.3 "$CLOUDFLARE_URL" 2>/dev/null)
    case "$code" in
        200|301|302|403|404) return 0 ;;
        *) return 1 ;;
    esac
}

check_github() {
    local gh_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 8 --tlsv1.3 "$GITHUB_URL" 2>/dev/null)
    local ghc_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 8 --tlsv1.3 "$GITHUB_CONTENT_URL" 2>/dev/null)
    
    local ok=0
    case "$gh_code" in
        200|301|302|403|404) ok=$((ok + 1)) ;;
    esac
    case "$ghc_code" in
        200|301|302|403|404) ok=$((ok + 1)) ;;
    esac
    
    [ $ok -ge 1 ]
}

check_domain() {
    local domain="$1"
    local code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 8 --tlsv1.3 "https://$domain" 2>/dev/null)
    case "$code" in
        200|301|302|403|404) return 0 ;;
        *) return 1 ;;
    esac
}

check_important_domains() {
    local total=0
    local ok=0
    
    for domain in youtube.com googlevideo.com rutracker.org; do
        total=$((total + 1))
        if check_domain "$domain"; then
            ok=$((ok + 1))
        fi
    done
    
    total=$((total + 1))
    if check_discord; then
        ok=$((ok + 1))
    fi
    
    total=$((total + 1))
    if check_cloudflare; then
        ok=$((ok + 1))
    fi
    
    total=$((total + 1))
    if check_github; then
        ok=$((ok + 1))
    fi
    
    [ $ok -eq $total ]
}
