import React, { useEffect, useState } from "react";
import { getMarketData, getSyncStatus } from "./services/stockService";

function App() {
  const [market, setMarket] = useState(null);
  const [syncStatus, setSyncStatus] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    setSyncStatus(getSyncStatus());
    getMarketData()
      .then(({ source, data }) => setMarket({ source, data }))
      .catch(console.error)
      .finally(() => setLoading(false));
  }, []);

  return (
    <div className="app">
      <header>
        <h1>📈 FintechStocks</h1>
        {syncStatus && (
          <div className="sync-badge">
            {syncStatus.synced
              ? `Last sync: ${syncStatus.ageMinutes}m ago${syncStatus.stale ? " ⚠️" : " ✅"}`
              : syncStatus.message}
          </div>
        )}
      </header>

      <main>
        {loading && <p>Loading market data…</p>}
        {market && (
          <section>
            <p>Source: <code>{market.source}</code></p>
            <pre>{JSON.stringify(market.data, null, 2)}</pre>
          </section>
        )}
      </main>
    </div>
  );
}

export default App;
