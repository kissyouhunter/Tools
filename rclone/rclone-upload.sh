#!/bin/bash
# 下下面的命令 放到 qbitorrent 的设置 Torrent 完成时运行外部程序中
# bash /config/rclone-upload.sh  "%N" "%F" "%R" "%D" "%C" "%Z" "%I"

NAME=""                # Rclone 配置时填写的 name
UP_PATH=""             # OneDrive 网盘上传目录
TG_TOKEN=""            # Telegram 机器人的 token
TG_ID=""               # Telegram 的 user ID

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
max_retries=1

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

# 对 torrent_name 执行类似操作
if [[ "$torrent_name" == *" "* || "$torrent_name" == *"-C" || "$torrent_name" == *"-UC" ]]; then
  new_name=$(echo "$torrent_name" | sed 's/ //g; s/-C$//; s/-UC$//')
  torrent_name="$new_name"
fi

# 通用的 Telegram 消息推送函数
function tg_push_message() {
    local message_text="$1"
    local TOKEN="${TG_TOKEN}"
    local chat_ID="${TG_ID}"
    local MODE="HTML"
    local URL="https://api.telegram.org/bot${TOKEN}/sendMessage"
    curl -s -o /dev/null -X POST "$URL" \
        -d chat_id="${chat_ID}" \
        -d parse_mode="${MODE}" \
        -d text="${message_text}" \
        --max-time 10
}

# 检查 rclone 是否安装
function rclone_check() {
    if [ "$(command -v rclone)" ]; then
        echo
    else
        tg_push_message "<b>rclone 未安装</b>"
        exit 1
    fi
}

# 检查上传是否成功的函数（检测本地内容是否还在）
function rclone_upload_check() {
    local local_path="$1" # 本地路径

    # 检查本地文件或文件夹是否还有内容
    local_file_count=$(find "${local_path}" -type f | wc -l)
    local_remaining_files=$(find "${local_path}" -type f)

    # 如果本地文件数量为0，说明全部移动成功
    if [ "$local_file_count" -eq 0 ]; then
        return 0  # 上传成功
    else
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] 上传失败！本地仍有 $local_file_count 个文件未移动: $local_remaining_files" >> ${log_dir}/qb.log
        return 1  # 上传失败
    fi
}

if [ ! -d ${log_dir} ]; then
    mkdir -p ${log_dir}
fi

function qb_del() {
    if [ ${leeching_mode} == "true" ]; then
        if [ -e "${save_dir}" ]; then
            rm -rf "${save_dir}/${torrent_name}"
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] 删除成功！种子名称:${torrent_name}" >> ${log_dir}/qb.log
            tg_push_message "[$(date '+%Y-%m-%d %H:%M:%S')] 删除成功！种子名称: <b>${torrent_name}</b>"
        else
            rm -rf "${save_dir}/${torrent_name}"
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] 删除成功！种子文件:${torrent_name}" >> ${log_dir}/qb.log
            tg_push_message "[$(date '+%Y-%m-%d %H:%M:%S')] 删除成功！种子名称: <b>${torrent_name}</b>"
        fi
    else
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] 不自动删除已上传种子" >> ${log_dir}/qb.log
        tg_push_message "[$(date '+%Y-%m-%d %H:%M:%S')] 不自动删除已上传种子"
    fi
}

function rclone_moveto() {
    retry_count=0
    upload_success=0

    if [ "${type}" == "file" ]; then
        file_name=$(basename "${content_dir}") # 提取文件名
        remote_path="${NAME}:${UP_PATH}/${file_name}" # 远程路径
        while [ $retry_count -lt $max_retries ] && [ $upload_success -eq 0 ]; do
            find "${content_dir}"/ -size -100000k -exec rm {} \;
            rclone -vv moveto -P --transfers=${rclone_parallel} --tpslimit 1 --drive-upload-cutoff 1000T "${content_dir}" "${remote_path}"
            if rclone_upload_check "${content_dir}"; then
                tg_push_message "[$(date '+%Y-%m-%d %H:%M:%S')] <b>${torrent_name}</b> 上传到网盘 <b>${NAME}</b> 的目录 <b>${UP_PATH}/${file_name}</b> 已完成。"
                upload_success=1
            else
                tg_push_message "[$(date '+%Y-%m-%d %H:%M:%S')] <b>${torrent_name}</b> 上传失败！将在10分钟后重试（第 $((retry_count + 1))/$max_retries 次）。"
                echo "[$(date '+%Y-%m-%d %H:%M:%S')] 上传失败！种子名称:${torrent_name}，将在10分钟后重试" >> ${log_dir}/qb.log
                sleep 600 # 等待10分钟
                retry_count=$((retry_count + 1))
                if [ $retry_count -eq $max_retries ]; then
                    tg_push_message "[$(date '+%Y-%m-%d %H:%M:%S')] <b>${torrent_name}</b> 上传失败！已达最大重试次数 ($max_retries)，请检查网络或配置。"
                    return 1
                fi
            fi
        done
    elif [ "${type}" == "dir" ]; then
        remote_path="${NAME}:${UP_PATH}/${torrent_name}" # 文件夹远程路径
        while [ $retry_count -lt $max_retries ] && [ $upload_success -eq 0 ]; do
            find "${content_dir}"/ -size -100000k -exec rm {} \;
            rclone -vv moveto -P --transfers=${rclone_parallel} --tpslimit 1 --drive-upload-cutoff 1000T "${content_dir}"/ "${remote_path}"
            if rclone_upload_check "${content_dir}"; then
                tg_push_message "[$(date '+%Y-%m-%d %H:%M:%S')] <b>${torrent_name}</b> 上传到网盘 <b>${NAME}</b> 的目录 <b>${UP_PATH}/${torrent_name}</b> 已完成。"
                upload_success=1
            else
                tg_push_message "[$(date '+%Y-%m-%d %H:%M:%S')] <b>${torrent_name}</b> 上传失败！将在10分钟后重试（第 $((retry_count + 1))/$max_retries 次）。"
                echo "[$(date '+%Y-%m-%d %H:%M:%S')] 上传失败！种子名称:${torrent_name}，将在10分钟后重试" >> ${log_dir}/qb.log
                sleep 600 # 等待10分钟
                retry_count=$((retry_count + 1))
                if [ $retry_count -eq $max_retries ]; then
                    tg_push_message "[$(date '+%Y-%m-%d %H:%M:%S')] <b>${torrent_name}</b> 上传失败！已达最大重试次数 ($max_retries)，请检查网络或配置。"
                    return 1
                fi
            fi
        done
    fi
    if [ $upload_success -eq 0 ]; then
        return 1
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
    tg_push_message "${TG_MSG2}"
    type="file"
    rclone_moveto
    if [ $? -eq 0 ]; then
        sync
        qb_del
        tg_push_message "[$(date '+%Y-%m-%d %H:%M:%S')] 上传和删除操作已完成。"
    fi
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
    tg_push_message "${TG_MSG2}"
    type="dir"
    rclone_moveto
    if [ $? -eq 0 ]; then
        sync
        qb_del
        tg_push_message "[$(date '+%Y-%m-%d %H:%M:%S')] 上传和删除操作已完成。"
    fi
else
    rclone_check
    tg_push_message "[$(date '+%Y-%m-%d %H:%M:%S')] 未知类型，取消上传"
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
