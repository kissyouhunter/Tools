#!/bin/bash

# 检查是否以 root 权限运行
if [ "$EUID" -ne 0 ]; then
  echo "错误：请以 root 权限运行此脚本（使用 sudo）"
  exit 1
fi

# 步骤 1：检查并卸载 nano
echo "步骤 1：检查并卸载 nano..."
if command -v nano &> /dev/null; then
  echo "发现 nano，正在卸载..."
  if command -v apt &> /dev/null; then
    apt remove -y nano
  elif command -v yum &> /dev/null; then
    yum remove -y nano
  elif command -v dnf &> /dev/null; then
    dnf remove -y nano
  elif command -v pacman &> /dev/null; then
    pacman -R --noconfirm nano
  else
    echo "警告：未找到支持的包管理器，无法自动卸载 nano，请手动卸载"
  fi
  # 验证 nano 是否卸载成功
  if command -v nano &> /dev/null; then
    echo "错误：nano 卸载失败，请检查包管理器或手动卸载"
    exit 1
  else
    echo "验证：nano 已成功卸载"
  fi
else
  echo "验证：系统中未安装 nano，跳过卸载步骤"
fi

# 步骤 2：下载并安装 micro
echo "步骤 2：下载并安装 micro..."
curl https://getmic.ro | bash
# 验证 micro 是否下载成功
if [ -f "./micro" ]; then
  echo "验证：micro 下载成功"
else
  echo "错误：micro 下载失败，请检查网络连接或手动安装"
  exit 1
fi

# 步骤 3：移动 micro 到 /usr/local/bin
echo "步骤 3：移动 micro 到 /usr/local/bin..."
mv ./micro /usr/local/bin/micro
chmod +x /usr/local/bin/micro
# 验证 micro 是否成功移动并可执行
if [ -x "/usr/local/bin/micro" ]; then
  echo "验证：micro 已成功移动到 /usr/local/bin 并具有执行权限"
else
  echo "错误：micro 移动或设置权限失败，请检查 /usr/local/bin 目录权限"
  exit 1
fi

# 步骤 4：检查 zsh 并添加 alias 到 ~/.zshrc
echo "步骤 4：配置 zsh alias..."
if command -v zsh &> /dev/null; then
  ZSHRC="$HOME/.zshrc"
  if [ -f "$ZSHRC" ]; then
    # 检查是否已存在相同的 alias
    if ! grep -q 'alias nano="micro"' "$ZSHRC"; then
      echo 'alias nano="micro"' >> "$ZSHRC"
      # 验证 alias 是否成功添加
      if grep -q 'alias nano="micro"' "$ZSHRC"; then
        echo "验证：已成功将 'alias nano=\"micro\"' 添加到 $ZSHRC"
      else
        echo "错误：alias 添加到 $ZSHRC 失败，请检查文件权限"
        exit 1
      fi
    else
      echo "验证：$ZSHRC 中已存在 'alias nano=\"micro\"'，无需重复添加"
    fi
  else
    # 如果 .zshrc 不存在，创建并添加
    echo 'alias nano="micro"' > "$ZSHRC"
    # 验证文件创建和内容
    if [ -f "$ZSHRC" ] && grep -q 'alias nano="micro"' "$ZSHRC"; then
      echo "验证：已创建 $ZSHRC 并成功添加 'alias nano=\"micro\"'"
    else
      echo "错误：创建 $ZSHRC 或添加 alias 失败，请检查写入权限"
      exit 1
    fi
  fi
else
  echo "错误：未检测到 zsh，请确保已安装 zsh 并手动配置 alias"
  exit 1
fi

# 完成提示
echo "所有步骤完成！请运行 'source ~/.zshrc' 或重启终端以应用更改"
echo "验证最终结果：输入 'nano' 应启动 micro"
exit 0
