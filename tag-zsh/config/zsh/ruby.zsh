machine=`uname -s`

if [ "$machine" != "Linux" ]; then
  export RUBY_CONFIGURE_OPTS="--with-openssl-dir=$(brew --prefix openssl@3) --with-readline-dir=$(brew --prefix readline) --with-libyaml-dir=$(brew --prefix libyaml) --with-zlib-dir=$(brew --prefix zlib)"
fi

export DISABLE_SPRING=1
export CFLAGS="-Wno-error=implicit-function-declaration"
export optflags="-Wno-error=implicit-function-declaration"

if command -v brew &> /dev/null; then
  export LDFLAGS="-L$HOMEBREW_HOME/opt/readline/lib -L$HOMEBREW_HOME/opt/libffi/lib $LDFLAGS"
  export CPPFLAGS="-I$HOMEBREW_HOME/opt/readline/include -I$HOMEBREW_HOME/opt/libffi/include $CPPFLAGS"
  export PKG_CONFIG_PATH="$HOMEBREW_HOME/opt/readline/lib/pkgconfig $HOMEBREW_HOME/opt/libffi/lib/pkgconfig $PKG_CONFIG_PATH"
fi
