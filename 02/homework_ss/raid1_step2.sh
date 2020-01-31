#!/bin/sh
#ini
WHITE='\033[1;97;40m'
RED='\033[1;91;40m'
YELLOW='\033[1;93;40m'
GREEN='\033[1;92;40m'
NORMAL='\033[0m'
#start
echo -e "${WHITE}╔═════════════════════════════╗${NORMAL}\n${WHITE}║        RAID1 Step 2         ║${NORMAL}\n${WHITE}╚═════════════════════════════╝${NORMAL}"
exit
(echo t; echo fd; echo w) | sudo fdisk /dev/sda
sudo mdadm —add /dev/md0 /dev/sda
sudo mdadm /dev/md0 --add /dev/sda1
sudo watch cat /proc/mdstat

