alias l='ls -CF'
alias la='ls -A'
alias ll='ls -alF'
alias lh='ls -lh'

pkgadd() {
    apk add "$@" && "$HOME"/archive.sh "$@"
}