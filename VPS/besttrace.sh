#!/bin/bash

# 判断系统架构
arch=$(uname -m)

if [ "$arch" == "x86_64" ]; then
  echo -e "系统架构为 x86"
  url="https://github.com/kissyouhunter/Tools/releases/download/besttrace/besttrace"

elif [ "$arch" == "aarch64" ]; then
  echo -e "系统架构为 arm64"
  url="https://github.com/kissyouhunter/Tools/releases/download/besttrace/besttracearm"

fi

# 下载文件
wget -O BestTrace "$url" && chmod +x BestTrace

exit 0