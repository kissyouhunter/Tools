#!/bin/sh
cd /etc/nginx/sites-enabled
wget https://ghproxy.com/https://raw.githubusercontent.com/kissyouhunter/Tools/main/emby/proxy.conf
curl https://ghproxy.com/https://raw.githubusercontent.com/kissyouhunter/Tools/main/emby/GMCert_RSACA01.cer >> /etc/ssl/certs/ca-certificates.crt
cd /var/packages/EmbyServer/target/mono/bin
./cert-sync /etc/ssl/certs/ca-certificates.crt
cd /volume1/web/mb3admin.com
wget https://ghproxy.com/https://raw.githubusercontent.com/kissyouhunter/Tools/main/emby/mb3admin.com.cert.pem
wget https://ghproxy.com/https://raw.githubusercontent.com/kissyouhunter/Tools/main/emby/mb3admin.com.key.pem
cat mb3admin.com.cert.pem >> /etc/ssl/certs/ca-certificates.crt
cd /usr/local/etc/nginx/conf.d/*-*-*-*
wget https://ghproxy.com/https://raw.githubusercontent.com/kissyouhunter/Tools/main/emby/user.conf
nginx -s reload
done
