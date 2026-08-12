# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

Personal dotfiles managed by **thoughtbot/rcm**. There is no application to build, lint, or test — the "deliverable" is a set of symlinks into `$HOME`. Most "edits" are followed by re-running `rcup` so the new file shows up at the right place.

## The rcm tag model (the one thing to internalize)

Each top-level `tag-<name>/` directory is a logical group whose contents get symlinked into `$HOME`. `rcup -t <name>` materializes one tag; the `setup` script materializes them all.

- A file at `tag-zsh/zshrc` becomes `~/.zshrc`.
- A file at `tag-zsh/config/zsh/foo.zsh` becomes `~/.config/zsh/foo.zsh`.
- A file at `tag-nvim/config/nvim/init.lua` becomes `~/.config/nvim/init.lua`.

When adding a new tag directory, also add it to the `rcup -t … -t …` invocation in `setup.d/rcup` — it lists tags explicitly rather than discovering them.

`tag-git/bin/` and `bin/` end up on `$PATH` via the standard `~/.bin` / `~/bin` symlink (so `git-foo` becomes `git foo`).

## Common commands

```sh
./setup                # full bootstrap on a fresh machine (orchestrates everything in setup.d/)
./setup.d/mise         # run a single setup step in isolation (mise, pacman, mac, shell, etc.)
rcup -x setup -t zsh   # relink one tag after editing
rcupall                # zsh alias: rcup every tag-* dir
reload!                # zsh alias: rcupall + source ~/.zshrc
```

There is no test suite, linter, or CI in this repo. The `tag-ruby/rails_template/` subdirectory has its own `.rubocop.yml` and `lefthook.yml`, but those are part of a `rails new -m` template — they apply to apps generated *from* this template, not to this repo itself.

## Auto-source / auto-import patterns

Two places use a "drop a file in, it gets picked up" pattern. Prefer adding a new fragment over editing a monolith:

- **zsh fragments** — `tag-zsh/zshrc` does `for config_file (~/.config/zsh/*.zsh(N-.)) source $config_file`. Anything in `tag-zsh/config/zsh/*.zsh` is loaded automatically. Order is glob-sorted; if a fragment must run before/after another, name it accordingly. The `(N-.)` qualifier matters: `rcup` creates symlinks but never removes stale ones, so renaming or deleting a fragment leaves a dangling symlink in `~/.config/zsh` on every machine that had the old one. `-` follows symlinks and `.` keeps only regular files, so dead links are skipped instead of throwing `no such file or directory` at every shell start; `N` keeps an empty glob from erroring.
- **nvim plugins** — `tag-nvim/config/nvim/lua/config/lazy.lua` calls `require("lazy").setup({ spec = { { import = "plugins" } } })`. Any file in `tag-nvim/config/nvim/lua/plugins/*.lua` returning a lazy.nvim spec is loaded automatically.

## Setup architecture

`setup` is a thin orchestrator. The actual work lives in `setup.d/` as small, single-purpose scripts that are each runnable standalone:

| Script | What it does |
|---|---|
| `setup.d/pacman` | Linux (Arch): install `Pacmanfile` via `yay`. No-ops on mac and on non-Arch Linux. |
| `setup.d/apt` | Linux (Debian/Ubuntu): install `Aptfile` via `apt-get`. No-ops on mac and on Linux without `apt-get`. |
| `setup.d/mac` | macOS: `brew bundle` (`./Brewfile` + `~/.Brewfile`), Xcode CLT, Font Book. No-ops on linux. |
| `setup.d/shell` | `chsh` to zsh, install custom terminfos, clone the pure prompt. |
| `setup.d/mise` | Install mise (brew/pacman/curl-fallback), run `mise install`, pin lazygit+bun globally. **No-ops when `~/.asdf` exists** — asdf takes precedence. |
| `setup.d/bunnai` | `bun install -g @chhoumann/bunnai`. Requires `setup.d/mise` first. |
| `setup.d/neovim` | Install the `neovim` gem in every mise-managed Ruby; install `pynvim` if Python 3 is present. |
| `setup.d/tmux` | Clone tpm. Idempotent — no-ops if already present. |
| `setup.d/prune` | Remove symlinks pointing into this repo whose target was deleted/renamed. `--dry-run` to preview. |
| `setup.d/rcup` | Final symlink step (`rcup -t … -t …`). |

Order matters in the orchestrator: package managers → shell → mise → bunnai (needs bun from mise) → neovim (needs ruby from mise) → tmux → prune (clear orphans before relinking) → rcup.

### Deleting or renaming a tracked file

`rcup` creates symlinks but **never removes them**, so deleting or renaming any tracked file strands a dangling symlink in `$HOME` on every machine that had the old version. Consumers that enumerate a directory — rather than look up a known filename — then fail on the corpse: the zsh fragment loop, and lazy.nvim's `import = "plugins"` (which aborts init with `cannot open .../<name>.lua`). Run `setup.d/prune` after any such change; `./setup` now does it automatically. The zsh loop additionally self-defends via its `(N-.)` glob qualifier, but nvim has no equivalent.

Each platform-specific script self-guards on `uname -s` and exits 0 with a "skipping" message on the wrong OS — so the orchestrator can call all three blindly. Several zsh fragments (`path.zsh`, `ruby.zsh`, `fzf.zsh`) also detect the platform at runtime. When adding new dependencies, update `Brewfile`, `Pacmanfile`, and `Aptfile` to keep parity — but note `Aptfile` is a tighter curated baseline, so daemons/codecs and other non-baseline tools belong only in the macOS/Arch lists. Linux supports both Arch and Debian/Ubuntu: fzf (`/usr/share/fzf` vs `/usr/share/doc/fzf/examples`), `JAVA_HOME` (`/usr/lib/jvm/default` vs `/usr/lib/jvm/default-java`), and `fd` (aliased to `fdfind` on Debian where the binary is renamed) all have fallbacks.

## Runtime versions

Two runtime managers are supported, and **`.tool-versions` is deliberately tool-agnostic** so both read the same file. `mise` is the default for new machines; **asdf takes precedence wherever `~/.asdf` already exists**, so a machine with runtimes already provisioned under asdf keeps using them instead of re-downloading everything under mise.

Activation lives in `tag-zsh/config/zsh/zz-runtime.zsh` (named `zz-*` so it sources last and its `$PATH` prepend survives `path.zsh`'s wholesale `path=(...)` reset), with the equivalent block in `tag-bash/bashrc`. The precedence chain is:

| Condition | Activation |
|---|---|
| `~/.asdf/asdf.sh` exists | `source ~/.asdf/asdf.sh` (asdf ≤ 0.15, shell-sourced) |
| `~/.asdf/shims` exists | prepend `~/.asdf/shims` to `$PATH` (asdf ≥ 0.16 — Go rewrite, no `asdf.sh`) |
| `mise` on `$PATH` | `eval "$(mise activate zsh)"` |

`.tool-versions` at the repo root currently pins neovim 0.12.2, nodejs 24.3.0, lua 5.1, stylua 2.1.0, ruby 3.4.7. On mise machines, `setup.d/mise` installs mise (Homebrew on mac, `pacman` on arch, `mise.run` curl-installer otherwise), runs `mise install` against `.tool-versions`, then pins global defaults with `mise use -g` (lazygit, bun, python); it exits early on asdf machines. **asdf machines are provisioned manually** — `setup.d/` has no asdf equivalent, and `setup.d/neovim`'s Ruby/Python provider steps are mise-guarded, so they no-op there.

Because `.tool-versions` is directory-scoped, a runtime's **global** pin (`~/.tool-versions` for asdf, `~/.config/mise/config.toml` for mise) is what applies outside this tree — keep the two in sync for anything the nvim config depends on.

Note the split: `.tool-versions` is **directory-scoped** (active only within the repo tree), while `mise use -g` writes `~/.config/mise/config.toml` for **user-wide** defaults. Tools that must be available everywhere (lazygit, bun, python) are global pins in `setup.d/mise`, not `.tool-versions` entries.

Python is a global pin (`python@3.13.14`) precisely so it supersedes the system interpreter user-wide. On Debian/Ubuntu (and recent Arch) the apt/pacman Python is marked externally-managed (PEP 668), so `pip install` is blocked at the system level. The mise standalone Python ships its own unmanaged `pip`, and because `mise activate` prepends its bin dir, `python`/`python3`/`pip`/`pip3` resolve to mise's ahead of `/usr/bin` — superseding the system interpreter without removing it (system `python3` stays as a base/ansible dependency). Consequently the package lists no longer install `python3-pip`/`python3-pynvim` (apt), `python-pip`/`python-pynvim` (pacman), or `python@3` (brew); `setup.d/neovim` installs the `pynvim` provider into mise's Python via `mise exec`.

## Private / machine-local overrides (do not commit)

- `~/.zshrc_private` — sourced first by `tag-zsh/zshrc`, never tracked.
- `tag-zsh/config/zsh/work.zsh` — gitignored; lives in-tree but won't be committed.
- `.nvim.lua`, `.nvimrc` — gitignored per-project nvim overrides (`vim.opt.exrc` is on).

If you encounter references to env vars like `TRANSMISSION_USER_NAME` in aliases, they live in one of these private files.

## Editor architecture (nvim)

Full-Lua config, **lazy.nvim** plugin manager, leader `,`. The `lua/plugins/` directory is one-file-per-plugin (or per closely-related group). LSP setup in `lua/plugins/lsp.lua` uses Mason but prefers `bundle exec` for `ruby_lsp` and `rubocop` when a `Gemfile` is present in the project root — this is intentional, don't replace with bare-Mason invocations. Format-on-save runs through **conform.nvim** (`lua/plugins/autoformat.lua`); JS/TS uses **oxfmt**, not prettier.

The Rails projection map in `lua/plugins/projectionist.lua` is the source of truth for `:A` / `<leader>pa` alternate-file navigation — extend it there when adding new file-type pairs.

### Treesitter (main branch)

`treesitter.lua` uses **nvim-treesitter's main branch** (rewritten API), which has two hard external requirements. Both fail at parser-install time, not at startup, so the error arrives as an async message *after* nvim is already open:

| Requirement | Symptom when unmet |
|---|---|
| **Neovim ≥ 0.12** | `config.lua:171: attempt to index field 'list' (a nil value)` — `norm_languages` calls `vim.list.unique()`, a 0.12 API |
| **`tree-sitter-cli` ≥ 0.26.1** | `error during "tree-sitter build": the subcommand 'build' wasn't recognized` — `build` landed in CLI 0.22, and the plugin needs 0.26.1+ |

The CLI is a genuine dependency of this config, so it's declared: `tree-sitter-cli` in the `Brewfile` and `Pacmanfile`. It is **deliberately absent from `Aptfile`** — Debian stable (trixie) ships only 0.22.6, which is new enough to have `build` but too old for the plugin, so installing it would swap one failure for a subtler one. On Debian, get it from sid/forky or `cargo install tree-sitter-cli`. Note on Homebrew the CLI is a *separate* formula from the `tree-sitter` library; older brew versions bundled both, so a long-lived machine may have a stale `tree-sitter` that shadows nothing and satisfies nothing.

Because `.tool-versions` is directory-scoped, the neovim requirement is easy to satisfy inside this repo and miss everywhere else: the repo pins 0.12.2, but the **global** pin (`~/.tool-versions` for asdf, `~/.config/mise/config.toml` for mise) is what applies when you edit anything outside the tree. Keep the global neovim ≥ 0.12, or treesitter silently breaks in every other directory.

Two further consequences of the main-branch rewrite:

- The plugin is just a parser installer — there is no `nvim-treesitter.configs.setup()` anymore. We call `require("nvim-treesitter").install({...})` and then a `FileType` autocmd starts highlight + sets `indentexpr` per buffer. To add a parser, append it to the `parsers` list in `treesitter.lua`.
- **Removed features:** `incremental_selection` (the `<C-space>` mapping) and the textobjects keymaps (`af`/`if`/`ac`/`ic` for treesitter functions/classes) are gone — they're not in the main branch and weren't trivial to port. Vim's built-in `af`/`if` (parens, brackets, quotes) still works. Re-add via `nvim-treesitter-textobjects` (main branch) if you want them back.

Folding is owned by `nvim-ufo` (`folding.lua`), which uses treesitter parsers as its provider — independent of the `nvim-treesitter` setup change.

### oxfmt (JS/TS formatter)

Conform expects `oxfmt` on PATH for JS/TS formatting. It's a Node package installed globally via bun — `setup.d/neovim` handles this automatically. To install manually:

```sh
bun install -g oxfmt
```

If oxfmt is missing, conform just skips JS/TS formatting (warning, not error).
