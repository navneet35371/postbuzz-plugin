---
description: Draft a post for one or more social platforms (saved as a draft, never auto-published)
argument-hint: "[idea or brief — include platforms and media if decided]"
allowed-tools: mcp__plugin_postbuzz_postbuzz
---
# Compose a post

Turn the idea into platform-correct drafts. `$ARGUMENTS` holds the brief; if
it's empty, ask for the idea and target platforms before doing anything.

## Steps

1. `check_setup` — if anything fails, stop and follow `/postbuzz:setup`.
2. `list_accounts` → identify target accounts. If the brief names a platform
   with no connected account, say so and offer `connect_account`.
3. `describe_platform` **for every distinct target platform** — honor its
   required fields, capabilities, and length limits from this response, not
   from memory.
4. Write the content:
   - one base caption, adapted per platform via `accountOverrides` when limits
     or conventions differ (e.g. hashtags for Instagram, none for LinkedIn)
   - if the media is longer than the platform limit and the platform supports
     threads, propose `postType: "thread"` with `threadParts` instead of
     truncating
   - media files/URLs from the brief: `upload_media` first, attach via
     `mediaIds`
   - Reddit needs a subreddit (+ often a flair: `list_account_tools` →
     `run_account_tool`), Pinterest needs a board — fetch live ids, never
     guess
5. Show the user the final text per platform with character counts against
     each limit. Revise until approved.
6. On approval, `create_post` (a **draft** — no `scheduledAt`, nothing
   publishes). Reply with the post id(s) and offer `/postbuzz:schedule`.

Never call `schedule_post` or set a date in this flow unless the user
explicitly asked for a time in the brief.
