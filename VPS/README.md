### DD VPS linux

```
#UBUNTU 20.04
bash <(wget --no-check-certificate -qO- 'https://ghproxy.com/https://raw.githubusercontent.com/kissyouhunter/Tools/main/VPS/InstallNET.sh') -u 20.04 -v 64 -p "password" -port "22" --mirror "http://mirrors.ustc.edu.cn/ubuntu/"
```

```
#DEBIAN 11
bash <(wget --no-check-certificate -qO- 'https://ghproxy.com/https://raw.githubusercontent.com/kissyouhunter/Tools/main/VPS/InstallNET.sh') -d 11 -v 64 -p "password" -port "22" --mirror "http://mirrors.ustc.edu.cn/debian/"
```
```
#DEBIAN 12
bash <(wget --no-check-certificate -qO- 'https://github.com/MoeClub/Note/raw/master/InstallNET.sh') -d 12 -v 64 -p pasword
```

```
#check ip
wget https://github.com/kissyouhunter/Tools/raw/main/VPS/checkip.sh
mv checkip.sh /etc/init.d/checkip && chmod +x /etc/init.d/checkip && update-rc.d -f checkip defaults && bash /etc/init.d/checkip
```

### DD Windows

```
#Windows 7
wget --no-check-certificate -qO InstallNET.sh 'https://github.com/MoeClub/Note/raw/master/InstallNET.sh' && bash InstallNET.sh -dd 'https://cloud.kisslove.eu.org/d/onedrive/ISO/guajibao-win7-sp1-ent-x64-cn.vhd.gz'
```

```
#Windows 10
wget --no-check-certificate -qO InstallNET.sh 'https://github.com/MoeClub/Note/raw/master/InstallNET.sh' && bash InstallNET.sh -dd 'https://cloud.kisslove.eu.org/d/onedrive/ISO/guajibao-win10-ent-ltsc-2021-x64-cn.vhd.gz'
```

```
#Windows 10 linode
wget -O- https://cloud.kisslove.eu.org/d/onedrive/ISO/guajibao-win10-ent-ltsc-2021-x64-cn.vhd.gz | gunzip | dd of=/dev/sda
```
### AZURE CLI

```
az group create \
    --name eastus-server \
    --location eastus
```

```
az vm create \
    --resource-group eastus-server \
    --name us-server \
    --location eastus \
    --image Debian:debian-12:12-gen2:latest \  ## MicrosoftWindowsServer:WindowsServer:2012-R2-Datacenter-smalldisk:latest
    --authentication-type password \
    --admin-username admin \
    --admin-password adminpassword \
    --size Standard_B1s \
    --os-disk-size-gb 64 \
    --public-ip-address-allocation Dynamic \
    --public-ip-sku Basic \
    --nsg "" \
    --availability-set "" \
    --security-type Standard
```

```
az account list-locations --output table
```

| DisplayName | Name | RegionalDisplayName |
|-|-|-|  
| East US | eastus | (US) East US |
| East US 2 | eastus2 | (US) East US 2 |
| South Central US | southcentralus | (US) South Central US |
| West US 2 | westus2 | (US) West US 2 |
| West US 3 | westus3 | (US) West US 3 |
| Australia East | australiaeast | (Asia Pacific) Australia East |
| Southeast Asia | southeastasia | (Asia Pacific) Southeast Asia |
| North Europe | northeurope | (Europe) North Europe |
| Sweden Central | swedencentral | (Europe) Sweden Central |
| UK South | uksouth | (Europe) UK South |
| West Europe | westeurope | (Europe) West Europe |
| Central US | centralus | (US) Central US |
| South Africa North | southafricanorth | (Africa) South Africa North |
| Central India | centralindia | (Asia Pacific) Central India |
| East Asia | eastasia | (Asia Pacific) East Asia |
| Japan East | japaneast | (Asia Pacific) Japan East |
| Korea Central | koreacentral | (Asia Pacific) Korea Central |
| Canada Central | canadacentral | (Canada) Canada Central |
| France Central | francecentral | (Europe) France Central |
| Germany West Central | germanywestcentral | (Europe) Germany West Central |
| Norway East | norwayeast | (Europe) Norway East |
| Poland Central | polandcentral | (Europe) Poland Central |
| Switzerland North | switzerlandnorth | (Europe) Switzerland North |
| UAE North | uaenorth | (Middle East) UAE North | 
| Brazil South | brazilsouth | (South America) Brazil South |
| Central US EUAP | centraluseuap | (US) Central US EUAP |
| Qatar Central | qatarcentral | (Middle East) Qatar Central |
| Central US (Stage) | centralusstage | (US) Central US (Stage) |
| East US (Stage) | eastusstage | (US) East US (Stage) |
| East US 2 (Stage) | eastus2stage | (US) East US 2 (Stage) |
| North Central US (Stage) | northcentralusstage | (US) North Central US (Stage) |
| South Central US (Stage) | southcentralusstage | (US) South Central US (Stage) |
| West US (Stage) | westusstage | (US) West US (Stage) |
| West US 2 (Stage) | westus2stage | (US) West US 2 (Stage) |
| Asia | asia | Asia |
| Asia Pacific | asiapacific | Asia Pacific |  
| Australia | australia | Australia |
| Brazil | brazil | Brazil |
| Canada | canada | Canada |
| Europe | europe | Europe |
| France | france | France |
| Germany | germany | Germany |
| Global | global | Global |
| India | india | India |
| Japan | japan | Japan |
| Korea | korea | Korea |
| Norway | norway | Norway |
| Singapore | singapore | Singapore |
| South Africa | southafrica | South Africa |
| Switzerland | switzerland | Switzerland |
| United Arab Emirates | uae | United Arab Emirates |
| United Kingdom | uk | United Kingdom |
| United States | unitedstates | United States |
| United States EUAP | unitedstateseuap | United States EUAP |
| East Asia (Stage) | eastasiastage | (Asia Pacific) East Asia (Stage) |
| Southeast Asia (Stage) | southeastasiastage | (Asia Pacific) Southeast Asia (Stage) |  
| Brazil US | brazilus | (South America) Brazil US |
| East US STG | eastusstg | (US) East US STG |
| North Central US | northcentralus | (US) North Central US |
| West US | westus | (US) West US |
| Jio India West | jioindiawest | (Asia Pacific) Jio India West |
| East US 2 EUAP | eastus2euap | (US) East US 2 EUAP |
| South Central US STG | southcentralusstg | (US) South Central US STG |
| West Central US | westcentralus | (US) West Central US |
| South Africa West | southafricawest | (Africa) South Africa West |
| Australia Central | australiacentral | (Asia Pacific) Australia Central |
| Australia Central 2 | australiacentral2 | (Asia Pacific) Australia Central 2 |  
| Australia Southeast | australiasoutheast | (Asia Pacific) Australia Southeast |
| Japan West | japanwest | (Asia Pacific) Japan West |
| Jio India Central | jioindiacentral | (Asia Pacific) Jio India Central |
| Korea South | koreasouth | (Asia Pacific) Korea South |
| South India | southindia | (Asia Pacific) South India |
| West India | westindia | (Asia Pacific) West India |
| Canada East | canadaeast | (Canada) Canada East |
| France South | francesouth | (Europe) France South |
| Germany North | germanynorth | (Europe) Germany North |
| Norway West | norwaywest | (Europe) Norway West |
| Switzerland West | switzerlandwest | (Europe) Switzerland West | 
| UK West | ukwest | (Europe) UK West |
| UAE Central | uaecentral | (Middle East) UAE Central |
| Brazil Southeast | brazilsoutheast | (South America) Brazil Southeast |
