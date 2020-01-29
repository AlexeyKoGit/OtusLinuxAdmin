#!/bin/sh
#ini
WHITE='\033[1;97;40m'
RED='\033[1;91;40m'
YELLOW='\033[1;93;40m'
GREEN='\033[1;92;40m'
NORMAL='\033[0m'
#start
echo -e "${WHITE}╔═════════════════════════════╗${NORMAL}\n${WHITE}║ Vagrant provision commands  ║${NORMAL}\n${WHITE}╚═════════════════════════════╝${NORMAL}"
#sudo sudo setenforce 0
echo "Install Mdadm"
v_tmp=`sudo yum -y install mdadm mc 2>/dev/null`
echo "Copy partition table sda->sdb"
v_tmp=`sudo sfdisk -d /dev/sda | sfdisk /dev/sdb  2>/dev/null`
echo "Set fd  Linux raid autodetect /dev/sdb"
v_tmp=`(echo t; echo fd; echo w) | sudo fdisk /dev/sdb`
echo "Change partition identifier on 0xFD (Linux raid autodetect)"
yes y | sudo mdadm --create /dev/md0 --level=1 --raid-disk=2 missing /dev/sdb1
sleep 10
##v_tmp=`yes y | sudo mdadm --create /dev/md0 --level=1 --raid-devices= missing /dev/sdb1`
##--raid-devices=2 /dev/sdb1 missing.
##v_tmp=`yes y | sudo mdadm --create /dev/md0 --level=10 --raid-devices=4$v_disks 2>/dev/null`
echo "Format type FS xfs"
v_tmp=`sudo mkfs.xfs /dev/md0`
uuid_root_part=`lsblk --output UUID,MOUNTPOINT | grep -P ' /$' | grep -oP '^.{36}'`
uuid_raid_part=`lsblk --output UUID,TYPE | grep -P 'raid' | grep -oP '^.{36}'`
cmd_l=`grep -P 'GRUB_CMDLINE_LINUX' /etc/default/grub`
cmd_ln=`echo "$cmd_l" | sed 's/\(\"\\s*\)$/ rd.auto=1\"/'`
sudo sed -i 's/'"$cmd_l"'/'"$cmd_ln"'/g' /etc/default/grub
cat /etc/default/grub
#echo "$root $uuid_root_part"
#echo "$raid $uuid_raid_part"
#echo "$cmd_l"
#echo "$cmd_ln"

sudo mount /dev/md0 /mnt/
sudo cp -dpRxf --preserve=context / /mnt/

lsblk --output NAME,FSTYPE,MAJ:MIN,RM,SIZE,RO,TYPE,UUID,MOUNTPOINT

sudo mount --bind /proc /mnt/proc
sudo mount --bind /dev /mnt/dev
sudo mount --bind /sys /mnt/sys
sudo mount --bind /run /mnt/run
#sudo chroot /mnt/
echo -e "${WHITE}=========== chroot  ===========${NORMAL}"
cat << EOF | sudo chroot /mnt 
mdadm --detail --scan > /etc/mdadm.conf
sed -i 's|'"$uuid_root_part"'|'"$uuid_raid_part"'|g' /etc/fstab
mv /boot/initramfs-3.10.0-957.12.2.el7.x86_64.img /boot/initramfs-3.10.0-957.12.2.el7.x86_64.img.bak
dracut /boot/initramfs-$(uname -r).img $(uname -r)
sed -i 's/'"$cmd_l"'/'"$cmd_ln"'/g' /etc/default/grub
grub2-mkconfig -o /boot/grub2/grub.cfg
grub2-install /dev/sdb
EOF
echo "==RAID=="