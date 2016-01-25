ZSH=$HOME/.oh-my-zsh
ZSH_THEME="robbyrussell"

plugins=(zsh-syntax-highlighting)

export PATH=./bin:/usr/local/share/npm/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/usr/X11/bin
export PATH="/usr/local/bin:$PATH"
export PATH="$HOME/.rbenv/bin:$PATH"
export PATH="/opt/homebrew-cask/Caskroom/postgres/latest/Postgres.app/Contents/MacOS/bin:$PATH"

[[ -f $HOME/.rubymotion ]] && source $HOME/.rubymotion
source $ZSH/oh-my-zsh.sh

[[ -f /usr/local/bin/git ]] && ORIG_GIT='/usr/local/bin/git' && alias g=/usr/local/bin/git
[[ -f /usr/bin/git ]] && ORIG_GIT='/usr/bin/git' && alias g=/usr/bin/git
alias s="$ORIG_GIT status"
alias p="$ORIG_GIT push"
alias pf="$ORIG_GIT push -f"
alias gf="$ORIG_GIT fetch"
alias glog="$ORIG_GIT log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --date=relative -40"
alias gpom="$ORIG_GIT pull origin master"
alias git='echo "use g"'
alias gti='echo "use g"'
alias gut='echo "use g"'
alias curl='echo "*******\nYou should use http instead\n*******\n" && sleep 2 && /usr/bin/curl'
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

ssh_backup() {
  cd
  tar -czf ssh.tgz .ssh
  openssl enc -aes256 -in ssh.tgz -out ssh.tgz.enc -salt
  rm ssh.tgz
  echo "ssh directory backed up to ssh.tgz.enc"
}

ssh_restore() {
  cd
  openssl enc -aes256 -in ssh.tgz.enc -out ssh.tgz -salt -d
  tar xzf ssh.tgz
  rm ssh.tgz
  echo "ssh directory restored to .ssh"
}

command -v brew >/dev/null && do_brew
command -v rbenv >/dev/null && do_rbenv

# added by travis gem
[ -f /Users/joel/.travis/travis.sh ] && source /Users/joel/.travis/travis.sh

# added per instructions from awscli install
source /usr/local/share/zsh/site-functions/_aws
eval `boot2docker shellinit 2>/dev/null`
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
