#!/bin/bash
# Hermes Gateway Watchdog
# Checks gateway process + log freshness, restarts if degraded.
# Install as a LaunchAgent (macOS) — see ai.hermes.watchdog.plist

CLI="hermes"
LOG_FILE="/tmp/hermes/watchdog.log"
LOCK_FILE="/tmp/hermes-watchdog.lock"
GATEWAY_LOG="$HOME/.hermes/logs/agent.log"

# Max seconds since last log write before considering it stale (2 hours)
STALE_THRESHOLD_SECONDS=7200

mkdir -p /tmp/hermes

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG_FILE"
}

# Rotate log if > 1MB
if [ -f "$LOG_FILE" ] && [ "$(stat -f%z "$LOG_FILE" 2>/dev/null || echo 0)" -gt 1048576 ]; then
    mv "$LOG_FILE" "${LOG_FILE}.old"
fi

acquire_lock() {
    if [ -f "$LOCK_FILE" ]; then
        local old_pid
        old_pid=$(cat "$LOCK_FILE" 2>/dev/null)
        if [ -n "$old_pid" ] && kill -0 "$old_pid" 2>/dev/null; then
            exit 0
        fi
    fi
    echo $$ > "$LOCK_FILE"
}

release_lock() { rm -f "$LOCK_FILE"; }
trap release_lock EXIT
acquire_lock

check_gateway_health() {
    # Check if gateway process is running
    if ! pgrep -f "hermes.*gateway" > /dev/null 2>&1; then
        echo "gateway_not_running"
        return 1
    fi

    # Check via hermes status
    local status_output
    status_output=$($CLI status 2>&1)
    if echo "$status_output" | grep -i "running" | grep -q "Gateway\|gateway"; then
        echo "ok"
        return 0
    fi
    if echo "$status_output" | grep -q "Status:.*running"; then
        echo "ok"
        return 0
    fi

    echo "status_check_failed"
    return 1
}

check_log_freshness() {
    local log_path="$1"
    [ ! -f "$log_path" ] && echo "log_missing" && return 1
    local now last_mod age
    now=$(date +%s)
    last_mod=$(stat -f%m "$log_path" 2>/dev/null || echo 0)
    age=$((now - last_mod))
    if [ "$age" -gt "$STALE_THRESHOLD_SECONDS" ]; then echo "log_stale_${age}s"; return 1; fi
    echo "fresh"; return 0
}

restart_gateway() {
    log "Restarting Hermes gateway..."
    $CLI gateway stop 2>/dev/null || true
    pkill -f "hermes.*gateway" 2>/dev/null || true
    sleep 3
    $CLI gateway start 2>/dev/null || true
    sleep 8
    local result; result=$(check_gateway_health)
    if [ "$result" = "ok" ]; then log "Gateway restarted successfully"; return 0
    else log "Gateway restarted but still degraded: $result"; return 1; fi
}

# Layer 1: gateway health
result=$(check_gateway_health)
if [ "$result" != "ok" ]; then
    log "Health check failed: $result"
    if restart_gateway; then
        log "Auto-recovery succeeded"
    else
        log "Auto-recovery FAILED — manual intervention needed"
    fi
    exit 0
fi

# Layer 2: log freshness (catches silent listener death)
freshness=$(check_log_freshness "$GATEWAY_LOG")
if [ "$freshness" != "fresh" ]; then
    log "Gateway log stale ($freshness) despite healthy status — restarting"
    if restart_gateway; then
        log "Auto-recovery from stale log succeeded"
    else
        log "Auto-recovery from stale log FAILED"
    fi
    exit 0
fi

log "Health check passed (gateway: $result, log: $freshness)"
