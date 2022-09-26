#!/bin/bash
#author kissyouhunter

declare flag=0
clear
while [ "$flag" -eq 0 ]
do
# 青龙变量
QL_DOCKER_IMG_NAME="whyour/qinglong"
TAG="latest"
QL_PATH=""
QL_SHELL_FOLDER=$(pwd)/ql
N1_QL_FOLDER=/mnt/mmcblk2p4/ql
QL_CONTAINER_NAME=""
NETWORK="bridge"
QL_PORT="5700"
# elev2p变量
V2P_DOCKER_IMG_NAME="elecv2/elecv2p"
V2P_PATH=""
V2P_SHELL_FOLDER=$(pwd)/elecv2p
N1_V2P_FOLDER=/mnt/mmcblk2p4/elecv2p
V2P_CONTAINER_NAME=""
V2P_PORT="8100"
V2P_PORT1="8101"
V2P_PORT2="8102"
# emby变量
EMBY_DOCKER_IMG_NAME="xinjiawei1/emby_unlockd"
EMBY_TAG="latest"
EMBY_PATH=""
EMBY_CONFIG_FOLDER=$(pwd)/emby
EMBY_MOVIES_FOLDER=$(pwd)/movies
EMBY_TVSHOWS_FOLDER=$(pwd)/tvshows
EMBY_CONTAINER_NAME=""
EMBY_PORT="8096"
EMBY_PORT1="8920"
# jellyfin变量
JELLYFIN_DOCKER_IMG_NAME="jellyfin/jellyfin"
JELLYFIN_PATH=""
JELLYFIN_CONFIG_FOLDER=$(pwd)/jellyfin
JELLYFIN_MOVIES_FOLDER=$(pwd)/movies
JELLYFIN_TVSHOWS_FOLDER=$(pwd)/tvshows
JELLYFIN_CONTAINER_NAME=""
JELLYFIN_PORT="8096"
JELLYFIN_PORT1="8920"
# qbittorrent变量
QB_DOCKER_IMG_NAME="johngong/qbittorrent"
QB_TAG="4.4.3.1-4.4.3.12"
QB_PATH=""
QB_CONFIG_FOLDER=$(pwd)/qbittorrent
QB_DOWNLOADS_FOLDER=$(pwd)/downloads
QB_CONTAINER_NAME=""
# aria2变量
ARIA2_DOCKER_IMG_NAME="superng6/aria2"
ARIA2_TAG="webui-latest"
ARIA2_PATH=""
ARIA2_CONFIG_FOLDER=$(pwd)/aria2
ARIA2_DOWNLOADS_FOLDER=$(pwd)/downloads
ARIA2_CONTAINER_NAME=""
TOKEN="aria2"
# aria2-pro变量
ARIA2_PRO_DOCKER_IMG_NAME="p3terx/aria2-pro"
ARIA2_PRO_WEBUI_DOCKER_IMG_NAME="p3terx/ariang"
ARIA2_PRO_PATH=""
ARIA2_PRO_CONFIG_FOLDER=$(pwd)/aria2-pro
ARIA2_PRO_DOWNLOADS_FOLDER=$(pwd)/downloads
ARIA2_PRO_CONTAINER_NAME=""
# telethon变量
TG_DOCKER_IMG_NAME="kissyouhunter/telethon"
TAG="latest"
TG_PATH=""
TG_SHELL_FOLDER=$(pwd)/telethon
N1_TG_FOLDER=/mnt/mmcblk2p4/telethon
TG_CONTAINER_NAME=""
# adguardhome变量
ADG_DOCKER_IMG_NAME="adguard/adguardhome"
TAG="latest"
ADG_PATH=""
ADG_CONFIG_FOLDER=$(pwd)/adguardhome
N1_ADG_FOLDER=/mnt/mmcblk2p4/adguardhome
ADG_CONTAINER_NAME=""
# x-ui变量
XUI_DOCKER_IMG_NAME="kissyouhunter/x-ui"
TAG="latest"
DEV="dev"
XUI_PATH=""
XUI_CONFIG_FOLDER=$(pwd)/x-ui
XUI_CONTAINER_NAME=""
# aapanel变量
AAPANEL_DOCKER_IMG_NAME="aapanel/aapanel"
AAPANEL_TAG="lib"
AAPANEL_PATH=""
AAPANEL_CONFIG_FOLDER=$(pwd)/aapanel
N1_AAPANEL_FOLDER=/mnt/mmcblk2p4/aapanel
AAPANEL_CONTAINER_NAME=""
# MaiARK 变量
MAIARK_DOCKER_IMG_NAME="kissyouhunter/maiark"
MAIARK_PATH=""
MAIARK_CONFIG_FOLDER=$(pwd)/MaiARK
N1_MAIARK_FOLDER=/mnt/mmcblk2p4/MarARK
MAIARK_CONTAINER_NAME=""
MAIARK_PORT="8082"
# FLAME 变量
FLAME_DOCKER_IMG_NAME="pawelmalak/flame"
FLAME_TAG="multiarch2.3.0"
FLAME_PATH=""
FLAME_CONFIG_FOLDER=$(pwd)/flame
N1_FLAME_FOLDER=/mnt/mmcblk2p4/flame
FLAME_CONTAINER_NAME=""

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

TIME w "============================================"
TIME w "              欢迎使用一键脚本"
TIME w "            作者：kissyouhunter"
TIME r "          请保证科学上网已经开启"
TIME w "      安装过程中可以按ctrl+c强制退出"
TIME w "     https://github.com/kissyouhunter"
TIME w "============================================"
#cat << EOF
TIME w "(1) 安装 docker和 docker-compose"
TIME w "(2) 安装 青龙 到宿主机"
TIME w "(3) 安装 elecv2p 到宿主机"
TIME w "(4) 安装 docker 图形管理工具"
TIME w "(5) 安装 emby 或 jellyfin (打造自己的爱奇艺)"
TIME w "(6) 安装下载工具"
TIME w "(7) Telegram 定时发送信息工具"
TIME w "(8) AdGuardHome DNS解析+去广告"
TIME w "(9) x-ui"
TIME w "(10) aaPanel (宝塔国际版)"
TIME w "(11) MaiARK (对接青龙提交京东CK)"
TIME w "(12) 一键申请SSL证书(acme申请)"
TIME w "(13) Flame (导航页)"
TIME r "(0) 不想安装了，给老子退出！！！"
#EOF
read -p "Please enter your choice[0-13]: " input
case $input in
#安装docker and docker-compose
1)
clear
while [ "$flag" -eq 0 ]
do
#cat << EOF
TIME w "----------------------------------------"
TIME w "|****Please Enter Your Choice:[0-3]****|"
TIME w "|******* DOCKER & DOCKER-COMPOSE ******|"
TIME w "----------------------------------------"
TIME w "(1) 安装 docker 和 docker-compose "
TIME w "(2) X86 openwrt 安装 docker 和 docker-comopse"
TIME w "(3) Arm64 openwrt 安装 docker和 docker-comopse(例 N1 等)"
TIME b "(0) 返回上级菜单"
#EOF
TIME l "<注>openwrt 宿主机默认安装 dockerman 图形 docker 管理工具！"
 read -p "Please enter your Choice[0-3]: " input1
 case $input1 in 
 1)
    TIME y " >>>>>>>>>>>开始安装 docker 和 docker-compose"
    if [ "$lsb_dist" == "openwrt" ]; then
        TIME r "****openwrt 宿主机请选择 2 或者 3 安装 docker****"
    else
		sleep 1
        bash <(curl -s -S -L https://raw.githubusercontent.com/kissyouhunter/Tools/main/docker-and-docker_compose.sh)
        TIME g "****docker和docker-compose安装完成，请返回上级菜单!****"
	    sleep 5
    fi
  ;;
 2)
    TIME y " >>>>>>>>>>>开始为 X86 openwrt 安装 docker 和 docker-compose"
    mkdir -p /tmp/upload/ && cd /tmp/upload/
    curl -LO https://cloud.kisslove.eu.org/d/aliyun/files/docker-2010.12-1_x86_64.zip
    unzip docker-2010.12-1_x86_64.zip && rm -f docker-2010.12-1_x86_64.zip
    cd /tmp/upload/docker-2010.12-1_x86_64 && opkg install *.ipk && cd .. && rm -rf docker-2010.12-1_x86_64/
    docker -v && docker-compose -v
    TIME g "****docker安装完成，请返回上级菜单!****"
    sleep 5
  ;;
 3)
    TIME y " >>>>>>>>>>>开始为 Arm64 openwrt 安装 docker 和 docker-compose"
    mkdir -p /tmp/upload/ && cd /tmp/upload/
    curl -LO https://cloud.kisslove.eu.org/d/aliyun/files/docker-20.10.15-1_aarch64.zip
    unzip docker-20.10.15-1_aarch64.zip && rm -f docker-20.10.15-1_aarch64.zip
    cd /tmp/upload/docker-20.10.15-1_aarch64 && opkg install *.ipk
    cd /tmp/upload && rm -rf docker-20.10.15-1_aarch64/
    docker -v && docker-compose -v
    TIME g "****docker 安装完成，请返回上级菜单!****"
    TIME g "****U盘上运行的 OP ，如果 docker 空间没有指定到 /mnt/sda4/docker ，请修改****"
    TIME g "****dockerman > 设置 > Docker 根目录 修改为 /mnt/sda4/docker ****"
    sleep 5
  ;;
 0) 
 clear 
 break
 ;;
 *) TIME r "----------------------------------"
    TIME r "|          Warning!!!            |"
    TIME r "|       请输入正确的选项!        |"
    TIME r "----------------------------------"
 for i in $(seq -w 1 -1 1)
   do
     #TIME r "\b\b$i";
     sleep 1;
   done
 clear
 ;;
 esac
 done
;;
#安装青龙
2)
clear
while [ "$flag" -eq 0 ]
do
#cat << EOF
TIME w "----------------------------------------"
TIME w "|****Please Enter Your Choice:[0-2]****|"
TIME w "|**************** 青龙 ****************|"
TIME w "----------------------------------------"
TIME w "(1) linxu系统、X86 的 openwrt、群辉等请选择 1"
TIME w "(2) N1 的 EMMC 上运行的 openwrt 请选择 2"
TIME b "(0) 返回上级菜单"
#EOF
TIME r "<注>选择1或2后，如果不明白如何选择或输入，请狂按回车！"
 read -p "Please enter your choice[0-3]: " input2
 case $input2 in 
 1)
  TIME y " >>>>>>>>>>>开始安装青龙"

    input_container_ql1_info() {
    log "列出所有宿主机上的容器"
    docker ps -a
    TIME g "-----------------------------------------------------"
    TIME g "|        青龙启动需要一点点时间，请耐心等待！       |"
    sleep 10
    TIME g "|             安装完成，自动退出脚本                |"
    if [ "$NETWORK" = "host" ]; then
    		TIME g "|            访问方式为 宿主机ip:5700               |"
    elif [ "$NETWORK" = "bridge" ]; then
    		TIME g "|            访问方式为 宿主机ip:$QL_PORT               |"
    fi
    TIME g "-----------------------------------------------------"
    exit 0
    }

  # 确认
  input_container_ql1_check() {
  while true
  do
  	TIME y "青龙配置文件路径：$QL_PATH"
  	TIME y "青龙容器名：$QL_CONTAINER_NAME"
  	TIME y "青龙网络类型：$NETWORK"
    TIME y "青龙版本：$TAG"
  	if [ "$NETWORK" = "host" ]; then
  		TIME y "青龙面板端口：5700"
  	elif [ "$NETWORK" = "bridge" ]; then
  		TIME y "青龙面板端口：$QL_PORT"
  	fi
  	read -r -p "以上信息是否正确？[Y/n] " input21
  	case $input21 in
  		[yY][eE][sS]|[yY])
  			break
  			;;
  		[nN][oO]|[nN])
  			TIME w "即将返回上一步"
  			sleep 1
  			QL_PORT="5700"
            TAG="latest"
  			input_container_ql1_version
            input_container_ql1_judge
            input_container_ql1_info
  			;;
  		*)
  			TIME r "输入错误，请输入[Y/n]"
  			;;
  	esac
  done
  }

  # 版本号
  input_container_ql1_version() {
  TIME w "青龙自2.12.0开始改变了目录结构，本脚本开始提供不同青龙版本。"
  TIME w "请根据提示驶入对应内容。"
  TIME w "目前提供的版本有如下："
  TIME w "2.10.6--13、2.11.0--3、2.12.0--2、2.13.0--9、2.14--最新"

  echo -n -e "请输入版本号（回车默认为最新版本）: "
  read ql_version
  if [ -z "$ql_version" ]; then
      QL_VERSION=$TAG
  elif [ -n "$ql_version" ]; then
      QL_VERSION=$ql_version
  fi
  TAG=$QL_VERSION
  }
  input_container_ql1_version

  # 创建映射文件夹
  input_container_ql1_config1() {
  echo -n -e "请输入青龙配置文件保存的绝对路径（示例：/home/ql)，回车默认为当前目录: "
  read ql_path
  if [ -z "$ql_path" ]; then
      QL_PATH=$QL_SHELL_FOLDER
  elif [ -d "$ql_path" ]; then
      QL_PATH=$ql_path
  else
      #mkdir -p $ql_path
      QL_PATH=$ql_path
  fi
  CONFIG_PATH=$QL_PATH
  }

  # 创建映射文件夹
  input_container_ql1_config2() {
  echo -n -e "请输入青龙配置文件保存的绝对路径（示例：/home/ql)，回车默认为当前目录: "
  read ql_path
  if [ -z "$ql_path" ]; then
      QL_PATH=$QL_SHELL_FOLDER
  elif [ -d "$ql_path" ]; then
      QL_PATH=$ql_path
  else
      #mkdir -p $ql_path
      QL_PATH=$ql_path
  fi
  CONFIG_PATH=$QL_PATH/config
  DB_PATH=$QL_PATH/db
  REPO_PATH=$QL_PATH/repo
  SCRIPT_PATH=$QL_PATH/scripts
  LOG_PATH=$QL_PATH/log
  DEPS_PATH=$QL_PATH/deps
  }

  # 输入容器名
  input_container_ql1_name() {
    echo -n -e "请输入将要创建的容器名[默认为：ql]-> "
    read container_name
    if [ -z "$container_name" ]; then
        QL_CONTAINER_NAME="ql"
    else
        QL_CONTAINER_NAME=$container_name
    fi
  }

  # 网络模式
  input_container_ql1_network_config() {
  inp "请选择容器的网络类型：\n1) host\n2) bridge[默认]"
  opt
  read net
  if [ "$net" = "1" ]; then
      NETWORK="host"
      MAPPING_QL_PORT=""
  fi
  
  if [ "$NETWORK" = "bridge" ]; then
      inp "是否修改青龙端口[默认 5700]：\n1) 修改\n2) 不修改[默认]"
      opt
      read change_ql_port
      if [ "$change_ql_port" = "1" ]; then
          echo -n -e "输入想修改的端口->"
          read QL_PORT
      else
          QL_PORT="5700"
      fi
  fi
  }

  input_container_ql1_build1() {
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
      $QL_DOCKER_IMG_NAME:$TAG

      if [ $? -ne 0 ] ; then
          cancelrun "** 错误：容器创建失败，请翻译以上英文报错，Google/百度尝试解决问题！"
      fi
  }

  input_container_ql1_build2() {
  TIME y " >>>>>>>>>>>配置完成，开始安装青龙"
  log "1.开始创建配置文件目录"
  PATH_LIST=($CONFIG_PATH $DB_PATH $REPO_PATH $SCRIPT_PATH $LOG_PATH $DEPS_PATH)
  for i in ${PATH_LIST[@]}; do
      mkdir -p $i
  done

  log "2.开始创建容器并执行"
  docker run -dit \
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
      $QL_DOCKER_IMG_NAME:$TAG

      if [ $? -ne 0 ] ; then
          cancelrun "** 错误：容器创建失败，请翻译以上英文报错，Google/百度尝试解决问题！"
      fi
  }

  input_container_ql1_judge() {
  if [ $TAG == "2.10" ] || [ $TAG == "2.10.6" ] || [ $TAG == "2.10.7" ] || [ $TAG == "2.10.8" ] || [ $TAG == "2.10.9" ] || [ $TAG == "2.10.10" ] || [ $TAG == "2.10.11" ] || [ $TAG == "2.10.12" ] || [ $TAG == "2.10.13" ] || [ $TAG == "2.11" ] || [ $TAG == "2.11.0" ] || [ $TAG == "2.11.1" ] || [ $TAG == "2.11.2" ] || [ $TAG == "2.11.3" ]; then
      input_container_ql1_config2
      input_container_ql1_name
      input_container_ql1_network_config
      input_container_ql1_check
      input_container_ql1_build2
  else 
      input_container_ql1_config1
      input_container_ql1_name
      input_container_ql1_network_config
      input_container_ql1_check
      input_container_ql1_build1
  fi
  }
  input_container_ql1_judge

      log "列出所有宿主机上的容器"
      docker ps -a
    TIME g "-----------------------------------------------------"
    TIME g "|        青龙启动需要一点点时间，请耐心等待！       |"
    sleep 10
    TIME g "|             安装完成，自动退出脚本                |"
    if [ "$NETWORK" = "host" ]; then
    		TIME g "|            访问方式为 宿主机ip:5700               |"
    elif [ "$NETWORK" = "bridge" ]; then
    		TIME g "|            访问方式为 宿主机ip:$QL_PORT               |"
    fi
    TIME g "-----------------------------------------------------"
  exit 0
  ;;
 2)  
  TIME y " >>>>>>>>>>>开始安装青龙到 N1 的 /mnt/mmcblk2p4/"

    input_container_ql2_info() {
    log "列出所有宿主机上的容器"
    docker ps -a
    TIME g "-----------------------------------------------------"
    TIME g "|        青龙启动需要一点点时间，请耐心等待！       |"
    sleep 10
    TIME g "|             安装完成，自动退出脚本                |"
    if [ "$NETWORK" = "host" ]; then
    		TIME g "|            访问方式为 宿主机ip:5700               |"
    elif [ "$NETWORK" = "bridge" ]; then
    		TIME g "|            访问方式为 宿主机ip:$QL_PORT               |"
    fi
    TIME g "-----------------------------------------------------"
    exit 0
    }

  # 确认
  input_container_ql2_check() {
  while true
  do
  	TIME y "青龙配置文件路径：$QL_PATH"
  	TIME y "青龙容器名：$QL_CONTAINER_NAME"
  	TIME y "青龙网络类型：$NETWORK"
    TIME y "青龙版本：$TAG"
  	if [ "$NETWORK" = "host" ]; then
  		TIME y "青龙面板端口：5700"
  	elif [ "$NETWORK" = "bridge" ]; then
  		TIME y "青龙面板端口：$QL_PORT"
  	fi
  	read -r -p "以上信息是否正确？[Y/n] " input21
  	case $input21 in
  		[yY][eE][sS]|[yY])
  			break
  			;;
  		[nN][oO]|[nN])
  			TIME w "即将返回上一步"
  			sleep 1
  			QL_PORT="5700"
            TAG="latest"
  			input_container_ql2_version
            input_container_ql2_judge
            input_container_ql2_info
  			;;
  		*)
  			TIME r "输入错误，请输入[Y/n]"
  			;;
  	esac
  done
  }

  # 版本号
  input_container_ql2_version() {
  TIME w "青龙自2.12.0开始改变了目录结构，本脚本开始提供不同青龙版本。"
  TIME w "请根据提示驶入对应内容。"
  TIME w "目前提供的版本有如下："
  TIME w "2.10.6--13、2.11.0--3、2.12.0--2、2.13.0--8及最新"
  echo -n -e "请输入版本号（回车默认为最新版本）: "
  read ql_version
  if [ -z "$ql_version" ]; then
      QL_VERSION=$TAG
  elif [ -n "$ql_version" ]; then
      QL_VERSION=$ql_version
  fi
  TAG=$QL_VERSION
  }
  input_container_ql2_version


  # 创建映射文件夹
  input_container_ql2_config1() {
  echo -n -e "请输入青龙存储的文件夹名称（如：ql)，回车默认为 ql: "
  read ql_path
  if [ -z "$ql_path" ]; then
      QL_PATH=$N1_QL_FOLDER
  elif [ -d "$ql_path" ]; then
      QL_PATH=/mnt/mmcblk2p4/$ql_path
  else
      #mkdir -p /mnt/mmcblk2p4/$ql_path
      QL_PATH=/mnt/mmcblk2p4/$ql_path
  fi
  CONFIG_PATH=$QL_PATH
  }

  # 创建映射文件夹
  input_container_ql2_config2() {
  echo -n -e "请输入青龙存储的文件夹名称（如：ql)，回车默认为 ql: "
  read ql_path
  if [ -z "$ql_path" ]; then
      QL_PATH=$N1_QL_FOLDER
  elif [ -d "$ql_path" ]; then
      QL_PATH=/mnt/mmcblk2p4/$ql_path
  else
      #mkdir -p /mnt/mmcblk2p4/$ql_path
      QL_PATH=/mnt/mmcblk2p4/$ql_path
  fi
  CONFIG_PATH=$QL_PATH/config
  DB_PATH=$QL_PATH/db
  REPO_PATH=$QL_PATH/repo
  SCRIPT_PATH=$QL_PATH/scripts
  LOG_PATH=$QL_PATH/log
  DEPS_PATH=$QL_PATH/deps
  }
  
  # 输入容器名
  input_container_ql2_name() {
    echo -n -e "请输入将要创建的容器名[默认为：ql]-> "
    read container_name
    if [ -z "$container_name" ]; then
        QL_CONTAINER_NAME="ql"
    else
        QL_CONTAINER_NAME=$container_name
    fi
  }

  # 网络模式
  input_container_ql2_network_config() {
  inp "请选择容器的网络类型：\n1) host\n2) bridge[默认]"
  opt
  read net
  if [ "$net" = "1" ]; then
      NETWORK="host"
      MAPPING_QL_PORT=""
  fi
  
  if [ "$NETWORK" = "bridge" ]; then
      inp "是否修改青龙端口[默认 5700]：\n1) 修改\n2) 不修改[默认]"
      opt
      read change_ql_port
      if [ "$change_ql_port" = "1" ]; then
          echo -n -e "输入想修改的端口->"
          read QL_PORT
      else
          QL_PORT="5700"
      fi
  fi
  }

  input_container_ql2_build1() {
  TIME y " >>>>>>>>>>>配置完成，开始安装青龙"
  log "1.开始创建配置文件目录"
  PATH_LIST=($CONFIG_PATH)
  for i in ${PATH_LIST[@]}; do
      mkdir -p $i
  done

  log "3.开始创建容器并执行"
  docker run -dit \
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
      $QL_DOCKER_IMG_NAME:$TAG

      if [ $? -ne 0 ] ; then
          cancelrun "** 错误：容器创建失败，请翻译以上英文报错，Google/百度尝试解决问题！"
      fi
  }

  input_container_ql2_build2() {
  TIME y " >>>>>>>>>>>配置完成，开始安装青龙"
  log "1.开始创建配置文件目录"
  PATH_LIST=($CONFIG_PATH $DB_PATH $REPO_PATH $SCRIPT_PATH $LOG_PATH $DEPS_PATH)
  for i in ${PATH_LIST[@]}; do
      mkdir -p $i
  done

  log "2.开始创建容器并执行"
  docker run -dit \
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
      $QL_DOCKER_IMG_NAME:$TAG

      if [ $? -ne 0 ] ; then
          cancelrun "** 错误：容器创建失败，请翻译以上英文报错，Google/百度尝试解决问题！"
      fi
  }

  input_container_ql2_judge() {
  if [ $TAG == "2.10" ] || [ $TAG == "2.10.6" ] || [ $TAG == "2.10.7" ] || [ $TAG == "2.10.8" ] || [ $TAG == "2.10.9" ] || [ $TAG == "2.10.10" ] || [ $TAG == "2.10.11" ] || [ $TAG == "2.10.12" ] || [ $TAG == "2.10.13" ] || [ $TAG == "2.11" ] || [ $TAG == "2.11.0" ] || [ $TAG == "2.11.1" ] || [ $TAG == "2.11.2" ] || [ $TAG == "2.11.3" ]; then
      input_container_ql2_config2
      input_container_ql2_name
      input_container_ql2_network_config
      input_container_ql2_check
      input_container_ql2_build2
  else 
      input_container_ql2_config1
      input_container_ql2_name
      input_container_ql2_network_config
      input_container_ql2_check
      input_container_ql2_build1
  fi
  }
  input_container_ql2_judge

      log "列出所有宿主机上的容器"
      docker ps -a
    TIME g "-----------------------------------------------------"
    TIME g "|        青龙启动需要一点点时间，请耐心等待！       |"
    sleep 10
    TIME g "|             安装完成，自动退出脚本                |"
    if [ "$NETWORK" = "host" ]; then
    		TIME g "|            访问方式为 宿主机ip:5700               |"
    elif [ "$NETWORK" = "bridge" ]; then
    		TIME g "|            访问方式为 宿主机ip:$QL_PORT               |"
    fi
    TIME g "-----------------------------------------------------"
  exit 0
  ;;
 0) 
 clear 
 break
 ;;
 *) TIME r "----------------------------------"
    TIME r "|          Warning!!!            |"
    TIME r "|       请输入正确的选项!        |"
    TIME r "----------------------------------"
 for i in $(seq -w 1 -1 1)
   do
     #TIME r "\b\b$i";
     sleep 1;
   done
 clear
 ;;
 esac
 done
;;
#安装elecv2p
3)
clear
while [ "$flag" -eq 0 ]
do
#cat << EOF
TIME w "----------------------------------------"
TIME w "|****Please Enter Your Choice:[0-2]****|"
TIME w "|*************** ELECV2P **************|"
TIME w "----------------------------------------"
TIME w "(1) linxu系统、X86 的 openwrt、群辉等请选择 1"
TIME w "(2) N1 的 EMMC 上运行的 openwrt 请选择 2"
TIME b "(0) 返回上级菜单"
#EOF
TIME r "<注>选择1或2后，如果不明白如何选择或输入，请狂按回车！"
 read -p "Please enter your Choice[0-2]: " input3
 case $input3 in 
 1)
  TIME y " >>>>>>>>>>>开始安装 elecv2p"
  # 创建映射文件夹
  input_container_v2p1_config() {
  echo -n -e "请输入 elecv2p 配置文件保存的绝对路径（示例：/home/elecv2p)，回车默认为当前目录: "
  read v2p_path
  if [ -z "$v2p_path" ]; then
      V2P_PATH=$V2P_SHELL_FOLDER
  elif [ -d "$v2p_path" ]; then
      V2P_PATH=$v2p_path
  else
      #mkdir -p $v2p_path
      V2P_PATH=$v2p_path
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
  
  # 输入容器名
  input_container_v2p1_name() {
    echo -n -e "请输入将要创建的容器名[默认为：elecv2p]-> "
    read container_name
    if [ -z "$container_name" ]; then
        V2P_CONTAINER_NAME="elecv2p"
    else
        V2P_CONTAINER_NAME=$container_name
    fi
  }
  input_container_v2p1_name

  # 面板端口
  input_container_v2p1_webui_config() {
  inp "是否修改 elecv2p 面板端口[默认 8100]：\n1) 修改\n2) 不修改[默认]"
  opt
  read change_v2p_port
  if [ "$change_v2p_port" = "1" ]; then
      echo -n -e "输入想修改的端口->"
      read V2P_PORT
  fi
  }
  input_container_v2p1_webui_config
  
  # ANYPROXY端口
  input_container_v2p1_anyproxy_config() {
  inp "是否修改 elecv2p 的 anyproxy 端口[默认 8101]：\n1) 修改\n2) 不修改[默认]"
  opt
  read change_v2p_port1
  if [ "$change_v2p_port1" = "1" ]; then
      echo -n -e "输入想修改的端口->"
      read V2P_PORT1
  fi
  }
  input_container_v2p1_anyproxy_config
  
  # 网络请求查看端口
  input_container_v2p1_http_config() {
  inp "是否修改 elecv2p 网络请求查看端口[默认 8102]：\n1) 修改\n2) 不修改[默认]"
  opt
  read change_v2p_port2
  if [ "$change_v2p_port2" = "1" ]; then
      echo -n -e "输入想修改的端口->"
      read V2P_PORT2
  fi
  }
  input_container_v2p1_http_config

  # 确认
  while true
  do
  	TIME y "elecv2p 配置文件路径：$V2P_PATH"
  	TIME y "elecv2p 容器名：$V2P_CONTAINER_NAME"
  	TIME y "elecv2p 面板端口：$V2P_PORT"
  	TIME y "elecv2p anyproxy端口：$V2P_PORT1"
  	TIME y "elecv2p 网络请求查看端口：$V2P_PORT2"
  	read -r -p "以上信息是否正确？[Y/n] " input32
  	case $input32 in
  		[yY][eE][sS]|[yY])
  			break
  			;;
  		[nN][oO]|[nN])
  			TIME w "即将返回上一步"
  			sleep 1
  			V2P_PORT="8100"
  			V2P_PORT1="8101"
  			V2P_PORT2="8102"
  			input_container_v2p1_config
  			input_container_v2p1_name
  			input_container_v2p1_webui_config
  			input_container_v2p1_anyproxy_config
  			input_container_v2p1_http_config
  			;;
  		*)
  			TIME r "输入错误，请输入[Y/n]"
  			;;
  	esac
  done

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
      -v $LOG_PATH:/usr/local/app/logs \
      -p $V2P_PORT:80 -p $V2P_PORT1:8001 -p $V2P_PORT2:8002 \
      -e TZ=Asia/Shanghai \
      --name $V2P_CONTAINER_NAME \
      --hostname $V2P_CONTAINER_NAME \
      --restart always \
      $V2P_DOCKER_IMG_NAME:$TAG

      if [ $? -ne 0 ] ; then
          cancelrun "** 错误：容器创建失败，请翻译以上英文报错，Google/百度尝试解决问题！"
      fi

      log "列出所有宿主机上的容器"
      docker ps -a
    TIME g "-----------------------------------------------------"
    TIME g "|      elev2p 启动需要一点点时间，请耐心等待！      |"
    sleep 10
    TIME g "|             安装完成，自动退出脚本                |"
    TIME g "|            访问方式为 宿主机ip:$V2P_PORT               |"
    TIME g "-----------------------------------------------------"
  exit 0
  ;;
 2)
  TIME y " >>>>>>>>>>>开始安装 elecv2p 到 N1 的 /mnt/mmcblk2p4/"
  # 创建映射文件夹
  input_container_v2p2_config() {
  echo -n -e "请输入 elecv2p 存储的文件夹名称（如：elecv2p)，回车默认为 elecv2p: "
  read v2p_path
  if [ -z "$v2p_path" ]; then
      V2P_PATH=$N1_V2P_FOLDER
  elif [ -d "$v2p_path" ]; then
      V2P_PATH=/mnt/mmcblk2p4/$v2p_path
  else
      #mkdir -p /mnt/mmcblk2p4/$v2p_path
      V2P_PATH=/mnt/mmcblk2p4/$v2p_path
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
  
  # 输入容器名
  input_container_v2p2_name() {
    echo -n -e "请输入将要创建的容器名[默认为：elecv2p]-> "
    read container_name
    if [ -z "$container_name" ]; then
        V2P_CONTAINER_NAME="elecv2p"
    else
        V2P_CONTAINER_NAME=$container_name
    fi
  }
  input_container_v2p2_name

  # 面板端口
  input_container_v2p2_webui_config() {
  inp "是否修改 elecv2p 面板端口[默认 8100]：\n1) 修改\n2) 不修改[默认]"
  opt
  read change_v2p_port
  if [ "$change_v2p_port" = "1" ]; then
      echo -n -e "输入想修改的端口->"
      read V2P_PORT
  fi
  }
  input_container_v2p2_webui_config
  
  # ANYPROXY端口
  input_container_v2p2_anyproxy_config() {
  inp "是否修改 elecv2p 的 anyproxy 端口[默认 8101]：\n1) 修改\n2) 不修改[默认]"
  opt
  read change_v2p_port1
  if [ "$change_v2p_port1" = "1" ]; then
      echo -n -e "输入想修改的端口->"
      read V2P_PORT1
  fi
  }
  input_container_v2p2_anyproxy_config
  
  # 网络请求查看端口
  input_container_v2p2_http_config() {
  inp "是否修改 elecv2p 网络请求查看端口[默认 8102]：\n1) 修改\n2) 不修改[默认]"
  opt
  read change_v2p_port2
  if [ "$change_v2p_port2" = "1" ]; then
      echo -n -e "输入想修改的端口->"
      read V2P_PORT2
  fi
  }
  input_container_v2p2_http_config

  # 确认
  while true
  do
  	TIME y "elecv2p 配置文件路径：$V2P_PATH"
  	TIME y "elecv2p 容器名：$V2P_CONTAINER_NAME"
  	TIME y "elecv2p 面板端口：$V2P_PORT"
  	TIME y "elecv2p anyproxy端口：$V2P_PORT1"
  	TIME y "elecv2p 网络请求查看端口：$V2P_PORT2"
  	read -r -p "以上信息是否正确？[Y/n] " input32
  	case $input32 in
  		[yY][eE][sS]|[yY])
  			break
  			;;
  		[nN][oO]|[nN])
  			TIME w "即将返回上一步"
  			sleep 1
  			V2P_PORT="8100"
  			V2P_PORT1="8101"
  			V2P_PORT2="8102"
  			input_container_v2p2_config
  			input_container_v2p2_name
  			input_container_v2p2_webui_config
  			input_container_v2p2_anyproxy_config
  			input_container_v2p2_http_config
  			;;
  		*)
  			TIME r "输入错误，请输入[Y/n]"
  			;;
  	esac
  done

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
      -v $LOG_PATH:/usr/local/app/logs \
      -p $V2P_PORT:80 -p $V2P_PORT1:8001 -p $V2P_PORT2:8002 \
      -e TZ=Asia/Shanghai \
      --name $V2P_CONTAINER_NAME \
      --hostname $V2P_CONTAINER_NAME \
      --restart always \
      $V2P_DOCKER_IMG_NAME:$TAG

      if [ $? -ne 0 ] ; then
          cancelrun "** 错误：容器创建失败，请翻译以上英文报错，Google/百度尝试解决问题！"
      fi

      log "列出所有宿主机上的容器"
      docker ps -a
    TIME g "-----------------------------------------------------"
    TIME g "|      elev2p 启动需要一点点时间，请耐心等待！      |"
    sleep 10
    TIME g "|             安装完成，自动退出脚本                |"
    TIME g "|            访问方式为 宿主机ip:$V2P_PORT               |"
    TIME g "-----------------------------------------------------"
  exit 0
  ;;
 0) 
 clear 
 break
 ;;
 *) TIME r "----------------------------------"
    TIME r "|          Warning!!!            |"
    TIME r "|       请输入正确的选项!        |"
    TIME r "----------------------------------"
 for i in $(seq -w 1 -1 1)
   do
     #TIME r "\b\b$i";
     sleep 1;
   done
 clear
 ;;
 esac
 done
;;
#安装portainer
4)
clear
while [ "$flag" -eq 0 ]
do
#cat << EOF
TIME w "----------------------------------------"
TIME w "|****Please Enter Your Choice:[0-3]****|"
TIME w "|********* DOCKER 图形管理工具 ********|"
TIME w "----------------------------------------"
TIME w "(1) 安装 portianer 官方原版"
TIME w "(2) 安装 portianer 大佬汉化版"
TIME w "(3) 安装 portianer 大佬汉化版（N1 openwert 专用）"
TIME b "(0) 返回上级菜单"
TIME r "大佬汉化版不能保证没有 bug"
#EOF
 read -p "Please enter your Choice[0-3]: " input4
 case $input4 in 
 1)
    TIME y " >>>>>>>>>>>开始安装 portainer 官方原版"
    docker volume create portainer_data
    docker run -d -p 8000:8000 -p 9000:9000 --name=portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ce
    
    if [ $? -ne 0 ] ; then
        cancelrun "** 错误：容器创建失败，请翻译以上英文报错，Google/百度尝试解决问题！"
    fi
      log "列出所有宿主机上的容器"
      docker ps -a
    TIME g "------------------------------------------------------"
    TIME g "|      portainer 启动需要一点点时间，请耐心等待！    |"
    sleep 10
    TIME g "|              安装完成，自动退出脚本                |"
    TIME g "|   访问方式为宿主机ip:端口(例192.168.2.1:9000)      |"
    TIME g "------------------------------------------------------"
  exit 0  
  ;;
 2)
    TIME y " >>>>>>>>>>>开始安装 portainer 大佬汉化版"
    if [ "$(command -v unzip)" ]; then
        mkdir -p /root/portainer
        curl -Lo /root/portainer/portainer-ce-public-cn-20220728.zip https://github.com/kissyouhunter/Tools/releases/download/portainer-ce-public-cn-20220728/portainer-ce-public-cn-20220728.zip
        cd /root/portainer && unzip portainer-ce-public-cn-20220728.zip && rm -f portainer-ce-public-cn-20220728.zip
    else
        apt update && apt install -y zip unzip
        mkdir -p /root/portainer
        curl -Lo /root/portainer/portainer-ce-public-cn-20220728.zip https://github.com/kissyouhunter/Tools/releases/download/portainer-ce-public-cn-20220728/portainer-ce-public-cn-20220728.zip
        cd /root/portainer && unzip portainer-ce-public-cn-20220728.zip && rm -f portainer-ce-public-cn-20220728.zip
    fi
    docker volume create portainer_data
    docker run -d -p 8000:8000 -p 9000:9000 --name=portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data -v /root/portainer/public:/public portainer/portainer-ce
    
    if [ $? -ne 0 ] ; then
        cancelrun "** 错误：容器创建失败，请翻译以上英文报错，Google/百度尝试解决问题！"
    fi
      log "列出所有宿主机上的容器"
      docker ps -a
    TIME g "------------------------------------------------------"
    TIME g "|      portainer 启动需要一点点时间，请耐心等待！    |"
    sleep 10
    TIME g "|              安装完成，自动退出脚本                |"
    TIME g "|   访问方式为宿主机ip:端口(例192.168.2.1:9000)      |"
    TIME r "|            大佬汉化版不能保证没有 bug              |"
    TIME g "------------------------------------------------------"
  exit 0   
  ;;
 3)
    TIME y " >>>>>>>>>>>开始安装 portainer 大佬汉化版（N1 openwert 专用）"
    if [ "$(command -v unzip)" ]; then
        mkdir -p /mnt/mmcblk2p4/portainer
        curl -Lo /mnt/mmcblk2p4/portainer/portainer-ce-public-cn-20220728.zip https://github.com/kissyouhunter/Tools/releases/download/portainer-ce-public-cn-20220728/portainer-ce-public-cn-20220728.zip
        cd /mnt/mmcblk2p4/portainer && unzip portainer-ce-public-cn-20220728.zip && rm -f portainer-ce-public-cn-20220728.zip
    else
        TIME r "宿主机缺少插件 zip 和 unzip，请自行安装。"
        exit 1
    fi
    docker volume create portainer_data
    docker run -d -p 8000:8000 -p 9000:9000 --name=portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data -v /mnt/mmcblk2p4/portainer/public:/public portainer/portainer-ce
    
    if [ $? -ne 0 ] ; then
        cancelrun "** 错误：容器创建失败，请翻译以上英文报错，Google/百度尝试解决问题！"
    fi
      log "列出所有宿主机上的容器"
      docker ps -a
    TIME g "------------------------------------------------------"
    TIME g "|      portainer 启动需要一点点时间，请耐心等待！    |"
    sleep 10
    TIME g "|              安装完成，自动退出脚本                |"
    TIME g "|   访问方式为宿主机ip:端口(例192.168.2.1:9000)      |"
    TIME r "|            大佬汉化版不能保证没有 bug              |"
    TIME g "------------------------------------------------------"
  exit 0 
  ;;
 0) 
 clear 
 break
 ;;
 *) TIME r "----------------------------------"
    TIME r "|          Warning!!!            |"
    TIME r "|       请输入正确的选项!        |"
    TIME r "----------------------------------"
 for i in $(seq -w 1 -1 1)
   do
     #TIME r "\b\b$i";
     sleep 1;
   done
 clear
 ;;
 esac
 done
;;
#安装emby和jellyfin
5)
clear
while [ "$flag" -eq 0 ]
do
#cat << EOF
TIME w "----------------------------------------"
TIME w "|****Please Enter Your Choice:[0-2]****|"
TIME w "|*********** EMBY & JELLYFIN **********|"
TIME w "----------------------------------------"
TIME w "(1) 安装 emby (开心版暂无 arm64)"
TIME w "(2) 安装 jellyfin"
TIME b "(0) 返回上级菜单"
#EOF
TIME r "<注>请使用 root 账户部署容器"
 read -p "Please enter your Choice[0-2]: " input5
 case $input5 in 
 1)
    TIME y " >>>>>>>>>>>开始安装 emby"
  # 创建映射文件夹
  input_container_emby_config() {
  echo -n -e "请输入 emby 配置文件保存的绝对路径（示例：/home/emby)，回车默认为当前目录: "
  read emby_path
  if [ -z "$emby_path" ]; then
      EMBY_PATH=$EMBY_CONFIG_FOLDER
  elif [ -d "$emby_path" ]; then
      EMBY_PATH=$emby_path
  else
      #mkdir -p $emby_path
      EMBY_PATH=$emby_path
  fi
  CONFIG_PATH=$EMBY_PATH/config
  echo -n -e "请输入电影文件保存的绝对路径（示例：/home/movies)，回车默认为当前目录: "
  read movies_path
  if [ -z "$movies_path" ]; then
      MOVIES_PATH=$EMBY_MOVIES_FOLDER
  elif [ -d "$movies_path" ]; then
      MOVIES_PATH=$movies_path
  else
      #mkdir -p $movies_path
      MOVIES_PATH=$movies_path
  fi
  echo -n -e "请输入电视剧文件保存的绝对路径（示例：/home/tvshows)，回车默认为当前目录: "
  read tvshows_path
  if [ -z "$tvshows_path" ]; then
      TVSHOWS_PATH=$EMBY_TVSHOWS_FOLDER
  elif [ -d "$tvshows_path" ]; then
      TVSHOWS_PATH=$tvshows_path
  else
      #mkdir -p $tvshows_path
      TVSHOWS_PATH=$tvshows_path
  fi
  }
  input_container_emby_config
  
  # 输入容器名
  input_container_emby_name() {
    echo -n -e "请输入将要创建的容器名[默认为：emby]-> "
    read container_name
    if [ -z "$container_name" ]; then
        EMBY_CONTAINER_NAME="emby"
    else
        EMBY_CONTAINER_NAME=$container_name
    fi
  }
  input_container_emby_name

  # 面板端口
  input_container_emby_webui_config() {
  inp "是否修改 emby 面板端口[默认 8096]：\n1) 修改\n2) 不修改[默认]"
  opt
  read change_emby_port
  if [ "$change_emby_port" = "1" ]; then
      echo -n -e "输入想修改的端口->"
      read EMBY_PORT
  fi
  }
  input_container_emby_webui_config
  
  # https端口
  input_container_emby_https_config() {
  inp "是否修改 emby 的 https 端口[默认 8920]：\n1) 修改\n2) 不修改[默认]"
  opt
  read change_emby_port1
  if [ "$change_emby_port1" = "1" ]; then
      echo -n -e "输入想修改的端口->"
      read EMBY_PORT1
  fi
  }
  input_container_emby_https_config

  # 确认
  while true
  do
  	TIME y "emby 配置文件路径：$CONFIG_PATH"
  	TIME y "emby 电影文件路径：$MOVIES_PATH"
  	TIME y "emby 电视剧文件路径：$TVSHOWS_PATH"
  	TIME y "emby 容器名：$EMBY_CONTAINER_NAME"
  	TIME y "emby 面板端口：$EMBY_PORT"
  	TIME y "emby https 端口：$EMBY_PORT1"
  	read -r -p "以上信息是否正确？[Y/n] " input51
  	case $input51 in
  		[yY][eE][sS]|[yY])
  			break
  			;;
  		[nN][oO]|[nN])
  			TIME w "即将返回上一步"
  			sleep 1
  			EMBY_PORT="8096"
  			EMBY_PORT1="8920"
  			input_container_emby_config
  			input_container_emby_name
  			input_container_emby_webui_config
  			input_container_emby_https_config
  			;;
  		*)
  			TIME r "输入错误，请输入[Y/n]"
  			;;
  	esac
  done

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

      log "列出所有宿主机上的容器"
      docker ps -a
    TIME g "-----------------------------------------------------------------"
    TIME g "|              emby 启动需要一点点时间，请耐心等待！            |"
    sleep 10
    TIME g "|                    安装完成，自动退出脚本                     |"
    TIME g "|         emby 默认端口为8096，如有修改请访问修改的端口         |"
    TIME g "|         访问方式为宿主机ip:端口(例192.168.2.1:8096)           |"
    TIME g "|   openwrt 需要先执行命令 chmod 777 /dev/dri/* 才能读取到显卡  |"
    TIME g "-----------------------------------------------------------------"
  exit 0
  ;;
 2)
    TIME y " >>>>>>>>>>>开始安装 jellyfin"
  # 创建映射文件夹
  input_container_jellyfin_config() {
  echo -n -e "请输入 jellyfin 配置文件保存的绝对路径（示例：/home/jellyfin)，回车默认为当前目录: "
  read jellyfin_path
  if [ -z "$jellyfin_path" ]; then
      JELLYFIN_PATH=$JELLYFIN_CONFIG_FOLDER
  elif [ -d "$jellyfin_path" ]; then
      JELLYFIN_PATH=$jellyfin_path
  else
      #mkdir -p $jellyfin_path
      JELLYFIN_PATH=$jellyfin_path
  fi
  CONFIG_PATH=$JELLYFIN_PATH/config
  echo -n -e "请输入电影文件保存的绝对路径（示例：/home/movies)，回车默认为当前目录: "
  read movies_path
  if [ -z "$movies_path" ]; then
      MOVIES_PATH=$JELLYFIN_MOVIES_FOLDER
  elif [ -d "$movies_path" ]; then
      MOVIES_PATH=$movies_path
  else
      #mkdir -p $movies_path
      MOVIES_PATH=$movies_path
  fi
  echo -n -e "请输入电视剧文件保存的绝对路径（示例：/home/tvshows)，回车默认为当前目录: "
  read tvshows_path
  if [ -z "$tvshows_path" ]; then
      TVSHOWS_PATH=$JELLYFIN_TVSHOWS_FOLDER
  elif [ -d "$tvshows_path" ]; then
      TVSHOWS_PATH=$tvshows_path
  else
      #mkdir -p $tvshows_path
      TVSHOWS_PATH=$tvshows_path
  fi
  }
  input_container_jellyfin_config
  
  # 输入容器名
  input_container_jellyfin_name() {
    echo -n -e "请输入将要创建的容器名[默认为：jellyfin]-> "
    read container_name
    if [ -z "$container_name" ]; then
        JELLYFIN_CONTAINER_NAME="jellyfin"
    else
        JELLYFIN_CONTAINER_NAME=$container_name
    fi
  }
  input_container_jellyfin_name

  # 面板端口
  input_container_jellyfin_webui_config() {
  inp "是否修改 jellyfin 面板端口[默认 8096]：\n1) 修改\n2) 不修改[默认]"
  opt
  read change_jellyfin_port
  if [ "$change_jellyfin_port" = "1" ]; then
      echo -n -e "输入想修改的端口->"
      read JELLYFIN_PORT
  fi
  }
  input_container_jellyfin_webui_config
  
  # https端口
  input_container_jellyfin_https_config() {
  inp "是否修改 jellyfin 的 https 端口[默认 8920]：\n1) 修改\n2) 不修改[默认]"
  opt
  read change_jellyfin_port1
  if [ "$change_jellyfin_port1" = "1" ]; then
      echo -n -e "输入想修改的端口->"
      read JELLYFIN_PORT1
  fi
  }
  input_container_jellyfin_https_config

  # 确认
  while true
  do
  	TIME y "jellyfin 配置文件路径：$CONFIG_PATH"
  	TIME y "jellyfin 电影文件路径：$MOVIES_PATH"
  	TIME y "jellyfin 电视剧文件路径：$TVSHOWS_PATH"
  	TIME y "jellyfin 容器名：$JELLYFIN_CONTAINER_NAME"
  	TIME y "jellyfin 面板端口：$JELLYFIN_PORT"
  	TIME y "jellyfin https端口：$JELLYFIN_PORT1"
  	read -r -p "以上信息是否正确？[Y/n] " input52
  	case $input52 in
  		[yY][eE][sS]|[yY])
  			break
  			;;
  		[nN][oO]|[nN])
  			TIME w "即将返回上一步"
  			sleep 1
  			JELLYFIN_PORT="8096"
  			JELLYFIN_PORT1="8920"
  			input_container_jellyfin_config
  			input_container_jellyfin_name
  			input_container_jellyfin_webui_config
  			input_container_jellyfin_https_config
  			;;
  		*)
  			TIME r "输入错误，请输入[Y/n]"
  			;;
  	esac
  done

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

      log "列出所有宿主机上的容器"
      docker ps -a
    TIME g "-----------------------------------------------------------------"
    TIME g "|            jellyfin 启动需要一点点时间，请耐心等待！         |"
    sleep 10
    TIME g "|                    安装完成，自动退出脚本                     |"
    TIME g "|       jellyfin 默认端口为8096，如有修改请访问修改的端口       |"
    TIME g "|         访问方式为宿主机ip:端口(例192.168.2.1:8096)           |"
    TIME g "|   openwrt 需要先执行命令 chmod 777 /dev/dri/* 才能读取到显卡  |"
    TIME g "-----------------------------------------------------------------"
  exit 0
  ;;
 0) 
 clear 
 break
 ;;
 *) TIME r "----------------------------------"
    TIME r "|          Warning!!!            |"
    TIME r "|       请输入正确的选项!        |"
    TIME r "----------------------------------"
 for i in $(seq -w 1 -1 1)
   do
     #TIME r "\b\b$i";
     sleep 1;
   done
 clear
 ;;
 esac
 done
;;
#安装qbittorrent,aria2,ari2-pro
6)
clear
while [ "$flag" -eq 0 ]
do
#cat << EOF
TIME w "----------------------------------------"
TIME w "|****Please Enter Your Choice:[0-3]****|"
TIME w "|******** QBITTORRENT & ARIA2 *********|"
TIME w "----------------------------------------"
TIME w "(1) 安装 qbittorrent 增强版"
TIME w "(2) 安装 aria2"
TIME w "(3) 安装 aria2-pro"
TIME b "(0) 返回上级菜单"
#EOF
TIME r "<注>请使用 root 账户部署容器"
TIME r "<注> aria2 和 aria2-pro 二选一"
 read -p "Please enter your Choice[0-3]: " input6
 case $input6 in 
 1)
    TIME y " >>>>>>>>>>>开始安装 qbittorrent 增强版"
  # 创建映射文件夹
  input_container_qb_config() {
  echo -n -e "请输入 qbittorrent 增强版配置文件保存的绝对路径（示例：/home/qbittorrent)，回车默认为当前目录: "
  read qb_path
  if [ -z "$qb_path" ]; then
      QB_PATH=$QB_CONFIG_FOLDER
  elif [ -d "$qb_path" ]; then
      QB_PATH=$qb_path
  else
      #mkdir -p $qb_path
      QB_PATH=$qb_path
  fi
  #QB_CONFIG_PATH=$QB_PATH/qbittorrent
  echo -n -e "请输入下载文件保存的绝对路径（示例：/home/downloads)，回车默认为当前目录: "
  read downloads_path
  if [ -z "$downloads_path" ]; then
      DOWNLOADS_PATH=$QB_DOWNLOADS_FOLDER
  elif [ -d "$downloads_path" ]; then
      DOWNLOADS_PATH=$downloads_path
  else
      #mkdir -p $downloads_path
      DOWNLOADS_PATH=$downloads_path
  fi
  }
  input_container_qb_config

  # 输入容器名
  input_container_qb_name() {
    echo -n -e "请输入将要创建的容器名[默认为：qbittorrent]-> "
    read container_name
    if [ -z "$container_name" ]; then
        QB_CONTAINER_NAME="qbittorrent"
    else
        QB_CONTAINER_NAME=$container_name
    fi
  }
  input_container_qb_name

  # 确认
  while true
  do
  	TIME y "qbittorrent 配置文件路径：$QB_PATH"
  	TIME y "qbittorrent 下载文件路径：$DOWNLOADS_PATH"
  	TIME y "qbittorrent 容器名：$QB_CONTAINER_NAME"
  	read -r -p "以上信息是否正确？[Y/n] " input61
  	case $input61 in
  		[yY][eE][sS]|[yY])
  			break
  			;;
  		[nN][oO]|[nN])
  			TIME w "即将返回上一步"
  			sleep 1
  			input_container_qb_config
  			input_container_qb_name
  			;;
  		*)
  			TIME r "输入错误，请输入[Y/n]"
  			;;
  	esac
  done

  TIME y " >>>>>>>>>>>配置完成，开始安装 qbittorrent 增强版"
  log "1.开始创建配置文件目录"
  PATH_LIST=($CONFIG_PATH $DOWNLOADS_PATH)
  for i in ${PATH_LIST[@]}; do
      mkdir -p $i
  done

  log "2.开始创建容器并执行"
  docker run -dit \
      -v $QB_PATH:/config \
      -v $DOWNLOADS_PATH:/Downloads \
      -e QB_WEBUI_PORT=8989 \
      -p 6881:6881 -p 6881:6881/udp -p 8989:8989 \
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

      log "列出所有宿主机上的容器"
      docker ps -a
    TIME g "---------------------------------------------------------"
    TIME g "|      qbittorrent 启动需要一点点时间，请耐心等待！     |"
    sleep 10
    TIME g "|               安装完成，自动退出脚本                  |"
    TIME g "|  qbittorrent 默认端口为8989，如有修改请访问修改的端口 |"
    TIME g "|     访问方式为宿主机ip:端口(例192.168.2.1:8989)       |"
    TIME g "|         默认用户名admin，默认密码 adminadmin          |"
    TIME g "---------------------------------------------------------"
  exit 0
  ;;
 2)
    TIME y " >>>>>>>>>>>开始安装 aria2"
  # 创建映射文件夹
  input_container_aria2_config() {
  echo -n -e "请输入 aria2 配置文件保存的绝对路径（示例：/home/aria2)，回车默认为当前目录: "
  read aria2_path
  if [ -z "$aria2_path" ]; then
      ARIA2_PATH=$ARIA2_CONFIG_FOLDER
  elif [ -d "$aria2_path" ]; then
      ARIA2_PATH=$aria2_path
  else
      #mkdir -p $aria2_path
      ARIA2_PATH=$aria2_path
  fi
  echo -n -e "请输入下载文件保存的绝对路径（示例：/home/downloads)，回车默认为当前目录: "
  read downloads_path
  if [ -z "$downloads_path" ]; then
      DOWNLOADS_PATH=$ARIA2_DOWNLOADS_FOLDER
  elif [ -d "$downloads_path" ]; then
      DOWNLOADS_PATH=$downloads_path
  else
      #mkdir -p $downloads_path
      DOWNLOADS_PATH=$downloads_path
  fi
  }
  input_container_aria2_config
  
  # 输入容器名
  input_container_aria2_name() {
    echo -n -e "请输入将要创建的容器名[默认为：aria2]-> "
    read container_name
    if [ -z "$container_name" ]; then
        ARIA2_CONTAINER_NAME="aria2"
    else
        ARIA2_CONTAINER_NAME=$container_name
    fi
  }
  input_container_aria2_name
  
  # TOKEN
  input_container_aria2_token() {
  inp "是否修改密钥[默认 aria2]：\n1) 修改\n2) 不修改[默认]"
  opt
  read change_token
  if [ "$change_token" = "1" ]; then
      echo -n -e "输入想修改的密钥-> "
      read TOKEN
  fi
  }
  input_container_aria2_token

  # 确认
  while true
  do
  	TIME y "aria2 配置文件路径：$ARIA2_PATH"
  	TIME y "aria2 下载文件路径：$DOWNLOADS_PATH"
  	TIME y "aria2 容器名：$ARIA2_CONTAINER_NAME"
  	TIME y "aria2 密钥：$TOKEN"
  	read -r -p "以上信息是否正确？[Y/n] " input62
  	case $input62 in
  		[yY][eE][sS]|[yY])
  			break
  			;;
  		[nN][oO]|[nN])
  			TIME w "即将返回上一步"
  			sleep 1
  			input_container_aria2_config
  			input_container_aria2_name
  			input_container_aria2_token
  			;;
  		*)
  			TIME r "输入错误，请输入[Y/n]"
  			;;
  	esac
  done

  TIME y " >>>>>>>>>>>配置完成，开始安装 aria2"
  log "1.开始创建配置文件目录"
  PATH_LIST=($ARIA2_PATH $DOWNLOADS_PATH)
  for i in ${PATH_LIST[@]}; do
      mkdir -p $i
  done

  log "2.开始创建容器并执行"
  docker run -dit \
      -v $ARIA2_PATH:/config \
      -v $DOWNLOADS_PATH:/downloads \
      -e WEBUIPORT=8080 \
      -p 32516:32516 -p 32516:32516/udp -p 6800:6800 -p 8080:8080 \
      -e TZ=Asia/Shanghai \
      -e SECRET=$TOKEN \
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

      log "列出所有宿主机上的容器"
      docker ps -a
    TIME g "---------------------------------------------------------"
    TIME g "|         aria2 启动需要一点点时间，请耐心等待！        |"
    sleep 10
    TIME g "|                 安装完成，自动退出脚本                |"
    TIME g "|     aria2 默认端口为8080，如有修改请访问修改的端口    |"
    TIME g "|     访问方式为宿主机ip:端口(例192.168.2.1:8080)       |"
    TIME g "|              Aria密钥设置在面板如下位置               |"
    TIME g "|      AriaNg 设置 > RPC(IP:6800) > Aria2 RPC 密钥      |"
    TIME g "---------------------------------------------------------"
    TIME z "                  设置的密钥为 $TOKEN"
  exit 0
  ;;
 3)
    TIME y " >>>>>>>>>>>开始安装 aria2-pro"
  # 创建映射文件夹
  input_container_aria2_pro_config() {
  echo -n -e "请输入 aria2-pro 配置文件保存的绝对路径（示例：/home/aria2-pro)，回车默认为当前目录: "
  read aria2_pro_path
  if [ -z "$aria2_pro_path" ]; then
      ARIA2_PRO_PATH=$ARIA2_PRO_CONFIG_FOLDER
  elif [ -d "$aria2_pro_path" ]; then
      ARIA2_PRO_PATH=$aria2_pro_path
  else
      #mkdir -p $aria2_pro_path
      ARIA2_PRO_PATH=$aria2_pro_path
  fi
  echo -n -e "请输入下载文件保存的绝对路径（示例：/home/downloads)，回车默认为当前目录: "
  read downloads_path
  if [ -z "$downloads_path" ]; then
      DOWNLOADS_PATH=$ARIA2_PRO_DOWNLOADS_FOLDER
  elif [ -d "$downloads_path" ]; then
      DOWNLOADS_PATH=$downloads_path
  else
      #mkdir -p $downloads_path
      DOWNLOADS_PATH=$downloads_path
  fi
  }
  input_container_aria2_pro_config
  
  # 输入容器名
  input_container_aria2_pro_name() {
    echo -n -e "请输入将要创建的容器名[默认为：aria2-pro]-> "
    read container_name
    if [ -z "$container_name" ]; then
        ARIA2_PRO_CONTAINER_NAME="aria2-pro"
    else
        ARIA2_PRO_CONTAINER_NAME=$container_name
    fi
  }
  input_container_aria2_pro_name
  # 输入容器名(面板)
  input_container_ariang_name() {
    echo -n -e "请输入将要创建的面板容器名[默认为：ariang]-> "
    read container_name1
    if [ -z "$container_name1" ]; then
        ARIA2_PRO_WEBUI_NAME="ariang"
    else
        ARIA2_PRO_WEBUI_NAME=$container_name1
    fi
  }
  input_container_ariang_name
  # TOKEN
  input_container_aria2_pro_token() {
  inp "是否修改密钥[默认 aria2]：\n1) 修改\n2) 不修改[默认]"
  opt
  read change_token
  if [ "$change_token" = "1" ]; then
      echo -n -e "输入想修改的密钥-> "
      read TOKEN
  fi
  }
  input_container_aria2_pro_token

  # 确认
  while true
  do
  	TIME y "aria2_pro 配置文件路径：$ARIA2_PRO_PATH"
  	TIME y "aria2_pro 下载文件路径：$DOWNLOADS_PATH"
  	TIME y "aria2_pro 容器名：$ARIA2_PRO_CONTAINER_NAME"
  	TIME y "aria2_pro 面板名：$ARIA2_PRO_WEBUI_NAME"
  	TIME y "aria2_pro 密钥：$TOKEN"
  	read -r -p "以上信息是否正确？[Y/n] " input63
  	case $input63 in
  		[yY][eE][sS]|[yY])
  			break
  			;;
  		[nN][oO]|[nN])
  			TIME w "即将返回上一步"
  			sleep 1
  			input_container_aria2_pro_config
  			input_container_aria2_pro_name
  			input_container_ariang_name
  			input_container_aria2_pro_token
  			;;
  		*)
  			TIME r "输入错误，请输入[Y/n]"
  			;;
  	esac
  done

  TIME y " >>>>>>>>>>>配置完成，开始安装 aria2-pro"
  log "1.开始创建配置文件目录"
  PATH_LIST=($ARIA2_PRO_PATH $DOWNLOADS_PATH)
  for i in ${PATH_LIST[@]}; do
      mkdir -p $i
  done

  log "2.开始创建容器并执行"
  docker run -dit \
      -v $ARIA2_PRO_PATH:/config \
      -v $DOWNLOADS_PATH:/downloads \
      -p 6800:6800 -p 6888:6888 -p 6888:6888/udp \
      -e TZ=Asia/Shanghai \
      -e RPC_SECRET=$TOKEN \
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
      -p 6880:6880 \
      $ARIA2_PRO_WEBUI_DOCKER_IMG_NAME:$TAG

      if [ $? -ne 0 ] ; then
          cancelrun "** 错误：容器创建失败，请翻译以上英文报错，Google/百度尝试解决问题！"
      fi

      log "列出所有宿主机上的容器"
      docker ps -a
    TIME g "------------------------------------------------------------"
    TIME g "|         aria2-pro 启动需要一点点时间，请耐心等待！       |"
    sleep 10
    TIME g "|                    安装完成，自动退出脚本                |"
    TIME g "|    aria2-pro 默认端口为8080，如有修改请访问修改的端口    |"
    TIME g "|        访问方式为宿主机ip:端口(例192.168.2.1:6880)       |"
    TIME g "|                 Aria密钥设置在面板如下位置               |"
    TIME g "|        AriaNg 设置 > RPC(IP:6800) > Aria2 RPC 密钥       |"
    TIME g "------------------------------------------------------------"
    TIME z "                  设置的密钥为 $TOKEN"
  exit 0
  ;;
 0) 
 clear 
 break
 ;;
 *) TIME r "----------------------------------"
    TIME r "|          Warning!!!            |"
    TIME r "|       请输入正确的选项!        |"
    TIME r "----------------------------------"
 for i in $(seq -w 1 -1 1)
   do
     #TIME r "\b\b$i";
     sleep 1;
   done
 clear
 ;;
 esac
 done
;;
#安装telethon
7)
clear
while [ "$flag" -eq 0 ]
do
#cat << EOF
TIME w "----------------------------------------"
TIME w "|****Please Enter Your Choice:[0-2]****|"
TIME w "|************** TELETHON **************|"
TIME w "----------------------------------------"
TIME w "(1) linxu系统、X86 的 openwrt、群辉等请选择 1"
TIME w "(2) N1 的 EMMC 上运行的 openwrt 请选择 2"
TIME b "(0) 返回上级菜单"
#EOF
TIME r "<注>选择1或2后，如果不明白如何选择或输入，请狂按回车！"
 read -p "Please enter your choice[0-2]: " input7
 case $input7 in 
 1)
  TIME y " >>>>>>>>>>>开始安装 telethon"
  # 创建映射文件夹
  input_container_telethon1_config() {
  echo -n -e "请输入 telethon 配置文件保存的绝对路径（示例：/home/telethon)，回车默认为当前目录: "
  read tg_path
  if [ -z "$tg_path" ]; then
      TG_PATH=$TG_SHELL_FOLDER
  elif [ -d "$tg_path" ]; then
      TG_PATH=$tg_path
  else
      #mkdir -p $tg_path
      TG_PATH=$tg_path
  fi
  CONFIG_PATH=$TG_PATH
  }
  input_container_telethon1_config

  # 输入容器名
  input_container_telethon1_name() {
    echo -n -e "请输入将要创建的容器名[默认为：telethon]-> "
    read container_name
    if [ -z "$container_name" ]; then
        TG_CONTAINER_NAME="telethon"
    else
        TG_CONTAINER_NAME=$container_name
    fi
  }
  input_container_telethon1_name

  # 确认
  while true
  do
  	TIME y "telethon 配置文件路径：$CONFIG_PATH"
  	TIME y "telethon 容器名：$TG_CONTAINER_NAME"
  	read -r -p "以上信息是否正确？[Y/n] " input71
  	case $input71 in
  		[yY][eE][sS]|[yY])
  			break
  			;;
  		[nN][oO]|[nN])
  			TIME w "即将返回上一步"
  			sleep 1
  			input_container_telethon1_config
  			input_container_telethon1_name
  			;;
  		*)
  			TIME r "输入错误，请输入[Y/n]"
  			;;
  	esac
  done

  TIME y " >>>>>>>>>>>配置完成，开始安装 telethon"
  log "1.开始创建配置文件目录"
  PATH_LIST=($CONFIG_PATH)
  for i in ${PATH_LIST[@]}; do
      mkdir -p $i
  done

  log "2.开始创建容器并执行"
  docker run -dit \
      -v $CONFIG_PATH:/telethon \
      --name $TG_CONTAINER_NAME \
      --hostname $TG_CONTAINER_NAME \
      --restart always \
      --net host \
      $TG_DOCKER_IMG_NAME:$TAG

      if [ $? -ne 0 ] ; then
          cancelrun "** 错误：容器创建失败，请翻译以上英文报错，Google/百度尝试解决问题！"
      fi

      log "列出所有宿主机上的容器"
      docker ps -a
    TIME g "-----------------------------------------------------------"
    TIME g "|         telethon 启动需要一点点时间，请耐心等待！       |"
    sleep 10
    TIME g "|                安装完成，自动退出脚本                   |"
    TIME g "| 使用教程https://hub.docker.com/r/kissyouhunter/telethon |"
    TIME g "-----------------------------------------------------------"
  exit 0
  ;;
 2)  
  TIME y " >>>>>>>>>>>开始安装 telethon 到 N1 的 /mnt/mmcblk2p4/"
  # 创建映射文件夹
  input_container_telethon2_config() {
  echo -n -e "请输入 telethon 存储的文件夹名称（如：telethon)，回车默认为 telethon: "
  read tg_path
  if [ -z "$tg_path" ]; then
      TG_PATH=$N1_TG_FOLDER
  elif [ -d "$tg_path" ]; then
      TG_PATH=/mnt/mmcblk2p4/$tg_path
  else
      #mkdir -p /mnt/mmcblk2p4/$tg_path
      TG_PATH=/mnt/mmcblk2p4/$tg_path
  fi
  CONFIG_PATH=$TG_PATH
  }
  input_container_telethon2_config
  
  # 输入容器名
  input_container_telethon2_name() {
    echo -n -e "请输入将要创建的容器名[默认为：telethon]-> "
    read container_name
    if [ -z "$container_name" ]; then
        TG_CONTAINER_NAME="telethon"
    else
        TG_CONTAINER_NAME=$container_name
    fi
  }
  input_container_telethon2_name

  # 确认
  while true
  do
  	TIME y "telethon 配置文件路径：$CONFIG_PATH"
  	TIME y "telethon 容器名：$TG_CONTAINER_NAME"
  	read -r -p "以上信息是否正确？[Y/n] " input72
  	case $input72 in
  		[yY][eE][sS]|[yY])
  			break
  			;;
  		[nN][oO]|[nN])
  			TIME w "即将返回上一步"
  			sleep 1
  			input_container_telethon2_config
  			input_container_telethon2_name
  			;;
  		*)
  			TIME r "输入错误，请输入[Y/n]"
  			;;
  	esac
  done

  TIME y " >>>>>>>>>>>配置完成，开始安装 telethon"
  log "1.开始创建配置文件目录"
  PATH_LIST=($CONFIG_PATH)
  for i in ${PATH_LIST[@]}; do
      mkdir -p $i
  done

  log "3.开始创建容器并执行"
  docker run -dit \
      -v $CONFIG_PATH:/telethon \
      --name $TG_CONTAINER_NAME \
      --hostname $TG_CONTAINER_NAME \
      --restart always \
      --net host \
      $TG_DOCKER_IMG_NAME:$TAG

      if [ $? -ne 0 ] ; then
          cancelrun "** 错误：容器创建失败，请翻译以上英文报错，Google/百度尝试解决问题！"
      fi

      log "列出所有宿主机上的容器"
      docker ps -a
    TIME g "-----------------------------------------------------------"
    TIME g "|         telethon 启动需要一点点时间，请耐心等待！       |"
    sleep 10
    TIME g "|                安装完成，自动退出脚本                   |"
    TIME g "| 使用教程https://hub.docker.com/r/kissyouhunter/telethon |"
    TIME g "-----------------------------------------------------------"
  exit 0
  ;;
 0) 
 clear 
 break
 ;;
 *) TIME r "----------------------------------"
    TIME r "|          Warning!!!            |"
    TIME r "|       请输入正确的选项!        |"
    TIME r "----------------------------------"
 for i in $(seq -w 1 -1 1)
   do
     #TIME r "\b\b$i";
     sleep 1;
   done
 clear
 ;;
 esac
 done
 ;;
#安装adguardhome
8)
clear
while [ "$flag" -eq 0 ]
do
#cat << EOF
TIME w "----------------------------------------"
TIME w "|****Please Enter Your Choice:[0-3]****|"
TIME w "|************* ADGUARDHOME ************|"
TIME w "----------------------------------------"
TIME w "(1) linxu系统、X86 的 openwrt、群辉等（docker 版）请选择 1"
TIME w "(2) N1 的 EMMC 上运行的 openwrt（docker 版）请选择 2"
TIME w "(3) linxu系统（非docker版，openwrt不可运行）"
TIME b "(0) 返回上级菜单"
#EOF
TIME r "<注>选择1或2后，如果不明白如何选择或输入，请狂按回车！"
 read -p "Please enter your choice[0-3]: " input8
 case $input8 in 
 1)
  TIME y " >>>>>>>>>>>开始安装 adguardhome（docker 版，x86 系统）"
  # 创建映射文件夹
  input_container_adg1_config() {
  echo -n -e "请输入 adguardhome 配置文件保存的绝对路径（示例：/home/adguardhome)，回车默认为当前目录: "
  read adg_path
  if [ -z "$adg_path" ]; then
      ADG_PATH=$ADG_CONFIG_FOLDER
  elif [ -d "$adg_path" ]; then
      ADG_PATH=$adg_path
  else
      #mkdir -p ${adg_path}/work
      #mkdir -p ${adg_path}/conf
      ADG_PATH=$adg_path
  fi
  CONFIG_PATH=$ADG_PATH
  WORK_PATH=$ADG_PATH/work
  CONF_PATH=$ADG_PATH/conf
  }
  input_container_adg1_config

  # 输入容器名
  input_container_adg1_name() {
    echo -n -e "请输入将要创建的容器名[默认为：adguardhome]-> "
    read container_name
    if [ -z "$container_name" ]; then
        ADG_CONTAINER_NAME="adguardhome"
    else
        ADG_CONTAINER_NAME=$container_name
    fi
  }
  input_container_adg1_name

  # 确认
  while true
  do
  	TIME y "adguardhome 配置文件路径：$CONFIG_PATH"
  	TIME y "adguardhome 容器名：$ADG_CONTAINER_NAME"
  	read -r -p "以上信息是否正确？[Y/n] " input81
  	case $input81 in
  		[yY][eE][sS]|[yY])
  			break
  			;;
  		[nN][oO]|[nN])
  			TIME w "即将返回上一步"
  			sleep 1
  			input_container_adg1_config
  			input_container_adg1_name
  			;;
  		*)
  			TIME r "输入错误，请输入[Y/n]"
  			;;
  	esac
  done

  TIME y " >>>>>>>>>>>配置完成，开始安装 adguardhome（docker 版，x86 系统）"
  log "1.开始创建配置文件目录"
  PATH_LIST=($CONFIG_PATH $WORK_PATH $CONF_PATH)
  for i in ${PATH_LIST[@]}; do
      mkdir -p $i
  done

  log "2.开始创建容器并执行"
  docker run -dit \
      -v $WORK_PATH:/opt/adguardhome/work \
      -v $CONF_PATH:/opt/adguardhome/conf \
      --name $ADG_CONTAINER_NAME \
      --hostname $ADG_CONTAINER_NAME \
      --restart always \
      --net host \
      $ADG_DOCKER_IMG_NAME:$TAG

      if [ $? -ne 0 ] ; then
          cancelrun "** 错误：容器创建失败，请翻译以上英文报错，Google/百度尝试解决问题！"
      fi

      log "列出所有宿主机上的容器"
      docker ps -a
    TIME g "-----------------------------------------------------------"
    TIME g "|       adguardhome 启动需要一点点时间，请耐心等待！      |"
    sleep 10
    TIME g "|                安装完成，自动退出脚本                   |"
    TIME g "|            首次启动请访问宿主机 IP:3000                 |"
    TIME g "-----------------------------------------------------------"
  exit 0
  ;;
 2)  
  TIME y " >>>>>>>>>>>开始安装 adguardhome（docker 版）到 N1 的 /mnt/mmcblk2p4/"
  # 创建映射文件夹
  input_container_adg2_config() {
  echo -n -e "请输入 adguardhome 存储文件名名称（示例：adguardhome)，回车默认为adguardhome: "
  read adg_path
  if [ -z "$adg_path" ]; then
      ADG_PATH=$N1_ADG_FOLDER
  elif [ -d "$adg_path" ]; then
      ADG_PATH=/mnt/mmcblk2p4/$adg_path
  else
      #mkdir -p /mnt/mmcblk2p4/$adg_path/work
      #mkdir -p /mnt/mmcblk2p4/$adg_path/conf
      ADG_PATH=/mnt/mmcblk2p4/$adg_path
  fi
  CONFIG_PATH=$ADG_PATH
  WORK_PATH=$ADG_PATH/work
  CONF_PATH=$ADG_PATH/conf
  }
  input_container_adg2_config

  # 输入容器名
  input_container_adg2_name() {
    echo -n -e "请输入将要创建的容器名[默认为：adguardhome]-> "
    read container_name
    if [ -z "$container_name" ]; then
        ADG_CONTAINER_NAME="adguardhome"
    else
        ADG_CONTAINER_NAME=$container_name
    fi
  }
  input_container_adg2_name

  # 确认
  while true
  do
  	TIME y "adguardhome 配置文件路径：$CONFIG_PATH"
  	TIME y "adguardhome 容器名：$ADG_CONTAINER_NAME"
  	read -r -p "以上信息是否正确？[Y/n] " input82
  	case $input82 in
  		[yY][eE][sS]|[yY])
  			break
  			;;
  		[nN][oO]|[nN])
  			TIME w "即将返回上一步"
  			sleep 1
  			input_container_adg2_config
  			input_container_adg2_name
  			;;
  		*)
  			TIME r "输入错误，请输入[Y/n]"
  			;;
  	esac
  done

  TIME y " >>>>>>>>>>>配置完成，开始安装 adguardhome（docker 版）到 N1 的 /mnt/mmcblk2p4/"
  log "1.开始创建配置文件目录"
  PATH_LIST=($CONFIG_PATH $WORK_PATH $CONF_PATH)
  for i in ${PATH_LIST[@]}; do
      mkdir -p $i
  done

  log "3.开始创建容器并执行"
  docker run -dit \
      -v $WORK_PATH:/opt/adguardhome/work \
      -v $CONF_PATH:/opt/adguardhome/conf \
      --name $ADG_CONTAINER_NAME \
      --hostname $ADG_CONTAINER_NAME \
      --restart always \
      --net host \
      $ADG_DOCKER_IMG_NAME:$TAG

      if [ $? -ne 0 ] ; then
          cancelrun "** 错误：容器创建失败，请翻译以上英文报错，Google/百度尝试解决问题！"
      fi

      log "列出所有宿主机上的容器"
      docker ps -a
    TIME g "-----------------------------------------------------------"
    TIME g "|       adguardhome启动需要一点点时间，请耐心等待！       |"
    sleep 10
    TIME g "|                安装完成，自动退出脚本                   |"
    TIME g "|            首次启动请访问宿主机 IP:3000                 |"
    TIME g "-----------------------------------------------------------"
  exit 0
  ;;
 3)  
  TIME y " >>>>>>>>>>>开始安装 adguardhome（非 docker 版）"
  apt update && apt install curl -y
  curl -s -S -L https://raw.githubusercontent.com/AdguardTeam/AdGuardHome/master/scripts/install.sh | sh -s -- -v
    TIME g "-----------------------------------------------------------"
    TIME g "|       adguardhome 启动需要一点点时间，请耐心等待！      |"
    sleep 10
    TIME g "|                安装完成，自动退出脚本                   |"
    TIME g "|            首次启动请访问宿主机 IP:3000                 |"
    TIME g "-----------------------------------------------------------"
  exit 0
  ;;
 0) 
 clear 
 break
 ;;
 *) TIME r "----------------------------------"
    TIME r "|          Warning!!!            |"
    TIME r "|       请输入正确的选项!        |"
    TIME r "----------------------------------"
 for i in $(seq -w 1 -1 1)
   do
     #TIME r "\b\b$i";
     sleep 1;
   done
 clear
 ;;
 esac
 done
;; 
#安装x-ui
9)
clear
while [ "$flag" -eq 0 ]
do
#cat << EOF
TIME w "----------------------------------------"
TIME w "|****Please Enter Your Choice:[0-2]****|"
TIME w "|**************** X-UI ****************|"
TIME w "----------------------------------------"
TIME w "(1) x-ui docker 版本"
TIME w "(2) x-ui 直装版本"
TIME b "(0) 返回上级菜单"
#EOF
 read -p "Please enter your choice[0-2]: " input9
 case $input9 in 
 1)
  TIME y " >>>>>>>>>>>开始安装 x-ui docker 版本"
  # 创建映射文件夹
  input_container_xui_config() {
  echo -n -e "请输入x-ui配置文件保存的绝对路径（示例：/home/x-ui)，回车默认为当前目录: "
  read xui_path
  if [ -z "$xui_path" ]; then
      XUI_PATH=$XUI_CONFIG_FOLDER
  elif [ -d "$xui_path" ]; then
      XUI_PATH=$xui_path
  else
      #mkdir -p ${xui_path}/db
      #mkdir -p ${xui_path}/cert
      XUI_PATH=$xui_path
  fi
  CONFIG_PATH=$XUI_PATH
  DB_PATH=$XUI_PATH/db
  CERT_PATH=$XUI_PATH/cert
  }
  input_container_xui_config

  # 输入容器名
  input_container_xui_name() {
    echo -n -e "请输入将要创建的容器名[默认为：x-ui]-> "
    read container_name
    if [ -z "$container_name" ]; then
        XUI_CONTAINER_NAME="x-ui"
    else
        XUI_CONTAINER_NAME=$container_name
    fi
  }
  input_container_xui_name

  # image 版本
  input_container_xui_image() {
    echo -n -e "请输入将要拉取镜像[默认为：最新版本latest，输入dev为尝鲜版]-> "
    read image_name
    if [ -z "$image_name" ]; then
        XUI_IMAGE_NAME="latest"
    elif [ "$image_name" == "latest" ]; then
        XUI_IMAGE_NAME="latest"
    else
        XUI_IMAGE_NAME=$DEV
    fi
  }
  input_container_xui_image

  # 确认
  while true
  do
  	TIME y "x-ui 配置文件路径：$CONFIG_PATH"
  	TIME y "x-ui 容器名：$XUI_CONTAINER_NAME"
    TIME y "x-ui 镜像版本：$XUI_IMAGE_NAME"
  	read -r -p "以上信息是否正确？[Y/n] " input91
  	case $input91 in
  		[yY][eE][sS]|[yY])
  			break
  			;;
  		[nN][oO]|[nN])
  			TIME w "即将返回上一步"
  			sleep 1
  			input_container_xui_config
  			input_container_xui_name
            input_container_xui_image
  			;;
  		*)
  			TIME r "输入错误，请输入[Y/n]"
  			;;
  	esac
  done

  TIME y " >>>>>>>>>>>配置完成，开始安装 x-ui"
  log "1.开始创建配置文件目录"
  PATH_LIST=($CONFIG_PATH $DB_PATH $CERT_PATH)
  for i in ${PATH_LIST[@]}; do
      mkdir -p $i
  done

  log "2.开始创建容器并执行"
  docker run -dit \
      -v $DB_PATH:/etc/x-ui/ \
      -v $CERT_PATH:/root/ \
      --name $XUI_CONTAINER_NAME \
      --hostname $XUI_CONTAINER_NAME \
      --restart always \
      --net host \
      $XUI_DOCKER_IMG_NAME:$XUI_IMAGE_NAME

      if [ $? -ne 0 ] ; then
          cancelrun "** 错误：容器创建失败，请翻译以上英文报错，Google/百度尝试解决问题！"
      fi

      log "列出所有宿主机上的容器"
      docker ps -a
    TIME g "-----------------------------------------------------------"
    TIME g "|            x-ui 启动需要一点点时间，请耐心等待！        |"
    sleep 10
    TIME g "|                安装完成，自动退出脚本                   |"
    TIME g "|      默认账号：admin 默认密码：admin 默认端口：54321    |"
    TIME g "-----------------------------------------------------------"
  exit 0
  ;;
 2)
  TIME y " >>>>>>>>>>>开始安装 x-ui 直装版本"
  bash <(curl -Ls https://raw.githubusercontent.com/vaxilu/x-ui/master/install.sh)
  exit 0
  ;;
 0) 
 clear 
 break
 ;;
 *) TIME r "----------------------------------"
    TIME r "|          Warning!!!            |"
    TIME r "|       请输入正确的选项!        |"
    TIME r "----------------------------------"
 for i in $(seq -w 1 -1 1)
   do
     #TIME r "\b\b$i";
     sleep 1;
   done
 clear
 ;;
 esac
 done
;;
0)
clear
exit 0
;;
#安装aapanel
10)
clear
while [ "$flag" -eq 0 ]
do
#cat << EOF
TIME w "----------------------------------------"
TIME w "|****Please Enter Your Choice:[0-2]****|"
TIME w "|******** AAPANEL(宝塔国际版) *********|"
TIME w "----------------------------------------"
TIME w "(1) linxu系统、X86的 openwrt、群辉等请选择 1"
TIME w "(2) N1 的 EMMC 上运行的 openwrt 请选择 2"
TIME b "(0) 返回上级菜单"
#EOF
TIME r "<注>选择1或2后，如果不明白如何选择或输入，请狂按回车！"
 read -p "Please enter your choice[0-2]: " input10
 case $input10 in 
 1)
  TIME y " >>>>>>>>>>>开始安装aapanel"
  # 创建映射文件夹
  input_container_aapanel1_config() {
  echo -n -e "请输入 aapanel 配置文件保存的绝对路径（示例：/home/aapanel)，回车默认为当前目录: "
  read aapanel_path
  if [ -z "$aapanel_path" ]; then
      AAPANEL_PATH=$AAPANEL_CONFIG_FOLDER
  elif [ -d "$aapanel_path" ]; then
      AAPANEL_PATH=$aapanel_path
  else
      AAPANEL_PATH=$aapanel_path
  fi
  CONFIG_PATH=$AAPANEL_PATH
  WEBSITE_DATA_PATH=$AAPANEL_PATH/website_data
  MYSQL_DATA_PATH=$AAPANEL_PATH/mysql_data
  VHOST_PATH=$AAPANEL_PATH/vhost
  }
  input_container_aapanel1_config

  # 输入容器名
  input_container_aapanel1_name() {
    echo -n -e "请输入将要创建的容器名[默认为：aapanel]-> "
    read container_name
    if [ -z "$container_name" ]; then
        AAPANEL_CONTAINER_NAME="aapanel"
    else
        AAPANEL_CONTAINER_NAME=$container_name
    fi
  }
  input_container_aapanel1_name

  # 确认
  while true
  do
  	TIME y "aapanel 配置文件路径：$CONFIG_PATH"
  	TIME y "aapanel 容器名：$AAPANEL_CONTAINER_NAME"
  	read -r -p "以上信息是否正确？[Y/n] " input101
  	case $input101 in
  		[yY][eE][sS]|[yY])
  			break
  			;;
  		[nN][oO]|[nN])
  			TIME w "即将返回上一步"
  			sleep 1
  			input_container_aapanel1_config
  			input_container_aapanel1_name
  			;;
  		*)
  			TIME r "输入错误，请输入[Y/n]"
  			;;
  	esac
  done

  TIME y " >>>>>>>>>>>配置完成，开始安装 aapanel"
  log "1.开始创建配置文件目录"
  PATH_LIST=($MYSQL_DATA_PATH)
  for i in ${PATH_LIST[@]}; do
      mkdir -p $i
  done
  PATH_LIST=($WEBSITE_DATA_PATH)
  for i in ${PATH_LIST[@]}; do
      mkdir -p $i
  done
  PATH_LIST=($VHOST_PATH)
  for i in ${PATH_LIST[@]}; do
      mkdir -p $i
  done

  log "2.开始创建容器并执行"
  docker run -dit \
      -v $WEBSITE_DATA_PATH:/www/wwwroot \
      -v $MYSQL_DATA_PATH:/www/server/data \
      -v $VHOST_PATH:/www/server/panel/vhost \
      --name $AAPANEL_CONTAINER_NAME \
      --hostname $AAPANEL_CONTAINER_NAME \
      --restart always \
      --net host \
      $AAPANEL_DOCKER_IMG_NAME:$AAPANEL_TAG

      if [ $? -ne 0 ] ; then
          cancelrun "** 错误：容器创建失败，请翻译以上英文报错，Google/百度尝试解决问题！"
      fi

      log "列出所有宿主机上的容器"
      docker ps -a
    TIME g "-----------------------------------------------------------"
    TIME g "|         aapanel 启动需要一点点时间，请耐心等待！        |"
    sleep 10
    TIME g "|                安装完成，自动退出脚本                   |"
    TIME g "|            访问方式为 宿主机ip:7800/aapanel/            |"
    TIME g "|        默认账号：aapanel  默认密码：aapanel123          |"
    TIME g "|   基础教程 https://wiki.991231.xyz/zh/docker/aapanel    |"
    TIME g "-----------------------------------------------------------"
  exit 0
  ;;
 2)  
  TIME y " >>>>>>>>>>>开始安装 aapanel 到 N1 的 /mnt/mmcblk2p4/"
  # 创建映射文件夹
  input_container_aapanel2_config() {
  echo -n -e "请输入 aapanel 存储的文件夹名称（如：aapanel)，回车默认为 aapanel: "
  read aapanel_path
  if [ -z "$aapanel_path" ]; then
      AAPANEL_PATH=$N1_AAPANEL_FOLDER
  elif [ -d "$aapanel_path" ]; then
      AAPANEL_PATH=/mnt/mmcblk2p4/$aapanel_path
  else
      #mkdir -p /mnt/mmcblk2p4/$aapanel_path
      AAPANEL_PATH=/mnt/mmcblk2p4/$aapanel_path
  fi
  CONFIG_PATH=$AAPANEL_PATH
  WEBSITE_DATA_PATH=$AAPANEL_PATH/website_data
  MYSQL_DATA_PATH=$AAPANEL_PATH/mysql_data
  VHOST_PATH=$AAPANEL_PATH/vhost
  }
  input_container_aapanel2_config
  
  # 输入容器名
  input_container_aapanel2_name() {
    echo -n -e "请输入将要创建的容器名[默认为：aapanel]-> "
    read container_name
    if [ -z "$container_name" ]; then
        AAPANEL_CONTAINER_NAME="aapanel"
    else
        AAPANEL_CONTAINER_NAME=$container_name
    fi
  }
  input_container_aapanel2_name

  # 确认
  while true
  do
  	TIME y "aapanel 配置文件路径：$CONFIG_PATH"
  	TIME y "aapanel 容器名：$AAPANEL_CONTAINER_NAME"
  	read -r -p "以上信息是否正确？[Y/n] " input102
  	case $input102 in
  		[yY][eE][sS]|[yY])
  			break
  			;;
  		[nN][oO]|[nN])
  			TIME w "即将返回上一步"
  			sleep 1
  			input_container_aapanel2_config
  			input_container_aapanel2_name
  			;;
  		*)
  			TIME r "输入错误，请输入[Y/n]"
  			;;
  	esac
  done

  TIME y " >>>>>>>>>>>配置完成，开始安装 aapanel"
  log "1.开始创建配置文件目录"
  PATH_LIST=($MYSQL_DATA_PATH)
  for i in ${PATH_LIST[@]}; do
      mkdir -p $i
  done
  PATH_LIST=($WEBSITE_DATA_PATH)
  for i in ${PATH_LIST[@]}; do
      mkdir -p $i
  done
  PATH_LIST=($VHOST_PATH)
  for i in ${PATH_LIST[@]}; do
      mkdir -p $i
  done

  log "3.开始创建容器并执行"
  docker run -dit \
      -v $WEBSITE_DATA_PATH:/www/wwwroot \
      -v $MYSQL_DATA_PATH:/www/server/data \
      -v $VHOST_PATH:/www/server/panel/vhost \
      --name $AAPANEL_CONTAINER_NAME \
      --hostname $AAPANEL_CONTAINER_NAME \
      --restart always \
      --net host \
      $AAPANEL_DOCKER_IMG_NAME:$AAPANEL_TAG

      if [ $? -ne 0 ] ; then
          cancelrun "** 错误：容器创建失败，请翻译以上英文报错，Google/百度尝试解决问题！"
      fi

      log "列出所有宿主机上的容器"
      docker ps -a
    TIME g "-----------------------------------------------------------"
    TIME g "|         aapanel 启动需要一点点时间，请耐心等待！        |"
    sleep 10
    TIME g "|                安装完成，自动退出脚本                   |"
    TIME g "|            访问方式为 宿主机ip:7800/aapanel/            |"
    TIME g "|        默认账号：aapanel  默认密码：aapanel123          |"
    TIME g "|   基础教程 https://wiki.991231.xyz/zh/docker/aapanel    |"
    TIME g "-----------------------------------------------------------"
  exit 0
  ;;
 0) 
 clear 
 break
 ;;
 *) TIME r "----------------------------------"
    TIME r "|          Warning!!!            |"
    TIME r "|       请输入正确的选项!        |"
    TIME r "----------------------------------"
 for i in $(seq -w 1 -1 1)
   do
     #TIME r "\b\b$i";
     sleep 1;
   done
 clear
 ;;
 esac
 done
;;
#安装MaiARK
11)
clear
while [ "$flag" -eq 0 ]
do
#cat << EOF
TIME w "----------------------------------------"
TIME w "|****Please Enter Your Choice:[0-2]****|"
TIME w "|************** MaiARK ****************|"
TIME w "----------------------------------------"
TIME w "(1) linxu系统、openwrt、群辉等请选择 1"
TIME w "(2) N1 的 EMMC 上运行的 openwrt 请选择 2"
TIME b "(0) 返回上级菜单"
#EOF
TIME r "<注>选择后，如果不明白如何选择或输入，请狂按回车！"
 read -p "Please enter your choice[0-2]: " input11
 case $input11 in 
 1)
  TIME y " >>>>>>>>>>>开始安装 MaiARK"
  # 创建映射文件夹
  input_container_maiark1_config() {
  echo -n -e "请输入 MaiARK 配置文件保存的绝对路径（示例：/home/MaiARK)，回车默认为当前目录: "
  read maiark_path
  if [ -z "$maiark_path" ]; then
      MAIARK_PATH=$MAIARK_CONFIG_FOLDER
  elif [ -d "$maiark_path" ]; then
      MAIARK_PATH=$maiark_path
  else
      MAIARK_PATH=$maiark_path
  fi
  CONFIG_PATH=$MAIARK_PATH
  }
  input_container_maiark1_config

  # 输入容器名
  input_container_maiark1_name() {
    echo -n -e "请输入将要创建的容器名[默认为：maiark]-> "
    read container_name
    if [ -z "$container_name" ]; then
        MAIARK_CONTAINER_NAME="maiark"
    else
        MAIARK_CONTAINER_NAME=$container_name
    fi
  }
  input_container_maiark1_name

  # 网络模式
  input_container_maiark1_network_config() {
  inp "请选择容器的网络类型：\n1) host\n2) bridge[默认]"
  opt
  read net
  if [ "$net" = "1" ]; then
      NETWORK="host"
      MAIARK_PORT="8082"
  fi
  
  if [ "$NETWORK" = "bridge" ]; then
      inp "是否修改 MaiMRK 端口[默认 8082]：\n1) 修改\n2) 不修改[默认]"
      opt
      read change_maiark_port
      if [ "$change_maiark_port" = "1" ]; then
          echo -n -e "输入想修改的端口->"
          read MAIARK_PORT
          echo $MAIARK_PORT
      else
          MAIARK_PORT="8082"
      fi
  fi
  }
  input_container_maiark1_network_config

  # 确认
  while true
  do
  	TIME y "MaiARK 配置文件路径：$CONFIG_PATH"
  	TIME y "Maiark 容器名：$MAIARK_CONTAINER_NAME"
    TIME y "Maiark 端口：$MAIARK_PORT"
    TIME r "确认下映射路径是否正确！！！"
  	read -r -p "以上信息是否正确？[Y/n] " input111
  	case $input111 in
  		[yY][eE][sS]|[yY])
  			break
  			;;
  		[nN][oO]|[nN])
  			TIME w "即将返回上一步"
  			sleep 1
  			input_container_maiark1_config
  			input_container_maiark1_name
            input_container_maiark1_network_config
            MAIARK_PORT="8082"
  			;;
  		*)
  			TIME r "输入错误，请输入[Y/n]"
  			;;
  	esac
  done

  TIME y " >>>>>>>>>>>配置完成，开始安装 MaiARK"
  log "1.开始创建配置文件目录"
  PATH_LIST=($CONFIG_PATH)
  for i in ${PATH_LIST[@]}; do
      mkdir -p $i
  done

  log "2.开始创建容器并执行"
  docker pull $MAIARK_DOCKER_IMG_NAME:$TAG
  docker run -d \
      -v $CONFIG_PATH:/MaiARK \
      --name $MAIARK_CONTAINER_NAME \
      --hostname $MAIARK_CONTAINER_NAME \
      --restart always \
      --network $NETWORK \
      -p $MAIARK_PORT:8082 \
      $MAIARK_DOCKER_IMG_NAME:$TAG

      if [ $? -ne 0 ] ; then
          cancelrun "** 错误：容器创建失败，请翻译以上英文报错，Google/百度尝试解决问题！"
      fi

      log "列出所有宿主机上的容器"
      docker ps -a
    TIME g "------------------------------------------------------------------------------"
    TIME g "|                  MaiARK 启动需要一点点时间，请耐心等待！                   |"
    sleep 10
    TIME g "|                          安装完成，自动退出脚本                            |"
    TIME g "|                          访问方式为 宿主机ip:$MAIARK_PORT                          |"
    TIME g "|             请先配置好映射文件夹下的 arkconfig.json 再重启容器             |"
    TIME r "| 桥接模式请不要修改 config 下的端口8082，host模式随意(前提是指定自己在干啥) |"
    TIME r "|                请看清映射的文件夹路径去找 config 文件                      |"
    TIME r "|   op用户出现“docker0: iptables: No chain/target/match by that name”错误    |"
    TIME r "|              输入命令“/etc/init.d/dockerd restart” 重启 docker             |"
    TIME r "|                     再输入“docker start $MAIARK_CONTAINER_NAME” 启动容器                   |"
    TIME r "|       op用户出现容器正常启动，但web界面无法方法Turbo ACC 网络加速设置      |"
    TIME r "|进入“网络——Turbo ACC 网络加速设置” 开启或关闭“全锥型 NAT”就可正常访问web界面|"
    TIME g "------------------------------------------------------------------------------"
  exit 0
  ;;
 2)  
  TIME y " >>>>>>>>>>>开始安装 MaiARK 到 N1 的 /mnt/mmcblk2p4/"
  # 创建映射文件夹
  input_container_maiark3_config() {
  echo -n -e "请输入 MaiARK 存储的文件夹名称（如：MaiARK)，回车默认为 MaiARK: "
  read maiark_path
  if [ -z "$maiark_path" ]; then
      MAIARK_PATH=$N1_MAIARK_FOLDER
  elif [ -d "$maiark_path" ]; then
      MAIARK_PATH=/mnt/mmcblk2p4/$maiark_path
  else
      MAIARK_PATH=/mnt/mmcblk2p4/$maiark_path
  fi
  CONFIG_PATH=$MAIARK_PATH
  }
  input_container_maiark3_config
  
  # 输入容器名
  input_container_maiark3_name() {
    echo -n -e "请输入将要创建的容器名[默认为：maiark]-> "
    read container_name
    if [ -z "$container_name" ]; then
        MAIARK_CONTAINER_NAME="maiark"
    else
        MAIARK_CONTAINER_NAME=$container_name
    fi
  }
  input_container_maiark3_name

  # 网络模式
  input_container_maiark3_network_config() {
  inp "请选择容器的网络类型：\n1) host\n2) bridge[默认]"
  opt
  read net
  if [ "$net" = "1" ]; then
      NETWORK="host"
      MAIARK_PORT="8082"
  fi
  
  if [ "$NETWORK" = "bridge" ]; then
      inp "是否修改 MaiMRK 端口[默认 8082]：\n1) 修改\n2) 不修改[默认]"
      opt
      read change_maiark_port
      if [ "$change_maiark_port" = "1" ]; then
          echo -n -e "输入想修改的端口->"
          read MAIARK_PORT
      else
          MAIARK_PORT="8082"
      fi
  fi
  }
  input_container_maiark3_network_config


  # 确认
  while true
  do
  	TIME y "MaiARK 配置文件路径：$CONFIG_PATH"
  	TIME y "MaiARK 容器名：$MAIARK_CONTAINER_NAME"
    TIME y "Maiark 端口：$MAIARK_PORT"
    TIME r "确认下映射路径是否正确！！！"
  	read -r -p "以上信息是否正确？[Y/n] " input113
  	case $input113 in
  		[yY][eE][sS]|[yY])
  			break
  			;;
  		[nN][oO]|[nN])
  			TIME w "即将返回上一步"
  			sleep 1
  			input_container_maiark3_config
  			input_container_maiark3_name
            input_container_maiark3_network_config
            MAIARK_PORT="8082"
  			;;
  		*)
  			TIME r "输入错误，请输入[Y/n]"
  			;;
  	esac
  done

  TIME y " >>>>>>>>>>>配置完成，开始安装 MaiARK"
  log "1.开始创建配置文件目录"
  PATH_LIST=($CONFIG_PATH)
  for i in ${PATH_LIST[@]}; do
      mkdir -p $i
  done

  log "3.开始创建容器并执行"
  docker pull $MAIARK_DOCKER_IMG_NAME:$TAG
  docker run -dit \
      -v $CONFIG_PATH:/MaiARK \
      --name $MAIARK_CONTAINER_NAME \
      --hostname $MAIARK_CONTAINER_NAME \
      --restart always \
      --network $NETWORK \
      -p $MAIARK_PORT:8082 \
      $MAIARK_DOCKER_IMG_NAME:$TAG

      if [ $? -ne 0 ] ; then
          cancelrun "** 错误：容器创建失败，请翻译以上英文报错，Google/百度尝试解决问题！"
      fi

      log "列出所有宿主机上的容器"
      docker ps -a
    TIME g "------------------------------------------------------------------------------"
    TIME g "|                  MaiARK 启动需要一点点时间，请耐心等待！                   |"
    sleep 10
    TIME g "|                          安装完成，自动退出脚本                            |"
    TIME g "|                          访问方式为 宿主机ip:$MAIARK_PORT                          |"
    TIME g "|             请先配置好映射文件夹下的 arkconfig.json 再重启容器             |"
    TIME r "| 桥接模式请不要修改 config 下的端口8082，host模式随意(前提是指定自己在干啥) |"
    TIME r "|                请看清映射的文件夹路径去找 config 文件                      |"
    TIME r "|   op用户出现“docker0: iptables: No chain/target/match by that name”错误    |"
    TIME r "|              输入命令“/etc/init.d/dockerd restart” 重启 docker             |"
    TIME r "|                     再输入“docker start $MAIARK_CONTAINER_NAME” 启动容器                   |"
    TIME r "|       op用户出现容器正常启动，但web界面无法方法Turbo ACC 网络加速设置      |"
    TIME r "|进入“网络——Turbo ACC 网络加速设置” 开启或关闭“全锥型 NAT”就可正常访问web界面|"
    TIME g "------------------------------------------------------------------------------"
  exit 0
  ;;
 0) 
 clear 
 break
 ;;
 *) TIME r "----------------------------------"
    TIME r "|          Warning!!!            |"
    TIME r "|       请输入正确的选项!        |"
    TIME r "----------------------------------"
 for i in $(seq -w 1 -1 1)
   do
     #TIME r "\b\b$i";
     sleep 1;
   done
 clear
 ;;
 esac
 done
;;
12)
# check os
if [[ -f /etc/redhat-release ]]; then
    release="centos"
elif cat /etc/issue | grep -Eqi "debian"; then
    release="debian"
elif cat /etc/issue | grep -Eqi "ubuntu"; then
    release="ubuntu"
elif cat /etc/issue | grep -Eqi "centos|red hat|redhat"; then
    release="centos"
elif cat /etc/issue | grep -Eqi "arch"; then
    release="arch"
elif cat /proc/version | grep -Eqi "debian"; then
    release="debian"
elif cat /proc/version | grep -Eqi "ubuntu"; then
    release="ubuntu"
elif cat /proc/version | grep -Eqi "centos|red hat|redhat"; then
    release="centos"
else
    LOGE "未检测到系统版本，请联系脚本作者！\n" && exit 1
fi

os_version=""

# os version
if [[ -f /etc/os-release ]]; then
    os_version=$(awk -F'[= ."]' '/VERSION_ID/{print $3}' /etc/os-release)
fi
if [[ -z "$os_version" && -f /etc/lsb-release ]]; then
    os_version=$(awk -F'[= ."]+' '/DISTRIB_RELEASE/{print $2}' /etc/lsb-release)
fi

if [[ x"${release}" == x"centos" ]]; then
    if [[ ${os_version} -le 6 ]]; then
        LOGE "请使用 CentOS 7 或更高版本的系统！\n" && exit 1
    fi
elif [[ x"${release}" == x"ubuntu" ]]; then
    if [[ ${os_version} -lt 16 ]]; then
        LOGE "请使用 Ubuntu 16 或更高版本的系统！\n" && exit 1
    fi
elif [[ x"${release}" == x"debian" ]]; then
    if [[ ${os_version} -lt 8 ]]; then
        LOGE "请使用 Debian 8 或更高版本的系统！\n" && exit 1
    fi
fi

confirm() {
    if [[ $# -gt 1 ]]; then
        echo && read -r -p "$1 [默认$2]: " temp
        if [[ "${temp}" == "" ]]; then
            temp=$2
        fi
    else
        read -r -p "$1 [y/n]: " temp
    fi
    if [[ "${temp}" == "y" || x"{temp}" == x"" ]]; then
        return 0
    else
        return 1
    fi
}

install_acme() {
    clear
    cd ~
    TIME g "开始安装acme脚本..."
    curl https://get.acme.sh | sh
    if [ $? -ne 0 ]; then
        TIME r "acme安装失败"
        return 1
    else
        TIME g "acme安装成功"
    fi
    return 0
}

ssl_cert_issue_standalone() {
    clear
    #install acme first
    install_acme
    if [ $? -ne 0 ]; then
        TIME r "无法安装acme,请检查错误日志"
        exit 1
    fi
    #install socat second
    if [[ "${release}" == "centos" ]]; then
        yum install socat -y
    elif [[ "${release}" == "arch" ]]; then
        pacman -S socat cron
    else
        apt install socat -y
    fi
    if [ $? -ne 0 ]; then
        TIME r "无法安装socat,请检查错误日志"
        exit 1
    else
        TIME g "socat安装成功..."
    fi
    #creat a directory for install cert
    certPath=/root/cert
    if [ ! -d "$certPath" ]; then
        mkdir $certPath
    else
        rm -rf $certPath
        mkdir $certPath
    fi
    #get the domain here,and we need verify it
    local domain=""
    read -r -p "请输入你的域名:" domain
    TIME w "你输入的域名为:${domain},正在进行域名合法性校验..."
    #here we need to judge whether there exists cert already
    currentCert=$(~/.acme.sh/acme.sh --list | tail -1 | awk '{print $1}')
    local currentCert
    if [ "${currentCert}" == "${domain}" ]; then
        certInfo=$(~/.acme.sh/acme.sh --list)
        local certInfo
        TIME r "域名合法性校验失败,当前环境已有对应域名证书,不可重复申请,当前证书详情:"
        TIME g "$certInfo"
        exit 1
    else
        TIME g "证书有效性校验通过..."
    fi
    #get needed port here
    local WebPort=80
    read -p "请输入你所希望使用的端口,如回车将使用默认80端口:" WebPort
    if [[ ${WebPort} -gt 65535 || ${WebPort} -lt 1 ]]; then
        TIME r "你所选择的端口${WebPort}为无效值,将使用默认80端口进行申请"
    fi
    TIME g "将会使用${WebPort}进行证书申请,请确保端口处于开放状态..."
    #NOTE:This should be handled by user
    #open the port and kill the occupied progress
    ~/.acme.sh/acme.sh --set-default-ca --server letsencrypt
    ~/.acme.sh/acme.sh --issue -d ${domain} --standalone --httpport ${WebPort}
    if [ $? -ne 0 ]; then
        TIME r "证书申请失败,原因请参见报错信息"
        exit 1
    else
        TIME g "证书申请成功,开始安装证书..."
    fi
    #install cert
    ~/.acme.sh/acme.sh --installcert -d ${domain} --ca-file /root/cert/ca.cer \
        --cert-file /root/cert/${domain}.cer --key-file /root/cert/${domain}.key \
        --fullchain-file /root/cert/fullchain.cer

    if [ $? -ne 0 ]; then
        TIME r "证书安装失败,脚本退出"
        exit 1
    else
        TIME g "证书安装成功,开启自动更新..."
    fi
    ~/.acme.sh/acme.sh --upgrade --auto-upgrade
    if [ $? -ne 0 ]; then
        TIME r "自动更新设置失败,脚本退出"
        ls -lah cert
        chmod 755 $certPath
        exit 1
    else
        TIME g "证书已安装且已开启自动更新,具体信息如下"
        ls -lah cert
        chmod 755 $certPath
    fi

}

ssl_cert_issue_by_cloudflare() {
    clear
    echo -E ""
    TIME w "******使用说明******"
    TIME g "该脚本将使用Acme脚本申请证书,使用时需保证:"
    TIME g "1.知晓Cloudflare 注册邮箱"
    TIME g "2.知晓Cloudflare Global API Key"
    TIME g "3.域名已通过Cloudflare进行解析到当前服务器"
    TIME g "4.该脚本申请证书默认安装路径为/root/cert目录"
    confirm "我已确认以上内容[y/n]" "y"
    if [ $? -eq 0 ]; then
        install_acme
        if [ $? -ne 0 ]; then
            TIME r "无法安装acme,请检查错误日志"
            exit 1
        fi
        CF_Domain=""
        CF_GlobalKey=""
        CF_AccountEmail=""
        certPath=/root/cert
        if [ ! -d "$certPath" ]; then
            mkdir $certPath
        else
            rm -rf $certPath
            mkdir $certPath
        fi
        TIME w "请设置域名:"
        read -r -p "Input your domain here:" CF_Domain
        TIME w "你的域名设置为:${CF_Domain},正在进行域名合法性校验..."
        #here we need to judge whether there exists cert already
        currentCert=$(~/.acme.sh/acme.sh --list | tail -1 | awk '{print $1}')
        local currentCert
        if [ "${currentCert}" == "${CF_Domain}" ]; then
            local certInfo=$(~/.acme.sh/acme.sh --list)
            TIME r "域名合法性校验失败,当前环境已有对应域名证书,不可重复申请,当前证书详情:"
            TIME g "$certInfo"
            exit 1
        else
            TIME g "证书有效性校验通过..."
        fi
        TIME w "请设置API密钥:"
        read -r -p "Input your key here:" CF_GlobalKey
        TIME g "你的API密钥为:${CF_GlobalKey}"
        TIME w "请设置注册邮箱:"
        read -r -p "Input your email here:" CF_AccountEmail
        TIME g "你的注册邮箱为:${CF_AccountEmail}"
        ~/.acme.sh/acme.sh --set-default-ca --server letsencrypt
        if [ $? -ne 0 ]; then
            TIME r "修改默认CA为Lets'Encrypt失败,脚本退出"
            exit 1
        fi
        export CF_Key="${CF_GlobalKey}"
        export CF_Email=${CF_AccountEmail}
        ~/.acme.sh/acme.sh --issue --dns dns_cf -d ${CF_Domain} -d *.${CF_Domain} --log
        if [ $? -ne 0 ]; then
            TIME r "证书签发失败,脚本退出"
            exit 1
        else
            TIME g "证书签发成功,安装中..."
        fi
        ~/.acme.sh/acme.sh --installcert -d ${CF_Domain} -d *.${CF_Domain} --ca-file /root/cert/ca.cer \
            --cert-file /root/cert/${CF_Domain}.cer --key-file /root/cert/${CF_Domain}.key \
            --fullchain-file /root/cert/fullchain.cer
        if [ $? -ne 0 ]; then
            TIME r "证书安装失败,脚本退出"
            exit 1
        else
            TIME g "证书安装成功,开启自动更新..."
        fi
        ~/.acme.sh/acme.sh --upgrade --auto-upgrade
        if [ $? -ne 0 ]; then
            TIME r "自动更新设置失败,脚本退出"
            ls -lah cert
            chmod 755 $certPath
            exit 1
        else
            TIME g "证书已安装且已开启自动更新,具体信息如下"
            ls -lah cert
            chmod 755 $certPath
        fi
    else
        clear
    fi
}

clear
while [ "$flag" -eq 0 ]
do
#cat << EOF
TIME w "----------------------------------------"
TIME w "|****Please Enter Your Choice:[0-2]****|"
TIME w "|*********** SSL 证书申请 *************|"
TIME w "----------------------------------------"
TIME w "该脚本提供两种方式实现证书签发,证书安装路径为/root/cert"
TIME w "如域名属于免费域名,则推荐使用方式(1)申请"
TIME w "如域名非免费域名且使用Cloudflare进行解析使用方式(2)申请"
TIME w "(1) acme standalone mode,需要保持端口开放"
TIME w "(2) acme DNS API mode,需要提供Cloudflare Global API Key"
TIME b "(0) 返回上级菜单"
#EOF
 read -p "Please enter your choice[0-2]: " input12
 case $input12 in
 1)
   ssl_cert_issue_standalone
   ;;
 2)
   ssl_cert_issue_by_cloudflare
   ;;
 0) 
   clear 
   break
   ;;
 *) TIME r "----------------------------------"
    TIME r "|          Warning!!!            |"
    TIME r "|       请输入正确的选项!        |"
    TIME r "----------------------------------"
 for i in $(seq -w 1 -1 1)
   do
     #TIME r "\b\b$i";
     sleep 1;
   done
 clear
 ;;
 esac
done
;;
#安装MFlame
13)
clear
while [ "$flag" -eq 0 ]
do
#cat << EOF
TIME w "----------------------------------------"
TIME w "|****Please Enter Your Choice:[0-2]****|"
TIME w "|************** FLAME *****************|"
TIME w "----------------------------------------"
TIME w "(1) linxu系统、openwrt、群辉等请选择 1"
TIME w "(2) N1 的 EMMC 上运行的 openwrt 请选择 2"
TIME b "(0) 返回上级菜单"
#EOF
TIME r "<注>选择后，如果不明白如何选择或输入，请狂按回车！"
 read -p "Please enter your choice[0-2]: " input11
 case $input11 in 
 1)
  TIME y " >>>>>>>>>>>开始安装 FLAME"
  # 创建映射文件夹
  input_container_flame1_config() {
  echo -n -e "请输入 FLAME 配置文件保存的绝对路径（示例：/home/flame)，回车默认为当前目录: "
  read flame_path
  if [ -z "$flame_path" ]; then
      FLAME_PATH=$FLAME_CONFIG_FOLDER
  elif [ -d "$flame_path" ]; then
      FLAME_PATH=$flame_path
  else
      FLAME_PATH=$flame_path
  fi
  CONFIG_PATH=$FLAME_PATH

  echo -n -e "请输入 FLAME 登陆密码（默认密码：flame)： "
  read flame_password
  if [ -z "$flame_password" ]; then
      FLAME_PASSWORD="flame"
  elif [ -d "$flame_password" ]; then
      FLAME_PASSWORD=$flame_password
  else
      FLAME_PASSWORD=$flame_password
  fi
  }
  input_container_flame1_config

  # 输入容器名
  input_container_flame1_name() {
    echo -n -e "请输入将要创建的容器名[默认为：flame]-> "
    read container_name
    if [ -z "$container_name" ]; then
        FLAME_CONTAINER_NAME="flame"
    else
        FLAME_CONTAINER_NAME=$container_name
    fi
  }
  input_container_flame1_name

  # 网络模式
  input_container_flame1_network_config() {
  inp "请选择容器的网络类型：\n1) host\n2) bridge[默认]"
  opt
  read net
  if [ "$net" = "1" ]; then
      NETWORK="host"
      FLAME_PORT="5005"
  fi
  
  if [ "$NETWORK" = "bridge" ]; then
      inp "是否修改 MaiMRK 端口[默认 5005]：\n1) 修改\n2) 不修改[默认]"
      opt
      read change_flame_port
      if [ "$change_flame_port" = "1" ]; then
          echo -n -e "输入想修改的端口->"
          read FLAME_PORT
          echo $FLAME_PORT
      else
          FLAME_PORT="5005"
      fi
  fi
  }
  input_container_flame1_network_config

  # 确认
  while true
  do
  	TIME y "Flame 配置文件路径：$CONFIG_PATH"
  	TIME y "Flame 容器名：$FLAME_CONTAINER_NAME"
    TIME y "Flame 端口：$FLAME_PORT"
    TIME y "Flame 密码：$FLAME_PASSWORD"
    TIME r "确认下映射路径是否正确！！！"
  	read -r -p "以上信息是否正确？[Y/n] " input111
  	case $input111 in
  		[yY][eE][sS]|[yY])
  			break
  			;;
  		[nN][oO]|[nN])
  			TIME w "即将返回上一步"
  			sleep 1
  			input_container_flame1_config
  			input_container_flame1_name
            input_container_flame1_network_config
            FLAME_PORT="5005"
            FLAME_PASSWORD="flame"
  			;;
  		*)
  			TIME r "输入错误，请输入[Y/n]"
  			;;
  	esac
  done

  TIME y " >>>>>>>>>>>配置完成，开始安装 FLAME"
  log "1.开始创建配置文件目录"
  PATH_LIST=($CONFIG_PATH)
  for i in ${PATH_LIST[@]}; do
      mkdir -p $i
  done

  log "2.开始创建容器并执行"
  docker pull $FLAME_DOCKER_IMG_NAME:$FLAME_TAG
  docker run -d \
      -v $CONFIG_PATH:/app/data \
      --name $FLAME_CONTAINER_NAME \
      --hostname $FLAME_CONTAINER_NAME \
      --restart always \
      --network $NETWORK \
      -p $FLAME_PORT:5005 \
      -e PASSWORD=$FLAME_PASSWORD \
      $FLAME_DOCKER_IMG_NAME:$FLAME_TAG

      if [ $? -ne 0 ] ; then
          cancelrun "** 错误：容器创建失败，请翻译以上英文报错，Google/百度尝试解决问题！"
      fi

      log "列出所有宿主机上的容器"
      docker ps -a
    TIME g "-----------------------------------------------------------"
    TIME g "|          Flame 启动需要一点点时间，请耐心等待！         |"
    sleep 10
    TIME g "|                  安装完成，自动退出脚本                 |"
    TIME g "|                 访问方式为宿主机ip:$FLAME_PORT                 |"
    TIME g "|                      登陆密码：$FLAME_PASSWORD                    |"
    TIME g "-----------------------------------------------------------"
  exit 0
  ;;
 2)  
  TIME y " >>>>>>>>>>>开始安装 FLAME 到 N1 的 /mnt/mmcblk2p4/"
  # 创建映射文件夹
  input_container_flame2_config() {
  echo -n -e "请输入 FLAME 存储的文件夹名称（如：flame)，回车默认为 flame: "
  read flame_path
  if [ -z "$flame_path" ]; then
      FLAME_PATH=$N1_FLAME_FOLDER
  elif [ -d "$flame_path" ]; then
      FLAME_PATH=/mnt/mmcblk2p4/$flame_path
  else
      FLAME_PATH=/mnt/mmcblk2p4/$flame_path
  fi
  CONFIG_PATH=$FLAME_PATH

  echo -n -e "请输入 FLAME 登陆密码（默认密码：flame)： "
  read flame_password
  if [ -z "$flame_password" ]; then
      FLAME_PASSWORD="flame"
  elif [ -d "$flame_password" ]; then
      FLAME_PASSWORD=$flame_password
  else
      FLAME_PASSWORD=$flame_password
  fi
  }
  input_container_flame2_config
  
  # 输入容器名
  input_container_flame2_name() {
    echo -n -e "请输入将要创建的容器名[默认为：flame]-> "
    read container_name
    if [ -z "$container_name" ]; then
        FLAME_CONTAINER_NAME="flame"
    else
        FLAME_CONTAINER_NAME=$container_name
    fi
  }
  input_container_flame2_name

  # 网络模式
  input_container_flame2_network_config() {
  inp "请选择容器的网络类型：\n1) host\n2) bridge[默认]"
  opt
  read net
  if [ "$net" = "1" ]; then
      NETWORK="host"
      MAIARK_PORT="5005"
  fi
  
  if [ "$NETWORK" = "bridge" ]; then
      inp "是否修改 MaiMRK 端口[默认 8082]：\n1) 修改\n2) 不修改[默认]"
      opt
      read change_flame_port
      if [ "$change_flame_port" = "1" ]; then
          echo -n -e "输入想修改的端口->"
          read FLAME_PORT
      else
          FLAME_PORT="5005"
      fi
  fi
  }
  input_container_flame2_network_config


  # 确认
  while true
  do
  	TIME y "FLAME 配置文件路径：$CONFIG_PATH"
  	TIME y "FLAME 容器名：$FLAME_CONTAINER_NAME"
    TIME y "FLAME 端口：$FLAME_PORT"
    TIME y "Flame 密码：$FLAME_PASSWORD"
    TIME r "确认下映射路径是否正确！！！"
  	read -r -p "以上信息是否正确？[Y/n] " input113
  	case $input113 in
  		[yY][eE][sS]|[yY])
  			break
  			;;
  		[nN][oO]|[nN])
  			TIME w "即将返回上一步"
  			sleep 1
  			input_container_flame2_config
  			input_container_flame2_name
            input_container_flame2_network_config
            FLAME_PORT="5005"
            FLAME_PASSWORD="flame"
  			;;
  		*)
  			TIME r "输入错误，请输入[Y/n]"
  			;;
  	esac
  done

  TIME y " >>>>>>>>>>>配置完成，开始安装 FLAME"
  log "1.开始创建配置文件目录"
  PATH_LIST=($CONFIG_PATH)
  for i in ${PATH_LIST[@]}; do
      mkdir -p $i
  done

  log "3.开始创建容器并执行"
  docker pull $FLAME_DOCKER_IMG_NAME:$FLAME_TAG
  docker run -dit \
      -v $CONFIG_PATH:/app/data \
      --name $FLAME_CONTAINER_NAME \
      --hostname $FLAME_CONTAINER_NAME \
      --restart always \
      --network $NETWORK \
      -p $FLAME_PORT:5005 \
      -e PASSWORD=$FLAME_PASSWORD \
      $FLAME_DOCKER_IMG_NAME:$FLAME_TAG

      if [ $? -ne 0 ] ; then
          cancelrun "** 错误：容器创建失败，请翻译以上英文报错，Google/百度尝试解决问题！"
      fi

      log "列出所有宿主机上的容器"
      docker ps -a
    TIME g "-----------------------------------------------------------"
    TIME g "|          Flame 启动需要一点点时间，请耐心等待！         |"
    sleep 10
    TIME g "|                  安装完成，自动退出脚本                 |"
    TIME g "|                 访问方式为宿主机ip:$FLAME_PORT                 |"
    TIME g "|                      登陆密码：$FLAME_PASSWORD                    |"
    TIME g "-----------------------------------------------------------"
  exit 0
  ;;
 0) 
 clear 
 break
 ;;
 *) TIME r "----------------------------------"
    TIME r "|          Warning!!!            |"
    TIME r "|       请输入正确的选项!        |"
    TIME r "----------------------------------"
 for i in $(seq -w 1 -1 1)
   do
     #TIME r "\b\b$i";
     sleep 1;
   done
 clear
 ;;
 esac
 done
;;
*) TIME r "----------------------------------"
 TIME r "|          Warning!!!            |"
 TIME r "|       请输入正确的选项!        |"
 TIME r  "----------------------------------"
 for i in $(seq -w 1 -1 1)
   do
     #TIME r "\b\b$i";
     sleep 1;
   done
 clear
;;
esac
done
