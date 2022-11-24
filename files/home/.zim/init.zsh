zimfw() { source /home/dustin/.zim/zimfw.zsh "${@}" }
zmodule() { source /home/dustin/.zim/zimfw.zsh "${@}" }
typeset -g _zim_fpath=(/home/dustin/.zim/modules/git/functions /home/dustin/.zim/modules/utility/functions /home/dustin/.zim/modules/duration-info/functions /home/dustin/.zim/modules/git-info/functions /home/dustin/.zim/modules/zsh-completions/src /home/dustin/.zim/modules/git/functions /home/dustin/.zim/modules/utility/functions /home/dustin/.zim/modules/duration-info/functions /home/dustin/.zim/modules/git-info/functions /home/dustin/.zim/modules/zsh-completions/src /home/dustin/.zim/modules/git/functions /home/dustin/.zim/modules/utility/functions /home/dustin/.zim/modules/duration-info/functions /home/dustin/.zim/modules/git-info/functions /home/dustin/.zim/modules/zsh-completions/src /home/dustin/.zim/modules/zim-helm/functions /home/dustin/.zim/modules/zim-k9s/functions /home/dustin/.zim/modules/zim-kubectl/functions /home/dustin/.zim/modules/zim-starship/functions)
fpath=(${_zim_fpath} ${fpath})
autoload -Uz -- git-alias-lookup git-branch-current git-branch-delete-interactive git-branch-remote-tracking git-dir git-ignore-add git-root git-stash-clear-interactive git-stash-recover git-submodule-move git-submodule-remove mkcd mkpw duration-info-precmd duration-info-preexec coalesce git-action git-info git-alias-lookup git-branch-current git-branch-delete-interactive git-branch-remote-tracking git-dir git-ignore-add git-root git-stash-clear-interactive git-stash-recover git-submodule-move git-submodule-remove mkcd mkpw duration-info-precmd duration-info-preexec coalesce git-action git-info git-alias-lookup git-branch-current git-branch-delete-interactive git-branch-remote-tracking git-dir git-ignore-add git-root git-stash-clear-interactive git-stash-recover git-submodule-move git-submodule-remove mkcd mkpw duration-info-precmd duration-info-preexec coalesce git-action git-info kubectl-alias-lookup
source /home/dustin/.zim/modules/environment/init.zsh
source /home/dustin/.zim/modules/git/init.zsh
source /home/dustin/.zim/modules/input/init.zsh
source /home/dustin/.zim/modules/termtitle/init.zsh
source /home/dustin/.zim/modules/utility/init.zsh
source /home/dustin/.zim/modules/duration-info/init.zsh
source /home/dustin/.zim/modules/asciiship/asciiship.zsh-theme
source /home/dustin/.zim/modules/completion/init.zsh
source /home/dustin/.zim/modules/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source /home/dustin/.zim/modules/zsh-history-substring-search/zsh-history-substring-search.zsh
source /home/dustin/.zim/modules/zsh-autosuggestions/zsh-autosuggestions.zsh
source /home/dustin/.zim/modules/environment/init.zsh
source /home/dustin/.zim/modules/git/init.zsh
source /home/dustin/.zim/modules/input/init.zsh
source /home/dustin/.zim/modules/termtitle/init.zsh
source /home/dustin/.zim/modules/utility/init.zsh
source /home/dustin/.zim/modules/duration-info/init.zsh
source /home/dustin/.zim/modules/asciiship/asciiship.zsh-theme
source /home/dustin/.zim/modules/completion/init.zsh
source /home/dustin/.zim/modules/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source /home/dustin/.zim/modules/zsh-history-substring-search/zsh-history-substring-search.zsh
source /home/dustin/.zim/modules/zsh-autosuggestions/zsh-autosuggestions.zsh
source /home/dustin/.zim/modules/environment/init.zsh
source /home/dustin/.zim/modules/git/init.zsh
source /home/dustin/.zim/modules/input/init.zsh
source /home/dustin/.zim/modules/termtitle/init.zsh
source /home/dustin/.zim/modules/utility/init.zsh
source /home/dustin/.zim/modules/duration-info/init.zsh
source /home/dustin/.zim/modules/asciiship/asciiship.zsh-theme
source /home/dustin/.zim/modules/completion/init.zsh
source /home/dustin/.zim/modules/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source /home/dustin/.zim/modules/zsh-history-substring-search/zsh-history-substring-search.zsh
source /home/dustin/.zim/modules/zsh-autosuggestions/zsh-autosuggestions.zsh
source /home/dustin/.zim/modules/exa/init.zsh
source /home/dustin/.zim/modules/ssh/init.zsh
source /home/dustin/.zim/modules/zim-helm/init.zsh
source /home/dustin/.zim/modules/zim-k9s/init.zsh
source /home/dustin/.zim/modules/zim-kubectl/init.zsh
source /home/dustin/.zim/modules/zim-starship/init.zsh
