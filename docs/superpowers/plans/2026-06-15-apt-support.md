# Apt (Debian/Ubuntu) Support Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restore first-class Debian 13 / Ubuntu 24.04 LTS support to the dotfiles setup that was removed during the `jro-arch` refactor.

**Architecture:** Add a third platform branch (apt) parallel to the existing pacman and mac branches in `setup.d/`, each self-guarding on `uname -s` and package-manager presence. Patch two shell fragments to fall back to Debian-specific paths so the same zsh/bash config works on either Linux distro. Tighten `setup.d/pacman` so it skips cleanly (exit 0) on non-Arch Linux instead of failing the orchestrator.

**Tech Stack:** Bash, zsh, apt/apt-get, thoughtbot/rcm tag layout.

**Spec:** `docs/superpowers/specs/2026-06-15-apt-support-design.md`

**Note on testing:** This repo has no test suite. "Verification" here means syntax checks (`bash -n`, `zsh -n`), confirming the script runs to its skip-message on the wrong platform, and (where reasonable) sourcing the changed shell fragment in the current shell to confirm it doesn't error. End-to-end verification requires a fresh Debian/Ubuntu VM — Task 8 covers that as the final manual gate.

---

## File Structure

**New files:**
- `Aptfile` — curated dev baseline package list (one per line, alphabetical).
- `setup.d/apt` — apt-get installer for `Aptfile`. Mirrors `setup.d/pacman`'s shape.

**Modified files:**
- `setup.d/pacman` — skip cleanly when `pacman` isn't installed (i.e. on non-Arch Linux).
- `setup` — orchestrator wires in `./setup.d/apt`.
- `tag-zsh/config/zsh/fzf.zsh` — Debian fallback path + guarded sourcing.
- `tag-bash/fzf.bash` — same fallback applied to the existing `Linux)` branch.
- `tag-zsh/config/zsh/path.zsh` — Debian `JAVA_HOME` candidate.
- `tag-zsh/config/zsh/aliases.zsh` — `fd` → `fdfind` alias on Debian.
- `CLAUDE.md` — document new script + remove the "Linux paths assume Arch" caveat.

---

## Task 1: Create curated Aptfile

**Files:**
- Create: `Aptfile`

- [ ] **Step 1: Write Aptfile**

Create `Aptfile` with exactly this content (alphabetical, one package per line):

```
ansible
autoconf
bison
build-essential
curl
direnv
fd-find
fzf
gh
git
gnupg
graphviz
jq
libffi-dev
libgmp-dev
libjemalloc-dev
libpq-dev
libreadline-dev
libssl-dev
libxml2-dev
libxslt1-dev
libyaml-dev
python3-pip
python3-pynvim
rcm
ripgrep
silversearcher-ag
tmux
universal-ctags
wget
zoxide
zsh
```

- [ ] **Step 2: Verify file is well-formed**

Run: `wc -l Aptfile && awk 'NF==0 || NF>1' Aptfile`

Expected:
- Line count is 32.
- The `awk` command prints nothing (no blank lines, no lines with multiple tokens).

- [ ] **Step 3: Commit**

```bash
git add Aptfile
git commit -m "Add Aptfile with curated Debian/Ubuntu dev baseline"
```

---

## Task 2: Make `setup.d/pacman` skip cleanly on non-Arch Linux

**Files:**
- Modify: `setup.d/pacman`

**Why this exists:** With `set -e` in `setup`, the orchestrator halts at the first failing script. `setup.d/pacman` today `exit 1`s with a "yay is required" error on any Linux box that doesn't have yay — including a fresh Debian box, where neither yay nor pacman exist. Fix: skip cleanly when `pacman` itself isn't on the system. Only complain about missing yay on a real Arch system.

- [ ] **Step 1: Insert a `pacman not found` skip before the yay check**

Current content of `setup.d/pacman` (lines 5–16):

```bash
if [[ "$(uname -s)" != "Linux" ]]; then
  echo "setup.d/pacman: skipping (not on Linux)"
  exit 0
fi

if ! command -v yay &>/dev/null; then
  echo "⚠️  yay is required (handles both pacman repos and AUR)."
  echo "   Bootstrap it with:"
  echo "     sudo pacman -S --needed git base-devel"
  echo "     git clone https://aur.archlinux.org/yay.git /tmp/yay && (cd /tmp/yay && makepkg -si)"
  exit 1
fi
```

Replace with:

```bash
if [[ "$(uname -s)" != "Linux" ]]; then
  echo "setup.d/pacman: skipping (not on Linux)"
  exit 0
fi

if ! command -v pacman &>/dev/null; then
  echo "setup.d/pacman: pacman not found, skipping (not an Arch-family system)"
  exit 0
fi

if ! command -v yay &>/dev/null; then
  echo "⚠️  yay is required (handles both pacman repos and AUR)."
  echo "   Bootstrap it with:"
  echo "     sudo pacman -S --needed git base-devel"
  echo "     git clone https://aur.archlinux.org/yay.git /tmp/yay && (cd /tmp/yay && makepkg -si)"
  exit 1
fi
```

- [ ] **Step 2: Syntax-check**

Run: `bash -n setup.d/pacman`

Expected: no output, exit code 0.

- [ ] **Step 3: Smoke-test on the current host (macOS)**

Run: `./setup.d/pacman; echo "exit=$?"`

Expected: `setup.d/pacman: skipping (not on Linux)` followed by `exit=0`.

- [ ] **Step 4: Commit**

```bash
git add setup.d/pacman
git commit -m "Skip setup.d/pacman cleanly on non-Arch Linux"
```

---

## Task 3: Add setup.d/apt and wire into orchestrator

**Files:**
- Create: `setup.d/apt`
- Modify: `setup`

- [ ] **Step 1: Create `setup.d/apt`**

Write `setup.d/apt` with exactly this content:

```bash
#!/bin/bash
# Install Debian/Ubuntu packages from Aptfile via apt-get.
set -e

if [[ "$(uname -s)" != "Linux" ]]; then
  echo "setup.d/apt: skipping (not on Linux)"
  exit 0
fi

if ! command -v apt-get &>/dev/null; then
  echo "setup.d/apt: apt-get not found, skipping (not a Debian/Ubuntu system)"
  exit 0
fi

cd "$(dirname "$0")/.."

sudo apt-get update
xargs -a Aptfile sudo apt-get install -y
```

- [ ] **Step 2: Make it executable**

Run: `chmod +x setup.d/apt`

- [ ] **Step 3: Syntax-check the script**

Run: `bash -n setup.d/apt`

Expected: no output, exit code 0.

- [ ] **Step 4: Smoke-test the on-macOS skip path**

Run: `./setup.d/apt; echo "exit=$?"`

Expected: `setup.d/apt: skipping (not on Linux)` followed by `exit=0`.

- [ ] **Step 5: Wire into orchestrator**

In `setup`, change this block:

```bash
# Platform-specific package installs (each no-ops on the wrong platform)
./setup.d/pacman
./setup.d/mac
```

…to:

```bash
# Platform-specific package installs (each no-ops on the wrong platform)
./setup.d/pacman
./setup.d/apt
./setup.d/mac
```

- [ ] **Step 6: Syntax-check the orchestrator**

Run: `bash -n setup`

Expected: no output, exit code 0.

- [ ] **Step 7: Commit**

```bash
git add setup.d/apt setup
git commit -m "Add setup.d/apt and wire into orchestrator"
```

---

## Task 4: Make fzf shell integration cross-distro

**Files:**
- Modify: `tag-zsh/config/zsh/fzf.zsh`
- Modify: `tag-bash/fzf.bash`

**Why both files together:** They're parallel implementations of the same behavior for two different shells, and they break together on Debian. Single coherent change.

- [ ] **Step 1: Rewrite `tag-zsh/config/zsh/fzf.zsh`**

Current content:

```zsh
# Setup fzf
# ---------

machine=`uname -s`
[ "$machine" = "Linux" ]  && FZF_BASE="/usr/share/fzf"
[ "$machine" = "Darwin" ] && FZF_BASE="/opt/homebrew/opt/fzf/shell"

# Auto-completion and key bindings
# ---------------
source "$FZF_BASE/completion.zsh"
source "$FZF_BASE/key-bindings.zsh"
```

Replace with:

```zsh
# Setup fzf
# ---------

machine=$(uname -s)
if [ "$machine" = "Darwin" ]; then
  FZF_BASE="/opt/homebrew/opt/fzf/shell"
elif [ "$machine" = "Linux" ]; then
  if   [ -d /usr/share/fzf ];              then FZF_BASE="/usr/share/fzf"              # arch
  elif [ -d /usr/share/doc/fzf/examples ]; then FZF_BASE="/usr/share/doc/fzf/examples" # debian
  fi
fi

# Auto-completion and key bindings
# ---------------
[ -n "$FZF_BASE" ] && {
  [ -r "$FZF_BASE/completion.zsh" ]   && source "$FZF_BASE/completion.zsh"
  [ -r "$FZF_BASE/key-bindings.zsh" ] && source "$FZF_BASE/key-bindings.zsh"
}
```

- [ ] **Step 2: Syntax-check the zsh fragment**

Run: `zsh -n tag-zsh/config/zsh/fzf.zsh`

Expected: no output, exit code 0.

- [ ] **Step 3: Source it in a fresh subshell**

Run: `zsh -c 'source tag-zsh/config/zsh/fzf.zsh && echo OK'`

Expected: prints `OK`. (May or may not load fzf completions depending on local install; not erroring is the success criterion.)

- [ ] **Step 4: Rewrite the `Linux)` branch of `tag-bash/fzf.bash`**

Current content:

```bash
# Setup fzf
# ---------
case "$(uname -s)" in
  Darwin)
    if [[ ! "$PATH" == */opt/homebrew/opt/fzf/bin* ]]; then
      PATH="${PATH:+${PATH}:}/opt/homebrew/opt/fzf/bin"
      source "/opt/homebrew/opt/fzf/shell/completion.bash"
      source "/opt/homebrew/opt/fzf/shell/key-bindings.bash"
    fi
    ;;
  Linux)
    [ -r /usr/share/fzf/completion.bash ]   && source /usr/share/fzf/completion.bash
    [ -r /usr/share/fzf/key-bindings.bash ] && source /usr/share/fzf/key-bindings.bash
    ;;
esac
```

Replace the entire file with:

```bash
# Setup fzf
# ---------
case "$(uname -s)" in
  Darwin)
    if [[ ! "$PATH" == */opt/homebrew/opt/fzf/bin* ]]; then
      PATH="${PATH:+${PATH}:}/opt/homebrew/opt/fzf/bin"
      source "/opt/homebrew/opt/fzf/shell/completion.bash"
      source "/opt/homebrew/opt/fzf/shell/key-bindings.bash"
    fi
    ;;
  Linux)
    if   [ -d /usr/share/fzf ];              then FZF_BASE="/usr/share/fzf"
    elif [ -d /usr/share/doc/fzf/examples ]; then FZF_BASE="/usr/share/doc/fzf/examples"
    fi
    [ -n "$FZF_BASE" ] && {
      [ -r "$FZF_BASE/completion.bash" ]   && source "$FZF_BASE/completion.bash"
      [ -r "$FZF_BASE/key-bindings.bash" ] && source "$FZF_BASE/key-bindings.bash"
    }
    ;;
esac
```

- [ ] **Step 5: Syntax-check the bash fragment**

Run: `bash -n tag-bash/fzf.bash`

Expected: no output, exit code 0.

- [ ] **Step 6: Commit**

```bash
git add tag-zsh/config/zsh/fzf.zsh tag-bash/fzf.bash
git commit -m "Make fzf shell integration cross-distro (debian fallback)"
```

---

## Task 5: Add Debian `JAVA_HOME` candidate

**Files:**
- Modify: `tag-zsh/config/zsh/path.zsh`

- [ ] **Step 1: Edit `tag-zsh/config/zsh/path.zsh`**

Replace these two lines at the top of the file:

```zsh
[[ -d /usr/lib/jvm/default ]]              && export JAVA_HOME="/usr/lib/jvm/default"
[[ -x /usr/libexec/java_home ]]            && export JAVA_HOME=$(/usr/libexec/java_home)
```

With these three lines:

```zsh
[[ -d /usr/lib/jvm/default ]]              && export JAVA_HOME="/usr/lib/jvm/default"        # arch
[[ -d /usr/lib/jvm/default-java ]]         && export JAVA_HOME="/usr/lib/jvm/default-java"   # debian
[[ -x /usr/libexec/java_home ]]            && export JAVA_HOME=$(/usr/libexec/java_home)     # macOS
```

(Indentation and the trailing `[[ -d "$HOME/.nvm" ]] && export NVM_DIR="$HOME/.nvm"` line stay untouched.)

- [ ] **Step 2: Syntax-check**

Run: `zsh -n tag-zsh/config/zsh/path.zsh`

Expected: no output, exit code 0.

- [ ] **Step 3: Source-test on the current host**

Run: `zsh -c 'source tag-zsh/config/zsh/path.zsh && echo "JAVA_HOME=$JAVA_HOME"'`

Expected on macOS: `JAVA_HOME=` followed by a real macOS path (e.g. `/Library/Java/JavaVirtualMachines/...`) **or** an empty value if no JDK is installed. Not an error.

- [ ] **Step 4: Commit**

```bash
git add tag-zsh/config/zsh/path.zsh
git commit -m "Add Debian JAVA_HOME candidate to path.zsh"
```

---

## Task 6: Alias `fd` → `fdfind` on Debian

**Files:**
- Modify: `tag-zsh/config/zsh/aliases.zsh`

- [ ] **Step 1: Inspect the current file**

Run: `cat tag-zsh/config/zsh/aliases.zsh`

Read the file. Identify a sensible insertion point (end of file is fine if there's no obvious section grouping).

- [ ] **Step 2: Append the alias line**

Append this exact block to the end of `tag-zsh/config/zsh/aliases.zsh` (with a leading blank line if the file doesn't end in one):

```zsh
# On Debian/Ubuntu the fd binary is named fdfind; alias it back to fd.
command -v fdfind &>/dev/null && ! command -v fd &>/dev/null && alias fd=fdfind
```

- [ ] **Step 3: Syntax-check**

Run: `zsh -n tag-zsh/config/zsh/aliases.zsh`

Expected: no output, exit code 0.

- [ ] **Step 4: Source-test**

Run: `zsh -c 'source tag-zsh/config/zsh/aliases.zsh && echo OK'`

Expected: prints `OK`.

- [ ] **Step 5: Commit**

```bash
git add tag-zsh/config/zsh/aliases.zsh
git commit -m "Alias fd to fdfind on Debian (where the binary is renamed)"
```

---

## Task 7: Update CLAUDE.md

**Files:**
- Modify: `CLAUDE.md`

- [ ] **Step 1: Update the setup architecture table**

Find this row in the table under the "Setup architecture" heading:

```
| `setup.d/pacman` | Linux: install `Pacmanfile` via `yay`. No-ops on mac. |
```

Replace the description so the new "skip on non-Arch Linux" behavior is documented:

```
| `setup.d/pacman` | Linux (Arch): install `Pacmanfile` via `yay`. No-ops on mac and on non-Arch Linux. |
```

Then insert a new row immediately after it:

```
| `setup.d/apt` | Linux (Debian/Ubuntu): install `Aptfile` via `apt-get`. No-ops on mac and on Linux without `apt-get`. |
```

- [ ] **Step 2: Update the orchestrator order paragraph**

In the paragraph below the table, find this sentence:

> Linux paths assume Arch (`/usr/share/fzf`, `/usr/lib/jvm/default`, etc.) — adjust if porting to another distro.

Replace it with:

> Linux supports both Arch and Debian/Ubuntu: fzf (`/usr/share/fzf` vs `/usr/share/doc/fzf/examples`), `JAVA_HOME` (`/usr/lib/jvm/default` vs `/usr/lib/jvm/default-java`), and `fd` (aliased to `fdfind` on Debian where the binary is renamed) all have fallbacks. `Aptfile` is intentionally a tighter dev baseline than `Pacmanfile` — apt and pacman lists are allowed to drift.

- [ ] **Step 3: Update the parity note**

In the same paragraph, find:

> When adding new dependencies, update both `Brewfile` and `Pacmanfile` to keep parity.

Replace with:

> When adding new dependencies, update `Brewfile`, `Pacmanfile`, and `Aptfile` to keep parity — but note `Aptfile` is a tighter curated baseline, so daemons/codecs and other non-baseline tools belong in only the macOS/Arch lists.

- [ ] **Step 4: Verify the edits read cleanly**

Run: `grep -n "apt\|Apt\|debian\|Debian" CLAUDE.md`

Expected: lines for `setup.d/apt`, the `Aptfile` parity note, and the Debian fallbacks sentence. Visually scan to confirm no garbled merges.

- [ ] **Step 5: Commit**

```bash
git add CLAUDE.md
git commit -m "Document apt support and cross-distro Linux paths in CLAUDE.md"
```

---

## Task 8: Manual end-to-end verification on a Debian/Ubuntu VM

**Files:** (none — verification only)

This task can't be automated from the dev machine. Do it on a fresh VM before merging the branch.

- [ ] **Step 1: Spin up a fresh VM**

Use Multipass, OrbStack, UTM, or any VM tool: a fresh **Ubuntu 24.04 LTS** or **Debian 13** instance.

- [ ] **Step 2: Install minimal prerequisites and clone**

Inside the VM:

```bash
sudo apt-get update
sudo apt-get install -y git
git clone <this-repo-url> ~/.dotfiles
cd ~/.dotfiles
git checkout jro-arch
```

- [ ] **Step 3: Run setup**

```bash
./setup
```

Expected sequence:
- `setup.d/pacman`: prints `setup.d/pacman: pacman not found, skipping (not an Arch-family system)` and exits 0.
- `setup.d/apt`: runs `apt-get update`, installs every package in `Aptfile`, completes without error.
- `setup.d/mac`: prints `setup.d/mac: skipping (not on macOS)`.
- Remaining steps (`shell`, `mise`, `bunnai`, `neovim`, `tmux`, `omarchy`, `rcup`) complete successfully.

- [ ] **Step 4: Smoke-test the shell**

```bash
zsh -i -c 'echo "ZDOTDIR ok"; command -v fd; echo "JAVA_HOME=$JAVA_HOME"; type _fzf_complete 2>/dev/null | head -1'
```

Expected:
- Prints `ZDOTDIR ok`.
- `command -v fd` resolves (via the Debian `fdfind` alias).
- `JAVA_HOME` is empty (no JDK in baseline) or set to `/usr/lib/jvm/default-java` if a JDK is present — not an error.
- `_fzf_complete` resolves to a shell function (proves the Debian fzf paths loaded).

- [ ] **Step 5: Confirm rcm linked tags**

```bash
ls -la ~/.zshrc ~/.config/zsh/ ~/.config/nvim/init.lua
```

Expected: all are symlinks pointing into `~/.dotfiles/tag-*/`.

- [ ] **Step 6: Re-run setup (idempotency check)**

```bash
./setup
```

Expected: completes without error; `apt-get install` reports everything already at latest version.

- [ ] **Step 7: Final commit / merge prep**

If anything failed in steps 1–6, return to the failing task in this plan, fix, and re-run from Step 3. Otherwise the branch is ready to merge.

```bash
git log --oneline main..HEAD
```

Expected: seven commits from Tasks 1–7 (plus the spec/plan commits from earlier).

---

## Spec Coverage Self-Review

| Spec requirement | Covered by |
|---|---|
| New `Aptfile` (curated baseline) | Task 1 |
| `setup.d/pacman` skips cleanly on non-Arch Linux | Task 2 |
| New `setup.d/apt` (mirrors pacman) | Task 3 |
| Orchestrator wires apt between pacman and mac | Task 3 Step 5 |
| fzf.zsh Debian fallback + guarded sourcing | Task 4 Step 1 |
| fzf.bash Debian fallback | Task 4 Step 4 |
| path.zsh Debian `JAVA_HOME` candidate | Task 5 |
| `fd` → `fdfind` alias on Debian | Task 6 |
| CLAUDE.md docs for new script + cross-distro note | Task 7 |
| End-to-end verification on a Debian/Ubuntu VM | Task 8 |
