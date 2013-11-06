ZSH=$HOME/.oh-my-zsh
ZSH_THEME="robbyrussell"
# CASE_SENSITIVE="true"
# DISABLE_AUTO_UPDATE="true"
# DISABLE_LS_COLORS="true"
# DISABLE_AUTO_TITLE="true"
# COMPLETION_WAITING_DOTS="true"

plugins=(git)

export PATH=./bin:/usr/local/share/npm/bin/:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/usr/X11/bin
export PATH="$HOME/.rbenv/bin:$PATH"

source $ZSH/oh-my-zsh.sh
source `find /usr/local/Cellar/zsh-syntax-highlighting -name zsh-syntax-highlighting.plugin.zsh`

alias g=/usr/local/bin/git
alias gf='/usr/local/bin/git fetch'
alias glog="/usr/local/bin/git log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --date=relative -25"
alias gpom='/usr/local/bin/git pull origin master'
alias gti=/usr/local/bin/git
alias gut=/usr/local/bin/git
alias sb='/usr/local/bin/git status -sb'

alias attach='tmux attach -t'
alias be='bundle exec'
alias ctag_refresh='ctags -R --exclude=.git --exclude=log *'
alias grep_history='history | grep'
alias restore_to='pg_restore --verbose --clean --no-acl --no-owner -d '
alias session='tmux new -s'
alias zs='zeus rspec'

[[ -f `brew --prefix`/etc/autojump.sh ]] && . `brew --prefix`/etc/autojump.sh
eval "$(rbenv init -)"
