#!/bin/bash

# --- 配置参数 ---
CONFIG_PATH="/usr/local/etc/xray/config.json"
BACKUP_DIR="/usr/local/etc/xray/"
LOG_DIR="/var/log/xray/"
VMESS_OUTPUT_FILE="/root/vmess.txt"
SOCKS5_OUTPUT_FILE="/root/ss5.txt"

# --- 函数定义 ---

# 确保 jq 已安装
ensure_jq_installed() {
    if ! command -v jq &> /dev/null; then
        echo "jq 未安装，正在尝试自动安装..."
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            case $ID in
                ubuntu|debian)
                    sudo apt update && sudo apt install -y jq
                    ;;
                centos|rhel)
                    sudo yum install -y jq
                    ;;
                *)
                    echo "不支持的系统，请手动安装 jq"
                    exit 1
                    ;;
            esac
        else
            echo "无法检测系统类型，请手动安装 jq"
            exit 1
        fi
    fi
    if ! command -v jq &> /dev/null; then
        echo "jq 安装失败，请手动安装 jq 后重试"
        exit 1
    else
        echo "jq 已就绪，可以使用"
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
        echo "获取 IPv4 地址失败，请检查网络连接或手动配置 IPv4 地址。"
        return 1 # 返回非零状态码表示失败
    fi
    if ! [[ $ipv4 =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "获取到的 IPv4 地址格式不正确: $ipv4"
        return 1
    fi
    echo "$ipv4"
}

# 获取公网 IPv6 地址
get_ipv6() {
    local ipv6=$(curl -6 -s --max-time 5 http://api6.ipify.org)
    if [[ $? -ne 0 ]]; then
        echo "获取 IPv6 地址失败，但 IPv6 是可选的，继续..." # IPv6 可选，不强制退出
        return 1 # 返回非零状态码，但不退出脚本
    fi
    if ! [[ $ipv6 =~ ^[0-9a-f:]+$ ]]; then
        echo "获取到的 IPv6 地址格式不正确: $ipv6"
        return 1
    fi
    echo "$ipv6"
}

# 解析现有配置
parse_existing_config() {
    if [ -f "$CONFIG_PATH" ]; then
        if [ -s "$CONFIG_PATH" ]; then
            jq '.' "$CONFIG_PATH" 2>/dev/null || {
                echo "配置文件格式不正确，使用空配置"
                echo '{}'
            }
        else
            echo "配置文件为空，使用空配置"
            echo '{}'
        fi
    else
        echo "配置文件不存在，使用空配置"
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
    "udp": true,
    "ip": "::"
  },
  "sniffing": {
    "enabled": true,
    "destOverride": ["http", "tls"]
  }
}
EOF
}

# 获取现有端口
get_existing_ports() {
    local config=$1
    echo "$config" | jq -r '.inbounds[].port // empty' 2>/dev/null || echo ""
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

# 安装 Xray（如果未安装）
install_xray() {
    if ! command -v xray &> /dev/null; then
        echo "安装 Xray..."
        bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install
        if [[ $? -ne 0 ]]; then
            echo "Xray 安装失败，请检查错误信息并重试。"
            exit 1
        fi
    fi
}

# 卸载 Xray
remove_xray() {
    read -p "!! 警告 !! 你确定要卸载 Xray 吗？此操作不可逆! (y/n): " confirm
    local lower_confirm=$(echo "$confirm" | tr '[:upper:]' '[:lower:]')  # 将用户输入转换为小写
    if [[ "$lower_confirm" == "y" ]]; then
        echo "卸载 Xray..."
        bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ remove
        rm -rf "$BACKUP_DIR"
        rm -rf "$LOG_DIR"
        rm -f "$VMESS_OUTPUT_FILE"
        rm -f "$SOCKS5_OUTPUT_FILE"
    else
        echo "已取消卸载。"
        return
    fi
}

# 显示菜单
show_menu() {
    echo "请选择操作："
    echo "1. 安装 Socks5"
    echo "2. 安装 VMess"
    echo "3. 安装 Socks5 和 VMess"
    echo "4. 删除 VMess 配置"
    echo "5. 删除 Socks5 配置"
    echo "6. 卸载 Xray"
    echo "7. 退出"
}

# --- 主逻辑 ---

ensure_jq_installed

while true; do
    show_menu
    read -p "请输入选项 (1-7): " choice
    case $choice in
        1)  # 安装 Socks5
            install_socks5=true
            install_vmess=false
            remove_vmess=false
            remove_socks5=false
            ;;
        2)  # 安装 VMess
            install_socks5=false
            install_vmess=true
            remove_vmess=false
            remove_socks5=false
            ;;
        3)  # 安装 Socks5 和 VMess
            install_socks5=true
            install_vmess=true
            remove_vmess=false
            remove_socks5=false
            ;;
        4)  # 删除 VMess 配置
            install_socks5=false
            install_vmess=false
            remove_vmess=true
            remove_socks5=false
            # **在执行删除操作前检测 Xray 是否已安装**
            if ! command -v xray &> /dev/null; then
                echo "错误：检测到 Xray 未安装，无法删除 VMess 配置。请先安装 Xray。"
                continue # 跳回菜单
            fi
            ;;
        5)  # 删除 Socks5 配置
            install_socks5=false
            install_vmess=false
            remove_vmess=false
            remove_socks5=true
            # **在执行删除操作前检测 Xray 是否已安装**
            if ! command -v xray &> /dev/null; then
                echo "错误：检测到 Xray 未安装，无法删除 Socks5 配置。请先安装 Xray。"
                continue # 跳回菜单
            fi
            ;;
        6)  # 卸载 Xray
            # **在执行卸载操作前检测 Xray 是否已安装**
            if ! command -v xray &> /dev/null; then
                echo "错误：检测到 Xray 未安装，无法执行卸载操作。"
                continue # 跳回菜单
            fi
            remove_xray
            exit 0
            ;;
        7)
            exit 0
            ;;
        *)
            echo "无效选择，请重试。"
            continue
            ;;
    esac

    # 如果选择了安装选项，确保 Xray 已安装
    if $install_socks5 || $install_vmess; then
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

    # 过滤旧配置，移除将被替换或删除的协议类型
    filtered_inbounds=$(echo "$existing_inbounds" | jq -c '
        # 如果安装或删除 VMess，则移除所有旧的 vmess 配置
        if '"$install_vmess"' or '"$remove_vmess"' then
            . | map(select(.protocol != "vmess"))
        else . end
        |
        # 如果安装或删除 Socks5，则移除所有旧的 socks 配置
        if '"$install_socks5"' or '"$remove_socks5"' then
            . | map(select(.protocol != "socks"))
        else . end
    ')

    # 将新生成的 inbounds 与过滤后的旧配置合并
    all_inbounds=$(echo "$filtered_inbounds" | jq --argjson new_inbounds "$(printf '%s\n' "${new_inbounds[@]}" | jq -s '.')" '. + $new_inbounds')

    # 检查并设置 outbounds
    existing_outbounds=$(echo "$existing_config" | jq '.outbounds // []')
    if [ "$(echo "$existing_outbounds" | jq 'length')" -eq 0 ]; then
        default_outbounds='[{"protocol": "freedom", "settings": {}}]'
        new_config=$(echo "$existing_config" | jq --argjson inbounds "$all_inbounds" --argjson outbounds "$default_outbounds" '.inbounds = $inbounds | .outbounds = $outbounds')
    else
        new_config=$(echo "$existing_config" | jq --argjson inbounds "$all_inbounds" --argjson outbounds "$existing_outbounds" '.inbounds = $inbounds | .outbounds = $outbounds')
    fi

    # 如果没有任何操作，直接跳过
    if ! $install_socks5 && ! $install_vmess && ! $remove_vmess && ! $remove_socks5; then
        continue
    fi

    # 备份并写入新配置
    if [ -f "$CONFIG_PATH" ]; then
        timestamp=$(date +%Y%m%d%H%M%S)
        backup_file="${BACKUP_DIR}config_${timestamp}.json"
        echo "已备份现有配置到: $backup_file"
        cp "$CONFIG_PATH" "$backup_file"
    fi
    echo "写入新配置到: $CONFIG_PATH"
    echo "$new_config" | jq . | tee "$CONFIG_PATH" > /dev/null
    chmod 644 "$CONFIG_PATH"

    # 重启 Xray 服务
    if systemctl is-active xray &>/dev/null; then
        echo "重启 Xray 服务..."
        systemctl restart xray
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
        echo -e "\n--- VMess 连接信息 ---"
        echo -e "$vmess_output"
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
        echo -e "\n--- Socks5 连接信息 ---"
        echo -e "$socks5_output"
        echo -e "$socks5_output" > "$SOCKS5_OUTPUT_FILE"
    fi

    # 根据操作显示提示信息
    if $install_vmess && $install_socks5; then
        echo "连接信息已保存到: $VMESS_OUTPUT_FILE 和 $SOCKS5_OUTPUT_FILE"
    elif $install_vmess; then
        echo "连接信息已保存到: $VMESS_OUTPUT_FILE"
    elif $install_socks5; then
        echo "连接信息已保存到: $SOCKS5_OUTPUT_FILE"
    elif $remove_vmess; then
        echo "已删除 VMess 配置"
    elif $remove_socks5; then
        echo "已删除 Socks5 配置"
    fi
    break
done
