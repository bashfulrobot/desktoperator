#!/usr/bin/env bash

sudo apt update
sudo apt install curl git fonts-powerline powerline jq zsh neovim -y
mkdir -p $HOME/.config/zsh
mkdir -p $HOME/.zim
sudo chsh --shell /usr/bin/zsh $USER
STARSHIP_TAG=$(curl -sL https://api.github.com/repos/starship/starship/releases/latest | jq -r ".tag_name")
DL_URL=$(echo "https://github.com/starship/starship/releases/download/${STARSHIP_TAG}/starship-x86_64-unknown-linux-gnu.tar.gz")
curl -L -o starship-x86_64-unknown-linux-gnu.tar.gz ${DL_URL}
tar xvfz starship-x86_64-unknown-linux-gnu.tar.gz
rm -f starship-x86_64-unknown-linux-gnu.tar.gz
sudo install starship /usr/local/bin
curl -fsSL https://raw.githubusercontent.com/zimfw/install/master/install.zsh | zsh
cd $HOME
curl -L -o .zshrc https://raw.githubusercontent.com/bashfulrobot/desktoperator/main/files/home/.zshrc
curl -L -o .zimrc https://raw.githubusercontent.com/bashfulrobot/desktoperator/main/files/home/.zimrc
cd $HOME/.config
curl -L -o starship.toml https://raw.githubusercontent.com/bashfulrobot/desktoperator/main/files/home/.config/starship.toml
# cd $HOME/.zim
# curl -L -o .latest_version https://raw.githubusercontent.com/bashfulrobot/desktoperator/main/files/home/.zim/.latest_version
# curl -L -o init.zsh https://raw.githubusercontent.com/bashfulrobot/desktoperator/main/files/home/.zim/init.zsh
# curl -L -o zimfw.zsh https://raw.githubusercontent.com/bashfulrobot/desktoperator/main/files/home/.zim/zimfw.zsh
cd $HOME/.config/zsh
curl -L -o do-update https://raw.githubusercontent.com/bashfulrobot/desktoperator/main/files/home/.config/zsh/do-update
curl -L -o runAptUpdateIfNeeded https://raw.githubusercontent.com/bashfulrobot/desktoperator/main/files/home/.config/zsh/runAptUpdateIfNeeded
curl -L -o echoHeader https://raw.githubusercontent.com/bashfulrobot/desktoperator/main/files/home/.config/zsh/echoHeader
curl -L -o echoSection https://raw.githubusercontent.com/bashfulrobot/desktoperator/main/files/home/.config/zsh/echoSection
sudo ln -s /usr/bin/batcat /usr/bin/bat
echo "---- after restarting your shell, please run: zimfw install && zimfw upgrade"
exit 0
