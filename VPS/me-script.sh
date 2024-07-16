#!/bin/bash

apt update
sleep 1
sudo timedatectl set-timezone Asia/Shanghai
sleep 1
echo 'net.core.default_qdisc=fq' | sudo tee -a /etc/sysctl.conf && echo 'net.ipv4.tcp_congestion_control=bbr' | sudo tee -a /etc/sysctl.conf && sudo sysctl -p && sysctl net.ipv4.tcp_congestion_control
sleep 1
bash <(curl -s -S -L https://get.docker.com)
sleep 1
docker -v && docker compose version
sleep 1
#docker run -d --restart=always --name tm traffmonetizer/cli_v2 start accept --token UUmcfhEvPoKY18zmFcwg2Hg/VmjI8/TSYTIDxhD4Jpo=
#sleep 2
#docker logs -t tm
docker run --name repocket -e RP_EMAIL=kissyouhunter@gmail.com -e RP_API_KEY=cdd26ec2-be0f-42f4-ba45-2c73bfd8558e -d --restart=always repocket/repocket
sleep 5
docker logs -t repocket
sleep 2
sh -c "$(curl -fsSL https://raw.githubusercontent.com/kissyouhunter/Tools/main/VPS/oh-my-zsh.sh)"
