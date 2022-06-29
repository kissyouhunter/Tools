### 解锁emby：

* 打开脚本，右上角+号，填入下面URL，别名emby

```
https://raw.githubusercontent.com/kissyouhunter/Tools/main/loon/embyUnlocked.plugin
```
-------------------------------------------------------------------------------------
[TikTok-Unlock](https://github.com/Semporia/TikTok-Unlock/tree/master/Loon)

### <a id="TikTok"> TikTok </a>

* iOS系统版本：16.0 （支持向下兼容）
* TikTok版本：V24.9.1（需要从抓包的21.1.0升级方可使用）
* TikTok TestFlight V25.1.0（251009）

**特别说明**

1、为什么要先卸载TikTok，TikTok会在第一次使用时触发限制，并导致之后无法通过MiMt解密  
2、所以先配置好规则之后，然后在下载TikTok，减少重定向的请求次数，降低风险，延长规则的寿命  
3、为什么配置好之后还是无法使用，请检查软件的证书有没有安装，信任，  
4、或者是Https解密（MiMt）与重写（Rewrite）有没有开启  
5、或者是软件是不是盗版，比如用共享ID下载的，有设备限制，是无法使用重写脚本功能的  

### <a id="Loon"> Loon </a>


**操作步骤**

1、打开`Loon`  

2、点击`插件`在右上角找到`➕`进去在URL添加想看的对应国家链接,tag处自定义；PROXY 选择TikTok分流策略即可。

**日本**
```
https://raw.githubusercontent.com/Semporia/TikTok-Unlock/master/Loon/TikTok-JP.plugin
```

**台湾**
```
https://raw.githubusercontent.com/Semporia/TikTok-Unlock/master/Loon/TikTok-TW.plugin
```

**韩国**
```
https://raw.githubusercontent.com/Semporia/TikTok-Unlock/master/Loon/TikTok-KR.plugin
```

**美国**
```
https://raw.githubusercontent.com/Semporia/TikTok-Unlock/master/Loon/TikTok-US.plugin
```

3、在`[Remote Rule]`下面添加TikTok分流规则，示例如下：

```
https://raw.githubusercontent.com/Semporia/TikTok-Unlock/master/Loon/TikTok.list, tag=TikTok, policy=TikTok, update-interval=86400, enabled=true
```
