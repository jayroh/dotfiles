# asdf → mise migration

**Date:** 2026-05-02
**Branch:** jro-arch
**Status:** approved, ready for implementation plan

## Goal

Replace [asdf](https://asdf-vm.com/) with [mise](https://mise.jdx.dev/) as the runtime version manager across the dotfiles repo. Clean cut — no coexistence period.

## Non-goals

- Converting `.tool-versions` to `mise.toml`. Mise reads `.tool-versions` natively; format conversion is reversible later if desired.
- Modifying `tag-ruby/rails_template/` — that subdirectory is a `rails new -m` template for generated apps, not runtime config for this repo.
- Cleaning up `~/.asdf/` on existing machines. That's a manual post-migration step the user performs after switching shells.

## Decisions

1. **Config format:** keep `.tool-versions` at repo root unchanged.
2. **Activation:** `eval "$(mise activate <shell>)"`, fronted by a `command -v mise` guard so missing-mise environments don't error on shell start.
3. **Tool invocation in editors:** rely on PATH from mise activation; do not hardcode shim paths. (Removes `~/.asdf/shims/...` paths from nvim conform config without replacing them.)
4. **Install path:** package manager where available (`brew "mise"` on mac), `curl https://mise.run | sh` fallback on linux since mise isn't in standard apt.
5. **Plugin model:** rely on mise's built-in core plugins for ruby/node/python/go. No `mise plugin add` step needed for the canonical languages.

## File-by-file changes

### Add

- **`tag-zsh/config/zsh/mise.zsh`** — new fragment, auto-sourced by the existing `for config_file (~/.config/zsh/*.zsh)` loop in `tag-zsh/zshrc`.
  ```sh
  command -v mise &>/dev/null && eval "$(mise activate zsh)"
  ```
- **`setup-mise`** — replaces `setup-asdf`. Installs mise via curl-script if not present, then provisions runtimes:
  ```sh
  mise use -g ruby@latest nodejs@latest neovim@latest lazygit@latest bun@latest stylua@latest
  ```
  Optional/commented-out lines for golang, python, rust to mirror the current `setup-asdf` plugin list.

### Modify

- **`tag-zsh/zshrc`** — remove the `[ -s "$HOME/.asdf/asdf.sh" ] && . "$HOME/.asdf/asdf.sh"` line. Mise loads via the auto-sourced `mise.zsh` fragment instead.
- **`tag-bash/bashrc`** — replace `[ -f ~/.asdf/asdf.sh ] && source ~/.asdf/asdf.sh` with `command -v mise &>/dev/null && eval "$(mise activate bash)"`.
- **`Brewfile`** — add `brew "mise"`.
- **`Aptfile`** — no change (mise not in apt; setup script handles install).
- **`setup`** — replace `./setup-asdf` with `./setup-mise`. Update the trailing `echo` reminders if they mention asdf.
- **`setup-neovim`** — replace asdf-specific Ruby loop:
  ```sh
  for version in $(mise ls ruby --json | jq -r '.[].version'); do
    mise exec ruby@$version -- gem install neovim
  done
  ```
  (Note: this assumes `jq` is available — already in `Aptfile`; needs verification on mac; fallback parser if not.)
- **`tag-nvim/config/nvim/lua/plugins/autoformat.lua`** — drop the explicit `formatters = { rubocop = { command = "~/.asdf/shims/rubocop" }, stylua = { command = "~/.asdf/shims/stylua" } }` block. Conform will find both on PATH via mise activation.
- **`CLAUDE.md`** — update the "Runtime versions" section (s/asdf/mise/, point at `setup-mise`).

### Delete

- **`setup-asdf`** — replaced wholesale.

### Untouched

- `.tool-versions` (mise reads this format directly).
- `tag-zsh/config/zsh/path.zsh` (no asdf references; mise activation handles its own PATH).
- `tag-zsh/config/zsh/ruby.zsh`, `node.zsh` (no asdf references).
- `tag-ruby/rails_template/**`.

## Verification

After implementation, on a fresh shell:

1. `which mise` → resolves to a real path.
2. `mise current` → lists ruby, nodejs, neovim, lua, stylua at versions matching `.tool-versions`.
3. `which rubocop stylua` → resolves through mise's shim/path-injection (no `~/.asdf/` in the path).
4. `nvim` opens cleanly; `:checkhealth conform` reports rubocop/stylua found.
5. `grep -r asdf ~/.dotfiles --exclude-dir=.git --exclude-dir=docs` returns nothing meaningful (only this spec or doc references, if any).

## Risks

- **`jq` availability on macOS** — `setup-neovim` will need `jq`. Add to `Brewfile` if missing, or use a `python -c` fallback to avoid the dep.
- **`Aptfile` install gap** — Linux machines won't get mise installed via `apt-get`; the setup script must handle the curl-install. Document this in the script's output.
- **Stale `~/.asdf/`** — leaving asdf shims on PATH could shadow mise during migration. Document in the migration that the user should remove `~/.asdf/` and start a new shell after running setup.
