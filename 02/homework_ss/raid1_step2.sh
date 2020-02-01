#!/bin/sh
#ini
WHITE='\033[1;97;40m'
RED='\033[1;91;40m'
YELLOW='\033[1;93;40m'
GREEN='\033[1;92;40m'
NORMAL='\033[0m'
#start
echo -e "${WHITE}╔═════════════════════════════╗${NORMAL}\n${WHITE}║        RAID1 Step 2         ║${NORMAL}\n${WHITE}╚═════════════════════════════╝${NORMAL}"
echo -e "${WHITE}========== Change partition identifier on 0xFD (Linux raid autodetect) /dev/sda${NORMAL}"
(echo t; echo fd; echo w) | sudo fdisk /dev/sda
echo -e "${WHITE}========== Add disk to RAID1${NORMAL}"
sudo sudo mdadm /dev/md0 --add /dev/sda1
sudo watch cat /proc/mdstat
echo -e "${WHITE}========== lsblk Финальный${NORMAL}"
lsblk --output NAME,FSTYPE,MAJ:MIN,RM,SIZE,RO,TYPE,UUID,MOUNTPOINT
echo -e "${GREEN}========== OS move to RAID1 complete${NORMAL}"