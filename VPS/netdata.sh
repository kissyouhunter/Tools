#!/bin/bash

# 匹配物理网卡 
netcard=$(cat /proc/net/dev | grep -E 'eth[0-9]+|wlan[0-9]+|enp[0-9]+|ens[0-9]+|eno[0-9]+|wl[0-9 ]+' | awk -F: '{print $1}' | tr -d ' ')

# 再过滤掉 veth
netcard=$(echo "$netcard" | grep -v 'veth')

# 获取流量信息并转换单位
in=$(cat /proc/net/dev | grep $netcard | awk '{printf "%.2f\n", $2/1024/1024/1024}')
out=$(cat /proc/net/dev | grep $netcard | awk '{printf "%.2f\n", $10/1024/1024/1024}')

# 输出结果 
echo "入站流量: $in GB"
echo "出站流量: $out GB"

exit 0