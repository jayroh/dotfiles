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
