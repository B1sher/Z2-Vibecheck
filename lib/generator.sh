#!/bin/sh
# Генерация NFQWS2_OPT с кастомными стратегиями по умолчанию

generate_nfqws2_opt() {
    local output_file="$1"
    local yt_strategy="$2"
    local autohostlist_strategy="$3"

    # Если переданы найденные — используем их, иначе берём кастомные
    if [ -z "$yt_strategy" ]; then
        yt_strategy=$(cat /opt/Z2Vibecheck/strategies/youtube-custom.lst 2>/dev/null | head -1)
    fi
    if [ -z "$autohostlist_strategy" ]; then
        autohostlist_strategy=$(cat /opt/Z2Vibecheck/strategies/autohostlist-custom.lst 2>/dev/null | head -1)
    fi

    # Фолбэк если файлы отсутствуют
    [ -z "$yt_strategy" ] && yt_strategy="--lua-desync=wssize:wsize=1:scale=6 --payload=tls_client_hello --lua-desync=multidisorder:pos=midsld"
    [ -z "$autohostlist_strategy" ] && autohostlist_strategy="--lua-desync=multisplit:pos=1:seqovl=664:seqovl_pattern=blob_tls_yaplakal2_android:strategy=1"

    local opt=""

    # YouTube блок
    opt="${opt} --comment=Youtube"
    opt="${opt} ${yt_strategy}"
    opt="${opt} --new"

    # Discord блок
    opt="${opt} --comment=Discord"
    opt="${opt} $(cat /opt/Z2Vibecheck/strategies/discord-custom.lst 2>/dev/null | head -1)"
    opt="${opt} --new"

    # Cloudflare блок
    opt="${opt} --comment=Cloudflare"
    opt="${opt} --filter-tcp=2053,2083,2087,2096,8443 --filter-l7=tls --hostlist=/opt/zapret2/ipset/zapret-hosts-cloudflare.txt --lua-desync=multisplit:pos=1:seqovl=1:strategy=1"
    opt="${opt} --new"

    # GitHub блок
    opt="${opt} --comment=GitHub"
    opt="${opt} --filter-tcp=443 --filter-l7=tls --hostlist=/opt/zapret2/ipset/zapret-hosts-github.txt --lua-desync=multisplit:pos=1:seqovl=1:strategy=1"
    opt="${opt} --new"

    # Autohostlist блок
    opt="${opt} --comment=Autohostlist"
    opt="${opt} ${autohostlist_strategy}"
    opt="${opt} --new"

    # Кастомные домены
    if [ -f "$CUSTOM_DOMAINS_FILE" ] && [ -s "$CUSTOM_DOMAINS_FILE" ]; then
        while IFS= read -r domain; do
            case "$domain" in
                '#'*|'') continue ;;
            esac
            local comment_name=$(echo "$domain" | tr '.' '_')
            opt="${opt} --comment=Custom_${comment_name}"
            opt="${opt} --filter-tcp=80,443 --filter-l7=tls --hostlist-domains=${domain}"
            opt="${opt} ${autohostlist_strategy}"
            opt="${opt} --new"
        done < "$CUSTOM_DOMAINS_FILE"
    fi

    echo "$opt" > "$output_file"
}
