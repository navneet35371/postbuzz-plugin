#!/usr/bin/env bash
set -euo pipefail

# postbuzz-plugin uninstaller — mirror of install.sh
# Usage: ./uninstall.sh [--target claude|codex|zcode|custom|all] [--path DIR]

target="all"
custom_path=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    --target) target="${2:?}"; shift 2 ;;
    --path) custom_path="${2:?}"; shift 2 ;;
    -h|--help)
      echo "Usage: ./uninstall.sh [--target claude|codex|zcode|custom|all] [--path DIR]"
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

remove_skill() {
  local dest_root="$1"
  if [ -f "${dest_root}/postbuzz/SKILL.md" ]; then
    rm -rf "${dest_root}/postbuzz"
    echo "  removed ${dest_root}/postbuzz"
  fi
}

remove_agents() {
  local dest_dir="$1"
  local removed=0
  while IFS= read -r -d '' f; do
    local name; name="$(basename "$f")"
    if [ -f "${dest_dir}/${name}" ]; then
      rm -f "${dest_dir}/${name}"
      removed=$((removed + 1))
    fi
  done < <(find "${plugin_root}/agents" -name '*.md' -print0)
  echo "  removed ${removed} agents from ${dest_dir}"
}

uninstall_claude() {
  echo "claude:"
  remove_skill "${HOME}/.claude/skills"
  remove_agents "${HOME}/.claude/agents"
  if command -v claude >/dev/null 2>&1 && [ "${POSTBUZZ_NO_MCP:-}" != "1" ]; then
    claude mcp remove --scope user postbuzz >/dev/null 2>&1 \
      && echo "  removed user-scope mcp server 'postbuzz'" \
      || echo "  mcp     'postbuzz' was not registered (nothing to do)"
  fi
}

uninstall_codex() {
  echo "codex:"
  remove_skill "${HOME}/.codex/skills"
  local config="${HOME}/.codex/config.toml"
  if [ -f "${config}" ] && grep -q '^# >>> postbuzz' "${config}"; then
    local tmp="${config}.tmp.postbuzz"
    awk '
      /^# >>> postbuzz \(added by postbuzz-plugin install\.sh\) >>>$/ { skip=1; next }
      /^# <<< postbuzz <<<$/ { skip=0; next }
      !skip { print }
    ' "${config}" > "${tmp}"
    mv "${tmp}" "${config}"
    echo "  removed [mcp_servers.postbuzz] from ${config}"
  else
    echo "  no postbuzz block in ${config} (nothing to do)"
  fi
}

uninstall_zcode() {
  echo "zcode:"
  remove_skill "${HOME}/.zcode/skills"
}

uninstall_custom() {
  echo "custom:"
  remove_skill "${custom_path}"
}

case "${target}" in
  claude) uninstall_claude ;;
  codex) uninstall_codex ;;
  zcode) uninstall_zcode ;;
  custom) uninstall_custom ;;
  all)
    uninstall_claude
    uninstall_codex
    uninstall_zcode
    ;;
esac

echo "done."
