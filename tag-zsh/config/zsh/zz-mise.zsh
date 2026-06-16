# Named zz-* so it sources LAST. `mise activate` prepends mise's bin dirs to
# $PATH, but path.zsh does a wholesale `path=(...)` reset that would wipe them
# (and mise's precmd hook won't restore them — its __MISE_DIFF state thinks the
# diff is already applied). Activating after every PATH-building fragment keeps
# mise-managed binaries (nvim, node, ruby, bun, ...) reachable.
command -v mise &>/dev/null && eval "$(mise activate zsh)"
