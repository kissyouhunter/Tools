#!/bin/bash

#curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add -
#apt-key fingerprint 0EBFCD88
#add-apt-repository "deb [arch=arm64,armhf] https://mirrors.tuna.tsinghua.edu.cn/docker-ce/linux/debian $(lsb_release -cs) stable"
#apt update
#apt install -y docker-ce docker-ce-cli containerd.io
#rm -f /etc/apt/sources.list.save
#rm -f /etc/apt/*.gpg~

apt update && apt install curl -y
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
docker -v
curl -L "https://github.com/docker/compose/releases/download/v2.0.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
docker-compose -v