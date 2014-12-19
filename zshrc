ZSH=$HOME/.oh-my-zsh
ZSH_THEME="robbyrussell"

plugins=(git zsh-syntax-highlighting)

export PATH=./bin:/usr/local/share/npm/bin/:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/usr/X11/bin
export PATH="/usr/local/bin:$PATH"
export PATH="$HOME/.rbenv/bin:$PATH"
export PATH="/opt/homebrew-cask/Caskroom/postgres/latest/Postgres.app/Contents/MacOS/bin:$PATH"

[[ -f $HOME/.rubymotion ]] && source $HOME/.rubymotion
source $ZSH/oh-my-zsh.sh

[[ -f /usr/local/bin/git ]] && ORIG_GIT='/usr/local/bin/git' && alias g=/usr/local/bin/git
[[ -f /usr/bin/git ]] && ORIG_GIT='/usr/bin/git' && alias g=/usr/bin/git
alias gf="$ORIG_GIT fetch"
alias glog="$ORIG_GIT log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --date=relative -25"
alias gpom="$ORIG_GIT pull origin master"
alias git='echo "use g"'
alias gti='echo "use g"'
alias gut='echo "use g"'
alias sb="$ORIG_GIT status -sb"
alias gap='sed -i "" "s/binding\.pry\s*//g" `g diff --name-only`'

alias attach='tmux attach -t'
alias be='bundle exec'
alias ctag_refresh='ctags -R --exclude=.git --exclude=log *'
alias grep_history='history | grep'
alias restore_to='pg_restore --verbose --clean --no-acl --no-owner -d '
alias session='tmux new -s'
alias zs='zeus rspec'

do_brew() {
  [[ -f `brew --prefix`/etc/autojump.sh ]] && . `brew --prefix`/etc/autojump.sh
}

do_rbenv() {
  eval "$(rbenv init -)"
}

command -v brew >/dev/null && do_brew
command -v rbenv >/dev/null && do_rbenv
