#!/usr/bin/env bash

# The folder that this script is in
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]:-$0}"; )" &> /dev/null && pwd 2> /dev/null; )";

# Deps
sudo apt install make curl git gpg openssh-server wget python3-pip apt-transport-https ca-certificates gnupg -y

# Doppler
curl -sLf --retry 3 --tlsv1.2 --proto "=https" 'https://packages.doppler.com/public/cli/gpg.DE2A7741A397C129.key' | sudo apt-key add -
echo "deb https://packages.doppler.com/public/cli/deb/debian any-version main" | sudo tee /etc/apt/sources.list.d/doppler-cli.list
sudo apt update && sudo apt install doppler -y

# Restore sentitive folders
if ! command -v restic &>/dev/null; then
    echo "restic could not be found"
    sudo apt install restic -y
fi

if ! command -v doppler &>/dev/null; then
    echo "doppler could not be found"
    curl -sLf --retry 3 --tlsv1.2 --proto "=https" 'https://packages.doppler.com/public/cli/gpg.DE2A7741A397C129.key' | sudo apt-key add -
    echo "deb https://packages.doppler.com/public/cli/deb/debian any-version main" | sudo tee /etc/apt/sources.list.d/doppler-cli.list
    sudo apt update && sudo apt install doppler -y
fi

RESTIC=$(command -v restic)
DOPPLER=$(command -v doppler)

# Folders to backup
RESTORE_FOLDERS=("${HOME}/.ssh" "${HOME}/.gnupg")
RESTORE_WORK_DIR="${HOME}/Downloads/restore"


echo ""
echo ">>> Restoring..."
echo ""
mkdir -p ${RESTORE_WORK_DIR}
cd ${RESTORE_WORK_DIR}
doppler setup

read -p "Press [Enter] key to continue..."

for i in "${RESTORE_FOLDERS[@]}"; do
    doppler run -- ${RESTIC} restore latest --target ${RESTORE_WORK_DIR} --path "${i}"
    rsync -a "${RESTORE_WORK_DIR}/${i}/" "${i}"
    chown -R ${USER}:${USER} "${i}"
    chmod -R 0700 "${i}"
done

chmod 0600 ${HOME}/.ssh/id_rsa*

rm -rf ${RESTORE_WORK_DIR}

# pcloud install
sudo add-apt-repository universe
sudo apt install libfuse2 -y

cd ${HOME}/Downloads
wget https://p-def8.pcloud.com/D4Zu1eKrMZMqwjTqZVFIm7ZXZSzX2r7Z2ZZ9WVZkZPF7pVZfRZF0ZOXZWTVkVZ77HBkyUvPa7KPCVOY00WIbuE3s37/pcloud

sudo apt install software-properties-common -y
sudo add-apt-repository ppa:appimagelauncher-team/stable
sudo apt update
sudo apt install appimagelauncher -y

AppImageLauncher pcloud


# Prep ansible
read -p "Press [Enter] key to continue..."
cd /tmp/ && git clone https://github.com/bashfulrobot/desktoperator && cd /tmp/desktoperator && make install

echo "'run make' to see your options."
