# Herdr-native runner for Neovim

**Date:** 2026-08-13
**Status:** Approved, ready for implementation

## Problem

Three separate Neovim integrations in this repo drive a second terminal pane, and
all three are tmux-only. Inside a herdr session (`$TMUX` unset, `$HERDR_PANE_ID`
set) every one of them is dead:

| Integration | Where | Why it's dead in herdr |
|---|---|---|
| `christoomey/vim-tmux-runner` | `lua/plugins/tmux.lua` | spec is `enabled = os.getenv("TMUX") ~= nil` |
| `vim-test` via `test#strategy = 'vimux'` | `lua/plugins/testing.lua` | vimux shells out to `tmux` |
| four `<leader>t*` pane maps | `lua/config/tmux.lua` | raw `tmux split-window` / `select-layout` calls |

The actual test-running path is vim-test → vimux, not vim-tmux-runner. Any
replacement that only ports vim-tmux-runner would leave `<leader>t`/`T`/`a`/`l`/`g`
broken.

Two defects surfaced while scoping this, both pre-existing:

- **`<leader>tl` collision.** `lua/config/tmux.lua:7` maps `<leader>tl` to "open
  tmux pane right". `init.lua` requires `config.tmux` *after* `config.lazy`, so it
  overwrites vim-tmux-runner's `<leader>tl` (`VtrSendLinesToRunner`). Send-lines
  has never been reachable.
- **`<leader>tl` was normal-mode only.** The lazy `keys` entry declared no `mode`,
  so it defaulted to normal despite the "send all visually selected lines"
  comment.

## Verified herdr capabilities

Against herdr 0.7.4, live, in this session. Every command returns JSON on stdout
shaped `{"id": ..., "result": {...}}`.

| vim-tmux-runner / vimux | herdr CLI |
|---|---|
| `VtrOpenRunner` | `herdr pane split <id> --direction down --ratio 0.25 --no-focus --cwd <path>` → `.result.pane.pane_id` |
| `VtrSendCommandToRunner` | `herdr pane run <id> <cmd>` (command + Enter) |
| `VtrSendLinesToRunner` | `herdr pane send-text <id> <text>` then `herdr pane send-keys <id> Enter` |
| `VtrAttachToPane` | `herdr pane list` → `.result.panes[].pane_id` |
| `VtrKillRunner` | `herdr pane close <id>` |
| `VtrClearRunner` | `herdr pane run <id> clear` |
| `VtrFocusRunner` | `herdr pane focus --direction down --pane $HERDR_PANE_ID` |
| — | `herdr pane read <id>` — pull runner output back into nvim; no VTR equivalent |

Note: `herdr pane read --source recent` returned empty in testing where
`--source visible` returned the expected content. Use `visible` for any read.

**Environment inheritance differs from vim-tmux-runner.** `tmux split-window`
inherits the calling pane's environment, which is how VTR's runner always saw
nvim's PATH (and thus asdf/mise shims) for free. `herdr pane split` spawns its
shell from the herdr *server*, not from nvim, so it does not inherit nvim's
environment at all -- a split pane's shell can come up with none of nvim's
PATH. Reproduced live in a session whose split shells resolve `bundle` to
`/usr/bin/bundle` (macOS system Ruby) instead of the asdf-shimmed version the
project's lockfile requires. `split_pane()` in `runner.lua` now passes
`--env PATH=<nvim's PATH>` (verbatim, always) plus a curated list of
runtime-manager variables (`ASDF_*`, `MISE_*`, `GEM_*`, `BUNDLE_*`) when set,
to every split -- runner and scratch panes alike, since both go through
`split_pane()`.

`vim-test` extension point confirmed at `vim-test/autoload/test.vim:111`:
`g:test#custom_strategies[strategy](cmd)`, a dict of funcrefs. Reachable from Lua
via `vim.fn.function("Name")`.

## Decisions

1. **herdr-only.** `christoomey/vim-tmux-runner` and `preservim/vimux` are
   removed outright, not kept as fallbacks. `christoomey/vim-tmux-navigator`
   stays — it is the tmux fallback for `vim-herdr-navigation`, a separate
   concern.
2. **Lazy auto-split, remembered and revalidated.** The first send creates the
   runner; later sends reuse it after confirming it still exists; a closed runner
   silently re-splits. No explicit open is required.
3. **`<leader>ab` targets the detected Claude agent**, not the generic runner.
4. **`lua/config/tmux.lua` is in scope**: `tj`/`tl` port to herdr, `tv`/`th` are
   dropped (herdr has no `select-layout` equivalent — only `swap`, `move`,
   `zoom`, none of which reproduce it).

## Architecture

A backend module plus a thin wiring layer. The runner is not a plugin, so it does
not belong in `lua/plugins/` — lazy.nvim imports every file there as a spec.

| File | Change |
|---|---|
| `lua/herdr/runner.lua` | new — all herdr CLI interaction |
| `lua/config/herdr.lua` | new — keymaps and `:Herdr*` commands |
| `lua/config/tmux.lua` | deleted |
| `lua/plugins/tmux.lua` | vim-tmux-runner spec removed; navigator block untouched |
| `lua/plugins/testing.lua` | vimux dependency dropped; custom herdr strategy registered |
| `init.lua` | `require("config.tmux")` → `require("config.herdr")` |
| `setup.d/herdr` | new — clone + `herdr plugin link` the nav plugin (see Provisioning) |
| `setup.d/mise` | herdr nav-plugin block removed; `mise use -g herdr` pin kept |
| `setup` | `./setup.d/herdr` added after `mise`, before `prune` |
| `tag-herdr/` | `git add` — currently untracked, so it reaches no other machine |

### `lua/herdr/runner.lua`

Single responsibility: own the runner pane and talk to the herdr CLI. Knows
nothing about keymaps or vim-test.

State: one module-local `runner_id`, scoped to the nvim instance.

Private helpers:

- `bin()` — `vim.env.HERDR_BIN_PATH` if non-empty, else `"herdr"`.
- `available()` — true when `vim.env.HERDR_PANE_ID` is set and non-empty.
- `cli(args)` — `vim.system():wait()`, decode stdout with `pcall(vim.json.decode, …)`,
  return `result` or `nil, err`.

Public API:

- `runner()` — returns a live pane id. If `runner_id` is set and still present in
  `pane list`, return it. Otherwise split from `$HERDR_PANE_ID` (`--direction down
  --ratio 0.25 --no-focus --cwd <vim.fn.getcwd()>`), cache
  `.result.pane.pane_id`, return it. The only place a pane is created.
- `run(cmd)` — `pane run` on `runner()`.
- `send_text(text)` — `pane send-text`, no Enter.
- `send_lines(text)` — `send-text` then `send-keys Enter`.
- `kill()` — `pane close`, clear `runner_id`.
- `focus()` — `pane focus --direction down --pane $HERDR_PANE_ID`. Exact because
  the runner is always split downward.
- `clear()` — `run("clear")`.
- `agent_send(text)` — `herdr agent send claude <text>` when `herdr agent list`
  reports a claude agent; otherwise falls back to `send_text`.

### `lua/config/herdr.lua`

Keymaps and user commands. Calls only the module above.

| lhs | mode | action |
|---|---|---|
| `<leader>rs` | n, v | send visual selection (v) or current line (n) to the runner |
| `<leader>rk` | n | kill runner |
| `<leader>rf` | n | focus runner |
| `<leader>rc` | n | clear runner |
| `<leader>ru` | n | `rubocop -A` |
| `<leader>bo` | n | `rubocop -A <current file>` |
| `<leader>ab` | n | `@<current file> ` to the Claude agent pane, no trailing Enter |
| `<leader>tj` | n | ad-hoc scratch split, direction down |
| `<leader>tl` | n | ad-hoc scratch split, direction right |

`<leader>tj`/`<leader>tl` create throwaway panes and do **not** touch
`runner_id` — they are not the runner.

User commands mirror the management maps: `:HerdrRunnerOpen`, `:HerdrRunnerKill`,
`:HerdrRunnerFocus`, `:HerdrRunnerClear`, `:HerdrRunnerSend <cmd>`.

### `lua/plugins/testing.lua`

```lua
vim.cmd([[
  function! HerdrTestStrategy(cmd) abort
    call luaeval('require("herdr.runner").run(_A)', a:cmd)
  endfunction
]])
vim.g["test#custom_strategies"] = { herdr = vim.fn.function("HerdrTestStrategy") }

local in_herdr = vim.env.HERDR_PANE_ID ~= nil and vim.env.HERDR_PANE_ID ~= ""
vim.g["test#strategy"] = in_herdr and "herdr" or "basic"
```

`<leader>t`/`T`/`a`/`l`/`g` keep their current bindings.

## Error handling

- Outside herdr (`$HERDR_PANE_ID` unset): every entry point no-ops after a single
  `vim.notify(…, vim.log.levels.WARN)`. Nothing throws.
- `herdr` missing from `$PATH`, non-zero exit, or unparseable JSON: notify with
  captured stderr, return `nil`, and do **not** cache a pane id.
- Stale `runner_id` (pane closed by hand): detected by the `pane list` check in
  `runner()` and self-healed by re-splitting. Never surfaces as an error.
- No claude agent found for `<leader>ab`: silently falls back to the runner pane.
- **Freshly split pane, not yet ready:** a pane being registered (visible in
  `pane list`) is not the same as its shell having finished sourcing
  `~/.zshrc`. `split_pane()` polls in two phases: registration (existing
  `pane_exists()` poll; exhaustion is fatal, returns `nil`) then readiness
  (poll `herdr pane read <id> --source visible` until two consecutive
  non-empty reads are byte-identical, meaning the shell has gone quiet at its
  prompt; exhaustion just warns and returns the id anyway — a slow/quiet
  shell is probably still usable). Sending input before readiness — in
  particular a C-c — can land mid-`.zshrc`: it can kill the still-forming
  pane outright, or interrupt sourcing between `path.zsh`'s early wholesale
  `PATH` reset and `zz-runtime.zsh`'s late asdf/mise restoration, stranding
  the pane on system Ruby instead of the asdf shim. Reproduced live,
  repeatedly, on the genuine cold `run()`/`send_lines()` path with zero
  artificial delay. Because a pane the current call just created cannot hold
  pending input, `open()`/`runner()` report whether they created the pane,
  and every dispatch function skips `clean_prompt()`'s C-c when they did —
  the C-c only ever fires against a *reused* runner, where it's still needed
  for the pending-input case. Note `herdr pane read` returns plain text, not
  JSON, so this poll cannot go through `cli()` — it makes its own direct
  `vim.system()` call.

## Testing

No test suite exists in this repo. Verification is:

1. `nvim --headless` load-check of each changed file — must exit clean.
2. Live pass in a herdr session: open → `run` → `send_lines` → `:TestNearest` →
   `focus` → `clear` → `kill`, asserting on `herdr pane read <id> --source visible`.
3. Stale-pane path: close the runner by hand, send again, confirm a new pane
   appears and receives the command.
4. Fallback path: `env -u HERDR_PANE_ID nvim --headless` — confirm keymaps warn
   rather than error, and `test#strategy` resolves to `basic`.
5. `./setup.d/herdr` run twice in a row — second run must be a clean no-op
   (fast-forward pull, re-link) and exit 0.
6. `./setup.d/prune --dry-run`, then `./setup.d/prune`, then `rcup -x setup -t nvim
   -t herdr` — confirm the stale `lua/config/tmux.lua` symlink is gone and
   `lua/herdr/runner.lua` is linked.

## Provisioning on other machines

The runner itself needs no herdr-side config — it is pure CLI against
`$HERDR_PANE_ID` — so `tag-nvim` plus git carries it everywhere. rcm creates real
directories and per-file symlinks, so the new `lua/herdr/` directory is
materialized by `rcup -t nvim` with no extra wiring.

Three gaps around it must close, or the config arrives on machine #2 half-dead.

### `setup.d/herdr` (new)

Commit `caeaf1a` put herdr provisioning inside `setup.d/mise`, where it has four
defects:

1. The nav-plugin guard is inverted (`-d` where `! -d` is meant), so it clones
   only when the target already exists — and `git clone` into a non-empty
   directory fails. Under `set -e` this aborts `./setup`.
2. The clone is nested inside `! command -v herdr`, but `setup.d/mac` brew-installs
   herdr earlier in the orchestrator, so on macOS the block never runs.
3. It never calls `herdr plugin link`, so a cloned plugin is not registered.
4. `setup.d/mise` exits early when `~/.asdf` exists, so asdf machines get nothing.

Extract to a standalone, self-guarding `setup.d/herdr`, ordered after
`setup.d/mise` and before `setup.d/prune`:

- Skip with a message if `herdr` is not on `$PATH` (Brewfile covers macOS; the
  mise global pin covers Linux; neither is this script's job).
- Clone `paulbkim-dev/vim-herdr-navigation` into
  `~/.config/herdr/vim-herdr-navigation` only when absent; `git -C … pull --ff-only`
  when present.
- Run `herdr plugin link ~/.config/herdr/vim-herdr-navigation` unconditionally —
  it is idempotent and repairs an unregistered clone.

Remove the herdr block from `setup.d/mise`, keeping only the `mise use -g herdr`
pin, which is what provisions the binary on Linux.

### Package lists

`brew 'herdr'` is already in `Brewfile:17`. **No `Pacmanfile` entry**: herdr has no
AUR package — upstream ships Homebrew, a curl installer, mise, and Nix only — so
Arch gets it from the mise global pin. `Aptfile` stays untouched, matching the
existing curated-baseline convention.

### `tag-herdr/` is untracked

`~/.config/herdr/config.toml` is already symlinked locally and `setup.d/rcup`
already lists `-t herdr`, but the directory has never been `git add`ed, so none of
it moves. Track it as part of this work.

### Pruning the deleted file

Deleting `lua/config/tmux.lua` strands `~/.config/nvim/lua/config/tmux.lua` on
every machine that already has it. `setup.d/prune` handles this and already runs
inside `./setup`, but needs a run on each existing machine. Not fatal —
`lua/config/` is not auto-imported the way `lua/plugins/` is, so it is a dead
symlink rather than a broken startup. Add `./setup.d/prune` to the verification
steps so it is actually run here.

## Out of scope

Pre-existing, deliberately untouched:

- `<leader>t` (TestNearest) is a prefix of `<leader>tj`/`<leader>tl`, and
  `<leader>a` (TestSuite) of `<leader>ab`, so each incurs a `timeoutlen` pause.
- `<leader>ro` in `lua/config/keymaps.lua` shells out to `tmux display-message`,
  dead in herdr.
- `herdr pane read` is not exposed at all — no keymap, no `M.*` wrapper. It
  also cannot be routed through `cli()` as written: `pane read` returns plain
  text, not JSON, and `cli()` correctly rejects non-JSON stdout as an
  unexpected-output failure. Exposing it would need a separate call path, not
  just a new keymap.
