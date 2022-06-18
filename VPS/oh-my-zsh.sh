#!/bin/bash

# shell script for debian ubuntu

sudo apt update
sudo apt install -y git wget curl nano zsh

chsh -s $(which zsh)
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions

curl -Lo ~/.zshrc

echo "please logout and log back in"

exit