#!/bin/bash

# Check Root User
if [[ "$EUID" -ne '0' ]]; then
    echo "$(tput setaf 1)Error: You must run this script as root!$(tput sgr0)"
    exit 1
fi

# GitHub repo & API
repo="go-gost/gost"
api_base="https://api.github.com/repos/$repo"
releases_url="$api_base/releases"
latest_url="$api_base/releases/latest"

# 安装函数
install_gost() {
    version="$1"

    # OS 检测
    uname_s="$(uname -s)"
    case "$uname_s" in
      Linux)   os="linux" ;;
      Darwin)  os="darwin" ;;
      MINGW*|MSYS*|CYGWIN*|Windows_NT) os="windows" ;;
      *) echo "Unsupported operating system: $uname_s"; exit 1 ;;
    esac

    # 架构映射
    arch="$(uname -m)"
    case "$arch" in
      x86_64|amd64)         cpu_arch="amd64" ;;
      i386|i686)            cpu_arch="386" ;;
      aarch64|arm64)        cpu_arch="arm64" ;;
      armv5*)               cpu_arch="armv5" ;;
      armv6*)               cpu_arch="armv6" ;;
      armv7*)               cpu_arch="armv7" ;;
      mips64*)              cpu_arch="mips64" ;;
      mipsel*)              cpu_arch="mipsle" ;;
      mips*)                cpu_arch="mips" ;;
      loongarch64)          cpu_arch="loong64" ;;
      riscv64)              cpu_arch="riscv64" ;;
      s390x)                cpu_arch="s390x" ;;
      *) echo "Unsupported CPU architecture: $arch"; exit 1 ;;
    esac

    # 从 tag 页面解析资产下载 URL（精确匹配 + 回退变体）
    get_download_url="$releases_url/tags/$version"
    json_all=$(curl -fsSL "$get_download_url") || { echo "Fetch release tag failed: $version"; exit 1; }

    # 提取所有 browser_download_url
    all_urls=$(printf "%s" "$json_all" \
      | tr -d '\n' \
      | grep -oP "\"browser_download_url\":[[:space:]]*\"[^\"]+\"" \
      | sed -E 's/^"browser_download_url":[[:space:]]*"([^"]+)".*$/\1/')

    # 常规匹配：gost_<ver>_<os>_<arch>.(tar.gz|zip)，ver 允许 3.2.4 或 3.2.4-rc 形式，但我们用的 latest 已是稳定版
    download_url=$(printf "%s\n" "$all_urls" \
      | grep -E "/download/${version}/gost_[0-9.]+(-[A-Za-z0-9]+)?_${os}_${cpu_arch}\.(tar\.gz|zip)$" \
      | head -n 1)

    # 回退匹配：加入 amd64v3 及 mips 浮点变体
    if [[ -z "$download_url" ]]; then
      download_url=$(printf "%s\n" "$all_urls" \
        | grep -E "/download/${version}/gost_[0-9.]+(-[A-Za-z0-9]+)?_${os}_${cpu_arch}(v3)?(_(hardfloat|softfloat))?\.(tar\.gz|zip)$" \
        | head -n 1)
    fi

    if [[ -z "$download_url" ]]; then
        echo "No matching asset for OS=${os}, ARCH=${cpu_arch}, VERSION=${version}"
        echo "Check assets: https://github.com/$repo/releases/tag/$version"
        exit 1
    fi

    echo "Downloading gost version $version..."
    curl -fsSL -o gost.pkg "$download_url" || { echo "Download failed."; exit 1; }

    echo "Installing gost..."
    # 不同平台解包
    if [[ "$download_url" =~ \.tar\.gz$ ]]; then
        tar -xzf gost.pkg || { echo "Extract failed."; rm -f gost.pkg; exit 1; }
    elif [[ "$download_url" =~ \.zip$ ]]; then
        command -v unzip >/dev/null 2>&1 || { echo "unzip not found. Please install unzip."; rm -f gost.pkg; exit 1; }
        unzip -o gost.pkg || { echo "Extract failed."; rm -f gost.pkg; exit 1; }
    else
        echo "Unknown package format."; rm -f gost.pkg; exit 1;
    fi

    # 找到解包后的二进制（通常就叫 gost）
    if [[ -f gost ]]; then
      chmod +x gost
      mv gost /usr/local/bin/gost
    else
      # 万一解包目录里包含前缀名
      bin_path="$(find . -maxdepth 2 -type f -name gost | head -n 1)"
      if [[ -n "$bin_path" ]]; then
        chmod +x "$bin_path"
        mv "$bin_path" /usr/local/bin/gost
      else
        echo "gost binary not found after extraction."
        exit 1
      fi
    fi

    # 清理
    rm -f LICENSE README.md README_en.md gost.pkg 2>/dev/null || true

    # 配置与 service
    mkdir -p /root/.gost/
    if [[ -f /root/.gost/gost.yml ]]; then
        read -p "/root/.gost/gost.yml 已存在. 是否覆盖? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            wget -O /root/.gost/gost.yml https://github.com/kissyouhunter/Tools/raw/main/VPS/gost.yml
        fi
    else
        wget -O /root/.gost/gost.yml https://github.com/kissyouhunter/Tools/raw/main/VPS/gost.yml
    fi

    wget -O /etc/systemd/system/gost.service https://github.com/kissyouhunter/Tools/raw/main/VPS/gost.service

    echo "gost installation completed!"
    echo "配置文件在 /root/.gost/gost.yml"
    echo "systemctl enable gost 命令开启开机自启动"
    echo "systemctl start gost 命令开启gost服务"
    echo "systemctl restart gost 命令重启gost服务"
}

# 获取最新稳定版 tag（使用 releases/latest）
get_latest_stable_tag() {
  curl -fsSL "$latest_url" | grep -oP '"tag_name":[[:space:]]*"\K[^"]+'
}

# 获取第一页的所有 tag（用于交互展示）
get_release_tags_page1() {
  curl -fsSL "$releases_url?per_page=100&page=1" | grep -oP '"tag_name":[[:space:]]*"\K[^"]+'
}

# 主逻辑
if [[ "$1" == "--install" ]]; then
    latest_version="$(get_latest_stable_tag)"
    if [[ -z "$latest_version" ]]; then
        echo "未能从 releases/latest 获取稳定版本，请稍后重试或检查网络/GitHub API。"
        exit 1
    fi
    echo "检测到最新稳定版本: $latest_version"
    install_gost "$latest_version"
else
    echo "Available gost versions (最新稳定版置顶):"
    latest_version="$(get_latest_stable_tag)"
    all_tags="$(get_release_tags_page1)"

    list=""
    if [[ -n "$latest_version" ]]; then
        list="$latest_version"
    fi
    while IFS= read -r t; do
        [[ -z "$t" ]] && continue
        [[ "$t" == "$latest_version" ]] && continue
        list="$list $t"
    done <<< "$all_tags"

    select version in $list; do
        if [[ -n "$version" ]]; then
            install_gost "$version"
            break
        else
            echo "Invalid choice! Please select a valid option."
        fi
    done
fi
