[[ -d /usr/lib/jvm/default ]]              && export JAVA_HOME="/usr/lib/jvm/default"        # arch
[[ -d /usr/lib/jvm/default-java ]]         && export JAVA_HOME="/usr/lib/jvm/default-java"   # debian
[[ -x /usr/libexec/java_home ]]            && export JAVA_HOME=$(/usr/libexec/java_home)     # macOS
[[ -d "$HOME/.nvm" ]]                      && export NVM_DIR="$HOME/.nvm"

path=(
	"/usr/bin"
	"/bin"
	"/usr/sbin"
	"/sbin"
	"/snap/bin"
	"node_modules/.bin"
	"$HOME/go/bin"
	"$HOME/.cargo/bin"
	"$HOME/.npm-packages/bin"
	"$HOME/.bin"
	"$HOME/.local/bin"
	"/usr/local/bin"
	"$JAVA_HOME/jre/bin"
)

YARN_BIN="$HOME/.yarn/bin"
[[ -d  $YARN_BIN ]] && path=(
	$YARN_BIN
	$path
)

BUN_BIN="$HOME/.bun/bin"
[[ -d  $BUN_BIN ]] && path=(
	$BUN_BIN
	$path
)

PG_APP_BIN="/Applications/Postgres.app/Contents/Versions/latest/bin"
[[ -d $PG_APP_BIN ]] && path=(
	$PG_APP_BIN
	$path
)

# Set up all homebrew paths
if [ "$(uname -m 2> /dev/null)" = "arm64" ]; then
  export HOMEBREW_HOME="/opt/homebrew"
else
  export HOMEBREW_HOME="/usr/local"
fi

if [[ -f "$HOMEBREW_HOME/bin/brew" ]] &> /dev/null; then
	path=(
		"$HOMEBREW_HOME/bin"
		"$HOMEBREW_HOME/sbin"
		$path
	)

	# Set up openssl path and ENV's
	if [[ -d $HOMEBREW_HOME/opt/openssl/bin ]]; then
		path=(
			"$HOMEBREW_HOME/opt/openssl/bin"
			$path
		)
		export LDFLAGS="-L$HOMEBREW_HOME/opt/openssl/lib"
		export CPPFLAGS="-I$HOMEBREW_HOME/opt/openssl/include"
		export PKG_CONFIG_PATH="$HOMEBREW_HOME/openssl/lib/pkgconfig"
	fi
fi
