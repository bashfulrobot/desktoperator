#!/usr/bin/env bash

# Install deps
sudo apt update && sudo apt install curl git fonts-powerline jq zsh neovim -y
sleep 5

# Install starship prompt
STARSHIP_TAG=$(curl -sL https://api.github.com/repos/starship/starship/releases/latest | jq -r ".tag_name") &&DL_URL=$(echo "https://github.com/starship/starship/releases/download/${STARSHIP_TAG}/starship-x86_64-unknown-linux-gnu.tar.gz") && curl -L -o starship-x86_64-unknown-linux-gnu.tar.gz ${DL_URL} && tar xvfz starship-x86_64-unknown-linux-gnu.tar.gz && rm -f starship-x86_64-unknown-linux-gnu.tar.gz && sudo install starship /usr/local/bin && cd $HOME/.config && curl -L -o starship.toml https://raw.githubusercontent.com/bashfulrobot/desktoperator/main/files/home/.config/starship.toml

# Install fwzim
curl -fsSL https://raw.githubusercontent.com/zimfw/install/master/install.zsh | zsh
# cd $HOME
# curl -L -o .zshrc https://raw.githubusercontent.com/bashfulrobot/desktoperator/main/files/home/.zshrc
# curl -L -o .zimrc https://raw.githubusercontent.com/bashfulrobot/desktoperator/main/files/home/.zimrc

# cd $HOME/.zim
# curl -L -o .latest_version https://raw.githubusercontent.com/bashfulrobot/desktoperator/main/files/home/.zim/.latest_version
# curl -L -o init.zsh https://raw.githubusercontent.com/bashfulrobot/desktoperator/main/files/home/.zim/init.zsh
# curl -L -o zimfw.zsh https://raw.githubusercontent.com/bashfulrobot/desktoperator/main/files/home/.zim/zimfw.zsh

# add core zsh funcitons
mkdir -p $HOME/.config/zsh
cd $HOME/.config/zsh
curl -L -o do-update https://raw.githubusercontent.com/bashfulrobot/desktoperator/main/files/home/.config/zsh/do-update
curl -L -o runAptUpdateIfNeeded https://raw.githubusercontent.com/bashfulrobot/desktoperator/main/files/home/.config/zsh/runAptUpdateIfNeeded
curl -L -o echoHeader https://raw.githubusercontent.com/bashfulrobot/desktoperator/main/files/home/.config/zsh/echoHeader
curl -L -o echoSection https://raw.githubusercontent.com/bashfulrobot/desktoperator/main/files/home/.config/zsh/echoSection

# sudo ln -s /usr/bin/batcat /usr/bin/bat

# Add customer .zshrc cfg
echo '### DK' >> $HOME/.zshrc
echo '######=== Autoload functions.' >> $HOME/.zshrc
echo 'fpath=( $HOME/.config/zsh "${fpath[@]}" )' >> $HOME/.zshrc
echo 'autoload -Uz $fpath[1]/*(.:t)' >> $HOME/.zshrc
echo '' >> $HOME/.zshrc
echo '# Enable starship prompt' >> $HOME/.zshrc
echo 'eval "$(starship init zsh)"' >> $HOME/.zshrc

# Add customer .zimrc cfg
echo '### DK Config' >> $HOME/.zimrc
echo '# SSH' >> $HOME/.zimrc
echo 'zmodule ssh' >> $HOME/.zimrc
echo '# Helm' >> $HOME/.zimrc
echo 'zmodule joke/zim-helm' >> $HOME/.zimrc
echo '# k9s' >> $HOME/.zimrc
echo 'zmodule joke/zim-k9s' >> $HOME/.zimrc
echo '# kubectl' >> $HOME/.zimrc
echo 'zmodule joke/zim-kubectl' >> $HOME/.zimrc
echo '# starship' >> $HOME/.zimrc
echo 'zmodule joke/zim-starship' >> $HOME/.zimrc

sleep 15

# change user shell to zsh
sudo chsh --shell /usr/bin/zsh $USER

echo "---- after restarting your shell, please run: zimfw install && zimfw upgrade"
exit 0
