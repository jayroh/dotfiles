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
