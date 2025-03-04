#!/bin/bash

# --- 配置参数 ---
CONFIG_PATH="/usr/local/etc/xray/config.json"
BACKUP_DIR="/usr/local/etc/xray/"
LOG_DIR="/var/log/xray/"
VMESS_OUTPUT_FILE="/root/vmess.txt"
SOCKS5_OUTPUT_FILE="/root/ss5.txt"
SHADOWSOCKS_OUTPUT_FILE="/root/shadowsocks.txt"

# --- 函数定义 ---

check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo "本脚本需要以 root 用户执行，请使用 sudo 或以 root 用户执行。"
        exit 1
    fi
}

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
        return 1
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
        echo "获取 IPv6 地址失败，但 IPv6 是可选的，继续..."
        return 1
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
    local lower_confirm=$(echo "$confirm" | tr '[:upper:]' '[:lower:]')
    if [[ "$lower_confirm" == "y" ]]; then
        echo "卸载 Xray..."
        bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ remove
        rm -rf "$BACKUP_DIR"
        rm -rf "$LOG_DIR"
        rm -f "$VMESS_OUTPUT_FILE"
        rm -f "$SOCKS5_OUTPUT_FILE"
        rm -f "$SHADOWSOCKS_OUTPUT_FILE"
    else
        echo "已取消卸载。"
        return
    fi
}

# 显示菜单
show_menu() {
    echo "请选择操作："
    echo "1. 安装协议"
    echo "2. 删除协议"
    echo "3. 卸载 Xray"
    echo "0. 退出"
}

# --- 主逻辑 ---
check_root
ensure_jq_installed

while true; do
    show_menu
    read -p "请输入选项 (0-3): " choice  # 更新提示
    case $choice in
        1)  # 安装协议
            echo "请选择要安装的协议（可多选，用空格分隔）："
            echo "1. Socks5"
            echo "2. VMess"
            echo "3. Shadowsocks"
            echo "4. 所有协议"
            echo "0. 返回"
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
                    *) echo "无效选择: $choice" ;;
                esac
            done
            remove_socks5=false  # 重置删除标志
            remove_vmess=false
            remove_shadowsocks=false
            ;;
        2)  # 删除协议
            echo "请选择要删除的协议（可多选，用空格分隔）："
            echo "1. Socks5"
            echo "2. VMess"
            echo "3. Shadowsocks"
            echo "4. 所有协议"
            echo "0. 返回"
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
                    *) echo "无效选择: $choice" ;;
                esac
            done
            install_socks5=false  # 重置安装标志
            install_vmess=false
            install_shadowsocks=false
            # 检查 Xray 是否安装
            if ! command -v xray &> /dev/null; then
                echo "错误：检测到 Xray 未安装，无法删除协议配置。请先安装 Xray。"
                continue
            fi
            ;;
        3)  # 卸载 Xray
            if ! command -v xray &> /dev/null; then
                echo "错误：检测到 Xray 未安装，无法执行卸载操作。"
                continue
            fi
            remove_xray
            exit 0
            ;;
        0)
            exit 0
            ;;
        *)
            echo "无效选择，请重试。"
            continue
            ;;
    esac

    # 如果选择了安装选项，确保 Xray 已安装
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
            echo "配置文件中未找到 VMess 配置"
            vmess_not_found=true
        fi
    fi
    if $remove_socks5; then
        if ! echo "$existing_inbounds" | jq -e '.[] | select(.protocol == "socks")' > /dev/null; then
            echo "配置文件中未找到 Socks5 配置"
            socks5_not_found=true
        fi
    fi
    if $remove_shadowsocks; then
        if ! echo "$existing_inbounds" | jq -e '.[] | select(.protocol == "shadowsocks")' > /dev/null; then
            echo "配置文件中未找到 Shadowsocks 配置"
            shadowsocks_not_found=true
        fi
    fi

    # 设置 skip_update 逻辑
    if $remove_vmess && $remove_socks5 && $remove_shadowsocks; then
        # 删除所有协议：如果没有任何协议存在，则跳过更新
        if [ "$(echo "$existing_inbounds" | jq 'length')" -eq 0 ]; then
            skip_update=true
            echo "配置文件中没有任何协议配置，无需删除。"
        else
            skip_update=false
        fi
    elif $remove_vmess || $remove_socks5 || $remove_shadowsocks; then
        # 只删除部分协议：如果所选协议都不存在，则跳过更新
        if ($remove_vmess && $vmess_not_found) && ($remove_socks5 && $socks5_not_found) && ($remove_shadowsocks && $shadowsocks_not_found); then
            skip_update=true
        elif ! $install_socks5 && ! $install_vmess && ! $install_shadowsocks; then
            # 如果没有安装操作，且至少有一种协议存在，则不跳过更新
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
        default_outbounds='[{"protocol": "freedom", "settings": {}}]'
        new_config=$(echo "$existing_config" | jq --argjson inbounds "$all_inbounds" --argjson outbounds "$default_outbounds" '.inbounds = $inbounds | .outbounds = $outbounds')
    else
        new_config=$(echo "$existing_config" | jq --argjson inbounds "$all_inbounds" --argjson outbounds "$existing_outbounds" '.inbounds = $inbounds | .outbounds = $outbounds')
    fi

    # 如果没有任何操作，或者设置了跳过更新标志，直接跳过
    if (! $install_socks5 && ! $install_vmess && ! $install_shadowsocks && ! $remove_vmess && ! $remove_socks5 && ! $remove_shadowsocks) || $skip_update; then
        if $skip_update; then
            echo "未进行任何更改。"
        fi
        continue
    fi

    # 根据 skip_update 和 config_changed 决定是否执行备份、写入和重启
    if [ "$skip_update" = false ] && [ "$config_changed" = true ]; then
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
        if systemctl is-active xray > /dev/null; then
            echo "重启 Xray 服务..."
            systemctl restart xray
        fi

        # 删除对应的输出文件
        if $remove_vmess; then
            [ -f "$VMESS_OUTPUT_FILE" ] && rm -f "$VMESS_OUTPUT_FILE" && echo "已删除 $VMESS_OUTPUT_FILE"
        fi
        if $remove_socks5; then
            [ -f "$SOCKS5_OUTPUT_FILE" ] && rm -f "$SOCKS5_OUTPUT_FILE" && echo "已删除 $SOCKS5_OUTPUT_FILE"
        fi
        if $remove_shadowsocks; then
            [ -f "$SHADOWSOCKS_OUTPUT_FILE" ] && rm -f "$SHADOWSOCKS_OUTPUT_FILE" && echo "已删除 $SHADOWSOCKS_OUTPUT_FILE"
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
            ss_base_str="chacha20-ietf-poly1305:${random_password}@[${ipv6_address}]:${shadowsocks_port}"
            ss_base64=$(echo -n "$ss_base_str" | base64 | tr -d '\n')
            shadowsocks_output+="ss://${ss_base64}#${ps_ipv6}\n"
        fi
        echo -e "\n--- Shadowsocks 连接信息 ---"
        echo -e "$shadowsocks_output"
        echo -e "$shadowsocks_output" > "$SHADOWSOCKS_OUTPUT_FILE"
    fi

    # 根据操作显示提示信息
    if $install_vmess || $install_socks5 || $install_shadowsocks; then
        echo "连接信息已保存到:"
        if $install_vmess; then
            echo "  $VMESS_OUTPUT_FILE"
        fi
        if $install_socks5; then
            echo "  $SOCKS5_OUTPUT_FILE"
        fi
        if $install_shadowsocks; then
            echo "  $SHADOWSOCKS_OUTPUT_FILE"
        fi
    elif $remove_vmess || $remove_socks5 || $remove_shadowsocks; then
        if [ "$vmess_not_found" = true ] && [ "$socks5_not_found" = true ] && [ "$shadowsocks_not_found" = true ]; then
            echo "配置文件中未找到任何要删除的协议配置"
        elif [ "$config_changed" = true ]; then
            echo "已删除选定的协议配置"
        fi
    fi

    break # 退出循环
done
