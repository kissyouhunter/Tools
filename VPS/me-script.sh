#!/bin/bash

apt update
sleep 1
sudo timedatectl set-timezone Asia/Shanghai
sleep 1
cat >> /etc/sysctl.conf << EOF
fs.file-max = 6815744
net.ipv4.tcp_no_metrics_save=1
net.ipv4.tcp_ecn=0
net.ipv4.tcp_frto=0
net.ipv4.tcp_mtu_probing=0
net.ipv4.tcp_rfc1337=0
net.ipv4.tcp_sack=1
net.ipv4.tcp_fack=1
net.ipv4.tcp_window_scaling=1
net.ipv4.tcp_adv_win_scale=1
net.ipv4.tcp_moderate_rcvbuf=1
net.core.rmem_max=33554432
net.core.wmem_max=33554432
net.ipv4.tcp_rmem=4096 87380 33554432
net.ipv4.tcp_wmem=4096 16384 33554432
net.ipv4.udp_rmem_min=8192
net.ipv4.udp_wmem_min=8192
net.ipv4.ip_forward=1
net.ipv4.conf.all.route_localnet=1
net.ipv4.conf.all.forwarding=1
net.ipv4.conf.default.forwarding=1
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr
net.ipv6.conf.all.forwarding=1
net.ipv6.conf.default.forwarding=1
EOF
sysctl -p && sysctl --system
sleep 1
curl -sSL https://get.docker.com | bash
sleep 1
docker -v && docker compose version
sleep 1
ARCH=$(uname -m)
if [ "$ARCH" == "x86_64" ]; then
    docker run -d --restart=always --name tm traffmonetizer/cli_v2 start accept --token UUmcfhEvPoKY18zmFcwg2Hg/VmjI8/TSYTIDxhD4Jpo=
elif [ "$ARCH" == "aarch64" ]; then
    docker run -d --restart always --name tm traffmonetizer/cli_v2:arm64v8 start accept --token UUmcfhEvPoKY18zmFcwg2Hg/VmjI8/TSYTIDxhD4Jpo=
fi
sleep 2
docker logs -t tm
sleep 2
curl -fsSL https://raw.githubusercontent.com/kissyouhunter/Tools/main/VPS/oh-my-zsh.sh | sh
