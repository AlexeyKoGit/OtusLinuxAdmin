#!/bin/sh
#ini
WHITE='\033[1;97;40m'
RED='\033[1;91;40m'
YELLOW='\033[1;93;40m'
GREEN='\033[1;92;40m'
NORMAL='\033[0m'
#start
echo -e "${WHITE}╔═════════════════════════════╗${NORMAL}\n${WHITE}║        RAID1 Step 1         ║${NORMAL}\n${WHITE}╚═════════════════════════════╝${NORMAL}"
#sudo sudo setenforce 0
echo -e "${WHITE}========== lsblk Первый.${NORMAL}"
lsblk --output NAME,FSTYPE,MAJ:MIN,RM,SIZE,RO,TYPE,UUID,MOUNTPOINT
#1
echo -e "${WHITE}========== Detect Mdadm${NORMAL}"
v_tmp=`sudo yum list installed | grep -c 'mdadm' 2>/dev/null`
if [ $v_tmp = 0 ]; then echo -e "${YELLOW}[WARNING]${NORMAL} Mdadm не установлен\nУстановка Mdadm"; v_n=`sudo yum -y install mdadm 2>/dev/null`; wait; fi
v_tmp=`sudo yum list installed | grep -c 'mdadm' 2>/dev/null`
if [ $v_tmp = 0 ]; then echo -e "${RED}[ERROR]${NORMAL} Mdadm установить не удалось\nРабота завершена с ошибкой"; exit; else echo -e "Mdadm ${GREEN}установлен${NORMAL}"; fi
#2
echo -e "${WHITE}========== Copy partition table sda->sdb${NORMAL}"
sudo sfdisk -d /dev/sda | sudo sfdisk /dev/sdb
wait
echo -e "${WHITE}========== Change partition identifier on 0xFD (Linux raid autodetect) /dev/sdb${NORMAL}"
v_tmp=`(echo t; echo fd; echo w) | sudo fdisk /dev/sdb`
wait
echo -e "${WHITE}========== Creating RAID1${NORMAL}"
yes y | sudo mdadm --create /dev/md0 --level=1 --raid-disk=2 missing /dev/sdb1
wait
sleep 10
echo -e "${WHITE}========== Format type FS xfs${NORMAL}"
v_tmp=`sudo mkfs.xfs /dev/md0`
uuid_root_part=`lsblk --output UUID,MOUNTPOINT | grep -P ' /$' | grep -oP '^.{36}'`
uuid_raid_part=`lsblk --output UUID,TYPE | grep -P 'raid' | grep -oP '^.{36}'`
cmd_l=`grep -P 'GRUB_CMDLINE_LINUX' /etc/default/grub`
cmd_ln=`echo "$cmd_l" | sed 's/\(\"\\s*\)$/ rd.auto=1\"/'`
echo -e "${WHITE}========== /etc/default/grub rd.auto=1${NORMAL}"
sudo sed -i 's/'"$cmd_l"'/'"$cmd_ln"'/g' /etc/default/grub
cat /etc/default/grub
#echo "$root $uuid_root_part"
#echo "$raid $uuid_raid_part"
#echo "$cmd_l"
#echo "$cmd_ln"
echo -e "${WHITE}========== copy root(/)${NORMAL}"
sudo mount /dev/md0 /mnt/
sudo cp -dpRxf --preserve=context / /mnt/

#lsblk --output NAME,FSTYPE,MAJ:MIN,RM,SIZE,RO,TYPE,UUID,MOUNTPOINT

sudo mount --bind /proc /mnt/proc
sudo mount --bind /dev /mnt/dev
sudo mount --bind /sys /mnt/sys
sudo mount --bind /run /mnt/run
#sudo chroot /mnt/
echo -e "${WHITE}========== chroot${NORMAL}"
cat << EOF | sudo chroot /mnt 
mdadm --detail --scan > /etc/mdadm.conf
sed -i 's|'"$uuid_root_part"'|'"$uuid_raid_part"'|g' /etc/fstab
mv /boot/initramfs-3.10.0-957.12.2.el7.x86_64.img /boot/initramfs-3.10.0-957.12.2.el7.x86_64.img.bak
dracut /boot/initramfs-$(uname -r).img $(uname -r)
sed -i 's/'"$cmd_l"'/'"$cmd_ln"'/g' /etc/default/grub
grub2-mkconfig -o /boot/grub2/grub.cfg
grub2-install /dev/sdb
grub2-install /dev/sda
EOF
#echo "==RAID=="
echo -e "${WHITE}========== lsblk${NORMAL}"
lsblk --output NAME,FSTYPE,MAJ:MIN,RM,SIZE,RO,TYPE,UUID,MOUNTPOINT
echo -e "${GREEN}Step 1 is complete. Reboot BOX and run script /vagrant/raid1_step2.sh${NORMAL}"
