#!/bin/bash

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

TIME y "start"
# modify Emby.Web.dll
rm -f /system/Emby.Web.dll
if [ -e "/system/Emby.Web.dll" ]; then
    TIME r "delete Emby.Web.dll error"
    exit
else
    TIME g "Emby.Web.dll removed"
    wget --no-check-certificate -O /system/Emby.Web.dll https://github.com/kissyouhunter/Tools/raw/main/emby/4.7.1.0/Emby.Web.dll
fi
sleep 1
if [ -e "/system/Emby.Web.dll" ]; then
    TIME g "Emby.Web.dll OKEY"
else
    TIME r "download Emby.Web.dll error"
    exit
fi
sleep 1
# modify MediaBrowser.Model.dll
rm -f /system/MediaBrowser.Model.dll
if [ -e "/system/MediaBrowser.Model.dll" ]; then
    TIME r "delete MediaBrowser.Model.dll error"
    exit
else
    TIME g "MediaBrowser.Model.dll removed"
    wget --no-check-certificate -O /system/MediaBrowser.Model.dll https://github.com/kissyouhunter/Tools/raw/main/emby/4.7.1.0/MediaBrowser.Model.dll
fi
sleep 1
if [ -e "/system/MediaBrowser.Model.dll" ]; then
    TIME g "MediaBrowser.Model.dll OKEY"
else
    TIME r "download MediaBrowser.Model.dll error"
    exit
fi
sleep 1
# modify Emby.Server.Implementations.dll
rm -f /system/Emby.Server.Implementations.dll
if [ -e "/system/Emby.Server.Implementations.dll" ]; then
    TIME r "delete Emby.Server.Implementations.dll error"
    exit
else
    TIME g "Emby.Server.Implementations.dll removed"
    wget --no-check-certificate -O /system/Emby.Server.Implementations.dll https://github.com/kissyouhunter/Tools/raw/main/emby/4.7.1.0/Emby.Server.Implementations.dll
fi
sleep 1
if [ -e "/system/Emby.Server.Implementations.dll" ]; then
    TIME g "Emby.Server.Implementations.dll OKEY"
else
    TIME r "download Emby.Server.Implementations.dll error"
    exit
fi
sleep 1
# modify embypremiere.js
rm -f /system/dashboard-ui/embypremiere/embypremiere.js
if [ -e "/system/dashboard-ui/embypremiere/embypremiere.js" ]; then
    TIME r "delete embypremiere.js error"
    exit
else
    TIME g "embypremiere.js removed"
    wget --no-check-certificate -O /system/dashboard-ui/embypremiere/embypremiere.js https://raw.githubusercontent.com/kissyouhunter/Tools/main/emby/4.7.1.0/embypremiere.js
fi
sleep 1
if [ -e "/system/dashboard-ui/embypremiere/embypremiere.js" ]; then
    TIME g "embypremiere.js OKEY"
else
    TIME r "download embypremiere.js error"
    exit
fi
sleep 1
TIME y "done"