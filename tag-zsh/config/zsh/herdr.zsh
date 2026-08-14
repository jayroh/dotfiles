# herdr's vim-herdr-navigation plugin (Ctrl+h/j/k/l pane navigation) is
# registered PER SESSION -- see setup.d/herdr for the full explanation. That
# script only covers sessions that already exist when ./setup runs, so a
# session created afterwards via `herdr --session <name>` starts with no
# plugin and dead Ctrl+h/j/k/l keys. Wrap `herdr` so a brand-new named session
# gets linked automatically, with no manual step.
#
# Mechanism (confirmed empirically 2026-08-14): `herdr --session <name>`
# starts that session's server, then blocks the foreground attaching its TUI
# client -- there's no flag to start the server alone/detached. But the
# server comes up and appears in `herdr session list --json` within
# ~100-400ms of invocation, long before a human could react, so a background
# job that polls for it and links the plugin (via HERDR_SOCKET_PATH, since
# the registry is per-session) wins the race without needing to fake a detach
# or touch the foreground client at all.
if command -v herdr &>/dev/null && command -v jq &>/dev/null; then
  herdr() {
    # Only intercept `herdr --session <name> ...` for a session that doesn't
    # exist yet; every other invocation (including re-attaching to an
    # already-known session, already linked by setup.d/herdr or a previous
    # run of this wrapper) passes straight through untouched.
    if [[ "$1" == "--session" && -n "$2" ]]; then
      local session_name=$2
      local plugin_dir="$HOME/.config/herdr/vim-herdr-navigation"

      if [[ -d "$plugin_dir" ]] && ! command herdr session list --json 2>/dev/null |
        jq -e --arg n "$session_name" '.sessions[] | select(.name == $n)' &>/dev/null; then
        (
          local socket
          for _ in {1..50}; do
            socket=$(command herdr session list --json 2>/dev/null |
              jq -r --arg n "$session_name" '.sessions[] | select(.name == $n and .running) | .socket_path')
            if [[ -n "$socket" ]]; then
              HERDR_SOCKET_PATH="$socket" command herdr plugin link "$plugin_dir" &>/dev/null
              break
            fi
            sleep 0.1
          done
        ) &!
      fi
    fi

    command herdr "$@"
  }
fi

# start, or attach to, a herdr session based on PWD basename (herdr-only,
# no tmux fallback). Session name: basename of $PWD with dots stripped,
# zsh-native instead of `basename`/`sed`. No `export TERM=tmux-256color`
# here -- that was tmux-specific and would misdescribe the terminal here.
#
# Mechanism: same race as the herdr() wrapper above. `herdr --session <name>`
# for a brand-new name starts the server and attaches its TUI in the
# foreground -- there's no detached start -- so a background job polls
# `session list --json` until the new session's socket appears, then
# configures tabs via HERDR_SOCKET_PATH before the foreground client catches
# up. The initial tab may not exist the instant the socket does, so that's
# polled for separately, selected by `number == 1` rather than array order.
t() {
  if ! command -v herdr &>/dev/null; then
    echo "t: herdr not found on PATH" >&2
    return 1
  fi
  if ! command -v jq &>/dev/null; then
    echo "t: jq not found on PATH (required to query herdr)" >&2
    return 1
  fi

  local proj_name=${${PWD:t}//./}
  local proj_dir=$PWD

  if command herdr session list --json 2>/dev/null |
    jq -e --arg n "$proj_name" '.sessions[] | select(.name == $n)' &>/dev/null; then
    echo "Project found. Connecting."
  else
    echo "Project not found. Creating and configuring."
    (
      local socket
      for _ in {1..50}; do
        socket=$(command herdr session list --json 2>/dev/null |
          jq -r --arg n "$proj_name" '.sessions[] | select(.name == $n and .running) | .socket_path')
        [[ -n "$socket" ]] && break
        sleep 0.1
      done
      if [[ -z "$socket" ]]; then
        return
      fi

      local vim_tab
      for _ in {1..50}; do
        vim_tab=$(HERDR_SOCKET_PATH="$socket" command herdr tab list 2>/dev/null |
          jq -r '.result.tabs[] | select(.number == 1) | .tab_id')
        [[ -n "$vim_tab" ]] && break
        sleep 0.1
      done
      if [[ -z "$vim_tab" ]]; then
        return
      fi

      HERDR_SOCKET_PATH="$socket" command herdr tab rename "$vim_tab" vim &>/dev/null
      HERDR_SOCKET_PATH="$socket" command herdr tab create --cwd "$proj_dir" --label server --no-focus &>/dev/null
      HERDR_SOCKET_PATH="$socket" command herdr tab create --cwd "$proj_dir" --label claude --no-focus &>/dev/null
      HERDR_SOCKET_PATH="$socket" command herdr tab focus "$vim_tab" &>/dev/null
    ) &!
  fi

  # Deliberately NOT `command herdr` here: this must go through the herdr()
  # wrapper above so a brand-new session also gets vim-herdr-navigation
  # linked (Ctrl+h/j/k/l). The wrapper's own existence check re-derives
  # "new session" independently and races its own linking poller alongside
  # the tab-configuring one just started above -- two short-lived pollers
  # doing two different jobs, not a merge candidate. The wrapper terminates
  # the chain itself via its internal `command herdr "$@"`, so this does not
  # recurse.
  herdr --session "$proj_name"
}
