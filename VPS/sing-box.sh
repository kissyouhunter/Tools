#!/bin/bash

# 配置路径
CONFIG_DIR="/etc/sing-box"
CONFIG_FILE="$CONFIG_DIR/config.json"
BACKUP_DIR="$CONFIG_DIR/backups"
SERVICE_NAME="sing-box"
LOG_LEVEL="info"
TIMESTAMP="true"
CONFIG_OUTPUT="/root/singbox_configs.txt"

# ANSI 颜色代码
GREEN="\033[0;32m"
RED="\033[0;31m"
NC="\033[0m" # 无颜色

# 服务器地址（将在脚本启动时动态获取）
SERVER_IPV4=""
SERVER_IPV6=""

# 检测包管理器
get_package_manager() {
    if command -v apt >/dev/null 2>&1; then
        echo "apt"
    elif command -v dnf >/dev/null 2>&1; then
        echo "dnf"
    elif command -v yum >/dev/null 2>&1; then
        echo "yum"
    else
        echo "none"
    fi
}

# 自动安装依赖
install_command() {
    local cmd=$1
    local pkg_manager=$(get_package_manager)
    echo "检测到缺少命令 '$cmd'，正在尝试安装..."
    
    case "$cmd" in
        jq)
            pkg="jq"
            ;;
        uuidgen)
            pkg="uuid-runtime"
            ;;
        curl)
            pkg="curl"
            ;;
        systemctl)
            pkg="systemd"
            ;;
        *)
            echo "未知命令 '$cmd'，请手动安装。"
            exit 1
            ;;
    esac

    case "$pkg_manager" in
        apt)
            apt update && apt install -y "$pkg"
            ;;
        dnf|yum)
            "$pkg_manager" install -y "$pkg"
            ;;
        none)
            echo "未检测到支持的包管理器，请手动安装 '$pkg'。"
            exit 1
            ;;
    esac

    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "安装 '$cmd' 失败，请手动安装。"
        exit 1
    fi
    echo "'$cmd' 已成功安装。"
}

# 检查必要命令
check_requirements() {
    for cmd in jq uuidgen curl systemctl; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            install_command "$cmd"
        fi
    done
}

# 动态获取服务器 IP
get_server_ips() {
    # 获取 IPv4
    SERVER_IPV4=$(curl -4 -s ip.sb 2>/dev/null)
    if [[ -z "$SERVER_IPV4" || ! "$SERVER_IPV4" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
        echo -e "${RED}无法获取合法的 IPv4 地址，请手动输入：${NC}"
        read -p "输入服务器 IPv4 地址: " SERVER_IPV4
        if [[ ! "$SERVER_IPV4" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
            echo -e "${RED}输入的 IPv4 地址格式非法，退出！${NC}"
            exit 1
        fi
    fi

    # 获取 IPv6
    SERVER_IPV6=$(curl -6 -s ip.sb 2>/dev/null)
    if [[ -z "$SERVER_IPV6" || ! "$SERVER_IPV6" =~ ^([0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4}$|^([0-9a-fA-F]{1,4}:){1,7}:$ ]]; then
        echo -e "${RED}无法获取合法的 IPv6 地址，请手动输入（留空表示无 IPv6）：${NC}"
        read -p "输入服务器 IPv6 地址: " SERVER_IPV6
        if [[ -n "$SERVER_IPV6" && ! "$SERVER_IPV6" =~ ^([0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4}$|^([0-9a-fA-F]{1,4}:){1,7}:$ ]]; then
            echo -e "${RED}输入的 IPv6 地址格式非法，退出！${NC}"
            exit 1
        fi
    fi
}

# 检查 sing-box 是否安装
is_installed() {
    command -v sing-box >/dev/null 2>&1
}

# 检查 sing-box 是否运行
is_running() {
    systemctl is-active --quiet "$SERVICE_NAME"
}

# 检查 sing-box 是否开机启动
is_enabled() {
    systemctl is-enabled --quiet "$SERVICE_NAME"
}

# 显示状态
display_status() {
    echo "=== Sing-box 状态 ==="
    if is_installed; then
        echo -e "已安装: ${GREEN}是${NC}"
        echo -e "运行中: $(is_running && echo "${GREEN}是${NC}" || echo "${RED}否${NC}")"
        echo -e "开机启动: $(is_enabled && echo "${GREEN}是${NC}" || echo "${RED}否${NC}")"
    else
        echo -e "已安装: ${RED}否${NC}"
    fi
    echo "======================"
}

# 生成随机端口
random_port() {
    shuf -i 10000-50000 -n 1
}

# 生成随机密码
random_password() {
    openssl rand -base64 16
}

# 生成 UUID
random_uuid() {
    uuidgen
}

# 备份配置文件
backup_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        mkdir -p "$BACKUP_DIR"
        timestamp=$(date +%Y%m%d_%H%M%S)
        cp "$CONFIG_FILE" "$BACKUP_DIR/config_$timestamp.json"
        # 保留最近 10 个备份
        ls -t "$BACKUP_DIR" | tail -n +11 | xargs -I {} rm "$BACKUP_DIR/{}"
    fi
}

# 初始化配置文件
init_config() {
    mkdir -p "$CONFIG_DIR"
    cat > "$CONFIG_FILE" << EOF
{
  "log": {
    "level": "$LOG_LEVEL",
    "timestamp": $TIMESTAMP
  },
  "inbounds": [],
  "outbounds": [
    {
      "type": "direct",
      "tag": "direct"
    }
  ]
}
EOF
}

# 检查和初始化配置文件
check_and_init_config() {
    echo "正在初始化标准配置文件..."
    backup_config
    init_config
    echo "配置文件已初始化为标准格式。"
}

# 检查并确保 outbounds 不为空
ensure_outbounds() {
    if [[ $(jq '.outbounds | length' "$CONFIG_FILE") -eq 0 ]]; then
        echo "outbounds 为空，添加默认 direct 出站..."
        jq '.outbounds = [
            {
                "type": "direct",
                "tag": "direct"
            }
        ]' "$CONFIG_FILE" > "${CONFIG_FILE}.tmp" && mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"
    fi
}

# 设置日志级别
set_log_level() {
    echo "=== 设置日志级别 ==="
    echo "1. info（默认）"
    echo "2. debug（详细）"
    read -p "请选择一个选项: " level_choice
    
    backup_config
    case "$level_choice" in
        1)
            jq '.log.level = "info"' "$CONFIG_FILE" > "${CONFIG_FILE}.tmp" && mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"
            echo "日志级别已设置为 info"
            ;;
        2)
            jq '.log.level = "debug"' "$CONFIG_FILE" > "${CONFIG_FILE}.tmp" && mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"
            echo "日志级别已设置为 debug"
            ;;
        *)
            echo "无效选项"
            read -p "按回车继续..."
            return 1
            ;;
    esac
    systemctl restart "$SERVICE_NAME"
    echo "服务已自动重启以应用配置。"
    echo "请使用 'journalctl -u sing-box -f' 查看详细日志。"
}

# 添加 Shadowsocks 入站
add_shadowsocks() {
    port=$(random_port)
    password=$(random_password)
    backup_config
    if [[ ! -f "$CONFIG_FILE" ]]; then
        init_config
    fi
    jq '.inbounds += [{
        "type": "shadowsocks",
        "listen": "::",
        "listen_port": '"$port"',
        "method": "chacha20-ietf-poly1305",
        "password": "'"$password"'",
        "tag": "ss-'"$port"'",
        "sniff": false,
        "tcp_fast_open": true
    }]' "$CONFIG_FILE" > "${CONFIG_FILE}.tmp" && mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"
    ensure_outbounds
    sing-box check -c "$CONFIG_FILE" || echo -e "${RED}配置文件验证失败，请检查日志！${NC}"
    systemctl restart "$SERVICE_NAME"
    
    # 生成 Shadowsocks 分享链接
    auth=$(echo -n "chacha20-ietf-poly1305:$password" | base64 -w 0)
    share_ipv4="ss://$auth@$SERVER_IPV4:$port#my_server"
    share_ipv6=""
    if [[ -n "$SERVER_IPV6" ]]; then
        share_ipv6="ss://$auth@[$SERVER_IPV6]:$port#my_server_ipv6"
    fi
    
    echo "Shadowsocks 已添加: 端口=$port, 密码=$password"
    echo "分享链接 (IPv4): $share_ipv4"
    if [[ -n "$share_ipv6" ]]; then
        echo "分享链接 (IPv6): $share_ipv6"
    fi
    echo "服务已自动重启以应用配置。"
    echo -e "${RED}调试提示：${NC}"
    echo "- 验证客户端配置（密码、IP、端口）。"
    echo "- 检查防火墙或云安全组是否允许入站流量。"
    echo "- 确保系统支持 TCP Fast Open（检查 'sysctl net.ipv4.tcp_fastopen'）。"
    echo "- 若连接失败，尝试启用嗅探（手动设置 'sniff: true'）。"
    echo "- 使用 'journalctl -u sing-box -f' 检查日志。"
    
    # 保存到文件并提示
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    {
        echo "[$timestamp] Shadowsocks 配置"
        echo "端口: $port"
        echo "IPv4: $share_ipv4"
        if [[ -n "$share_ipv6" ]]; then
            echo "IPv6: $share_ipv6"
        fi
        echo ""
    } >> "$CONFIG_OUTPUT"
    echo -e "配置已保存到 ${GREEN}$CONFIG_OUTPUT${NC}"
}

# 添加 VMess 入站
add_vmess() {
    port=$(random_port)
    uuid=$(random_uuid)
    backup_config
    if [[ ! -f "$CONFIG_FILE" ]]; then
        init_config
    fi
    jq '.inbounds += [{
        "type": "vmess",
        "listen": "::",
        "listen_port": '"$port"',
        "users": [{
            "uuid": "'"$uuid"'",
            "alterId": 0
        }],
        "transport": {
            "type": "ws",
            "path": "/m3u8"
        },
        "tag": "vmess-'"$port"'",
        "sniff": false,
        "tcp_fast_open": true
    }]' "$CONFIG_FILE" > "${CONFIG_FILE}.tmp" && mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"
    ensure_outbounds
    sing-box check -c "$CONFIG_FILE" || echo -e "${RED}配置文件验证失败，请检查日志！${NC}"
    systemctl restart "$SERVICE_NAME"
    
    # 生成 VMess 分享链接
    vmess_json=$(jq -n \
        --arg id "$uuid" \
        --arg port "$port" \
        --arg path "/m3u8" \
        --arg ipv4 "$SERVER_IPV4" \
        '{v: "2", ps: "my_server", add: $ipv4, port: $port, id: $id, aid: "0", net: "ws", type: "none", host: "", path: $path, tls: ""}' \
        | base64 -w 0)
    share_ipv4="vmess://$vmess_json"
    share_ipv6=""
    if [[ -n "$SERVER_IPV6" ]]; then
        vmess_json_ipv6=$(jq -n \
            --arg id "$uuid" \
            --arg port "$port" \
            --arg path "/m3u8" \
            --arg ipv6 "$SERVER_IPV6" \
            '{v: "2", ps: "my_server_ipv6", add: $ipv6, port: $port, id: $id, aid: "0", net: "ws", type: "none", host: "", path: $path, tls: ""}' \
            | base64 -w 0)
        share_ipv6="vmess://$vmess_json_ipv6"
    fi
    
    echo "VMess 已添加: 端口=$port, UUID=$uuid, 路径=/m3u8"
    echo "分享链接 (IPv4): $share_ipv4"
    if [[ -n "$share_ipv6" ]]; then
        echo "分享链接 (IPv6): $share_ipv6"
    fi
    echo "服务已自动重启以应用配置。"
    echo -e "${RED}调试提示：${NC}"
    echo "- 验证客户端配置（UUID、IP、端口、WebSocket 路径）。"
    echo "- 检查防火墙或云安全组是否允许入站流量。"
    echo "- 确保系统支持 TCP Fast Open（检查 'sysctl net.ipv4.tcp_fastopen'）。"
    echo "- 若连接失败，尝试启用嗅探（手动设置 'sniff: true'）。"
    echo "- 使用 'journalctl -u sing-box -f' 检查日志。"
    
    # 保存到文件并提示
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    {
        echo "[$timestamp] VMess 配置"
        echo "端口: $port"
        echo "路径: /m3u8"
        echo "IPv4: $share_ipv4"
        if [[ -n "$share_ipv6" ]]; then
            echo "IPv6: $share_ipv6"
        fi
        echo ""
    } >> "$CONFIG_OUTPUT"
    echo -e "配置已保存到 ${GREEN}$CONFIG_OUTPUT${NC}"
}

# 删除入站配置
delete_inbound() {
    echo "当前入站配置:"
    inbounds=$(jq -r '.inbounds | to_entries | map("\(.key + 1). \(.value.tag) (协议: \(.value.type), 端口: \(.value.listen_port))") | .[]' "$CONFIG_FILE")
    if [[ -z "$inbounds" ]]; then
        echo "没有可删除的入站配置。"
        read -p "按回车继续..."
        return 1
    fi
    echo "$inbounds"
    read -p "请输入要删除的序号: " choice
    if ! [[ "$choice" =~ ^[0-9]+$ ]] || [[ "$choice" -lt 1 ]] || [[ "$choice" -gt $(jq '.inbounds | length' "$CONFIG_FILE") ]]; then
        echo "无效的序号。"
        read -p "按回车继续..."
        return 1
    fi
    index=$((choice-1))
    tag=$(jq -r ".inbounds[$index].tag" "$CONFIG_FILE")
    protocol=$(jq -r ".inbounds[$index].type" "$CONFIG_FILE")
    port=$(jq -r ".inbounds[$index].listen_port" "$CONFIG_FILE")
    echo "即将删除配置:"
    echo "标签: $tag"
    echo "协议: $protocol"
    echo "端口: $port"
    read -p "确认删除？(y/n): " confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        echo "已取消删除。"
        read -p "按回车继续..."
        return 1
    fi
    backup_config
    jq "del(.inbounds[$index])" "$CONFIG_FILE" > "${CONFIG_FILE}.tmp" && mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"
    systemctl restart "$SERVICE_NAME"
    echo "入站配置 $tag 已删除"
    echo "服务已自动重启以应用配置。"
}

# 在启动时检查必要命令并获取服务器 IP
check_requirements
get_server_ips

# 主菜单
while true; do
    clear
    display_status
    echo "=== Sing-box 管理菜单 ==="
    
    # 动态菜单选项（退出固定为 0）
    options=()
    if ! is_installed; then
        options+=("安装 sing-box")
    else
        options+=("卸载 sing-box")
        if is_running; then
            options+=("停止 sing-box")
            options+=("重启 sing-box")
        else
            options+=("启动 sing-box")
        fi
        if is_enabled; then
            options+=("禁用开机启动")
        else
            options+=("启用开机启动")
        fi
        options+=("设置日志级别" "查看日志" "添加 Shadowsocks" "添加 VMess" "删除入站配置")
    fi

    # 显示动态编号菜单（从 1 开始）
    for i in "${!options[@]}"; do
        echo "$((i+1)). ${options[i]}"
    done
    echo "0. 退出"

    read -p "请选择一个选项: " choice

    # 处理退出选项
    if [[ "$choice" == "0" ]]; then
        exit 0
    fi

    # 将选择转换为数组索引
    index=$((choice-1))
    if [[ "$choice" -lt 1 ]] || [[ "$choice" -gt ${#options[@]} ]]; then
        echo "无效选项"
        read -p "按回车继续..."
        continue
    fi

    case "${options[index]}" in
        "安装 sing-box")
            curl -fsSL https://sing-box.app/install.sh | sh
            check_and_init_config
            systemctl enable "$SERVICE_NAME"
            systemctl start "$SERVICE_NAME"
            echo "Sing-box 已安装并启动"
            read -p "按回车继续..."
            ;;
        "卸载 sing-box")
            echo "即将卸载 sing-box，删除所有备份和配置记录文件。"
            read -p "确认卸载？(y/n): " confirm
            if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
                echo "已取消卸载。"
                read -p "按回车继续..."
                continue
            fi
            systemctl stop "$SERVICE_NAME"
            systemctl disable "$SERVICE_NAME"
            # 删除备份目录和 txt 文件
            rm -rf "$BACKUP_DIR"
            rm -f "$CONFIG_OUTPUT"
            pkg_manager=$(get_package_manager)
            case "$pkg_manager" in
                apt)
                    apt purge -y sing-box
                    apt autoremove -y
                    ;;
                dnf|yum)
                    "$pkg_manager" remove -y sing-box
                    ;;
                *)
                    rm -rf /usr/bin/sing-box /etc/sing-box /usr/lib/systemd/system/sing-box.service
                    ;;
            esac
            echo "Sing-box 已卸载，备份和配置记录文件已删除"
            read -p "按回车继续..."
            ;;
        "启动 sing-box")
            systemctl start "$SERVICE_NAME"
            echo "Sing-box 已启动"
            read -p "按回车继续..."
            ;;
        "停止 sing-box")
            systemctl stop "$SERVICE_NAME"
            echo "Sing-box 已停止"
            read -p "按回车继续..."
            ;;
        "重启 sing-box")
            systemctl restart "$SERVICE_NAME"
            echo "Sing-box 已重启"
            read -p "按回车继续..."
            ;;
        "启用开机启动")
            systemctl enable "$SERVICE_NAME"
            echo "开机启动已启用"
            read -p "按回车继续..."
            ;;
        "禁用开机启动")
            systemctl disable "$SERVICE_NAME"
            echo "开机启动已禁用"
            read -p "按回车继续..."
            ;;
        "设置日志级别")
            set_log_level
            read -p "按回车继续..."
            ;;
        "查看日志")
            journalctl -u "$SERVICE_NAME" -f
            ;;
        "添加 Shadowsocks")
            add_shadowsocks
            read -p "按回车继续..."
            ;;
        "添加 VMess")
            add_vmess
            read -p "按回车继续..."
            ;;
        "删除入站配置")
            delete_inbound
            read -p "按回车继续..."
            ;;
        *)
            echo "无效选项"
            read -p "按回车继续..."
            ;;
    esac
done
