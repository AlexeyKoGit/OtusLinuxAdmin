#!/bin/sh
#ini
WHITE='\033[1;97;40m'
RED='\033[1;91;40m'
YELLOW='\033[1;93;40m'
GREEN='\033[1;92;40m'
NORMAL='\033[0m'
#start
label="${WHITE}║        LVM STEP 2           ║${NORMAL}"
echo -e "${WHITE}╔═════════════════════════════╗${NORMAL}\n${WHITE}$label${NORMAL}\n${WHITE}╚═════════════════════════════╝${NORMAL}"
sudo lvs
echo -e "${WHITE}════════ Removing Volume${NORMAL}"
yes y | sudo lvremove /dev/VolGroup00/LogVol00
echo -e "${WHITE}════════ Creating volume 8G${NORMAL}"
yes y | sudo lvcreate -n LogVol00 -L 8G /dev/VolGroup00
echo -e "${WHITE}════════ Creating filesystem${NORMAL}"
v_tmp=`sudo mkfs.xfs /dev/VolGroup00/LogVol00 2>/dev/null`
sudo blkid | grep -P '(xfs|ext4)' | grep 'LogVol00'
echo -e "${WHITE}════════ Mount LVM Volumes${NORMAL}"
sudo mount /dev/VolGroup00/LogVol00/ /mnt/
sudo mount | grep 'VolGroup00-LogVol00'
echo -e "${WHITE}════════ Copying Data${NORMAL}"
echo "/ copy-> /mnt/"
sudo cp -dpRxf --preserve=context / /mnt/
echo -e "${WHITE}════════ Modify Fstab Config${NORMAL}"
root_uiid=`lsblk --output NAME,UUID | grep 'VolGroup00-LogVol00' | grep -oP '[-\w]+$'`
root_tmp_uiid=`lsblk --output NAME,UUID | grep 'vg_tmp_root-lv_tmp_root' | grep -oP '[-\w]+$'`
echo -e "root uiid 8G\t$root_uiid"
echo -e "root tmp uiid\t$root_tmp_uiid"
sudo sed -i 's|vg_tmp_root-lv_tmp_root|VolGroup00-LogVol00|g' /mnt/etc/fstab
cat /mnt/etc/fstab | grep -vP '^#'
echo -e "${WHITE}════════ Chroot${NORMAL}"
sudo mount --bind /proc /mnt/proc
sudo mount --bind /dev /mnt/dev
sudo mount --bind /sys /mnt/sys
sudo mount --bind /run /mnt/run
sudo mount --bind /boot /mnt/boot
sudo mount --bind /var /mnt/var
#
cat << EOF | sudo chroot /mnt
sed -i 's|vg_tmp_root/lv_tmp_root|VolGroup00/LogVol00|g' /etc/default/grub
grub2-mkconfig -o /boot/grub2/grub.cfg
EOF
echo -e "${WHITE}════════ After Rebooting The PC, Run /vagrant/lvm_step3.sh${NORMAL}"
echo "Reboot BOX"
sudo reboot
