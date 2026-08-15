# Migration from tmux to herdr

**Date:** 2026-08-15
**Commits:** `caeaf1a` → `d2c711e`

This repo no longer configures tmux. Neovim drives [herdr](https://herdr.dev)
panes directly, and the tmux-only plugins that used to do that job are gone.

---

## Keyboard shortcuts — active

Leader is `,`. Everything under Runner and Testing requires nvim to be running
**inside a herdr pane** (`$HERDR_PANE_ID` set). Outside one, each warns once and
does nothing rather than erroring.

### Runner

| Keys | Mode | Behaviour |
|---|---|---|
| `,rs` | normal | Send the current line to the runner and execute it |
| `,rs` | visual | Send the selection (charwise, linewise or blockwise) as one block and execute |
| `,rk` | normal | Close the runner pane |
| `,rf` | normal | Move focus into the runner (the pane below) |
| `,rc` | normal | Clear the runner's screen |
| `,ru` | normal | Run `rubocop -A` |
| `,bo` | normal | Run `rubocop -A <current file>` |

### Testing — same keys as before, different transport

vim-test now dispatches through the herdr runner instead of vimux.

| Keys | Mode | Behaviour |
|---|---|---|
| `,t` | normal | `TestNearest` |
| `,T` | normal | `TestFile` |
| `,a` | normal | `TestSuite` |
| `,l` | normal | `TestLast` |
| `,g` | normal | `TestVisit` |

### Navigation

| Keys | Mode | Behaviour |
|---|---|---|
| `Ctrl-h/j/k/l` | normal in nvim; any pane elsewhere | Move between nvim splits; at a split edge, cross into the neighbouring herdr pane. The same keys move between herdr panes everywhere else |

### Commands (no keymaps)

`:HerdrRunnerOpen` · `:HerdrRunnerKill` · `:HerdrRunnerFocus` ·
`:HerdrRunnerClear` · `:HerdrRunnerSend <cmd>`

### Shell

| Command | Behaviour |
|---|---|
| `t` | Start or attach to a herdr session named after `$PWD`'s basename (dots stripped), with tabs `vim` / `server` / `claude`, focused on `vim`, all with cwd set to the project |
| `herdr --session <name>` | Wrapped in zsh: a brand-new session gets `vim-herdr-navigation` linked automatically. Every other `herdr` invocation passes through untouched |

---

## Keyboard shortcuts — removed

| Keys | Did | Why it's gone |
|---|---|---|
| `,tv` | `tmux select-layout main-horizontal` | herdr has no `select-layout`; only `swap`, `move`, `zoom`, none of which reproduce it. **Genuine capability loss.** |
| `,th` | `tmux select-layout main-vertical` | Same |
| `,tj` | Open a pane below in the current dir | Ported to herdr, then removed by choice |
| `,tl` | Open a pane to the right in the current dir | Ported to herdr, then removed by choice |
| `,tl` | `VtrSendLinesToRunner` | Never actually worked — `lua/config/tmux.lua` was required *after* `config.lazy` and overwrote it. Replaced by `,rs`, which also fixes it being normal-mode-only despite the "visually selected lines" comment |
| `,ab` | Send `@./<file>` to Claude Code | Removed by choice |

`,rn` is **not** a herdr binding — it is Snacks' Rename File. A runner
open-keymap briefly shadowed it during this work and was removed; `:HerdrRunnerOpen`
covers the explicit case.

`,ro` still exists and still notifies "Use T J instead!", but no longer shells out
to `tmux display-message`.

---

## Behaviour worth knowing

- **No explicit open.** The first send creates the runner. Close it by hand and
  the next send silently re-creates it.
- **Re-sends interrupt.** `,rs`, `,ru`, `,bo` and vim-test send `C-c` before
  dispatching into an *existing* runner, so a re-run cancels a live suite. A
  foreground `tail -f`, `watch` or `less` in that pane will be terminated.
  Freshly created panes are never interrupted — see below.
- **Fresh panes are waited for.** `herdr pane split` returns a pane id before
  that pane's shell has finished sourcing `~/.zshrc`. Dispatching into that
  window either kills the pane outright or leaves zsh having aborted mid-init —
  and because `path.zsh` resets `PATH` wholesale early while `zz-runtime.zsh`
  restores the asdf shims last, the result was a pane on the system `PATH` with
  the wrong Ruby. The runner now polls the pane's output until it is quiet
  before sending anything.
- **`,t` pauses ~1s.** `,t` is a prefix of no current binding, but `,a`
  (`TestSuite`) and `,l`/`,g` share the leader with two-key maps elsewhere; where
  a one-key map is a prefix of a two-key one, vim waits out `timeoutlen`.
- **Select mode** (snippet placeholders) falls through to current-line behaviour
  on `,rs`, not the selection.

---

## What changed in the repo

### Neovim

| File | Change |
|---|---|
| `lua/herdr/runner.lua` | **New.** Owns every `herdr` CLI call — pane lifecycle, sends, focus, clear, agent targeting |
| `lua/config/herdr.lua` | **New.** Keymaps, `:Herdr*` commands, and the `dofile` of `vim-herdr-navigation`'s `editor/nvim.lua` |
| `lua/config/tmux.lua` | **Deleted.** Was four raw `tmux` shell-outs |
| `lua/plugins/tmux.lua` | **Deleted.** `vim-tmux-runner` and `vim-tmux-navigator` both gone |
| `lua/plugins/testing.lua` | `vimux` dependency dropped; vim-test reaches the runner via `g:test#custom_strategies.herdr`, falling back to `basic` outside herdr |
| `lua/config/keymaps.lua` | `,ro` no longer shells out to `tmux display-message` |

Detection is `$HERDR_PANE_ID`, never `$TMUX`.

### Provisioning

| File | Change |
|---|---|
| `setup.d/herdr` | **New.** Clones `vim-herdr-navigation` and links it into **every running herdr session** — the plugin registry is per-session while `config.toml` is shared, so a session without the plugin reports `plugin action not found` on every `Ctrl-h/j/k/l` |
| `setup.d/mise` | Pins `herdr` globally when absent from `PATH` — the Linux path, since herdr has no AUR package |
| `tag-zsh/config/zsh/herdr.zsh` | **New.** The `herdr()` wrapper and `t()` |
| `tag-zsh/config/zsh/tmux.zsh` | **Deleted.** Held the old tmux `t()` |
| `tag-herdr/` | **New tag.** `config.toml` with the four `Ctrl-h/j/k/l` binds |
| `tag-tmux/`, `setup.d/tmux` | **Deleted**, along with the `-t tmux` rcup tag and the orchestrator line |
| `Brewfile` | `herdr` and `jq` added |

`tmux` itself is still in `Brewfile` / `Pacmanfile` / `Aptfile` — the binary is
worth having on remote boxes; it just is not configured from here any more.

---

## Loose ends

- **`~/.tmux` still holds ~445 files** — tpm-installed plugins (tmux2k,
  tmux-sensible), created at runtime rather than by rcm, so nothing here manages
  them. Delete by hand if you want them gone.
- **`runner.agent_send()` and `runner.split()` are now unreachable.** Their only
  call sites were `,ab` and `,tj`/`,tl`. Still available from `:lua` or by
  re-binding; otherwise dead code worth pruning.
- **`setup.d/prune` cannot find orphans under a deleted tag tree.** It derives
  what to scan from the tags that still exist, so removing `tag-tmux/` wholesale
  also removed the map to its own orphans — 35 dangling symlinks under
  `~/.plugins/` had to go by hand. Documented at `setup.d/prune:31-32`.
- **`herdr` has no "pane ready" signal.** Three separate bugs in this migration
  traced back to clients having to poll output stability to guess when a shell
  has finished starting. Worth raising upstream.
