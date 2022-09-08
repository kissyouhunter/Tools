#!/bin/bash
#AUTHOR kissyouhunter

TIME() {
[[ -z "$1" ]] && {
	echo -ne " "
} || {
     case $1 in
	r) export Color="\e[31;1m";;
	g) export Color="\e[32;1m";;
	b) export Color="\e[34;1m";;
	y) export Color="\e[33;1m";;
	z) export Color="\e[35;1m";;
	l) export Color="\e[36;1m";;
	w) export Color="\e[29;1m";;
      esac
	[[ $# -lt 2 ]] && echo -e "\e[36m\e[0m ${1}" || {
		echo -e "\e[36m\e[0m ${Color}${2}\e[0m"
	 }
      }
}

log() {
    echo -e "\n$1"
}
inp() {
    echo -e "\n$1"
}

opt() {
    echo -n -e "输入您的选择->"
}
cancelrun() {
    if [ $# -gt 0 ]; then
        echo -e " $1 "
    fi
    exit 1
}

tg_push_message() {
	TOKEN=	#TG机器人token
	chat_ID=		#用户ID或频道、群ID
	message_text="${TG_MSG}"		#要发送的信息
	MODE="markdownV2"		#解析模式，可选HTML或Markdown
	URL="https://api.telegram.org/bot${TOKEN}/sendMessage"		#api接口
	curl -s -o /dev/null -X POST $URL -d chat_id=${chat_ID} -d parse_mode=${MODE} -d text="${message_text}" --max-time 10
}

# 青龙变量
QL_DOCKER_IMG_NAME="whyour/qinglong"
# elev2p变量
TAG="latest"
V2P_DOCKER_IMG_NAME="elecv2/elecv2p"
# emby变量
EMBY_DOCKER_IMG_NAME="xinjiawei1/emby_unlockd"
EMBY_TAG="latest"
# jellyfin变量
JELLYFIN_DOCKER_IMG_NAME="jellyfin/jellyfin"
# qbittorrent变量
QB_DOCKER_IMG_NAME="johngong/qbittorrent"
QB_TAG="4.4.3.1-4.4.3.12"
# aria2变量
ARIA2_DOCKER_IMG_NAME="superng6/aria2"
ARIA2_TAG="webui-latest"
# aria2-pro变量
ARIA2_PRO_DOCKER_IMG_NAME="p3terx/aria2-pro"
ARIA2_PRO_WEBUI_DOCKER_IMG_NAME="p3terx/ariang"
# telethon变量
TELETHON_DOCKER_IMG_NAME="kissyouhunter/telethon"
# adguardhome变量
ADG_DOCKER_IMG_NAME="adguard/adguardhome"
# x-ui变量
XUI_DOCKER_IMG_NAME="kissyouhunter/x-ui"
# aapanel变量
AAPANEL_DOCKER_IMG_NAME="aapanel/aapanel"
AAPANEL_TAG="lib"
# MaiARK 变量
MAIARK_DOCKER_IMG_NAME="kissyouhunter/maiark"

#检查root环境
#f [[ $EUID != 0 ]]; then
#	TIME w "请切换至root用户再执行脚本！" >&2
#	sleep 2
#	exit 1
#fi

function main() {
	clear
	MENU=$(whiptail --title "一键脚本 作者：kissyouhunter" --menu "Github: https://github.com/kissyouhunter \
	安装过程中如想退出，请狂按 ESC" 20 55 11 \
	"1" "安装 docker 和 docker-compose" \
	"2" "安装 青龙 到宿主机" \
	"3" "安装 elecv2p 到宿主机" \
	"4" "安装 docker 图形管理工具" \
	"5" "安装 emby 或 jellyfin (打造自己的爱奇艺)" \
	"6" "安装下载工具" \
	"7" "Telegram 定时发送信息工具" \
	"8" "AdGuardHome DNS解析+去广告" \
	"9" "x-ui" \
	"10" "aaPanel (宝塔国际版)" \
	"11" "MaiARK (对接青龙提交京东CK)" \
	3>&1 1>&2 2>&3)

	exitstatus=$?	
	if [ $exitstatus = 0 ]; then
    	case "$MENU" in
		1 )
			#安装docker和docker-compose
            clear
			function submenu1() {
				SUBMENU1=$(whiptail --title "一键脚本 作者：kissyouhunter" --menu "DOCKER & DOCKER-COMPOSE" 15 63 4 \
				"1" "安装<docker>和<docker-compose>" \
				"2" "X86 openwrt安装docker和装docker-comopse" \
				"3" "Arm64 openwrt安装docker和装docker-comopse(例 N1 等)" \
				"0" "返回上级菜单" \
				3>&1 1>&2 2>&3)

				exitstatus=$?
				if [ $exitstatus = 0 ]; then
					case "$SUBMENU1" in
						1 )
							TIME y " >>>>>>>>>>>开始安装docker和docker-compose"
							if [ "$lsb_dist" == "openwrt" ]; then
								whiptail --title "一键脚本 作者：kissyouhunter" --msgbox "openwrt宿主机请选择<2>或<3>安装docker，点击 OK 返回" 10 55
								main
							else
								sleep 1
        						bash <(curl -s -S -L https://raw.githubusercontent.com/kissyouhunter/Tools/main/docker-and-docker_compose.sh)
								if [ "$(command -v docker)" ] && [ "$(command -v docker-compose)" ]; then
									whiptail --title "一键脚本 作者：kissyouhunter" --msgbox "docker 和 docker-compose 安装完成，点击 OK 返回" 10 55
									main
								elif [ ! "$(command -v docker)" ]; then
									whiptail --title "一键脚本 作者：kissyouhunter" --msgbox "docker 和 docker-compose 安装失败了,点击 OK 返回" 10 55
									main
								elif [ "$(command -v docker)" ] && [ ! "$(command -v docker-compose)" ]; then
									whiptail --title "一键脚本 作者：kissyouhunter" --msgbox "docker 安装完成，docker-compose 安装失败了,点击 OK 返回" 10 65
									main
								fi
							fi
							;;
						2 )
							TIME y " >>>>>>>>>>>开始为 X86 openwrt 安装 docker 和 docker-compose"
							mkdir -p /tmp/upload/ && cd /tmp/upload/
							curl -LO https://tt.kisssik.ga/d/aliyun/files/docker-2010.12-1_x86_64.zip
							unzip docker-2010.12-1_x86_64.zip && rm -f docker-2010.12-1_x86_64.zip
							cd /tmp/upload/docker-2010.12-1_x86_64 && opkg install *.ipk && cd .. && rm -rf docker-2010.12-1_x86_64/
							if [ "$(command -v docker)" ]; then
								whiptail --title "一键脚本 作者：kissyouhunter" --msgbox "docker 和 docker-compose 安装完成，点击 OK 返回" 10 55
							else
								whiptail --title "一键脚本 作者：kissyouhunter" --msgbox "docker 和 docker-compose 安装失败，点击 OK 返回" 10 55
							fi
							main
							;;
						3 )
						    TIME y " >>>>>>>>>>>开始为 Arm64 openwrt 安装 docker 和 docker-compose"
							mkdir -p /tmp/upload/ && cd /tmp/upload/
							curl -LO https://tt.kisssik.ga/d/aliyun/files/docker-20.10.15-1_aarch64.zip
							unzip docker-20.10.15-1_aarch64.zip && rm -f docker-20.10.15-1_aarch64.zip
							cd /tmp/upload/docker-20.10.15-1_aarch64 && opkg install *.ipk
							cd /tmp/upload && rm -rf docker-20.10.15-1_aarch64/
							if [ "$(command -v docker)" ]; then
								whiptail --title "一键脚本 作者：kissyouhunter" --msgbox "docker 和 docker-compose 安装完成，点击 OK 返回 \
								U盘上运行的OP，如果docker空间没有指定到 /mnt/sda4/docker ，请修改 \
								dockerman > 设置 > Docker 根目录 修改为 /mnt/sda4/docker" 10 70
							else
								whiptail --title "一键脚本 作者：kissyouhunter" --msgbox "docker 和 docker-compose 安装失败，点击 OK 返回" 10 55
							fi
							main
							;;
						0 )
							main
							;;
					esac
				else
					exit 0
				fi
			}
			submenu1
			;;
		2 )
			#安装青龙
            clear
			function submenu2() {
				SUBMENU2=$(whiptail --title "一键脚本 作者：kissyouhunter" --menu "青龙" 15 52 3 \
				"1" "linxu系统、X86 的 openwrt、群辉等请选择 1" \
				"2" "N1 的 EMMC 上运行的 openwrt 请选择 2" \
				"0" "返回上级菜单" \
				3>&1 1>&2 2>&3)

				exitstatus=$?
				if [ $exitstatus = 0 ]; then
					case "$SUBMENU2" in
						1 )
							function input_container_ql1_info() {
								whiptail --title "一键脚本 作者：kissyouhunter" --msgbox "访问方式为：宿主机 ip:$QL_PORT \
								青龙 安装完成，点击 ok 退出脚本 " 10 50
							}

							function input_container_ql1_docker() {
								function input_container_ql1_build1() {
									TIME y " >>>>>>>>>>>配置完成，开始安装青龙"
									log "1.开始创建配置文件目录"
									PATH_LIST=($CONFIG_PATH)
									for i in ${PATH_LIST[@]}; do
										mkdir -p $i
									done
									log "2.开始创建容器并执行"
									docker run -dit \
										-t \
										-v $CONFIG_PATH:/ql/data \
										-e ENABLE_HANGUP=false \
										-e ENABLE_WEB_PANEL=true \
										-p $QL_PORT:5700 \
										--name $QL_CONTAINER_NAME \
										--hostname $QL_CONTAINER_NAME \
										--restart always \
										--network $NETWORK \
										--log-opt max-size=10m \
										--log-opt max-file=5 \
										$QL_DOCKER_IMG_NAME:$QL_TAG

									if [ $? -ne 0 ] ; then
										cancelrun "** 错误：容器创建失败，请翻译以上英文报错，Google/百度尝试解决问题！"
									fi
								}

								function input_container_ql1_build2() {
									TIME y " >>>>>>>>>>>配置完成，开始安装青龙"
									log "1.开始创建配置文件目录"
									PATH_LIST=($CONFIG_PATH $DB_PATH $REPO_PATH $SCRIPT_PATH $LOG_PATH $DEPS_PATH)
									for i in ${PATH_LIST[@]}; do
										mkdir -p $i
									done
									log "2.开始创建容器并执行"
									docker run -dit \
										-t \
										-v $CONFIG_PATH:/ql/config \
										-v $DB_PATH:/ql/db \
										-v $LOG_PATH:/ql/log \
										-v $REPO_PATH:/ql/repo \
										-v $SCRIPT_PATH:/ql/scripts \
										-v $DEPS_PATH:/ql/deps \
										-e ENABLE_HANGUP=false \
										-e ENABLE_WEB_PANEL=true \
										-p $QL_PORT:5700 \
										--name $QL_CONTAINER_NAME \
										--hostname $QL_CONTAINER_NAME \
										--restart always \
										--network $NETWORK \
										--log-opt max-size=10m \
										--log-opt max-file=5 \
										$QL_DOCKER_IMG_NAME:$QL_TAG

									if [ $? -ne 0 ] ; then
										cancelrun "** 错误：容器创建失败，请翻译以上英文报错，Google/百度尝试解决问题！"
									fi
								}
								
								if [ $QL_TAG == "2.10" ] || [ $QL_TAG == "2.10.6" ] || [ $QL_TAG == "2.10.7" ] || [ $QL_TAG == "2.10.8" ] || [ $QL_TAG == "2.10.9" ] || [ $QL_TAG == "2.10.10" ] || [ $QL_TAG == "2.10.11" ] || [ $QL_TAG == "2.10.12" ] || [ $QL_TAG == "2.10.13" ] || [ $QL_TAG == "2.11" ] || [ $QL_TAG == "2.11.0" ] || [ $QL_TAG == "2.11.1" ] || [ $QL_TAG == "2.11.2" ] || [ $QL_TAG == "2.11.3" ]; then
									CONFIG_PATH=$QL_PATH/config
									DB_PATH=$QL_PATH/db
									REPO_PATH=$QL_PATH/repo
									SCRIPT_PATH=$QL_PATH/scripts
									LOG_PATH=$QL_PATH/log
									DEPS_PATH=$QL_PATH/deps
									input_container_ql1_build2
									sleep 10
									input_container_ql1_info
									docker ps -a
								else
									CONFIG_PATH=$QL_PATH
									input_container_ql1_build1
									sleep 10
									input_container_ql1_info
									docker ps -a
								fi
							}

							function input_container_ql1_check() {
								if (whiptail --title "一键脚本 作者：kissyouhunter" --yesno "青龙容器名：$QL_CONTAINER_NAME           \
								青龙配置文件路径：$QL_PATH           \
								青龙网络类型：$NETWORK           \
								青龙面板端口：$QL_PORT           \
								青龙版本：$QL_TAG               \
								以上信息是否正确？"              \
								13 40) then
									input_container_ql1_docker
								else
									ql1_input
									QL_PORT="5700"
								fi
							}

							function input_container_ql1_version() {
								QL1_VERSION=$(whiptail --title "一键脚本 作者：kissyouhunter" --inputbox "目前提供的版本有如下： \
								2.10.6--13、2.11.0--3、2.12.0--2、2.13.0--8及最新 \
								请输入版本号[回车默认为：latest]" 12 55 3>&1 1>&2 2>&3)

								exitstatus=$?
								if [ $exitstatus = 0 ]; then
									if [ -z "$QL1_VERSION" ]; then
										QL_TAG="latest"
									else
										QL_TAG=$QL1_VERSION
									fi
								else
									exit 0
								fi
							}

							function ql1_input() {
								QL1_NAME=$(whiptail --title "一键脚本 作者：kissyouhunter" --inputbox "请输入将要创建的容器名[回车默认为：ql]" 10 55 3>&1 1>&2 2>&3)
								
								exitstatus=$?
								if [ $exitstatus = 0 ]; then
									if [ -z "$QL1_NAME" ]; then
										QL_CONTAINER_NAME="ql"
									else
										QL_CONTAINER_NAME=$QL1_NAME
									fi
								else
									exit 0
								fi

								QL1_CONFIG=$(whiptail --title "一键脚本 作者：kissyouhunter" --inputbox "请输入青龙配置文件保存的绝对路径 \
								（示例：/home/ql)，回车默认为当前目录:" 10 50 3>&1 1>&2 2>&3)

								exitstatus=$?
								if [ $exitstatus = 0 ]; then
									if [ -z "$QL1_CONFIG" ]; then
										QL_PATH=$(pwd)/ql
									else
										QL_PATH=$QL1_CONFIG
									fi
								else
									exit 0
								fi

								function input_container_ql1_network_config() {
									QL1_NETWORK=$(whiptail --title "一键脚本 作者：kissyouhunter" --menu "请选择网络模式" 12 40 2 \
									"1" "bridge（桥接模式）" \
									"2" "host模式" \
									3>&1 1>&2 2>&3)

									exitstatus=$?
									if [ $exitstatus = 0 ]; then
										case "$QL1_NETWORK" in
											1 )
												NETWORK="bridge"
												function input_container_ql1_bridge_port() {
													QL1_BRIDGE_PORT=$(whiptail --title "一键脚本 作者：kissyouhunter" --inputbox "请输入桥接端口[回车默认为：5700]" 10 55 3>&1 1>&2 2>&3)
													if [ -z "$QL1_BRIDGE_PORT" ]; then
														QL_PORT="5700"
													else
														QL_PORT=$QL1_BRIDGE_PORT
													fi
												}
												input_container_ql1_bridge_port
												input_container_ql1_version
												input_container_ql1_check
												;;
											2 )
												NETWORK="host"
												QL_PORT="5700"
												input_container_ql1_version
												input_container_ql1_check
												;;
										esac
									else
										exit 0
									fi
								}
								input_container_ql1_network_config

							}
							ql1_input
							;;
						2 )
							function input_container_ql2_info() {
								whiptail --title "一键脚本 作者：kissyouhunter" --msgbox "访问方式为：宿主机 ip:$QL_PORT \
								青龙 安装完成，点击 ok 退出脚本 " 10 50
							}

							function input_container_ql2_docker() {
								function input_container_ql2_build1() {
									TIME y " >>>>>>>>>>>配置完成，开始安装青龙"
									log "1.开始创建配置文件目录"
									PATH_LIST=($CONFIG_PATH)
									for i in ${PATH_LIST[@]}; do
										mkdir -p $i
									done
									log "2.开始创建容器并执行"
									docker run -dit \
										-t \
										-v $CONFIG_PATH:/ql/data \
										-e ENABLE_HANGUP=false \
										-e ENABLE_WEB_PANEL=true \
										-p $QL_PORT:5700 \
										--name $QL_CONTAINER_NAME \
										--hostname $QL_CONTAINER_NAME \
										--restart always \
										--network $NETWORK \
										--log-opt max-size=10m \
										--log-opt max-file=5 \
										$QL_DOCKER_IMG_NAME:$QL_TAG

									if [ $? -ne 0 ] ; then
										cancelrun "** 错误：容器创建失败，请翻译以上英文报错，Google/百度尝试解决问题！"
									fi
								}

								function input_container_ql2_build2() {
									TIME y " >>>>>>>>>>>配置完成，开始安装青龙"
									log "1.开始创建配置文件目录"
									PATH_LIST=($CONFIG_PATH $DB_PATH $REPO_PATH $SCRIPT_PATH $LOG_PATH $DEPS_PATH)
									for i in ${PATH_LIST[@]}; do
										mkdir -p $i
									done
									log "2.开始创建容器并执行"
									docker run -dit \
										-t \
										-v $CONFIG_PATH:/ql/config \
										-v $DB_PATH:/ql/db \
										-v $LOG_PATH:/ql/log \
										-v $REPO_PATH:/ql/repo \
										-v $SCRIPT_PATH:/ql/scripts \
										-v $DEPS_PATH:/ql/deps \
										-e ENABLE_HANGUP=false \
										-e ENABLE_WEB_PANEL=true \
										-p $QL_PORT:5700 \
										--name $QL_CONTAINER_NAME \
										--hostname $QL_CONTAINER_NAME \
										--restart always \
										--network $NETWORK \
										--log-opt max-size=10m \
										--log-opt max-file=5 \
										$QL_DOCKER_IMG_NAME:$QL_TAG

									if [ $? -ne 0 ] ; then
										cancelrun "** 错误：容器创建失败，请翻译以上英文报错，Google/百度尝试解决问题！"
									fi
								}
								
								if [ $QL_TAG == "2.10" ] || [ $QL_TAG == "2.10.6" ] || [ $QL_TAG == "2.10.7" ] || [ $QL_TAG == "2.10.8" ] || [ $QL_TAG == "2.10.9" ] || [ $QL_TAG == "2.10.10" ] || [ $QL_TAG == "2.10.11" ] || [ $QL_TAG == "2.10.12" ] || [ $QL_TAG == "2.10.13" ] || [ $QL_TAG == "2.11" ] || [ $QL_TAG == "2.11.0" ] || [ $QL_TAG == "2.11.1" ] || [ $QL_TAG == "2.11.2" ] || [ $QL_TAG == "2.11.3" ]; then
									CONFIG_PATH=$QL_PATH/config
									DB_PATH=$QL_PATH/db
									REPO_PATH=$QL_PATH/repo
									SCRIPT_PATH=$QL_PATH/scripts
									LOG_PATH=$QL_PATH/log
									DEPS_PATH=$QL_PATH/deps
									input_container_ql2_build2
									sleep 10
									input_container_ql2_info
									docker ps -a
								else
									CONFIG_PATH=$QL_PATH
									input_container_ql2_build1
									sleep 10
									input_container_ql2_info
									docker ps -a
								fi
							}

							function input_container_ql2_check() {
								if (whiptail --title "一键脚本 作者：kissyouhunter" --yesno "青龙容器名：$QL_CONTAINER_NAME             \
								青龙配置文件路径：$QL_PATH                \
								青龙网络类型：$NETWORK                 \
								青龙面板端口：$QL_PORT                 \
								青龙版本：$QL_TAG                      \
								以上信息是否正确？"                     \
								13 40) then
									input_container_ql2_docker
								else
									ql2_input
									QL_PORT="5700"
								fi
							}

							function input_container_ql2_version() {
								QL2_VERSION=$(whiptail --title "一键脚本 作者：kissyouhunter" --inputbox "目前提供的版本有如下： \
								2.10.6--13、2.11.0--3、2.12.0--2、2.13.0--8及最新 \
								请输入版本号[回车默认为：latest]" 12 55 3>&1 1>&2 2>&3)

								exitstatus=$?
								if [ $exitstatus = 0 ]; then
									if [ -z "$QL2_VERSION" ]; then
										QL_TAG="latest"
									else
										QL_TAG=$QL2_VERSION
									fi
								else
									exit 0
								fi
							}

							function ql2_input() {
								QL2_NAME=$(whiptail --title "一键脚本 作者：kissyouhunter" --inputbox "请输入将要创建的容器名[回车默认为：ql]" 10 55 3>&1 1>&2 2>&3)
								
								exitstatus=$?
								if [ $exitstatus = 0 ]; then
									if [ -z "$QL2_NAME" ]; then
										QL_CONTAINER_NAME="ql"
									else
										QL_CONTAINER_NAME=$QL2_NAME
									fi
								else
									exit 0
								fi

								QL2_CONFIG=$(whiptail --title "一键脚本 作者：kissyouhunter" --inputbox "请输入青龙存储的文件夹名称（如：ql)，回车默认为 ql:" 10 50 3>&1 1>&2 2>&3)

								exitstatus=$?
								if [ $exitstatus = 0 ]; then
									if [ -z "$QL2_CONFIG" ]; then
										QL_PATH=/mnt/mmcblk2p4/ql
									else
										QL_PATH=/mnt/mmcblk2p4/$QL2_CONFIG
									fi
								else
									exit 0
								fi

								function input_container_ql2_network_config() {
									QL2_NETWORK=$(whiptail --title "一键脚本 作者：kissyouhunter" --menu "请选择网络模式" 12 40 2 \
									"1" "bridge（桥接模式）" \
									"2" "host模式" \
									3>&1 1>&2 2>&3)

									exitstatus=$?
									if [ $exitstatus = 0 ]; then
										case "$QL2_NETWORK" in
											1 )
												NETWORK="bridge"
												function input_container_ql2_bridge_port() {
													QL2_BRIDGE_PORT=$(whiptail --title "一键脚本 作者：kissyouhunter" --inputbox "请输入桥接端口[回车默认为：5700]" 10 55 3>&1 1>&2 2>&3)
													if [ -z "$QL2_BRIDGE_PORT" ]; then
														QL_PORT="5700"
													else
														QL_PORT=$QL2_BRIDGE_PORT
													fi
												}
												input_container_ql2_bridge_port
												input_container_ql2_version
												input_container_ql2_check
												;;
											2 )
												NETWORK="host"
												QL_PORT="5700"
												input_container_ql2_version
												input_container_ql2_check
												;;
										esac
									else
										exit 0
									fi
								}
								input_container_ql2_network_config

							}
							ql2_input
							;;							
						0 )
							main
							;;
					esac
				else
					exit 0
				fi
			}
			submenu2
			;;
		3 )
			#安装elecv2p
            clear
			function submenu3() {
				SUBMENU3=$(whiptail --title "一键脚本 作者：kissyouhunter" --menu "ELECV2P" 15 52 3 \
				"1" "linxu系统、X86 的 openwrt、群辉等请选择 1" \
				"2" "N1 的 EMMC 上运行的 openwrt 请选择 2" \
				"0" "返回上级菜单" \
				3>&1 1>&2 2>&3)

				exitstatus=$?
				if [ $exitstatus = 0 ]; then
					case "$SUBMENU3" in
						1 )
							function input_container_v2p1_info() {
								whiptail --title "一键脚本 作者：kissyouhunter" --msgbox "访问方式为：宿主机 ip:$V2P_PORT \
								ELECV2P 安装完成，点击 ok 退出脚本 " 10 50
							}

							function input_container_v2p1_build() {
								TIME y " >>>>>>>>>>>配置完成，开始安装 elecv2p"
								log "1.开始创建配置文件目录"
								PATH_LIST=($JSFILE_PATH $LISTS_PATH $STORE_PATH $SHELL_PATH $ROOTCA_PATH $EFSS_PATH $LOG_PATH)
								for i in ${PATH_LIST[@]}; do
									mkdir -p $i
								done
								log "2.开始创建容器并执行"
								docker run -dit \
									-v $JSFILE_PATH:/usr/local/app/script/JSFile \
									-v $LISTS_PATH:/usr/local/app/script/Lists \
									-v $STORE_PATH:/usr/local/app/script/Store \
									-v $SHELL_PATH:/usr/local/app/script/Shell \
									-v $ROOTCA_PATH:/usr/local/app/rootCA \
									-v $EFSS_PATH:/usr/local/app/efss \
									-p $V2P_PORT:80 -p $V2P_PORT1:8001 -p $V2P_PORT2:8002 \
									-e TZ=Asia/Shanghai \
									--name $V2P_CONTAINER_NAME \
									--hostname $V2P_CONTAINER_NAME \
									--restart always \
									$V2P_DOCKER_IMG_NAME:$TAG

								if [ $? -ne 0 ] ; then
									cancelrun "** 错误：容器创建失败，请翻译以上英文报错，Google/百度尝试解决问题！"
								fi
							}

							function input_container_v2p1_check() {
								if (whiptail --title "一键脚本 作者：kissyouhunter" --yesno "elecv2p 容器名：$V2P_CONTAINER_NAME       \
								elecv2p 面板端口：$V2P_PORT             \
								elecv2p anyproxy端口：$V2P_PORT1               \
								elecv2p 网络请求查看端口：$V2P_PORT2          \
								elecv2p 配置文件路径：$V2P_PATH             \
								以上信息是否正确？"                          \
								13 45) then
									input_container_v2p1_build
									sleep 10
									input_container_v2p1_info
									docker ps -a
								else
									v2p1_input
									V2P_PORT="8100"
									V2P_PORT1="8101"
									V2P_PORT2="8102"
								fi
							}

							function v2p1_input() {
								function input_container_v2p1_name() {
									V2P1_NAME=$(whiptail --title "一键脚本 作者：kissyouhunter" --inputbox "请输入将要创建的容器名 [默认为：elecv2p]" 10 55 3>&1 1>&2 2>&3)

									exitstatus=$?
									if [ $exitstatus = 0 ]; then
										if [ -z "$V2P1_NAME" ]; then
											V2P_CONTAINER_NAME="elecv2p"
										else
											V2P_CONTAINER_NAME=$V2P1_NAME
										fi
									else
										exit 0
									fi
								}
								input_container_v2p1_name

								function input_container_v2p1_config() {
									V2P1_CONFIG=$(whiptail --title "一键脚本 作者：kissyouhunter" --inputbox "请输入 elecv2p 配置文件保存的绝对路径 \
									（示例：/home/elecv2p)，回车默认为当前目录:" 10 50 3>&1 1>&2 2>&3)

									exitstatus=$?
									if [ $exitstatus = 0 ]; then
										if [ -z "$V2P1_CONFIG" ]; then
											V2P_PATH=$(pwd)/elecv2p
										else
											V2P_PATH=$V2P1_CONFIG
										fi
									else
										exit 0
									fi
									JSFILE_PATH=$V2P_PATH/JSFile
 	 								LISTS_PATH=$V2P_PATH/Lists
 									STORE_PATH=$V2P_PATH/Store
  									SHELL_PATH=$V2P_PATH/Shell
  									ROOTCA_PATH=$V2P_PATH/rootCA
  									EFSS_PATH=$V2P_PATH/efss
  									LOG_PATH=$V2P_PATH/logs
								}
								input_container_v2p1_config

								function input_container_v2p1_network_config() {
									function input_container_v2p1_webui_config() {
										V2P1_WEBUI_PORT_CHANGE=$(whiptail --title "一键脚本 作者：kissyouhunter" --inputbox "输入 elecv2p 面板端口 [默认 8100]" 10 55 3>&1 1>&2 2>&3)

										exitstatus=$?
										if [ $exitstatus = 0 ]; then
											if [ -z "$V2P1_WEBUI_PORT_CHANGE" ]; then
												V2P_PORT="8100"
											else
												V2P_PORT=$V2P1_WEBUI_PORT_CHANGE
											fi
										else
											exit 0
										fi
									}
									input_container_v2p1_webui_config

									function input_container_v2p1_anyproxy_config() {
										V2P1_WEBUI_PORT_CHANGE=$(whiptail --title "一键脚本 作者：kissyouhunter" --inputbox "输入 elecv2p 的 anyproxy 端口 [默认 8101]" 10 55 3>&1 1>&2 2>&3)

										exitstatus=$?
										if [ $exitstatus = 0 ]; then
											if [ -z "$V2P1_WEBUI_PORT_CHANGE" ]; then
												V2P_PORT1="8101"
											else
												V2P_PORT1=$V2P1_WEBUI_PORT_CHANGE
											fi
										else
											exit 0
										fi
									}
									input_container_v2p1_anyproxy_config

									function input_container_v2p1_http_config() {
										V2P1_WEBUI_PORT_CHANGE=$(whiptail --title "一键脚本 作者：kissyouhunter" --inputbox "输入 elecv2p 网络请求查看端口 [默认 8102]" 10 55 3>&1 1>&2 2>&3)

										exitstatus=$?
										if [ $exitstatus = 0 ]; then
											if [ -z "$V2P1_WEBUI_PORT_CHANGE" ]; then
												V2P_PORT2="8102"
											else
												V2P_PORT2=$V2P1_WEBUI_PORT_CHANGE
											fi
										else
											exit 0
										fi
									}
									input_container_v2p1_http_config
									input_container_v2p1_check
								}
								input_container_v2p1_network_config
							}
							v2p1_input
							;;
						2 )
							function input_container_v2p2_info() {
								whiptail --title "一键脚本 作者：kissyouhunter" --msgbox "访问方式为：宿主机 ip:$V2P_PORT \
								ELECV2P 安装完成，点击 ok 退出脚本 " 10 50
							}

							function input_container_v2p2_build() {
								TIME y " >>>>>>>>>>>配置完成，开始安装 elecv2p"
								log "1.开始创建配置文件目录"
								PATH_LIST=($JSFILE_PATH $LISTS_PATH $STORE_PATH $SHELL_PATH $ROOTCA_PATH $EFSS_PATH $LOG_PATH)
								for i in ${PATH_LIST[@]}; do
									mkdir -p $i
								done
								log "2.开始创建容器并执行"
								docker run -dit \
									-v $JSFILE_PATH:/usr/local/app/script/JSFile \
									-v $LISTS_PATH:/usr/local/app/script/Lists \
									-v $STORE_PATH:/usr/local/app/script/Store \
									-v $SHELL_PATH:/usr/local/app/script/Shell \
									-v $ROOTCA_PATH:/usr/local/app/rootCA \
									-v $EFSS_PATH:/usr/local/app/efss \
									-p $V2P_PORT:80 -p $V2P_PORT1:8001 -p $V2P_PORT2:8002 \
									-e TZ=Asia/Shanghai \
									--name $V2P_CONTAINER_NAME \
									--hostname $V2P_CONTAINER_NAME \
									--restart always \
									$V2P_DOCKER_IMG_NAME:$TAG

								if [ $? -ne 0 ] ; then
									cancelrun "** 错误：容器创建失败，请翻译以上英文报错，Google/百度尝试解决问题！"
								fi
							}

							function input_container_v2p2_check() {
								if (whiptail --title "一键脚本 作者：kissyouhunter" --yesno "elecv2p 容器名：$V2P_CONTAINER_NAME                  \
								elecv2p 面板端口：$V2P_PORT                     \
								elecv2p anyproxy端口：$V2P_PORT1                    \
								elecv2p 网络请求查看端口：$V2P_PORT2                      \
								elecv2p 配置文件路径：$V2P_PATH                   \
								以上信息是否正确？"                               \
								13 50) then
									input_container_v2p2_build
									sleep 10
									input_container_v2p2_info
									docker ps -a
								else
									v2p2_input
									V2P_PORT="8100"
									V2P_PORT1="8101"
									V2P_PORT2="8102"
								fi
							}

							function v2p2_input() {
								function input_container_v2p2_name() {
									V2P2_NAME=$(whiptail --title "一键脚本 作者：kissyouhunter" --inputbox "请输入将要创建的容器名 [默认为：elecv2p]" 10 55 3>&1 1>&2 2>&3)

									exitstatus=$?
									if [ $exitstatus = 0 ]; then
										if [ -z "$V2P2_NAME" ]; then
											V2P_CONTAINER_NAME="elecv2p"
										else
											V2P_CONTAINER_NAME=$V2P1_NAME
										fi
									else
										exit 0
									fi
								}
								input_container_v2p2_name

								function input_container_v2p2_config() {
									V2P2_CONFIG=$(whiptail --title "一键脚本 作者：kissyouhunter" --inputbox "请输入 elecv2p 存储的文件夹名称 \
									（如：elecv2p)，回车默认为当前目录:" 10 50 3>&1 1>&2 2>&3)

									exitstatus=$?
									if [ $exitstatus = 0 ]; then
										if [ -z "$V2P2_CONFIG" ]; then
											V2P_PATH=/mnt/mmcblk2p4/elecv2p
										else
											V2P_PATH=/mnt/mmcblk2p4/$V2P1_CONFIG
										fi
									else
										exit 0
									fi
									JSFILE_PATH=$V2P_PATH/JSFile
 	 								LISTS_PATH=$V2P_PATH/Lists
 									STORE_PATH=$V2P_PATH/Store
  									SHELL_PATH=$V2P_PATH/Shell
  									ROOTCA_PATH=$V2P_PATH/rootCA
  									EFSS_PATH=$V2P_PATH/efss
  									LOG_PATH=$V2P_PATH/logs
								}
								input_container_v2p2_config

								function input_container_v2p2_network_config() {
									function input_container_v2p2_webui_config() {
										V2P2_WEBUI_PORT_CHANGE=$(whiptail --title "一键脚本 作者：kissyouhunter" --inputbox "输入 elecv2p 面板端口 [默认 8100]" 10 55 3>&1 1>&2 2>&3)

										exitstatus=$?
										if [ $exitstatus = 0 ]; then
											if [ -z "$V2P2_WEBUI_PORT_CHANGE" ]; then
												V2P_PORT="8100"
											else
												V2P_PORT=$V2P2_WEBUI_PORT_CHANGE
											fi
										else
											exit 0
										fi
									}
									input_container_v2p2_webui_config

									function input_container_v2p2_anyproxy_config() {
										V2P2_WEBUI_PORT_CHANGE=$(whiptail --title "一键脚本 作者：kissyouhunter" --inputbox "输入 elecv2p 的 anyproxy 端口 [默认 8101]" 10 55 3>&1 1>&2 2>&3)

										exitstatus=$?
										if [ $exitstatus = 0 ]; then
											if [ -z "$V2P2_WEBUI_PORT_CHANGE" ]; then
												V2P_PORT1="8101"
											else
												V2P_PORT1=$V2P2_WEBUI_PORT_CHANGE
											fi
										else
											exit 0
										fi
									}
									input_container_v2p2_anyproxy_config

									function input_container_v2p2_http_config() {
										V2P2_WEBUI_PORT_CHANGE=$(whiptail --title "一键脚本 作者：kissyouhunter" --inputbox "输入 elecv2p 网络请求查看端口 [默认 8102]" 10 55 3>&1 1>&2 2>&3)

										exitstatus=$?
										if [ $exitstatus = 0 ]; then
											if [ -z "$V2P2_WEBUI_PORT_CHANGE" ]; then
												V2P_PORT2="8102"
											else
												V2P_PORT2=$V2P2_WEBUI_PORT_CHANGE
											fi
										else
											exit 0
										fi
									}
									input_container_v2p2_http_config
									input_container_v2p2_check
								}
								input_container_v2p2_network_config
							}
							v2p2_input
							;;							
						0 )
							main
							;;
					esac
				else
					exit 0
				fi
			}
			submenu3	
			;;
		4 )
			#安装portainer
            clear
			function submenu4() {
				SUBMENU4=$(whiptail --title "一键脚本 作者：kissyouhunter" --menu "DOCKER 图形管理工具" 15 40 4 \
				"1" "安装 portianer" \
				"2" "安装 Fast Os Docker 中文" \
				"3" "安装 simpledocker 中文" \
				"0" "返回上级菜单" \
				3>&1 1>&2 2>&3)

				exitstatus=$?
				if [ $exitstatus = 0 ]; then
					case "$SUBMENU4" in
						1 )
							function input_container_portainer_info() {
								whiptail --title "一键脚本 作者：kissyouhunter" --msgbox "访问方式为：宿主机 ip:9000 \
								PORTAINER 安装完成，点击 ok 退出脚本 " 10 45
							}

							function input_container_portainer_build() {
								TIME y " >>>>>>>>>>>开始安装 portainer"
								docker volume create portainer_data
								docker run -d -p 8000:8000 -p 9000:9000 --name=portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ce
								if [ $? -ne 0 ] ; then
									cancelrun "** 错误：容器创建失败，请翻译以上英文报错，Google/百度尝试解决问题！"
								fi
							}
							input_container_portainer_build
							input_container_portainer_info
							;;
						2 )
							function input_container_fast_info() {
								whiptail --title "一键脚本 作者：kissyouhunter" --msgbox "访问方式为：宿主机 ip:18081 \
								Fast Os Docker 安装完成 \
								点击 ok 退出脚本 " 10 30
							}

							function input_container_fast_build() {
								TIME y " >>>>>>>>>>>开始安装 Fast Os Docker"
								docker run --restart always --name fast -p 18081:8081 -d -v /var/run/docker.sock:/var/run/docker.sock wangbinxingkong/fast
								if [ $? -ne 0 ] ; then
									cancelrun "** 错误：容器创建失败，请翻译以上英文报错，Google/百度尝试解决问题！"
								fi
							}
							input_container_fast_build
							input_container_fast_info
							;;
						3 )
							function input_container_simple_info() {
								whiptail --title "一键脚本 作者：kissyouhunter" --msgbox "访问方式为：宿主机 ip:9009 \
								simpledocker 安装完成，点击 ok 退出脚本 " 10 45
							}

							function input_container_simple_build() {
								TIME y " >>>>>>>>>>>开始安装 Fast Os Docker"
								mkdir -p simpledocker && cd simpledocker && curl -Lo docker-compose.yml https://raw.githubusercontent.com/kissyouhunter/Tools/main/simpledocker-docker-compose.yml
								docker-compose up -d
								if [ $? -ne 0 ] ; then
									cancelrun "** 错误：容器创建失败，请翻译以上英文报错，Google/百度尝试解决问题！"
								fi
							}
							input_container_simple_build
							input_container_simple_info
							;;
						0 )
							main
							;;
					esac
				else
					exit 0
				fi
			}
			submenu4	
			;;
		5 )
			#安装emby和jellyfin
            clear
			function submenu5() {
				SUBMENU5=$(whiptail --title "一键脚本 作者：kissyouhunter" --menu "EMBY & JELLYFIN" 15 40 3 \
				"1" "安装 emby (开心版暂无 arm64)" \
				"2" "安装 jellyfin" \
				"0" "返回上级菜单" \
				3>&1 1>&2 2>&3)

				exitstatus=$?
				if [ $exitstatus = 0 ]; then
					case "$SUBMENU5" in
						1 )
							function input_container_emby_info() {
								whiptail --title "一键脚本 作者：kissyouhunter" --msgbox "访问方式为宿主机 ip:$EMBY_PORT \
								执行命令 chmod 777 /dev/dri/* 才能读取到显卡 \
								emby 安装完成，点击 ok 退出脚本 " 10 50
							}

							function input_container_emby_build() {
								TIME y " >>>>>>>>>>>配置完成，开始安装 emby"
								log "1.开始创建配置文件目录"
								PATH_LIST=($CONFIG_PATH $MOVIES_PATH $TVSHOWS_PATH)
								for i in ${PATH_LIST[@]}; do
									mkdir -p $i
								done

								log "2.开始创建容器并执行"
									if [ -d "/dev/dri" ]; then
										docker run -dit \
             								--name $EMBY_CONTAINER_NAME \
              								--hostname $EMBY_CONTAINER_NAME \
              								--restart always \
              								-v $CONFIG_PATH:/config \
              								-v $MOVIES_PATH:/mnt/movies \
              								-v $TVSHOWS_PATH:/mnt/tvshows \
              								-p $EMBY_PORT:8096 -p $EMBY_PORT1:8920 \
              								-e TZ=Asia/Shanghai \
              								--device /dev/dri:/dev/dri \
              								-e UMASK_SET=022 \
              								-e UID=0 \
              								-e GID=0 \
              								-e GIDLIST=0 \
              								$EMBY_DOCKER_IMG_NAME:$EMBY_TAG
									else
          								docker run -dit \
              								--name $EMBY_CONTAINER_NAME \
              								--hostname $EMBY_CONTAINER_NAME \
              								--restart always \
              								-v $CONFIG_PATH:/config \
              								-v $MOVIES_PATH:/mnt/movies \
              								-v $TVSHOWS_PATH:/mnt/tvshows \
              								-p $EMBY_PORT:8096 -p $EMBY_PORT1:8920 \
              								-e TZ=Asia/Shanghai \
              								-e UMASK_SET=022 \
              								-e UID=0 \
  								            -e GID=0 \
              								-e GIDLIST=0 \
              								$EMBY_DOCKER_IMG_NAME:$EMBY_TAG
      								fi
								if [ $? -ne 0 ] ; then
									cancelrun "** 错误：容器创建失败，请翻译以上英文报错，Google/百度尝试解决问题！"
								fi
							}

							function input_container_emby_check() {
								if (whiptail --title "一键脚本 作者：kissyouhunter" --yesno "emby 容器名：$EMBY_CONTAINER_NAME                        \
								emby 配置文件路径：$CONFIG_PATH                                          \
								emby 电影文件路径：$MOVIES_PATH                                   \
								emby 电视剧文件路径：$TVSHOWS_PATH                                     \
								emby 面板端口：$EMBY_PORT                                     \
								emby https 端口：$EMBY_PORT1                                   \
								以上信息是否正确？"                                	       \
								14 45) then
									input_container_emby_build
									sleep 10
									input_container_emby_info
									docker ps -a
								else
									input_container_emby_input
									EMBY_PORT="8096"
									EMBY_PORT1="8920"
								fi
							}

							function input_container_emby_input() {
								function input_container_emby_name() {
									EMBY_NAME=$(whiptail --title "一键脚本 作者：kissyouhunter" --inputbox "请输入将要创建的容器名 [回车默认为：emby]" 10 55 3>&1 1>&2 2>&3)

									exitstatus=$?
									if [ $exitstatus = 0 ]; then
										if [ -z "$EMBY_NAME" ]; then
											EMBY_CONTAINER_NAME="emby"
										else
											EMBY_CONTAINER_NAME=$EMBY_NAME
										fi
									else
										exit 0
									fi
								}
								input_container_emby_name

								function input_container_emby_config() {
									EMBY_CONFIG=$(whiptail --title "一键脚本 作者：kissyouhunter" --inputbox "请输入 emby 配置文件保存的 \
									绝对路径（示例：/home/emby)， \
									回车默认为当前目录:" 10 45 3>&1 1>&2 2>&3)

									exitstatus=$?
									if [ $exitstatus = 0 ]; then
										if [ -z "$EMBY_CONFIG" ]; then
											EMBY_PATH=$(pwd)/emby
										else
											EMBY_PATH=$EMBY_CONFIG
										fi
									else
										exit 0
									fi
									CONFIG_PATH=$EMBY_PATH
								}
								input_container_emby_config

								function input_container_emby_movies_config() {
									MOVIES_CONFIG=$(whiptail --title "一键脚本 作者：kissyouhunter" --inputbox "请输入电影文件保存的绝对路径（示例：/home/movies)，回车默认为当前目录:" 10 55 3>&1 1>&2 2>&3)

									exitstatus=$?
									if [ $exitstatus = 0 ]; then
										if [ -z "$MOVIES_CONFIG" ]; then
											MOVIES_PATH=$(pwd)/movies
										else
											MOVIES_PATH=$MOVIES_CONFIG
										fi
									else
										exit 0
									fi
								}
								input_container_emby_movies_config

								function input_container_emby_tvshows_config() {
									TVSHOWS_CONFIG=$(whiptail --title "一键脚本 作者：kissyouhunter" --inputbox "请输入的电视剧文件保存的绝对路径 \
									（示例：/home/tvshows)，回车默认为当前目录:" 10 55 3>&1 1>&2 2>&3)

									exitstatus=$?
									if [ $exitstatus = 0 ]; then
										if [ -z "$TVSHOWS_CONFIG" ]; then
											TVSHOWS_PATH=$(pwd)/tvshows
										else
											TVSHOWS_PATH=$TVSHOWS_CONFIG
										fi
									else
										exit 0
									fi
								}
								input_container_emby_tvshows_config

								function input_container_emby_webui_config() {
									EMBY_WEBUI_CONFIG=$(whiptail --title "一键脚本 作者：kissyouhunter" --inputbox "请输入 emby 面板端口 [默认 8096]" 10 55 3>&1 1>&2 2>&3)

									exitstatus=$?
									if [ $exitstatus = 0 ]; then
										if [ -z "$EMBY_WEBUI_CONFIG" ]; then
											EMBY_PORT="8096"
										else
											EMBY_PORT=$EMBY_WEBUI_CONFIG
										fi
									else
										exit 0
									fi									
								}
								input_container_emby_webui_config

								function input_container_emby_https_config() {
									EMBY_HTTPS_CONFIG=$(whiptail --title "一键脚本 作者：kissyouhunter" --inputbox "请输入 emby 的 https 端口 [默认 8920]" 10 55 3>&1 1>&2 2>&3)

									exitstatus=$?
									if [ $exitstatus = 0 ]; then
										if [ -z "$EMBY_HTTPS_CONFIG" ]; then
											EMBY_PORT1="8920"
										else
											EMBY_PORT1=$EMBY_HTTPS_CONFIG
										fi
									else
										exit 0
									fi									
								}
								input_container_emby_https_config
								input_container_emby_check
							}
							input_container_emby_input
							;;
						2 )
							function input_container_jellyfin_info() {
								whiptail --title "一键脚本 作者：kissyouhunter" --msgbox "访问方式为宿主机 ip:$JELLYFIN_PORT \
								执行命令 chmod 777 /dev/dri/* 才能读取到显卡 \
								jellyfin 安装完成，点击 ok 退出脚本 " 10 50
							}

							function input_container_jellyfin_build() {
								TIME y " >>>>>>>>>>>配置完成，开始安装 jellyfin"
								log "1.开始创建配置文件目录"
								PATH_LIST=($CONFIG_PATH $MOVIES_PATH $TVSHOWS_PATH)
								for i in ${PATH_LIST[@]}; do
									mkdir -p $i
								done

								log "2.开始创建容器并执行"
	     							if [ -d "/dev/dri" ]; then
          								docker run -dit \
              								--name $JELLYFIN_CONTAINER_NAME \
              								--hostname $JELLYFIN_CONTAINER_NAME \
              								--restart always \
              								-v $CONFIG_PATH:/config \
              								-v $MOVIES_PATH:/mnt/movies \
              								-v $TVSHOWS_PATH:/mnt/tvshows \
              								-p $JELLYFIN_PORT:8096 -p $JELLYFIN_PORT1:8920 \
              								-e TZ=Asia/Shanghai \
              								--device /dev/dri:/dev/dri \
              								-e UMASK_SET=022 \
              								-e UID=0 \
              								-e GID=0 \
              								-e GIDLIST=0 \
              								$JELLYFIN_DOCKER_IMG_NAME:$TAG
      								else
          								docker run -dit \
              								--name $JELLYFIN_CONTAINER_NAME \
              								--hostname $JELLYFIN_CONTAINER_NAME \
              								--restart always \
              								-v $CONFIG_PATH:/config \
              								-v $MOVIES_PATH:/mnt/movies \
              								-v $TVSHOWS_PATH:/mnt/tvshows \
              								-p $JELLYFIN_PORT:8096 -p $JELLYFIN_PORT1:8920 \
              								-e TZ=Asia/Shanghai \
              								-e UMASK_SET=022 \
              								-e UID=0 \
              								-e GID=0 \
              								-e GIDLIST=0 \
				              				$JELLYFIN_DOCKER_IMG_NAME:$TAG
								    fi
								if [ $? -ne 0 ] ; then
									cancelrun "** 错误：容器创建失败，请翻译以上英文报错，Google/百度尝试解决问题！"
								fi
							}

							function input_container_jellyfin_check() {
								if (whiptail --title "一键脚本 作者：kissyouhunter" --yesno "jellyfin 容器名：$JELLYFIN_CONTAINER_NAME                           \
								jellyfin 配置文件路径：$CONFIG_PATH                               \
								jellyfin 电影文件路径：$MOVIES_PATH                                   \
								jellyfin 电视剧文件路径：$TVSHOWS_PATH                             \
								jellyfin 面板端口：$JELLYFIN_PORT                                  \
								jellyfin https端口：$JELLYFIN_PORT1                                   \
								以上信息是否正确？"                                                  \
								14 50) then
									input_container_jellyfin_build
									sleep 10
									input_container_jellyfin_info
									docker ps -a
								else
									input_container_jellyfin_input
									EMBY_PORT="8096"
									EMBY_PORT1="8920"
								fi
							}

							function input_container_jellyfin_input() {
								function input_container_jellyfin_name() {
									JELLYFIN_NAME=$(whiptail --title "一键脚本 作者：kissyouhunter" --inputbox "请输入将要创建的容器名 [回车默认为：jellyfin]" 10 55 3>&1 1>&2 2>&3)

									exitstatus=$?
									if [ $exitstatus = 0 ]; then
										if [ -z "$JELLYFIN_NAME" ]; then
											JELLYFIN_CONTAINER_NAME="emby"
										else
											JELLYFIN_CONTAINER_NAME=$JELLYFIN_NAME
										fi
									else
										exit 0
									fi
								}
								input_container_jellyfin_name

								function input_container_jellyfin_config() {
									JELLYFIN_CONFIG=$(whiptail --title "一键脚本 作者：kissyouhunter" --inputbox "请输入 jellyfin 配置文件保存的绝对路径 \
									（示例：/home/jellyfin)， \
									回车默认为当前目录:" 10 50 3>&1 1>&2 2>&3)

									exitstatus=$?
									if [ $exitstatus = 0 ]; then
										if [ -z "$JELLYFIN_CONFIG" ]; then
											JELLYFIN_PATH=$(pwd)/jellyfin
										else
											JELLYFIN_PATH=$JELLYFIN_CONFIG
										fi
									else
										exit 0
									fi
									CONFIG_PATH=$JELLYFIN_PATH
								}
								input_container_jellyfin_config

								function input_container_jellyfin_movies_config() {
									MOVIES_CONFIG=$(whiptail --title "一键脚本 作者：kissyouhunter" --inputbox "请输入电影文件保存的绝对路径（示例：/home/movies)，回车默认为当前目录:" 10 55 3>&1 1>&2 2>&3)

									exitstatus=$?
									if [ $exitstatus = 0 ]; then
										if [ -z "$MOVIES_CONFIG" ]; then
											MOVIES_PATH=$(pwd)/movies
										else
											MOVIES_PATH=$MOVIES_CONFIG
										fi
									else
										exit 0
									fi
								}
								input_container_jellyfin_movies_config

								function input_container_jellyfin_tvshows_config() {
									TVSHOWS_CONFIG=$(whiptail --title "一键脚本 作者：kissyouhunter" --inputbox "请输入电视剧文件保存的绝对路径 \
									（示例：/home/tvshows)，回车默认为当前目录:" 10 55 3>&1 1>&2 2>&3)

									exitstatus=$?
									if [ $exitstatus = 0 ]; then
										if [ -z "$TVSHOWS_CONFIG" ]; then
											TVSHOWS_PATH=$(pwd)/tvshows
										else
											TVSHOWS_PATH=$TVSHOWS_CONFIG
										fi
									else
										exit 0
									fi
								}
								input_container_jellyfin_tvshows_config

								function input_container_jellyfin_webui_config() {
									JELLYFIN_WEBUI_CONFIG=$(whiptail --title "一键脚本 作者：kissyouhunter" --inputbox "请输入 jellyfin 面板端口 [默认 8096]" 10 55 3>&1 1>&2 2>&3)

									exitstatus=$?
									if [ $exitstatus = 0 ]; then
										if [ -z "$JELLYFIN_WEBUI_CONFIG" ]; then
											JELLYFIN_PORT="8096"
										else
											JELLYFIN_PORT=$JELLYFIN_WEBUI_CONFIG
										fi
									else
										exit 0
									fi
								}
								input_container_jellyfin_webui_config

								function input_container_jellyfin_https_config() {
									JELLYFIN_HTTPS_CONFIG=$(whiptail --title "一键脚本 作者：kissyouhunter" --inputbox "请输入 jellyfin 的 https 端口 [默认 8920]" 10 55 3>&1 1>&2 2>&3)
									
									exitstatus=$?
									if [ $exitstatus = 0 ]; then
										if [ -z "$JELLYFIN_HTTPS_CONFIG" ]; then
											JELLYFIN_PORT1="8920"
										else
											JELLYFIN_PORT1=$JELLYFIN_HTTPS_CONFIG
										fi
									else
										exit 0
									fi
								}
								input_container_jellyfin_https_config
								input_container_jellyfin_check
							}
							input_container_jellyfin_input
							;;
						0 )
							main
							;;
					esac
				else
					exit 0
				fi
			}
			submenu5
			;;
		6 )
			#安装qbittorrent,aria2,ari2-pro
            clear
			function submenu6() {
				SUBMENU5=$(whiptail --title "一键脚本 作者：kissyouhunter" --menu "下载工具" 15 40 4 \
				"1" "安装 qbittorrent 增强版" \
				"2" "安装 aria2" \
				"3" "安装 aria2-pro" \
				"0" "返回上级菜单" \
				3>&1 1>&2 2>&3)

				exitstatus=$?
				if [ $exitstatus = 0 ]; then
					case "$SUBMENU5" in
						1 )
							function input_container_qb_info() {
								whiptail --title "一键脚本 作者：kissyouhunter" --msgbox "访问方式为宿主机 ip:$QB_PORT                        \
								默认用户名 admin，默认密码 adminadmin \
								qbittorrent 安装完成，点击 ok 退出脚本 " 10 50
							}

							function input_container_qb_build() {
								TIME y " >>>>>>>>>>>配置完成，开始安装 qbittorrent"
								log "1.开始创建配置文件目录"
								PATH_LIST=($QB_PATH $QB_DOWNLOAD_PATH)
								for i in ${PATH_LIST[@]}; do
									mkdir -p $i
								done

								log "2.开始创建容器并执行"
								docker run -dit \
      								-v $QB_PATH:/config \
      								-v $QB_DOWNLOAD_PATH:/Downloads \
     								-e QB_WEBUI_PORT="$QB_PORT"  \
     							    -p 6881:6881 -p 6881:6881/udp -p "$QB_PORT":8989 \
     								-e QB_EE_BIN=true \
     								-e UID=0  \
     								-e GID=0  \
     								-e UMASK=022  \
     								--name $QB_CONTAINER_NAME \
     								--hostname $QB_CONTAINER_NAME \
     								--restart always \
    							    $QB_DOCKER_IMG_NAME:$QB_TAG
								if [ $? -ne 0 ] ; then
									cancelrun "** 错误：容器创建失败，请翻译以上英文报错，Google/百度尝试解决问题！"
								fi
							}

							function input_container_qb_check() {
								if (whiptail --title "一键脚本 作者：kissyouhunter" --yesno "qbittorrent 容器名：$QB_CONTAINER_NAME                                   \
								qbittorrent 配置文件路径：$QB_PATH                                        \
								qbittorrent 下载文件路径：$QB_DOWNLOAD_PATH                                    \
								qbittorrent 面板端口：$QB_PORT                                                    \
								以上信息是否正确？"                                                 \
								12 50) then
									input_container_qb_build
									sleep 10
									input_container_qb_info
									docker ps -a
								else
									input_container_qb_input
									QB_PORT="8989"
								fi
							}

							function input_container_qb_input() {
								function input_container_qb_name() {
									QB_NAME=$(whiptail --title "一键脚本 作者：kissyouhunter" --inputbox "请输入将要创建的容器名[回车默认为：qbittorrent]" 10 55 3>&1 1>&2 2>&3)

									exitstatus=$?
									if [ $exitstatus = 0 ]; then
										if [ -z "$QB_NAME" ]; then
											QB_CONTAINER_NAME="qbittorrent"
										else
											QB_CONTAINER_NAME=$QB_NAME
										fi
									else
										exit 0
									fi
								}
								input_container_qb_name

								function input_container_qb_config() {
									QB_CONFIG=$(whiptail --title "一键脚本 作者：kissyouhunter" --inputbox "请输入 qbittorrent 增强版配置文件保存的绝对路径 \
									（示例：/home/qbittorrent)，                         \
									回车默认为当前目录:" 10 55 3>&1 1>&2 2>&3)

									exitstatus=$?
									if [ $exitstatus = 0 ]; then
										if [ -z "$QB_CONFIG" ]; then
											QB_PATH=$(pwd)/qbittorrent
										else
											QB_PATH=$QB_CONFIG
										fi
									else
										exit 0
									fi
								}
								input_container_qb_config

								function input_container_qb_download_config() {
									QB_DOWNLOAD_CONFIG=$(whiptail --title "一键脚本 作者：kissyouhunter" --inputbox "请输入下载文件保存的绝对路径 \
									（示例：/home/downloads)，                               \
									回车默认为当前目录:" 10 45 3>&1 1>&2 2>&3)

									exitstatus=$?
									if [ $exitstatus = 0 ]; then
										if [ -z "$QB_DOWNLOAD_CONFIG" ]; then
											QB_DOWNLOAD_PATH=$(pwd)/downloads
										else
											QB_DOWNLOAD_PATH=$QB_DOWNLOAD_CONFIG
										fi
									else
										exit 0
									fi
								}
								input_container_qb_download_config

								function input_container_qb_web_config() {
									QB_WEB_CONFIG=$(whiptail --title "一键脚本 作者：kissyouhunter" --inputbox "请输入 qbittorrent 增强版的面板端口 [默认 8989]" 10 55 3>&1 1>&2 2>&3)

									exitstatus=$?
									if [ $exitstatus = 0 ]; then
										if [ -z "$QB_WEB_CONFIG" ]; then
											QB_PORT="8989"
										else
											QB_PORT=$QB_WEB_CONFIG
										fi
									else
										exit 0
									fi									
								}
								input_container_qb_web_config
								input_container_qb_check
							}
							input_container_qb_input
							;;
						2 )
							function input_container_aria2_info() {
								whiptail --title "一键脚本 作者：kissyouhunter" --msgbox "访问方式为宿主机 ip:$ARIA2_PORT                                          \
								Aria密钥设置在面板如下位置                                                          \
								AriaNg 设置 > RPC(IP:6800) > Aria2 RPC 密钥                                                            \
								设置的密钥为 $ARIA2_TOKEN                                                \
								aria2 安装完成，点击 ok 退出脚本 " 13 50
							}

							function input_container_aria2_build() {
								TIME y " >>>>>>>>>>>配置完成，开始安装 aria2"
								log "1.开始创建配置文件目录"
								PATH_LIST=($ARIA2_PATH $ARIA2_DOWNLOAD_PATH)
								for i in ${PATH_LIST[@]}; do
									mkdir -p $i
								done

								log "2.开始创建容器并执行"
								docker run -dit \
      								-v $ARIA2_PATH:/config \
      								-v $ARIA2_DOWNLOAD_PATH:/downloads \
      								-e WEBUIPORT="$ARIA2_PORT" \
      								-p 32516:32516 -p 32516:32516/udp -p 6800:6800 -p "$ARIA2_PORT":8080 \
      								-e TZ=Asia/Shanghai \
      								-e SECRET=$ARIA2_TOKEN \
      								-e UID=0  \
      								-e GID=0  \
      								-e CACHE=512M \
      								-e PORT=6800 \
      								-e BTPORT=32516 \
      								-e UT=true \
      								-e RUT=true \
      								-e FA=falloc \
      								-e QUIET=true \
      								-e SMD=false \
      								--name $ARIA2_CONTAINER_NAME \
      								--hostname $ARIA2_CONTAINER_NAME \
      								--restart always \
      								$ARIA2_DOCKER_IMG_NAME:$ARIA2_TAG
								
								if [ $? -ne 0 ] ; then
									cancelrun "** 错误：容器创建失败，请翻译以上英文报错，Google/百度尝试解决问题！"
								fi
							}

							function input_container_aria2_check() {
								if (whiptail --title "一键脚本 作者：kissyouhunter" --yesno "aria2 容器名：$ARIA2_CONTAINER_NAME                                  \
								aria2 配置文件路径：$ARIA2_PATH                                           \
								aria2 下载文件路径：$ARIA2_DOWNLOAD_PATH                                        \
								aria2 面板端口：$ARIA2_PORT                                                   \
								aria2 密钥：$ARIA2_TOKEN                                                   \
								以上信息是否正确？"                                                       \
								14 50) then
									input_container_aria2_build
									sleep 10
									input_container_aria2_info
									docker ps -a
								else
									input_container_aria2_input
									ARIA2_PORT="8080"
								fi
							}

							function input_container_aria2_input() {
								function input_container_aria2_name() {
									ARIA2_NAME=$(whiptail --title "一键脚本 作者：kissyouhunter" --inputbox "请输入将要创建的容器名 [回车默认为：aria2]" 10 55 3>&1 1>&2 2>&3)

									exitstatus=$?
									if [ $exitstatus = 0 ]; then
										if [ -z "$ARIA2_NAME" ]; then
											ARIA2_CONTAINER_NAME="aria2"
										else
											ARIA2_CONTAINER_NAME=$ARIA2_NAME
										fi
									else
										exit 0
									fi
								}
								input_container_aria2_name

								function input_container_aria2_config() {
									ARIA2_CONFIG=$(whiptail --title "一键脚本 作者：kissyouhunter" --inputbox "请输入 aria2 配置文件保存的绝对路径 \
									（示例：/home/aria2)，回车默认为当前目录:" 10 55 3>&1 1>&2 2>&3)

									exitstatus=$?
									if [ $exitstatus = 0 ]; then
										if [ -z "$ARIA2_CONFIG" ]; then
											ARIA2_PATH=$(pwd)/aria2
										else
											ARIA2_PATH=$ARIA2_CONFIG
										fi
									else
										exit 0
									fi
								}
								input_container_aria2_config

								function input_container_aria2_download_config() {
									ARIA2_DOWNLOAD_CONFIG=$(whiptail --title "一键脚本 作者：kissyouhunter" --inputbox "请输入下载文件保存的绝对路径 \
									（示例：/home/downloads)，回车默认为当前目录:" 10 55 3>&1 1>&2 2>&3)

									exitstatus=$?
									if [ $exitstatus = 0 ]; then
										if [ -z "$ARIA2_DOWNLOAD_CONFIG" ]; then
											ARIA2_DOWNLOAD_PATH=$(pwd)/downloads
										else
											ARIA2_DOWNLOAD_PATH=$ARIA2_DOWNLOAD_CONFIG
										fi
									else
										exit 0
									fi
								}
								input_container_aria2_download_config

								function input_container_aria2_webui_config() {
									ARIA2_WEBUI_CONFIG=$(whiptail --title "一键脚本 作者：kissyouhunter" --inputbox "请输入 aria2 面板端口 [默认 8080]" 10 55 3>&1 1>&2 2>&3)

									exitstatus=$?
									if [ $exitstatus = 0 ]; then
										if [ -z "$ARIA2_WEBUI_CONFIG" ]; then
											ARIA2_PORT="8080"
										else
											ARIA2_PORT=$ARIA2_WEBUI_CONFIG
										fi
									else
										exit 0
									fi
								}
								input_container_aria2_webui_config

								function input_container_aria2_token_config() {
									ARIA2_TOKEN_CONFIG=$(whiptail --title "一键脚本 作者：kissyouhunter" --inputbox "请输入 aria2 的密钥 [默认 aria2]" 10 55 3>&1 1>&2 2>&3)

									exitstatus=$?
									if [ $exitstatus = 0 ]; then
										if [ -z "$ARIA2_TOKEN_CONFIG" ]; then
											ARIA2_TOKEN="aria2"
										else
											ARIA2_TOKEN=$ARIA2_TOKEN_CONFIG
										fi
									else
										exit 0
									fi
								}
								input_container_aria2_token_config
								input_container_aria2_check
							}
							input_container_aria2_input
							;;
						3 )
							function input_container_aria2_pro_info() {
								whiptail --title "一键脚本 作者：kissyouhunter" --msgbox "访问方式为宿主机 ip:$ARIA2_PRO_PORT                                          \
								Aria密钥设置在面板如下位置                                                          \
								AriaNg 设置 > RPC(IP:6800) > Aria2 RPC 密钥                                                            \
								设置的密钥为 $ARIA2_PRO_TOKEN                                                \
								aria2 安装完成，点击 ok 退出脚本 " 13 50
							}

							function input_container_aria2_pro_build() {
								TIME y " >>>>>>>>>>>配置完成，开始安装 aria2 pro"
								log "1.开始创建配置文件目录"
								PATH_LIST=($ARIA2_PRO_PATH $ARIA2_PRO_DOWNLOAD_PATH)
								for i in ${PATH_LIST[@]}; do
									mkdir -p $i
								done

								log "2.开始创建容器并执行"
								docker run -dit \
      								-v $ARIA2_PRO_PATH:/config \
      								-v $ARIA2_PRO_DOWNLOAD_PATH:/downloads \
      								-p 6800:6800 -p 6888:6888 -p 6888:6888/udp \
      								-e TZ=Asia/Shanghai \
      								-e SECRET=$ARIA2_PRO_TOKEN \
      								-e RPC_PORT=6800 \
      								-e LISTEN_PORT=6888 \
      								-e UID=0  \
      								-e GID=0  \
      								-e UMASK_SET=022 \
      								--log-opt max-size=1m \
      								--name $ARIA2_PRO_CONTAINER_NAME \
      								--hostname $ARIA2_PRO_CONTAINER_NAME \
      								--restart always \
      								$ARIA2_PRO_DOCKER_IMG_NAME:$TAG
								
								docker run -d \
									--name $ARIA2_PRO_WEBUI_NAME \
									--log-opt max-size=1m \
									--restart unless-stopped \
									-p $ARIA2_PRO_PORT:6880 \
									$ARIA2_PRO_WEBUI_DOCKER_IMG_NAME:$TAG
								
								if [ $? -ne 0 ] ; then
									cancelrun "** 错误：容器创建失败，请翻译以上英文报错，Google/百度尝试解决问题！"
								fi
							}

							function input_container_aria2_pro_check() {
								if (whiptail --title "一键脚本 作者：kissyouhunter" --yesno "aria2-pro 容器名：$ARIA2_PRO_CONTAINER_NAME                                  \
								aria2_pro 面板名：$ARIA2_PRO_WEBUI_NAME                                                          \
								aria2-pro 配置文件路径：$ARIA2_PRO_PATH                                           \
								aria2-pro 下载文件路径：$ARIA2_PRO_DOWNLOAD_PATH                                        \
								aria2-pro 面板端口：$ARIA2_PRO_PORT                                                   \
								aria2-pro 密钥：$ARIA2_PRO_TOKEN                                                   \
								以上信息是否正确？"                                                       \
								14 50) then
									input_container_aria2_pro_build
									sleep 10
									input_container_aria2_pro_info
									docker ps -a
								else
									input_container_aria2_pro_input
									ARIA2_PRO_PORT="6880"
								fi
							}

							function input_container_aria2_pro_input() {
								function input_container_aria2_pro_name() {
									ARIA2_PRO_NAME=$(whiptail --title "一键脚本 作者：kissyouhunter" --inputbox "请输入将要创建的容器名 [回车默认为：aria2-pro]" 10 55 3>&1 1>&2 2>&3)

									exitstatus=$?
									if [ $exitstatus = 0 ]; then
										if [ -z "$ARIA2_PRO_NAME" ]; then
											ARIA2_PRO_CONTAINER_NAME="aria2-pro"
										else
											ARIA2_PRO_CONTAINER_NAME=$ARIA2_PRO_NAME
										fi
									else
										exit 0
									fi
								}
								input_container_aria2_pro_name

								function input_container_ariang_name() {
									ARIANG_NAME=$(whiptail --title "一键脚本 作者：kissyouhunter" --inputbox "请输入将要创建的面板容器名 [回车默认为：ariang]" 10 55 3>&1 1>&2 2>&3)

									exitstatus=$?
									if [ $exitstatus = 0 ]; then
										if [ -z "$ARIANG_NAME" ]; then
											ARIA2_PRO_WEBUI_NAME="ariang"
										else
											ARIA2_PRO_WEBUI_NAME=$ARIANG_NAME
										fi
									else
										exit 0
									fi
								}
								input_container_ariang_name

								function input_container_aria2_pro_config() {
									ARIA2_PRO_CONFIG=$(whiptail --title "一键脚本 作者：kissyouhunter" --inputbox "请输入 aria2-pro 配置文件保存的绝对路径 \
									（示例：/home/aria2-pro)，回车默认为当前目录:" 10 55 3>&1 1>&2 2>&3)

									exitstatus=$?
									if [ $exitstatus = 0 ]; then
										if [ -z "$ARIA2_PRO_CONFIG" ]; then
											ARIA2_PRO_PATH=$(pwd)/aria2-pro
										else
											ARIA2_PRO_PATH=$ARIA2_PRO_CONFIG
										fi
									else
										exit 0
									fi
								}
								input_container_aria2_pro_config

								function input_container_aria2_pro_download_config() {
									ARIA2_PRO_DOWNLOAD_CONFIG=$(whiptail --title "一键脚本 作者：kissyouhunter" --inputbox "请输入下载文件保存的绝对路径 \
									（示例：/home/downloads)，回车默认为当前目录:" 10 55 3>&1 1>&2 2>&3)

									exitstatus=$?
									if [ $exitstatus = 0 ]; then
										if [ -z "$ARIA2_PRO_DOWNLOAD_CONFIG" ]; then
											ARIA2_PRO_DOWNLOAD_PATH=$(pwd)/downloads
										else
											ARIA2_PRO_DOWNLOAD_PATH=$ARIA2_PRO_DOWNLOAD_CONFIG
										fi
									else
										exit 0
									fi
								}
								input_container_aria2_pro_download_config

								function input_container_aria2_pro_webui_config() {
									ARIA2_PRO_WEBUI_CONFIG=$(whiptail --title "一键脚本 作者：kissyouhunter" --inputbox "请输入 aria2-pro 面板端口 [默认 6880]" 10 55 3>&1 1>&2 2>&3)

									exitstatus=$?
									if [ $exitstatus = 0 ]; then
										if [ -z "$ARIA2_PRO_WEBUI_CONFIG" ]; then
											ARIA2_PRO_PORT="6880"
										else
											ARIA2_PRO_PORT=$ARIA2_PRO_WEBUI_CONFIG
										fi
									else
										exit 0
									fi
								}
								input_container_aria2_pro_webui_config

								function input_container_aria2_pro_token_config() {
									ARIA2_PRO_TOKEN_CONFIG=$(whiptail --title "一键脚本 作者：kissyouhunter" --inputbox "请输入 aria2-pro 的密钥 [默认 aria2]" 10 55 3>&1 1>&2 2>&3)

									exitstatus=$?
									if [ $exitstatus = 0 ]; then
										if [ -z "$ARIA2_PRO_TOKEN_CONFIG" ]; then
											ARIA2_PRO_TOKEN="aria2"
										else
											ARIA2_PRO_TOKEN=$ARIA2_PRO_TOKEN_CONFIG
										fi
									else
										exit 0
									fi
								}
								input_container_aria2_pro_token_config
								input_container_aria2_pro_check
							}
							input_container_aria2_pro_input
							;;
						0 )
							main
							;;
					esac
				else
					exit 0
				fi
			}
			submenu6
			;;
		7 )
			#安装telethon
            clear
			function submenu7() {
				SUBMENU5=$(whiptail --title "一键脚本 作者：kissyouhunter" --menu "telethon" 15 50 3 \
				"1" "linxu系统、X86 的 openwrt、群辉等请选择 1" \
				"2" "N1 的 EMMC 上运行的 openwrt 请选择 2" \
				"0" "返回上级菜单" \
				3>&1 1>&2 2>&3)

				exitstatus=$?
				if [ $exitstatus = 0 ]; then
					case "$SUBMENU5" in
						1 )
							function input_container_telethon1_info() {
								whiptail --title "一键脚本 作者：kissyouhunter" --msgbox "使用教程https://hub.docker.com/r/kissyouhunter/telethon                        \
								telethon 安装完成，点击 ok 退出脚本 " 10 60
							}

							function input_container_telethon1_build() {
								TIME y " >>>>>>>>>>>配置完成，开始安装 telethon"
								log "1.开始创建配置文件目录"
								PATH_LIST=($TELETHON1_PATH)
								for i in ${PATH_LIST[@]}; do
									mkdir -p $i
								done

								log "2.开始创建容器并执行"
								docker run -dit \
      								-v $TELETHON1_PATH:/telethon \
      								--name $TELETHON1_CONTAINER_NAME \
									--hostname $TELETHON1_CONTAINER_NAME \
									--restart always \
									--net host \
									$TELETHON_DOCKER_IMG_NAME:$TAG

								if [ $? -ne 0 ] ; then
									cancelrun "** 错误：容器创建失败，请翻译以上英文报错，Google/百度尝试解决问题！"
								fi
							}

							function input_container_telethon1_check() {
								if (whiptail --title "一键脚本 作者：kissyouhunter" --yesno "telethon 容器名：$TELETHON1_CONTAINER_NAME                                   \
								telethon 配置文件路径：$TELETHON1_PATH                                        \
								以上信息是否正确？"                                                 \
								12 50) then
									input_container_telethon1_build
									sleep 10
									input_container_telethon1_info
									docker ps -a
								else
									input_container_telethon1_input
								fi
							}

							function input_container_telethon1_input() {
								function input_container_telethon1_name() {
									TELETHON1_NAME=$(whiptail --title "一键脚本 作者：kissyouhunter" --inputbox "请输入将要创建的容器名 [回车默认为：telethon]" 10 55 3>&1 1>&2 2>&3)

									exitstatus=$?
									if [ $exitstatus = 0 ]; then
										if [ -z "$TELETHON1_NAME" ]; then
											TELETHON1_CONTAINER_NAME="telethon"
										else
											TELETHON1_CONTAINER_NAME=$TELETHON1_NAME
										fi
									else
										exit 0
									fi
								}
								input_container_telethon1_name

								function input_container_telethon1_config() {
									TELETHON1_CONFIG=$(whiptail --title "一键脚本 作者：kissyouhunter" --inputbox "请输入 telethon 配置文件保存的绝对路径 \
									（示例：/home/telethon)，                                    \
									回车默认为当前目录:" 10 55 3>&1 1>&2 2>&3)

									exitstatus=$?
									if [ $exitstatus = 0 ]; then
										if [ -z "$TELETHON1_CONFIG" ]; then
											TELETHON1_PATH=$(pwd)/telethon
										else
											TELETHON1_PATH=$TELETHON1_CONFIG
										fi
									else
										exit 0
									fi
								}
								input_container_telethon1_config
								input_container_telethon1_check
							}
							input_container_telethon1_input
							;;
						2 )
							function input_container_telethon2_info() {
								whiptail --title "一键脚本 作者：kissyouhunter" --msgbox "使用教程https://hub.docker.com/r/kissyouhunter/telethon                        \
								telethon 安装完成，点击 ok 退出脚本 " 10 60
							}

							function input_container_telethon2_build() {
								TIME y " >>>>>>>>>>>配置完成，开始安装 telethon 到 N1 的 /mnt/mmcblk2p4/"
								log "1.开始创建配置文件目录"
								PATH_LIST=($TELETHON2_PATH)
								for i in ${PATH_LIST[@]}; do
									mkdir -p $i
								done

								log "2.开始创建容器并执行"
								docker run -dit \
      								-v $TELETHON2_PATH:/telethon \
      								--name $TELETHON2_CONTAINER_NAME \
									--hostname $TELETHON2_CONTAINER_NAME \
									--restart always \
									--net host \
									$TELETHON_DOCKER_IMG_NAME:$TAG

								if [ $? -ne 0 ] ; then
									cancelrun "** 错误：容器创建失败，请翻译以上英文报错，Google/百度尝试解决问题！"
								fi
							}

							function input_container_telethon2_check() {
								if (whiptail --title "一键脚本 作者：kissyouhunter" --yesno "telethon 容器名：$TELETHON2_CONTAINER_NAME                                   \
								telethon 配置文件路径：$TELETHON2_PATH                                        \
								以上信息是否正确？"                                                 \
								12 50) then
									input_container_telethon2_build
									sleep 10
									input_container_telethon2_info
									docker ps -a
								else
									input_container_telethon2_input
								fi
							}

							function input_container_telethon2_input() {
								function input_container_telethon2_name() {
									TELETHON2_NAME=$(whiptail --title "一键脚本 作者：kissyouhunter" --inputbox "请输入将要创建的容器名 [回车默认为：telethon]" 10 55 3>&1 1>&2 2>&3)

									exitstatus=$?
									if [ $exitstatus = 0 ]; then
										if [ -z "$TELETHON2_NAME" ]; then
											TELETHON2_CONTAINER_NAME="telethon"
										else
											TELETHON2_CONTAINER_NAME=$TELETHON2_NAME
										fi
									else
										exit 0
									fi
								}
								input_container_telethon2_name

								function input_container_telethon2_config() {
									TELETHON2_CONFIG=$(whiptail --title "一键脚本 作者：kissyouhunter" --inputbox "请输入 telethon 配置文件夹名（示例：/telethon)，           \
									回车默认为 /mnt/mmcblk2p4//telethon:" 10 55 3>&1 1>&2 2>&3)

									exitstatus=$?
									if [ $exitstatus = 0 ]; then
										if [ -z "$TELETHON2_CONFIG" ]; then
											TELETHON2_PATH=/mnt/mmcblk2p4/telethon
										else
											TELETHON2_PATH=/mnt/mmcblk2p4/$TELETHON2_CONFIG
										fi
									else
										exit 0
									fi
								}
								input_container_telethon2_config
								input_container_telethon2_check
							}
							input_container_telethon2_input
							;;
						0 )
							main
							;;
					esac
				else
					exit 0
				fi
			}
			submenu7
			;;
		8 )
			#安装adguardhome
            clear
			function submenu8() {
				SUBMENU5=$(whiptail --title "一键脚本 作者：kissyouhunter" --menu "telethon" 15 65 4 \
				"1" "linxu系统、X86 的 openwrt、群辉等（docker 版）请选择 1" \
				"2" "N1 的 EMMC 上运行的 openwrt（docker 版）请选择 2" \
				"3" "inxu系统（非docker版，openwrt不可运行）" \
				"0" "返回上级菜单" \
				3>&1 1>&2 2>&3)

				exitstatus=$?
				if [ $exitstatus = 0 ]; then
					case "$SUBMENU5" in
						1 )
							function input_container_adg1_info() {
								whiptail --title "一键脚本 作者：kissyouhunter" --msgbox "首次启动请访问宿主机 IP:3000                               \
								adguardhome 安装完成，点击 ok 退出脚本 " 10 60
							}

							function input_container_adg1_build() {
								TIME y " >>>>>>>>>>>配置完成，开始安装 adguardhome（docker 版，x86 系统）"
								log "1.开始创建配置文件目录"
								PATH_LIST=($ADG1_WORK_PATH $ADG1_CONF_PATH)
								for i in ${PATH_LIST[@]}; do
									mkdir -p $i
								done

								log "2.开始创建容器并执行"
								docker run -dit \
      								-v $ADG1_WORK_PATH:/opt/adguardhome/work \
									-v $ADG1_CONF_PATH:/opt/adguardhome/conf \
      								--name $ADG1_CONTAINER_NAME \
									--hostname $ADG1_CONTAINER_NAME \
									--restart always \
									--net host \
									$ADG_DOCKER_IMG_NAME:$TAG

								if [ $? -ne 0 ] ; then
									cancelrun "** 错误：容器创建失败，请翻译以上英文报错，Google/百度尝试解决问题！"
								fi
							}

							function input_container_adg1_check() {
								if (whiptail --title "一键脚本 作者：kissyouhunter" --yesno "adguardhome 容器名：$ADG1_CONTAINER_NAME                                   \
								adguardhome 配置文件路径：$ADG1_PATH                                        \
								以上信息是否正确？"                                                 \
								12 60) then
									input_container_adg1_build
									sleep 10
									input_container_adg1_info
									docker ps -a
								else
									input_container_adg1_input
								fi
							}

							function input_container_adg1_input() {
								function input_container_adg1_name() {
									ADG1_NAME=$(whiptail --title "一键脚本 作者：kissyouhunter" --inputbox "请输入将要创建的容器名 [回车默认为：adguardhome]" 10 55 3>&1 1>&2 2>&3)

									exitstatus=$?
									if [ $exitstatus = 0 ]; then
										if [ -z "$ADG1_NAME" ]; then
											ADG1_CONTAINER_NAME="adguardhome"
										else
											ADG1_CONTAINER_NAME=$ADG1_NAME
										fi
									else
										exit 0
									fi
								}
								input_container_adg1_name

								function input_container_adg1_config() {
									ADG1_CONFIG=$(whiptail --title "一键脚本 作者：kissyouhunter" --inputbox "请输入 adguardhome 配置文件保存的绝对路径 \
									（示例：/home/adguardhome)，                                    \
									回车默认为当前目录:" 10 55 3>&1 1>&2 2>&3)

									exitstatus=$?
									if [ $exitstatus = 0 ]; then
										if [ -z "$ADG1_CONFIG" ]; then
											ADG1_PATH=$(pwd)/adguardhome
										else
											ADG1_PATH=$ADG1_CONFIG
										fi
										ADG1_WORK_PATH=$ADG1_PATH/work
										ADG1_CONF_PATH=$ADG1_PATH/conf
									else
										exit 0
									fi
								}
								input_container_adg1_config
								input_container_adg1_check
							}
							input_container_adg1_input
							;;
						2 )
							function input_container_telethon2_info() {
								whiptail --title "一键脚本 作者：kissyouhunter" --msgbox "使用教程https://hub.docker.com/r/kissyouhunter/telethon                        \
								telethon 安装完成，点击 ok 退出脚本 " 10 60
							}

							function input_container_telethon2_build() {
								TIME y " >>>>>>>>>>>配置完成，开始安装 telethon 到 N1 的 /mnt/mmcblk2p4/"
								log "1.开始创建配置文件目录"
								PATH_LIST=($TELETHON2_PATH)
								for i in ${PATH_LIST[@]}; do
									mkdir -p $i
								done

								log "2.开始创建容器并执行"
								docker run -dit \
      								-v $TELETHON2_PATH:/telethon \
      								--name $TELETHON2_CONTAINER_NAME \
									--hostname $TELETHON2_CONTAINER_NAME \
									--restart always \
									--net host \
									$TELETHON_DOCKER_IMG_NAME:$TAG

								if [ $? -ne 0 ] ; then
									cancelrun "** 错误：容器创建失败，请翻译以上英文报错，Google/百度尝试解决问题！"
								fi
							}

							function input_container_telethon2_check() {
								if (whiptail --title "一键脚本 作者：kissyouhunter" --yesno "telethon 容器名：$TELETHON2_CONTAINER_NAME                                   \
								telethon 配置文件路径：$TELETHON2_PATH                                        \
								以上信息是否正确？"                                                 \
								12 50) then
									input_container_telethon2_build
									sleep 10
									input_container_telethon2_info
									docker ps -a
								else
									input_container_telethon2_input
								fi
							}

							function input_container_telethon2_input() {
								function input_container_telethon2_name() {
									TELETHON2_NAME=$(whiptail --title "一键脚本 作者：kissyouhunter" --inputbox "请输入将要创建的容器名 [回车默认为：telethon]" 10 55 3>&1 1>&2 2>&3)

									exitstatus=$?
									if [ $exitstatus = 0 ]; then
										if [ -z "$TELETHON2_NAME" ]; then
											TELETHON2_CONTAINER_NAME="telethon"
										else
											TELETHON2_CONTAINER_NAME=$TELETHON2_NAME
										fi
									else
										exit 0
									fi
								}
								input_container_telethon2_name

								function input_container_telethon2_config() {
									TELETHON2_CONFIG=$(whiptail --title "一键脚本 作者：kissyouhunter" --inputbox "请输入 telethon 配置文件夹名（示例：/telethon)，           \
									回车默认为 /mnt/mmcblk2p4//telethon:" 10 55 3>&1 1>&2 2>&3)

									exitstatus=$?
									if [ $exitstatus = 0 ]; then
										if [ -z "$TELETHON2_CONFIG" ]; then
											TELETHON2_PATH=/mnt/mmcblk2p4/telethon
										else
											TELETHON2_PATH=/mnt/mmcblk2p4/$TELETHON2_CONFIG
										fi
									else
										exit 0
									fi
								}
								input_container_telethon2_config
								input_container_telethon2_check
							}
							input_container_telethon2_input
							;;
						0 )
							main
							;;
					esac
				else
					exit 0
				fi
			}
			submenu8
			;;
		exit | quit | q )
			exit
			::
		esac
	else
		exit 0
	fi
}
main
