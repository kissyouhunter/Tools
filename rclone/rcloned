#!/bin/bash

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

### BEGIN INIT INFO
# Provides:          rclone
# Required-Start:    $all
# Required-Stop:     $all
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Start rclone at boot time
# Description:       Enable rclone by daemon.
### END INIT INFO

Green_font_prefix="\033[32m" && Red_font_prefix="\033[31m" && Green_background_prefix="\033[42;37m" && Red_background_prefix="\033[41;37m" && Font_color_suffix="\033[0m"
Info="${Green_font_prefix}[信息]${Font_color_suffix}"
Error="${Red_font_prefix}[错误]${Font_color_suffix}"

check_running() {
    PID="$(ps -C rclone -o pid=,args= | awk -v name="$NAME" '$0~name {print $1}')"
    if [[ ! -z ${PID} ]]; then
        return 0
    else
        return 1
    fi
}

do_start() {
    NAME="$1"
    REMOTE="$2"
    LOCAL="$3"

    check_running
    if [[ $? -eq 0 ]]; then
        echo -e "${Info} $NAME (PID ${PID}) 正在运行..."
    else
        fusermount -zuq "$LOCAL" >/dev/null 2>&1
        mkdir -p "$LOCAL"
        /usr/bin/rclone mount -vv "$NAME":"$REMOTE" "$LOCAL" --copy-links --allow-other --allow-non-empty --umask 000 >/dev/null 2>&1 &
        sleep 2s
        check_running
        if [[ $? -eq 0 ]]; then
            echo -e "${Info} $NAME 启动成功！"
        else
            echo -e "${Error} $NAME 启动失败！"
        fi
    fi
}

do_stop() {
    NAME="$1"
    LOCAL="$2"

    check_running
    if [[ $? -eq 0 ]]; then
        kill -9 "$PID"
        RETVAL=$?
        if [[ $RETVAL -eq 0 ]]; then
            echo -e "${Info} $NAME 停止成功！"
        else
            echo -e "${Error} $NAME 停止失败！"
        fi
    else
        echo -e "${Info} $NAME 未运行"
        RETVAL=1
    fi
    fusermount -zuq "$LOCAL" >/dev/null 2>&1
}

do_status() {
    NAME="$1"

    check_running
    if [[ $? -eq 0 ]]; then
        echo -e "${Info} $NAME (PID $PID) 正在运行..."
    else
        echo -e "${Info} $NAME 未运行！"
        RETVAL=1
    fi
}

do_restart() {
    NAME="$1"
    REMOTE="$2"
    LOCAL="$3"

    do_stop "$NAME" "$LOCAL"
    sleep 2s
    do_start "$NAME" "$REMOTE" "$LOCAL"
}

case "$1" in
    start)
        do_start "<Rclone配置时填写的name>" "<远程文件夹，网盘里的挂载的一个文件夹，留空为整个网盘>" "<本地挂载地址>"
        do_start "<Rclone配置时填写的name>" "<远程文件夹，网盘里的挂载的一个文件夹，留空为整个网盘>" "<本地挂载地址>"
        ;;
    stop)
        do_stop "<Rclone配置时填写的name>" "<本地挂载地址>"
        do_stop "<Rclone配置时填写的name>" "<本地挂载地址>"
        ;;
    status)
        do_status "<Rclone配置时填写的name>"
        do_status "<Rclone配置时填写的name>"
        ;;
    restart)
        do_restart "<Rclone配置时填写的name>" "<远程文件夹，网盘里的挂载的一个文件夹，留空为整个网盘>" "<本地挂载地址>"
        do_restart "<Rclone配置时填写的name>" "<远程文件夹，网盘里的挂载的一个文件夹，留空为整个网盘>" "<本地挂载地址>"
        ;;
    *)
        echo "使用方法: $0 { start | stop | status }"
        RETVAL=1
        ;;
esac

exit $RETVAL
