#!/bin/bash

DL_PATH="/root/qb/downloads" #qb下载目录
NAME="" #Rclone配置时填写的name
UP_PATH="onedrive/tmp" #onedrive网盘上传目录
TG_TOKEN=""  #tg机器人的token
TG_ID="" #tg的user ID

tg_push_message1() {
	TOKEN=${TG_TOKEN}	#TG机器人token
	chat_ID=${TG_ID}		#用户ID或频道、群ID
	message_text="${TG_MSG1}"		#要发送的信息
	MODE="markdownV2"		#解析模式，可选HTML或Markdown
	URL="https://api.telegram.org/bot${TOKEN}/sendMessage"		#api接口
	curl -s -o /dev/null -X POST $URL -d chat_id=${chat_ID} -d parse_mode=${MODE} -d text="${message_text}" --max-time 10
}

tg_push_message2() {
	TOKEN=${TG_TOKEN}	#TG机器人token
	chat_ID=${TG_ID}		#用户ID或频道、群ID
	message_text="${TG_MSG2}"		#要发送的信息
	MODE="HTML"		#解析模式，可选HTML或Markdown
	URL="https://api.telegram.org/bot${TOKEN}/sendMessage"		#api接口
	curl -s -o /dev/null -X POST $URL -d chat_id=${chat_ID} -d parse_mode=${MODE} -d text="${message_text}" --max-time 10
}

VOL=$(du -sh "${DL_PATH}" | awk '{print $1}')
MP4_FILES=$(ls ${DL_PATH}/* | grep mp4)
MKV_FILES=$(ls ${DL_PATH}/* | grep mkv)
MP3_FILES=$(ls ${DL_PATH}/* | grep mp3)
rm -rf ${DL_PATH}/temp
TG_MSG2="
MP4文件：
${MP4_FILES}
MKV文件：
${MKV_FILES}
MP3文件：
${MP3_FILES}
总共${VOL}
上传至${NAME}
目录${UP_PATH}
"

tg_push_message2

rclone sync ${DL_PATH} ${NAME}:${UP_PATH}

TG_MSG1="rclone 文件上传完毕。"

tg_push_message1

rm -rf ${DL_PATH}/*

exit 0
