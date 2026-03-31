# 📈 FintechStocks

> Real-time stock tracking, portfolio analytics, and market alerts platform.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Node](https://img.shields.io/badge/node-%3E%3D18-green)](https://nodejs.org)

---

## 🚀 Quick Start

```bash
git clone https://github.com/your-org/FintechStocks.git
cd FintechStocks
npm install
cp .env.example .env
npm run dev
```

---

## 🗂 Project Structure

```
FintechStocks/
├── .vscode/                  # Editor settings
├── config/                   # App & market config
├── src/
│   ├── api/                  # REST API client (market data)
│   ├── components/           # UI components
│   ├── services/             # Business logic (portfolio, alerts)
│   └── utils/                # Shared helpers
├── scripts/
│   ├── sync-market-data.sh   # Linux/macOS: auto market sync → ~/.cache/fintechstocks/
│   └── sync-market-data.bat  # Windows: auto market sync → %LOCALAPPDATA%\fintechstocks\cache\
├── tests/
└── docs/
```

---

## 📡 Market Data Sync

The sync script runs automatically (via cron / Task Scheduler) and writes snapshots to the user cache directory **outside** the project folder:

| OS | Cache Location |
|---|---|
| Linux/macOS | `~/.cache/fintechstocks/` |
| Windows | `%LOCALAPPDATA%\fintechstocks\cache\` |

### Run manually

```bash
# Linux / macOS
bash scripts/sync-market-data.sh

# Windows
scripts\sync-market-data.bat
```

### Schedule automatically

**Linux/macOS** — add to crontab (`crontab -e`):
```cron
*/15 * * * * /bin/bash /path/to/FintechStocks/scripts/sync-market-data.sh >> ~/.cache/fintechstocks/logs/cron.log 2>&1
```

**Windows** — import the included Task Scheduler XML:
```
schtasks /create /xml scripts\FintechStocks-Sync.xml /tn "FintechStocks\MarketSync"
```

---

## 🛠 Scripts

| Command | Description |
|---|---|
| `npm run dev` | Start dev server |
| `npm run build` | Production build |
| `npm run sync` | Run market data sync manually |
| `npm test` | Run test suite |
| `npm run lint` | Lint source files |

---

## 📄 License

MIT © FintechStocks
