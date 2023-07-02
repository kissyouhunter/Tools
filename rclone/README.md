### rcloned 挂载脚本

挂载需要安装 fuse，根据自己的系统来选择安装命令
```
# Debian/Ubantu
apt-get update && apt-get install -y fuse
# CentOS
yum install -y fuse
```
wget https://github.com/kissyouhunter/Tools/raw/main/rclone/rcloned
```

设置开机自启

```
mv rcloned /etc/init.d/rcloned 
chmod +x /etc/init.d/rcloned 
update-rc.d -f rcloned defaults # Debian/Ubuntu 
chkconfig rcloned on # CentOS 
bash /etc/init.d/rcloned start 
```

卸载自启挂载
```
bash /etc/init.d/rcloned stop
update-rc.d -f rcloned remove # Debian/Ubuntu
chkconfig rcloned off # CentOS
rm -f /etc/init.d/rcloned
```
