#!/bin/bash

# Step 1: 检查并安装jq
if ! command -v jq &> /dev/null; then
    echo "jq 未安装，尝试自动安装..."
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        case "$ID" in
            ubuntu | debian)
                sudo apt-get update && sudo apt-get install -y jq
                ;;
            centos | rhel | fedora | amzn)
                sudo yum install -y jq
                ;;
            *)
                echo "不支持的Linux发行版，无法自动安装jq，请手动安装。"
                exit 1
                ;;
        esac
    else
        echo "无法识别操作系统发行版，无法自动安装jq，请手动安装。"
        exit 1
    fi
    echo "jq 安装完成。"
else
    echo "jq 已安装。"
fi

# Step 2: 使用GitHub API获取最新版本的realm下载链接
api_url="https://api.github.com/repos/zhboner/realm/releases/latest"
release_info=$(curl -s "$api_url")
architecture=$(uname -m)
case "$architecture" in
    x86_64)
        suffix="x86_64-unknown-linux-gnu.tar.gz"
        ;;
    aarch64)
        suffix="aarch64-unknown-linux-gnu.tar.gz"
        ;;
    armv7l)
        suffix="armv7-unknown-linux-gnueabihf.tar.gz"
        ;;
    arm*)
        suffix="arm-unknown-linux-gnueabihf.tar.gz"
        ;;
    *)
        echo "不支持的架构：$architecture"
        exit 1
        ;;
esac
file_name="realm-${suffix}"
download_url=$(echo "$release_info" | jq -r ".assets[] | select(.name | endswith(\"$suffix\")) | .browser_download_url")
if [ -z "$download_url" ]; then
    echo "找不到匹配的下载链接"
    exit 1
fi

# Step 3: 下载并解压realm
echo "下载链接：$download_url"
curl -L "$download_url" -o "/tmp/$file_name"
tar -xzvf "/tmp/$file_name" -C /tmp

# Step 4: 将realm可执行文件移动到/usr/local/bin/
sudo mv "/tmp/realm" /usr/local/bin/realm
sudo chmod +x /usr/local/bin/realm
echo "realm 安装完成。"

# 创建配置文件目录
config_dir="/root/.realm"
mkdir -p "$config_dir"
config_file="$config_dir/config.toml"

# 检查config.toml文件是否存在
if [ -f "$config_file" ]; then
    echo "$config_file 已存在。"
    read -p "是否覆盖已存在的config.toml文件？(y/N): " answer
    case "$answer" in
        [Yy]* )
            echo "将覆盖已存在的文件..."
            ;;
        * )
            echo "操作取消。"
            exit 1
            ;;
    esac
fi

# 创建并写入配置到config.toml文件
cat << EOF > "$config_file"
[log]
level = "warn"
output = "$config_dir/realm.log"

[network]
no_tcp = false
use_udp = true

[[endpoints]]
listen = "0.0.0.0:5000"
remote = "1.1.1.1:443"
extra_remotes = ["1.1.1.2:443", "1.1.1.3:443"]
balance = "roundrobin: 4, 2, 1"

[[endpoints]]
listen = "[::]:10000"
remote = "www.google.com:443"
EOF

echo "config.toml 配置文件已创建于 $config_file。"

# Step 5: 创建systemd服务文件
cat << EOF > /tmp/realm.service
[Unit]
Description=Realm Proxy Service
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/realm -c /root/.realm/config.toml
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
sudo mv /tmp/realm.service /etc/systemd/system/realm.service

echo "systemd 服务文件已创建。"
