#!/usr/bin/env bash

# The folder that this script is in
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]:-$0}"; )" &> /dev/null && pwd 2> /dev/null; )";

# Deps
sudo apt install restic make curl git gpg openssh-server wget python3-pip apt-transport-https ca-certificates gnupg -y

if ! command -v doppler &>/dev/null; then
    echo "doppler could not be found"
    curl -sLf --retry 3 --tlsv1.2 --proto "=https" 'https://packages.doppler.com/public/cli/gpg.DE2A7741A397C129.key' | sudo apt-key add -
    echo "deb https://packages.doppler.com/public/cli/deb/debian any-version main" | sudo tee /etc/apt/sources.list.d/doppler-cli.list
    sudo apt update && sudo apt install doppler -y
fi

RESTIC=$(command -v restic)
DOPPLER=$(command -v doppler)

# Folders to backup
RESTORE_FOLDERS=("${HOME}/.ssh" "${HOME}/.gnupg" "${HOME}/.aws" "${HOME}/.bazaar" "${HOME}/.fonts" "${HOME}/.icons" "${HOME}/.themes" "${HOME}/.config/espanso" "${HOME}/.local/share/cod" "${HOME}/.password-store" "${HOME}/Documents" "${HOME}/code" "${HOME}/Desktop" "${HOME}/Pictures" "${HOME}/Videos" "${HOME}/.kube")
RESTORE_WORK_DIR="${HOME}/Downloads/restore"

# Ensure retore folders exist
for i in "${RESTORE_FOLDERS[@]}"; do
    mkdir -p "${i}"
    chown -R ${USER}:${USER} "${i}"
    chmod -R 0700 "${i}"
done


echo ""
echo ">>> Restoring..."
echo ""


read -p "please run doppler login in another terminal, then press [ENTER] when complete. "

mkdir -p ${RESTORE_WORK_DIR}
cd ${RESTORE_WORK_DIR}

read -p "please run doppler setup in another terminal (within ${RESTORE_WORK_DIR}), then press [ENTER] when complete. "


for i in "${RESTORE_FOLDERS[@]}"; do
    doppler run -- ${RESTIC} restore latest --target ${RESTORE_WORK_DIR} --path "${i}"
    rsync -a "${RESTORE_WORK_DIR}/${i}/" "${i}"
    chown -R ${USER}:${USER} "${i}"
    chmod -R 0700 "${i}"
done

chmod 0600 ${HOME}/.ssh/id_rsa*

# Prep ansible

cd ~/tmp/ && git clone https://github.com/bashfulrobot/desktoperator && cd ~/tmp/desktoperator

read -p "please run doppler setup in another terminal (within ~/tmp/desktoperator), then press [ENTER] when complete. "


make install

echo "'run make' to see your options."
