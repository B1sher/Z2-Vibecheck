#!/bin/sh
# Z2Vibecheck — Автоматический подбор стратегий Zapret2

AUTOTEST_DIR="/opt/Z2Vibecheck"
CONFIG_FILE="$AUTOTEST_DIR/config"

if [ -f "$CONFIG_FILE" ]; then
    . "$CONFIG_FILE"
else
    echo "ERROR: config not found: $CONFIG_FILE"
    exit 1
fi

. "$AUTOTEST_DIR/lib/colors.sh" 2>/dev/null
. "$AUTOTEST_DIR/lib/generator.sh" 2>/dev/null
. "$AUTOTEST_DIR/lib/apply.sh" 2>/dev/null
. "$AUTOTEST_DIR/lib/health-check.sh" 2>/dev/null
. "$AUTOTEST_DIR/lib/proxy-control.sh" 2>/dev/null
. "$AUTOTEST_DIR/lib/test-strategies.sh" 2>/dev/null
. "$AUTOTEST_DIR/lib/blockcheck-runner.sh" 2>/dev/null

# Стандартные и кастомные домены
STANDARD_DOMAINS_FILE="$AUTOTEST_DIR/lib/domains/domains.default.conf"
CUSTOM_DOMAINS_FILE="$AUTOTEST_DIR/lib/domains/domains.custom.conf"

init_standard_domains() {
    if [ ! -f "$STANDARD_DOMAINS_FILE" ]; then
        cat > "$STANDARD_DOMAINS_FILE" << 'STDDOMAINS'
youtube.com
gateway.discord.gg
discord.com
cloudflare-ech.com
rutracker.org
github.com
githubusercontent.com
STDDOMAINS
    fi
    [ -f "$CUSTOM_DOMAINS_FILE" ] || touch "$CUSTOM_DOMAINS_FILE"
}

regenerate_domains() {
    cat "$STANDARD_DOMAINS_FILE" "$CUSTOM_DOMAINS_FILE" > "$DOMAINS_FILE"
}

init_dirs() {
    mkdir -p "$BACKUP_DIR" "$LAST_GOOD_DIR" "$RESULTS_DIR" "$STRATEGIES_DIR" "$LOG_DIR" "$VAR_DIR/state" "$AUTOTEST_DIR/bin"
    export VAR_DIR="$VAR_DIR"
}

log() {
    local msg="$1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') $msg" >> "$LOG_FILE"
}

get_last_scan_date() {
    if [ -f "$RESULTS_DIR/last-scan-date" ]; then
        cat "$RESULTS_DIR/last-scan-date"
    else
        echo "никогда"
    fi
}

get_last_backup_date() {
    ls -t "$BACKUP_DIR" 2>/dev/null | head -1 | sed 's/config-//' | cut -c1-8
}

show_menu() {
    clear 2>/dev/null || true

    local last_scan=$(get_last_scan_date)
    local last_backup=$(get_last_backup_date)
    [ -z "$last_backup" ] && last_backup="нет бекапов"

    local schedule="выключено"
    if crontab -l 2>/dev/null | grep -q "0 4 \* \* \*"; then
        schedule="ежедневно"
    elif crontab -l 2>/dev/null | grep -q "0 4 \* \* 1"; then
        schedule="еженедельно"
    fi

    printf "${C_MAGENTA}${C_BOLD}"
    
    printf "                   ═══ Z2💜VIBECHECK ═══                    \n"
    printf "╔══════════════════════════════════════════════════════════╗\n"
    printf "║            Автоматический подбор стратегий               ║\n"
    printf "║          на основе blockcheck2 (blockcheckw)             ║\n"
    printf "╚══════════════════════════════════════════════════════════╝\n"
    printf "${C_RESET}"

    printf "${C_GREEN}   Дата последнего сканирования: %s${C_RESET}\n\n" "$last_scan"

    printf "${C_MAGENTA}${C_BOLD}   1. Запустить автопоиск${C_RESET}\n"
    printf "${C_YELLOW}   2. Проверка доступности адресов${C_RESET}\n"
    printf "${C_YELLOW}   3. Настроить адреса теста${C_RESET}\n"
    printf "${C_YELLOW}   4. Показать лучшие рабочие стратегии (%s)${C_RESET}\n" "$last_scan"
    printf "${C_YELLOW}   5. Вернуть бекап предыдущих стратегий (%s)${C_RESET}\n" "$last_backup"
    printf "${C_YELLOW}   6. Установить расписание (%s)${C_RESET}\n" "$schedule"
    printf "${C_WHITE}${C_BOLD}   7. Выход${C_RESET}\n\n"

    printf "${C_YELLOW}   Выберите пункт: ${C_RESET}"
}

check_domains_visual() {
    printf "\n${C_YELLOW}═══ Проверка доступности адресов ═══${C_RESET}\n\n"

    local total=0
    local ok=0

    while IFS= read -r domain; do
        case "$domain" in
            '#'*|'') continue ;;
        esac

        total=$((total + 1))
        printf "${C_PLAIN}  %s... ${C_RESET}" "$domain"

        local code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 8 --tlsv1.3 "https://$domain" 2>/dev/null)

        case "$code" in
            200|301|302|403|404)
                printf "${C_GREEN}OK (HTTP %s)${C_RESET}\n" "$code"
                ok=$((ok + 1))
                ;;
            *)
                printf "${C_RED}FAIL (HTTP %s)${C_RESET}\n" "$code"
                ;;
        esac
    done < "$DOMAINS_FILE"

    printf "\n${C_YELLOW}  Итог: ${ok}/${total} доступны${C_RESET}\n\n"
}

show_search_mode_menu() {
    clear 2>/dev/null || true

    printf "${C_MAGENTA}${C_BOLD}"
    printf "╔══════════════════════════════════════════════════════════╗\n"
    printf "║                    РЕЖИМ АВТОПОИСКА                      ║\n"
    printf "╚══════════════════════════════════════════════════════════╝\n"
    printf "${C_RESET}\n"

    printf "${C_MAGENTA}${C_BOLD}   1. Полная проверка${C_RESET}\n"
    printf "${C_YELLOW}   2. Только YouTube${C_RESET}\n"
    printf "${C_YELLOW}   3. Только Cloudflare и Rutracker${C_RESET}\n"
    printf "${C_YELLOW}   4. Только Discord${C_RESET}\n"
    printf "${C_YELLOW}   5. Только GitHub${C_RESET}\n"
    printf "${C_YELLOW}   6. Только кастомный список${C_RESET}\n"
    printf "${C_WHITE}${C_BOLD}   7. Назад${C_RESET}\n\n"

    printf "${C_YELLOW}   Выберите режим: ${C_RESET}"
}

show_address_menu() {
    clear 2>/dev/null || true
    printf "${C_MAGENTA}${C_BOLD}"
    printf "╔══════════════════════════════════════════════════════════╗\n"
    printf "║                    НАСТРОЙКА АДРЕСОВ                     ║\n"
    printf "╚══════════════════════════════════════════════════════════╝\n"
    printf "${C_RESET}\n"

    printf "${C_YELLOW}   1. Показать текущий полный список${C_RESET}\n"
    printf "${C_YELLOW}   2. Добавить кастомные адреса${C_RESET}\n"
    printf "${C_YELLOW}   3. Удалить кастомные адреса${C_RESET}\n"
    printf "${C_YELLOW}   4. Вернуть только стандартные${C_RESET}\n"
    printf "${C_YELLOW}   5. Показать кастомные адреса${C_RESET}\n"
    printf "${C_WHITE}${C_BOLD}   6. Назад${C_RESET}\n\n"

    printf "${C_YELLOW}   Выберите: ${C_RESET}"
}

manage_addresses() {
    while true; do
        show_address_menu
        choice=""; while [ -z "$choice" ]; do read choice; done

        case "$choice" in
            1)
                printf "\n${C_PLAIN}  Полный список адресов:${C_RESET}\n"
                for d in $(grep -v "^#" "$DOMAINS_FILE" | grep -v "^$"); do
                    printf "${C_MAGENTA}    • %s${C_RESET}\n" "$d"
                done
                printf "\n"
                printf "${C_PLAIN}  Нажмите Enter...${C_RESET}"
                read dummy
                ;;
            2)
                printf "${C_PLAIN}  Введите адрес (Enter для завершения):${C_RESET}\n"
                while true; do
                    printf "${C_YELLOW}  > ${C_RESET}"
                    read new_addr
                    [ -z "$new_addr" ] && break
                    echo "$new_addr" >> "$CUSTOM_DOMAINS_FILE"
                    printf "${C_GREEN}    %s добавлен ✓${C_RESET}\n" "$new_addr"
                done
                regenerate_domains
                ;;
            3)
                printf "${C_PLAIN}  Введите адрес для удаления: ${C_RESET}"
                read del_addr
                if [ -n "$del_addr" ]; then
                    sed -i "/^${del_addr}$/d" "$CUSTOM_DOMAINS_FILE"
                    printf "${C_GREEN}  %s удалён ✓${C_RESET}\n" "$del_addr"
                fi
                regenerate_domains
                ;;
            4)
                rm -f "$CUSTOM_DOMAINS_FILE"
                touch "$CUSTOM_DOMAINS_FILE"
                regenerate_domains
                printf "${C_GREEN}  Оставлены только стандартные ✓${C_RESET}\n"
                ;;
            5)
                printf "\n${C_PLAIN}  Кастомные адреса:${C_RESET}\n"
                if [ -s "$CUSTOM_DOMAINS_FILE" ]; then
                    cat "$CUSTOM_DOMAINS_FILE" | while read d; do
                        printf "${C_MAGENTA}    • %s${C_RESET}\n" "$d"
                    done
                else
                    printf "${C_YELLOW}    Нет кастомных адресов${C_RESET}\n"
                fi
                printf "\n"
                ;;
            6)
                return
                ;;
        esac
    done
}

run_autosearch() {
    # Показываем меню выбора режима
    while true; do
        show_search_mode_menu
        mode=""; while [ -z "$mode" ]; do read mode; done
        case "$mode" in
            1)
                SEARCH_DOMAINS=$(cat "$DOMAINS_FILE" | grep -v '^#' | grep -v '^$' | tr '\n' ' ')
                SEARCH_LABEL="Полная проверка"
                break
                ;;
            2)
                SEARCH_DOMAINS="youtube.com googlevideo.com"
                SEARCH_LABEL="Только YouTube"
                break
                ;;
            3)
                SEARCH_DOMAINS="cloudflare-ech.com rutracker.org"
                SEARCH_LABEL="Cloudflare и Rutracker"
                break
                ;;
            4)
                SEARCH_DOMAINS="discord.com gateway.discord.gg"
                SEARCH_LABEL="Только Discord"
                break
                ;;
            5)
                SEARCH_DOMAINS="github.com githubusercontent.com"
                SEARCH_LABEL="Только GitHub"
                break
                ;;
            6)
                SEARCH_DOMAINS=$(cat "$CUSTOM_DOMAINS_FILE" | grep -v '^#' | grep -v '^$' | tr '\n' ' ')
                SEARCH_LABEL="Кастомный список"
                break
                ;;
            7)
                return
                ;;
            *)
                printf "${C_RED}  Неверный выбор${C_RESET}\n"
                sleep 1
                ;;
        esac
    done

    if [ -z "$SEARCH_DOMAINS" ]; then
        printf "${C_RED}  Список пуст!${C_RESET}\n"
        return
    fi

    local search_file="${TMPDIR:-/tmp}/zapret2-search-domains-$$.txt"
    echo "$SEARCH_DOMAINS" | tr ' ' '\n' > "$search_file"

    printf "\n${C_MAGENTA}${C_BOLD}"
    printf "╔══════════════════════════════════════════════════════════╗\n"
    printf "║                    ЗАПУСК АВТОПОИСКА                     ║\n"
    printf "╚══════════════════════════════════════════════════════════╝\n"
    printf "${C_RESET}\n"
    printf "${C_MAGENTA}  Режим: %s${C_RESET}\n" "$SEARCH_LABEL"
    printf "${C_PLAIN}  Домены: %s${C_RESET}\n\n" "$SEARCH_DOMAINS"

    init_dirs
    init_state

    # Этап 0: Обновление blockcheckw
    printf "${C_YELLOW}[0/6] Обновление blockcheckw${C_RESET}\n"
    if blockcheckw --upgrade > /dev/null 2>&1; then
        printf "${C_GREEN}  └─ blockcheckw обновлён ✓${C_RESET}\n\n"
    else
        printf "${C_YELLOW}  └─ Обновление не удалось, использую имеющийся${C_RESET}\n\n"
    fi

    # Этап 1: Подготовка
    printf "${C_YELLOW}[1/6] Подготовка к тестированию${C_RESET}\n"

    printf "${C_PLAIN}  ├─ Сохранение состояния прокси...${C_RESET}\n"
    save_proxy_state > /dev/null 2>&1

    PROXY_NIKKI_WAS_RUNNING=0
    PROXY_PODKOP_WAS_RUNNING=0
    is_proxy_running "nikki" && PROXY_NIKKI_WAS_RUNNING=1
    is_proxy_running "podkop" && PROXY_PODKOP_WAS_RUNNING=1

    printf "${C_PLAIN}  ├─ Nikki... ${C_RESET}"
    if [ ! -x "/etc/init.d/nikki" ]; then
        printf "${C_PLAIN}не установлен, пропускаю${C_RESET}\n"
    elif is_proxy_running "nikki"; then
        printf "${C_YELLOW}останавливаю... ${C_RESET}"
        /etc/init.d/nikki stop 2>/dev/null
        sleep 3
        if ! is_proxy_running "nikki"; then
            printf "${C_GREEN}остановлен ✓${C_RESET}\n"
        else
            printf "${C_RED}ошибка остановки${C_RESET}\n"
        fi
    else
        printf "${C_PLAIN}выключен, пропускаю${C_RESET}\n"
    fi

    printf "${C_PLAIN}  ├─ Podkop... ${C_RESET}"
    if [ ! -x "/etc/init.d/podkop" ]; then
        printf "${C_PLAIN}не установлен, пропускаю${C_RESET}\n"
    elif is_proxy_running "podkop"; then
        printf "${C_YELLOW}останавливаю... ${C_RESET}"
        /etc/init.d/podkop stop 2>/dev/null
        sleep 3
        if ! is_proxy_running "podkop"; then
            printf "${C_GREEN}остановлен ✓${C_RESET}\n"
        else
            printf "${C_RED}ошибка остановки${C_RESET}\n"
        fi
    else
        printf "${C_PLAIN}выключен, пропускаю${C_RESET}\n"
    fi

    ZAPRET2_WAS_RUNNING=0
    pgrep -f nfqws2 > /dev/null && ZAPRET2_WAS_RUNNING=1

    printf "${C_PLAIN}  ├─ Zapret2... ${C_RESET}"
    if [ ! -x "/etc/init.d/zapret2" ]; then
        printf "${C_PLAIN}не установлен, пропускаю${C_RESET}\n"
    elif [ "$ZAPRET2_WAS_RUNNING" = "1" ]; then
        printf "${C_YELLOW}останавливаю... ${C_RESET}"
        /etc/init.d/zapret2 stop >/dev/null 2>&1
        sleep 3
        killall nfqws2 2>/dev/null
        sleep 1
        if pgrep -f nfqws2 > /dev/null; then
            printf "${C_RED}ошибка остановки${C_RESET}\n"
        else
            printf "${C_GREEN}остановлен ✓${C_RESET}\n"
        fi
    else
        printf "${C_PLAIN}выключен, пропускаю${C_RESET}\n"
    fi

    printf "${C_PLAIN}  ├─ Переключение DNS (8.8.8.8, 1.1.1.1)...${C_RESET}\n"
    backup_dns
    apply_test_dns
    printf "${C_GREEN}  └─ DNS переключён ✓${C_RESET}\n\n"

    # Этап 2: Проверка доступности
    printf "${C_YELLOW}[2/6] Проверка текущей доступности${C_RESET}\n"
    local failed_domains=""
    while IFS= read -r domain; do
        case "$domain" in
            '#'*|'') continue ;;
        esac
        printf "${C_PLAIN}  ├─ %s... ${C_RESET}" "$domain"
        local code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 8 --tlsv1.3 "https://$domain" 2>/dev/null)
        case "$code" in
            200|301|302|403|404)
                printf "${C_GREEN}OK${C_RESET}\n"
                ;;
            *)
                printf "${C_RED}FAIL (HTTP %s)${C_RESET}\n" "$code"
                failed_domains="$failed_domains $domain"
                ;;
        esac
    done < "$search_file"
    if [ -z "$failed_domains" ]; then
        printf "${C_GREEN}  └─ Все домены доступны!${C_RESET}\n\n"
        restore_after_test
        return 0
    fi
    printf "${C_RED}  └─ Недоступны:${failed_domains}${C_RESET}\n\n" 

    # Этап 3: Диагностика
    printf "${C_YELLOW}[3/6] Диагностика блокировок${C_RESET}\n"

    local status_file="$RESULTS_DIR/status-$(date +%Y%m%d-%H%M%S).txt"
    run_blockcheckw_status "$search_file" "$status_file"

    printf "${C_PLAIN}  ├─ Типы блокировок:${C_RESET}\n"
    grep -E 'SNI blocked|IP blocked|DNS failed' "$status_file" | while IFS= read -r line; do
        local d=$(echo "$line" | awk '{print $1}')
        local t=$(echo "$line" | awk '{print $3, $4}')
        case "$t" in
            "SNI blocked")
                printf "${C_MAGENTA}  │   • %s → SNI blocked (обходится zapret2)${C_RESET}\n" "$d"
                ;;
            "IP blocked")
                printf "${C_RED}  │   • %s → IP blocked (нужен VPN)${C_RESET}\n" "$d"
                ;;
            "DNS failed")
                printf "${C_YELLOW}  │   • %s → DNS failed${C_RESET}\n" "$d"
                ;;
        esac
    done

    local sni_blocked=$(get_sni_blocked "$status_file")

    if [ -z "$sni_blocked" ]; then
        printf "${C_YELLOW}  Нет SNI-blocked доменов для обхода${C_RESET}\n\n"
        restore_after_test
        /etc/init.d/zapret2 start 2>/dev/null
        return 0
    fi

    # Этап 4: Поиск стратегий
    printf "${C_YELLOW}[4/6] Поиск стратегий${C_RESET}\n"

    local TOTAL_FOUND=0
    for domain in $sni_blocked; do
        printf "${C_MAGENTA}  ├─ Сканирование: %s${C_RESET}\n" "$domain"

        local scan_file="$RESULTS_DIR/scan-$domain-$(date +%Y%m%d-%H%M%S).txt"

        start_spinner "Поиск стратегий"
        run_blockcheckw_scan "$domain" "$scan_file"
        save_strategies "$domain" "$scan_file"
        stop_spinner

        local count=$(grep -oE 'success: [0-9]+' "$scan_file" | tail -1 | awk '{print $2}')
        [ -z "$count" ] && count=0

        if [ "$count" -gt 0 ]; then
            printf "${C_GREEN}  │   └─ Успешных стратегий: %s ✓${C_RESET}\n" "$count"
            TOTAL_FOUND=$((TOTAL_FOUND + 1))
        else
            printf "${C_RED}  │   └─ Успешных стратегий не найдено${C_RESET}\n"
        fi
    done

    printf "\n${C_YELLOW}  Итог: успешные стратегии найдены для %s доменов${C_RESET}\n\n" "$TOTAL_FOUND"

    # Этап 5: Применение
    if [ "$TOTAL_FOUND" -gt 0 ]; then
        printf "${C_YELLOW}[5/6] Применение стратегий${C_RESET}\n"

        local latest_scan=$(ls -t "$RESULTS_DIR"/scan-youtube.com-*.txt 2>/dev/null | head -1)
        local best_strategy=$(grep -A 5 "Top strategies" "$latest_scan" 2>/dev/null | grep "#1" | head -1 | sed "s/^.*nfqws2 //; s/  *$//")

        if [ -n "$best_strategy" ]; then
            printf "${C_PLAIN}  ├─ Лучшая стратегия: %s${C_RESET}\n" "$best_strategy"

            local new_opt_file="$RESULTS_DIR/new-opt-$(date +%Y%m%d-%H%M%S).txt"
            generate_nfqws2_opt "$new_opt_file" "$best_strategy" ""

            printf "${C_PLAIN}  ├─ Применение конфигурации...${C_RESET}\n"
            if apply_nfqws2_opt "$new_opt_file"; then
                printf "${C_GREEN}  │   └─ Zapret2 перезапущен ✓${C_RESET}\n"

                # Пост-проверка: для каждого домена перебираем его стратегии
                printf "${C_PLAIN}  ├─ Пост-проверка по доменам...${C_RESET}\n"

                local ALL_FOUND=1

                for domain in $sni_blocked; do
                    printf "${C_MAGENTA}  │   ├─ Домен: %s${C_RESET}\n" "$domain"

                    local strategy_file="$VAR_DIR/strategies/strategies-${domain}.txt"
                    if [ ! -f "$strategy_file" ] || [ ! -s "$strategy_file" ]; then
                        printf "${C_RED}  │   │   └─ Нет стратегий, пропускаю${C_RESET}\n"
                        ALL_FOUND=0
                        continue
                    fi

                    local STRATEGY_FOUND=0
                    local attempt=1

                    while [ $attempt -le 33 ]; do
                        local strategy=$(sed -n "${attempt}p" "$strategy_file")
                        [ -z "$strategy" ] && break

                        printf "${C_PLAIN}  │   │   ├─ Стратегия #%s: %s${C_RESET}\n" "$attempt" "$strategy"

                        generate_nfqws2_opt "$new_opt_file" "$strategy" ""
                        if apply_nfqws2_opt "$new_opt_file"; then
                            sleep 3
                            local code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 --tlsv1.3 "https://$domain" 2>/dev/null)
                            case "$code" in
                                200|301|302|403|404)
                                    printf "${C_GREEN}  │   │   └─ %s работает ✓ (стратегия #%s, HTTP %s)${C_RESET}\n" "$domain" "$attempt" "$code"
                                    save_last_good
                                    STRATEGY_FOUND=1
                                    break
                                    ;;
                                *)
                                    printf "${C_YELLOW}  │   │   └─ Стратегия #%s: FAIL (HTTP %s), пробую дальше...${C_RESET}\n" "$attempt" "$code"
                                    ;;
                            esac
                        else
                            printf "${C_RED}  │   │   └─ Стратегия #%s: ошибка применения${C_RESET}\n" "$attempt"
                        fi

                        attempt=$((attempt + 1))
                    done

                    if [ "$STRATEGY_FOUND" = "0" ]; then
                        printf "${C_RED}  │   │   └─ Ни одна из 33 не сработала для %s${C_RESET}\n" "$domain"
                        ALL_FOUND=0
                    fi
                done

                if [ "$ALL_FOUND" = "1" ]; then
                    printf "${C_GREEN}  │   └─ Все домены работают ✓${C_RESET}\n"
                else
                    printf "${C_YELLOW}  │   └─ Часть доменов не удалось обойти${C_RESET}\n"
                fi

        fi
        fi
    fi
    # Этап 6: Восстановление
    printf "${C_YELLOW}[6/6] Восстановление прокси${C_RESET}\n"

    restore_dns
    printf "${C_GREEN}  ├─ DNS восстановлен ✓${C_RESET}\n"

    if [ "$ZAPRET2_WAS_RUNNING" = "1" ]; then
        /etc/init.d/zapret2 start >/dev/null 2>&1
        sleep 3
        if pgrep -f nfqws2 > /dev/null; then
            printf "${C_GREEN}  ├─ Zapret2 запущен ✓${C_RESET}\n"
        fi
    else
        printf "${C_PLAIN}  ├─ Zapret2: был выключен, пропускаю${C_RESET}\n"
    fi

    if [ "$PROXY_NIKKI_WAS_RUNNING" = "1" ]; then
        /etc/init.d/nikki start 2>/dev/null
        sleep 3
        if is_proxy_running "nikki"; then
            printf "${C_GREEN}  ├─ Nikki запущен ✓${C_RESET}\n"
        fi
    else
        printf "${C_PLAIN}  ├─ Nikki: был выключен, пропускаю${C_RESET}\n"
    fi

    if [ "$PROXY_PODKOP_WAS_RUNNING" = "1" ]; then
        /etc/init.d/podkop start 2>/dev/null
        sleep 3
        if is_proxy_running "podkop"; then
            printf "${C_GREEN}  ├─ Podkop запущен ✓${C_RESET}\n"
        fi
    else
        printf "${C_PLAIN}  ├─ Podkop: был выключен, пропускаю${C_RESET}\n"
    fi

    rm -f "$search_file"

    printf "\n${C_MAGENTA}${C_BOLD}"
    printf "╔══════════════════════════════════════════════════════════╗\n"
    printf "║                    АВТОПОИСК ЗАВЕРШЁН                    ║\n"
    printf "╚══════════════════════════════════════════════════════════╝\n"
    printf "${C_RESET}\n"
}

manage_strategies() {
    while true; do
        show_strategies_menu
        choice=""; while [ -z "$choice" ]; do read choice; done
        case "$choice" in
            1) show_strategy_file "youtube.com" ;;
            2) show_strategy_file "discord.com" ;;
            3) show_strategy_file "cloudflare-ech.com" ;;
            4) show_strategy_file "github.com" ;;
            5) show_strategy_file "rutracker.org" ;;
            6) show_strategy_file "autohostlist" ;;
            7) return ;;
        esac
    done
}

show_strategy_file() {
    local domain="$1"
    local file="$VAR_DIR/strategies/strategies-${domain}.txt"
    clear 2>/dev/null || true
    printf "\n${C_MAGENTA}═══ Стратегии: %s ═══${C_RESET}\n\n" "$domain"
    if [ -f "$file" ] && [ -s "$file" ]; then
        cat "$file" | head -20 | while IFS= read -r line; do
            printf "${C_YELLOW}  • %s${C_RESET}\n" "$line"
        done
    else
        printf "${C_RED}  Нет сохранённых стратегий${C_RESET}\n"
    fi
    printf "\n${C_PLAIN}  Нажмите Enter...${C_RESET}"
    read dummy
}


show_strategies_menu() {
    clear 2>/dev/null || true
    printf "${C_MAGENTA}${C_BOLD}"
    printf "╔══════════════════════════════════════════════════════════╗\n"
    printf "║                    СТРАТЕГИИ                             ║\n"
    printf "╚══════════════════════════════════════════════════════════╝\n"
    printf "${C_RESET}\n"
    printf "${C_YELLOW}   1. YouTube${C_RESET}\n"
    printf "${C_YELLOW}   2. Discord${C_RESET}\n"
    printf "${C_YELLOW}   3. Cloudflare${C_RESET}\n"
    printf "${C_YELLOW}   4. GitHub${C_RESET}\n"
    printf "${C_YELLOW}   5. Rutracker${C_RESET}\n"
    printf "${C_YELLOW}   6. Autohostlist (универсальные)${C_RESET}\n"
    printf "${C_WHITE}${C_BOLD}   7. Назад${C_RESET}\n\n"
    printf "${C_YELLOW}   Выберите: ${C_RESET}"
}


manage_schedule() {
    clear 2>/dev/null || true
    printf "\n${C_YELLOW}═══ Расписание ═══${C_RESET}\n\n"

    local current="выключено"
    if crontab -l 2>/dev/null | grep -q "0 4 \* \* \*"; then
        current="ежедневно"
    elif crontab -l 2>/dev/null | grep -q "0 4 \* \* 1"; then
        current="еженедельно"
    fi

    printf "${C_PLAIN}  Текущий режим: ${C_GREEN}%s${C_RESET}\n\n" "$current"

    printf "${C_YELLOW}  1. Ежедневно (в 4:00)${C_RESET}\n"
    printf "${C_YELLOW}  2. Еженедельно (пн 4:00)${C_RESET}\n"
    printf "${C_YELLOW}  3. Выключить${C_RESET}\n"
    printf "${C_WHITE}${C_BOLD}  4. Назад${C_RESET}\n\n"
    printf "${C_YELLOW}  Выберите: ${C_RESET}"
    choice=""; while [ -z "$choice" ]; do read choice; done

    case "$choice" in
        1)
            (crontab -l 2>/dev/null | grep -v 'Z2Vibecheck'; echo "0 4 * * * /opt/Z2Vibecheck/Z2Vibecheck.sh autosearch >> /var/log/Z2Vibecheck-cron.log 2>&1") | crontab -
            printf "${C_GREEN}  Расписание: ежедневно ✓${C_RESET}\n"
            ;;
        2)
            (crontab -l 2>/dev/null | grep -v 'Z2Vibecheck'; echo "0 4 * * 1 /opt/Z2Vibecheck/Z2Vibecheck.sh autosearch >> /var/log/Z2Vibecheck-cron.log 2>&1") | crontab -
            printf "${C_GREEN}  Расписание: еженедельно ✓${C_RESET}\n"
            ;;
        3)
            (crontab -l 2>/dev/null | grep -v 'Z2Vibecheck') | crontab -
            printf "${C_GREEN}  Расписание выключено ✓${C_RESET}\n"
            ;;
        4)
            return
            ;;
    esac
}

cmd_rollback() {
    printf "\n${C_YELLOW}═══ Откат к last-good ═══${C_RESET}\n\n"
    if [ -f "$LAST_GOOD_DIR/config" ]; then
        rollback_last_good
        printf "${C_GREEN}  Откат выполнен ✓${C_RESET}\n"
    else
        printf "${C_RED}  Нет last-good конфига${C_RESET}\n"
    fi
}

# Главный цикл
init_standard_domains
regenerate_domains

while true; do
    show_menu
    choice=""; while [ -z "$choice" ]; do read choice; done

    case "$choice" in
        1)
            run_autosearch
            printf "\n${C_YELLOW}  Нажмите Enter...${C_RESET}"
            read dummy
            ;;
        2)
            check_domains_visual
            printf "\n${C_YELLOW}  Нажмите Enter...${C_RESET}"
            read dummy
            ;;
        3)
            manage_addresses
            ;;
        4)
            manage_strategies
            read dummy
            ;;
        5)
            cmd_rollback
            printf "\n${C_YELLOW}  Нажмите Enter...${C_RESET}"
            read dummy
            ;;
        6)
            manage_schedule
            ;;
        7)
            printf "\n${C_GREEN}  До свидания!${C_RESET}\n"
            exit 0
            ;;
        *)
            printf "${C_RED}  Неверный выбор${C_RESET}\n"
            sleep 1
            ;;
    esac
done
