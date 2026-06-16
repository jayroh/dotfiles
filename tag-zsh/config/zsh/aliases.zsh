# convenience
case "$(uname -s)" in
  Darwin) alias ls='ls -G' ;;
  Linux)  alias ls='ls --color=auto' ;;
esac
alias Grep='grep'
alias hist='history'
alias his='history'
alias iv='nvim'
alias vi='nvim'
alias vim='nvim'

if [ -x "$(command -v brew)" ]; then
  alias ctags="`brew --prefix`/bin/ctags"
fi

# On Debian/Ubuntu the fd binary is named fdfind; alias it back to fd.
command -v fdfind &>/dev/null && ! command -v fd &>/dev/null && alias fd=fdfind

# ruby
alias be='echo "No need for bundle exec. Use binstubs."'

# rails
alias migrate='bundle exec rake db:migrate; bundle exec rake db:migrate RAILS_ENV=test'
alias rollback='bundle exec rake db:rollback; bundle exec rake db:rollback RAILS_ENV=test'
alias features='bundle exec rspec spec/features'
alias services='bundle exec rspec spec/services'
alias drake='./docker/run bundle exec rake'

# git
alias g='git'
alias s='g status'
alias gc='g commit'
alias gs='g status'
alias gpf='g push --force-with-lease'
alias gut='git'
alias glog='g l'
alias stash='g add . && g stash'
alias pop='g stash pop'
alias skip='g rebase --skip'
alias cont='g rebase --continue'
alias unstage='g reset'

function grom() {
  BASE_BRANCH="$(git remote show origin | grep 'HEAD branch' | cut -d ':' -f 2 | tr -d '[:space:]')"
  git fetch origin && g rebase origin/$BASE_BRANCH
}

function grim() {
  BASE_BRANCH="$(git remote show origin | grep 'HEAD branch' | cut -d ':' -f 2 | tr -d '[:space:]')"
  git fetch origin && g rebase -i origin/$BASE_BRANCH
}

function gpom() {
  BASE_BRANCH="$(git remote show origin | grep 'HEAD branch' | cut -d ':' -f 2 | tr -d '[:space:]')"
  git pull origin $BASE_BRANCH
}

# open links in current commit in browser
alias resolve="for link in \`git show -s --format=%B HEAD | grep 'https.*\(jira\|honeybadger\)'\`; open \$link;"

# rcm
alias rcup='rcup -x setup'
alias rcupall="rcup `ls ~/.dotfiles | grep tag- | sed 's/^tag-/-t /' | tr "\n" ' '`"
alias reload_zsh='source ~/.zshrc'
alias reload!='rcupall; reload_zsh'

# If need be, alias pbcopy and pbpaste to match the utilities in OSX. Lifted
# from - https://superuser.com/questions/288320/whats-like-osxs-pbcopy-for-linux
#
if ! (( $+commands[pbcopy] )); then
  alias pbcopy='xsel --clipboard --input'
fi

if ! (( $+commands[pbpaste] )); then
  alias pbpaste='xsel --clipboard --output'
fi

# transmission
alias t-start='sudo service transmission-daemon start'
alias t-stop='sudo service transmission-daemon stop'
alias t-reload='sudo service transmission-daemon reload'
alias t-list="transmission-remote -n '$TRANSMISSION_USER_NAME:$TRANSMISSION_USER_PASS' -l"
alias t-basicstats="transmission-remote -n '$TRANSMISSION_USER_NAME:$TRANSMISSION_USER_PASS' -st"
alias t-fullstats="transmission-remote -n '$TRANSMISSION_USER_NAME:$TRANSMISSION_USER_PASS' -si"

function t-info() {
  if [ "$1" != "" ]; then
  transmission-remote -t $1 -n $TRANSMISSION_USER_NAME:$TRANSMISSION_USER_PASS -i
  else
  echo "nope"
  fi
}
