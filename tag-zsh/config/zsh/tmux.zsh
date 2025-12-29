# start, or attach to, tmux session based on PWD basename
t() {
  PROJ_NAME=$(basename $PWD | sed 's/\.//g')
  export TERM=tmux-256color

  tmux has-session -t $PROJ_NAME 2>/dev/null

  if [ "$?" -eq 1 ] ; then
    echo "Project not found. Creating and configuring."
    tmux new-session -d -s $PROJ_NAME

    # Probably editing in here, so ...
    tmux rename-window "vim"

    # Probably going to need a "server" window, so ...
    tmux neww -n server

    # Probably going to need a "claude" window, so ...
    tmux neww -n claude

    # Go back to vim window ...
    tmux select-window -t :1
  else
    echo "Project found. Connecting."
  fi

  tmux attach-session -t $PROJ_NAME
}
