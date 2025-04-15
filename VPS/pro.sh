#!/bin/bash

# --- 配置参数 ---
CONFIG_PATH="/usr/local/etc/xray/config.json"
BACKUP_DIR="/usr/local/etc/xray/"
LOG_DIR="/var/log/xray/"
VMESS_OUTPUT_FILE="/root/vmess.txt"
SOCKS5_OUTPUT_FILE="/root/ss5.txt"
SHADOWSOCKS_OUTPUT_FILE="/root/shadowsocks.txt"
PRIORITY_FILE="/usr/local/etc/xray/priority.txt"

# --- 函数定义 ---

check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo "本脚本需要以 root 用户执行，请使用 sudo 或以 root 用户执行。"
        exit 1
    fi
}

# 清理超过 30 天的备份文件
cleanup_old_backups() {
    find "$BACKUP_DIR" -name 'config_*.json' -mtime +30 -delete 2>/dev/null
    echo "已清理 30 天前的备份文件"
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

# 确保 uuidgen 已安装
ensure_uuidgen_installed() {
    if ! command -v uuidgen &> /dev/null; then
        echo "uuidgen 未安装，正在尝试自动安装..."
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            case $ID in
                ubuntu|debian)
                    sudo apt update && sudo apt install -y uuid-runtime
                    ;;
                centos|rhel)
                    sudo yum install -y libuuid
                    ;;
                *)
                    echo "不支持的系统，请手动安装 uuidgen"
                    exit 1
                    ;;
            esac
        else
            echo "无法检测系统类型，请手动安装 uuidgen"
            exit 1
        fi
    fi
    if ! command -v uuidgen &> /dev/null; then
        echo "uuidgen 安装失败，请手动安装后重试"
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

# 验证端口合法性
validate_port() {
    local port=$1
    if [[ "$port" =~ ^[0-9]+$ && "$port" -ge 1 && "$port" -le 65535 ]]; then
        return 0
    else
        echo "错误：端口必须是 1-65535 之间的数字"
        return 1
    fi
}

# 验证地址格式（简单检查）
validate_address() {
    local addr=$1
    if [[ "$addr" =~ ^[a-zA-Z0-9.-]+$ || "$addr" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ || "$addr" =~ ^[0-9a-f:]+$ ]]; then
        return 0
    else
        echo "错误：无效的远程地址格式"
        return 1
    fi
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
        rm -f "$PRIORITY_FILE"
    else
        echo "已取消卸载。"
        return
    fi
}

# 设置出口优先级
set_priority() {
    echo "请选择出口优先级："
    echo "1. IPv6 优先"
    echo "2. IPv4 优先"
    echo "3. 默认 (AsIs)"
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
            echo "无效选择，返回主菜单。"
            return
            ;;
    esac

    # 备份现有配置
    if [ -f "$CONFIG_PATH" ]; then
        timestamp=$(date +%Y%m%d%H%M%S)
        backup_file="${BACKUP_DIR}config_${timestamp}.json"
        echo "已备份现有配置到: $backup_file"
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
    echo "写入新配置到: $CONFIG_PATH"
    echo "$new_config" | jq . | tee "$CONFIG_PATH" > /dev/null
    chmod 644 "$CONFIG_PATH"

    # 保存优先级描述
    echo "$priority_desc" > "$PRIORITY_FILE"

    # 重启 Xray 服务
    if systemctl is-active xray > /dev/null; then
        echo "重启 Xray 服务..."
        systemctl restart xray
        if [[ $? -ne 0 ]]; then
            echo "警告：Xray 服务重启失败，查看日志..."
            journalctl -u xray -n 50 --no-pager
        fi
    fi

    echo "已设置出口优先级为：$priority_desc"
}

# 管理 Dokodemo-door 配置
manage_dokodemo() {
    # 在操作 Dokodemo-door 前确保 Xray 已安装
    install_xray

    while true; do
        echo "Dokodemo-door 管理："
        echo "1. 添加配置"
        echo "2. 管理配置"
        echo "0. 返回主菜单"
        read -p "请输入选项 (0-2): " dokodemo_choice
        case $dokodemo_choice in
            1)  # 添加 Dokodemo-door 配置
                existing_config=$(parse_existing_config)
                existing_ports=$(get_existing_ports "$existing_config")

                echo "请输入本地监听端口（留空则随机生成）："
                read -p "端口: " local_port
                if [ -z "$local_port" ]; then
                    local_port=$(generate_unique_port "$existing_ports")
                else
                    validate_port "$local_port" || continue
                    if echo "$existing_ports" | grep -q "^$local_port$"; then
                        echo "错误：端口 $local_port 已占用"
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
                existing_dokodemo=$(echo "$existing_config" | jq '.inbounds[] | select(.protocol == "dokodemo-door")')
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
                    echo "已备份现有配置到: $backup_file"
                    cp "$CONFIG_PATH" "$backup_file"
                fi
                echo "写入新配置到: $CONFIG_PATH"
                echo "$new_config" | jq . | tee "$CONFIG_PATH" > /dev/null
                chmod 644 "$CONFIG_PATH"

                # 重启 Xray 服务
                echo "重启 Xray 服务..."
                systemctl restart xray
                if [[ $? -ne 0 ]]; then
                    echo "警告：Xray 服务重启失败，查看日志..."
                    journalctl -u xray -n 50 --no-pager
                fi

                echo "已添加 Dokodemo-door 配置：端口 $local_port -> $remote_host:$remote_port，备注：$remark"
                ;;
            2)  # 管理配置（列出配置，选择删除或修改）
                existing_config=$(parse_existing_config)
                dokodemo_configs=$(echo "$existing_config" | jq '.inbounds[] | select(.protocol == "dokodemo-door")')
                if [ -z "$dokodemo_configs" ]; then
                    echo "没有 Dokodemo-door 配置可管理"
                    continue
                fi

                echo "当前 Dokodemo-door 配置："
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
                    echo "无效编号"
                    continue
                fi

                # 获取选定配置
                manage_tag=$(echo "$dokodemo_configs" | jq -s ".[$((manage_index-1))].tag" | tr -d '"')
                current_port=$(echo "$dokodemo_configs" | jq -s ".[$((manage_index-1))].port")
                current_remote_host=$(echo "$dokodemo_configs" | jq -s ".[$((manage_index-1))].settings.address" | tr -d '"')
                current_remote_port=$(echo "$dokodemo_configs" | jq -s ".[$((manage_index-1))].settings.port")
                current_remark=$(echo "$manage_tag" | sed 's/^dokodemo-\(.*\)-[0-9]*$/\1/')
                current_index=$(echo "$manage_tag" | sed 's/^dokodemo-.*-\([0-9]*\)$/\1/')

                echo "已选择配置：端口 $current_port, 远程 $current_remote_host:$current_remote_port, 备注 $current_remark"
                echo "请选择操作："
                echo "1. 删除配置"
                echo "2. 修改配置"
                echo "0. 取消"
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
                            echo "已备份现有配置到: $backup_file"
                            cp "$CONFIG_PATH" "$backup_file"
                        fi
                        echo "写入新配置到: $CONFIG_PATH"
                        echo "$new_config" | jq . | tee "$CONFIG_PATH" > /dev/null
                        chmod 644 "$CONFIG_PATH"

                        # 重启 Xray 服务
                        echo "重启 Xray 服务..."
                        systemctl restart xray
                        if [[ $? -ne 0 ]]; then
                            echo "警告：Xray 服务重启失败，查看日志..."
                            journalctl -u xray -n 50 --no-pager
                        fi

                        echo "已删除 Dokodemo-door 配置：$manage_tag"
                        ;;
                    2)  # 修改配置
                        echo "请输入新值（留空保持不变）："
                        read -p "本地端口 [$current_port]: " new_port
                        new_port=${new_port:-$current_port}
                        if [ "$new_port" != "$current_port" ]; then
                            validate_port "$new_port" || continue
                            existing_ports=$(get_existing_ports "$existing_config")
                            if echo "$existing_ports" | grep -q "^$new_port$" && [ "$new_port" != "$current_port" ]; then
                                echo "错误：端口 $new_port 已占用"
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
                            echo "已备份现有配置到: $backup_file"
                            cp "$CONFIG_PATH" "$backup_file"
                        fi
                        echo "写入新配置到: $CONFIG_PATH"
                        echo "$new_config" | jq . | tee "$CONFIG_PATH" > /dev/null
                        chmod 644 "$CONFIG_PATH"

                        # 重启 Xray 服务
                        echo "重启 Xray 服务..."
                        systemctl restart xray
                        if [[ $? -ne 0 ]]; then
                            echo "警告：Xray 服务重启失败，查看日志..."
                            journalctl -u xray -n 50 --no-pager
                        fi

                        echo "已修改 Dokodemo-door 配置：端口 $new_port -> $new_remote_host:$new_remote_port，备注：$new_remark"
                        ;;
                    0)
                        echo "已取消操作"
                        ;;
                    *)
                        echo "无效选择，请重试。"
                        ;;
                esac
                ;;
            0)
                break
                ;;
            *)
                echo "无效选择，请重试。"
                ;;
        esac
    done
}

# 显示菜单
show_menu() {
    echo "请选择操作："
    echo "1. 安装协议"
    echo "2. 删除协议"
    echo "3. 管理 Dokodemo-door 配置"
    echo "4. 设置出口优先级"
    echo "5. 卸载 Xray"
    echo "0. 退出"
}

# --- 主逻辑 ---
check_root
ensure_jq_installed
ensure_uuidgen_installed
cleanup_old_backups

while true; do
    show_menu
    read -p "请输入选项 (0-6): " choice
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
        3)  # 管理 Dokodemo-door
            manage_dokodemo
            continue
            ;;
        4)  # 设置出口优先级
            install_xray  # 确保 Xray 已安装
            set_priority
            continue
            ;;
        5)  # 卸载 Xray
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
        if [ "$(echo "$existing_inbounds" | jq 'length')" -eq 0 ]; then
            skip_update=true
            echo "配置文件中没有任何协议配置，无需删除。"
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
        echo "重启 Xray 服务..."
        systemctl restart xray
        if [[ $? -ne 0 ]]; then
            echo "警告：Xray 服务重启失败，查看日志..."
            journalctl -u xray -n 50 --no-pager
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