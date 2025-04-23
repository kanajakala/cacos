#!/bin/bash
#this script is used to install the mkbootimage utility

#colors
cyan="\e[36m"
green="\e[32m"
ENDCOLOR="\e[0m"

#we download the utility
echo -e "${cyan}Dowloading bootboot...\n\n${ENDCOLOR}"
git clone https://gitlab.com/bztsrc/bootboot.git .cache/bootboot

#we build the utility
echo -e "${cyan}Building mkbootimg...\n\n${ENDCOLOR}"
cd .cache/bootboot/mkbootimg
make

#clean up
echo -e "${cyan}Cleaning up...\n\n${ENDCOLOR}"
cp mkbootimg ../../
cd ../../
rm -rf bootboot

echo -e "${green}Done !\n\n${ENDCOLOR}"
