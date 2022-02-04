#!/bin/bash
#author kissyouhunter

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
      esac
	[[ $# -lt 2 ]] && echo -e "\e[36m\e[0m ${1}" || {
		echo -e "\e[36m\e[0m ${Color}${2}\e[0m"
	 }
      }
}
if [ "$(uname -m)" == "x86_64" ];then
	TIME g "starting to install exa"
	sleep 2
	TIME g "installing unzip"
	sudo apt update && sudo apt install -y unzip
	TIME g "downloading exa"
	EXA_VERSION=$(curl -s "https://api.github.com/repos/ogham/exa/releases/latest" | grep -Po '"tag_name": "v\K[0-9.]+')
	curl -Lo exa.zip "https://github.com/ogham/exa/releases/latest/download/exa-linux-x86_64-v${EXA_VERSION}.zip"
	TIME g "unzipping exa & installing exa"
	sudo unzip -q exa.zip bin/exa -d /usr
	TIME g "clearing..."
	rm -rf exa.zip
	TIME g "checking version"
	exa --version
	exit 0
else
	TIME r "exa is not support $(uname -m) host!"
	exit 0
fi
exit 0
