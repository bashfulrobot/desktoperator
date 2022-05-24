#!/usr/bin/env bash

# Deps
sudo apt install make curl git wget python3-pip apt-transport-https ca-certificates gnupg -y

# Doppler
# curl -sLf --retry 3 --tlsv1.2 --proto "=https" 'https://packages.doppler.com/public/cli/gpg.DE2A7741A397C129.key' | sudo apt-key add -
# echo "deb https://packages.doppler.com/public/cli/deb/debian any-version main" | sudo tee /etc/apt/sources.list.d/doppler-cli.list
# sudo apt update && sudo apt install doppler -y

cd /tmp/ && git clone https://github.com/bashfulrobot/desktoperator && cd desktoperator
# doppler setup
make install
make requirements
echo "'run make' to see your options."
