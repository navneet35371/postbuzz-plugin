---
description: Schedule a post (existing draft or new) for a specific time, or at the best time
argument-hint: "[post id or idea] [when — time, natural language, or \"best time\"]"
allowed-tools: mcp__plugin_postbuzz_postbuzz
---
# Schedule a post

`$ARGUMENTS` is either `<postId> <when>` for an existing draft or
`<idea> <when>` for something new. Missing pieces → ask before acting.

## Steps

1. `check_setup` first; any failure → stop, point at `/postbuzz:setup`.
2. Resolve **when**:
   - "best time"/"optimal": `get_best_times` (optionally per account) and use
     its recommendation for that platform.
   - Natural language ("tuesday 9am cet"): convert to ISO 8601 UTC, and state
     the conversion ("Tue 2026-10-20 09:00 CET → 2026-10-20T08:00:00Z").
   - Bare time today/tomorrow: same conversion rule.
   - Anything in the past → say so and propose the next sensible slot instead.
3. Resolve **what**:
   - Existing id: verify with `get_post` (exists, status draft/scheduled).
     Draft → `update_post { postId, scheduledAt }`; already scheduled →
     `reschedule_post` and say it's a move.
   - New idea: run the `/postbuzz:compose` steps (targets →
     `describe_platform` → draft → approval), then `schedule_post` with the
     agreed time.
4. Confirm before the call: accounts + final text summary + the exact ISO
   time. Then schedule.
5. Verify with `get_post` and report the scheduled time and target accounts.

One confirmation is enough; don't re-ask after the user already gave an
explicit time and content.
