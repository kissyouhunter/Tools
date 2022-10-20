#!/bin/bash

TG_TOKEN=""  #tg机器人的token
TG_ID="" #tg的user ID

tg_push_message() {
    TOKEN=${TG_TOKEN}	#TG机器人token
    chat_ID=${TG_ID}		#用户ID或频道、群ID
    message_text="${TG_MSG}"		#要发送的信息
    MODE="HTML"		#解析模式，可选HTML或Markdown
    URL="https://api.telegram.org/bot${TOKEN}/sendMessage"		#api接口
    curl -s -o /dev/null -X POST $URL -d chat_id=${chat_ID} -d parse_mode=${MODE} -d text="${message_text}" --max-time 10
}

TXT_FILE="/root/domains.txt"

if [ -f "${TXT_FILE}" ]; then
   echo “文件存在”
else
   touch ${TXT_FILE}
   TG_MSG="${TXT_FILE} 自动创建，在文件中添加需要检测的域名。"
   tg_push_message
   exit 1
fi

if [ -s "${TXT_FILE}" ]; then
   echo "文件存在，并文件大小大于0"
else
   TG_MSG="${TXT_FILE} 中还没有域名，添加后再运行脚本。"
   tg_push_message
   exit 1
fi

DOMAINS=$(cat ${TXT_FILE})
#echo -n -e "please enter a domain or an ip: "
#read IP
#status=`echo $?`
#Local_ip=`ifconfig | grep "inet" | awk 'NR==3{print $2}'`
for i in $DOMAINS
do
test=$(ping -c 1 $i &> /dev/null && echo success || echo fail)
if [ $test == "success" ]; then
   TG_MSG="域名 $i 正在努力干活！"
   tg_push_message
   echo "域名 $i 正在努力干活！"
elif [ $test == "fail" ]; then
   TG_MSG="域名 $i GG了，有能小鸡出问题了，但是极有可能域名被回收了！"
   tg_push_message
   echo "域名 $i GG了，有能小鸡出问题了，但是极有可能域名被回收了！"
fi
done

exit 0
