#!/bin/bash
# 下下面的命令 放到 qbitorrent 的设置 Torrent 完成时运行外部程序中
# bash /config/rclone-upload.sh  "%N" "%F" "%R" "%D" "%C" "%Z" "%I"

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
rclone_parallel="4"

# 检查文件夹名结尾是否为"-UC"或"-C"，并移除名称中的空格
if [[ "${content_dir}" == *" "* || "${content_dir}" == *"-UC" || "${content_dir}" == *"-C" ]]; then
  # 移除文件夹名中的空格和结尾的"-UC"或"-C"
  new_dir=$(echo "${content_dir}" | sed 's/ //g; s/-UC$//; s/-C$//')

  if [ -d "${content_dir}" ]; then
    # 重命名文件夹
    mv "${content_dir}" "${new_dir}"

    # 更新变量以反映文件夹的最新路径
    content_dir="${new_dir}"
    root_dir="${new_dir}"

    # 移除文件夹下视频文件名中的空格和末尾的"-UC"或"-C"
    find "${new_dir}" -type f \( -iname "*.mp4" -o -iname "*.avi" -o -iname "*.mkv" -o -iname "*.mov" \) -exec bash -c '
    new_name=$(echo "$1" | sed "s/ //g; s/\(.*\)\(-UC\|-C\)\(\..*\)$/\1\3/")
    mv "$1" "${new_name}"
    ' _ {} \;
  fi
fi

# 对 torrent_name 也执行类似的操作：先移除空格，再检查并删除结尾的 "-C" 或 "-UC"
if [[ "$torrent_name" == *" "* || "$torrent_name" == *"-C" || "$torrent_name" == *"-UC" ]]; then
  # 删除名称中的空格和结尾的 "-C" 或 "-UC"
  new_name=$(echo "$torrent_name" | sed 's/ //g; s/-C$//; s/-UC$//')
  torrent_name="$new_name"
fi

function tg_push_message1() {
    TOKEN=${TG_TOKEN}   #TG机器人token
    chat_ID=${TG_ID}            #用户ID或频道、群ID
    message_text="${TG_MSG1}"           #要发送的信息
    MODE="HTML"         #解析模式，可选HTML或Markdown
    URL="https://api.telegram.org/bot${TOKEN}/sendMessage"              #api接口
    curl -s -o /dev/null -X POST $URL -d chat_id=${chat_ID} -d parse_mode=${MODE} -d text="${message_text}" --max-time 10
}

function tg_push_message2() {
        TOKEN=${TG_TOKEN}       #TG机器人token
        chat_ID=${TG_ID}                #用户ID或频道、群ID
        message_text="${TG_MSG2}"               #要发送的信息
        MODE="HTML"             #解析模式，可选HTML或Markdown
        URL="https://api.telegram.org/bot${TOKEN}/sendMessage"          #api接口
        curl -s -o /dev/null -X POST $URL -d chat_id=${chat_ID} -d parse_mode=${MODE} -d text="${message_text}" --max-time 10
}

function tg_push_message3() {
        TOKEN=${TG_TOKEN}       #TG机器人token
        chat_ID=${TG_ID}                #用户ID或频道、群ID
        message_text="${TG_MSG3}"               #要发送的信息
        MODE="HTML"             #解析模式，可选HTML或Markdown
        URL="https://api.telegram.org/bot${TOKEN}/sendMessage"          #api接口
        curl -s -o /dev/null -X POST $URL -d chat_id=${chat_ID} -d parse_mode=${MODE} -d text="${message_text}" --max-time 10
}

function tg_push_message4() {
        TOKEN=${TG_TOKEN}       #TG机器人token
        chat_ID=${TG_ID}                #用户ID或频道、群ID
        message_text="${TG_MSG4}"               #要发送的信息
        MODE="HTML"             #解析模式，可选HTML或Markdown
        URL="https://api.telegram.org/bot${TOKEN}/sendMessage"          #api接口
        curl -s -o /dev/null -X POST $URL -d chat_id=${chat_ID} -d parse_mode=${MODE} -d text="${message_text}" --max-time 10
}

function rclone_check() {
    if [ "$(command -v rclone)" ]; then
        echo
    else
        TG_MSG4="rclone 未安装"
        tg_push_message4
        exit 1
    fi
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
            #find ${content_dir}/ -size -100000k -exec rm {} \;
            rclone_moveto_cmd=$(rclone -v moveto -P --transfers=${rclone_parallel} --tpslimit 1 --drive-upload-cutoff 1000T "${content_dir}" ${NAME}:${UP_PATH}"${content_dir}")
            TG_MSG1="[$(date '+%Y-%m-%d %H:%M:%S')] ${torrent_name} 上传到网盘 $NAME 的目录 ${UP_PATH}"${content_dir}" 已完成。"
        elif [ "${type}" == "dir" ]; then
            #find ${content_dir}/ -size -100000k -exec rm {} \;
            rclone_moveto_cmd=$(rclone -v moveto -P --transfers=${rclone_parallel} --tpslimit 1 --drive-upload-cutoff 1000T "${content_dir}"/ ${NAME}:${UP_PATH}/"${torrent_name}")
            TG_MSG1="[$(date '+%Y-%m-%d %H:%M:%S')] ${torrent_name} 上传到网盘 $NAME 的目录 ${UP_PATH}/"${torrent_name}" 已完成。"
        fi
}


VOL=$(du -sh "${content_dir}" | awk '{print $1}')

if [ -f "${content_dir}" ]; then
    rclone_check
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
    rclone_check
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
    rclone_check
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
