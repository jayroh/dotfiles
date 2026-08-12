# Runtime version manager activation. asdf wins when present; mise otherwise.
#
# Both managers read the same tool-agnostic `.tool-versions`, so a machine can
# run either one without the repo changing. Precedence is asdf-first because a
# machine that already has runtimes installed under ~/.asdf should keep using
# them rather than re-provisioning everything under mise. Machines without asdf
# get mise, which is the default for new setups.
#
# Named zz-* so it sources LAST. Both managers prepend their shim/bin dirs to
# $PATH, but path.zsh does a wholesale `path=(...)` reset that would wipe them
# (and mise's precmd hook won't restore them — its __MISE_DIFF state thinks the
# diff is already applied). Activating after every PATH-building fragment keeps
# managed binaries (nvim, node, ruby, bun, ...) reachable.

if [[ -f ~/.asdf/asdf.sh ]]; then
	# asdf <= 0.15: shell-sourced. Defines the `asdf` function and puts
	# ~/.asdf/bin + ~/.asdf/shims on $PATH (idempotently — it checks first).
	source ~/.asdf/asdf.sh
elif [[ -d ~/.asdf/shims ]]; then
	# asdf >= 0.16: rewritten as a Go binary, asdf.sh no longer exists. There
	# is nothing to source — activation is just putting the shims on $PATH.
	path=(
		"$HOME/.asdf/shims"
		$path
	)
elif command -v mise &>/dev/null; then
	eval "$(mise activate zsh)"
fi
