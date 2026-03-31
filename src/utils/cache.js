/**
 * FintechStocks Cache Reader
 * Reads market data snapshots from Desktop
 * Cache location: C:\Users\Vignesh\Desktop\fintechstocks
 */

const fs   = require("fs");
const path = require("path");

// ✅ Desktop path (WSL)
const CACHE_DIR = "/mnt/c/Users/Vignesh/Desktop/fintechstocks";

const DATA_DIR   = path.join(CACHE_DIR, "market-data");
const STATE_FILE = path.join(CACHE_DIR, "last-sync.json");

/**
 * Get last sync state
 */
function getLastSyncState() {
  if (!fs.existsSync(STATE_FILE)) return null;
  try {
    return JSON.parse(fs.readFileSync(STATE_FILE, "utf8"));
  } catch {
    return null;
  }
}

/**
 * Get most recent market snapshot from cache
 */
function getLatestSnapshot() {
  const today = new Date().toISOString().slice(0, 10);
  const dayDir = path.join(DATA_DIR, today);
  if (!fs.existsSync(dayDir)) return null;

  const files = fs.readdirSync(dayDir)
    .filter(f => f.startsWith("snapshot_"))
    .sort()
    .reverse();

  if (!files.length) return null;

  const latest = path.join(dayDir, files[0]);
  try {
    return JSON.parse(fs.readFileSync(latest, "utf8"));
  } catch {
    return null;
  }
}

/**
 * Get most recent portfolio from cache
 */
function getLatestPortfolio() {
  const today = new Date().toISOString().slice(0, 10);
  const dayDir = path.join(DATA_DIR, today);
  if (!fs.existsSync(dayDir)) return null;

  const files = fs.readdirSync(dayDir)
    .filter(f => f.startsWith("portfolio_"))
    .sort()
    .reverse();

  if (!files.length) return null;

  const latest = path.join(dayDir, files[0]);
  try {
    return JSON.parse(fs.readFileSync(latest, "utf8"));
  } catch {
    return null;
  }
}

/**
 * List all cached dates
 */
function listCachedDates() {
  if (!fs.existsSync(DATA_DIR)) return [];
  return fs.readdirSync(DATA_DIR)
    .filter(f => fs.statSync(path.join(DATA_DIR, f)).isDirectory())
    .sort()
    .reverse();
}

module.exports = {
  CACHE_DIR,
  DATA_DIR,
  getLastSyncState,
  getLatestSnapshot,
  getLatestPortfolio,
  listCachedDates,
};