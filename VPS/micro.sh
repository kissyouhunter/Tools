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

# 步骤 5：创建并保存 micro 配置文件
echo "步骤 5：创建 micro 配置文件 ~/.config/micro/settings.json..."
MICRO_CONFIG_DIR="$HOME/.config/micro"
MICRO_CONFIG_FILE="$MICRO_CONFIG_DIR/settings.json"

# 创建配置目录（如果不存在）
if [ ! -d "$MICRO_CONFIG_DIR" ]; then
  mkdir -p "$MICRO_CONFIG_DIR"
  # 验证目录是否创建成功
  if [ ! -d "$MICRO_CONFIG_DIR" ]; then
    echo "错误：无法创建 $MICRO_CONFIG_DIR 目录，请检查权限"
    exit 1
  fi
  echo "验证：已成功创建 $MICRO_CONFIG_DIR 目录"
fi

# 写入配置文件内容
cat > "$MICRO_CONFIG_FILE" << 'EOF'
{
    "autoclose": true,
    "autoindent": true,
    "autosave": 0,
    "autosu": false,
    "backup": true,
    "backupdir": "",
    "basename": false,
    "clipboard": "external",
    "colorcolumn": 0,
    "colorscheme": "default",
    "comment": true,
    "cursorline": true,
    "detectlimit": 100,
    "diff": true,
    "diffgutter": false,
    "divchars": "|-",
    "divreverse": true,
    "encoding": "utf-8",
    "eofnewline": true,
    "fakecursor": false,
    "fastdirty": false,
    "fileformat": "unix",
    "filetype": "unknown",
    "ftoptions": true,
    "helpsplit": "hsplit",
    "hlsearch": false,
    "hltaberrors": false,
    "hltrailingws": false,
    "ignorecase": true,
    "incsearch": true,
    "indentchar": " ",
    "infobar": true,
    "initlua": true,
    "keepautoindent": false,
    "keymenu": false,
    "linter": true,
    "literate": true,
    "matchbrace": true,
    "matchbraceleft": true,
    "matchbracestyle": "underline",
    "mkparents": false,
    "mouse": false,
    "multiopen": "tab",
    "pageoverlap": 2,
    "parsecursor": false,
    "paste": false,
    "permbackup": false,
    "pluginchannels": [
        "https://raw.githubusercontent.com/micro-editor/plugin-channel/master/channel.json"
    ],
    "pluginrepos": [],
    "readonly": false,
    "relativeruler": false,
    "reload": "prompt",
    "rmtrailingws": false,
    "ruler": false,
    "savecursor": false,
    "savehistory": true,
    "saveundo": false,
    "scrollbar": false,
    "scrollbarchar": "|",
    "scrollmargin": 3,
    "scrollspeed": 2,
    "smartpaste": true,
    "softwrap": false,
    "splitbottom": true,
    "splitright": true,
    "status": true,
    "statusformatl": "$(filename) $(modified)$(overwrite)($(line),$(col)) $(status.paste)| ft:$(opt:filetype) | $(opt:fileformat) | $(opt:encoding)",
    "statusformatr": "$(bind:ToggleKeyMenu): bindings, $(bind:ToggleHelp): help",
    "statusline": true,
    "sucmd": "sudo",
    "syntax": true,
    "tabhighlight": true,
    "tabmovement": false,
    "tabreverse": false,
    "tabsize": 4,
    "tabstospaces": false,
    "useprimary": true,
    "wordwrap": false,
    "xterm": false
}
EOF

# 验证配置文件是否创建成功
if [ -f "$MICRO_CONFIG_FILE" ]; then
  # 检查文件内容是否包含特定字段（例如 "autoclose": true）
  if grep -q '"autoclose": true' "$MICRO_CONFIG_FILE"; then
    echo "验证：micro 配置文件 $MICRO_CONFIG_FILE 已成功创建并写入"
  else
    echo "错误：$MICRO_CONFIG_FILE 创建成功但内容写入失败，请检查"
    exit 1
  fi
else
  echo "错误：无法创建 $MICRO_CONFIG_FILE，请检查 $MICRO_CONFIG_DIR 权限"
  exit 1
fi

# 完成提示
echo "所有步骤完成！请运行 'source ~/.zshrc' 或重启终端以应用更改"
echo "验证最终结果：输入 'nano' 应启动 micro，且配置已生效"
exit 0
