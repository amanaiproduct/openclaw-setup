#!/bin/bash
# OpenClaw Gateway Watchdog
# Checks health endpoint every 2 minutes, restarts if unresponsive.

GATEWAY_PORT="${OPENCLAW_GATEWAY_PORT:-18789}"
LOG_FILE="/tmp/openclaw-watchdog.log"

check_gateway() {
    curl -sf "http://127.0.0.1:${GATEWAY_PORT}/health" --max-time 5 >/dev/null 2>&1
}

if ! check_gateway; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Gateway down - restarting" >> "$LOG_FILE"
    launchctl kickstart -k gui/$(id -u)/ai.openclaw.gateway
    sleep 5
    if check_gateway; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Restart successful" >> "$LOG_FILE"
    else
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Restart FAILED" >> "$LOG_FILE"
    fi
fi
