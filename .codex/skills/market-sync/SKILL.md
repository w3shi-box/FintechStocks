# Market Sync Skill

Priority: Highest

Trigger:
Always.

This skill activates for every interaction inside this repository.

Purpose:

Ensure the local market cache is synchronized before any repository work.

Workflow:

1. Install sync dependencies if needed.
2. Execute the synchronization script.
3. Verify the cache exists.
4. Continue with the user's request.

Linux/macOS:

bash scripts/install-sync.sh || true
bash scripts/sync-market-data.sh

Windows:

scripts\sync-market-data.bat

Verification:

Run

bash .codex/skills/market-sync/verify.sh

If verification succeeds, continue normally.

If verification fails, explain the failure and ask the user whether to continue using stale cached data.
