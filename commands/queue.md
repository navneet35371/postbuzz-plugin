---
description: Review the upcoming queue — scheduled and failed posts — and fix problems
allowed-tools: mcp__plugin_postbuzz_postbuzz
---
# Review the post queue

Show what's queued and fix what's broken.

## Steps

1. `check_setup` first; any failure → stop, point at `/postbuzz:setup`.
2. Pull the queue:
   - `list_posts { status: "scheduled", limit: 25 }` — upcoming
   - `list_posts { status: "failed", limit: 25 }` — problems
   - `list_posts { status: "draft", limit: 25 }` — parked, may be stale
3. Present a chronological table of scheduled posts: time (UTC + user's local
   zone), platform, account, caption excerpt, id. Flag:
   - **collisions** — two posts to the same account within an hour
   - **duplicate content** — same caption scheduled more than once
   - **stale drafts** older than two weeks
4. For each **failed** post: `get_post` to show the failure reason. Offer
   `retry_post` when the cause looks transient (token refresh →
   `refresh_account` first if token health is bad); offer edit-and-retry via
   `update_post` + `retry_post`; offer `delete_post` only with explicit
   confirmation.
5. Ask what to change. Act on approved edits:
   - move → `reschedule_post { postId, scheduledAt }` (state the ISO time)
   - edit text → `update_post`
   - cancel → `delete_post` (confirm first — destructive)

Never bulk-delete or bulk-move without an explicit list approved by the user.
