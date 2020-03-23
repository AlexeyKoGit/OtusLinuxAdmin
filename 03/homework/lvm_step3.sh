#!/bin/sh
#ini
WHITE='\033[1;97;40m'
RED='\033[1;91;40m'
YELLOW='\033[1;93;40m'
GREEN='\033[1;92;40m'
NORMAL='\033[0m'
#start
label="${WHITE}║        LVM STEP 3           ║${NORMAL}"
echo -e "${WHITE}╔═════════════════════════════╗${NORMAL}\n${WHITE}$label${NORMAL}\n${WHITE}╚═════════════════════════════╝${NORMAL}"
echo -e "${WHITE}════════ Generating Files In /home${NORMAL}"
rm -f /home/vagrant/*.txt
for (( i=1; i <= 15; i++ ))
do
echo "/home/vagrant/$i.txt gen"
cat > /home/vagrant/$i.txt << EOF
$RANDOM
EOF
done
echo -e "${WHITE}════════ Create Snapshot${NORMAL}"
yes y | sudo lvremove /dev/mapper/vg_home-s_shot_lv_home
sudo lvcreate -s -n s_shot_lv_home -l +100%FREE /dev/vg_home/lv_home
echo -e "${WHITE}════════ Deleting Part Of Files${NORMAL}"
echo -e "${WHITE}Before${NORMAL}"
ls -l /home/vagrant/
for (( i=1; i <= 10; i++ ))
do
rm /home/vagrant/$i.txt
done
echo -e "${WHITE}After${NORMAL}"
ls -l /home/vagrant/
#sudo sudo mount -o remount,rw /dev/vg_home/lv_home /home
#sudo vgrename -v vg_tmp_root fs_lab
#sudo lvrename /dev/fs_lab/lv_tmp_root /dev/fs_lab/lv_zfs
#lvconvert --merge /dev/vg_home/s_shot_lv_home
#sudo mount -o remount,rw /dev/vg_home/lv_home /home
#sudo lvs
echo -e "${WHITE}════════ Recovering Files From Snapshot${NORMAL}"
#echo "Before"
#ls -X /home/vagrant/
#echo "Recovering"
sudo lvconvert --merge /dev/vg_home/s_shot_lv_home
echo "Reboot BOX"
sudo reboot
