#!/bin/bash

NAME="" # rclone 配置时填写的name
UP_PATH="" # onedrive 网盘上传目录
TG_TOKEN=""  # telegram 机器人的token
TG_ID="" # telegram 的user ID
qb_username="admin" # qbitorrent 登陆账号
qb_password="adminadmin" # qbitorrent 登陆密码
qb_web_url="http://localhost:8989" # qbitorrent 的端口和ip
qb_version="4.4.3.12" # qbitorrent 版本

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
auto_del_flag="rclone"


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

function tg_push_message4() {
	TOKEN=${TG_TOKEN}	#TG机器人token
	chat_ID=${TG_ID}		#用户ID或频道、群ID
	message_text="${TG_MSG4}"		#要发送的信息
	MODE="HTML"		#解析模式，可选HTML或Markdown
	URL="https://api.telegram.org/bot${TOKEN}/sendMessage"		#api接口
	curl -s -o /dev/null -X POST $URL -d chat_id=${chat_ID} -d parse_mode=${MODE} -d text="${message_text}" --max-time 10
}

if [ ! -d ${log_dir} ]
then
	mkdir -p ${log_dir}
fi

version=$(echo $qb_version | grep -P -o "([0-9]\.){2}[0-9]" | sed s/\\.//g)

function qb_login() {
	if [[ ${version} -gt 404 ]]; then
		qb_v="1"
		cookie=$(curl -i --header "Referer: ${qb_web_url}" --data "username=${qb_username}&password=${qb_password}" "${qb_web_url}/api/v2/auth/login" | grep -P -o 'SID=\S{32}')
		if [[ -n ${cookie} ]]; then
			echo "[$(date '+%Y-%m-%d %H:%M:%S')] 登录成功！cookie:${cookie}" >> ${log_dir}/autodel.log
			TG_MSG3="[$(date '+%Y-%m-%d %H:%M:%S')] 登录成功！cookie:${cookie}"
			tg_push_message3
		else
			echo "[$(date '+%Y-%m-%d %H:%M:%S')] 登录失败！" >> ${log_dir}/autodel.log
			TG_MSG3="[$(date '+%Y-%m-%d %H:%M:%S')] 登录失败！"
			tg_push_message3
		fi
	elif [[ ${version} -le 404 && ${version} -ge 320 ]]; then
		qb_v="2"
		cookie=$(curl -i --header "Referer: ${qb_web_url}" --data "username=${qb_username}&password=${qb_password}" "${qb_web_url}/login" | grep -P -o 'SID=\S{32}')
		if [[ -n ${cookie} ]]; then
			echo "[$(date '+%Y-%m-%d %H:%M:%S')] 登录成功！cookie:${cookie}" >> ${log_dir}/autodel.log
			TG_MSG3="[$(date '+%Y-%m-%d %H:%M:%S')] 登录成功！cookie:${cookie}"
			tg_push_message3
		else
			echo "[$(date '+%Y-%m-%d %H:%M:%S')] 登录失败" >> ${log_dir}/autodel.log
			TG_MSG3="[$(date '+%Y-%m-%d %H:%M:%S')] 登录失败！"
			tg_push_message3
		fi
	elif [[ ${version} -ge 310 && ${version} -lt 320 ]]; then
		qb_v="3"
		TG_MSG3="陈年老版本，请及时升级"
		tg_push_message3
		exit
	else
		qb_v="0"
		exit
	fi
}

function qb_del() {
	if [ ${leeching_mode} == "true" ]; then
		if [ ${qb_v} == "1" ]; then
			curl "${qb_web_url}/api/v2/torrents/delete?hashes=${file_hash}&deleteFiles=true" --cookie ${cookie}
			echo "[$(date '+%Y-%m-%d %H:%M:%S')] 删除成功！种子名称:${torrent_name}" >> ${log_dir}/qb.log
			TG_MSG4="[$(date '+%Y-%m-%d %H:%M:%S')] 删除成功！种子名称:${torrent_name}"
			tg_push_message4
		elif [ ${qb_v} == "2" ]; then
			curl -X POST -d "hashes=${file_hash}" "${qb_web_url}/command/deletePerm" --cookie ${cookie}
		else
			echo "[$(date '+%Y-%m-%d %H:%M:%S')] 删除成功！种子文件:${torrent_name}" >> ${log_dir}/qb.log
			TG_MSG4="[$(date '+%Y-%m-%d %H:%M:%S')] 删除成功！种子名称:${torrent_name}"
			tg_push_message4
			echo "qb_v=${qb_v}" >> ${log_dir}/qb.log
		fi
	else
		echo "[$(date '+%Y-%m-%d %H:%M:%S')] 不自动删除已上传种子" >> ${log_dir}/qb.log
		TG_MSG4="[$(date '+%Y-%m-%d %H:%M:%S')] 不自动删除已上传种子"
		tg_push_message4
	fi
}

function rclone_moveto() {
	if [ "${type}" == "file" ]; then
		rclone_moveto_cmd=$(rclone -v moveto -P --transfers=${rclone_parallel} "${content_dir}" ${NAME}:${UP_PATH})
	elif [ "${type}" == "dir" ]; then
		rclone_moveto_cmd=$(rclone -v moveto -P --transfers=${rclone_parallel} "${content_dir}"/ ${NAME}:${UP_PATH}/"${torrent_name}")
	fi
}

function qb_add_auto_del_tags() {
	if [ ${qb_v} == "1" ]; then
		curl -X POST -d "hashes=${file_hash}&tags=${auto_del_flag}" "${qb_web_url}/api/v2/torrents/addTags" --cookie "${cookie}"
	elif [ ${qb_v} == "2" ]; then
		curl -X POST -d "hashes=${file_hash}&category=${auto_del_flag}" "${qb_web_url}/command/setCategory" --cookie ${cookie}
	else
		echo "qb_v=${qb_v}" >> ${log_dir}/qb.log
	fi
}

if [ -f "${content_dir}" ]; then
 	TG_MSG2="
 	种子名称：${torrent_name}
    内容路径：${content_dir}
    根目录：${root_dir}
    保存路径：${save_dir}
    文件数：${files_num}
    文件大小：${torrent_size}Bytes
    HASH: ${file_hash}
    Cookie: ${cookie}"
    tg_push_message2
    type="file"
    rclone_moveto
    qb_login
    qb_add_auto_del_tags
    qb_del
    TG_MSG1="rclone 文件上传完毕。"
    tg_push_message1
elif [ -d "${content_dir}" ]; then 
	TG_MSG2="
    种子名称：${torrent_name}
    内容路径：${content_dir}
    根目录：${root_dir}
    保存路径：${save_dir}
    文件数：${files_num}
    文件大小：${torrent_size}Bytes
    HASH: ${file_hash}
    Cookie: ${cookie}"
    tg_push_message2
    type="dir"
    rclone_moveto
    qb_login
    qb_add_auto_del_tags
    qb_del
    TG_MSG1="rclone 文件上传完毕。"
    tg_push_message1
else
	TG_MSG2="$(date '+%Y-%m-%d %H:%M:%S') 未知类型，取消上传"
    tg_push_message2
    exit 1
fi

{
  种子名称："${torrent_name}"
  内容路径："${content_dir}"
  根目录："${root_dir}"
  保存路径："${save_dir}"
  文件数："${files_num}"
  文件大小："${torrent_size}"Bytes
  HASH: "${file_hash}"
  Cookie: "${cookie}"
} >> ${log_dir}/qb.log
echo -e "-------------------------------------------------------------\n" >> ${log_dir}/qb.log