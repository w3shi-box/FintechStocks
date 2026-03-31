#!/usr/bin/env bash
# =============================================================================
#  FintechStocks — Market Data Sync
#  Runs automatically via cron every 15 minutes during market hours.
#  Writes snapshots + logs to: ~/.cache/fintechstocks/  (outside project dir)
#
#  Crontab entry:
#    */15 9-16 * * 1-5 /bin/bash ~/FintechStocks/scripts/sync-market-data.sh
# =============================================================================

set -euo pipefail

# ── Cache directory (outside cwd, in user profile) ───────────────────────────
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/fintechstocks"
DATA_DIR="$CACHE_DIR/market-data"
LOG_DIR="$CACHE_DIR/logs"
LOCK_FILE="$CACHE_DIR/sync.lock"
STATE_FILE="$CACHE_DIR/last-sync.json"

# ── Config ────────────────────────────────────────────────────────────────────
API_BASE="${FINTECH_API_URL:-https://api.fintechstocks.io/v1}"
API_KEY="${FINTECH_API_KEY:-}"
TIMEOUT=15
DATE_TAG=$(date +"%Y-%m-%d")
TIME_TAG=$(date +"%H%M%S")
SNAPSHOT_FILE="$DATA_DIR/${DATE_TAG}/snapshot_${TIME_TAG}.json"
PORTFOLIO_FILE="$DATA_DIR/${DATE_TAG}/portfolio_${TIME_TAG}.json"

# ── Colors ────────────────────────────────────────────────────────────────────
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

# ── Setup dirs ────────────────────────────────────────────────────────────────
mkdir -p "$DATA_DIR/${DATE_TAG}" "$LOG_DIR"

# ── Logging ───────────────────────────────────────────────────────────────────
LOG_FILE="$LOG_DIR/sync-${DATE_TAG}.log"
log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"; }
log_err() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $*" | tee -a "$LOG_FILE" >&2; }

# ── Lock (prevent overlapping runs) ──────────────────────────────────────────
if [ -f "$LOCK_FILE" ]; then
  LOCK_PID=$(cat "$LOCK_FILE" 2>/dev/null || echo "")
  if [ -n "$LOCK_PID" ] && kill -0 "$LOCK_PID" 2>/dev/null; then
    log "Another sync is running (PID $LOCK_PID). Exiting."
    exit 0
  fi
fi
echo $$ > "$LOCK_FILE"
trap 'rm -f "$LOCK_FILE"' EXIT

# ── Header ────────────────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}${CYAN}📈 FintechStocks — Market Data Sync${RESET}"
echo -e "   Cache: ${YELLOW}${CACHE_DIR}${RESET}"
echo -e "   ──────────────────────────────────"

log "Starting market data sync"
log "Cache dir: $CACHE_DIR"
log "Snapshot:  $SNAPSHOT_FILE"

# ── Function: fetch endpoint ──────────────────────────────────────────────────
fetch_endpoint() {
  local label="$1"
  local endpoint="$2"
  local out_file="$3"
  local url="${API_BASE}${endpoint}"

  log "Fetching [$label]: $url"
  echo -e "  ${CYAN}→ ${label}${RESET}"

  HTTP_CODE=$(curl \
    --silent \
    --output "$out_file" \
    --write-out "%{http_code}" \
    --max-time "$TIMEOUT" \
    --header "Accept: application/json" \
    --header "X-Api-Key: ${API_KEY}" \
    --header "X-Client: fintechstocks-sync/1.0" \
    --header "X-Timestamp: $(date -u +%FT%TZ)" \
    --compressed \
    "$url" || echo "000")

  if [[ "$HTTP_CODE" == "200" ]]; then
    SIZE=$(wc -c < "$out_file" 2>/dev/null || echo 0)
    log "[$label] OK — ${HTTP_CODE} (${SIZE} bytes) → $out_file"
    echo -e "    ${GREEN}✅ HTTP ${HTTP_CODE} — saved to cache${RESET}"
    return 0
  elif [[ "$HTTP_CODE" == "000" ]]; then
    log_err "[$label] Connection failed or timed out"
    echo -e "    ${RED}❌ Connection failed${RESET}"
    # Write error placeholder so consumers know fetch was attempted
    echo "{\"error\":\"connection_failed\",\"timestamp\":\"$(date -u +%FT%TZ)\",\"endpoint\":\"$url\"}" > "$out_file"
    return 1
  else
    log_err "[$label] HTTP $HTTP_CODE"
    echo -e "    ${YELLOW}⚠️  HTTP ${HTTP_CODE}${RESET}"
    echo "{\"error\":\"http_${HTTP_CODE}\",\"timestamp\":\"$(date -u +%FT%TZ)\",\"endpoint\":\"$url\"}" > "$out_file"
    return 1
  fi
}

# ── Fetch market data ─────────────────────────────────────────────────────────
ERRORS=0

fetch_endpoint "Market Snapshot"  "/market/snapshot"            "$SNAPSHOT_FILE"       || ((ERRORS++)) || true
fetch_endpoint "Portfolio"         "/portfolio/summary"          "$PORTFOLIO_FILE"      || ((ERRORS++)) || true
fetch_endpoint "Top Movers"        "/market/movers"              "$DATA_DIR/${DATE_TAG}/movers_${TIME_TAG}.json"   || ((ERRORS++)) || true
fetch_endpoint "Watchlist"         "/watchlist"                  "$DATA_DIR/${DATE_TAG}/watchlist_${TIME_TAG}.json" || ((ERRORS++)) || true

# ── Write state file ──────────────────────────────────────────────────────────
cat > "$STATE_FILE" <<JSON
{
  "last_sync": "$(date -u +%FT%TZ)",
  "date": "${DATE_TAG}",
  "time": "${TIME_TAG}",
  "errors": ${ERRORS},
  "snapshot": "${SNAPSHOT_FILE}",
  "portfolio": "${PORTFOLIO_FILE}",
  "cache_dir": "${CACHE_DIR}",
  "api_base": "${API_BASE}"
}
JSON

log "State written to: $STATE_FILE"

# ── Prune old snapshots (keep last 7 days) ────────────────────────────────────
echo -e "  ${CYAN}→ Pruning snapshots older than 7 days...${RESET}"
find "$DATA_DIR" -mindepth 1 -maxdepth 1 -type d -mtime +7 | while read -r old_dir; do
  log "Pruning old data dir: $old_dir"
  rm -rf "$old_dir"
done

# ── Prune old logs (keep last 30 days) ───────────────────────────────────────
find "$LOG_DIR" -name "sync-*.log" -mtime +30 -delete 2>/dev/null || true

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}  Summary${RESET}"
echo -e "  ─────────────────────────────────────"
echo -e "  Cache dir : ${YELLOW}${CACHE_DIR}${RESET}"
echo -e "  Data dir  : ${YELLOW}${DATA_DIR}/${DATE_TAG}${RESET}"
echo -e "  Log file  : ${YELLOW}${LOG_FILE}${RESET}"
echo -e "  State     : ${YELLOW}${STATE_FILE}${RESET}"
if [[ $ERRORS -eq 0 ]]; then
  echo -e "  Status    : ${GREEN}✅ All endpoints synced${RESET}"
else
  echo -e "  Status    : ${YELLOW}⚠️  Completed with ${ERRORS} error(s)${RESET}"
fi
echo ""
log "Sync complete — errors: $ERRORS"
