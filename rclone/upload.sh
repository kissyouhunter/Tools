#!/usr/bin/env bash
#
# https://github.com/P3TERX/aria2.conf
# File name：upload.sh
# Description: Use Rclone to upload files after Aria2 download is complete
# Version: 3.1
#
# Copyright (c) 2018-2021 P3TERX <https://p3terx.com>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#

# TG BOT
TG_TOKEN=""  #tg机器人的token
TG_ID="" #tg的user ID

tg_push_message1() {
    TOKEN=${TG_TOKEN}	#TG机器人token
    chat_ID=${TG_ID}		#用户ID或频道、群ID
    message_text="${TG_MSG1}"		#要发送的信息
    MODE="HTML"		#解析模式，可选HTML或Markdown
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

tg_push_message3() {
	TOKEN=${TG_TOKEN}	#TG机器人token
	chat_ID=${TG_ID}		#用户ID或频道、群ID
	message_text="${TG_MSG3}"		#要发送的信息
	MODE="HTML"		#解析模式，可选HTML或Markdown
	URL="https://api.telegram.org/bot${TOKEN}/sendMessage"		#api接口
	curl -s -o /dev/null -X POST $URL -d chat_id=${chat_ID} -d parse_mode=${MODE} -d text="${message_text}" --max-time 10
}

tg_push_message4() {
	TOKEN=${TG_TOKEN}	#TG机器人token
	chat_ID=${TG_ID}		#用户ID或频道、群ID
	message_text="${TG_MSG4}"		#要发送的信息
	MODE="HTML"		#解析模式，可选HTML或Markdown
	URL="https://api.telegram.org/bot${TOKEN}/sendMessage"		#api接口
	curl -s -o /dev/null -X POST $URL -d chat_id=${chat_ID} -d parse_mode=${MODE} -d text="${message_text}" --max-time 10
}

CHECK_CORE_FILE() {
    CORE_FILE="$(dirname $0)/core"
    if [[ -f "${CORE_FILE}" ]]; then
        . "${CORE_FILE}"
    else
        echo && echo "!!! core file does not exist !!!"
        exit 1
    fi
}

CHECK_RCLONE() {
    if [ "$(command -v rclone)" ]; then
        echo
    else
        TG_MSG4="rclone 未安装"
        tg_push_message4
        exit 1
    fi
}

TASK_INFO() {
    echo -e "
-------------------------- [${YELLOW_FONT_PREFIX}Task Infomation${FONT_COLOR_SUFFIX}] --------------------------
${LIGHT_PURPLE_FONT_PREFIX}Task GID:${FONT_COLOR_SUFFIX} ${TASK_GID}
${LIGHT_PURPLE_FONT_PREFIX}Number of Files:${FONT_COLOR_SUFFIX} ${FILE_NUM}
${LIGHT_PURPLE_FONT_PREFIX}First File Path:${FONT_COLOR_SUFFIX} ${FILE_PATH}
${LIGHT_PURPLE_FONT_PREFIX}Task File Name:${FONT_COLOR_SUFFIX} ${TASK_FILE_NAME}
${LIGHT_PURPLE_FONT_PREFIX}Task Path:${FONT_COLOR_SUFFIX} ${TASK_PATH}
${LIGHT_PURPLE_FONT_PREFIX}Aria2 Download Directory:${FONT_COLOR_SUFFIX} ${ARIA2_DOWNLOAD_DIR}
${LIGHT_PURPLE_FONT_PREFIX}Custom Download Directory:${FONT_COLOR_SUFFIX} ${DOWNLOAD_DIR}
${LIGHT_PURPLE_FONT_PREFIX}Local Path:${FONT_COLOR_SUFFIX} ${LOCAL_PATH}
${LIGHT_PURPLE_FONT_PREFIX}Remote Path:${FONT_COLOR_SUFFIX} ${REMOTE_PATH}
${LIGHT_PURPLE_FONT_PREFIX}.aria2 File Path:${FONT_COLOR_SUFFIX} ${DOT_ARIA2_FILE}
-------------------------- [${YELLOW_FONT_PREFIX}Task Infomation${FONT_COLOR_SUFFIX}] --------------------------
"
}

OUTPUT_UPLOAD_LOG() {
    LOG="${UPLOAD_LOG}"
    LOG_PATH="${UPLOAD_LOG_PATH}"
    OUTPUT_LOG
}

DEFINITION_PATH() {
    LOCAL_PATH="${TASK_PATH}"
    if [[ -f "${TASK_PATH}" ]]; then
        REMOTE_PATH="${DRIVE_NAME}:${DRIVE_DIR}${DEST_PATH_SUFFIX%/*}"
    else
        REMOTE_PATH="${DRIVE_NAME}:${DRIVE_DIR}${DEST_PATH_SUFFIX}"
    fi
}

LOAD_RCLONE_ENV() {
    RCLONE_ENV_FILE="${ARIA2_CONF_DIR}/rclone.env"
    [[ -f ${RCLONE_ENV_FILE} ]] && export $(grep -Ev "^#|^$" ${RCLONE_ENV_FILE} | xargs -0)
}

UPLOAD_FILE() {
    echo -e "$(DATE_TIME) ${INFO} Start upload files..."
    TG_MSG1="$(DATE_TIME) 开始上传..."
    tg_push_message1
    TASK_INFO
    TG_MSG2="--- [Task Infomation] ---
Task GID: ${TASK_GID}
Number of Files: ${FILE_NUM}
First File Path: ${FILE_PATH}
Task File Name: ${TASK_FILE_NAME}
Task Path: ${TASK_PATH}
Aria2 Download Directory: ${ARIA2_DOWNLOAD_DIR}
Custom Download Directory: ${DOWNLOAD_DIR}
Local Path: ${LOCAL_PATH}
Remote Path: ${REMOTE_PATH}
.aria2 File Path: ${DOT_ARIA2_FILE}
--- [Task Infomation] ---"
    tg_push_message2
    RETRY=0
    RETRY_NUM=3
    while [ ${RETRY} -le ${RETRY_NUM} ]; do
        [ ${RETRY} != 0 ] && (
            echo
            echo -e "$(DATE_TIME) ${ERROR} Upload failed! Retry ${RETRY}/${RETRY_NUM} ..."
            echo
        )
        rclone move -v "${LOCAL_PATH}" "${REMOTE_PATH}"
        TG_MSG3="[$(date '+%Y-%m-%d %H:%M:%S')] ${LOCAL_PATH} 上传到网盘 $NAME 的 ${REMOTE_PATH} 目录已完成。"
        tg_push_message1
        RCLONE_EXIT_CODE=$?
        if [ ${RCLONE_EXIT_CODE} -eq 0 ]; then
            UPLOAD_LOG="$(DATE_TIME) ${INFO} Upload done: ${LOCAL_PATH} -> ${REMOTE_PATH}"
            OUTPUT_UPLOAD_LOG
            DELETE_EMPTY_DIR
            break
        else
            RETRY=$((${RETRY} + 1))
            [ ${RETRY} -gt ${RETRY_NUM} ] && (
                echo
                UPLOAD_LOG="$(DATE_TIME) ${ERROR} Upload failed: ${LOCAL_PATH}"
                OUTPUT_UPLOAD_LOG
            )
            sleep 3
        fi
    done
}

CHECK_CORE_FILE "$@"
CHECK_SCRIPT_CONF
CHECK_RCLONE
CHECK_FILE_NUM
GET_TASK_INFO
GET_DOWNLOAD_DIR
CONVERSION_PATH
DEFINITION_PATH
CLEAN_UP
LOAD_RCLONE_ENV
UPLOAD_FILE
exit 0
