---
description: Verify the post.buzz connection (API key, accounts, quota) and fix what's broken
allowed-tools: mcp__postbuzz
---
# post.buzz setup check

Run the post.buzz first-run diagnostic and fix every failure it reports.

## Steps

1. Call `check_setup`. It verifies the API key, API reachability, connected
   accounts, and quota in one shot.
2. Handle each failing check in order — stop and fix before moving on:
   - **API key missing/invalid**: tell the user to create a key at
     **post.buzz → Settings → API Keys** (`sx_live_…`), then configure it:
     `/config` → plugin **postbuzz** → *post.buzz API key* (or restart the
     session with `POSTBUZZ_API_KEY` exported). Do not retry until they say
     it's set.
   - **API unreachable**: show the exact error; mention
     `POSTBUZZ_API_URL`/`api_url` config only if the user is on staging or
     self-hosting.
   - **No connected accounts**: run `list_accounts`; if still empty, ask which
     platforms they want, then call `connect_account` per platform and give
     them each OAuth URL to open in a browser. Do not proceed to posting.
3. When all checks pass, call `list_accounts` and `get_usage`, then report:
   - a table of connected accounts (platform, username, id) with token-health
     flags from the list (`disconnectedAt`/`tokenExpiresAt` mean the account
     needs `refresh_account` or a reconnect)
   - plan/quota line: plan name, posts used vs monthly limit, credits left
4. Finish with the one next step that fits: `/postbuzz:compose` if they have
   something to post, `/postbuzz:analytics` if they want a read-out.

Report only what the tools returned — no assumed account state.
