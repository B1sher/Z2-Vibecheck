#!/bin/sh
# Health check + backoff

STATE_DIR="$VAR_DIR/state"
FAIL_COUNT_FILE="$STATE_DIR/fail-count"
PAUSE_UNTIL_FILE="$STATE_DIR/pause-until"

init_state() {
    mkdir -p "$STATE_DIR"
    [ -f "$FAIL_COUNT_FILE" ] || echo "0" > "$FAIL_COUNT_FILE"
    [ -f "$PAUSE_UNTIL_FILE" ] || echo "0" > "$PAUSE_UNTIL_FILE"
}

get_fail_count() {
    cat "$FAIL_COUNT_FILE" 2>/dev/null || echo "0"
}

set_fail_count() {
    echo "$1" > "$FAIL_COUNT_FILE"
}

reset_fail_count() {
    echo "0" > "$FAIL_COUNT_FILE"
}

get_pause_until() {
    cat "$PAUSE_UNTIL_FILE" 2>/dev/null || echo "0"
}

is_paused() {
    local now=$(date +%s)
    local pause_until=$(get_pause_until)
    [ "$now" -lt "$pause_until" ]
}

get_next_sunday_4am() {
    local now=$(date +%s)
    local day_of_week=$(date +%u)
    local days_until_sunday=$(( (7 - day_of_week) % 7 ))
    if [ $days_until_sunday -eq 0 ]; then
        local current_hour=$(date +%H)
        if [ "$current_hour" -ge 4 ]; then
            days_until_sunday=7
        fi
    fi
    local target_date=$(date -d "+$days_until_sunday days" +%Y-%m-%d 2>/dev/null || date -v+${days_until_sunday}d +%Y-%m-%d 2>/dev/null)
    local target_ts=$(date -d "$target_date 04:00:00" +%s 2>/dev/null || date -j -f "%Y-%m-%d %H:%M:%S" "$target_date 04:00:00" +%s 2>/dev/null)
    echo "$target_ts"
}

set_pause_until_sunday() {
    local ts=$(get_next_sunday_4am)
    echo "$ts" > "$PAUSE_UNTIL_FILE"
}

reset_pause() {
    echo "0" > "$PAUSE_UNTIL_FILE"
}

reset_on_boot() {
    init_state
    reset_fail_count
    reset_pause
}
