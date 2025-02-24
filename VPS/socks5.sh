#!/bin/bash

# --- 配置参数 ---
CONFIG_PATH="/usr/local/etc/xray/config.json"
BACKUP_DIR="/usr/local/etc/xray/"
OUTPUT_FILE="/root/ss5.txt"
LOG_DIR="/var/log/xray/"
# --- 卸载处理 ---
if [[ "$1" == "remove" ]]; then
    echo "Uninstalling Xray..."
    bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ remove
    rm -rf ${BACKUP_DIR}
    rm -rf ${LOG_DIR}
    rm -f ${OUTPUT_FILE}
    exit $?
fi

# --- 函数定义 ---

# 生成随机端口 (10000-65535)
generate_random_port() {
  echo $((10000 + RANDOM % 55536))
}

# 生成随机用户名/密码 (8-16位字母数字组合)
generate_random_user_pass() {
  cat /dev/urandom | tr -dc A-Za-z0-9 | head -c$((8 + RANDOM % 9))
  echo ""
}

# 获取公网 IPv4 地址
get_ipv4() {
  ipv4=$(curl -4 -s --max-time 5 http://api.ipify.org)
  if [ $? -ne 0 ]; then
    echo "Error: Failed to retrieve IPv4 address."
    exit 1
  fi
  echo "$ipv4"
}

# 获取公网 IPv6 地址
get_ipv6() {
  ipv6=$(curl -6 -s --max-time 5 http://api6.ipify.org)
  if [ $? -ne 0 ]; then
    echo "Error: Failed to retrieve IPv6 address."
    exit 1
  fi
  echo "$ipv6"
}

# --- 主要逻辑 ---

# 1. 安装 Xray (如果尚未安装)
if ! command -v xray &> /dev/null; then
    echo "Installing Xray..."
    bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install
    if [ $? -ne 0 ]; then
        echo "Error: Xray installation failed."
        exit 1
    fi
else
    echo "Xray is already installed."
fi

# 2. 生成随机配置
random_port=$(generate_random_port)
random_user=$(generate_random_user_pass)
random_pass=$(generate_random_user_pass)

# 3. 创建配置文件的JSON内容
config_content=$(cat <<EOF
{
  "log": {
    "loglevel": "warning"
  },
  "inbounds": [
    {
      "port": ${random_port},
      "protocol": "socks",
      "settings": {
        "auth": "password",
        "accounts": [
          {
            "user": "${random_user}",
            "pass": "${random_pass}"
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
  ],
  "outbounds": [
    {
      "protocol": "freedom",
      "settings": {}
    }
  ]
}
EOF
)

# 4. 备份和覆盖
if [ -f "$CONFIG_PATH" ]; then
  timestamp=$(date +%Y%m%d%H%M%S)
  backup_file="${BACKUP_DIR}config_${timestamp}.json"
  echo "Existing config file found. Backing up to: $backup_file"
  cp "$CONFIG_PATH" "$backup_file"
fi

# 5. 写入新的配置文件
echo "Writing new config file to: $CONFIG_PATH"
echo "$config_content" | tee "$CONFIG_PATH" > /dev/null

# --- 权限设置 ---
mkdir -p "$(dirname "$CONFIG_PATH")"
chmod 644 "$CONFIG_PATH"

# 6. 重启 Xray 服务
echo "Restarting Xray service..."
systemctl restart xray
if [ $? -ne 0 ]; then
    echo "Warning: Failed to restart Xray service."
fi

# 7. 获取 IP 地址
ipv4_address=$(get_ipv4)
ipv6_address=$(get_ipv6)

# 8. 构建输出信息
output_info=""
if [[ $ipv4_address =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  output_info+="${ipv4_address}:${random_port}:${random_user}:${random_pass}\n"
fi
if [[ $ipv6_address =~ ^[0-9a-f:]+$ ]]; then
  output_info+="[${ipv6_address}]:${random_port}:${random_user}:${random_pass}\n"
fi

# 9. 显示并保存信息
echo -e "\n--- Connection Information ---"
echo -e "$output_info"
echo -e "$output_info" > "$OUTPUT_FILE"

echo "Connection information saved to: $OUTPUT_FILE"

exit 0
