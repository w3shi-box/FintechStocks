/**
 * FintechStocks API Client
 * Base URL: https://api.fintechstocks.io/v1
 */

const API_BASE = process.env.FINTECH_API_URL || "https://api.fintechstocks.io/v1";
const API_KEY  = process.env.FINTECH_API_KEY  || "";

async function apiFetch(path, options = {}) {
  const url = `${API_BASE}${path}`;
  const res = await fetch(url, {
    headers: {
      "Content-Type": "application/json",
      "Accept": "application/json",
      "X-Api-Key": API_KEY,
      "X-Client": "fintechstocks-js/1.0",
      ...options.headers,
    },
    ...options,
  });
  if (!res.ok) throw new Error(`HTTP ${res.status} — ${url}`);
  return res.json();
}

export const getMarketSnapshot  = () => apiFetch("/market/snapshot");
export const getTopMovers        = () => apiFetch("/market/movers");
export const getPortfolio        = () => apiFetch("/portfolio/summary");
export const getWatchlist        = () => apiFetch("/watchlist");
export const getQuote            = (ticker) => apiFetch(`/quotes/${ticker}`);
export const searchStocks        = (q) => apiFetch(`/search?q=${encodeURIComponent(q)}`);

export { API_BASE };
