#!/bin/sh
##sudo yum -y install mc
#ini
WHITE='\033[1;97;40m'
RED='\033[1;91;40m'
YELLOW='\033[1;93;40m'
GREEN='\033[1;92;40m'
NORMAL='\033[0m'
#start
label="${WHITE}║        LVM STEP 1           ║${NORMAL}"
echo -e "${WHITE}╔═════════════════════════════╗${NORMAL}\n${WHITE}$label${NORMAL}\n${WHITE}╚═════════════════════════════╝${NORMAL}"
lsblk
#get disks
echo -e "${WHITE}════════ Disks${NORMAL}"
disk_tmp_root=`lsblk | grep 10G | grep -oP '^sd.'`
echo "$disk_tmp_root for TMP Root"
disk_home=`lsblk | grep 2G | grep -oP '^sd.'`
echo "$disk_home for /home"
disk_var_t=( `lsblk | grep -P '1G' | grep -oP '^sd.'` )
for i in ${disk_var_t[@]}; do
disk_var_s="$disk_var_s$i "
done
echo "$disk_var_s for /var"
echo -e "${WHITE}════════ LVM Creating Physical Volumes${NORMAL}"
sudo pvcreate /dev/$disk_tmp_root
sudo pvcreate /dev/$disk_home
for i in ${disk_var_t[@]}; do
sudo pvcreate /dev/$i
done
echo -e "${WHITE}════════ LVM Creating Volume Groups${NORMAL}"
sudo vgcreate vg_tmp_root /dev/$disk_tmp_root
sudo vgcreate vg_home /dev/$disk_home
#for i in $disk_var_t; do
#sudo vgcreate vg_var /dev/$i
#done
sudo vgcreate vg_var /dev/${disk_var_t[0]}
sudo vgextend vg_var /dev/${disk_var_t[1]}
echo -e "${WHITE}════════ LVM Physical Volume and Group${NORMAL}"
sudo pvscan
echo -e "${WHITE}════════ LVM Creating Logical Volumes${NORMAL}"
sudo lvcreate -n lv_tmp_root -l +100%FREE /dev/vg_tmp_root
sudo lvcreate -n lv_home -l +50%FREE /dev/vg_home
#
sudo lvcreate -s -n s_shot_home -l +100%FREE /dev/vg_home/lv_home

#sudo lvcreate -L10G -s -n snaphot_test.local /dev/vmstore/test.local





