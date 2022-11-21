- Install starship.rs
curl -sS <https://starship.rs/install.sh> | sh
- change zsh to zimfw
wget -nv -O - <https://raw.githubusercontent.com/zimfw/install/master/install.zsh> | zsh
sudo update-alternatives --install /usr/bin/x-terminal-emulator x-terminal-emulator $( which kitty ) 10
sudo update-alternatives --config x-terminal-emulator
