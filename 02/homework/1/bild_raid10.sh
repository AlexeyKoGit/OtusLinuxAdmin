#!/bin/sh
#ini
WHITE='\033[1;97;40m'
RED='\033[1;91;40m'
YELLOW='\033[1;93;40m'
GREEN='\033[1;92;40m'
NORMAL='\033[0m'
#start
echo -e "${WHITE}╔═════════════════════════════╗${NORMAL}\n${WHITE}║        BUILD RAID10         ║${NORMAL}\n${WHITE}╚═════════════════════════════╝${NORMAL}"
#1
echo -e "${WHITE}======= Detected Mdadm  =======${NORMAL}"
v_install=`sudo yum list installed | grep mdadm`
v_serch=`expr "$v_install" : '.*\(mdadm\)'`
if ! [ $v_serch  ]
then
    echo -e "${YELLOW}[WARNING]${NORMAL} Mdadm not installed!"
    echo "Install Mdadm"
    #date +"%T"
    v_res=`sudo yum -y install mdadm 2>/dev/null` 
    #date +"%T"
    wait
fi
v_install=`sudo yum list installed | grep mdadm`
unset v_serch
v_serch=`expr "$v_install" : '.*\(mdadm\)'`
if ! [ $v_serch  ]
then
    echo -e "${RED}[ERROR]${NORMAL} Mdadm not installed, run stop"
else
    echo -e "Mdadm installation completed!"
fi
#2
echo -e "${WHITE}======== Search disks  ========${NORMAL}"
lsblk
#v_count=`lsblk --output NAME | grep -P '^sd.' | wc -l`
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

echo -e "\
${WHITE}╔═════════════════════════════════════╗${NORMAL}\n\
${WHITE}║         RAID10 - created ${GREEN}successful ${WHITE}║${NORMAL}\n\
${WHITE}║            GPT - created ${GREEN}successful ${WHITE}║${NORMAL}\n\
${WHITE}║ Five partition - created ${GREEN}successful ${WHITE}║${NORMAL}\n\
${WHITE}╚═════════════════════════════════════╝${NORMAL}"
#lsblk
