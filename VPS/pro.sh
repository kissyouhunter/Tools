#!/bin/bash

# --- 配置参数 ---
CONFIG_PATH="/usr/local/etc/xray/config.json"
BACKUP_DIR="/usr/local/etc/xray/"
LOG_DIR="/var/log/xray/"
VMESS_OUTPUT_FILE="/root/vmess.txt"
SOCKS5_OUTPUT_FILE="/root/ss5.txt"
SHADOWSOCKS_OUTPUT_FILE="/root/shadowsocks.txt"
PRIORITY_FILE="/usr/local/etc/xray/priority.txt"

# --- 颜色定义 ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# --- 进度指示器 ---
show_progress() {
    local duration=$1
    local message=$2
    local command=$3
    
    echo -e "${CYAN}${message}${NC}"
    
    # 如果没有提供命令，使用原来的假进度条
    if [ -z "$command" ]; then
        local progress=0
        local bar_length=30
        
        while [ $progress -le 100 ]; do
            local filled=$((progress * bar_length / 100))
            local empty=$((bar_length - filled))
            
            printf "\r${BLUE}["
            printf "%*s" $filled | tr ' ' '='
            printf "%*s" $empty | tr ' ' ' '
            printf "] ${WHITE}%d%%${NC}" $progress
            
            sleep $(echo "scale=2; $duration/100" | bc -l 2>/dev/null || echo "0.05")
            progress=$((progress + 5))
        done
        echo
        return 0
    fi
    
    # 后台执行实际命令，重定向所有输出
    eval "$command" >/dev/null 2>&1 &
    local cmd_pid=$!
    
    # 前台显示进度条，直到命令完成
    local progress=0
    local spinner_chars="⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"
    local spinner_index=0
    
    while kill -0 $cmd_pid 2>/dev/null; do
        # 显示旋转指示器和进度条
        local spinner_char=${spinner_chars:$spinner_index:1}
        printf "\r${BLUE}${spinner_char} ["
        
        # 绘制进度条
        local filled=$((progress * 30 / 100))
        local empty=$((30 - filled))
        printf "%*s" $filled | tr ' ' '='
        printf "%*s" $empty | tr ' ' ' '
        printf "] ${WHITE}%d%% ${message}...${NC}" $progress
        
        sleep 0.2
        progress=$(((progress + 2) % 95))  # 保持在95%以下直到完成
        spinner_index=$(((spinner_index + 1) % ${#spinner_chars}))
    done
    
    # 等待命令完成并获取结果
    wait $cmd_pid
    local cmd_result=$?
    
    # 显示最终结果
    if [ $cmd_result -eq 0 ]; then
        printf "\r${GREEN}✓ ["
        printf "%*s" 30 | tr ' ' '='
        printf "] ${WHITE}100%% ${message} 完成${NC}\n"
        return 0
    else
        printf "\r${RED}✗ ["
        printf "%*s" 30 | tr ' ' '='
        printf "] ${WHITE}100%% ${message} 失败${NC}\n"
        return 1
    fi
}

# --- 函数定义 ---
check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}本脚本需要以 root 用户执行，请使用 sudo 或以 root 用户执行。${NC}"
        exit 1
    fi
}

# 检查Xray是否安装
check_xray_installed() {
    if command -v xray &> /dev/null; then
        echo -e "${GREEN}已安装${NC}"
        return 0
    else
        echo -e "${RED}未安装${NC}"
        return 1
    fi
}

# 检查Xray服务状态
check_xray_status() {
    if systemctl is-active --quiet xray 2>/dev/null; then
        echo -e "${GREEN}运行中${NC}"
        return 0
    else
        echo -e "${RED}已停止${NC}"
        return 1
    fi
}

# 检查Xray开机自启状态
check_xray_enabled() {
    if systemctl is-enabled --quiet xray 2>/dev/null; then
        echo -e "${GREEN}已启用${NC}"
        return 0
    else
        echo -e "${RED}已禁用${NC}"
        return 1
    fi
}

# 启动Xray服务
start_xray() {
    if systemctl is-active --quiet xray; then
        echo -e "${YELLOW}Xray 服务已在运行中${NC}"
        return 0
    fi
    
    echo -e "${CYAN}正在启动 Xray 服务...${NC}"
    show_progress 2 "启动 Xray 服务" "systemctl start xray"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Xray 服务启动成功${NC}"
    else
        echo -e "${RED}✗ Xray 服务启动失败${NC}"
        echo -e "${YELLOW}查看错误日志：${NC}"
        journalctl -u xray -n 10 --no-pager
    fi
}

# 停止Xray服务
stop_xray() {
    if ! systemctl is-active --quiet xray; then
        echo -e "${YELLOW}Xray 服务未在运行${NC}"
        return 0
    fi
    
    echo -e "${CYAN}正在停止 Xray 服务...${NC}"
    show_progress 2 "停止 Xray 服务" "systemctl stop xray"

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Xray 服务停止成功${NC}"
    else
        echo -e "${RED}✗ Xray 服务停止失败${NC}"
    fi
}

# 重启Xray服务
restart_xray() {
    echo -e "${CYAN}正在重启 Xray 服务...${NC}"
    show_progress 3 "重启 Xray 服务" "systemctl restart xray"

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Xray 服务重启成功${NC}"
    else
        echo -e "${RED}✗ Xray 服务重启失败${NC}"
        echo -e "${YELLOW}查看错误日志：${NC}"
        journalctl -u xray -n 10 --no-pager
    fi
}

# 升级 Xray
upgrade_xray() {
    if ! command -v xray &>/dev/null; then
        echo -e "${RED}检测到 Xray 未安装，无法升级。${NC}"
        return 1
    fi
    echo -e "${CYAN}正在升级 Xray...${NC}"
    show_progress 8 "升级 Xray" 'bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install'
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Xray 升级完成${NC}"
    else
        echo -e "${RED}✗ Xray 升级失败，请检查日志${NC}"
    fi
}

# 启用开机自启
enable_xray() {
    if systemctl is-enabled --quiet xray; then
        echo -e "${YELLOW}Xray 开机自启已启用${NC}"
        return 0
    fi
    
    echo -e "${CYAN}正在启用 Xray 开机自启...${NC}"
    show_progress 1 "启用开机自启" "systemctl enable xray"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Xray 开机自启启用成功${NC}"
    else
        echo -e "${RED}✗ Xray 开机自启启用失败${NC}"
    fi
}

# 禁用开机自启
disable_xray() {
    if ! systemctl is-enabled --quiet xray; then
        echo -e "${YELLOW}Xray 开机自启已禁用${NC}"
        return 0
    fi
    
    echo -e "${CYAN}正在禁用 Xray 开机自启...${NC}"
    show_progress 1 "禁用开机自启" "systemctl disable xray"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Xray 开机自启禁用成功${NC}"
    else
        echo -e "${RED}✗ Xray 开机自启禁用失败${NC}"
    fi
}

# 清理超过 30 天的备份文件
cleanup_old_backups() {
    find "$BACKUP_DIR" -name 'config_*.json' -mtime +30 -delete 2>/dev/null
    echo -e "${GREEN}已清理 30 天前的备份文件${NC}"
}

# 确保 jq 已安装
ensure_jq_installed() {
    if ! command -v jq &> /dev/null; then
        echo -e "${YELLOW}jq 未安装，正在尝试自动安装...${NC}"
        
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            case $ID in
                ubuntu|debian)
                    show_progress 5 "安装 jq" "apt update -qq && apt install -y jq"
                    ;;
                centos|rhel)
                    show_progress 5 "安装 jq" "yum install -y jq"
                    ;;
                *)
                    echo -e "${RED}不支持的系统，请手动安装 jq${NC}"
                    exit 1
                    ;;
            esac
        else
            echo -e "${RED}无法检测系统类型，请手动安装 jq${NC}"
            exit 1
        fi
        
        if [ $? -ne 0 ]; then
            echo -e "${RED}jq 安装失败，请手动安装 jq 后重试${NC}"
            exit 1
        fi
    fi
    
    if ! command -v jq &> /dev/null; then
        echo -e "${RED}jq 安装失败，请手动安装 jq 后重试${NC}"
        exit 1
    else
        echo -e "${GREEN}jq 已就绪，可以使用${NC}"
    fi
}

# 确保 uuidgen 已安装
ensure_uuidgen_installed() {
    if ! command -v uuidgen &> /dev/null; then
        echo -e "${YELLOW}uuidgen 未安装，正在尝试自动安装...${NC}"
        
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            case $ID in
                ubuntu|debian)
                    show_progress 5 "安装 uuidgen" "apt update -qq && apt install -y uuid-runtime"
                    ;;
                centos|rhel)
                    show_progress 5 "安装 uuidgen" "yum install -y libuuid"
                    ;;
                *)
                    echo -e "${RED}不支持的系统，请手动安装 uuidgen${NC}"
                    exit 1
                    ;;
            esac
        else
            echo -e "${RED}无法检测系统类型，请手动安装 uuidgen${NC}"
            exit 1
        fi
        
        if [ $? -ne 0 ]; then
            echo -e "${RED}uuidgen 安装失败，请手动安装后重试${NC}"
            exit 1
        fi
    fi
    
    if ! command -v uuidgen &> /dev/null; then
        echo -e "${RED}uuidgen 安装失败，请手动安装后重试${NC}"
        exit 1
    fi
}

# 生成随机端口 (10000-65535)
generate_random_port() {
    echo $((10000 + RANDOM % 55536))
}

# 生成随机 UUID
generate_random_uuid() {
    uuidgen
}

# 生成随机用户名/密码 (8-16位)
generate_random_user_pass() {
    cat /dev/urandom | tr -dc A-Za-z0-9 | head -c$((8 + RANDOM % 9))
    echo ""
}

# 获取公网 IPv4 地址
get_ipv4() {
    local ipv4=$(curl -4 -s --max-time 5 http://api.ipify.org)
    if [[ $? -ne 0 ]]; then
        echo -e "${RED}获取 IPv4 地址失败，请检查网络连接或手动配置 IPv4 地址。${NC}"
        return 1
    fi
    if ! [[ $ipv4 =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo -e "${RED}获取到的 IPv4 地址格式不正确: $ipv4${NC}"
        return 1
    fi
    echo "$ipv4"
}

# 获取公网 IPv6 地址
get_ipv6() {
    local ipv6=$(curl -6 -s --max-time 5 http://api6.ipify.org)
    if [[ $? -ne 0 ]]; then
        echo -e "${YELLOW}获取 IPv6 地址失败，但 IPv6 是可选的，继续...${NC}"
        return 1
    fi
    if ! [[ $ipv6 =~ ^[0-9a-f:]+$ ]]; then
        echo -e "${RED}获取到的 IPv6 地址格式不正确: $ipv6${NC}"
        return 1
    fi
    echo "$ipv6"
}

# 解析现有配置
parse_existing_config() {
    if [ -f "$CONFIG_PATH" ]; then
        if [ -s "$CONFIG_PATH" ]; then
            jq '.' "$CONFIG_PATH" 2>/dev/null || {
                echo -e "${YELLOW}配置文件格式不正确，使用空配置${NC}"
                echo '{}'
            }
        else
            echo -e "${YELLOW}配置文件为空，使用空配置${NC}"
            echo '{}'
        fi
    else
        echo -e "${YELLOW}配置文件不存在，使用空配置${NC}"
        echo '{}'
    fi
}

# 生成 VMess inbound 配置
generate_vmess_inbound() {
    local port=$1
    local uuid=$2
    cat <<EOF
{
  "port": ${port},
  "protocol": "vmess",
  "settings": {
    "clients": [
      {
        "id": "${uuid}",
        "alterId": 0
      }
    ]
  },
  "streamSettings": {
    "network": "ws",
    "wsSettings": {
      "path": "/m3u8"
    }
  },
  "sniffing": {
    "enabled": true,
    "destOverride": ["http", "tls"]
  }
}
EOF
}

# 生成 Socks5 inbound 配置
generate_socks5_inbound() {
    local port=$1
    local user=$2
    local pass=$3
    cat <<EOF
{
  "port": ${port},
  "protocol": "socks",
  "settings": {
    "auth": "password",
    "accounts": [
      {
        "user": "${user}",
        "pass": "${pass}"
      }
    ],
    "udp": true
  },
  "sniffing": {
    "enabled": true,
    "destOverride": ["http", "tls"]
  }
}
EOF
}

# 生成 Shadowsocks inbound 配置
generate_shadowsocks_inbound() {
    local port=$1
    local password=$2
    cat <<EOF
{
  "port": ${port},
  "protocol": "shadowsocks",
  "settings": {
    "method": "chacha20-ietf-poly1305",
    "network": "tcp,udp",
    "password": "${password}"
  },
  "sniffing": {
    "enabled": true,
    "destOverride": ["http", "tls"]
  }
}
EOF
}

# 生成 Dokodemo-door inbound 配置
generate_dokodemo_inbound() {
    local port=$1
    local remote_host=$2
    local remote_port=$3
    local remark=$4
    local index=$5
    cat <<EOF
{
  "port": ${port},
  "protocol": "dokodemo-door",
  "settings": {
    "address": "${remote_host}",
    "port": ${remote_port},
    "network": "tcp,udp",
    "followRedirect": false
  },
  "tag": "dokodemo-${remark}-${index}",
  "sniffing": {
    "enabled": false
  }
}
EOF
}

# 获取现有端口
get_existing_ports() {
    local config=$1
    echo "$config" | jq -r '(.inbounds // [])[] | .port // empty' 2>/dev/null || echo ""
}

# 生成不冲突的端口
generate_unique_port() {
    local existing_ports=$1
    local port
    while true; do
        port=$(generate_random_port)
        if ! echo "$existing_ports" | grep -q "^$port$"; then
            echo "$port"
            break
        fi
    done
}

# 验证端口合法性
validate_port() {
    local port=$1
    if [[ "$port" =~ ^[0-9]+$ && "$port" -ge 1 && "$port" -le 65535 ]]; then
        return 0
    else
        echo -e "${RED}错误：端口必须是 1-65535 之间的数字${NC}"
        return 1
    fi
}

# 验证地址格式（域名、IPv4、IPv6）
validate_address() {
    local addr=$1
    
    # IPv4 地址验证
    if [[ "$addr" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
        # 进一步验证每个字段是否在 0-255 范围内
        IFS='.' read -ra ADDR <<< "$addr"
        for i in "${ADDR[@]}"; do
            if [[ $i -lt 0 || $i -gt 255 ]]; then
                echo -e "${RED}错误：IPv4 地址格式不正确，每个字段必须在 0-255 范围内${NC}"
                return 1
            fi
        done
        return 0
    fi
    
    # IPv6 地址验证（简化版）
    if [[ "$addr" =~ ^([0-9a-fA-F]{0,4}:){2,7}[0-9a-fA-F]{0,4}$ ]] || [[ "$addr" =~ ^::1$ ]] || [[ "$addr" =~ ^::$ ]]; then
        return 0
    fi
    
    # 域名验证
    # 域名规则：
    # 1. 总长度不超过 253 个字符
    # 2. 每个标签不超过 63 个字符
    # 3. 标签只能包含字母、数字和连字符
    # 4. 标签不能以连字符开头或结尾
    # 5. 顶级域名至少 2 个字符，只能是字母
    if [[ ${#addr} -gt 253 ]]; then
        echo -e "${RED}错误：域名长度不能超过 253 个字符${NC}"
        return 1
    fi
    
    # 域名正则表达式
    local domain_regex="^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*\.[a-zA-Z]{2,}$"
    
    if [[ "$addr" =~ $domain_regex ]]; then
        # 检查是否有连续的点号
        if [[ "$addr" =~ \.\. ]]; then
            echo -e "${RED}错误：域名不能包含连续的点号${NC}"
            return 1
        fi
        
        # 检查是否以点号开头或结尾
        if [[ "$addr" =~ ^\. ]] || [[ "$addr" =~ \.$ ]]; then
            echo -e "${RED}错误：域名不能以点号开头或结尾${NC}"
            return 1
        fi
        
        return 0
    fi
    
    echo -e "${RED}错误：无效的地址格式。请输入有效的域名、IPv4 或 IPv6 地址${NC}"
    echo -e "${YELLOW}示例：${NC}"
    echo -e "${YELLOW}  域名: example.com, www.google.com${NC}"
    echo -e "${YELLOW}  IPv4: 192.168.1.1, 8.8.8.8${NC}"
    echo -e "${YELLOW}  IPv6: 2001:db8::1, ::1${NC}"
    return 1
}

# 安装 Xray（如果未安装）
install_xray() {
    if ! command -v xray &> /dev/null; then
        echo -e "${CYAN}安装 Xray...${NC}"
        show_progress 10 "下载并安装 Xray" 'bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install'
        
        if [[ $? -ne 0 ]]; then
            echo -e "${RED}Xray 安装失败，请检查错误信息并重试。${NC}"
            exit 1
        fi
        echo -e "${GREEN}✓ Xray 安装成功${NC}"
    fi
}

# 卸载 Xray
remove_xray() {
    echo -e "${RED}!! 警告 !! 你确定要卸载 Xray 吗？此操作不可逆!${NC}"
    read -p "请输入 (y/n): " confirm
    local lower_confirm=$(echo "$confirm" | tr '[:upper:]' '[:lower:]')
    if [[ "$lower_confirm" == "y" ]]; then
        echo -e "${CYAN}卸载 Xray...${NC}"
        show_progress 5 "卸载 Xray" 'bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ remove'
        
        rm -rf "$BACKUP_DIR"
        rm -rf "$LOG_DIR"
        rm -f "$VMESS_OUTPUT_FILE"
        rm -f "$SOCKS5_OUTPUT_FILE"
        rm -f "$SHADOWSOCKS_OUTPUT_FILE"
        rm -f "$PRIORITY_FILE"
        echo -e "${GREEN}✓ Xray 卸载完成${NC}"
    else
        echo -e "${YELLOW}已取消卸载。${NC}"
        return
    fi
}

# 设置出口优先级
set_priority() {
    echo -e "${CYAN}请选择出口优先级：${NC}"
    echo -e "${WHITE}1.${NC} IPv6 优先"
    echo -e "${WHITE}2.${NC} IPv4 优先"
    echo -e "${WHITE}3.${NC} 默认 (AsIs)"
    read -p "请输入选项 (1-3): " priority_choice
    case $priority_choice in
        1)
            priority="UseIPv6v4"
            priority_desc="IPv6 优先"
            ;;
        2)
            priority="UseIPv4v6"
            priority_desc="IPv4 优先"
            ;;
        3)
            priority="AsIs"
            priority_desc="默认 (AsIs)"
            ;;
        *)
            echo -e "${RED}无效选择，返回主菜单。${NC}"
            return
            ;;
    esac

    # 备份现有配置
    if [ -f "$CONFIG_PATH" ]; then
        timestamp=$(date +%Y%m%d%H%M%S)
        backup_file="${BACKUP_DIR}config_${timestamp}.json"
        echo -e "${GREEN}已备份现有配置到: $backup_file${NC}"
        cp "$CONFIG_PATH" "$backup_file"
    fi

    # 更新 outbound 配置
    existing_config=$(parse_existing_config)
    existing_inbounds=$(echo "$existing_config" | jq '.inbounds // []')
    existing_outbounds=$(echo "$existing_config" | jq '.outbounds // []')
    if [ "$(echo "$existing_outbounds" | jq 'length')" -eq 0 ]; then
        new_outbounds="[{\"protocol\": \"freedom\", \"settings\": {\"domainStrategy\": \"$priority\"}}]"
    else
        new_outbounds=$(echo "$existing_outbounds" | jq ".[0].settings.domainStrategy = \"$priority\"")
    fi

    # 写入新配置
    new_config=$(echo "$existing_config" | jq --argjson inbounds "$existing_inbounds" --argjson outbounds "$new_outbounds" '.inbounds = $inbounds | .outbounds = $outbounds')
    echo -e "${GREEN}写入新配置到: $CONFIG_PATH${NC}"
    echo "$new_config" | jq . | tee "$CONFIG_PATH" > /dev/null
    chmod 644 "$CONFIG_PATH"

    # 保存优先级描述
    echo "$priority_desc" > "$PRIORITY_FILE"

    # 重启 Xray 服务
    if systemctl is-active xray > /dev/null; then
        echo -e "${CYAN}重启 Xray 服务...${NC}"
        show_progress 2 "重启 Xray 服务" "systemctl restart xray"
        if [[ $? -ne 0 ]]; then
            echo -e "${RED}警告：Xray 服务重启失败，查看日志...${NC}"
            journalctl -u xray -n 50 --no-pager
        fi
    fi

    echo -e "${GREEN}已设置出口优先级为：$priority_desc${NC}"
}

# 管理 Dokodemo-door 配置
manage_dokodemo() {
    # 在操作 Dokodemo-door 前确保 Xray 已安装
    install_xray

    while true; do
        echo -e "\n${PURPLE}=== Dokodemo-door 管理 ===${NC}"
        echo -e "${WHITE}1.${NC} 添加配置"
        echo -e "${WHITE}2.${NC} 管理配置"
        echo -e "${WHITE}0.${NC} 返回主菜单"
        read -p "请输入选项 (0-2): " dokodemo_choice
        case $dokodemo_choice in
            1)  # 添加 Dokodemo-door 配置
                existing_config=$(parse_existing_config)
                existing_ports=$(get_existing_ports "$existing_config")

                echo -e "${CYAN}请输入本地监听端口（留空则随机生成）：${NC}"
                read -p "端口: " local_port
                if [ -z "$local_port" ]; then
                    local_port=$(generate_unique_port "$existing_ports")
                else
                    validate_port "$local_port" || continue
                    if echo "$existing_ports" | grep -q "^$local_port$"; then
                        echo -e "${RED}错误：端口 $local_port 已占用${NC}"
                        continue
                    fi
                fi

                read -p "请输入远程地址（例如 example.com 或 IP）：" remote_host
                validate_address "$remote_host" || continue

                read -p "请输入远程端口：" remote_port
                validate_port "$remote_port" || continue

                read -p "请输入备注（英文或数字，避免特殊字符）：" remark
                if [ -z "$remark" ]; then
                    remark="default"
                fi

                # 生成唯一索引
                existing_dokodemo=$(echo "$existing_config" | jq '(.inbounds // [])[] | select(.protocol == "dokodemo-door")')
                dokodemo_count=$(echo "$existing_dokodemo" | jq -s 'length')
                index=$((dokodemo_count + 1))

                dokodemo_inbound=$(generate_dokodemo_inbound "$local_port" "$remote_host" "$remote_port" "$remark" "$index")
                new_inbounds=$(echo "$existing_config" | jq '.inbounds // []' | jq --argjson new "$dokodemo_inbound" '. += [$new]')

                # 更新配置
                existing_outbounds=$(echo "$existing_config" | jq '.outbounds // []')
                if [ "$(echo "$existing_outbounds" | jq 'length')" -eq 0 ]; then
                    if [ -f "$PRIORITY_FILE" ]; then
                        priority=$(grep -o "IPv6 优先\|IPv4 优先\|默认 (AsIs)" "$PRIORITY_FILE" | grep -o "UseIPv6v4\|UseIPv4v6\|AsIs" || echo "AsIs")
                    else
                        priority="AsIs"
                    fi
                    default_outbounds="[{\"protocol\": \"freedom\", \"settings\": {\"domainStrategy\": \"$priority\"}}]"
                    new_config=$(echo "$existing_config" | jq --argjson inbounds "$new_inbounds" --argjson outbounds "$default_outbounds" '.inbounds = $inbounds | .outbounds = $outbounds')
                else
                    new_config=$(echo "$existing_config" | jq --argjson inbounds "$new_inbounds" --argjson outbounds "$existing_outbounds" '.inbounds = $inbounds | .outbounds = $outbounds')
                fi

                # 备份并写入配置
                if [ -f "$CONFIG_PATH" ]; then
                    timestamp=$(date +%Y%m%d%H%M%S)
                    backup_file="${BACKUP_DIR}config_${timestamp}.json"
                    echo -e "${GREEN}已备份现有配置到: $backup_file${NC}"
                    cp "$CONFIG_PATH" "$backup_file"
                fi
                echo -e "${GREEN}写入新配置到: $CONFIG_PATH${NC}"
                echo "$new_config" | jq . | tee "$CONFIG_PATH" > /dev/null
                chmod 644 "$CONFIG_PATH"

                # 重启 Xray 服务
                echo -e "${CYAN}重启 Xray 服务...${NC}"
                show_progress 2 "重启 Xray 服务" "systemctl restart xray"
                if [[ $? -ne 0 ]]; then
                    echo -e "${RED}警告：Xray 服务重启失败，查看日志...${NC}"
                    journalctl -u xray -n 50 --no-pager
                fi

                echo -e "${GREEN}已添加 Dokodemo-door 配置：端口 $local_port -> $remote_host:$remote_port，备注：$remark${NC}"
                ;;
            2)  # 管理配置（列出配置，选择删除或修改）
                existing_config=$(parse_existing_config)
                dokodemo_configs=$(echo "$existing_config" | jq '(.inbounds // [])[] | select(.protocol == "dokodemo-door")')
                if [ -z "$dokodemo_configs" ]; then
                    echo -e "${YELLOW}没有 Dokodemo-door 配置可管理${NC}"
                    continue
                fi

                echo -e "${CYAN}当前 Dokodemo-door 配置：${NC}"
                # 列出配置，IPv6 地址加 []
                echo "$dokodemo_configs" | jq -r '
                    if (.settings.address | test("^[0-9a-f:]+$")) then
                        "[\(.tag)] 端口: \(.port), 远程: [\(.settings.address)]:\(.settings.port)"
                    else
                        "[\(.tag)] 端口: \(.port), 远程: \(.settings.address):\(.settings.port)"
                    end' | nl -w2 -s". "

                read -p "请输入要管理的配置编号（0 取消）：" manage_index
                if [ "$manage_index" == "0" ]; then
                    continue
                fi

                if ! [[ "$manage_index" =~ ^[0-9]+$ ]] || [ "$manage_index" -lt 1 ] || [ "$manage_index" -gt "$(echo "$dokodemo_configs" | jq -s 'length')" ]; then
                    echo -e "${RED}无效编号${NC}"
                    continue
                fi

                # 获取选定配置
                manage_tag=$(echo "$dokodemo_configs" | jq -s ".[$((manage_index-1))].tag" | tr -d '"')
                current_port=$(echo "$dokodemo_configs" | jq -s ".[$((manage_index-1))].port")
                current_remote_host=$(echo "$dokodemo_configs" | jq -s ".[$((manage_index-1))].settings.address" | tr -d '"')
                current_remote_port=$(echo "$dokodemo_configs" | jq -s ".[$((manage_index-1))].settings.port")
                current_remark=$(echo "$manage_tag" | sed 's/^dokodemo-\(.*\)-[0-9]*$/\1/')
                current_index=$(echo "$manage_tag" | sed 's/^dokodemo-.*-\([0-9]*\)$/\1/')

                echo -e "${CYAN}已选择配置：端口 $current_port, 远程 $current_remote_host:$current_remote_port, 备注 $current_remark${NC}"
                echo -e "${WHITE}请选择操作：${NC}"
                echo -e "${WHITE}1.${NC} 删除配置"
                echo -e "${WHITE}2.${NC} 修改配置"
                echo -e "${WHITE}0.${NC} 取消"
                read -p "请输入选项 (0-2): " manage_action
                case $manage_action in
                    1)  # 删除配置
                        new_inbounds=$(echo "$existing_config" | jq ".inbounds | map(select(.tag != \"$manage_tag\"))")
                        existing_outbounds=$(echo "$existing_config" | jq '.outbounds // []')
                        new_config=$(echo "$existing_config" | jq --argjson inbounds "$new_inbounds" --argjson outbounds "$existing_outbounds" '.inbounds = $inbounds | .outbounds = $outbounds')

                        # 备份并写入配置
                        if [ -f "$CONFIG_PATH" ]; then
                            timestamp=$(date +%Y%m%d%H%M%S)
                            backup_file="${BACKUP_DIR}config_${timestamp}.json"
                            echo -e "${GREEN}已备份现有配置到: $backup_file${NC}"
                            cp "$CONFIG_PATH" "$backup_file"
                        fi
                        echo -e "${GREEN}写入新配置到: $CONFIG_PATH${NC}"
                        echo "$new_config" | jq . | tee "$CONFIG_PATH" > /dev/null
                        chmod 644 "$CONFIG_PATH"

                        # 重启 Xray 服务
                        echo -e "${CYAN}重启 Xray 服务...${NC}"
                        show_progress 2 "重启 Xray 服务" "systemctl restart xray"
                        if [[ $? -ne 0 ]]; then
                            echo -e "${RED}警告：Xray 服务重启失败，查看日志...${NC}"
                            journalctl -u xray -n 50 --no-pager
                        fi

                        echo -e "${GREEN}已删除 Dokodemo-door 配置：$manage_tag${NC}"
                        ;;
                    2)  # 修改配置
                        echo -e "${CYAN}请输入新值（留空保持不变）：${NC}"
                        read -p "本地端口 [$current_port]: " new_port
                        new_port=${new_port:-$current_port}
                        if [ "$new_port" != "$current_port" ]; then
                            validate_port "$new_port" || continue
                            existing_ports=$(get_existing_ports "$existing_config")
                            if echo "$existing_ports" | grep -q "^$new_port$" && [ "$new_port" != "$current_port" ]; then
                                echo -e "${RED}错误：端口 $new_port 已占用${NC}"
                                continue
                            fi
                        fi

                        read -p "远程地址 [$current_remote_host]: " new_remote_host
                        new_remote_host=${new_remote_host:-$current_remote_host}
                        validate_address "$new_remote_host" || continue

                        read -p "远程端口 [$current_remote_port]: " new_remote_port
                        new_remote_port=${new_remote_port:-$current_remote_port}
                        validate_port "$new_remote_port" || continue

                        read -p "备注 [$current_remark]: " new_remark
                        new_remark=${new_remark:-$current_remark}

                        # 更新配置
                        dokodemo_inbound=$(generate_dokodemo_inbound "$new_port" "$new_remote_host" "$new_remote_port" "$new_remark" "$current_index")
                        new_inbounds=$(echo "$existing_config" | jq ".inbounds | map(if .tag == \"$manage_tag\" then $dokodemo_inbound else . end)")
                        existing_outbounds=$(echo "$existing_config" | jq '.outbounds // []')
                        new_config=$(echo "$existing_config" | jq --argjson inbounds "$new_inbounds" --argjson outbounds "$existing_outbounds" '.inbounds = $inbounds | .outbounds = $outbounds')

                        # 备份并写入配置
                        if [ -f "$CONFIG_PATH" ]; then
                            timestamp=$(date +%Y%m%d%H%M%S)
                            backup_file="${BACKUP_DIR}config_${timestamp}.json"
                            echo -e "${GREEN}已备份现有配置到: $backup_file${NC}"
                            cp "$CONFIG_PATH" "$backup_file"
                        fi
                        echo -e "${GREEN}写入新配置到: $CONFIG_PATH${NC}"
                        echo "$new_config" | jq . | tee "$CONFIG_PATH" > /dev/null
                        chmod 644 "$CONFIG_PATH"

                        # 重启 Xray 服务
                        echo -e "${CYAN}重启 Xray 服务...${NC}"
                        show_progress 2 "重启 Xray 服务" "systemctl restart xray"
                        if [[ $? -ne 0 ]]; then
                            echo -e "${RED}警告：Xray 服务重启失败，查看日志...${NC}"
                            journalctl -u xray -n 50 --no-pager
                        fi

                        echo -e "${GREEN}已修改 Dokodemo-door 配置：端口 $new_port -> $new_remote_host:$new_remote_port，备注：$new_remark${NC}"
                        ;;
                    0)
                        echo -e "${YELLOW}已取消操作${NC}"
                        ;;
                    *)
                        echo -e "${RED}无效选择，请重试。${NC}"
                        ;;
                esac
                ;;
            0)
                break
                ;;
            *)
                echo -e "${RED}无效选择，请重试。${NC}"
                ;;
        esac
    done
}

# 显示状态信息
show_status() {
    echo -e "\n${PURPLE}=== Xray 服务状态 ===${NC}"
    echo -e "${CYAN}安装状态:${NC} $(check_xray_installed)"
    
    if command -v xray &> /dev/null; then
        echo -e "${CYAN}运行状态:${NC} $(check_xray_status)"
        echo -e "${CYAN}开机自启:${NC} $(check_xray_enabled)"

        # 版本: 仅显示 "Xray 25.8.3"
        xr_ver_line="$(xray version 2>/dev/null | head -n 1)"
        xr_ver_short="$(echo "$xr_ver_line" | grep -Eo 'Xray[[:space:]]+[0-9]+\.[0-9]+\.[0-9]+' || echo "$xr_ver_line")"
        echo -e "${CYAN}版本:${NC} ${GREEN}${xr_ver_short}${NC}"

        # 出口优先级
        if [ -f "$PRIORITY_FILE" ]; then
            priority_desc=$(cat "$PRIORITY_FILE")
            echo -e "${CYAN}出口优先级:${NC} ${GREEN}$priority_desc${NC}"
        else
            echo -e "${CYAN}出口优先级:${NC} ${GREEN}AsIs (默认)${NC}"
        fi
    else
        echo -e "${CYAN}运行状态:${NC} ${YELLOW}未安装${NC}"
        echo -e "${CYAN}开机自启:${NC} ${YELLOW}未安装${NC}"
    fi
}

# 显示菜单
show_menu() {
    clear
    echo -e "${PURPLE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║                        Xray 管理脚本                         ║${NC}"
    echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════╝${NC}"
    
    show_status
    
    echo -e "\n${CYAN}=== 主菜单 ===${NC}"
    
    # 动态菜单选项
    local menu_options=()
    local menu_count=1
    
    # 检查 Xray 是否已安装
    if command -v xray &> /dev/null; then
        # Xray 已安装，显示完整菜单
        
        # 协议管理
        menu_options+=("安装协议")
        echo -e "${WHITE}${menu_count}.${NC} 安装协议"
        ((menu_count++))
        
        menu_options+=("删除协议")
        echo -e "${WHITE}${menu_count}.${NC} 删除协议"
        ((menu_count++))
        
        menu_options+=("管理 Dokodemo-door 配置")
        echo -e "${WHITE}${menu_count}.${NC} 管理 Dokodemo-door 配置"
        ((menu_count++))
        
        # 服务管理 - 根据状态动态显示
        if systemctl is-active --quiet xray 2>/dev/null; then
            # Xray 正在运行
            menu_options+=("停止 Xray 服务")
            echo -e "${WHITE}${menu_count}.${NC} 停止 Xray 服务"
            ((menu_count++))
            
            menu_options+=("重启 Xray 服务")
            echo -e "${WHITE}${menu_count}.${NC} 重启 Xray 服务"
            ((menu_count++))
        else
            # Xray 未运行
            menu_options+=("启动 Xray 服务")
            echo -e "${WHITE}${menu_count}.${NC} 启动 Xray 服务"
            ((menu_count++))
        fi
        
        # 新增升级功能
        menu_options+=("升级 Xray")
        echo -e "${WHITE}${menu_count}.${NC} 升级 Xray"; ((menu_count++))

        # 开机自启管理 - 根据状态动态显示
        if systemctl is-enabled --quiet xray 2>/dev/null; then
            # 已启用开机自启
            menu_options+=("禁用开机自启")
            echo -e "${WHITE}${menu_count}.${NC} 禁用开机自启"
            ((menu_count++))
        else
            # 未启用开机自启
            menu_options+=("启用开机自启")
            echo -e "${WHITE}${menu_count}.${NC} 启用开机自启"
            ((menu_count++))
        fi
        
        # 其他选项
        menu_options+=("设置出口优先级")
        echo -e "${WHITE}${menu_count}.${NC} 设置出口优先级"
        ((menu_count++))
        
        menu_options+=("卸载 Xray")
        echo -e "${WHITE}${menu_count}.${NC} 卸载 Xray"
        ((menu_count++))
        
    else
        # Xray 未安装，只显示安装选项
        menu_options+=("安装协议")
        echo -e "${WHITE}${menu_count}.${NC} 安装协议 (将自动安装 Xray)"
        ((menu_count++))
        
        menu_options+=("管理 Dokodemo-door 配置")
        echo -e "${WHITE}${menu_count}.${NC} 管理 Dokodemo-door 配置 (将自动安装 Xray)"
        ((menu_count++))
    fi
    
    echo -e "${WHITE}0.${NC} 退出"
    
    # 返回菜单选项数组和计数
    MENU_OPTIONS=("${menu_options[@]}")
    MENU_MAX=$((menu_count-1))
}

# --- 主逻辑 ---
check_root
ensure_jq_installed
ensure_uuidgen_installed
cleanup_old_backups

while true; do
    show_menu
    read -p "请输入选项 (0-${MENU_MAX}): " choice
    
    # 验证输入
    if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 0 ] || [ "$choice" -gt "$MENU_MAX" ]; then
        echo -e "${RED}无效选择，请重试。${NC}"
        sleep 2
        continue
    fi
    
    case $choice in
        0)
            echo -e "${GREEN}感谢使用！${NC}"
            exit 0
            ;;
        *)
            # 根据选择执行对应功能
            selected_option="${MENU_OPTIONS[$((choice-1))]}"
            case "$selected_option" in
                "安装协议")
                    echo -e "${CYAN}请选择要安装的协议（可多选，用空格分隔）：${NC}"
                    echo -e "${WHITE}1.${NC} Socks5"
                    echo -e "${WHITE}2.${NC} VMess"
                    echo -e "${WHITE}3.${NC} Shadowsocks"
                    echo -e "${WHITE}4.${NC} 所有协议"
                    echo -e "${WHITE}0.${NC} 返回"
                    read -p "请输入选项 (例如: 1 3): " install_choices
                    install_socks5=false
                    install_vmess=false
                    install_shadowsocks=false
                    for choice in $install_choices; do
                        case $choice in
                            1) install_socks5=true ;;
                            2) install_vmess=true ;;
                            3) install_shadowsocks=true ;;
                            4) install_socks5=true
                               install_vmess=true
                               install_shadowsocks=true
                               ;;
                            0) continue 2 ;;  # 返回主菜单
                            *) echo -e "${RED}无效选择: $choice${NC}" ;;
                        esac
                    done
                    remove_socks5=false  # 重置删除标志
                    remove_vmess=false
                    remove_shadowsocks=false
                    ;;
                "删除协议")
                    echo -e "${CYAN}请选择要删除的协议（可多选，用空格分隔）：${NC}"
                    echo -e "${WHITE}1.${NC} Socks5"
                    echo -e "${WHITE}2.${NC} VMess"
                    echo -e "${WHITE}3.${NC} Shadowsocks"
                    echo -e "${WHITE}4.${NC} 所有协议"
                    echo -e "${WHITE}0.${NC} 返回"
                    read -p "请输入选项 (例如: 1 3): " remove_choices
                    remove_socks5=false
                    remove_vmess=false
                    remove_shadowsocks=false
                    for choice in $remove_choices; do
                        case $choice in
                            1) remove_socks5=true ;;
                            2) remove_vmess=true ;;
                            3) remove_shadowsocks=true ;;
                            4) remove_socks5=true
                               remove_vmess=true
                               remove_shadowsocks=true
                               ;;
                            0) continue 2 ;;  # 返回主菜单
                            *) echo -e "${RED}无效选择: $choice${NC}" ;;
                        esac
                    done
                    install_socks5=false  # 重置安装标志
                    install_vmess=false
                    install_shadowsocks=false
                    # 检查 Xray 是否安装
                    if ! command -v xray &> /dev/null; then
                        echo -e "${RED}错误：检测到 Xray 未安装，无法删除协议配置。请先安装 Xray。${NC}"
                        read -p "按任意键继续..."
                        continue
                    fi
                    ;;
                "管理 Dokodemo-door 配置")
                    manage_dokodemo
                    continue
                    ;;
                "启动 Xray 服务")
                    start_xray
                    read -p "按任意键继续..."
                    continue
                    ;;
                "停止 Xray 服务")
                    stop_xray
                    read -p "按任意键继续..."
                    continue
                    ;;
                "重启 Xray 服务")
                    restart_xray
                    read -p "按任意键继续..."
                    continue
                    ;;
                "启用开机自启")
                    enable_xray
                    read -p "按任意键继续..."
                    continue
                    ;;
                "禁用开机自启")
                    disable_xray
                    read -p "按任意键继续..."
                    continue
                    ;;
                "设置出口优先级")
                    install_xray  # 确保 Xray 已安装
                    set_priority
                    read -p "按任意键继续..."
                    continue
                    ;;
                "卸载 Xray")
                    if ! command -v xray &> /dev/null; then
                        echo -e "${RED}错误：检测到 Xray 未安装，无法执行卸载操作。${NC}"
                        read -p "按任意键继续..."
                        continue
                    fi
                    remove_xray
                    exit 0
                    ;;
                "升级 Xray")
                    upgrade_xray
                    read -p "按任意键继续..."
                    continue
                    ;;
                *)
                    echo -e "${RED}未知选项${NC}"
                    sleep 2
                    continue
                    ;;
            esac
            ;;
    esac

    # 如果选择了协议安装，确保 Xray 已安装
    if $install_socks5 || $install_vmess || $install_shadowsocks; then
        install_xray
    fi

    # 解析现有配置
    existing_config=$(parse_existing_config)
    existing_ports=$(get_existing_ports "$existing_config")
    existing_inbounds=$(echo "$existing_config" | jq '.inbounds // []')

    # 准备新的 inbounds 数组
    new_inbounds=()

    # 根据选择生成新的配置
    if $install_socks5; then
        socks5_port=$(generate_unique_port "$existing_ports")
        random_user=$(generate_random_user_pass)
        random_pass=$(generate_random_user_pass)
        socks5_inbound=$(generate_socks5_inbound "$socks5_port" "$random_user" "$random_pass")
        new_inbounds+=("$socks5_inbound")
    fi
    if $install_vmess; then
        vmess_port=$(generate_unique_port "$existing_ports")
        random_uuid=$(generate_random_uuid)
        vmess_inbound=$(generate_vmess_inbound "$vmess_port" "$random_uuid")
        new_inbounds+=("$vmess_inbound")
    fi
    if $install_shadowsocks; then
        shadowsocks_port=$(generate_unique_port "$existing_ports")
        random_password=$(generate_random_user_pass)
        shadowsocks_inbound=$(generate_shadowsocks_inbound "$shadowsocks_port" "$random_password")
        new_inbounds+=("$shadowsocks_inbound")
    fi

    # 过滤旧配置，移除将被替换或删除的协议类型
    filtered_inbounds=$(echo "$existing_inbounds" | jq -c '
        if '"$install_vmess"' or '"$remove_vmess"' then
            . | map(select(.protocol != "vmess"))
        else . end
        |
        if '"$install_socks5"' or '"$remove_socks5"' then
            . | map(select(.protocol != "socks"))
        else . end
        |
        if '"$install_shadowsocks"' or '"$remove_shadowsocks"' then
            . | map(select(.protocol != "shadowsocks"))
        else . end
    ')

    # 检查是否存在要删除的协议，并设置 skip_update 标志
    skip_update=false
    vmess_not_found=false
    socks5_not_found=false
    shadowsocks_not_found=false

    if $remove_vmess; then
        if ! echo "$existing_inbounds" | jq -e '.[] | select(.protocol == "vmess")' > /dev/null; then
            echo -e "${YELLOW}配置文件中未找到 VMess 配置${NC}"
            vmess_not_found=true
        fi
    fi
    if $remove_socks5; then
        if ! echo "$existing_inbounds" | jq -e '.[] | select(.protocol == "socks")' > /dev/null; then
            echo -e "${YELLOW}配置文件中未找到 Socks5 配置${NC}"
            socks5_not_found=true
        fi
    fi
    if $remove_shadowsocks; then
        if ! echo "$existing_inbounds" | jq -e '.[] | select(.protocol == "shadowsocks")' > /dev/null; then
            echo -e "${YELLOW}配置文件中未找到 Shadowsocks 配置${NC}"
            shadowsocks_not_found=true
        fi
    fi

    # 设置 skip_update 逻辑
    if $remove_vmess && $remove_socks5 && $remove_shadowsocks; then
        if [ "$(echo "$existing_inbounds" | jq 'length')" -eq 0 ]; then
            skip_update=true
            echo -e "${YELLOW}配置文件中没有任何协议配置，无需删除。${NC}"
        else
            skip_update=false
        fi
    elif $remove_vmess || $remove_socks5 || $remove_shadowsocks; then
        if ($remove_vmess && $vmess_not_found) && ($remove_socks5 && $socks5_not_found) && ($remove_shadowsocks && $shadowsocks_not_found); then
            skip_update=true
        elif ! $install_socks5 && ! $install_vmess && ! $install_shadowsocks; then
            skip_update=false
        fi
    fi

    # 将新生成的 inbounds 与过滤后的旧配置合并
    all_inbounds=$(echo "$filtered_inbounds" | jq --argjson new_inbounds "$(printf '%s\n' "${new_inbounds[@]}" | jq -s '.')" '. + $new_inbounds')

    # 检查是否有实际变更
    config_changed=false
    if [ "$(echo "$existing_inbounds" | jq -c .)" != "$(echo "$filtered_inbounds" | jq -c .)" ] || [ ${#new_inbounds[@]} -gt 0 ]; then
        config_changed=true
    fi

    # 检查并设置 outbounds
    existing_outbounds=$(echo "$existing_config" | jq '.outbounds // []')
    if [ "$(echo "$existing_outbounds" | jq 'length')" -eq 0 ]; then
        if [ -f "$PRIORITY_FILE" ]; then
            priority=$(grep -o "IPv6 优先\|IPv4 优先\|默认 (AsIs)" "$PRIORITY_FILE" | grep -o "UseIPv6v4\|UseIPv4v6\|AsIs" || echo "AsIs")
        else
            priority="AsIs"
        fi
        default_outbounds="[{\"protocol\": \"freedom\", \"settings\": {\"domainStrategy\": \"$priority\"}}]"
        new_config=$(echo "$existing_config" | jq --argjson inbounds "$all_inbounds" --argjson outbounds "$default_outbounds" '.inbounds = $inbounds | .outbounds = $outbounds')
    else
        new_config=$(echo "$existing_config" | jq --argjson inbounds "$all_inbounds" --argjson outbounds "$existing_outbounds" '.inbounds = $inbounds | .outbounds = $outbounds')
    fi

    # 如果没有任何操作，或者设置了跳过更新标志，直接跳过
    if (! $install_socks5 && ! $install_vmess && ! $install_shadowsocks && ! $remove_vmess && ! $remove_socks5 && ! $remove_shadowsocks) || $skip_update; then
        if $skip_update; then
            echo -e "${YELLOW}未进行任何更改。${NC}"
        fi
        read -p "按任意键继续..."
        continue
    fi

    # 根据 skip_update 和 config_changed 决定是否执行备份、写入和重启
    if [ "$skip_update" = false ] && [ "$config_changed" = true ]; then
        # 备份并写入新配置
        if [ -f "$CONFIG_PATH" ]; then
            timestamp=$(date +%Y%m%d%H%M%S)
            backup_file="${BACKUP_DIR}config_${timestamp}.json"
            echo -e "${GREEN}已备份现有配置到: $backup_file${NC}"
            cp "$CONFIG_PATH" "$backup_file"
        fi
        echo -e "${GREEN}写入新配置到: $CONFIG_PATH${NC}"
        echo "$new_config" | jq . | tee "$CONFIG_PATH" > /dev/null
        chmod 644 "$CONFIG_PATH"

        # 重启 Xray 服务
        echo -e "${CYAN}重启 Xray 服务...${NC}"
        show_progress 2 "重启 Xray 服务" "systemctl restart xray"
        if [[ $? -ne 0 ]]; then
            echo -e "${RED}警告：Xray 服务重启失败，查看日志...${NC}"
            journalctl -u xray -n 50 --no-pager
        fi

        # 删除对应的输出文件
        if $remove_vmess; then
            [ -f "$VMESS_OUTPUT_FILE" ] && rm -f "$VMESS_OUTPUT_FILE" && echo -e "${GREEN}已删除 $VMESS_OUTPUT_FILE${NC}"
        fi
        if $remove_socks5; then
            [ -f "$SOCKS5_OUTPUT_FILE" ] && rm -f "$SOCKS5_OUTPUT_FILE" && echo -e "${GREEN}已删除 $SOCKS5_OUTPUT_FILE${NC}"
        fi
        if $remove_shadowsocks; then
            [ -f "$SHADOWSOCKS_OUTPUT_FILE" ] && rm -f "$SHADOWSOCKS_OUTPUT_FILE" && echo -e "${GREEN}已删除 $SHADOWSOCKS_OUTPUT_FILE${NC}"
        fi
    fi

    # 如果是安装操作，生成连接信息
    ipv4_address=$(get_ipv4)
    ipv6_address=$(get_ipv6)

    if $install_vmess; then
        vmess_output=""
        if [[ $ipv4_address =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            vmess_json=$(cat <<EOF
{
  "v": "2",
  "ps": "my_server",
  "add": "${ipv4_address}",
  "port": "${vmess_port}",
  "id": "${random_uuid}",
  "aid": "0",
  "scy": "none",
  "net": "ws",
  "type": "none",
  "host": "",
  "path": "/m3u8",
  "tls": "",
  "sni": ""
}
EOF
            )
            vmess_base64=$(echo -n "$vmess_json" | base64 | tr -d '\n')
            vmess_output+="vmess://${vmess_base64}\n"
        fi
        if [[ $ipv6_address =~ ^[0-9a-f:]+$ ]]; then
            vmess_json_ipv6=$(cat <<EOF
{
  "v": "2",
  "ps": "my_server_ipv6",
  "add": "[${ipv6_address}]",
  "port": "${vmess_port}",
  "id": "${random_uuid}",
  "aid": "0",
  "scy": "none",
  "net": "ws",
  "type": "none",
  "host": "",
  "path": "/m3u8",
  "tls": "",
  "sni": ""
}
EOF
            )
            vmess_base64_ipv6=$(echo -n "$vmess_json_ipv6" | base64 | tr -d '\n')
            vmess_output+="vmess://${vmess_base64_ipv6}\n"
        fi
        echo -e "\n${CYAN}=== VMess 连接信息 ===${NC}"
        echo -e "${GREEN}$vmess_output${NC}"
        echo -e "$vmess_output" > "$VMESS_OUTPUT_FILE"
    fi

    if $install_socks5; then
        socks5_output=""
        if [[ $ipv4_address =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            socks5_output+="${ipv4_address}:${socks5_port}:${random_user}:${random_pass}\n"
        fi
        if [[ $ipv6_address =~ ^[0-9a-f:]+$ ]]; then
            socks5_output+="[${ipv6_address}]:${socks5_port}:${random_user}:${random_pass}\n"
        fi
        echo -e "\n${CYAN}=== Socks5 连接信息 ===${NC}"
        echo -e "${GREEN}$socks5_output${NC}"
        echo -e "$socks5_output" > "$SOCKS5_OUTPUT_FILE"
    fi

    if $install_shadowsocks; then
        shadowsocks_output=""
        ps_ipv4="my_server"
        ps_ipv6="my_server_ipv6"
        if [[ $ipv4_address =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            ss_base_str="chacha20-ietf-poly1305:${random_password}@${ipv4_address}:${shadowsocks_port}"
            ss_base64=$(echo -n "$ss_base_str" | base64 | tr -d '\n')
            shadowsocks_output+="ss://${ss_base64}#${ps_ipv4}\n"
        fi
        if [[ $ipv6_address =~ ^[0-9a-f:]+$ ]]; then
            ss_base_str="chacha20-ietf-poly1305:${random_password}@[${ipv6_address}]:${shadowsocks_port}"            ss_base64=$(echo -n "$ss_base_str" | base64 | tr -d '\n')
            shadowsocks_output+="ss://${ss_base64}#${ps_ipv6}\n"
        fi
        echo -e "\n${CYAN}=== Shadowsocks 连接信息 ===${NC}"
        echo -e "${GREEN}$shadowsocks_output${NC}"
        echo -e "$shadowsocks_output" > "$SHADOWSOCKS_OUTPUT_FILE"
    fi

    # 根据操作显示提示信息
    if $install_vmess || $install_socks5 || $install_shadowsocks; then
        echo -e "\n${GREEN}连接信息已保存到:${NC}"
        if $install_vmess; then
            echo -e "  ${YELLOW}$VMESS_OUTPUT_FILE${NC}"
        fi
        if $install_socks5; then
            echo -e "  ${YELLOW}$SOCKS5_OUTPUT_FILE${NC}"
        fi
        if $install_shadowsocks; then
            echo -e "  ${YELLOW}$SHADOWSOCKS_OUTPUT_FILE${NC}"
        fi
    elif $remove_vmess || $remove_socks5 || $remove_shadowsocks; then
        if [ "$vmess_not_found" = true ] && [ "$socks5_not_found" = true ] && [ "$shadowsocks_not_found" = true ]; then
            echo -e "${YELLOW}配置文件中未找到任何要删除的协议配置${NC}"
        elif [ "$config_changed" = true ]; then
            echo -e "${GREEN}已删除选定的协议配置${NC}"
        fi
    fi

    read -p "按任意键继续..."
done
