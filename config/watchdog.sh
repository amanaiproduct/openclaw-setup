#!/bin/bash
# OpenClaw Gateway Watchdog
# Checks gateway AND channel-level health, restarts if degraded.
#
# Why channel-level checks matter:
# The gateway process can stay alive (launchd KeepAlive sees it as healthy)
# while a channel inside it dies — e.g. WhatsApp WebSocket timeout.
# A simple curl to /health won't catch this. `openclaw health` checks
# each channel's actual connection state.
#
# Supports multiple profiles (e.g. main + a Slack-only profile).
# Runs via LaunchAgent/systemd every 2 minutes.

CLI="/opt/homebrew/bin/openclaw"
LOG_FILE="/tmp/openclaw/watchdog.log"
LOCK_FILE="/tmp/openclaw-watchdog.lock"

# Set to your phone number for WhatsApp notifications, or leave empty to skip
NOTIFY_PHONE=""

mkdir -p /tmp/openclaw

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG_FILE"
}

# Rotate log if > 1MB
if [ -f "$LOG_FILE" ] && [ "$(stat -f%z "$LOG_FILE" 2>/dev/null || stat -c%s "$LOG_FILE" 2>/dev/null || echo 0)" -gt 1048576 ]; then
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

release_lock() {
    rm -f "$LOCK_FILE"
}

trap release_lock EXIT
acquire_lock

# Check channel-level health using `openclaw health`.
# Returns "ok" if all channels are healthy, or a failure reason string.
check_channel_health() {
    local profile_flag="$1"
    local health_output

    health_output=$($CLI $profile_flag health 2>&1)

    if [ $? -ne 0 ]; then
        echo "health_cmd_failed"
        return 1
    fi

    if echo "$health_output" | grep -qi "whatsapp.*failed\|whatsapp.*error\|whatsapp.*disconnected\|whatsapp.*timeout"; then
        echo "whatsapp_down"
        return 1
    fi

    if echo "$health_output" | grep -qi "slack.*failed\|slack.*error\|slack.*disconnected\|slack.*timeout"; then
        echo "slack_down"
        return 1
    fi

    if echo "$health_output" | grep -qi "telegram.*failed\|telegram.*error\|telegram.*disconnected"; then
        echo "telegram_down"
        return 1
    fi

    if echo "$health_output" | grep -qi "discord.*failed\|discord.*error\|discord.*disconnected"; then
        echo "discord_down"
        return 1
    fi

    echo "ok"
    return 0
}

restart_profile() {
    local profile_flag="$1"
    local label="$2"

    log "Restarting $label gateway..."

    # Stop cleanly
    $CLI $profile_flag gateway stop 2>/dev/null || true
    sleep 3

    # Reinstall to pick up any entrypoint changes (common after updates)
    $CLI $profile_flag gateway install 2>/dev/null
    sleep 8

    local result
    result=$(check_channel_health "$profile_flag")
    if [ "$result" = "ok" ]; then
        log "$label gateway restarted successfully (channels healthy)"
        return 0
    else
        log "$label gateway restarted but channels degraded: $result"
        return 1
    fi
}

send_notification() {
    local message="$1"
    [ -z "$NOTIFY_PHONE" ] && return 0
    $CLI message send \
        --channel whatsapp \
        --to "$NOTIFY_PHONE" \
        --message "$message" 2>/dev/null || log "Failed to send notification: $message"
}

check_and_fix_profile() {
    local profile_flag="$1"  # "" for main, "--profile <name>" for others
    local label="$2"

    local result
    result=$(check_channel_health "$profile_flag")

    if [ "$result" = "ok" ]; then
        return 0
    fi

    log "$label health check failed: $result"

    if restart_profile "$profile_flag" "$label"; then
        send_notification "[watchdog] $label gateway was degraded ($result) and auto-restarted at $(date '+%H:%M')"
    else
        send_notification "[watchdog] $label gateway is degraded ($result) and failed to auto-recover. Manual intervention needed."
    fi
}

main() {
    # Check the default profile
    check_and_fix_profile "" "main"

    # Add additional profiles here, e.g.:
    # check_and_fix_profile "--profile my-slack" "my-slack"
}

main
