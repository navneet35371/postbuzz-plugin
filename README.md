# postbuzz-plugin

Agent-plugin for [post.buzz](https://post.buzz) — bring social media
publishing, scheduling, engagement, and analytics into Claude Code, Codex, and
zcode. Built on the published [`postbuzz-mcp`](https://www.npmjs.com/package/postbuzz-mcp)
server (MCP tools) and [`postbuzz-cli`](https://www.npmjs.com/package/postbuzz-cli)
(fallback). Requires Node.js 20+ and a post.buzz account.

## What each target gets

| Target | Skill | Agents | MCP server |
| --- | --- | --- | --- |
| Claude Code (plugin) | `postbuzz` | `growth-strategist`, `engagement-triage` | `postbuzz` via plugin `.mcp.json` |
| Claude Code (install.sh) | ✅ `~/.claude/skills` | ✅ `~/.claude/agents` | ✅ user scope (`claude mcp add`) |
| Codex | ✅ `~/.codex/skills` | — | ✅ `[mcp_servers.postbuzz]` in `config.toml` |
| zcode | ✅ `~/.zcode/skills` | — | — (skill falls back to `postbuzz-cli`) |

## Install

### Claude Code — plugin (recommended)

```bash
claude plugin marketplace add navneet35371/postbuzz-plugin
claude plugin install postbuzz@postbuzz
```

Or from a local checkout: `claude plugin marketplace add ./postbuzz/postbuzz-plugin`,
then the same install command. For local development without the plugin
system: `claude --plugin-dir ./postbuzz/postbuzz-plugin`.

### Codex

```bash
./install.sh --target codex
# embeds $POSTBUZZ_API_KEY if exported; otherwise replace sx_live_REPLACE_ME
# in ~/.codex/config.toml afterwards
```

### zcode

```bash
./install.sh --target zcode
```

### Everything / manual skill drop

```bash
./install.sh --target all
./install.sh --target custom --path ~/.your-agent/skills
```

Uninstall mirrors it: `./uninstall.sh --target claude|codex|zcode|custom|all`.

## API key

Create a key at **post.buzz → Settings → API Keys** (`sx_live_…`).

- **Plugin path**: `/config` → plugin **postbuzz** → *post.buzz API key*
  (stored in secure storage), or export `POSTBUZZ_API_KEY` before launching.
- **install.sh path**: export `POSTBUZZ_API_KEY` before running (Codex
  embeds it in `config.toml`; Claude reads it from the environment).
- Staging/self-hosted: set `api_url` user config or `POSTBUZZ_API_URL`.

Verify any time: ask the agent *"run the postbuzz setup check"* or
`/postbuzz:setup`.

## What's inside

**Commands** — `/postbuzz:<name>`

| Command | Does |
| --- | --- |
| `setup` | One-shot diagnostic: key, connectivity, accounts, quota; fixes guidance |
| `compose [brief]` | Platform-correct drafts (limits, threads, media, flairs/boards) — saved as drafts, never auto-published |
| `schedule [what] [when]` | Resolve natural-language or "best" times to ISO 8601 UTC and schedule drafts |
| `queue` | Scheduled/failed/draft posts; collisions, dupes, retries; safe edits |
| `analytics [days]` | Digest from real metrics + ≤3 data-tied recommendations |
| `inbox` | Triage unread comments/mentions/DMs; approval-gated replies |

**Agents** — delegable, proactive

- `growth-strategist` — builds a 7-day calendar from `get_best_times` +
  recent performance, creates **drafts only**; scheduling stays with you.
- `engagement-triage` — answers routine questions/praise in your voice,
  escalates complaints/legal/sarcasm, caps at 20 replies per run, never
  deletes or disconnects.

**Skill** — `skills/postbuzz/SKILL.md`: the operating manual (tool map,
non-negotiable rules, error handling) that all three targets share.

**MCP** — `.mcp.json` pins `postbuzz-mcp@0.2.0` (stdio). Bump the pin there,
in `install.sh` (`POSTBUZZ_MCP_REF`), and in the skill's CLI fallback line
together.

## Safety model

- `create_post` is draft-only by design; nothing publishes without an explicit
  schedule step the user approved.
- Destructive calls (`delete_post`, `delete_media`, `disconnect_account`) and
  public replies require explicit confirmation in every command/agent flow.
- No ids are ever guessed — accounts, media, posts, flairs, and boards are
  fetched live first.

## Validation

```bash
claude plugin validate ./postbuzz-plugin            # manifest + marketplace
node ../validate/plugin-check.mjs                   # structure, frontmatter, wiring
node ../validate/plugin-live.mjs                    # MCP handshake + offline tools
```

## License

MIT © NAVIKEDAR TECH PRIVATE LIMITED
