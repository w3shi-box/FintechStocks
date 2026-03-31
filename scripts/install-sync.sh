#!/usr/bin/env bash
# =============================================================================
#  FintechStocks — Auto-Sync Installer
#  Sets up scheduled execution of sync-market-data.sh
#  Cache will be written to: ~/.cache/fintechstocks/
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SYNC_SCRIPT="$SCRIPT_DIR/sync-market-data.sh"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/fintechstocks"
LOG_DIR="$CACHE_DIR/logs"
CRON_TAG="# FintechStocks market sync"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'
BOLD='\033[1m'; RESET='\033[0m'

echo ""
echo -e "${BOLD}${CYAN}📈 FintechStocks — Sync Installer${RESET}"
echo -e "   Cache target: ${YELLOW}${CACHE_DIR}${RESET}"
echo ""

# ── Pre-flight ────────────────────────────────────────────────────────────────
if [ ! -f "$SYNC_SCRIPT" ]; then
  echo "ERROR: sync script not found at $SYNC_SCRIPT"
  exit 1
fi

chmod +x "$SYNC_SCRIPT"
mkdir -p "$LOG_DIR"

# ── Install cron entry ────────────────────────────────────────────────────────
CRON_JOB="*/15 9-16 * * 1-5 /bin/bash \"$SYNC_SCRIPT\" >> \"$LOG_DIR/cron.log\" 2>&1 $CRON_TAG"

# Remove any existing FintechStocks cron entry
(crontab -l 2>/dev/null | grep -v "$CRON_TAG" || true) | crontab -

# Add new entry
(crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -

echo -e "${GREEN}✅ Cron job installed:${RESET}"
echo -e "   ${CYAN}${CRON_JOB}${RESET}"
echo ""
echo -e "   Runs every 15 min on weekdays 09:00–16:00"
echo -e "   Writes to: ${YELLOW}${CACHE_DIR}${RESET}"
echo -e "   Cron log:  ${YELLOW}${LOG_DIR}/cron.log${RESET}"
echo ""
echo -e "To uninstall: ${YELLOW}crontab -e${RESET} and remove the FintechStocks line."
echo ""
