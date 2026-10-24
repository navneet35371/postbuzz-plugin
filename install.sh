#!/usr/bin/env bash
set -euo pipefail

# postbuzz-plugin installer
# Installs the post.buzz agent surface into Claude Code, Codex, and zcode.
#
# Targets:
#   claude   ~/.claude/skills + ~/.claude/agents + user-scope MCP server
#   codex    ~/.codex/skills + [mcp_servers.postbuzz] in ~/.codex/config.toml
#   zcode    ~/.zcode/skills
#   custom   --path DIR   (skill only, into DIR/postbuzz)
#   all      claude + codex + zcode
#
# Usage:
#   ./install.sh [--target claude|codex|zcode|custom|all] [--path DIR]
#
# API key: asked for interactively (hidden input) when run in a terminal;
# never read from the environment. Skip the prompt to fill it in later.
#
# Env:
#   POSTBUZZ_NO_MCP=1  skip `claude mcp add` (used by tests / offline installs)

readonly POSTBUZZ_PLUGIN_VERSION="0.2.2"
readonly POSTBUZZ_MCP_REF="postbuzz-mcp@0.2.1"

target="all"
custom_path=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    --target) target="${2:?}"; shift 2 ;;
    --path) custom_path="${2:?}"; shift 2 ;;
    -h|--help)
      echo "Usage: ./install.sh [--target claude|codex|zcode|custom|all] [--path DIR]"
      exit 0 ;;
    *) echo "ERROR: unknown argument: $1" >&2; exit 2 ;;
  esac
done

case "${target}" in
  claude|codex|zcode|custom|all) ;;
  *) echo "ERROR: invalid target: ${target}" >&2; exit 2 ;;
esac
if [ "${target}" = "custom" ] && [ -z "${custom_path}" ]; then
  echo "ERROR: --target custom requires --path" >&2
  exit 2
fi

plugin_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Ask once, only on a terminal, only for targets that configure an MCP server.
api_key=""
if [ -t 0 ] && { [ "${target}" = "claude" ] || [ "${target}" = "codex" ] || [ "${target}" = "all" ]; }; then
  printf 'post.buzz API key (sx_live_…, from post.buzz → Settings → API Keys; Enter to skip): ' >&2
  IFS= read -rs api_key || api_key=""
  printf '\n' >&2
fi
skill_src="${plugin_root}/skills/postbuzz"
agents_src="${plugin_root}/agents"

copy_skill() {
  local dest_root="$1"
  mkdir -p "${dest_root}"
  rm -rf "${dest_root}/postbuzz"
  cp -R "${skill_src}" "${dest_root}/postbuzz"
  echo "  skill   → ${dest_root}/postbuzz/SKILL.md"
}

copy_agents() {
  local dest_dir="$1"
  mkdir -p "${dest_dir}"
  local copied=0
  while IFS= read -r -d '' f; do
    # The plugin names its server's tools mcp__plugin_postbuzz_postbuzz; the
    # server added here by `claude mcp add postbuzz` is plain mcp__postbuzz.
    sed 's/mcp__plugin_postbuzz_postbuzz/mcp__postbuzz/g' "$f" > "${dest_dir}/$(basename "$f")"
    copied=$((copied + 1))
  done < <(find "${agents_src}" -name '*.md' -print0)
  echo "  agents  → ${dest_dir} (${copied} agents)"
}

install_claude() {
  echo "claude:"
  copy_skill "${HOME}/.claude/skills"
  copy_agents "${HOME}/.claude/agents"
  if [ "${POSTBUZZ_NO_MCP:-}" = "1" ]; then
    echo "  mcp     skipped (POSTBUZZ_NO_MCP=1)"
    return
  fi
  if ! command -v claude >/dev/null 2>&1; then
    echo "  mcp     skipped (claude CLI not found — or use the plugin system: /plugin marketplace add)"
    return
  fi
  if [ -n "${api_key}" ]; then
    claude mcp add --scope user postbuzz -e POSTBUZZ_API_KEY="${api_key}" -- npx -y "${POSTBUZZ_MCP_REF}" >/dev/null 2>&1 \
      || { echo "  mcp     postbuzz already registered (user scope) — left unchanged"; return; }
  else
    claude mcp add --scope user postbuzz -- npx -y "${POSTBUZZ_MCP_REF}" >/dev/null 2>&1 \
      || { echo "  mcp     postbuzz already registered (user scope) — left unchanged"; return; }
    echo "  note    no API key given; re-run ./install.sh --target claude in a terminal to enter it"
  fi
  echo "  mcp     → user-scope server 'postbuzz' (${POSTBUZZ_MCP_REF})"
}

# Remove any existing postbuzz marker block, then append a fresh one.
write_codex_mcp() {
  local config="$1"
  local key="${api_key:-sx_live_REPLACE_ME}"
  touch "${config}"
  local tmp="${config}.tmp.postbuzz"
  awk '
    /^# >>> postbuzz \(added by postbuzz-plugin install\.sh\) >>>$/ { skip=1; next }
    /^# <<< postbuzz <<<$/ { skip=0; next }
    !skip { print }
  ' "${config}" > "${tmp}"
  if [ -s "${tmp}" ] && [ "$(tail -c1 "${tmp}" | wc -l)" = "0" ]; then
    printf '\n' >> "${tmp}"
  fi
  cat >> "${tmp}" <<EOF
# >>> postbuzz (added by postbuzz-plugin install.sh) >>>
[mcp_servers.postbuzz]
command = "npx"
args = ["-y", "${POSTBUZZ_MCP_REF}"]
env = { POSTBUZZ_API_KEY = "${key}" }
# <<< postbuzz <<<
EOF
  mv "${tmp}" "${config}"
}

install_codex() {
  echo "codex:"
  copy_skill "${HOME}/.codex/skills"
  write_codex_mcp "${HOME}/.codex/config.toml"
  echo "  mcp     → ${HOME}/.codex/config.toml [mcp_servers.postbuzz]"
  if [ -z "${api_key}" ]; then
    echo "  note    no API key given — edit ${HOME}/.codex/config.toml and replace sx_live_REPLACE_ME"
  fi
}

install_zcode() {
  echo "zcode:"
  copy_skill "${HOME}/.zcode/skills"
}

install_custom() {
  echo "custom:"
  copy_skill "${custom_path}"
}

case "${target}" in
  claude) install_claude ;;
  codex) install_codex ;;
  zcode) install_zcode ;;
  custom) install_custom ;;
  all)
    install_claude
    install_codex
    install_zcode
    ;;
esac

echo "done (postbuzz-plugin v${POSTBUZZ_PLUGIN_VERSION}). Next: ask your agent to run the postbuzz setup check."
