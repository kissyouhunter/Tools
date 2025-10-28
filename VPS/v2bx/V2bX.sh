#!/bin/bash

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

# check root
[[ $EUID -ne 0 ]] && echo -e "${red}错误: ${plain} 必须使用root用户运行此脚本！\n" && exit 1

# check os
if [[ -f /etc/redhat-release ]]; then
    release="centos"
elif cat /etc/issue | grep -Eqi "alpine"; then
    release="alpine"
elif cat /etc/issue | grep -Eqi "debian"; then
    release="debian"
elif cat /etc/issue | grep -Eqi "ubuntu"; then
    release="ubuntu"
elif cat /etc/issue | grep -Eqi "centos|red hat|redhat|rocky|alma|oracle linux"; then
    release="centos"
elif cat /proc/version | grep -Eqi "debian"; then
    release="debian"
elif cat /proc/version | grep -Eqi "ubuntu"; then
    release="ubuntu"
elif cat /proc/version | grep -Eqi "centos|red hat|redhat|rocky|alma|oracle linux"; then
    release="centos"
elif cat /proc/version | grep -Eqi "arch"; then
    release="arch"
else
    echo -e "${red}未检测到系统版本，请联系脚本作者！${plain}\n" && exit 1
fi

# os version
if [[ -f /etc/os-release ]]; then
    os_version=$(awk -F'[= ."]' '/VERSION_ID/{print $3}' /etc/os-release)
fi
if [[ -z "$os_version" && -f /etc/lsb-release ]]; then
    os_version=$(awk -F'[= ."]+' '/DISTRIB_RELEASE/{print $2}' /etc/lsb-release)
fi

if [[ x"${release}" == x"centos" ]]; then
    if [[ ${os_version} -le 6 ]]; then
        echo -e "${red}请使用 CentOS 7 或更高版本的系统！${plain}\n" && exit 1
    fi
    if [[ ${os_version} -eq 7 ]]; then
        echo -e "${red}注意： CentOS 7 无法使用hysteria1/2协议！${plain}\n"
    fi
elif [[ x"${release}" == x"ubuntu" ]]; then
    if [[ ${os_version} -lt 16 ]]; then
        echo -e "${red}请使用 Ubuntu 16 或更高版本的系统！${plain}\n" && exit 1
    fi
elif [[ x"${release}" == x"debian" ]]; then
    if [[ ${os_version} -lt 8 ]]; then
        echo -e "${red}请使用 Debian 8 或更高版本的系统！${plain}\n" && exit 1
    fi
fi

# 函数: 检查 IPv6 支持
check_ipv6_support() {
    if ip -6 addr | grep -q "inet6"; then
        echo "1"  # 支持 IPv6
    else
        echo "0"  # 不支持 IPv6
    fi
}

# 重要: 自动判断系统优先级
get_ip_priority() {
    ipv6_support=$(check_ipv6_support)
    if [[ "$ipv6_support" == "1" ]]; then
        echo "ipv6"
    else
        echo "ipv4"
    fi
}

# 获取当前优先级（从现有配置文件读取）
get_current_priority() {
    if [[ -f /etc/V2bX/sing_origin.json ]]; then
        local strategy=$(jq -r '.dns.strategy // "system"' /etc/V2bX/sing_origin.json 2>/dev/null)
        case "$strategy" in
            "prefer_ipv6"|"ipv6_only") echo "ipv6" ;;
            "prefer_ipv4"|"ipv4_only") echo "ipv4" ;;
            *) 
                # 如果没有配置，自动检测
                ipv6_support=$(check_ipv6_support)
                [[ "$ipv6_support" == "1" ]] && echo "ipv6" || echo "ipv4"
                ;;
        esac
    else
        # 配置文件不存在，自动检测
        ipv6_support=$(check_ipv6_support)
        [[ "$ipv6_support" == "1" ]] && echo "ipv6" || echo "ipv4"
    fi
}

# 设置优先级（直接修改配置文件）
set_priority() {
    local pref="$1"  # ipv4 or ipv6

    local current_pref=$(get_current_priority)
    if [[ "$current_pref" == "$pref" ]]; then
        echo -e "${green}当前已是 $pref 优先${plain}"
        return 0
    fi

    # ListenIP 永远是 "::" 以支持双栈
    local listen_ip="::"

    # 根据优先级确定 SendIP 和 DNS 策略
    if [[ "$pref" == "ipv6" ]]; then
        local dns_strategy="prefer_ipv6"
        local send_ip="::"
        local dns_type="UseIP"
    else
        local dns_strategy="prefer_ipv4"
        local send_ip="0.0.0.0"
        local dns_type="UseIPv4"
    fi

    # 备份配置文件
    local timestamp=$(date +%Y%m%d_%H%M%S)
    [[ -f /etc/V2bX/config.json ]] && cp /etc/V2bX/config.json /etc/V2bX/config.json.bak.$timestamp
    [[ -f /etc/V2bX/sing_origin.json ]] && cp /etc/V2bX/sing_origin.json /etc/V2bX/sing_origin.json.bak.$timestamp

    # 修改配置文件
    if [[ -f /etc/V2bX/config.json ]]; then
        # 修改 config.json 中的相关配置
        # 只修改 SendIP，ListenIP 保持为 "::"
        sed -i "s/\"SendIP\": \"[^\"]*\"/\"SendIP\": \"$send_ip\"/g" /etc/V2bX/config.json
        sed -i "s/\"ListenIP\": \"[^\"]*\"/\"ListenIP\": \"$listen_ip\"/g" /etc/V2bX/config.json
        sed -i "s/\"DNSType\": \"[^\"]*\"/\"DNSType\": \"$dns_type\"/g" /etc/V2bX/config.json
    fi

    # 修改 sing_origin.json
    if [[ -f /etc/V2bX/sing_origin.json ]]; then
        # 使用 jq 修改 DNS 策略
        if command -v jq >/dev/null 2>&1; then
            jq ".dns.strategy = \"$dns_strategy\" | .outbounds[0].domain_resolver.strategy = \"$dns_strategy\"" \
               /etc/V2bX/sing_origin.json > /tmp/sing_origin_tmp.json && \
               mv /tmp/sing_origin_tmp.json /etc/V2bX/sing_origin.json
        else
            # 如果没有 jq，使用 sed
            sed -i "s/\"strategy\": \"[^\"]*\"/\"strategy\": \"$dns_strategy\"/g" /etc/V2bX/sing_origin.json
        fi
    fi

    echo -e "${green}已切换为 $pref 优先${plain}"
    echo -e "${yellow}配置文件已更新并备份${plain}"

    # 自动重启服务
    echo -e "${green}正在重启 V2bX...${plain}"
    restart 0
    echo -e "${green}V2bX 已重启，新的优先级已生效${plain}"
}

# 切换优先级
switch_ip_priority() {
    check_install
    if [[ $? != 0 ]]; then
        return 1
    fi
    
    local current=$(get_current_priority)
    
    echo ""
    echo -e "=========================================="
    echo -e "${green}IP 优先级切换${plain}"
    echo -e "=========================================="
    
    if [[ "$current" == "ipv4" ]]; then
        echo -e "当前优先级: ${yellow}IPv4 优先${plain}"
        echo -e "只能切换为: ${green}IPv6 优先${plain}"
        echo ""
        read -rp "确认切换到 IPv6 优先吗？(y/n): " confirm
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            set_priority "ipv6"
        else
            echo -e "${yellow}已取消切换${plain}"
        fi
    else
        echo -e "当前优先级: ${green}IPv6 优先${plain}"
        echo -e "只能切换为: ${yellow}IPv4 优先${plain}"
        echo ""
        read -rp "确认切换到 IPv4 优先吗？(y/n): " confirm
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            set_priority "ipv4"
        else
            echo -e "${yellow}已取消切换${plain}"
        fi
    fi
    
    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

confirm() {
    if [[ $# > 1 ]]; then
        echo && read -rp "$1 [默认$2]: " temp
        if [[ x"${temp}" == x"" ]]; then
            temp=$2
        fi
    else
        read -rp "$1 [y/n]: " temp
    fi
    if [[ x"${temp}" == x"y" || x"${temp}" == x"Y" ]]; then
        return 0
    else
        return 1
    fi
}

before_show_menu() {
    echo && echo -n -e "${yellow}按回车返回主菜单: ${plain}" && read temp
    show_menu
}

install() {
    bash <(curl -Ls https://raw.githubusercontent.com/kissyouhunter/Tools/refs/heads/main/VPS/v2bx/install.sh)
    if [[ $? == 0 ]]; then
        if [[ $# == 0 ]]; then
            start
        else
            start 0
        fi
    fi
}

update() {
    if [[ $# == 0 ]]; then
        echo && echo -n -e "输入指定版本(默认最新版): " && read version
    else
        version=$2
    fi
    bash <(curl -Ls https://raw.githubusercontent.com/kissyouhunter/Tools/refs/heads/main/VPS/v2bx/install.sh) $version
    if [[ $? == 0 ]]; then
        echo -e "${green}更新完成，已自动重启 V2bX，请使用 V2bX log 查看运行日志${plain}"
        exit
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

config() {
    echo "V2bX在修改配置后会自动尝试重启"
    nano /etc/V2bX/config.json
    sleep 2
    restart
    check_status
    case $? in
        0)
            echo -e "V2bX状态: ${green}已运行${plain}"
            ;;
        1)
            echo -e "检测到您未启动V2bX或V2bX自动重启失败，是否查看日志？[Y/n]" && echo
            read -e -rp "(默认: y):" yn
            [[ -z ${yn} ]] && yn="y"
            if [[ ${yn} == [Yy] ]]; then
               show_log
            fi
            ;;
        2)
            echo -e "V2bX状态: ${red}未安装${plain}"
    esac
}

uninstall() {
    confirm "确定要卸载 V2bX 吗?" "n"
    if [[ $? != 0 ]]; then
        if [[ $# == 0 ]]; then
            show_menu
        fi
        return 0
    fi
    if [[ x"${release}" == x"alpine" ]]; then
        service V2bX stop
        rc-update del V2bX
        rm /etc/init.d/V2bX -f
    else
        systemctl stop V2bX
        systemctl disable V2bX
        rm /etc/systemd/system/V2bX.service -f
        systemctl daemon-reload
        systemctl reset-failed
    fi
    rm /etc/V2bX/ -rf
    rm /usr/local/V2bX/ -rf

    echo ""
    echo -e "卸载成功，如果你想删除此脚本，则退出脚本后运行 ${green}rm /usr/bin/V2bX -f${plain} 进行删除"
    echo ""

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

start() {
    check_status
    if [[ $? == 0 ]]; then
        echo ""
        echo -e "${green}V2bX已运行，无需再次启动，如需重启请选择重启${plain}"
    else
        if [[ x"${release}" == x"alpine" ]]; then
            service V2bX start
        else
            systemctl start V2bX
        fi
        sleep 2
        check_status
        if [[ $? == 0 ]]; then
            echo -e "${green}V2bX 启动成功，请使用 V2bX log 查看运行日志${plain}"
        else
            echo -e "${red}V2bX可能启动失败，请稍后使用 V2bX log 查看日志信息${plain}"
        fi
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

stop() {
    if [[ x"${release}" == x"alpine" ]]; then
        service V2bX stop
    else
        systemctl stop V2bX
    fi
    sleep 2
    check_status
    if [[ $? == 1 ]]; then
        echo -e "${green}V2bX 停止成功${plain}"
    else
        echo -e "${red}V2bX停止失败，可能是因为停止时间超过了两秒，请稍后查看日志信息${plain}"
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

restart() {
    if [[ x"${release}" == x"alpine" ]]; then
        service V2bX restart
    else
        systemctl restart V2bX
    fi
    sleep 2
    check_status
    if [[ $? == 0 ]]; then
        echo -e "${green}V2bX 重启成功，请使用 V2bX log 查看运行日志${plain}"
    else
        echo -e "${red}V2bX可能启动失败，请稍后使用 V2bX log 查看日志信息${plain}"
    fi
    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

status() {
    if [[ x"${release}" == x"alpine" ]]; then
        service V2bX status
    else
        systemctl status V2bX --no-pager -l
    fi
    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

enable() {
    if [[ x"${release}" == x"alpine" ]]; then
        rc-update add V2bX
    else
        systemctl enable V2bX
    fi
    if [[ $? == 0 ]]; then
        echo -e "${green}V2bX 设置开机自启成功${plain}"
    else
        echo -e "${red}V2bX 设置开机自启失败${plain}"
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

disable() {
    if [[ x"${release}" == x"alpine" ]]; then
        rc-update del V2bX
    else
        systemctl disable V2bX
    fi
    if [[ $? == 0 ]]; then
        echo -e "${green}V2bX 取消开机自启成功${plain}"
    else
        echo -e "${red}V2bX 取消开机自启失败${plain}"
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

show_log() {
    if [[ x"${release}" == x"alpine" ]]; then
        echo -e "${red}alpine系统暂不支持日志查看${plain}\n" && exit 1
    else
        journalctl -u V2bX.service -e --no-pager -f
    fi
    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

update_shell() {
    wget -O /usr/bin/V2bX -N --no-check-certificate https://github.com/kissyouhunter/Tools/raw/refs/heads/main/VPS/v2bx/V2bX.sh
    if [[ $? != 0 ]]; then
        echo ""
        echo -e "${red}下载脚本失败，请检查本机能否连接 Github${plain}"
        before_show_menu
    else
        chmod +x /usr/bin/V2bX
        echo -e "${green}升级脚本成功，请重新运行脚本${plain}" && exit 0
    fi
}

# 0: running, 1: not running, 2: not installed
check_status() {
    if [[ ! -f /usr/local/V2bX/V2bX ]]; then
        return 2
    fi
    if [[ x"${release}" == x"alpine" ]]; then
        temp=$(service V2bX status | awk '{print $3}')
        if [[ x"${temp}" == x"started" ]]; then
            return 0
        else
            return 1
        fi
    else
        temp=$(systemctl status V2bX | grep Active | awk '{print $3}' | cut -d "(" -f2 | cut -d ")" -f1)
        if [[ x"${temp}" == x"running" ]]; then
            return 0
        else
            return 1
        fi
    fi
}

check_enabled() {
    if [[ x"${release}" == x"alpine" ]]; then
        temp=$(rc-update show | grep V2bX)
        if [[ x"${temp}" == x"" ]]; then
            return 1
        else
            return 0
        fi
    else
        temp=$(systemctl is-enabled V2bX)
        if [[ x"${temp}" == x"enabled" ]]; then
            return 0
        else
            return 1;
        fi
    fi
}

check_uninstall() {
    check_status
    if [[ $? != 2 ]]; then
        echo ""
        echo -e "${red}V2bX已安装，请不要重复安装${plain}"
        if [[ $# == 0 ]]; then
            before_show_menu
        fi
        return 1
    else
        return 0
    fi
}

check_install() {
    check_status
    if [[ $? == 2 ]]; then
        echo ""
        echo -e "${red}请先安装V2bX${plain}"
        if [[ $# == 0 ]]; then
            before_show_menu
        fi
        return 1
    else
        return 0
    fi
}

show_status() {
    check_status
    case $? in
        0)
            echo -e "V2bX状态: ${green}已运行${plain}"
            show_enable_status
            ;;
        1)
            echo -e "V2bX状态: ${yellow}未运行${plain}"
            show_enable_status
            ;;
        2)
            echo -e "V2bX状态: ${red}未安装${plain}"
    esac
    
    # 显示当前优先级和可切换目标
    local current=$(get_current_priority)
    if [[ "$current" == "ipv6" ]]; then
        echo -e "IP优先级: ${green}IPv6优先${plain}"
        echo -e "可切换为: ${yellow}IPv4优先${plain}"
    else
        echo -e "IP优先级: ${yellow}IPv4优先${plain}"
        echo -e "可切换为: ${green}IPv6优先${plain}"
    fi
}

show_enable_status() {
    check_enabled
    if [[ $? == 0 ]]; then
        echo -e "是否开机自启: ${green}是${plain}"
    else
        echo -e "是否开机自启: ${red}否${plain}"
    fi
}

generate_x25519_key() {
    echo -n "正在生成 x25519 密钥："
    /usr/local/V2bX/V2bX x25519
    echo ""
    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

show_V2bX_version() {
    echo -n "V2bX 版本："
    /usr/local/V2bX/V2bX version
    echo ""
    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}


# 添加节点到现有配置
add_new_node() {
    check_install
    if [[ $? != 0 ]]; then
        return 1
    fi

    if [[ ! -f /etc/V2bX/config.json ]]; then
        echo -e "${red}配置文件不存在，请先生成配置文件${plain}"
        before_show_menu
        return 1
    fi

    echo -e "${green}添加节点配置${plain}"
    echo -e "${yellow}================================================${plain}"

    # 读取当前配置文件中的IP优先级
    current_priority=$(get_current_priority)
    echo -e "${green}当前配置优先级: ${current_priority}${plain}"

    # 检查配置文件中是否已有节点
    local node_count=$(jq '.Nodes | length' /etc/V2bX/config.json 2>/dev/null)

    if [[ $node_count -gt 0 ]]; then
        # 有节点时才询问是否使用现有API信息
        read -rp "是否使用配置文件中已有的API信息？(y/n): " use_existing_api
        if [[ "$use_existing_api" =~ ^[Yy]$ ]]; then
            # 从配置文件中读取第一个节点的API信息
            ApiHost=$(jq -r '.Nodes[0].ApiHost' /etc/V2bX/config.json)
            ApiKey=$(jq -r '.Nodes[0].ApiKey' /etc/V2bX/config.json)
            echo -e "${green}使用API地址: $ApiHost${plain}"
        else
            read -rp "请输入机场网址(https://example.com)：" ApiHost
            read -rp "请输入面板对接API Key：" ApiKey
        fi
    else
        # 没有节点时直接输入
        echo -e "${yellow}配置文件中没有现有节点，请输入API信息${plain}"
        read -rp "请输入机场网址(https://example.com)：" ApiHost
        read -rp "请输入面板对接API Key：" ApiKey
    fi

    # 调用原有的节点配置函数，传入use_current_priority标记
    nodes_config=()
    use_current_priority=true
    add_node_config
    # 重置标记，避免影响其他函数调用
    use_current_priority=false

    # 备份配置文件
    local timestamp=$(date +%Y%m%d_%H%M%S)
    cp /etc/V2bX/config.json /etc/V2bX/config.json.bak.$timestamp
    echo -e "${yellow}配置文件已备份到: config.json.bak.$timestamp${plain}"

    # 使用jq添加新节点到配置文件
    local new_node="${nodes_config[0]}"
    # 移除末尾的逗号
    new_node="${new_node%,}"

    # 将新节点添加到Nodes数组
    jq ".Nodes += [$new_node]" /etc/V2bX/config.json > /tmp/config_tmp.json
    if [[ $? -eq 0 ]]; then
        mv /tmp/config_tmp.json /etc/V2bX/config.json
        echo -e "${green}节点已成功添加到配置文件${plain}"

        # 自动重启服务
        echo -e "${green}正在重启 V2bX...${plain}"
        restart 0
        echo -e "${green}V2bX 已重启，节点已生效${plain}"
    else
        echo -e "${red}添加节点失败，配置文件已回滚${plain}"
        mv /etc/V2bX/config.json.bak.$timestamp /etc/V2bX/config.json
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

# 删除节点
delete_node() {
    check_install
    if [[ $? != 0 ]]; then
        return 1
    fi

    if [[ ! -f /etc/V2bX/config.json ]]; then
        echo -e "${red}配置文件不存在${plain}"
        before_show_menu
        return 1
    fi

    # 检查是否安装了jq
    if ! command -v jq >/dev/null 2>&1; then
        echo -e "${red}需要安装jq工具，正在安装...${plain}"
        if [[ x"${release}" == x"centos" ]]; then
            yum install jq -y
        elif [[ x"${release}" == x"alpine" ]]; then
            apk add jq
        else
            apt install jq -y
        fi
    fi

    echo -e "${green}节点列表${plain}"
    echo -e "${yellow}================================================${plain}"

    # 读取并显示所有节点
    local node_count=$(jq '.Nodes | length' /etc/V2bX/config.json)

    if [[ $node_count -eq 0 ]]; then
        echo -e "${red}配置文件中没有节点${plain}"
        before_show_menu
        return 1
    fi

    echo -e "${green}序号 | NodeID | 节点类型 | 核心类型 | API地址${plain}"
    echo "------------------------------------------------------------"

    for ((i=0; i<$node_count; i++)); do
        local node_id=$(jq -r ".Nodes[$i].NodeID" /etc/V2bX/config.json)
        local node_type=$(jq -r ".Nodes[$i].NodeType" /etc/V2bX/config.json)
        local core=$(jq -r ".Nodes[$i].Core" /etc/V2bX/config.json)
        local api_host=$(jq -r ".Nodes[$i].ApiHost" /etc/V2bX/config.json)
        echo -e "${green}$((i+1))${plain}    | $node_id | $node_type | $core | $api_host"
    done

    echo "------------------------------------------------------------"
    echo -e "${yellow}当前共有 $node_count 个节点${plain}"
    echo ""

    # 如果只有一个节点，警告用户
    if [[ $node_count -eq 1 ]]; then
        echo -e "${red}警告：这是最后一个节点，删除后配置文件将没有节点！${plain}"
    fi

    read -rp "请输入要删除的节点序号 (1-$node_count，输入0取消): " node_index

    if [[ "$node_index" == "0" ]]; then
        echo -e "${yellow}已取消删除${plain}"
        before_show_menu
        return 0
    fi

    # 验证输入
    if ! [[ "$node_index" =~ ^[0-9]+$ ]] || [[ $node_index -lt 1 ]] || [[ $node_index -gt $node_count ]]; then
        echo -e "${red}无效的序号${plain}"
        before_show_menu
        return 1
    fi

    # 显示要删除的节点信息
    local array_index=$((node_index-1))
    local del_node_id=$(jq -r ".Nodes[$array_index].NodeID" /etc/V2bX/config.json)
    local del_node_type=$(jq -r ".Nodes[$array_index].NodeType" /etc/V2bX/config.json)
    local del_core=$(jq -r ".Nodes[$array_index].Core" /etc/V2bX/config.json)

    echo ""
    echo -e "${yellow}即将删除：${plain}"
    echo -e "  NodeID: ${red}$del_node_id${plain}"
    echo -e "  节点类型: ${red}$del_node_type${plain}"
    echo -e "  核心类型: ${red}$del_core${plain}"
    echo ""

    read -rp "确认删除此节点吗？(y/n): " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo -e "${yellow}已取消删除${plain}"
        before_show_menu
        return 0
    fi

    # 备份配置文件
    local timestamp=$(date +%Y%m%d_%H%M%S)
    cp /etc/V2bX/config.json /etc/V2bX/config.json.bak.$timestamp
    echo -e "${yellow}配置文件已备份到: config.json.bak.$timestamp${plain}"

    # 删除节点
    jq "del(.Nodes[$array_index])" /etc/V2bX/config.json > /tmp/config_tmp.json
    if [[ $? -eq 0 ]]; then
        mv /tmp/config_tmp.json /etc/V2bX/config.json
        echo -e "${green}节点已成功删除${plain}"

        # 自动重启服务
        echo -e "${green}正在重启 V2bX...${plain}"
        restart 0
        echo -e "${green}V2bX 已重启，配置已生效${plain}"
    else
        echo -e "${red}删除节点失败，配置文件已回滚${plain}"
        mv /etc/V2bX/config.json.bak.$timestamp /etc/V2bX/config.json
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

# 节点配置自动根据 IPv4/IPv6 生成
add_node_config() {
    # 如果是添加新节点，使用当前配置的优先级；否则自动检测系统
    if [[ "$use_current_priority" == "true" ]]; then
        ip_priority=$(get_current_priority)
        echo -e "${yellow}使用当前配置的IP优先级: ${ip_priority}${plain}"
    else
        ip_priority=$(get_ip_priority)
    fi

    # ListenIP 永远是 "::" 以支持双栈
    listen_ip="::"

    # 根据优先级设置 SendIP
    if [[ "$ip_priority" == "ipv6" ]]; then
        send_ip="::"
        dnsstrategy="prefer_ipv6"
        dnstype="UseIP"
    else
        send_ip="0.0.0.0"
        dnsstrategy="ipv4_only"
        dnstype="UseIPv4"
    fi

    echo -e "${green}请选择节点核心类型：${plain}"
    echo -e "${green}1. xray${plain}"
    echo -e "${green}2. singbox${plain}"
    echo -e "${green}3. hysteria2${plain}"
    read -rp "请输入：" core_type
    if [ "$core_type" == "1" ]; then
        core="xray"
        core_xray=true
    elif [ "$core_type" == "2" ]; then
        core="sing"
        core_sing=true
    elif [ "$core_type" == "3" ]; then
        core="hysteria2"
        core_hysteria2=true
    else
        echo "无效的选择。请选择 1 2 3。"
        continue
    fi
    while true; do
        read -rp "请输入节点Node ID：" NodeID
        # 判断NodeID是否为正整数
        if [[ "$NodeID" =~ ^[0-9]+$ ]]; then
            break  # 输入正确，退出循环
        else
            echo "错误：请输入正确的数字作为Node ID。"
        fi
    done

    if [ "$core_hysteria2" = true ] && [ "$core_xray" = false ] && [ "$core_sing" = false ]; then
        NodeType="hysteria2"
    else
        echo -e "${yellow}请选择节点传输协议：${plain}"
        echo -e "${green}1. Shadowsocks${plain}"
        echo -e "${green}2. Vless${plain}"
        echo -e "${green}3. Vmess${plain}"
        if [ "$core_sing" == true ]; then
            echo -e "${green}4. Hysteria${plain}"
            echo -e "${green}5. Hysteria2${plain}"
        fi
        if [ "$core_hysteria2" == true ] && [ "$core_sing" = false ]; then
            echo -e "${green}5. Hysteria2${plain}"
        fi
        echo -e "${green}6. Trojan${plain}"  
        if [ "$core_sing" == true ]; then
            echo -e "${green}7. Tuic${plain}"
            echo -e "${green}8. AnyTLS${plain}"
        fi
        read -rp "请输入：" NodeType
        case "$NodeType" in
            1 ) NodeType="shadowsocks" ;;
            2 ) NodeType="vless" ;;
            3 ) NodeType="vmess" ;;
            4 ) NodeType="hysteria" ;;
            5 ) NodeType="hysteria2" ;;
            6 ) NodeType="trojan" ;;
            7 ) NodeType="tuic" ;;
            8 ) NodeType="anytls" ;;
            * ) NodeType="shadowsocks" ;;
        esac
    fi
    fastopen=true
    if [ "$NodeType" == "vless" ]; then
        read -rp "请选择是否为reality节点？(y/n)" isreality
    elif [ "$NodeType" == "hysteria" ] || [ "$NodeType" == "hysteria2" ] || [ "$NodeType" == "tuic" ] || [ "$NodeType" == "anytls" ]; then
        fastopen=false
        istls="y"
    fi

    if [[ "$isreality" != "y" && "$isreality" != "Y" &&  "$istls" != "y" ]]; then
        read -rp "请选择是否进行TLS配置？(y/n)" istls
    fi

    certmode="none"
    certdomain="example.com"
    if [[ "$isreality" != "y" && "$isreality" != "Y" && ( "$istls" == "y" || "$istls" == "Y" ) ]]; then
        echo -e "${yellow}请选择证书申请模式：${plain}"
        echo -e "${green}1. http模式自动申请，节点域名已正确解析${plain}"
        echo -e "${green}2. dns模式自动申请，需填入正确域名服务商API参数${plain}"
        echo -e "${green}3. self模式，自签证书或提供已有证书文件${plain}"
        read -rp "请输入：" certmode
        case "$certmode" in
            1 ) certmode="http" ;;
            2 ) certmode="dns" ;;
            3 ) certmode="self" ;;
        esac
        read -rp "请输入节点证书域名(example.com)：" certdomain
        if [ "$certmode" != "http" ]; then
            echo -e "${red}请手动修改配置文件后重启V2bX！${plain}"
        fi
    fi

    node_config=""
    if [ "$core_type" == "1" ]; then 
    node_config=$(cat <<EOF
{
        "Core": "$core",
        "ApiHost": "$ApiHost",
        "ApiKey": "$ApiKey",
        "NodeID": $NodeID,
        "NodeType": "$NodeType",
        "Timeout": 30,
        "ListenIP": "$listen_ip",
        "SendIP": "$send_ip",
        "DeviceOnlineMinTraffic": 200,
        "MinReportTraffic": 0,
        "EnableProxyProtocol": false,
        "EnableUot": true,
        "EnableTFO": true,
        "DNSType": "$dnstype",
        "CertConfig": {
            "CertMode": "$certmode",
            "RejectUnknownSni": false,
            "CertDomain": "$certdomain",
            "CertFile": "/etc/V2bX/fullchain.cer",
            "KeyFile": "/etc/V2bX/cert.key",
            "Email": "v2bx@github.com",
            "Provider": "cloudflare",
            "DNSEnv": {
                "EnvName": "env1"
            }
        }
    },
EOF
)
    elif [ "$core_type" == "2" ]; then
    node_config=$(cat <<EOF
{
        "Core": "$core",
        "ApiHost": "$ApiHost",
        "ApiKey": "$ApiKey",
        "NodeID": $NodeID,
        "NodeType": "$NodeType",
        "Timeout": 30,
        "ListenIP": "$listen_ip",
        "SendIP": "$send_ip",
        "DeviceOnlineMinTraffic": 200,
        "MinReportTraffic": 0,
        "TCPFastOpen": $fastopen,
        "SniffEnabled": true,
        "CertConfig": {
            "CertMode": "$certmode",
            "RejectUnknownSni": false,
            "CertDomain": "$certdomain",
            "CertFile": "/etc/V2bX/fullchain.cer",
            "KeyFile": "/etc/V2bX/cert.key",
            "Email": "v2bx@github.com",
            "Provider": "cloudflare",
            "DNSEnv": {
                "EnvName": "env1"
            }
        }
    },
EOF
)
    elif [ "$core_type" == "3" ]; then
    node_config=$(cat <<EOF
{
        "Core": "$core",
        "ApiHost": "$ApiHost",
        "ApiKey": "$ApiKey",
        "NodeID": $NodeID,
        "NodeType": "$NodeType",
        "Hysteria2ConfigPath": "/etc/V2bX/hy2config.yaml",
        "Timeout": 30,
        "ListenIP": "",
        "SendIP": "$send_ip",
        "DeviceOnlineMinTraffic": 200,
        "MinReportTraffic": 0,
        "CertConfig": {
            "CertMode": "$certmode",
            "RejectUnknownSni": false,
            "CertDomain": "$certdomain",
            "CertFile": "/etc/V2bX/fullchain.cer",
            "KeyFile": "/etc/V2bX/cert.key",
            "Email": "v2bx@github.com",
            "Provider": "cloudflare",
            "DNSEnv": {
                "EnvName": "env1"
            }
        }
    },
EOF
)
    fi
    nodes_config+=("$node_config")
}

generate_config_file() {
    echo -e "${yellow}V2bX 配置文件生成向导${plain}"
    echo -e "${red}请阅读以下注意事项：${plain}"
    echo -e "${red}1. 目前该功能正处测试阶段${plain}"
    echo -e "${red}2. 生成的配置文件会保存到 /etc/V2bX/config.json${plain}"
    echo -e "${red}3. 原来的配置文件会保存到 /etc/V2bX/config.json.bak${plain}"
    echo -e "${red}4. 目前仅部分支持TLS${plain}"
    echo -e "${red}5. 使用此功能生成的配置文件会自带审计，确定继续？(y/n)${plain}"
    read -rp "请输入：" continue_prompt
    if [[ "$continue_prompt" =~ ^[Nn][Oo]? ]]; then
        exit 0
    fi

    nodes_config=()
    first_node=true
    core_xray=false
    core_sing=false
    fixed_api_info=false
    check_api=false
    # 生成配置文件时使用系统检测，不使用现有配置
    use_current_priority=false
    
    while true; do
        if [ "$first_node" = true ]; then
            read -rp "请输入机场网址(https://example.com)：" ApiHost
            read -rp "请输入面板对接API Key：" ApiKey
            read -rp "是否设置固定的机场网址和API Key？(y/n)" fixed_api
            if [ "$fixed_api" = "y" ] || [ "$fixed_api" = "Y" ]; then
                fixed_api_info=true
                echo -e "${red}成功固定地址${plain}"
            fi
            first_node=false
            add_node_config
        else
            read -rp "是否继续添加节点配置？(回车继续，输入n或no退出)" continue_adding_node
            if [[ "$continue_adding_node" =~ ^[Nn][Oo]? ]]; then
                break
            elif [ "$fixed_api_info" = false ]; then
                read -rp "请输入机场网址：" ApiHost
                read -rp "请输入面板对接API Key：" ApiKey
            fi
            add_node_config
        fi
    done

    # 初始化核心配置数组
    cores_config="["

    # 检查并添加xray核心配置
    if [ "$core_xray" = true ]; then
        cores_config+="
    {
        \"Type\": \"xray\",
        \"Log\": {
            \"Level\": \"error\",
            \"ErrorPath\": \"/etc/V2bX/error.log\"
        },
        \"OutboundConfigPath\": \"/etc/V2bX/custom_outbound.json\",
        \"RouteConfigPath\": \"/etc/V2bX/route.json\"
    },"
    fi

    # 检查并添加sing核心配置
    if [ "$core_sing" = true ]; then
        cores_config+="
    {
        \"Type\": \"sing\",
        \"Log\": {
            \"Level\": \"error\",
            \"Timestamp\": true
        },
        \"NTP\": {
            \"Enable\": false,
            \"Server\": \"time.apple.com\",
            \"ServerPort\": 0
        },
        \"OriginalPath\": \"/etc/V2bX/sing_origin.json\"
    },"
    fi

    # 检查并添加hysteria2核心配置
    if [ "$core_hysteria2" = true ]; then
        cores_config+="
    {
        \"Type\": \"hysteria2\",
        \"Log\": {
            \"Level\": \"error\"
        }
    },"
    fi

    # 移除最后一个逗号并关闭数组
    cores_config+="]"
    cores_config=$(echo "$cores_config" | sed 's/},]$/}]/')

    # 切换到配置文件目录
    cd /etc/V2bX
    
    # 备份旧的配置文件
    mv config.json config.json.bak
    nodes_config_str="${nodes_config[*]}"
    formatted_nodes_config="${nodes_config_str%,}"

    # 创建 config.json 文件
    cat <<EOF > /etc/V2bX/config.json
{
    "Log": {
        "Level": "error",
        "Output": ""
    },
    "Cores": $cores_config,
    "Nodes": [$formatted_nodes_config]
}
EOF
    
    # 创建 custom_outbound.json 文件
    cat <<EOF > /etc/V2bX/custom_outbound.json
    [
        {
            "tag": "IPv4_out",
            "protocol": "freedom",
            "settings": {
                "domainStrategy": "UseIPv4v6"
            }
        },
        {
            "tag": "IPv6_out",
            "protocol": "freedom",
            "settings": {
                "domainStrategy": "UseIPv6"
            }
        },
        {
            "protocol": "blackhole",
            "tag": "block"
        }
    ]
EOF
    
    # 创建 route.json 文件
    cat <<EOF > /etc/V2bX/route.json
    {
        "domainStrategy": "AsIs",
        "rules": [
            {
                "type": "field",
                "outboundTag": "block",
                "ip": [
                    "geoip:private"
                ]
            },
            {
                "type": "field",
                "outboundTag": "block",
                "domain": [
                    "regexp:(api|ps|sv|offnavi|newvector|ulog.imap|newloc)(.map|).(baidu|n.shifen).com",
                    "regexp:(.+.|^)(360|so).(cn|com)",
                    "regexp:(Subject|HELO|SMTP)",
                    "regexp:(torrent|.torrent|peer_id=|info_hash|get_peers|find_node|BitTorrent|announce_peer|announce.php?passkey=)",
                    "regexp:(^.@)(guerrillamail|guerrillamailblock|sharklasers|grr|pokemail|spam4|bccto|chacuo|027168).(info|biz|com|de|net|org|me|la)",
                    "regexp:(.?)(xunlei|sandai|Thunder|XLLiveUD)(.)",
                    "regexp:(..||)(dafahao|mingjinglive|botanwang|minghui|dongtaiwang|falunaz|epochtimes|ntdtv|falundafa|falungong|wujieliulan|zhengjian).(org|com|net)",
                    "regexp:(ed2k|.torrent|peer_id=|announce|info_hash|get_peers|find_node|BitTorrent|announce_peer|announce.php?passkey=|magnet:|xunlei|sandai|Thunder|XLLiveUD|bt_key)",
                    "regexp:(.+.|^)(360).(cn|com|net)",
                    "regexp:(.*.||)(guanjia.qq.com|qqpcmgr|QQPCMGR)",
                    "regexp:(.*.||)(rising|kingsoft|duba|xindubawukong|jinshanduba).(com|net|org)",
                    "regexp:(.*.||)(netvigator|torproject).(com|cn|net|org)",
                    "regexp:(..||)(visa|mycard|gash|beanfun|bank).",
                    "regexp:(.*.||)(gov|12377|12315|talk.news.pts.org|creaders|zhuichaguoji|efcc.org|cyberpolice|aboluowang|tuidang|epochtimes|zhengjian|110.qq|mingjingnews|inmediahk|xinsheng|breakgfw|chengmingmag|jinpianwang|qi-gong|mhradio|edoors|renminbao|soundofhope|xizang-zhiye|bannedbook|ntdtv|12321|secretchina|dajiyuan|boxun|chinadigitaltimes|dwnews|huaglad|oneplusnews|epochweekly|cn.rfi).(cn|com|org|net|club|net|fr|tw|hk|eu|info|me)",
                    "regexp:(.*.||)(miaozhen|cnzz|talkingdata|umeng).(cn|com)",
                    "regexp:(.*.||)(mycard).(com|tw)",
                    "regexp:(.*.||)(gash).(com|tw)",
                    "(.bank.)",
                    "regexp:(.*.||)(pincong).(rocks)",
                    "regexp:(.*.||)(taobao).(com)",
                    "regexp:(.*.||)(laomoe|jiyou|ssss|lolicp|vv1234|0z|4321q|868123|ksweb|mm126).(com|cloud|fun|cn|gs|xyz|cc)",
                    "regexp:(flows|miaoko).(pages).(dev)"
                ]
            },
            {
                "type": "field",
                "outboundTag": "block",
                "ip": [
                    "127.0.0.1/32",
                    "10.0.0.0/8",
                    "fc00::/7",
                    "fe80::/10",
                    "172.16.0.0/12"
                ]
            },
            {
                "type": "field",
                "outboundTag": "block",
                "protocol": [
                    "bittorrent"
                ]
            }
        ]
    }
EOF

    ip_priority=$(get_ip_priority)
    if [[ "$ip_priority" == "ipv6" ]]; then
        dnsstrategy="prefer_ipv6"
    else
        dnsstrategy="ipv4_only"
    fi
    # 创建 sing_origin.json 文件
    cat <<EOF > /etc/V2bX/sing_origin.json
{
  "dns": {
    "servers": [
      {
        "tag": "cf",
        "address": "1.1.1.1"
      }
    ],
    "strategy": "$dnsstrategy"
  },
  "outbounds": [
    {
      "tag": "direct",
      "type": "direct",
      "domain_resolver": {
        "server": "cf",
        "strategy": "$dnsstrategy"
      }
    },
    {
      "type": "block",
      "tag": "block"
    }
  ],
  "route": {
    "rules": [
      {
        "ip_is_private": true,
        "outbound": "block"
      },
      {
        "domain_regex": [
            "(api|ps|sv|offnavi|newvector|ulog.imap|newloc)(.map|).(baidu|n.shifen).com",
            "(.+.|^)(360|so).(cn|com)",
            "(Subject|HELO|SMTP)",
            "(torrent|.torrent|peer_id=|info_hash|get_peers|find_node|BitTorrent|announce_peer|announce.php?passkey=)",
            "(^.@)(guerrillamail|guerrillamailblock|sharklasers|grr|pokemail|spam4|bccto|chacuo|027168).(info|biz|com|de|net|org|me|la)",
            "(.?)(xunlei|sandai|Thunder|XLLiveUD)(.)",
            "(..||)(dafahao|mingjinglive|botanwang|minghui|dongtaiwang|falunaz|epochtimes|ntdtv|falundafa|falungong|wujieliulan|zhengjian).(org|com|net)",
            "(ed2k|.torrent|peer_id=|announce|info_hash|get_peers|find_node|BitTorrent|announce_peer|announce.php?passkey=|magnet:|xunlei|sandai|Thunder|XLLiveUD|bt_key)",
            "(.+.|^)(360).(cn|com|net)",
            "(.*.||)(guanjia.qq.com|qqpcmgr|QQPCMGR)",
            "(.*.||)(rising|kingsoft|duba|xindubawukong|jinshanduba).(com|net|org)",
            "(.*.||)(netvigator|torproject).(com|cn|net|org)",
            "(..||)(visa|mycard|gash|beanfun|bank).",
            "(.*.||)(gov|12377|12315|talk.news.pts.org|creaders|zhuichaguoji|efcc.org|cyberpolice|aboluowang|tuidang|epochtimes|zhengjian|110.qq|mingjingnews|inmediahk|xinsheng|breakgfw|chengmingmag|jinpianwang|qi-gong|mhradio|edoors|renminbao|soundofhope|xizang-zhiye|bannedbook|ntdtv|12321|secretchina|dajiyuan|boxun|chinadigitaltimes|dwnews|huaglad|oneplusnews|epochweekly|cn.rfi).(cn|com|org|net|club|net|fr|tw|hk|eu|info|me)",
            "(.*.||)(miaozhen|cnzz|talkingdata|umeng).(cn|com)",
            "(.*.||)(mycard).(com|tw)",
            "(.*.||)(gash).(com|tw)",
            "(.bank.)",
            "(.*.||)(pincong).(rocks)",
            "(.*.||)(taobao).(com)",
            "(.*.||)(laomoe|jiyou|ssss|lolicp|vv1234|0z|4321q|868123|ksweb|mm126).(com|cloud|fun|cn|gs|xyz|cc)",
            "(flows|miaoko).(pages).(dev)"
        ],
        "outbound": "block"
      },
      {
        "outbound": "direct",
        "network": [
          "udp","tcp"
        ]
      }
    ]
  },
  "experimental": {
    "cache_file": {
      "enabled": true
    }
  }
}
EOF

    # 创建 hy2config.yaml 文件           
    cat <<EOF > /etc/V2bX/hy2config.yaml
quic:
  initStreamReceiveWindow: 8388608
  maxStreamReceiveWindow: 8388608
  initConnReceiveWindow: 20971520
  maxConnReceiveWindow: 20971520
  maxIdleTimeout: 30s
  maxIncomingStreams: 1024
  disablePathMTUDiscovery: false
ignoreClientBandwidth: false
disableUDP: false
udpIdleTimeout: 60s
resolver:
  type: system
acl:
  inline:
    - direct(geosite:google)
    - reject(geosite:cn)
    - reject(geoip:cn)
masquerade:
  type: 404
EOF
    echo -e "${green}V2bX 配置文件生成完成，正在重新启动 V2bX 服务${plain}"
    restart 0
    before_show_menu
}

show_usage() {
    echo "V2bX 管理脚本使用方法: "
    echo "------------------------------------------"
    echo "V2bX              - 显示管理菜单 (功能更多)"
    echo "V2bX start        - 启动 V2bX"
    echo "V2bX stop         - 停止 V2bX"
    echo "V2bX restart      - 重启 V2bX"
    echo "V2bX status       - 查看 V2bX 状态"
    echo "V2bX enable       - 设置 V2bX 开机自启"
    echo "V2bX disable      - 取消 V2bX 开机自启"
    echo "V2bX log          - 查看 V2bX 日志"
    echo "V2bX x25519       - 生成 x25519 密钥"
    echo "V2bX generate     - 生成 V2bX 配置文件"
    echo "V2bX addnode      - 添加节点到配置"
    echo "V2bX delnode      - 删除节点"
    echo "V2bX update       - 更新 V2bX"
    echo "V2bX update x.x.x - 安装 V2bX 指定版本"
    echo "V2bX install      - 安装 V2bX"
    echo "V2bX uninstall    - 卸载 V2bX"
    echo "V2bX version      - 查看 V2bX 版本"
    echo "------------------------------------------"
}

show_menu() {
    echo -e "
  ${green}V2bX 后端管理脚本，${plain}${red}不适用于docker${plain}
--- [https://github.com/wyx2685/V2bX](https://github.com/wyx2685/V2bX) ---
  ${green}0.${plain} 修改配置
————————————————
  ${green}1.${plain} 安装 V2bX
  ${green}2.${plain} 更新 V2bX
  ${green}3.${plain} 卸载 V2bX
————————————————
  ${green}4.${plain} 启动 V2bX
  ${green}5.${plain} 停止 V2bX
  ${green}6.${plain} 重启 V2bX
  ${green}7.${plain} 查看 V2bX 状态
  ${green}8.${plain} 查看 V2bX 日志
————————————————
  ${green}9.${plain} 设置 V2bX 开机自启
  ${green}10.${plain} 取消 V2bX 开机自启
————————————————
  ${green}11.${plain} 查看 V2bX 版本
  ${green}12.${plain} 生成 X25519 密钥
  ${green}13.${plain} 升级 V2bX 维护脚本
  ${green}14.${plain} 生成 V2bX 配置文件
  ${green}15.${plain} 添加节点
  ${green}16.${plain} 删除节点
  ${green}17.${plain} 切换 IP 优先级
  ${green}18.${plain} 退出脚本
 "
    show_status
    echo && read -rp "请输入选择 [0-18]: " num

    case "${num}" in
        0) config ;;
        1) check_uninstall && install ;;
        2) check_install && update ;;
        3) check_install && uninstall ;;
        4) check_install && start ;;
        5) check_install && stop ;;
        6) check_install && restart ;;
        7) check_install && status ;;
        8) check_install && show_log ;;
        9) check_install && enable ;;
        10) check_install && disable ;;
        11) check_install && show_V2bX_version ;;
        12) check_install && generate_x25519_key ;;
        13) update_shell ;;
        14) generate_config_file ;;
        15) add_new_node ;;
        16) delete_node ;;
        17) switch_ip_priority ;;
        18) exit ;;
        *) echo -e "${red}请输入正确的数字 [0-18]${plain}" ;;
    esac
}

if [[ $# > 0 ]]; then
    case $1 in
        "start") check_install 0 && start 0 ;;
        "stop") check_install 0 && stop 0 ;;
        "restart") check_install 0 && restart 0 ;;
        "status") check_install 0 && status 0 ;;
        "enable") check_install 0 && enable 0 ;;
        "disable") check_install 0 && disable 0 ;;
        "log") check_install 0 && show_log 0 ;;
        "update") check_install 0 && update 0 $2 ;;
        "config") config $* ;;
        "generate") generate_config_file ;;
        "addnode") check_install 0 && add_new_node ;;
        "delnode") check_install 0 && delete_node ;;
        "install") check_uninstall 0 && install 0 ;;
        "uninstall") check_install 0 && uninstall 0 ;;
        "x25519") check_install 0 && generate_x25519_key 0 ;;
        "version") check_install 0 && show_V2bX_version 0 ;;
        "update_shell") update_shell ;;
        *) show_usage
    esac
else
    show_menu
fi
