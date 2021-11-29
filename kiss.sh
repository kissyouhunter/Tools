#!/bin/bash
#author kissyouhunter

declare flag=0
clear
while [ "$flag" -eq 0 ]
do
# 青龙变量
JD_DOCKER_IMG_NAME="whyour/qinglong"
TAG="latest"
JD_PATH=""
JD_SHELL_FOLDER=$(pwd)/ql
N1_JD_FOLDER=/mnt/mmcblk2p4/ql
JD_CONTAINER_NAME=""
NETWORK="bridge"
JD_PORT=5700
# elev2p变量
V2P_DOCKER_IMG_NAME="elecv2/elecv2p"
V2P_PATH=""
V2P_SHELL_FOLDER=$(pwd)/elecv2p
N1_V2P_FOLDER=/mnt/mmcblk2p4/elecv2p
V2P_CONTAINER_NAME=""
V2P_PORT=8100
V2P_PORT1=8101
V2P_PORT2=8102

log() {
    echo -e "\n$1"
}
inp() {
    echo -e "\n$1"
}

opt() {
    echo -e "输入您的选择->"
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
      esac
	[[ $# -lt 2 ]] && echo -e "\e[36m\e[0m ${1}" || {
		echo -e "\e[36m\e[0m ${Color}${2}\e[0m"
	 }
      }
}

echo "============================================"
echo "              欢迎使用一键脚本"
echo "             请按照命令提示操作"
TIME r "           请保证科学上网已经开启"
echo "        安装过程中可以按ctrl+c强制退出"
echo "============================================"
cat << EOF
----------------------------------------
(1) 安装docker和docker-compose
(2) 安装<青龙>到宿主机
(3) 安装<elecv2p>到宿主机
(4) 安装portainer(docker图形管理工具)
(0) 不想安装了，给老子退出！！！
EOF
read -p "Please enter your choice[0-4]: " input
case $input in
#安装docker and docker-compose
1)
clear
while [ "$flag" -eq 0 ]
do
cat << EOF
----------------------------------------
|****Please Enter Your Choice:[0-5]****|
|********DOCKER & DOCKER-COMPOSE*******|
----------------------------------------
(1) 安装docker和docker-comopse
(2) 只安装docker
(3) 只装docker-comopse(注：宿主机上必须安装有docker才可以使用docker-compose)
(4) X86 openwrt安装docker和装docker-comopse
(5) Arm64 openwrt安装docker和装docker-comopse(例 N1 等)
(0) 返回上级菜单
EOF
TIME l "<注>openwrt宿主机默认安装dockerman图形docker管理工具！"
 read -p "Please enter your Choice[0-5]: " input1
 case $input1 in 
 1)
    echo "检测 Docker......"
    if [ -x "$(command -v docker)" ]; then
        echo "检测到 Docker 已安装!"
    else
        if [ -r /etc/os-release ]; then
            lsb_dist="$(. /etc/os-release && echo "$ID")"
        fi
        if [ $lsb_dist == "openwrt" ]; then
            TIME r "****openwrt宿主机请选择4或者5安装docker****"
            #exit 1
        else
            TIME y " >>>>>>>>>>>开始安装docker&docker-compose"
            bash <(curl -s -S -L https://raw.githubusercontent.com/kissyouhunter/Tools/main/install-docker.sh)
            systemctl enable docker
            systemctl start docker
            TIME g "****docker和docker-compose安装完成，请返回上级菜单!****"
	    sleep 5
        fi
    fi
  ;;
 2)
    echo "检测 Docker......"
    if [ -x "$(command -v docker)" ]; then
        echo "检测到 Docker 已安装!"
    else
        if [ -r /etc/os-release ]; then
            lsb_dist="$(. /etc/os-release && echo "$ID")"
        fi
        if [ $lsb_dist == "openwrt" ]; then
            TIME r "****openwrt宿主机请选择4或者5安装docker****"
            #exit 1
        else
            TIME y " >>>>>>>>>>>开始安装docker"
            #apt update && apt install curl -y
            curl -fsSL https://get.docker.com -o get-docker.sh
            sh get-docker.sh
            docker -v
            systemctl enable docker
            systemctl start docker
            TIME g "****docker安装完成，请返回上级菜单!****"
	    sleep 5
        fi
    fi
  ;;
 3)
    echo "检测 Docker......"
    if [ -x "$(command -v docker)" ]; then
        echo "检测到 Docker 已安装!"
        TIME y " >>>>>>>>>>>开始安装docker-compose"
        #apt update && apt install curl -y
        curl -L "https://github.com/docker/compose/releases/download/v2.0.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        chmod +x /usr/local/bin/docker-compose
        docker-compose -v
        TIME g "****docker-compose安装完成，请返回上级菜单!****"
	sleep 5
    else
        if [ -r /etc/os-release ]; then
            lsb_dist="$(. /etc/os-release && echo "$ID")"
        fi
        if [ $lsb_dist == "openwrt" ]; then
            TIME r "****openwrt宿主机请选择4或者5安装docker****"
            #exit 1
        elif [ -x "$(command -v docker-compose)" ]; then
              echo "宿主机上已存在docker-compose"
        else
            TIME y " >>>>>>>>>>>开始安装docker&docker-compose"
            bash <(curl -s -S -L https://raw.githubusercontent.com/kissyouhunter/Tools/main/install-docker.sh)
            systemctl enable docker
            systemctl start docker
            TIME g "****docker和docker-compose安装完成，请返回上级菜单!****"
	    sleep 5
        fi
    fi
  ;;
 4)
    TIME y " >>>>>>>>>>>开始为X86 openwrt安装docker和docker-compose"
    mkdir -p /tmp/upload/
    curl -fsSL https://github.com/gd0772/AutoBuild-OpenWrt/releases/download/AutoUpdate/docker_2.1.0-1_x86_64.zip -o /tmp/upload/docker.zip
    cd /tmp/upload/ && unzip docker.zip && rm -f docker.zip
    cd /tmp/upload/ && opkg install *.ipk && rm -f *.ipk
    TIME g "****docker安装完成，请返回上级菜单!****"
    sleep 5
  ;;
 5)
    TIME y " >>>>>>>>>>>开始为Arm64 openwrt安装docker和docker-compose"
    mkdir -p /tmp/upload/
    curl -fsSL https://github.com/kissyouhunter/Openwrt_X86-Openwrt_N1-Armbian_N1/releases/download/openwrt_n1/docker-armv8.zip -o /tmp/upload/docker.zip
    cd /tmp/upload/ && unzip docker.zip && rm -f docker.zip
    cd /tmp/upload/ && opkg install *.ipk && rm -f *.ipk
    TIME g "****docker安装完成，请返回上级菜单!****"
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
 for i in `seq -w 3 -1 1`
   do
     echo -ne "$i";
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
cat << EOF
----------------------------------------
|****Please Enter Your Choice:[0-2]****|
|*****************青龙*****************|
----------------------------------------
(1) linxu系统、X86的openwrt、群辉等请选择 1
(2) N1的EMMC上运行的openwrt请选择 2
(0) 返回上级菜单
EOF
TIME r "<注>选择1或2后，如果不明白如何选择或输入，请狂按回车！"
 read -p "Please enter your choice[0-3]: " input2
 case $input2 in 
 1)
  TIME y " >>>>>>>>>>>开始安装青龙"
    # 创建映射文件夹
  echo -e "请输入青龙配置文件保存的绝对路径（示例：/home/ql)，回车默认为当前目录:"
  read jd_path
  if [ -z "$jd_path" ]; then
      JD_PATH=$JD_SHELL_FOLDER
  elif [ -d "$jd_path" ]; then
      JD_PATH=$jd_path
  else
      mkdir -p $jd_path
      JD_PATH=$jd_path
  fi
  CONFIG_PATH=$JD_PATH/config
  DB_PATH=$JD_PATH/db
  REPO_PATH=$JD_PATH/repo
  SCRIPT_PATH=$JD_PATH/scripts
  LOG_PATH=$JD_PATH/log
  DEPS_PATH=$JD_PATH/deps

  # 输入容器名
  input_container_name() {
    echo -e "请输入将要创建的容器名[默认为：ql]->"
    read container_name
    if [ -z "$container_name" ]; then
        JD_CONTAINER_NAME="ql"
    else
        JD_CONTAINER_NAME=$container_name
    fi
  }
  input_container_name

  # 网络模式
  inp "请选择容器的网络类型：\n1) host\n2) bridge[默认]"
  opt
  read net
  if [ "$net" = "1" ]; then
      NETWORK="host"
      MAPPING_JD_PORT=""
  fi
  
  if [ "$NETWORK" = "bridge" ]; then
      inp "是否修改青龙端口[默认 5700]：\n1) 修改\n2) 不修改[默认]"
      opt
      read change_ql_port
      if [ "$change_ql_port" = "1" ]; then
          echo -e "输入想修改的端口->"
          read JD_PORT
      else
          JD_PORT="5700"
      fi
  fi

  TIME y " >>>>>>>>>>>配置完成，开始安装青龙"
  log "1.开始创建配置文件目录"
  PATH_LIST=($CONFIG_PATH $DB_PATH $REPO_PATH $SCRIPT_PATH $LOG_PATH $DEPS_PATH)
  for i in ${PATH_LIST[@]}; do
      mkdir -p $i
  done

  log "3.开始创建容器并执行"
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
      -p $JD_PORT:5700 \
      --name $JD_CONTAINER_NAME \
      --hostname $JD_CONTAINER_NAME \
      --restart always \
      --network $NETWORK \
      $JD_DOCKER_IMG_NAME:$TAG

      if [ $? -ne 0 ] ; then
          cancelrun "** 错误：容器创建失败，请翻译以上英文报错，Google/百度尝试解决问题！"
      fi

      log "列出所有宿主机上的容器"
      docker ps -a
    TIME g "-----------------------------------------------------"
    TIME g "|        青龙启动需要一点点时间，请耐心等待！       |"
    sleep 10
    TIME g "|             安装完成，自动退出脚本                |"
    TIME g "|   青龙默认端口为5700，如有修改请访问修改后的端口  |"
    TIME g "|    访问方式为宿主机ip:端口(例192.168.2.1:5700)    |"
    TIME g "-----------------------------------------------------"  
  exit 0
  ;;
 2)  
  TIME y " >>>>>>>>>>>开始安装青龙到N1的/mnt/mmcblk2p4/"
  # 创建映射文件夹
  echo -e "请输入青龙存储的文件夹名称（如：ql)，回车默认为ql"
  read jd_path
  if [ -z "$jd_path" ]; then
      JD_PATH=$N1_JD_FOLDER
  elif [ -d "$jd_path" ]; then
      JD_PATH=/mnt/mmcblk2p4/$jd_path
  else
      mkdir -p /mnt/mmcblk2p4/$jd_path
      JD_PATH=/mnt/mmcblk2p4/$jd_path
  fi
  CONFIG_PATH=$JD_PATH/config
  DB_PATH=$JD_PATH/db
  REPO_PATH=$JD_PATH/repo
  SCRIPT_PATH=$JD_PATH/scripts
  LOG_PATH=$JD_PATH/log
  DEPS_PATH=$JD_PATH/deps
  
  # 输入容器名
  input_container_name() {
    echo -e "请输入将要创建的容器名[默认为：ql]->"
    read container_name
    if [ -z "$container_name" ]; then
        JD_CONTAINER_NAME="ql"
    else
        JD_CONTAINER_NAME=$container_name
    fi
  }
  input_container_name

  # 网络模式
  inp "请选择容器的网络类型：\n1) host\n2) bridge[默认]"
  opt
  read net
  if [ "$net" = "1" ]; then
      NETWORK="host"
      MAPPING_JD_PORT=""
  fi
  
  if [ "$NETWORK" = "bridge" ]; then
      inp "是否修改青龙端口[默认 5700]：\n1) 修改\n2) 不修改[默认]"
      opt
      read change_ql_port
      if [ "$change_ql_port" = "1" ]; then
          echo -e "输入想修改的端口->"
          read JD_PORT
      else
          JD_PORT="5700"
      fi
  fi

  TIME y " >>>>>>>>>>>配置完成，开始安装青龙"
  log "1.开始创建配置文件目录"
  PATH_LIST=($CONFIG_PATH $DB_PATH $REPO_PATH $SCRIPT_PATH $LOG_PATH $DEPS_PATH)
  for i in ${PATH_LIST[@]}; do
      mkdir -p $i
  done

  log "3.开始创建容器并执行"
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
      -p $JD_PORT:5700 \
      --name $JD_CONTAINER_NAME \
      --hostname $JD_CONTAINER_NAME \
      --restart always \
      --network $NETWORK \
      $JD_DOCKER_IMG_NAME:$TAG

      if [ $? -ne 0 ] ; then
          cancelrun "** 错误：容器创建失败，请翻译以上英文报错，Google/百度尝试解决问题！"
      fi

      log "列出所有宿主机上的容器"
      docker ps -a
    TIME g "-----------------------------------------------------"
    TIME g "|        青龙启动需要一点点时间，请耐心等待！       |"
    sleep 10
    TIME g "|             安装完成，自动退出脚本                |"
    TIME g "|    青龙默认端口为9000，如有修改请访问修改的端口   |"
    TIME g "|    访问方式为宿主机ip:端口(例192.168.2.1:9000)    |"
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
 for i in `seq -w 3 -1 1`
   do
     echo -ne "$i";
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
cat << EOF
----------------------------------------
|****Please Enter Your Choice:[0-2]****|
|****************ELECV2P***************|
----------------------------------------
(1) linxu系统、X86的openwrt、群辉等请选择 1
(2) N1的EMMC上运行的openwrt请选择 2
(0) 返回上级菜单
EOF
TIME r "<注>选择1或2后，如果不明白如何选择或输入，请狂按回车！"
 read -p "Please enter your Choice[0-2]: " input3
 case $input3 in 
 1)
  TIME y " >>>>>>>>>>>开始安装elecv2p"
  # 创建映射文件夹
  echo -e "请输入elecv2p配置文件保存的绝对路径（示例：/home/elecv2p)，回车默认为当前目录:"
  read v2p_path
  if [ -z "$v2p_path" ]; then
      V2P_PATH=$V2P_SHELL_FOLDER
  elif [ -d "$v2p_path" ]; then
      V2P_PATH=$v2p_path
  else
      mkdir -p $v2p_path
      V2P_PATH=$v2p_path
  fi
  JSFILE_PATH=$V2P_PATH/JSFile
  LISTS_PATH=$V2P_PATH/Lists
  STORE_PATH=$V2P_PATH/Store
  SHELL_PATH=$V2P_PATH/Shell
  ROOTCA_PATH=$V2P_PATH/rootCA
  EFSS_PATH=$V2P_PATH/efss
  LOG_PATH=$V2P_PATH/logs
  
  # 输入容器名
  input_container_name() {
    echo -e "请输入将要创建的容器名[默认为：elecv2p]->"
    read container_name
    if [ -z "$container_name" ]; then
        V2P_CONTAINER_NAME="elecv2p"
    else
        V2P_CONTAINER_NAME=$container_name
    fi
  }
  input_container_name

  # 面板端口
  inp "是否修改elecv2p面板端口[默认 8100]：\n1) 修改\n2) 不修改[默认]"
  opt
  read change_v2p_port
  if [ "$change_v2p_port" = "1" ]; then
      echo -e "输入想修改的端口->"
      read V2P_PORT
  fi
  # ANYPROXY端口
  inp "是否修改elecv2p的anyproxy端口[默认 8101]：\n1) 修改\n2) 不修改[默认]"
  opt
  read change_v2p_port1
  if [ "$change_v2p_port1" = "1" ]; then
      echo -e "输入想修改的端口->"
      read V2P_PORT1
  fi
  # 网络请求查看端口
  inp "是否修改elecv2p网络请求查看端口[默认 8102]：\n1) 修改\n2) 不修改[默认]"
  opt
  read change_v2p_port2
  if [ "$change_v2p_port2" = "1" ]; then
      echo -e "输入想修改的端口->"
      read V2P_PORT2
  fi

  TIME y " >>>>>>>>>>>配置完成，开始安装elecv2p"
  log "1.开始创建配置文件目录"
  PATH_LIST=($JSFILE_PATH $LISTS_PATH $STORE_PATH $SHELL_PATH $ROOTCA_PATH $EFSS_PATH $LOG_PATH)
  for i in ${PATH_LIST[@]}; do
      mkdir -p $i
  done

  log "3.开始创建容器并执行"
  docker run -dit \
      -v $JSFILE_PATH:/usr/local/app/script/JSFile \
      -v $LISTS_PATH:/usr/local/app/script/Lists \
      -v $STIRE_PATH:/usr/local/app/script/Store \
      -v $SHELL_PATH:/usr/local/app/script/Shell \
      -v $ROOTCA_PATH:/usr/local/app/rootCA \
      -v $EFSS_PATH:/usr/local/app/efss \
      -v $LOG_PATH:/usr/local/app/logs \
      -p $V2P_PORT:80 -p $V2P_PORT1:8001 -p $V2P_PORT2:8002 \
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
    TIME g "|      elev2p启动需要一点点时间，请耐心等待！       |"
    sleep 10
    TIME g "|             安装完成，自动退出脚本                |"
    TIME g "|  elev2p默认端口为8100，如有修改请访问修改的端口   |"
    TIME g "|    访问方式为宿主机ip:端口(例192.168.2.1:8100)    |"
    TIME g "-----------------------------------------------------"
  exit 0
  ;;
 2)
  TIME y " >>>>>>>>>>>开始安装elecv2p到N1的/mnt/mmcblk2p4/"
  # 创建映射文件夹
  echo -e "请输入elecv2p存储的文件夹名称（如：elecv2p)，回车默认为elecv2p"
  read v2p_path
  if [ -z "$v2p_path" ]; then
      V2P_PATH=$N1_V2P_FOLDER
  elif [ -d "$v2p_path" ]; then
      V2P_PATH=/mnt/mmcblk2p4/$v2p_path
  else
      mkdir -p /mnt/mmcblk2p4/$v2p_path
      V2P_PATH=/mnt/mmcblk2p4/$v2p_path
  fi
  JSFILE_PATH=$V2P_PATH/JSFile
  LISTS_PATH=$V2P_PATH/Lists
  STORE_PATH=$V2P_PATH/Store
  SHELL_PATH=$V2P_PATH/Shell
  ROOTCA_PATH=$V2P_PATH/rootCA
  EFSS_PATH=$V2P_PATH/efss
  LOG_PATH=$V2P_PATH/logs
  
  # 输入容器名
  input_container_name() {
    echo -e "请输入将要创建的容器名[默认为：elecv2p]->"
    read container_name
    if [ -z "$container_name" ]; then
        V2P_CONTAINER_NAME="elecv2p"
    else
        V2P_CONTAINER_NAME=$container_name
    fi
  }
  input_container_name

  # 面板端口
  inp "是否修改elecv2p面板端口[默认 8100]：\n1) 修改\n2) 不修改[默认]"
  opt
  read change_v2p_port
  if [ "$change_v2p_port" = "1" ]; then
      echo -e "输入想修改的端口->"
      read V2P_PORT
  fi
  # ANYPROXY端口
  inp "是否修改elecv2p的anyproxy端口[默认 8101]：\n1) 修改\n2) 不修改[默认]"
  opt
  read change_v2p_port1
  if [ "$change_v2p_port1" = "1" ]; then
      echo -e "输入想修改的端口->"
      read V2P_PORT1
  fi
  # 网络请求查看端口
  inp "是否修改elecv2p网络请求查看端口[默认 8102]：\n1) 修改\n2) 不修改[默认]"
  opt
  read change_v2p_port2
  if [ "$change_v2p_port2" = "1" ]; then
      echo -e "输入想修改的端口->"
      read V2P_PORT2
  fi

  TIME y " >>>>>>>>>>>配置完成，开始安装elecv2p"
  log "1.开始创建配置文件目录"
  PATH_LIST=($JSFILE_PATH $LISTS_PATH $STORE_PATH $SHELL_PATH $ROOTCA_PATH $EFSS_PATH $LOG_PATH)
  for i in ${PATH_LIST[@]}; do
      mkdir -p $i
  done

  log "3.开始创建容器并执行"
  docker run -dit \
      -v $JSFILE_PATH:/usr/local/app/script/JSFile \
      -v $LISTS_PATH:/usr/local/app/script/Lists \
      -v $STIRE_PATH:/usr/local/app/script/Store \
      -v $SHELL_PATH:/usr/local/app/script/Shell \
      -v $ROOTCA_PATH:/usr/local/app/rootCA \
      -v $EFSS_PATH:/usr/local/app/efss \
      -v $LOG_PATH:/usr/local/app/logs \
      -p $V2P_PORT:80 -p $V2P_PORT1:8001 -p $V2P_PORT2:8002 \
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
    TIME g "|      elev2p启动需要一点点时间，请耐心等待！       |"
    sleep 10
    TIME g "|             安装完成，自动退出脚本                |"
    TIME g "|  elev2p默认端口为8100，如有修改请访问修改的端口   |"
    TIME g "|    访问方式为宿主机ip:端口(例192.168.2.1:8100)    |"
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
 for i in `seq -w 3 -1 1`
   do
     echo -ne "$i";
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
cat << EOF
----------------------------------------
|****Please Enter Your Choice:[0-1]****|
|********DOCKER & DOCKER-COMPOSE*******|
----------------------------------------
(1) 安装portianer
(0) 返回上级菜单
EOF
 read -p "Please enter your Choice[0-1]: " input4
 case $input4 in 
 1)
    TIME y " >>>>>>>>>>>开始安装portainer"
    docker volume create portainer_data
    docker run -d -p 8000:8000 -p 9000:9000 --name=portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ce
    
    if [ $? -ne 0 ] ; then
        cancelrun "** 错误：容器创建失败，请翻译以上英文报错，Google/百度尝试解决问题！"
    fi

    TIME g "------------------------------------------------------"
    TIME g "|      portainer启动需要一点点时间，请耐心等待！     |"
    sleep 10
    TIME g "|              安装完成，自动退出脚本                |"
    TIME g "| portianer默认端口为9000，如有修改请访问修改的端口  |"
    TIME g "|   访问方式为宿主机ip:端口(例192.168.2.1:9000)      |"
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
 for i in `seq -w 3 -1 1`
   do
     echo -ne "$i";
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
*)  TIME r "----------------------------------"
 TIME r "|          Warning!!!            |"
 TIME r "|       请输入正确的选项!        |"
 TIME r  "----------------------------------"
 for i in `seq -w 3 -1 1`
   do
     echo -ne "$i";
     sleep 1;
   done
 clear
;;
esac
done
