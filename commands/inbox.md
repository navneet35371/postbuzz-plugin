---
description: Triage the engagement inbox — comments, mentions, DMs — and reply in the user's voice
allowed-tools: mcp__postbuzz
---
# Inbox triage

`$ARGUMENTS` optionally narrows scope (platform, account, or "unread only").

## Steps

1. `check_setup` first; any failure → stop, point at `/postbuzz:setup`.
2. `list_inbox { status: "unread" }` (add platform/account filters if given).
   Empty → say so and stop. Cap this run at the 15 oldest items; report the
   remainder count.
3. Group items: **questions**, **praise/mentions**, **complaints**,
   **spam/irrelevant**. Show author, platform, post context, and snippet.
4. Draft replies for questions and praise only, in the user's established
   voice — check recent published captions via `list_posts { status:
   "published" }` if voice is unknown, and ask for a one-line voice
   description if it still isn't clear.
   - questions: answer factually from context; "I'll find out" beats a guess
   - praise: short, human, no links
   - complaints, legal-ish, anything heated: **do not draft a public reply** —
     summarize for the user and let them respond
   - spam: skip, just report it
5. Show all drafts with their target items. Send only after approval, via
   `reply_to_inbox_item` per item. A sent reply that needs fixing →
   `edit_inbox_reply`.
6. Report what was sent, what was escalated, what was skipped.

Never send a public reply without approval in this flow, and never send bulk
or identical replies to multiple items.
