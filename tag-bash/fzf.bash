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
