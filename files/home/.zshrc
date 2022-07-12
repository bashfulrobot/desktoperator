# Personal Zsh configuration file. It is strongly recommended to keep all
# shell customization and configuration (including exported environment
# variables such as PATH) in this file or in files sourced from it.
#
# Documentation: https://github.com/romkatv/zsh4humans/blob/v5/README.md.

#####=== z4h Core Config

# Periodic auto-update on Zsh startup: 'ask' or 'no'.
# You can manually run `z4h update` to update everything.
zstyle ':z4h:' auto-update      'ask'
# Ask whether to auto-update this often; has no effect if auto-update is 'no'.
zstyle ':z4h:' auto-update-days '7'

# Move prompt to the bottom when zsh starts and on Ctrl+L.
zstyle ':z4h:' prompt-at-bottom 'no'

# Keyboard type: 'mac' or 'pc'.
zstyle ':z4h:bindkey' keyboard  'pc'

# Mark up shell's output with semantic information.
zstyle ':z4h:' term-shell-integration 'yes'

# Right-arrow key accepts one character ('partial-accept') from
# command autosuggestions or the whole thing ('accept')?
zstyle ':z4h:autosuggestions' forward-char 'accept'

# Recursively traverse directories when TAB-completing files.
zstyle ':z4h:fzf-complete' recurse-dirs 'yes'

#####=== Direnv

# Enable direnv to automatically source .envrc files.
zstyle ':z4h:direnv'         enable 'yes'
# Show "loading" and "unloading" notifications from direnv.
zstyle ':z4h:direnv:success' notify 'yes'

#####=== SSH

# Enable ('yes') or disable ('no') automatic teleportation of z4h over
# SSH when connecting to these hosts.
# zstyle ':z4h:ssh:example-hostname1'   enable 'yes'
# zstyle ':z4h:ssh:*.example-hostname2' enable 'no'
# The default value if none of the overrides above match the hostname.
zstyle ':z4h:ssh:*'                   enable 'yes'

# Send these files over to the remote host when connecting over SSH to the
# enabled hosts.
zstyle ':z4h:ssh:*' send-extra-files '$HOME/.nanorc' '$HOME/.env.zsh' '$HOME/.config/zsh'

#####=== GIT Clone

# Clone additional Git repositories from GitHub.
#
# This doesn't do anything apart from cloning the repository and keeping it
# up-to-date. Cloned files can be used after `z4h init`. This is just an
# example. If you don't plan to use Oh My Zsh, delete this line.
# z4h install ohmyzsh/ohmyzsh || return
z4h install djui/alias-tips || return

# Install or update core components (fzf, zsh-autosuggestions, etc.) and
# initialize Zsh. After this point console I/O is unavailable until Zsh
# is fully initialized. Everything that requires user interaction or can
# perform network I/O must be done above. Everything else is best done below.
z4h init || return

#####=== Extend PATH.

# Go
GOBIN=$HOME/go/bin

pathdirs=(
    $HOME/bin
    $HOME/Documents/bin
    $HOME/.local/bin
    $HOME/.cargo/bin
    $GOBIN
    /usr/local/go/bin
    $HOME/.arkade/bin/
)
for dir in $pathdirs; do
    if [ -d $dir ]; then
        path+=$dir
    fi
done

# export it all
export PATH

#####=== Export environment variables.

# Colours
export RED=$(tput setaf 1)
export GREEN=$(tput setaf 2)
export YELLOW=$(tput setaf 3)
export NC=$(tput sgr0)

export ONLINE="${GREEN}online$NC"
export OFFLINE="${RED}offline$NC"

export GPG_TTY=$TTY
# Support additional terminal
export TERM=xterm-256color
# dch Settings for ubuntu packaging
export DEBFULLNAME="Dustin Krysak"
export DEBEMAIL="dustin@bashfulrobot.com"
# Set editor
export EDITOR=code-insiders
# Add colour to MAN pages
export MANPAGER="sh -c 'col -bx | bat -l man -p'"
# Go
export GOPATH=$HOME/go
export GOROOT=/usr/local/go
export GOBIN=$HOME/go/bin
export GO111MODULE=on

# Export kubeconfig files from ~/.kube/clusters
export KUBECONFIG=$(find ~/.kube/clusters -type f | sed ':a;N;s/\n/:/;ba')

#####=== Source additional local files if they exist.
z4h source $HOME/.env.zsh
# Enable COD binary
if [[ -f "/usr/local/bin/cod" ]]; then
    z4h source <(cod init $$ zsh)
fi

# Enable alias tips plug in
# cloned via previous install command
z4h source $Z4H/djui/alias-tips/alias-tips.plugin.zsh

# Use additional Git repositories pulled in with `z4h install`.
#
# This is just an example that you should delete. It does nothing useful.
#z4h source ohmyzsh/ohmyzsh/lib/diagnostics.zsh  # source an individual file
#z4h load   ohmyzsh/ohmyzsh/plugins/emoji-clock  # load a plugin

#####=== Eval additional commands

# Enable zioxide (z functionality)
eval "$(zoxide init zsh)"

#####=== Define key bindings.

z4h bindkey z4h-backward-kill-word  Ctrl+Backspace     Ctrl+H
z4h bindkey z4h-backward-kill-zword Ctrl+Alt+Backspace

z4h bindkey undo Ctrl+/ Shift+Tab # undo the last command line change
z4h bindkey redo Alt+/            # redo the last undone command line change

z4h bindkey z4h-cd-back    Alt+Left   # cd into the previous directory
z4h bindkey z4h-cd-forward Alt+Right  # cd into the next directory
z4h bindkey z4h-cd-up      Alt+Up     # cd into the parent directory
z4h bindkey z4h-cd-down    Alt+Down   # cd into a child directory

#####=== Autoload functions.
fpath=( $HOME/.config/zsh "${fpath[@]}" )
autoload -Uz $fpath[1]/*(.:t)


#####=== Define functions and completions.


function md() { [[ $# == 1 ]] && mkdir -p -- "$1" && cd -- "$1" }
compdef _directories md

#####=== Define named directories: $HOMEw <=> Windows home directory on WSL.
[[ -z $z4h_win_home ]] || hash -d w=$z4h_win_home

#####=== Define aliases.
alias tree='tree -a -I .git'

alias pcp='rsync -aP'

alias er='code-insiders -r'
alias e='code-insiders'
alias e-root='code-insiders --user-data-dir="$HOME/.vscode-insiders/"'

alias opermissions="stat -c '%A %a %n'"
alias octperm="stat -c '%A %a %n'"

alias espanso-list="cat $HOME/.config/espanso/default.yml | grep trigger | cut -d ' ' -f5 | less"

alias vpn-login="/usr/bin/nordvpn login"
alias vpn-logout="/usr/bin/nordvpn logout"
alias vpn-up="/usr/bin/nordvpn connect"
alias vpn-down="/usr/bin/nordvpn disconnect"
alias vpn-countries="/usr/bin/nordvpn countries"
alias vpn-cities="/usr/bin/nordvpn cities"
alias vpn-settings="/usr/bin/nordvpn settings"
alias vpn-status="/usr/bin/nordvpn status"
alias vpn-account="/usr/bin/nordvpn account"
alias vpn-help="/usr/bin/google-chrome https://support.nordvpn.com/Connectivity/Linux/1325531132/Installing-and-using-NordVPN-on-Debian-Ubuntu-and-Linux-Mint.htm"

if [[ ! -f "/usr/bin/batcat" ]]; then
    sudo apt install bat -y
fi
# alias cat="batcat"
alias bat="batcat"
# alias ls="exa"
# alias grep="rg"

# Hide snap packages in df command
alias df="df -x squashfs"

alias k="kubectl"
# short alias to set/show context/namespace (only works for bash and bash-compatible shells, current context to be set before using kn to set namespace)
alias kx='f() { [ "$1" ] && kubectl config use-context $1 || kubectl config current-context ; } ; f'
alias kn='f() { [ "$1" ] && kubectl config set-context --current --namespace $1 || kubectl config view --minify | grep namespace | cut -d" " -f6 ; } ; f'

alias d="docker"
alias g="git"
alias dc="docker-compose"
alias lzd="lazydocker"

alias top="gotop"
alias htop="gotop"

alias dnd-on="dunstctl set-paused true"
alias dnd-off="dunstctl set-paused false"

if [ -d "$HOME/.bookmarks" ]; then
    export CDPATH=".:$HOME/.bookmarks:/"
    alias gt="cd -P"
fi

# alias vi="$HOME/Applications/nvim.appimage"
# alias vim="$HOME/Applications/nvim.appimage"
# alias nvim="$HOME/Applications/nvim.appimage"
# alias neovim="$HOME/Applications/nvim.appimage"

# Add flags to existing aliases.
# alias ls="${aliases[ls]:-ls} -A"

#####=== Set shell options: http://zsh.sourceforge.net/Doc/Release/Options.html.
setopt glob_dots     # no special treatment for file names with a leading dot
setopt no_auto_menu  # require an extra TAB press to open the completion menu

# log history to file
export HISTFILE=~/.zsh_history
# Increase history size
export HISTFILESIZE=1000000000
export HISTSIZE=1000000000
# Add to history immediately
setopt INC_APPEND_HISTORY
export HISTTIMEFORMAT="[%F %T] "
# Add Timestamp to history
setopt EXTENDED_HISTORY
# Remove duplicates from the history
setopt HIST_FIND_NO_DUPS