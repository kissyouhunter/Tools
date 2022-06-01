#!/bin/bash
#author kissyouhunter
#自动安装依赖说明
#青龙青龙容器后执行 rm -f qinglong.sh && curl -fsSL https://raw.githubusercontent.com/kissyouhunter/Tools/main/qinglong.sh | bash


TIME() {
[[ -z "$1" ]] && {
	echo -ne " "
} || {
     case $1 in
	r) export Color="\e[31;1m";;
	g) export Color="\e[32;1m";;
	b) export Color="\e[34;1m";;
	y) export Color="\e[33;1m";;
	z) export Color="\e[35;1m";;
	l) export Color="\e[36;1m";;
        m) export Color="\e[37;1m";;
	w) export Color="\e[29;1m";;
      esac
	[[ $# -lt 2 ]] && echo -e "\e[36m\e[0m ${1}" || {
		echo -e "\e[36m\e[0m ${Color}${2}\e[0m"
	 }
      }
}

TIME y "青龙安装依赖脚本，如想退出，请在10秒内输入ctrl+c退出脚本。"
sleep 10
TIME y "开始安装依赖，安装依赖速度取决于网速和CPU，耐心等吧！"
sleep 2
if [ -e "/ql/data/scripts" ]; then
	apk update
	apk add --no-cache build-base g++ cairo-dev pango-dev giflib-dev
	TIME g "apk 执行完毕"
	pnpm install -g axios
	pnpm install -g date-fns
	pnpm install -g require
	pnpm install -g --save-dev @types/node
	pnpm install -g tslib
	pnpm install -g png-js
	pnpm install -g ts-md5
	pnpm install -g md5
	pnpm install -g crypto-js
	pnpm install -g dotenv
	pnpm install -g tough-cookie
	pnpm install -g sync-request
	pnpm install -g cron
	pnpm install -g jsdom
	pnpm install -g js-base64
	pnpm install -g ws@7.4.3
	pnpm install -g jieba
	pnpm install -g fs
	pnpm install -g form-data
	pnpm install -g json5
	pnpm install -g global-agent
	pnpm install -g @types/node  
	pnpm install -g typescript
	pnpm install -g requests
	pnpm install -g canvas
	pnpm install -g crypto-js --save
	pnpm install -g moment
	TIME g "pnpm 执行完毕"
	pip3 install file-read-backwards prettytable canvas requests ping3 jieba
	pip3 install pillow  --no-cache-dir
	TIME g "pip3 执行完毕"
	TIME g "依赖安装完毕，如有错误，请重试。"
	sleep 2
	TIME g "退出脚本"
	exit 0
elif [ -e "/ql/scripts" ]; then
	apk update
	apk add --no-cache build-base g++ cairo-dev pango-dev giflib-dev
	TIME g "apk 执行完毕"
	pnpm install -g axios
	pnpm install -g date-fns
	pnpm install -g require
	pnpm install -g --save-dev @types/node
	pnpm install -g tslib
	pnpm install -g png-js
	pnpm install -g ts-md5
	pnpm install -g md5
	pnpm install -g crypto-js
	pnpm install -g dotenv
	pnpm install -g tough-cookie
	pnpm install -g sync-request
	pnpm install -g cron
	pnpm install -g jsdom
	pnpm install -g js-base64
	pnpm install -g ws@7.4.3
	pnpm install -g jieba
	pnpm install -g fs
	pnpm install -g form-data
	pnpm install -g json5
	pnpm install -g global-agent
	pnpm install -g @types/node  
	pnpm install -g typescript
	pnpm install -g requests
	pnpm install -g canvas
	pnpm install -g crypto-js --save
	pnpm install -g moment
	TIME g "pnpm 执行完毕"
	pip3 install file-read-backwards prettytable canvas requests ping3 jieba
	pip3 install pillow  --no-cache-dir
	TIME g "pip3 执行完毕"
	TIME g "依赖安装完毕，如有错误，请重试。"
	sleep 2
	TIME g "退出脚本"
	exit 0
else
	TIME r "非青龙，脚本退出！"
	exit 0
fi

exit 0
