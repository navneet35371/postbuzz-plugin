---
name: postbuzz
description: Operate post.buzz — agent-first social media management — via its MCP server. Use when the user asks to publish, draft, schedule, or manage social posts, reply to comments/DMs, check social analytics, connect social accounts, or bulk-import posts across Instagram, X, TikTok, LinkedIn, YouTube, Facebook, Pinterest, Reddit, Threads, Bluesky, Mastodon, Discord, Slack, Telegram, Dribbble, or Google Business.
---

# post.buzz

Drive [post.buzz](https://post.buzz) through the `postbuzz` MCP server
(tools appear as `mcp__plugin_postbuzz_postbuzz__<name>` when installed as a
Claude Code plugin, `mcp__postbuzz__<name>` when added with `claude mcp add`,
plain `<name>` in Codex). Requires Node.js 20+ and a post.buzz API key
(**post.buzz → Settings → API Keys**, format `sx_live_…`), which the user
enters in the plugin's **post.buzz API key** setting. Never search files or
environment variables for a key — if it's missing, ask the user to set it.

If no postbuzz MCP tools are available in this session, every operation below
also works through the CLI: `npx -y postbuzz-cli@0.2.0 <command>` (same
subcommand names, one JSON value on stdout, errors as
`{"error":{"code","message"}}` with exit 1).

## Non-negotiable rules

1. **Call `check_setup` first** in any new session. If it reports problems,
   stop and tell the user what failed (missing key, unreachable API, zero
   connected accounts) before touching anything else.
2. **Call `describe_platform` before creating anything** for a platform. It
   returns required fields, capability flags, and limits — offline, no API
   call. Never guess field requirements.
3. **Never invent ids.** Account, media, and post ids come from
   `list_accounts`, `list_media`, `list_posts` — always.
4. **`create_post` saves a draft** (no `scheduledAt`); `schedule_post`
   schedules; `update_post`/`reschedule_post` change an existing post. Nothing
   publishes until a post has a schedule time, so drafts are the safe default.
5. **Dates are ISO 8601 UTC** (`2026-10-01T09:00:00Z`). Convert the user's
   local time and state the UTC value you used.
6. **Destructive actions need explicit confirmation**: `delete_post`,
   `delete_media`, `disconnect_account`, deleting teams, sending public
   replies (`reply_to_inbox_item`). Deleting/disconnecting cascades schedules
   and automation.

## Tool map

| Area | Tools |
| --- | --- |
| Diagnostics | `check_setup`, `describe_platform` |
| Org & quota | `get_organization`, `get_usage` |
| Accounts | `list_accounts`, `get_account`, `connect_account` (returns an OAuth URL for the user to open), `disconnect_account`, `refresh_account`, `list_account_tools`, `run_account_tool` |
| Posts | `create_post` (draft), `schedule_post`, `list_posts`, `get_post`, `update_post`, `delete_post`, `retry_post`, `reschedule_post` |
| Comments | `create_comment`, `list_comments`, `get_comment`, `update_comment`, `delete_comment`, `retry_comment` |
| Inbox | `list_inbox`, `reply_to_inbox_item`, `edit_inbox_reply` |
| Media | `upload_media` (local path or public URL), `list_media`, `get_media`, `delete_media`, `delete_media_many` |
| Analytics | `get_post_analytics`, `get_account_analytics`, `get_bulk_post_analytics`, `get_analytics_summary`, `get_best_times`, `refresh_analytics` |
| Teams | `list_teams`, `get_team`, `create_team`, `update_team`, `delete_team`, `add_team_account`, `remove_team_account` |
| Bulk import | `create_post_csv_import`, `list_post_csv_imports`, `get_post_csv_import`, `get_post_csv_import_rows`, plus retry/status variants |
| Video clipping | `create_clip` (always pass a fresh `idempotencyKey`; reuse it only to retry the same request), `get_clip` to poll, `list_clips`, `get_clip_usage` before starting |

## Standard flows

**Draft → schedule → move**

```
check_setup → list_accounts → describe_platform <platform>
create_post   { accountIds, caption, mediaIds?, firstComment?, postType?, threadParts? }
update_post   { postId, scheduledAt }        # or reschedule_post to move it
```

**Attach media**: `upload_media { path }` (or `{ url }`) → attach the returned
id via `mediaIds`.

**Threads** (`postType: "thread"`): `threadParts` is an object keyed by
accountId → ordered parts. **Polls**: caption carries the question; see
`describe_platform` for the poll fields on the target platform.

**Engagement**: `list_inbox { status: "unread" }` → draft replies → confirm
with the user → `reply_to_inbox_item`. Chain deeper replies with
`create_comment { parentCommentId }`.

**Analytics loop**: `get_analytics_summary { windowDays }` + `get_best_times`
feed scheduling decisions; `get_bulk_post_analytics` (≤60 ids) compares posts.

**Reddit/Pinterest extras**: `list_account_tools` + `run_account_tool` fetch
live flairs/boards before posting (`{"subreddit":"…"}` input for
`reddit-flairs`).

## Error handling

Tool errors surface as `{"error":{"code","message"}}`. `MISSING_API_KEY` →
fix the key config, don't retry. `subscription_required`/`rate_limited` →
report the limit to the user and stop. `not_found` → usually a wrong or
invented id; re-list instead of retrying.
