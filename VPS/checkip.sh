#!/bin/bash
#author kissyouhunter
### BEGIN INIT INFO
# Provides:          kissyouhunter
# Required-Start:    $local_fs $network
# Required-Stop:     $local_fs
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: self define auto start
# Description:       self define auto start
### END INIT INFO

TG_TOKEN=""  #tg机器人的token
TG_ID="" #tg的user ID

function tg_push_message() {
    TOKEN=${TG_TOKEN}	#TG机器人token
    chat_ID=${TG_ID}		#用户ID或频道、群ID
    message_text="${TG_MSG}"		#要发送的信息
    MODE="HTML"		#解析模式，可选HTML或Markdown
    URL="https://api.telegram.org/bot${TOKEN}/sendMessage"		#api接口
    curl -s -o /dev/null -X POST $URL -d chat_id=${chat_ID} -d parse_mode=${MODE} -d text="${message_text}" --max-time 10
}

function check_ip() {
	IP=$(curl -s ipv4.ip.sb)
	NAME=$(cat /etc/hostname)
	echo "${NAME}的IP地址为：${IP}"
	TG_MSG="${NAME}的IP地址为：${IP}"
	tg_push_message
}

check_ip

exit 0
