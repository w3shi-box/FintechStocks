/**
 * FintechStocks — Stock Service
 * Merges live API data with local cache from ~/.cache/fintechstocks/
 */

import { getMarketSnapshot, getQuote, getTopMovers } from "../api/client";
import { getLatestSnapshot, getLastSyncState } from "../utils/cache";

/**
 * Get market data — tries live API first, falls back to cache.
 */
export async function getMarketData() {
  try {
    const live = await getMarketSnapshot();
    return { source: "live", data: live };
  } catch (err) {
    console.warn("Live API unavailable, reading from cache:", err.message);
    const cached = getLatestSnapshot();
    if (cached) return { source: "cache", data: cached };
    throw new Error("No market data available (API down, cache empty)");
  }
}

/**
 * Get a single stock quote with cache fallback.
 */
export async function getStockQuote(ticker) {
  try {
    return await getQuote(ticker.toUpperCase());
  } catch (err) {
    console.warn(`Quote fetch failed for ${ticker}:`, err.message);
    return null;
  }
}

/**
 * Get sync status from cache state file.
 */
export function getSyncStatus() {
  const state = getLastSyncState();
  if (!state) return { synced: false, message: "Never synced. Run: npm run sync" };
  const lastSync = new Date(state.last_sync);
  const ageMinutes = Math.round((Date.now() - lastSync) / 60000);
  return {
    synced: true,
    lastSync: state.last_sync,
    ageMinutes,
    errors: state.errors,
    cacheDir: state.cache_dir,
    stale: ageMinutes > 20,
  };
}

export { getTopMovers };
