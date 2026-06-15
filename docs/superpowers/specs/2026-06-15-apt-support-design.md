# Apt (Debian/Ubuntu) support

## Context

This branch (`jro-arch`) refactored the dotfiles setup around `rcm` tags and
a `setup.d/` orchestrator, and in the process removed the previous apt
support: `Aptfile` and `Snapfile.classic` were deleted, and the old monolithic
`setup` script lost its `uname -s = Linux` branch. The orchestrator now only
calls `setup.d/pacman` (Arch via `yay`) and `setup.d/mac` (Homebrew). The
result: macOS and Arch are first-class targets; a fresh Debian or Ubuntu box
has no package-install path.

Additionally, two shell fragments hard-code Arch-only Linux paths:

- `tag-zsh/config/zsh/fzf.zsh` and `tag-bash/fzf.bash` point at `/usr/share/fzf`.
- `tag-zsh/config/zsh/path.zsh` sets `JAVA_HOME=/usr/lib/jvm/default`.

CLAUDE.md acknowledges this drift ("Linux paths assume Arch — adjust if
porting to another distro"). This spec is the adjustment.

## Goal

Restore first-class support for apt-based Linux on Ubuntu 24.04 LTS and
Debian 13, without disturbing the existing macOS and Arch flows. The
expected outcome: running `./setup` on a fresh Debian 13 / Ubuntu 24.04
box completes successfully and produces a working dev environment
equivalent to the curated baseline below.

## Non-goals

- Supporting older Debian/Ubuntu releases. Targeting Debian 13 / Ubuntu
  24.04 means `mise`, `zoxide`, `gh`, `fd-find`, `ripgrep`, `rcm`, and
  the rest of the baseline are in default repos with no PPA dance.
- Maintaining package parity between `Aptfile` and `Pacmanfile`.
  Pacmanfile has accumulated codec/daemon packages (`x264`, `ffmpeg`,
  `redis`, `memcached`, `pgcli`, `jdk-openjdk`, `s3cmd`, `docker-*`)
  that aren't part of a "dev baseline." Apt and pacman flows are
  intentionally allowed to drift; install those on demand.
- Restoring `Snapfile.classic`. Deleted intentionally on this branch; not revived.
- Docker setup on Debian (different repo dance; install on demand).
- Font installation on Linux beyond what's already documented in the
  `setup` post-run echo (same `fc-cache` instructions apply on Debian).

## Approach

Add a third platform branch parallel to the existing two, following the
same self-guarding pattern documented in CLAUDE.md ("each platform-specific
script self-guards on `uname -s` and exits 0 with a 'skipping' message on
the wrong OS"). Then fix the few shell fragments that hard-code Arch paths
so the same zsh/bash config works on either Linux distro.

## Architecture

### New files

**`Aptfile`** at repo root — curated dev baseline:

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

Rationale for inclusions/exclusions:

- `build-essential`, `autoconf`, `bison`, `libreadline-dev`, `libssl-dev`,
  `libffi-dev`, `libyaml-dev`, `libgmp-dev` are present so mise can build
  Ruby from source. Pacmanfile gets these implicitly through Arch's
  `base-devel` meta-package; on Debian they must be listed.
- `neovim`, `nodejs`, `ruby`, `lua` are **not** in `Aptfile` — mise owns
  those via `.tool-versions`.
- `mise` itself is **not** in `Aptfile` (not packaged for Debian 13).
  `setup.d/mise` already has a curl-installer fallback that handles this.
- `python3-psycopg2` from Pacmanfile is dropped (use venvs + pip; not a
  baseline need).
- Codec and daemon packages from Pacmanfile (`ffmpeg`, `x264`, `x265`,
  `xvidcore`, `libwebp`, `unrar`, `redis`, `memcached`, `pgcli`,
  `jdk-openjdk`, `s3cmd`, `docker-buildx`, `docker-compose`) are
  intentionally absent.

**`setup.d/apt`** — mirrors `setup.d/pacman`'s shape:

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

Two-layer self-guard: first `uname -s` (skip on macOS), then `command -v
apt-get` (skip on Arch even though that's also Linux). The `xargs -a`
form handles an empty/trailing-newline Aptfile cleanly. `apt-get update`
is needed because Debian doesn't refresh package lists implicitly the way
`yay` does.

### Modified files

**`setup`** orchestrator — insert the new step between pacman and mac:

```diff
 ./setup.d/pacman
+./setup.d/apt
 ./setup.d/mac
```

All three are mutually exclusive at runtime; each no-ops where it doesn't
apply.

**`tag-zsh/config/zsh/fzf.zsh`** — Debian fallback path and guarded sourcing:

```zsh
machine=$(uname -s)
if [ "$machine" = "Darwin" ]; then
  FZF_BASE="/opt/homebrew/opt/fzf/shell"
elif [ "$machine" = "Linux" ]; then
  if   [ -d /usr/share/fzf ];              then FZF_BASE="/usr/share/fzf"              # arch
  elif [ -d /usr/share/doc/fzf/examples ]; then FZF_BASE="/usr/share/doc/fzf/examples" # debian
  fi
fi

[ -n "$FZF_BASE" ] && {
  [ -r "$FZF_BASE/completion.zsh" ]   && source "$FZF_BASE/completion.zsh"
  [ -r "$FZF_BASE/key-bindings.zsh" ] && source "$FZF_BASE/key-bindings.zsh"
}
```

The `[ -r ]` guards also make the file safe to source on a Linux box
where fzf isn't installed yet (previously it would error).

**`tag-bash/fzf.bash`** — same fallback applied to the existing `Linux)`
branch:

```bash
Linux)
  if   [ -d /usr/share/fzf ];              then FZF_BASE="/usr/share/fzf"
  elif [ -d /usr/share/doc/fzf/examples ]; then FZF_BASE="/usr/share/doc/fzf/examples"
  fi
  [ -n "$FZF_BASE" ] && {
    [ -r "$FZF_BASE/completion.bash" ]   && source "$FZF_BASE/completion.bash"
    [ -r "$FZF_BASE/key-bindings.bash" ] && source "$FZF_BASE/key-bindings.bash"
  }
  ;;
```

**`tag-zsh/config/zsh/path.zsh`** — add Debian's `JAVA_HOME` candidate
before the macOS override:

```zsh
[[ -d /usr/lib/jvm/default ]]      && export JAVA_HOME="/usr/lib/jvm/default"        # arch
[[ -d /usr/lib/jvm/default-java ]] && export JAVA_HOME="/usr/lib/jvm/default-java"   # debian
[[ -x /usr/libexec/java_home ]]    && export JAVA_HOME=$(/usr/libexec/java_home)     # macOS
```

Order matters: the macOS check uses `-x` against a script that doesn't
exist on Linux, so it never fires there. On Linux, the Debian line
overrides the Arch line only if `/usr/lib/jvm/default-java` exists —
which it doesn't on Arch.

**`tag-zsh/config/zsh/aliases.zsh`** — alias `fd` to `fdfind` on Debian
where the binary is renamed:

```zsh
command -v fdfind &>/dev/null && ! command -v fd &>/dev/null && alias fd=fdfind
```

Self-guarded: no-op on Arch/macOS where `fd` exists under its real name.

**`CLAUDE.md`** updates:

- Add `setup.d/apt` row to the setup architecture table.
- Update the orchestrator order line in the same section.
- Replace the "Linux paths assume Arch" note: fzf now falls back on
  Debian; `JAVA_HOME` handles both distros; `fd` is aliased to `fdfind`
  on Debian.
- Add a note that `Aptfile` is a curated baseline (no daemons/codecs) and
  Pacmanfile is broader by historical accident — drift is accepted.

## Error handling and edge cases

- `setup.d/apt` and `setup.d/pacman` both `command -v` for their tool.
  On a Linux machine that has both apt and pacman (extremely unusual —
  derivatives like pacapt don't ship real `apt-get`), both scripts would
  run. Acceptable; not worth detecting.
- `apt-get install` is idempotent on already-installed packages; safe to
  re-run `./setup` on a configured box.
- `setup.d/mise`'s existing fallbacks (brew → pacman → curl-installer)
  cover Debian via the curl branch — no change needed.
- `setup.d/shell`'s `tic` calls require `ncurses-bin`. That package is
  `Essential: yes` on Debian/Ubuntu — always pre-installed — so no
  Aptfile entry is needed.

## Verification

- Fresh Debian 13 VM: `./setup` completes, `which zsh` returns a real
  path, `zsh -c 'source ~/.zshrc'` runs without errors, `fzf` keybindings
  load, `rcup` linked the tags into `$HOME`.
- Fresh Ubuntu 24.04 VM: same.
- Existing Arch box: `./setup.d/apt` prints its skip message and exits 0;
  no regression in `setup.d/pacman` path.
- macOS: `./setup.d/apt` prints its skip message and exits 0; no
  regression in `setup.d/mac` path.
