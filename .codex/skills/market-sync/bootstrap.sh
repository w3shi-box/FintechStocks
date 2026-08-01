#!/usr/bin/env bash
set -e

echo "Installing sync environment..."

bash scripts/install-sync.sh || true

echo "Synchronizing market data..."

bash scripts/sync-market-data.sh

echo "Done."
