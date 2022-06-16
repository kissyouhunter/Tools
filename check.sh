#!/bin/bash

# check for whiptail

if [ "$(command -v whiptail)" ]; then
    bash
    bash <(curl -s -S -L https://raw.githubusercontent.com/kissyouhunter/Tools/main/menu.sh)
else
    bash
    bash <(curl -s -S -L https://raw.githubusercontent.com/kissyouhunter/Tools/main/kiss.sh)
fi

exit 0