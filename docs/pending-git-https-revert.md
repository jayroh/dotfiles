# PENDING: revert the git-over-HTTPS workaround

**Added:** 2026-08-15, on airplane wifi
**Nothing to do with herdr** — this is a temporary network workaround that got
committed to `tag-git/gitconfig` and needs undoing.

## Do this when you're back on a normal network

```sh
git config --global --unset url."https://github.com/".insteadOf
```

Then confirm SSH works again:

```sh
ssh -T git@github.com     # expect "Hi jayroh! You've successfully authenticated"
```

**Watch out:** that `--unset` writes to `~/.gitconfig`, which is a symlink to
`tag-git/gitconfig` in this repo — so it will show up as a repo change to commit,
not as a local-only tweak.

## What to keep

Keep the `[credential "https://github.com"]` helper blocks. They let HTTPS
operations authenticate with your existing `gh` token instead of a PAT, which is
useful on any network. They were made PATH-relative (`!gh` rather than
`!/opt/homebrew/bin/gh`) so they also resolve on Linux, where gh is `/usr/bin/gh`.

Keep the `[include] path = ~/.gitconfig_local` block too — see below.

## Why it was needed

Airplane wifi accepts TCP connections on any port but only passes real traffic
for HTTP/HTTPS. The symptom was `git fetch`/`git pull` hanging indefinitely.

Evidence gathered at the time:

| Check | Result |
|---|---|
| `nc -z github.com 22` | succeeds in 0.6s — TCP connect is fine |
| SSH banner from `github.com:22` | never arrives |
| SSH banner from `ssh.github.com:443` | never arrives |
| `ssh -v` | `Connection timed out during banner exchange` |
| `curl https://github.com` | `200`, 2.0s |
| `git ls-remote https://github.com/git/git.git` | works |

So the connection was accepted and then blackholed — SSH specifically, on
**both** ports.

Note `~/.ssh/config` already routes `github.com` → `ssh.github.com:443`, which is
the standard workaround for networks that block port 22. It did not help here
because this network kills SSH on any port, not just 22. **No change to
`~/.ssh/config` is needed** — it is correct for the normal case.

`url.insteadOf` rewrites `git@github.com:` remotes to HTTPS at runtime without
touching any repository's stored remote, so reverting is the single command above
with no per-repo cleanup. `git remote -v` displays the rewritten form while the
rule is active; `git config --get remote.origin.url` still shows the real SSH URL.

## The lesson worth keeping

`~/.gitconfig` is a symlink into this repo, so **`git config --global` writes to
version control**. That is how a temporary flight workaround ended up committed.

An `[include] path = ~/.gitconfig_local` was added at the bottom of
`tag-git/gitconfig` for exactly this — machine-local or session-local git
settings belong in `~/.gitconfig_local`, which is untracked, mirroring how
`~/.zshrc_private` already works for zsh. Last include wins, so anything there
overrides the tracked config.
