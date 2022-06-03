#!/bin/bash
## Author: kissyouhunter
## Date: 2022-04-28

## 变量
ARCH=$(uname -m)
DockerCompose=/usr/local/bin/docker-compose
PROXY_URL=https://get.daocloud.io/docker/compose/releases/download/v2.5.0/docker-compose-`uname -s`-`uname -m`
DOCKER_COMPOSE_VERSION=v2.6.0
DOCKER_COMPOSE_DOWNLOAD_URL=https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-Linux-x86_64
DOCKER_COMPOSE_AARCG64_DOWNLOAD_URL=https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-Linux-aarch64

## 颜色 
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'
PLAIN='\033[0m'
BOLD='\033[1m'
SUCCESS='[\033[32mOK\033[0m]'
COMPLETE='[\033[32mDone\033[0m]'
WARN='[\033[33mWARN\033[0m]'
ERROR='[\033[31mERROR\033[0m]'
WORKING='[\033[34m*\033[0m]'

## 组合函数
function Combin_Function() {
    WelcomeMsg
    PermissionJudgment
    EnvJudgment
    DockerMirror
    $InstallDocker
    DockerCompose
    ShowVersion
}

function WelcomeMsg() {
    echo -e "\n${GREEN} ------------ 安装程序开始 ------------ ${PLAIN}\n"
}

## root 判断
function PermissionJudgment() {
    if [ $UID -ne 0 ]; then
        echo -e "\n${ERROR} 请切换到root再运行脚本! \n"
        exit
    fi
}

## 判定系统处理器架构
function EnvJudgment() {
    case ${ARCH} in
    x86_64)
        SYSTEM_ARCH="x86_64"
        SOURCE_ARCH="amd64"
        ;;
    aarch64)
        SYSTEM_ARCH="ARM64"
        SOURCE_ARCH="arm64"
        ;;
    armv7l)
        SYSTEM_ARCH="ARMv7"
        SOURCE_ARCH="armhf"
        ;;
    armv6l)
        SYSTEM_ARCH="ARMv6"
        SOURCE_ARCH="armhf"
        ;;
    i386 | i686)
        SYSTEM_ARCH="x86_32"
        echo -e "\n${RED}---------- Docker Engine 不支持安装在 x86_32 架构的环境上！ ----------${PLAIN}\n"
        exit
        ;;
    *)
        SYSTEM_ARCH=${ARCH}
        SOURCE_ARCH=armhf
        ;;
    esac
}

## 判断源

function DockerMirror() {
    declare flag=0
    while [ "$flag" -eq 0 ]
    do
    echo -e "${GREEN} 请选择源: ${PLAIN}"
    echo -e "${GREEN} 1 官方源 ${PLAIN}"
    echo -e "${GREEN} 2 阿里源 ${PLAIN}"
    read -p "请输入选项[1-2]: " input
    case $input in
    1)
        InstallDocker=DockerEngine1
        break
    ;;
    2)
        InstallDocker=DockerEngine2
        break
    ;;
    *)
        echo -e "\n${RED} 输入错误 ${PLAIN}\n" 
         for i in $(seq -w 1 -1 1)
            do
                sleep 1;
            done
    esac
    done

    if [ -x $DockerCompose ]; then
        CHOICE_D=$(echo -e "${BOLD}检测到已安装 Docker Compose ，是否覆盖安装 [ Y/n ]：${PLAIN}")
    else
        CHOICE_D=$(echo -e "${GREEN}是否安装 Docker Compose [ Y/n ]：${PLAIN}")
    fi
    read -p "${CHOICE_D}" INPUT
    [ -z ${INPUT} ] && INPUT=Y
    case $INPUT in
    [Yy] | [Yy][Ee][Ss])
        DOCKER_COMPOSE="True"
        CHOICE_D1=$(echo -e "${BOLD}是否使用国内代理进行下载 [ Y/n ]：${PLAIN}")
        read -p "${CHOICE_D1}" INPUT
        [ -z ${INPUT} ] && INPUT=Y
        case $INPUT in
        [Yy] | [Yy][Ee][Ss])
            DOCKER_COMPOSE_DOWNLOAD_PROXY="True"
            ;;
        [Nn] | [Nn][Oo])
            DOCKER_COMPOSE_DOWNLOAD_PROXY="False"
            ;;
        *)
            echo -e "\n${RED} 输入错误 ${PLAIN}\n" 
            for i in $(seq -w 1 -1 1)
                do
                    sleep 1;
                done
            ;;
        esac
        ;;
    [Nn] | [Nn][Oo])
        DOCKER_COMPOSE="False"
        ;;
    *)
        echo -e "\n${RED} 输入错误 ${PLAIN}\n" 
         for i in $(seq -w 1 -1 1)
            do
                sleep 1;
            done
    esac
}

## 安装 Docker Engine
function DockerEngine1() {
    curl -Lo get-docker.sh https://raw.githubusercontent.com/kissyouhunter/Tools/main/get-docker.sh
    sh get-docker.sh
}
function DockerEngine2() {
    curl -Lo get-docker.sh https://raw.githubusercontent.com/kissyouhunter/Tools/main/get-docker.sh
    sh get-docker.sh --mirror Aliyun
}

## 安装 Docker-Compose
function DockerCompose() {
    if [[ ${DOCKER_COMPOSE} == "True" ]]; then
        [ -e $DockerCompose ] && rm -rf $DockerCompose
        if [[ ${ARCH} == "x86_64" ]]; then
            if [ ${DOCKER_COMPOSE_DOWNLOAD_PROXY} == "True" ]; then
                curl -Lo $DockerCompose ${PROXY_URL}
            else
                curl -Lo $DockerCompose ${DOCKER_COMPOSE_DOWNLOAD_URL}
            fi
            chmod +x $DockerCompose
        elif [[ ${ARCH} == "aarch64" ]]; then
            if [ ${DOCKER_COMPOSE_DOWNLOAD_PROXY} == "True" ]; then
                curl -Lo $DockerCompose ${PROXY_URL}
            else
                curl -Lo $DockerCompose ${DOCKER_COMPOSE_AARCG64_DOWNLOAD_URL}
            fi
            chmod +x $DockerCompose
        fi
    fi
}

## 查看版本并验证安装结果
function ShowVersion() {
    echo -e "${WORKING} 验证安装版本...\n"
    docker -v
    VERIFICATION_DOCKER=$?
    [[ ${DOCKER_COMPOSE} == "True" ]] && docker-compose -v
    if [ ${VERIFICATION_DOCKER} -eq 0 ]; then
        echo -e "\n${SUCCESS} 安装完成"
    else
        echo -e "\n${ERROR} 安装失败"
        case ${SYSTEM_FACTIONS} in
        Debian)
            echo -e "\n检查源文件： cat $DockerSourceList"
            echo -e '请尝试手动执行安装命令： apt-get install -y docker-ce docker-ce-cli containerd.io\n'
            echo ''
            ;;
        RedHat)
            echo -e "\n检查源文件： cat $DockerRepo"
            echo -e '请尝试手动执行安装命令： yum install -y docker-ce docker-ce-cli containerd.io\n'
            ;;
        esac
        exit
    fi
    systemctl status docker | grep running -q
    if [ $? -ne 0 ]; then
        sleep 2
        systemctl disable --now docker >/dev/null 2>&1
        sleep 2
        systemctl enable --now docker >/dev/null 2>&1
        sleep 2
        systemctl status docker | grep running -q
        if [ $? -ne 0 ]; then
            echo -e "\n${ERROR} 检测到 Docker 服务启动异常，可能由于重复安装相同版本导致"
            echo -e "\n请执行 systemctl start docker 或 service docker start 命令尝试启动"
            echo -e "\n官方安装文档：https://docs.docker.com/engine/install"
        fi
    fi
}

Combin_Function