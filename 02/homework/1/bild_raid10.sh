#!/bin/sh
#ini
WHITE='\033[1;97;40m'
RED='\033[1;91;40m'
YELLOW='\033[1;93;40m'
GREEN='\033[1;92;40m'
NORMAL='\033[0m'
#start
label="${WHITE}║        BUILD RAID10         ║${NORMAL}"
echo -e "${WHITE}╔═════════════════════════════╗${NORMAL}\n${WHITE}$label${NORMAL}\n${WHITE}╚═════════════════════════════╝${NORMAL}"
#1
echo -e "${WHITE}======== Detect Mdadm  ========${NORMAL}"
v_tmp=`sudo yum list installed | grep -c 'mdadm' 2>/dev/null`
if [ $v_tmp = 0 ]; then echo -e "${YELLOW}[WARNING]${NORMAL} Mdadm не установлен\nУстановка Mdadm"; v_n=`sudo yum -y install mdadm 2>/dev/null`; wait; fi
v_tmp=`sudo yum list installed | grep -c 'mdadm' 2>/dev/null`
if [ $v_tmp = 0 ]; then echo -e "${RED}[ERROR]${NORMAL} Mdadm установить не удалось\nРабота завершена с ошибкой"; exit; else echo -e "Mdadm ${GREEN}установлен${NORMAL}"; fi
#2
echo -e "${WHITE}======== Search disks  ========${NORMAL}"
lsblk
v_list=$(lsblk --output NAME | grep -P '^sd.')
v_x=`lsblk | grep -P '/$'`
v_disks=""
for i in $v_list; do
    if ! [[ "$v_x" == *"$i"* ]]; then
      #echo "$i"
      v_disks="$v_disks /dev/$i"
    else
		v_disk_for_root=$i
    fi
done
echo -e "Detected disks $v_disks"
echo -e "Root "/" - $v_disk_for_root"
#exit
#3
echo -e "${WHITE}======= Creating RAID10 =======${NORMAL}"
v_tmp=`lsblk --output TYPE | grep -P 'raid' | wc -l`
if ! [ "$v_tmp" -eq 0  ]
then
    echo -e "${RED}[WARN]${NORMAL} RAID found, run stop"
    exit
else
	echo -e "RAID not found, crate RAID10"
fi
# /dev/sdb /dev/sdc /dev/sdd /dev/sde#
v_tmp=`yes y | sudo mdadm --create --verbose /dev/md0 --level=10 --raid-devices=4$v_disks 2>/dev/null`
cat /proc/mdstat | grep -v 'resync'
echo -e "${WHITE}===== Creating Partitions =====${NORMAL}"
v_tmp=`sudo parted -s --script /dev/md0 'print free' | grep 'Partition Table' 2>/dev/null`
echo "$v_tmp"
echo "Creating GPT"
v_tmp=`sudo parted -s --script /dev/md0 'mklabel gpt' 2>/dev/null`
#echo "$v_tmp"
v_tmp=`sudo parted -s --script /dev/md0 'print free' | grep 'Partition Table'  2>/dev/null`
echo "$v_tmp"

v_tmp=`sudo parted -s --script /dev/md0 'mkpart primary ext4 0 104' 2>/dev/null`
echo "$v_tmp"
v_tmp=`sudo parted -s --script /dev/md0 'mkpart primary ext4 104 208' 2>/dev/null`
echo "$v_tmp"
v_tmp=`sudo parted -s --script /dev/md0 'mkpart primary ext4 208 312' 2>/dev/null`
echo "$v_tmp"
v_tmp=`sudo parted -s --script /dev/md0 'mkpart primary ext4 312 416' 2>/dev/null`
echo "$v_tmp"
v_tmp=`sudo parted -s --script /dev/md0 'mkpart primary ext4 416 520' 2>/dev/null`
echo "$v_tmp"
v_tmp=`sudo parted -s --script /dev/md0 'print free' | grep -v 'Free Space' 2>/dev/null`
echo "$v_tmp"
echo -e "${WHITE}╔═════════════════════════════════════╗${NORMAL}"
v_tmp=`lsblk | grep -c 'raid10'`
if [ $v_tmp = 4 ]; then echo -e "${WHITE}║         RAID10 - created ${GREEN}successful${WHITE} ║${NORMAL}\n"; else echo -e "${WHITE}║            RAID10 - created ${RED}failed     ${WHITE}║${NORMAL}\n"; fi
v_tmp=`sudo parted -s --script /dev/md0 'print free' | grep -c 'gpt'`
if [ $v_tmp != 0 ]; then echo -e "${WHITE}║            GPT - created ${GREEN}successful${WHITE} ║${NORMAL}\n"; else echo -e "${WHITE}║            GPT - created ${RED}failed     ${WHITE}║${NORMAL}\n"; fi
v_tmp=`sudo parted -s --script /dev/md0 'print free' | grep -c 'primary'`
if [ $v_tmp = 5 ]; then echo -e "${WHITE}║ Five partition - created ${GREEN}successful${WHITE} ║${NORMAL}\n"; else echo -e "${WHITE}║ Five partition - created ${RED}failed     ${WHITE}║${NORMAL}\n"; fi
echo -e "${WHITE}╚═════════════════════════════════════╝${NORMAL}"

echo -e "\
${WHITE}╔=====================================╗${NORMAL}\n\
${WHITE}�         RAID10 - created ${GREEN}successful ${WHITE}�${NORMAL}\n\
${WHITE}�            GPT - created ${GREEN}successful ${WHITE}�${NORMAL}\n\
${WHITE}� Five partition - created ${GREEN}successful ${WHITE}�${NORMAL}\n\
${WHITE}L=====================================-${NORMAL}"
#lsblk