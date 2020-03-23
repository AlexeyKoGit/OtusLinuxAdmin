#!/bin/sh
#ini
WHITE='\033[1;97;40m'
RED='\033[1;91;40m'
YELLOW='\033[1;93;40m'
GREEN='\033[1;92;40m'
NORMAL='\033[0m'
#start
label="${WHITE}║        ZFS STEP 2           ║${NORMAL}"
echo -e "${WHITE}╔═════════════════════════════╗${NORMAL}\n${WHITE}$label${NORMAL}\n${WHITE}╚═════════════════════════════╝${NORMAL}"
sudo lsblk
echo -e "${WHITE}════════ Creating ZFS pool${NORMAL}"
echo -e "create ZFS pool 'tank' (sdb)"
sudo zpool create tank sdb
echo -e "create ZFS cache (sdc)"
sudo zpool add -f tank cache sdc
echo -e ""
zpool status
echo -e "create ZFS /opt"
sudo zfs create -o mountpoint=/opt tank/opt_
echo -e ""
zfs list -r tank
echo -e "\n${WHITE}please run next sh file zfs_step3.sh${NORMAL}"
