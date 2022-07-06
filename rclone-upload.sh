#!/bin/bash

NAME="" #Rclone配置时填写的name
UP_PATH="" #onedrive网盘上传目录
TG_TOKEN=""  #tg机器人的token
TG_ID="" #tg的user ID

torrent_name=$1
content_dir=$2
root_dir=$3
save_dir=$4
files_num=$5
torrent_size=$6
file_hash=$7

leeching_mode="true"
log_dir="/config/rclone"
rclone_parallel="32"

function tg_push_message1() {
    TOKEN=${TG_TOKEN}	#TG机器人token
    chat_ID=${TG_ID}		#用户ID或频道、群ID
    message_text="${TG_MSG1}"		#要发送的信息
    MODE="HTML"		#解析模式，可选HTML或Markdown
    URL="https://api.telegram.org/bot${TOKEN}/sendMessage"		#api接口
    curl -s -o /dev/null -X POST $URL -d chat_id=${chat_ID} -d parse_mode=${MODE} -d text="${message_text}" --max-time 10
}

function tg_push_message2() {
	TOKEN=${TG_TOKEN}	#TG机器人token
	chat_ID=${TG_ID}		#用户ID或频道、群ID
	message_text="${TG_MSG2}"		#要发送的信息
	MODE="HTML"		#解析模式，可选HTML或Markdown
	URL="https://api.telegram.org/bot${TOKEN}/sendMessage"		#api接口
	curl -s -o /dev/null -X POST $URL -d chat_id=${chat_ID} -d parse_mode=${MODE} -d text="${message_text}" --max-time 10
}

function tg_push_message3() {
	TOKEN=${TG_TOKEN}	#TG机器人token
	chat_ID=${TG_ID}		#用户ID或频道、群ID
	message_text="${TG_MSG3}"		#要发送的信息
	MODE="HTML"		#解析模式，可选HTML或Markdown
	URL="https://api.telegram.org/bot${TOKEN}/sendMessage"		#api接口
	curl -s -o /dev/null -X POST $URL -d chat_id=${chat_ID} -d parse_mode=${MODE} -d text="${message_text}" --max-time 10
}

if [ ! -d ${log_dir} ]; then
    mkdir -p ${log_dir}
fi

function qb_del() {
	if [ ${leeching_mode} == "true" ]; then
		if [ -e "${save_dir}" ]; then
		    rm -rf ${save_dir}/${torrent_name}
		    echo "[$(date '+%Y-%m-%d %H:%M:%S')] 删除成功！种子名称:${torrent_name}" >> ${log_dir}/qb.log
		    TG_MSG3="[$(date '+%Y-%m-%d %H:%M:%S')] 删除成功！种子名称:${torrent_name}"
		    tg_push_message3
		else
			rm -rf ${save_dir}/${torrent_name}
			echo "[$(date '+%Y-%m-%d %H:%M:%S')] 删除成功！种子文件:${torrent_name}" >> ${log_dir}/qb.log
			TG_MSG3="[$(date '+%Y-%m-%d %H:%M:%S')] 删除成功！种子名称:${torrent_name}"
			tg_push_message3
		fi
	else
		echo "[$(date '+%Y-%m-%d %H:%M:%S')] 不自动删除已上传种子" >> ${log_dir}/qb.log
		TG_MSG3="[$(date '+%Y-%m-%d %H:%M:%S')] 不自动删除已上传种子"
		tg_push_message3
	fi
}

function rclone_moveto() {
	if [ "${type}" == "file" ]; then
		rclone_moveto_cmd=$(rclone -v moveto -P --transfers=${rclone_parallel} "${content_dir}" ${NAME}:${UP_PATH}/"${content_dir}")
        TG_MSG1="[$(date '+%Y-%m-%d %H:%M:%S')] ${torrent_name} 上传到网盘 $NAME 的目录 ${UP_PATH}/"${content_dir}" 已完成。"
	elif [ "${type}" == "dir" ]; then
		rclone_moveto_cmd=$(rclone -v moveto -P --transfers=${rclone_parallel} "${content_dir}"/ ${NAME}:${UP_PATH}/"${torrent_name}")
        TG_MSG1="[$(date '+%Y-%m-%d %H:%M:%S')] ${torrent_name} 上传到网盘 $NAME 的目录 ${UP_PATH}/"${torrent_name}" 已完成。"
	fi
}


VOL=$(du -sh "${content_dir}" | awk '{print $1}')

if [ -f "${content_dir}" ]; then
    TG_MSG2="[$(date '+%Y-%m-%d %H:%M:%S')]
    种子名称：${torrent_name}
    内容路径：${content_dir}
    根目录：${root_dir}
    保存路径：${save_dir}
    文件数：${files_num}
    文件大小：${VOL}
    HASH: ${file_hash}"
    tg_push_message2
    type="file"
    rclone_moveto
    sync
    qb_del
    tg_push_message1
elif [ -d "${content_dir}" ]; then 
    TG_MSG2="[$(date '+%Y-%m-%d %H:%M:%S')]
    种子名称：${torrent_name}
    内容路径：${content_dir}
    根目录：${root_dir}
    保存路径：${save_dir}
    文件数：${files_num}
    文件大小：${VOL}
    HASH: ${file_hash}"
    tg_push_message2
    type="dir"
    rclone_moveto
    sync
    qb_del
    tg_push_message1
else
    TG_MSG2="[$(date '+%Y-%m-%d %H:%M:%S')] 未知类型，取消上传"
    tg_push_message2
    exit 1
fi

echo "种子名称：${torrent_name}" >> ${log_dir}/qb.log
echo "内容路径：${content_dir}" >> ${log_dir}/qb.log
echo "根目录：${root_dir}" >> ${log_dir}/qb.log
echo "保存路径：${save_dir}" >> ${log_dir}/qb.log
echo "文件数：${files_num}" >> ${log_dir}/qb.log
echo "文件大小：${torrent_size}Bytes" >> ${log_dir}/qb.log
echo "HASH:${file_hash}" >> ${log_dir}/qb.log
echo -e "-------------------------------------------------------------\n" >> ${log_dir}/qb.log