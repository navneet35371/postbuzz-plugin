---
description: Analytics digest — account performance, best posting times, and what to do next
argument-hint: "[window in days — default 7]"
allowed-tools: mcp__plugin_postbuzz_postbuzz
---
# Analytics digest

Read performance and turn it into decisions. Window = `$ARGUMENTS` parsed as
days, default 7 (30 for "monthly").

## Steps

1. `check_setup` first; any failure → stop, point at `/postbuzz:setup`.
2. Gather:
   - `get_analytics_summary { windowDays }` — per-account rollup
   - `get_best_times` — recommended slots
   - `list_posts { status: "published", limit: 15 }` →
     `get_bulk_post_analytics` on those ids — per-post numbers
3. If a post shows zero/stale metrics, note it; `refresh_analytics` is async —
   kick it off only if the user wants fresh numbers, and say results arrive
   on the next run.
4. Report:
   - per-account table for the window: posts published, reach/impressions,
     engagement rate, follower delta (only the metrics the API returned —
     omit columns with no data, never estimate)
   - top 3 and bottom 2 posts with their numbers and one observed pattern
     each (format, time, topic, media vs text)
   - best-times recommendation next to the times actually used
5. Close with **at most 3 recommendations**, each tied to a number you just
   showed (e.g. "video drafts outperformed 3:1 — schedule the two parked
   video drafts into Thursday's best slot"). Offer `/postbuzz:schedule` to
   execute one.

No vanity metrics, no invented benchmarks — only what the tools returned.
