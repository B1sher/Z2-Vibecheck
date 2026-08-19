#!/bin/sh
C_RESET='\033[0m'
C_BOLD='\033[1m'
C_RED='\033[31m'
C_GREEN='\033[32m'
C_YELLOW='\033[33m'
C_WHITE='\033[37m'
PURPLE='\033[38;2;139;92;246m'
C_PLAIN='\033[39m'
C_MAGENTA="$PURPLE"

print_green() { printf "${C_GREEN}%s${C_RESET}\n" "$1"; }
print_red() { printf "${C_RED}%s${C_RESET}\n" "$1"; }
print_yellow() { printf "${C_YELLOW}%s${C_RESET}\n" "$1"; }
print_magenta() { printf "${PURPLE}%s${C_RESET}\n" "$1"; }
print_white_bold() { printf "${C_BOLD}${C_WHITE}%s${C_RESET}\n" "$1"; }

spinner() {
    local message="$1"
    local frames="⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏"
    while true; do
        for frame in $frames; do
            printf "\r${C_YELLOW}  %s ${PURPLE}%s${C_RESET} " "$message" "$frame"
            sleep 0.1
        done
    done
}

start_spinner() {
    local message="$1"
    spinner "$message" &
    SPINNER_PID=$!
}

stop_spinner() {
    if [ -n "$SPINNER_PID" ]; then
        kill $SPINNER_PID 2>/dev/null
        wait $SPINNER_PID 2>/dev/null
        SPINNER_PID=""
    fi
    printf "\r\033[K"
}
