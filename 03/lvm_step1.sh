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
sudo vgcreate vg_var /dev/${disk_var_t[0]} /dev/${disk_var_t[1]}
#sudo vgextend vg_var /dev/${disk_var_t[1]}
echo -e "${WHITE}════════ LVM Physical Volume and Group${NORMAL}"
sudo pvscan
echo -e "${WHITE}════════ LVM Creating Logical Volumes${NORMAL}"
sudo lvcreate -n lv_tmp_root -l +100%FREE /dev/vg_tmp_root
sudo lvcreate -n lv_home -l +50%FREE /dev/vg_home
# snap shot
sudo lvcreate -s -n s_shot_lv_home -l +100%FREE /dev/vg_home/lv_home
#sudo lvcreate -n lv_var -l +50%FREE /dev/vg_var
#sudo lvcreate -n lv_var -l 250 /dev/vg_var
# mirror
sudo lvcreate -m1 -n mirror_lv_var -l +100%FREE /dev/vg_var
#lvcreate -L 50G -m1 -n mirrorlv vg0
echo -e "${WHITE}════════ LVM Result${NORMAL}"
echo "/root"
sudo lvdisplay | grep -A15 '/lv_tmp_root' | grep -P '(/lv_tmp_root|LV Size)'
echo "/home"
sudo lvdisplay | grep -A15 '/lv_home' | grep -P '(/lv_home|LV Size)'
echo "/home (snapshot)"
sudo lvdisplay | grep -A15 '/s_shot_lv_home' | grep -P '(/s_shot_lv_home|LV Size|LV snapshot status.+active)'
echo "/var (mirror)"
sudo lvdisplay | grep -A15 '/mirror_lv_var' | grep -P '(/mirror_lv_var)'
sudo lvdisplay | grep -A15 '/mirror_lv_var' | grep -P '(Mirrored volumes)'
sudo lvdisplay | grep -A15 '/mirror_lv_var' | grep -P '(LV Size)'
echo -e "${WHITE}════════ Creating filesystem${NORMAL}"
v_tmp=`sudo mkfs.xfs /dev/vg_tmp_root/lv_tmp_root 2>/dev/null`
v_tmp=`sudo mkfs.ext4 /dev/vg_home/lv_home 2>/dev/null`
v_tmp=`sudo mkfs.ext4 /dev/vg_home/s_shot_lv_home 2>/dev/null`
v_tmp=`sudo mkfs.ext4 /dev/vg_var/mirror_lv_var 2>/dev/null`
blkid | grep -P '(xfs|ext4)' | grep '/vg_'
echo -e "${WHITE}════════ Creating Mount Points${NORMAL}"
sudo mkdir /mnt/v_tmp_root
sudo mkdir /mnt/v_home
sudo mkdir /mnt/v_var
ls -l /mnt/
echo -e "${WHITE}════════ Mount LVM Volumes${NORMAL}"
sudo mount /dev/vg_tmp_root/lv_tmp_root/ /mnt/v_tmp_root
sudo mount /dev/vg_home/lv_home/ /mnt/v_home
sudo mount /dev/vg_var/mirror_lv_var/ /mnt/v_var
mount | grep '/vg_'
echo -e "${WHITE}════════ Copying Data${NORMAL}"
sudo cp -dpRxf --preserve=context / /mnt/v_tmp_root/
sudo cp -dpRf --preserve=context /home /mnt/v_home/
sudo cp -dpRf --preserve=context /var /mnt/v_var/