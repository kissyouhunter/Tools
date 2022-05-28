#!/bin/bash
echo "start"
cd /system
#rm -f Emby.Web.dll
if [ -a /system/Emby.Web.dll ]; then
    echo "delete Emby.Web.dll error"
else
    echo "Emby.Web.dll removed"
fi
sleep 1
#wget https://github.com/kissyouhunter/Tools/raw/main/emby/4.6.7.0/Emby.Web.dll
#rm -f MediaBrowser.Model.dll
#wget https://github.com/kissyouhunter/Tools/raw/main/emby/4.6.7.0/MediaBrowser.Model.dll
#cd /system/dashboard-ui/embypremiere/
#rm -f embypremiere.js
#wget https://raw.githubusercontent.com/kissyouhunter/Tools/main/emby/4.6.7.0/embypremiere.js
echo "done"
