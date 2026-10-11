# Pin GOPATH/GOBIN explicitly. Left unset, asdf-golang's exec-env points them
# at the version-specific install dir (~/.asdf/installs/golang/<ver>/bin), so
# `go install` binaries land off $PATH and vanish on every Go upgrade.
# $GOBIN ($HOME/go/bin) is already on $PATH via path.zsh.
export GOPATH="$HOME/go"
export GOBIN="$GOPATH/bin"
