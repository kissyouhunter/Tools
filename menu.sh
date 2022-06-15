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
	"1" "安装<docker>和<docker-compose>" \
	"2" "安装<青龙>到宿主机" \
	"3" "安装<elecv2p>到宿主机" \
	"4" "安装docker图形管理工具" \
	"5" "安装<emby>或<jellyfin>(打造自己的爱奇艺)" \
	"6" "安装下载工具" \
	"7" "<Telegram>定时发送信息工具" \
	"8" "<AdGuardHome>DNS解析+去广告" \
	"9" "x-ui" \
	"10" "<aaPanel>(宝塔国际版)" \
	"11" "<MaiARK>(对接青龙提交京东CK)" \
	3>&1 1>&2 2>&3)

	exitstatus=$?	
	if [ $exitstatus = 0 ]; then
    	case "$MENU" in
		1 )
			#安装docker和docker-compose
            clear
			function submenu1() {
				SUBMENU1=$(whiptail --title "一键脚本 作者：kissyouhunter" --menu "安装 <DOCKER & DOCKER-COMPOSE>" 15 63 4 \
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
									whiptail --title "一键脚本 作者：kissyouhunter" --msgbox "<docker>和<docker-compose>安装完成，点击 OK 返回" 10 55
									main
								elif [ ! "$(command -v docker)" ]; then
									whiptail --title "一键脚本 作者：kissyouhunter" --msgbox "<docker>和<docker-compose>安装失败了,点击 OK 返回" 10 55
									main
								elif [ "$(command -v docker)" ] && [ ! "$(command -v docker-compose)" ]; then
									whiptail --title "一键脚本 作者：kissyouhunter" --msgbox "<docker>安装完成，<docker-compose>安装失败了,点击 OK 返回" 10 65
									main
								fi
							fi
							;;
						2 )
							TIME y " >>>>>>>>>>>开始为X86 openwrt安装docker和docker-compose"
							mkdir -p /tmp/upload/ && cd /tmp/upload/
							curl -LO https://tt.kisssik.ga/d/aliyun/files/docker-2010.12-1_x86_64.zip
							unzip docker-2010.12-1_x86_64.zip && rm -f docker-2010.12-1_x86_64.zip
							cd /tmp/upload/docker-2010.12-1_x86_64 && opkg install *.ipk && cd .. && rm -rf docker-2010.12-1_x86_64/
							if [ "$(command -v docker)" ]; then
								whiptail --title "一键脚本 作者：kissyouhunter" --msgbox "<docker>和<docker-compose>安装完成，点击 OK 返回" 10 55
							else
								whiptail --title "一键脚本 作者：kissyouhunter" --msgbox "<docker>和<docker-compose>安装失败，点击 OK 返回" 10 55
							fi
							main
							;;
						3 )
						    TIME y " >>>>>>>>>>>开始为Arm64 openwrt安装docker和docker-compose"
							mkdir -p /tmp/upload/ && cd /tmp/upload/
							curl -LO https://tt.kisssik.ga/d/aliyun/files/docker-20.10.15-1_aarch64.zip
							unzip docker-20.10.15-1_aarch64.zip && rm -f docker-20.10.15-1_aarch64.zip
							cd /tmp/upload/docker-20.10.15-1_aarch64 && opkg install *.ipk
							cd /tmp/upload && rm -rf docker-20.10.15-1_aarch64/
							if [ "$(command -v docker)" ]; then
								whiptail --title "一键脚本 作者：kissyouhunter" --msgbox "<docker>和<docker-compose>安装完成，点击 OK 返回 \
								U盘上运行的OP，如果docker空间没有指定到 /mnt/sda4/docker ，请修改 \
								dockerman > 设置 > Docker 根目录 修改为 /mnt/sda4/docker" 10 70
							else
								whiptail --title "一键脚本 作者：kissyouhunter" --msgbox "<docker>和<docker-compose>安装失败，点击 OK 返回" 10 55
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
				SUBMENU2=$(whiptail --title "一键脚本 作者：kissyouhunter" --menu "安装 <青龙>" 15 52 3 \
				"1" "linxu系统、X86的openwrt、群辉等请选择 1" \
				"2" "N1的EMMC上运行的openwrt请选择 2" \
				"0" "返回上级菜单" \
				3>&1 1>&2 2>&3)

				exitstatus=$?
				if [ $exitstatus = 0 ]; then
					case "$SUBMENU2" in
						1 )
							function input_container_ql1_info() {
								whiptail --title "一键脚本 作者：kissyouhunter" --msgbox "访问方式为：宿主机ip:$QL_PORT \
								<青龙>安装完成，点击 ok 退出脚本 " 10 50
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
								if (whiptail --title "一键脚本 作者：kissyouhunter" --yesno "青龙容器名：$QL_CONTAINER_NAME \
								青龙配置文件路径：$QL_PATH \
								青龙网络类型：$NETWORK \
								青龙面板端口：$QL_PORT \
								青龙版本：$QL_TAG \
								以上信息是否正确？" \
								15 40) then
									input_container_ql1_docker
								else
									ql1_input
									QL_PORT="5700"
								fi
							}

							function input_container_ql1_version() {
								QL1_VERSION=$(whiptail --title "一键脚本 作者：kissyouhunter" --inputbox "目前提供的版本有如下： \
								2.10、2.10.6、2.10.7、2.10.8、2.10.9 \
								2.10.10、2.10.11、2.10.12、2.10.13 \
								2.11.0、2.11.1、2.11.2.2.11.3 \
								2.12.0、2.12.1、2.12.2 \
								2.13.0、2.13.1、2.13.2和最新 \
								请输入版本号[回车默认为：latest]" 15 55 3>&1 1>&2 2>&3)

								if [ -z "$QL1_VERSION" ]; then
									QL_TAG="latest"
								else
									QL_TAG=$QL1_VERSION
								fi
							}

							function ql1_input() {
								QL1_NAME=$(whiptail --title "一键脚本 作者：kissyouhunter" --inputbox "请输入将要创建的容器名[回车默认为：ql]" 10 55 3>&1 1>&2 2>&3)
								
								if [ -z "$QL1_NAME" ]; then
									QL_CONTAINER_NAME="ql"
								else
									QL_CONTAINER_NAME=$QL1_NAME
								fi

								QL1_CONFIG=$(whiptail --title "一键脚本 作者：kissyouhunter" --inputbox "请输入青龙配置文件保存的绝对路径 \
								（示例：/home/ql)，回车默认为当前目录:" 10 50 3>&1 1>&2 2>&3)

								if [ -z "$QL1_CONFIG" ]; then
									QL_PATH=$(pwd)/ql
								else
									QL_PATH=$QL1_CONFIG
								fi

								function input_container_ql1_network_config() {
									QL1_NETWORK=$(whiptail --title "一键脚本 作者：kissyouhunter" --menu "请选择网络模式" 15 50 2 \
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
								whiptail --title "一键脚本 作者：kissyouhunter" --msgbox "访问方式为：宿主机ip:$QL_PORT \
								<青龙>安装完成，点击 ok 退出脚本 " 10 50
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
								if (whiptail --title "一键脚本 作者：kissyouhunter" --yesno "青龙容器名：$QL_CONTAINER_NAME \
								青龙配置文件路径：$QL_PATH \
								青龙网络类型：$NETWORK \
								青龙面板端口：$QL_PORT \
								青龙版本：$QL_TAG \
								以上信息是否正确？" \
								15 40) then
									input_container_ql2_docker
								else
									ql2_input
									QL_PORT="5700"
								fi
							}

							function input_container_ql2_version() {
								QL2_VERSION=$(whiptail --title "一键脚本 作者：kissyouhunter" --inputbox "目前提供的版本有如下： \
								2.10、2.10.6、2.10.7、2.10.8、2.10.9 \
								2.10.10、2.10.11、2.10.12、2.10.13 \
								2.11.0、2.11.1、2.11.2.2.11.3 \
								2.12.0、2.12.1、2.12.2 \
								2.13.0、2.13.1、2.13.2和最新 \
								请输入版本号[回车默认为：latest]" 15 55 3>&1 1>&2 2>&3)

								if [ -z "$QL2_VERSION" ]; then
									QL_TAG="latest"
								else
									QL_TAG=$QL2_VERSION
								fi
							}

							function ql2_input() {
								QL2_NAME=$(whiptail --title "一键脚本 作者：kissyouhunter" --inputbox "请输入将要创建的容器名[回车默认为：ql]" 10 55 3>&1 1>&2 2>&3)
								
								if [ -z "$QL2_NAME" ]; then
									QL_CONTAINER_NAME="ql"
								else
									QL_CONTAINER_NAME=$QL2_NAME
								fi

								QL2_CONFIG=$(whiptail --title "一键脚本 作者：kissyouhunter" --inputbox "请输入青龙存储的文件夹名称（如：ql)，回车默认为 ql:" 10 50 3>&1 1>&2 2>&3)

								if [ -z "$QL2_CONFIG" ]; then
									QL_PATH=/mnt/mmcblk2p4/ql
								else
									QL_PATH=/mnt/mmcblk2p4/$QL2_CONFIG
								fi

								function input_container_ql2_network_config() {
									QL2_NETWORK=$(whiptail --title "一键脚本 作者：kissyouhunter" --menu "请选择网络模式" 15 50 2 \
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
				SUBMENU3=$(whiptail --title "一键脚本 作者：kissyouhunter" --menu "安装 <ELECV2P>" 15 52 3 \
				"1" "linxu系统、X86的openwrt、群辉等请选择 1" \
				"2" "N1的EMMC上运行的openwrt请选择 2" \
				"0" "返回上级菜单" \
				3>&1 1>&2 2>&3)

				exitstatus=$?
				if [ $exitstatus = 0 ]; then
					case "$SUBMENU3" in
						1 )
							function input_container_v2p1_info() {
								whiptail --title "一键脚本 作者：kissyouhunter" --msgbox "访问方式为：宿主机ip:$V2P_PORT \
								<ELECV2P>安装完成，点击 ok 退出脚本 " 10 50
							}

							function input_container_v2p1_build() {
								TIME y " >>>>>>>>>>>配置完成，开始安装elecv2p"
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
								if (whiptail --title "一键脚本 作者：kissyouhunter" --yesno "elecv2p 容器名：$V2P_CONTAINER_NAME \
								elecv2p 面板端口：$V2P_PORT \
								elecv2p anyproxy端口：$V2P_PORT1 \
								elecv2p 网络请求查看端口：$V2P_PORT2 \
								elecv2p 配置文件路径：$V2P_PATH \
								以上信息是否正确？" \
								15 50) then
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
									V2P1_NAME=$(whiptail --title "一键脚本 作者：kissyouhunter" --inputbox "请输入将要创建的容器名[默认为：elecv2p]" 10 55 3>&1 1>&2 2>&3)
								
									if [ -z "$V2P1_NAME" ]; then
										V2P_CONTAINER_NAME="elecv2p"
									else
										V2P_CONTAINER_NAME=$V2P1_NAME
									fi
								}
								input_container_v2p1_name

								function input_container_v2p1_config() {
									V2P1_CONFIG=$(whiptail --title "一键脚本 作者：kissyouhunter" --inputbox "请输入elecv2p配置文件保存的绝对路径 \
									（示例：/home/elecv2p)，回车默认为当前目录:" 10 50 3>&1 1>&2 2>&3)

									if [ -z "$V2P1_CONFIG" ]; then
										V2P_PATH=$(pwd)/elecv2p
									else
										V2P_PATH=$V2P1_CONFIG
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
										V2P1_WEBUI_PORT=$(whiptail --title "一键脚本 作者：kissyouhunter" --menu "是否修改elecv2p面板端口[默认 8100]" 15 50 2 \
										"1" "修改" \
										"2" "不修改" \
										3>&1 1>&2 2>&3)

										exitstatus=$?
										if [ $exitstatus = 0 ]; then
											case "$V2P1_WEBUI_PORT" in
												1 )
													function input_container_v2p1_webui_port() {
														V2P1_WEBUI_PORT_CHANGE=$(whiptail --title "一键脚本 作者：kissyouhunter" --inputbox "输入想修改的端口" 10 55 3>&1 1>&2 2>&3)
														if [ -z "$V2P1_WEBUI_PORT_CHANGE" ]; then
															V2P_PORT="8100"
														else
															V2P_PORT=$V2P1_WEBUI_PORT_CHANGE
														fi
													}
													input_container_v2p1_webui_port
													;;
												2 )
													V2P_PORT="8100"
													;;
											esac
										else
											exit 0
										fi
									}
									input_container_v2p1_webui_config

									function input_container_v2p1_anyproxy_config() {
										V2P1_WEBUI_PORT=$(whiptail --title "一键脚本 作者：kissyouhunter" --menu "是否修改elecv2p的anyproxy端口[默认 8101]" 15 50 2 \
										"1" "修改" \
										"2" "不修改" \
										3>&1 1>&2 2>&3)

										exitstatus=$?
										if [ $exitstatus = 0 ]; then
											case "$V2P1_WEBUI_PORT" in
												1 )
													function input_container_v2p1_webui_port() {
														V2P1_WEBUI_PORT_CHANGE=$(whiptail --title "一键脚本 作者：kissyouhunter" --inputbox "输入想修改的端口" 10 55 3>&1 1>&2 2>&3)
														if [ -z "$V2P1_WEBUI_PORT_CHANGE" ]; then
															V2P_PORT1="8101"
														else
															V2P_PORT1=$V2P1_WEBUI_PORT_CHANGE
														fi
													}
													input_container_v2p1_webui_port
													;;
												2 )
													V2P_PORT1="8101"
													;;
											esac
										else
											exit 0
										fi
									}
									input_container_v2p1_anyproxy_config

									function input_container_v2p1_http_config() {
										V2P1_WEBUI_PORT=$(whiptail --title "一键脚本 作者：kissyouhunter" --menu "是否修改elecv2p网络请求查看端口[默认 8102]" 15 50 2 \
										"1" "修改" \
										"2" "不修改" \
										3>&1 1>&2 2>&3)

										exitstatus=$?
										if [ $exitstatus = 0 ]; then
											case "$V2P1_WEBUI_PORT" in
												1 )
													function input_container_v2p1_webui_port() {
														V2P1_WEBUI_PORT_CHANGE=$(whiptail --title "一键脚本 作者：kissyouhunter" --inputbox "输入想修改的端口" 10 55 3>&1 1>&2 2>&3)
														if [ -z "$V2P1_WEBUI_PORT_CHANGE" ]; then
															V2P_PORT2="8102"
														else
															V2P_PORT2=$V2P1_WEBUI_PORT_CHANGE
														fi
													}
													input_container_v2p1_webui_port
													;;
												2 )
													V2P_PORT2="8102"
													;;
											esac
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
							function input_container_ql2_info() {
								whiptail --title "一键脚本 作者：kissyouhunter" --msgbox "访问方式为：宿主机ip:$QL_PORT \
								<青龙>安装完成，点击 ok 退出脚本 " 10 50
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
								#while true
								#do
									if (whiptail --title "一键脚本 作者：kissyouhunter" --yesno "青龙容器名：$QL_CONTAINER_NAME \
									青龙配置文件路径：$QL_PATH \
									青龙网络类型：$NETWORK \
									青龙面板端口：$QL_PORT \
									青龙版本：$QL_TAG \
									以上信息是否正确？" \
									15 40) then
										input_container_ql2_docker
									else
										ql2_input
										QL_PORT="5700"
									fi
								#done
							}

							function input_container_ql2_version() {
								QL2_VERSION=$(whiptail --title "一键脚本 作者：kissyouhunter" --inputbox "目前提供的版本有如下： \
								2.10、2.10.6、2.10.7、2.10.8、2.10.9 \
								2.10.10、2.10.11、2.10.12、2.10.13 \
								2.11.0、2.11.1、2.11.2.2.11.3 \
								2.12.0、2.12.1、2.12.2 \
								2.13.0、2.13.1、2.13.2和最新 \
								请输入版本号[回车默认为：latest]" 15 55 3>&1 1>&2 2>&3)

								if [ -z "$QL2_VERSION" ]; then
									QL_TAG="latest"
								else
									QL_TAG=$QL2_VERSION
								fi
							}

							function ql2_input() {
								QL2_NAME=$(whiptail --title "一键脚本 作者：kissyouhunter" --inputbox "请输入将要创建的容器名[回车默认为：ql]" 10 55 3>&1 1>&2 2>&3)
								
								if [ -z "$QL2_NAME" ]; then
									QL_CONTAINER_NAME="ql"
								else
									QL_CONTAINER_NAME=$QL2_NAME
								fi

								QL2_CONFIG=$(whiptail --title "一键脚本 作者：kissyouhunter" --inputbox "请输入青龙存储的文件夹名称（如：ql)，回车默认为 ql:" 10 50 3>&1 1>&2 2>&3)

								if [ -z "$QL2_CONFIG" ]; then
									QL_PATH=/mnt/mmcblk2p4/ql
								else
									QL_PATH=/mnt/mmcblk2p4/$QL2_CONFIG
								fi

								function input_container_ql2_network_config() {
									QL2_NETWORK=$(whiptail --title "一键脚本 作者：kissyouhunter" --menu "请选择网络模式" 15 50 2 \
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
										echo
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
					echo
				fi
			}
			submenu3	
			;;		
		exit | quit | q )
			exit
			::
		esac
	else
		echo
	fi
}
main
