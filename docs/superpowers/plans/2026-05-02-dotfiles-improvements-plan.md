# Dotfiles improvements — punch list

**Date:** 2026-05-02

10 candidate improvements identified after the asdf→mise / debian→arch / setup-modularization / nvim 0.12 work. Quick wins below the line are being applied immediately; the rest are tracked for follow-up.

---

## Quick wins (apply now)

### 1. autojump → zoxide
- [x] **Why:** autojump is unmaintained; zoxide is its modern Rust replacement, faster scoring algorithm, actively developed.
- **Files:** `Pacmanfile` (autojump → zoxide), delete `tag-zsh/config/zsh/autojump.zsh`, create `tag-zsh/config/zsh/zoxide.zsh` with `eval "$(zoxide init zsh --cmd j)"` so `j` muscle memory keeps working.

### 2. Fix broken `alias ls='ls -G'` on Linux
- [x] **Why:** GNU `ls -G` means "hide groups," not colorize. `tag-zsh/config/zsh/aliases.zsh` has been silently broken on Linux since the user moved to Arch.
- **Files:** `tag-zsh/config/zsh/aliases.zsh` — branch on `$(uname -s)`: `--color=auto` on Linux, `-G` on Darwin.

### 3. Drop dead lines in `init.lua`
- [x] **Why:** All three are no-ops on nvim 0.12.2:
  - `vim.opt.secure = true` — option removed in nvim 0.10
  - `vim.cmd("runtime macros/matchit.vim")` — matchit is built in
  - `vim.g.vsnip_snippet_dir = "~/.dotfiles/tag-nvim/snippets"` — vsnip not installed; using blink.cmp
- **Files:** `tag-nvim/config/nvim/init.lua`

### 4. Prune stale paths in `path.zsh`
- [x] **Why:** Specific old versions that won't resolve on a current Arch box (and didn't on a current mac either).
  - `Qt5.5.1` (released 2015)
  - homebrew `bison@2.7`
  - homebrew `imagemagick@6`
- **Files:** `tag-zsh/config/zsh/path.zsh`. (Leave `PG_APP_BIN` — already guarded, useful if returning to mac.)

### 5. Fix `httpserver()` python 2 → python 3
- [x] **Why:** `python -m SimpleHTTPServer` is Python 2; on a modern Arch box `python` is 3.x and the module is `http.server`.
- **Files:** `tag-zsh/config/zsh/util.zsh`

---

## Bigger improvements (deferred)

### 6. Snippet location consolidation
- [ ] Two snippet dirs exist: `tag-nvim/snippets/` (vsnip-era) and `tag-nvim/config/nvim/snippets/` (blink.cmp). Delete the vsnip dir; blink.cmp is the active path.

### 7. Add `which-key.nvim`
- [ ] Many leader-prefixed mappings (`<leader>p*`, `<leader>t*`, `<leader>n*`, `<leader>g*`, `<leader>r*`). which-key shows a discoverable popup after a `<leader>` pause. Snacks already has a `Snacks.toggle` integration that flagged which-key as missing in checkhealth.

### 8. `.editorconfig` at repo root
- [ ] One file to make shell/lua/yaml/markdown indentation consistent across editors. Useful when editing on a remote machine without nvim config available.

### 9. eslint → oxlint
- [ ] Symmetry with the prettier→oxfmt move. Same Oxc team, same speed story. Touches `lua/plugins/lsp.lua` (drop eslint server) plus install of `oxlint` similar to oxfmt.

### 10. Re-evaluate dropped treesitter features
- [ ] `nvim-treesitter-textobjects` (main branch) for `af`/`if`/`ac`/`ic` and a manual incremental selection mapping. Defer until you notice you miss them — if a week passes without complaint, they weren't earning their keep.
