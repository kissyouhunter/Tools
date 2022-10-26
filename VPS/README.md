DD VPS linux

```
#UBUNTU 20.04
bash <(wget --no-check-certificate -qO- 'https://ghproxy.com/https://raw.githubusercontent.com/kissyouhunter/Tools/main/VPS/InstallNET.sh') -u 20.04 -v 64 -p "password" -port "22" --mirror "http://mirrors.ustc.edu.cn/ubuntu/"
```

```
#DEBIAN 11
bash <(wget --no-check-certificate -qO- 'https://ghproxy.com/https://raw.githubusercontent.com/kissyouhunter/Tools/main/VPS/InstallNET.sh') -d 11 -v 64 -p "password" -port "22" --mirror "http://mirrors.ustc.edu.cn/debian/"
```
```
#check ip
wget https://github.com/kissyouhunter/Tools/raw/main/VPS/checkip.sh
mv checkip.sh /etc/init.d/checkip && chmod +x /etc/init.d/checkip && update-rc.d -f checkip defaults && bash /etc/init.d/checkip
```
