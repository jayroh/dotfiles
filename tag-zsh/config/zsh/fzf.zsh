# Setup fzf
# ---------

machine=`uname -s`
[ "$machine" = "Linux" ]  && FZF_BASE="/usr/share/fzf"
[ "$machine" = "Darwin" ] && FZF_BASE="/opt/homebrew/opt/fzf/shell"

# Auto-completion and key bindings
# ---------------
source "$FZF_BASE/completion.zsh"
source "$FZF_BASE/key-bindings.zsh"
