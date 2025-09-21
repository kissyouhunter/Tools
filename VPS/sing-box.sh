#!/bin/bash

# 严格模式
set -euo pipefail

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 配置文件路径
CONFIG_FILE="/etc/sing-box/config.json"
SERVICE_NAME="sing-box"
BACKUP_DIR="/etc/sing-box/backup"
TEMP_DIR="/tmp/singbox_$$"

# 全局变量
SERVER_IPV4=""
SERVER_IPV6=""
CURRENT_PRIORITY=""  # 新增：存储当前优先级

# 全局错误处理函数
error_handler() {
    local line_no=$1
    local error_code=$2
    echo -e "${RED}错误: 脚本在第 $line_no 行失败，退出码: $error_code${NC}" >&2
    cleanup
    exit "$error_code"
}

trap 'error_handler ${LINENO} $?' ERR
trap 'cleanup' EXIT

# 清理函数
cleanup() {
    [[ -f "${CONFIG_FILE}.tmp" ]] && rm -f "${CONFIG_FILE}.tmp"
    [[ -d "$TEMP_DIR" ]] && rm -rf "$TEMP_DIR"
    [[ -f "/tmp/singbox_status_$$" ]] && rm -f "/tmp/singbox_status_$$"
}

# 创建临时目录
mkdir -p "$TEMP_DIR"

# 检测包管理器
detect_package_manager() {
    if command -v apt-get >/dev/null 2>&1; then
        echo "apt"
    elif command -v dnf >/dev/null 2>&1; then
        echo "dnf"
    elif command -v yum >/dev/null 2>&1; then
        echo "yum"
    elif command -v pacman >/dev/null 2>&1; then
        echo "pacman"
    else
        echo "unknown"
    fi
}

# 进度指示器
show_progress() {
    local pid=$1
    local message=$2
    local spinner='|/-\'
    local i=0
    
    while kill -0 "$pid" 2>/dev/null; do
        printf "\r%s %c" "$message" "${spinner:i++%${#spinner}:1}"
        sleep 0.1
    done
    printf "\r%s 完成\n" "$message"
}

# 刷新服务状态缓存
refresh_service_status() {
    rm -f "/tmp/singbox_status_$$"
    sleep 1  # 等待服务状态稳定
}

# 获取服务状态（带缓存）
get_service_status() {
    local status_cache="/tmp/singbox_status_$$"
    if [[ ! -f "$status_cache" ]] || [[ $(($(date +%s) - $(stat -c %Y "$status_cache" 2>/dev/null || echo 0))) -gt 2 ]]; then
        {
            systemctl is-active --quiet "$SERVICE_NAME" && echo "running" || echo "stopped"
            systemctl is-enabled --quiet "$SERVICE_NAME" && echo "enabled" || echo "disabled"
        } > "$status_cache"
    fi
    cat "$status_cache"
}

# 检查服务是否运行
is_running() {
    local status
    status=$(get_service_status)
    [[ "$(echo "$status" | head -n1)" == "running" ]]
}

# 检查服务是否启用
is_enabled() {
    local status
    status=$(get_service_status)
    [[ "$(echo "$status" | tail -n1)" == "enabled" ]]
}

# 确认提示函数
confirm_action() {
    local message=$1
    read -p "$message (y/n): " -n 1 -r
    echo
    [[ $REPLY =~ ^[Yy]$ ]]
}

# 安全的配置更新
safe_config_update() {
    local filter=$1
    local temp_file
    temp_file=$(mktemp "${CONFIG_FILE}.XXXXXX")
    
    if jq "$filter" "$CONFIG_FILE" > "$temp_file"; then
        if command -v sing-box >/dev/null 2>&1 && sing-box check -c "$temp_file" >/dev/null 2>&1; then
            mv "$temp_file" "$CONFIG_FILE"
            return 0
        else
            echo -e "${YELLOW}警告: 无法验证配置，但仍将应用更改${NC}" >&2
            mv "$temp_file" "$CONFIG_FILE"
            return 0
        fi
    else
        echo -e "${RED}配置更新失败${NC}" >&2
        rm -f "$temp_file"
        return 1
    fi
}

# 统一的服务重启逻辑
restart_service_with_feedback() {
    echo "正在重启服务..."
    if systemctl restart "$SERVICE_NAME"; then
        echo -e "${GREEN}服务重启成功${NC}"
        refresh_service_status
        return 0
    else
        echo -e "${RED}服务重启失败，请检查日志${NC}"
        systemctl status "$SERVICE_NAME" --no-pager -l
        return 1
    fi
}

# 等待用户返回主菜单
wait_for_return() {
    echo ""
    echo "按回车键返回主菜单..."
    read
}

# 端口验证和读取
read_port() {
    local port
    while true; do
        read -p "请输入端口号 (10000-50000): " port
        if [[ "$port" =~ ^[0-9]+$ ]] && [[ "$port" -ge 10000 ]] && [[ "$port" -le 50000 ]]; then
            # 检查端口是否已被占用
            if ! ss -tuln | grep -q ":$port "; then
                echo "$port"
                return 0
            else
                echo -e "${RED}端口 $port 已被占用，请选择其他端口${NC}"
            fi
        else
            echo -e "${RED}无效端口号，请输入 10000-50000 之间的数字${NC}"
        fi
    done
}

# 生成随机端口
random_port() {
    local port
    local max_attempts=50
    local attempts=0
    
    while [[ $attempts -lt $max_attempts ]]; do
        port=$((RANDOM % 40001 + 10000))
        if ! ss -tuln | grep -q ":$port "; then
            echo "$port"
            return 0
        fi
        ((attempts++))
    done
    
    echo -e "${RED}无法找到可用端口，请手动指定${NC}" >&2
    read_port
}

# 生成随机密码
random_password() {
    openssl rand -base64 32 | tr -d "=+/" | cut -c1-25
}

# 生成UUID
generate_uuid() {
    if command -v uuidgen >/dev/null 2>&1; then
        uuidgen
    else
        cat /proc/sys/kernel/random/uuid
    fi
}

generate_tls_cert() {
    local cert_dir="/etc/sing-box"
    local cert_path="$cert_dir/server.crt"
    local key_path="$cert_dir/server.key"
    local openssl_cfg
    openssl_cfg=$(mktemp)

    cat > "$openssl_cfg" << 'EOF'
[ req ]
distinguished_name = req_distinguished_name
x509_extensions    = v3_req
prompt             = no

[ req_distinguished_name ]
CN = bing.com

[ v3_req ]
subjectAltName = @alt_names

[ alt_names ]
DNS.1 = bing.com
DNS.2 = www.bing.com
EOF

    mkdir -p "$cert_dir"

    echo "生成自签名证书..."
    openssl req -x509 -newkey ec:<(openssl ecparam -name prime256v1) \
        -keyout "$key_path" \
        -out "$cert_path" \
        -days 36500 \
        -nodes \
        -extensions v3_req \
        -config "$openssl_cfg" >/dev/null 2>&1

    chmod 600 "$key_path"
    chmod 644 "$cert_path"
    rm -f "$openssl_cfg"
    echo -e "${GREEN}证书生成完成: $cert_path, $key_path${NC}"
}

# 自动获取服务器IP，并在获取后自动设置优先级
get_server_ips() {
    echo "正在自动获取服务器IP地址..."
    
    # 清空之前的IP
    SERVER_IPV4=""
    SERVER_IPV6=""
    
    # 获取IPv4地址
    echo -n "获取IPv4地址... "
    SERVER_IPV4=$(curl -4 -s --connect-timeout 10 --max-time 15 ip.sb 2>/dev/null || echo "")
    if [[ -n "$SERVER_IPV4" && "$SERVER_IPV4" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        echo -e "${GREEN}✓ $SERVER_IPV4${NC}"
    else
        echo -e "${YELLOW}失败${NC}"
        SERVER_IPV4=""
    fi
    
    # 获取IPv6地址
    echo -n "获取IPv6地址... "
    SERVER_IPV6=$(curl -6 -s --connect-timeout 10 --max-time 15 ip.sb 2>/dev/null || echo "")
    if [[ -n "$SERVER_IPV6" && "$SERVER_IPV6" =~ ^[0-9a-fA-F:]+$ ]]; then
        echo -e "${GREEN}✓ $SERVER_IPV6${NC}"
    else
        echo -e "${YELLOW}失败${NC}"
        SERVER_IPV6=""
    fi
    
    # 总结结果
    if [[ -n "$SERVER_IPV4" || -n "$SERVER_IPV6" ]]; then
        echo -e "${GREEN}✓ IP地址获取完成${NC}"
    else
        echo -e "${YELLOW}⚠ 未能获取到服务器IP地址${NC}"
        echo -e "${YELLOW}  这不会影响服务运行，但会影响分享链接生成${NC}"
    fi

    # 自动设置优先级
    auto_set_priority
}

# 获取当前优先级
get_current_priority() {
    if [[ -f "$CONFIG_FILE" ]]; then
        local strategy=$(jq -r '.outbounds[0].domain_resolver.strategy // "system"' "$CONFIG_FILE" 2>/dev/null)
        case "$strategy" in
            "prefer_ipv6"|"ipv6_only") echo "ipv6" ;;
            "prefer_ipv4"|"ipv4_only") echo "ipv4" ;;
            *) echo "system" ;;
        esac
    else
        echo "system"
    fi
}

# 设置 outbounds 优先级
set_priority() {
    local pref=$1  # "ipv4" or "ipv6"

    # 确保 DNS 配置存在
    safe_config_update 'if .dns == null then .dns = {"servers": [{"tag": "local", "type": "local"}]} else . end'

    # 设置 outbounds.domain_resolver
    local strategy
    if [[ "$pref" == "ipv6" ]]; then
        strategy="prefer_ipv6"
    else
        strategy="prefer_ipv4"
    fi

    safe_config_update '.outbounds[0].domain_resolver = {"server": "local", "strategy": "'"$strategy"'"}'

    # 更新全局变量
    CURRENT_PRIORITY=$(get_current_priority)

    # 重启服务
    restart_service_with_feedback
}

# 自动设置优先级（基于 IP 可用性）
auto_set_priority() {
    if [[ -n "$SERVER_IPV4" && -n "$SERVER_IPV6" ]]; then
        set_priority "ipv6"
        echo -e "${GREEN}已自动设置 outbounds 为 IPv6 优先${NC}"
    elif [[ -n "$SERVER_IPV4" ]]; then
        set_priority "ipv4"
        echo -e "${GREEN}已自动设置 outbounds 为 IPv4 优先${NC}"
    elif [[ -n "$SERVER_IPV6" ]]; then
        set_priority "ipv6"
        echo -e "${GREEN}已自动设置 outbounds 为 IPv6 优先${NC}"
    else
        echo -e "${YELLOW}无可用 IP，未设置 outbounds 优先级${NC}"
    fi
}

# 备份配置
backup_config() {
    [[ ! -f "$CONFIG_FILE" ]] && return 0
    
    mkdir -p "$BACKUP_DIR"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_file="$BACKUP_DIR/config_$timestamp.json"
    
    if cp "$CONFIG_FILE" "$backup_file"; then
        echo -e "${GREEN}配置已备份到: $backup_file${NC}"
        
        # 异步清理旧备份（保留最新10个）
        (
            find "$BACKUP_DIR" -name "config_*.json" -type f -printf '%T@ %p\n' 2>/dev/null | \
            sort -rn | \
            tail -n +11 | \
            cut -d' ' -f2- | \
            xargs -r rm -f
        ) &
    fi
}

# 强制初始化配置目录和文件（添加基本 DNS 配置）
force_initialize_config() {
    echo -e "${BLUE}强制初始化sing-box配置${NC}"
    
    # 停止服务（如果运行）
    systemctl stop sing-box 2>/dev/null || true
    
    # 完全清理现有配置
    if [[ -d "/etc/sing-box" ]]; then
        echo "清理现有配置目录..."
        rm -rf /etc/sing-box/*
    fi
    
    # 创建配置目录
    mkdir -p "$(dirname "$CONFIG_FILE")"
    mkdir -p "$BACKUP_DIR"
    
    # 创建基础配置文件（添加 DNS）
    cat > "$CONFIG_FILE" << 'EOF'
{
    "log": {
        "level": "info",
        "timestamp": true
    },
    "dns": {
        "servers": [
            {
                "tag": "local",
                "type": "local"
            }
        ]
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
    
    # 设置正确的权限
    chmod 644 "$CONFIG_FILE"
    chown root:root "$CONFIG_FILE"
    
    echo -e "${GREEN}✓ 强制初始化完成${NC}"
    echo -e "${GREEN}✓ 创建基础配置文件: $CONFIG_FILE${NC}"
    echo -e "${GREEN}✓ 创建备份目录: $BACKUP_DIR${NC}"
}

# 生成配置模板
generate_socks5_config() {
    local port=$1
    local username=$2
    local password=$3
    cat << EOF
{
    "type": "socks",
    "listen": "::",
    "listen_port": $port,
    "tag": "socks5-$port",
    "users": [
        {
            "username": "$username",
            "password": "$password"
        }
    ]
}
EOF
}

generate_shadowsocks_config() {
    local port=$1
    local password=$2
    
    cat << EOF
{
    "type": "shadowsocks",
    "listen": "::",
    "listen_port": $port,
    "method": "chacha20-ietf-poly1305",
    "password": "$password",
    "tag": "ss-$port",
    "tcp_fast_open": true
}
EOF
}

generate_vmess_config() {
    local port=$1
    local uuid=$2
    
    cat << EOF
{
    "type": "vmess",
    "listen": "::",
    "listen_port": $port,
    "users": [
        {
            "uuid": "$uuid",
            "alterId": 0
        }
    ],
    "tag": "vmess-$port"
}
EOF
}

generate_anytls_config() {
    local port=$1
    local username=$2
    local password=$3
    cat << EOF
{
  "type": "anytls",
  "listen": "::",
  "listen_port": $port,
  "tag": "anytls-$port",
  "users": [
    {
      "name": "$username",
      "password": "$password"
    }
  ],
  "padding_scheme": [
    "stop=7",
    "0=20-50",
    "1=100-200",
    "2=400-800,c,800-1200",
    "3=50-100,300-600",
    "4=500-800",
    "5=50-200",
    "6=10-10"
  ],
  "tls": {
    "enabled": true,
    "server_name": "bing.com",
    "certificate_path": "/etc/sing-box/server.crt",
    "key_path": "/etc/sing-box/server.key",
    "alpn": ["h2","http/1.1"]
  }
}
EOF
}

# 生成分享链接
generate_share_links() {
    local protocol=$1
    local port=$2
    local auth=$3
    local share_links=""
    
    case "$protocol" in
        "shadowsocks")
            if [[ -n "$SERVER_IPV4" ]]; then
                local ss_link=$(echo -n "chacha20-ietf-poly1305:$auth" | base64 -w 0)
                share_links+="ss://$ss_link@$SERVER_IPV4:$port#SS-IPv4-$port"$'\n'
            fi
            if [[ -n "$SERVER_IPV6" ]]; then
                local ss_link=$(echo -n "chacha20-ietf-poly1305:$auth" | base64 -w 0)
                share_links+="ss://$ss_link@[$SERVER_IPV6]:$port#SS-IPv6-$port"$'\n'
            fi
            ;;
        "vmess")
            if [[ -n "$SERVER_IPV4" ]]; then
                local vmess_json="{\"v\":\"2\",\"ps\":\"VMess-IPv4-$port\",\"add\":\"$SERVER_IPV4\",\"port\":\"$port\",\"id\":\"$auth\",\"aid\":\"0\",\"net\":\"tcp\",\"type\":\"none\",\"host\":\"\",\"path\":\"\",\"tls\":\"\"}"
                share_links+="vmess://$(echo -n "$vmess_json" | base64 -w 0)"$'\n'
            fi
            if [[ -n "$SERVER_IPV6" ]]; then
                local vmess_json="{\"v\":\"2\",\"ps\":\"VMess-IPv6-$port\",\"add\":\"$SERVER_IPV6\",\"port\":\"$port\",\"id\":\"$auth\",\"aid\":\"0\",\"net\":\"tcp\",\"type\":\"none\",\"host\":\"\",\"path\":\"\",\"tls\":\"\"}"
                share_links+="vmess://$(echo -n "$vmess_json" | base64 -w 0)"$'\n'
            fi
            ;;
    esac
    
    if [[ -n "$share_links" ]]; then
        echo -e "${GREEN}分享链接:${NC}"
        echo "$share_links"
    else
        echo -e "${YELLOW}无法生成分享链接（未获取到服务器IP地址）${NC}"
    fi
}

# 保存配置到文件（修改为/root目录）
save_config_to_file() {
    local protocol=$1
    local port=$2
    local share_links=$3
    
    local config_file="/root/${protocol}_${port}.txt"
    cat > "$config_file" << EOF
协议: $protocol
端口: $port
创建时间: $(date)
服务器IPv4: ${SERVER_IPV4:-"未获取"}
服务器IPv6: ${SERVER_IPV6:-"未获取"}

分享链接:
$share_links
EOF
    echo -e "${GREEN}配置已保存到: $config_file${NC}"
}

# 添加Socks5配置
add_socks5() {
    echo -e "${BLUE}添加 SOCKS5 配置${NC}"

    local port=$(random_port)
    # 生成随机 username（长小写字符串，基于您的偏好）
    local username=$(tr -dc 'a-z' < /dev/urandom | head -c 12)  # 12位小写字母
    local password=$(random_password)  # 使用脚本中的 random_password 函数

    local config
    config=$(generate_socks5_config "$port" "$username" "$password")

    if safe_config_update ".inbounds += [$config]"; then
        echo -e "${GREEN}SOCKS5 配置添加成功${NC}"
        echo "端口: $port"
        echo "用户名: $username"
        echo "密码: $password"

        restart_service_with_feedback

        # 生成新的分享链接格式
        local share_links=""
        if [[ -n "$SERVER_IPV4" ]]; then
            local link4="${SERVER_IPV4}:${port}:${username}:${password}"
            echo -e "${GREEN}分享链接 IPv4: ${link4}${NC}"
            share_links+="$link4"$'\n'
        fi
        if [[ -n "$SERVER_IPV6" ]]; then
            local link6="[${SERVER_IPV6}]:${port}:${username}:${password}"
            echo -e "${GREEN}分享链接 IPv6: ${link6}${NC}"
            share_links+="$link6"$'\n'
        fi

        save_config_to_file "SOCKS5" "$port" "$share_links"
    else
        echo -e "${RED}添加 SOCKS5 配置失败${NC}"
        return 1
    fi
}

# 添加Shadowsocks配置
add_shadowsocks() {
    echo -e "${BLUE}添加Shadowsocks配置${NC}"
    
    local port=$(random_port)
    local password=$(random_password)
    local config
    
    config=$(generate_shadowsocks_config "$port" "$password")
    
    if safe_config_update ".inbounds += [$config]"; then
        echo -e "${GREEN}Shadowsocks配置添加成功${NC}"
        echo "端口: $port"
        echo "密码: $password"
        echo "加密方式: chacha20-ietf-poly1305"
        
        local share_links
        share_links=$(generate_share_links "shadowsocks" "$port" "$password")
        echo "$share_links"
        
        restart_service_with_feedback
        save_config_to_file "Shadowsocks" "$port" "$share_links"
    else
        echo -e "${RED}添加Shadowsocks配置失败${NC}"
        return 1
    fi
}

# 添加VMess配置
add_vmess() {
    echo -e "${BLUE}添加VMess配置${NC}"
    
    local port=$(random_port)
    local uuid=$(generate_uuid)
    local config
    
    config=$(generate_vmess_config "$port" "$uuid")
    
    if safe_config_update ".inbounds += [$config]"; then
        echo -e "${GREEN}VMess配置添加成功${NC}"
        echo "端口: $port"
        echo "UUID: $uuid"
        echo "AlterID: 0"
        
        local share_links
        share_links=$(generate_share_links "vmess" "$port" "$uuid")
        echo "$share_links"
        
        restart_service_with_feedback
        save_config_to_file "VMess" "$port" "$share_links"
    else
        echo -e "${RED}添加VMess配置失败${NC}"
        return 1
    fi
}

# 添加Anytls配置
add_anytls() {
    echo -e "${BLUE}添加 AnyTLS 配置${NC}"
    generate_tls_cert

    local port
    port=$(random_port)
    local username="sekai"
    local client_id
    client_id=$(generate_uuid)

    # 生成服务端配置：用户名保留，密码使用 client_id
    local config
    config=$(generate_anytls_config "$port" "$username" "$client_id")

    if safe_config_update ".inbounds += [$config]"; then
        echo -e "${GREEN}AnyTLS 配置添加成功${NC}"
        echo "端口: $port"
        restart_service_with_feedback

        local tag="anytls-${port}"
        local share_links=""

        # IPv6 链接（存在时）
        if [[ -n "$SERVER_IPV6" ]]; then
            local link6="anytls://${client_id}@[${SERVER_IPV6}]:${port}?insecure=1&allowInsecure=1#${tag}"
            echo -e "${GREEN}分享链接 IPv6: ${link6}${NC}"
            share_links+="$link6"$'\n'
        fi

        # IPv4 链接（存在时）
        if [[ -n "$SERVER_IPV4" ]]; then
            local link4="anytls://${client_id}@${SERVER_IPV4}:${port}?insecure=1&allowInsecure=1#${tag}"
            echo -e "${GREEN}分享链接 IPv4: ${link4}${NC}"
            share_links+="$link4"$'\n'
        fi

        # 保存两条链接（或现有的一条）
        save_config_to_file "AnyTLS" "$port" "$share_links"
    else
        echo -e "${RED}添加 AnyTLS 配置失败${NC}"
        return 1
    fi
}

# 查看当前配置
view_config() {
    echo -e "${BLUE}当前配置信息${NC}"
    
    if [[ ! -f "$CONFIG_FILE" ]]; then
        echo -e "${RED}配置文件不存在${NC}"
        return 1
    fi
    
    local inbounds
    inbounds=$(jq -r '.inbounds[] | "\(.type) - 端口: \(.listen_port) - 标签: \(.tag)"' "$CONFIG_FILE" 2>/dev/null)
    
    if [[ -z "$inbounds" ]]; then
        echo -e "${YELLOW}暂无入站配置${NC}"
    else
        echo -e "${GREEN}入站配置:${NC}"
        echo "$inbounds"
    fi
    
    echo ""
    echo -e "${GREEN}服务器信息:${NC}"
    echo "IPv4地址: ${SERVER_IPV4:-"未获取"}"
    echo "IPv6地址: ${SERVER_IPV6:-"未获取"}"
}

# 删除协议（原删除配置，添加子菜单循环）
delete_protocol() {
  while true; do
    echo -e "${BLUE}删除协议${NC}"

    if [[ ! -f "$CONFIG_FILE" ]]; then
      echo -e "${RED}配置文件不存在${NC}"
      break
    fi

    local inbounds
    inbounds=$(jq -r '.inbounds[] | select(.listen_port != null) |
                      "\(.listen_port) - \(.type) - \(.tag)"' "$CONFIG_FILE" 2>/dev/null)

    if [[ -z "$inbounds" ]]; then
      echo -e "${YELLOW}暂无可删除的配置${NC}"
      break
    fi

    echo -e "${GREEN}当前配置:${NC}"
    echo "$inbounds" | awk '{printf("%d  %s\n", NR, $0)}'
    echo "0) 返回上级目录"
    read -p "请输入要删除的配置编号: " choice

    # ---------- 处理返回 ----------
    [[ "$choice" == "0" ]] && break

    # ---------- 正常删除 ----------
    if [[ "$choice" =~ ^[0-9]+$ ]]; then
      local port
      port=$(echo "$inbounds" | sed -n "${choice}p" | cut -d' ' -f1)

      if [[ -n "$port" ]]; then
        local cfg_info
        cfg_info=$(echo "$inbounds" | sed -n "${choice}p")

        if confirm_action "确定要删除 [$cfg_info] 吗？"; then
          backup_config
          if safe_config_update "del(.inbounds[] | select(.listen_port == $port))"; then
            echo -e "${GREEN}配置删除成功${NC}"
            restart_service_with_feedback
            find /root/ -name "*_${port}.txt" -delete 2>/dev/null || true
            [[ "$cfg_info" == *"anytls"* ]] && {
              rm -f /etc/sing-box/server.{crt,key}
              echo -e "${YELLOW}已删除 AnyTLS 证书和私钥${NC}"
            }
          else
            echo -e "${RED}配置删除失败${NC}"
          fi
        else
          echo -e "${YELLOW}取消删除操作${NC}"
        fi
      else
        echo -e "${RED}无效选择${NC}"
      fi
    else
      echo -e "${RED}请输入有效数字${NC}"
    fi
    echo
  done
}

# 安装sing-box（仅使用curl脚本）
install_singbox() {
    echo -e "${BLUE}安装sing-box${NC}"
    
    if command -v sing-box >/dev/null 2>&1; then
        echo -e "${YELLOW}sing-box已安装${NC}"
        sing-box version
        return 0
    fi
    
    echo "正在通过官方脚本安装sing-box..."
    
    {
        curl -fsSL https://sing-box.app/install.sh | bash
    } &
    show_progress $! "正在安装 sing-box"
    wait
    
    if command -v sing-box >/dev/null 2>&1; then
        echo -e "${GREEN}sing-box安装成功${NC}"
        systemctl enable sing-box
        
        # 首次安装强制初始化
        force_initialize_config
        
        # 安装成功后自动获取IP
        echo ""
        get_server_ips
    else
        echo -e "${RED}sing-box安装失败${NC}"
        return 1
    fi
}

# 卸载sing-box
uninstall_singbox() {
    echo -e "${BLUE}卸载sing-box${NC}"
    
    if ! confirm_action "确定要卸载sing-box吗？这将删除所有配置文件"; then
        echo "取消卸载"
        return 0
    fi
    
    # 停止并禁用服务
    systemctl stop sing-box 2>/dev/null || true
    systemctl disable sing-box 2>/dev/null || true
    
    # 在卸载前先清空配置目录（避免dpkg警告）
    if [[ -d "/etc/sing-box" ]]; then
        echo "预清理配置目录..."
        # 备份重要文件到临时位置
        if [[ -f "$CONFIG_FILE" ]]; then
            cp "$CONFIG_FILE" "/tmp/singbox_backup_$$.json" 2>/dev/null || true
        fi
        # 清空目录内容但保留目录结构
        find /etc/sing-box -type f -delete 2>/dev/null || true
        find /etc/sing-box -type d -empty -delete 2>/dev/null || true
    fi
    
    # 使用包管理器卸载
    local pkg_manager=$(detect_package_manager)
    
    case "$pkg_manager" in
        "apt")
            echo "使用APT卸载sing-box..."
            if apt list --installed 2>/dev/null | grep -q "sing-box"; then
                # 重定向stderr以隐藏dpkg警告
                apt-get remove --purge -y sing-box >/dev/null 2>&1 || true
                echo -e "${GREEN}通过APT卸载成功${NC}"
            else
                echo -e "${YELLOW}APT中未找到sing-box包，尝试手动清理${NC}"
                manual_cleanup
            fi
            ;;
        "dnf")
            echo "使用DNF卸载sing-box..."
            if rpm -qa | grep -q "sing-box"; then
                dnf remove -y sing-box >/dev/null 2>&1 || true
                echo -e "${GREEN}通过DNF卸载成功${NC}"
            else
                echo -e "${YELLOW}DNF中未找到sing-box包，尝试手动清理${NC}"
                manual_cleanup
            fi
            ;;
        "yum")
            echo "使用YUM卸载sing-box..."
            if rpm -qa | grep -q "sing-box"; then
                yum remove -y sing-box >/dev/null 2>&1 || true
                echo -e "${GREEN}通过YUM卸载成功${NC}"
            else
                echo -e "${YELLOW}YUM中未找到sing-box包，尝试手动清理${NC}"
                manual_cleanup
            fi
            ;;
        "pacman")
            echo "使用Pacman卸载sing-box..."
            if pacman -Q sing-box >/dev/null 2>&1; then
                pacman -R --noconfirm sing-box >/dev/null 2>&1 || true
                echo -e "${GREEN}通过Pacman卸载成功${NC}"
            else
                echo -e "${YELLOW}Pacman中未找到sing-box包，尝试手动清理${NC}"
                manual_cleanup
            fi
            ;;
        *)
            echo -e "${YELLOW}未检测到支持的包管理器，进行手动清理${NC}"
            manual_cleanup
            ;;
    esac
    
    # 卸载后彻底清理残留
    echo "清理残留文件..."
    rm -rf /etc/sing-box/ 2>/dev/null || true
    rm -f /tmp/singbox_backup_$$.json 2>/dev/null || true
    
    # 删除保存的配置文件
    find /root/ -name "Shadowsocks_*.txt" -delete 2>/dev/null || true
    find /root/ -name "VMess_*.txt" -delete 2>/dev/null || true
    
    systemctl daemon-reload
    
    echo -e "${GREEN}sing-box卸载完成${NC}"
    echo -e "${BLUE}脚本即将退出...${NC}"
    sleep 2
    exit 0
}

# 手动清理函数
manual_cleanup() {
    echo "进行手动清理..."
    # 删除二进制文件
    rm -f /usr/local/bin/sing-box
    rm -f /usr/bin/sing-box
    # 删除systemd服务文件
    rm -f /etc/systemd/system/sing-box.service
    rm -f /lib/systemd/system/sing-box.service
    echo -e "${GREEN}手动清理完成${NC}"
}

# 主菜单
show_menu() {
    clear
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}      Sing-box 管理脚本${NC}"
    echo -e "${BLUE}================================${NC}"
    echo ""
    
    # 检查sing-box是否已安装
    if command -v sing-box >/dev/null 2>&1; then
        # 获取版本号，仅保留纯版本
        local version
        version=$(sing-box version 2>/dev/null | head -n1 | awk '{print $3}' || echo "未知")

        printf "${GREEN}✓ sing-box 已安装${NC} ${BLUE}(v%s)${NC}\n" "$version"
        
        # 显示详细服务状态
        local status
        status=$(get_service_status)
        local running_status=$(echo "$status" | head -n1)
        local enabled_status=$(echo "$status" | tail -n1)
        
        if [[ "$running_status" == "running" ]]; then
            echo -e "${GREEN}✓ 服务运行中${NC}"
        else
            echo -e "${RED}✗ 服务已停止${NC}"
        fi
        
        if [[ "$enabled_status" == "enabled" ]]; then
            echo -e "${GREEN}✓ 开机自启已启用${NC}"
        else
            echo -e "${YELLOW}⚠ 开机自启未启用${NC}"
        fi
        
        # 显示服务器IP信息
        if [[ -n "$SERVER_IPV4" || -n "$SERVER_IPV6" ]]; then
            echo ""
            echo -e "${GREEN}服务器信息:${NC}"
            [[ -n "$SERVER_IPV4" ]] && echo "  IPv4: $SERVER_IPV4"
            [[ -n "$SERVER_IPV6" ]] && echo "  IPv6: $SERVER_IPV6"
        fi
        
        # 显示当前优先级
        CURRENT_PRIORITY=$(get_current_priority)
        echo ""
        echo -e "${GREEN}当前优先级:${NC}"
        if [[ "$CURRENT_PRIORITY" == "ipv6" ]]; then
            echo "  IPv6优先"
        elif [[ "$CURRENT_PRIORITY" == "ipv4" ]]; then
            echo "  IPv4优先"
        else
            echo "  系统默认 (通常IPv4优先)"
        fi
        
        echo ""
        
        # 根据服务状态显示相应的菜单选项
        local menu_num=1
        
        # 服务控制选项（根据当前状态显示）
        if [[ "$running_status" == "running" ]]; then
            echo "$menu_num. 停止服务"
            ((menu_num++))
            echo "$menu_num. 重启服务"
            ((menu_num++))
        else
            echo "$menu_num. 启动服务"
            ((menu_num++))
        fi
        
        # 自启动控制选项（根据当前状态显示）
        if [[ "$enabled_status" == "enabled" ]]; then
            echo "$menu_num. 禁用开机自启"
            ((menu_num++))
        else
            echo "$menu_num. 启用开机自启"
            ((menu_num++))
        fi
        
        echo "$menu_num. 查看服务日志"
        ((menu_num++))
        echo "$menu_num. 添加协议"
        ((menu_num++))
        echo "$menu_num. 删除协议"
        ((menu_num++))
        echo "$menu_num. 查看当前配置"
        ((menu_num++))
        echo "$menu_num. 刷新服务器IP"
        ((menu_num++))

        # 动态添加优先级切换选项，并记录编号
        SWITCH_PRIORITY_NUM=0  # 默认0，表示无
        if [[ -n "$SERVER_IPV4" && -n "$SERVER_IPV6" ]]; then  # 只有双栈时才允许切换
            if [[ "$CURRENT_PRIORITY" == "ipv6" ]]; then
                SWITCH_PRIORITY_NUM=$menu_num
                echo "$menu_num. 切换到IPv4优先"
                ((menu_num++))
            elif [[ "$CURRENT_PRIORITY" == "ipv4" ]]; then
                SWITCH_PRIORITY_NUM=$menu_num
                echo "$menu_num. 切换到IPv6优先"
                ((menu_num++))
            fi
        fi
        
        UNINSTALL_NUM=$menu_num  # 卸载编号跟随在上一个后
        echo "$menu_num. 卸载 sing-box"
        echo "0. 退出"
    else
        echo -e "${RED}✗ sing-box 未安装${NC}"
        local pkg_manager=$(detect_package_manager)
        echo -e "${BLUE}  检测到包管理器: $pkg_manager${NC}"
        
        echo ""
        echo "1. 安装 sing-box"
        echo "0. 退出"
    fi
    
    echo ""
}

# 主函数
main() {
    # 检查root权限
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}请使用root权限运行此脚本${NC}"
        exit 1
    fi
    
    declare -A debian_pkg=( [jq]=jq [uuidgen]=uuid-runtime [curl]=curl )
    declare -A redhat_pkg=( [jq]=jq [uuidgen]=util-linux [curl]=curl )
    declare -A arch_pkg=( [jq]=jq [uuidgen]=util-linux [curl]=curl )

    # 检查并安装依赖
    for cmd in jq uuidgen curl; do
        if ! command -v $cmd >/dev/null 2>&1; then
            echo "未检测到 $cmd，正在尝试自动安装..."
            if command -v apt >/dev/null 2>&1; then
                sudo apt update
                sudo apt install -y "${debian_pkg[$cmd]}"
            elif command -v yum >/dev/null 2>&1; then
                sudo yum install -y epel-release
                sudo yum install -y "${redhat_pkg[$cmd]}"
            elif command -v dnf >/dev/null 2>&1; then
                sudo dnf install -y "${redhat_pkg[$cmd]}"
            elif command -v pacman >/dev/null 2>&1; then
                sudo pacman -Sy --noconfirm "${arch_pkg[$cmd]}"
            elif command -v apk >/dev/null 2>&1; then
                sudo apk add "${alpine_pkg[$cmd]}"
            else
                echo "未能识别的包管理器，请手动安装 $cmd。"
                exit 1
            fi
        fi
    done
    
    # 如果sing-box已安装，自动获取服务器IP
    if command -v sing-box >/dev/null 2>&1; then
        get_server_ips
    fi
    
    while true; do
        show_menu
        read -p "请选择操作: " choice
        
        # 根据sing-box安装状态处理不同的选项
        if command -v sing-box >/dev/null 2>&1; then
            # 获取当前服务状态
            local status
            status=$(get_service_status)
            local running_status=$(echo "$status" | head -n1)
            local enabled_status=$(echo "$status" | tail -n1)
            
            # 动态菜单逻辑
            local menu_num=1
            
            # 服务控制选项处理
            if [[ "$running_status" == "running" ]]; then
                if [[ "$choice" == "$menu_num" ]]; then
                    systemctl stop sing-box && echo -e "${GREEN}服务停止成功${NC}" || echo -e "${RED}服务停止失败${NC}"
                    refresh_service_status
                    continue
                fi
                ((menu_num++))
                if [[ "$choice" == "$menu_num" ]]; then
                    restart_service_with_feedback
                    continue
                fi
                ((menu_num++))
            else
                if [[ "$choice" == "$menu_num" ]]; then
                    systemctl start sing-box && echo -e "${GREEN}服务启动成功${NC}" || echo -e "${RED}服务启动失败${NC}"
                    refresh_service_status
                    continue
                fi
                ((menu_num++))
            fi
            
            # 自启动控制选项处理
            if [[ "$enabled_status" == "enabled" ]]; then
                if [[ "$choice" == "$menu_num" ]]; then
                    systemctl disable sing-box && echo -e "${GREEN}开机自启已禁用${NC}" || echo -e "${RED}禁用开机自启失败${NC}"
                    refresh_service_status
                    continue
                fi
                ((menu_num++))
            else
                if [[ "$choice" == "$menu_num" ]]; then
                    systemctl enable sing-box && echo -e "${GREEN}开机自启已启用${NC}" || echo -e "${RED}启用开机自启失败${NC}"
                    refresh_service_status
                    continue
                fi
                ((menu_num++))
            fi
            
            # 其他固定选项处理
            if [[ "$choice" == "$menu_num" ]]; then
                echo -e "${BLUE}查看服务日志 (按 Ctrl+C 退出)${NC}"
                journalctl -u sing-box -f --no-pager
            elif [[ "$choice" == $((menu_num+1)) ]]; then
                # 添加协议（添加子菜单循环）
                while true; do
                    echo "请选择协议类型："
                    echo "1) Socks5"
                    echo "2) Shadowsocks"
                    echo "3) VMess"
                    echo "4) AnyTLS"
                    echo "0. 返回上级目录"
                    read -p "输入序号: " proto_choice
                    if [[ "$proto_choice" == "0" ]]; then
                        break
                    fi
                    case "$proto_choice" in
                        1) add_socks5 ;;
                        2) add_shadowsocks ;;
                        3) add_vmess ;;
                        4) add_anytls ;;
                        *) echo -e "${RED}无效选项${NC}" ;;
                    esac
                done
            elif [[ "$choice" == $((menu_num+2)) ]]; then
                delete_protocol
            elif [[ "$choice" == $((menu_num+3)) ]]; then
                view_config
                wait_for_return
            elif [[ "$choice" == $((menu_num+4)) ]]; then
                get_server_ips
                wait_for_return
            elif [[ $SWITCH_PRIORITY_NUM -ne 0 && "$choice" == "$SWITCH_PRIORITY_NUM" ]]; then
                # 动态优先级切换
                if [[ "$CURRENT_PRIORITY" == "ipv6" ]]; then
                    set_priority "ipv4"
                    echo -e "${GREEN}已切换到 IPv4 优先${NC}"
                elif [[ "$CURRENT_PRIORITY" == "ipv4" ]]; then
                    set_priority "ipv6"
                    echo -e "${GREEN}已切换到 IPv6 优先${NC}"
                fi
                wait_for_return
            elif [[ "$choice" == "$UNINSTALL_NUM" ]]; then
                uninstall_singbox
                # 卸载后会直接退出，不会到这里
            elif [[ "$choice" == "0" ]]; then
                echo -e "${GREEN}感谢使用！${NC}"
                exit 0
            else
                echo -e "${RED}无效选项，请重新选择${NC}"
                sleep 2
            fi
        else
            # sing-box未安装的菜单逻辑
            case $choice in
                1)
                    install_singbox
                    wait_for_return
                    ;;
                0)
                    echo -e "${GREEN}感谢使用！${NC}"
                    exit 0
                    ;;
                *)
                    echo -e "${RED}无效选项，请重新选择${NC}"
                    sleep 2
                    ;;
            esac
        fi
    done
}

# 运行主函数
main "$@"
