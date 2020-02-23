#!/bin/sh
#ini
WHITE='\033[1;97;40m'
RED='\033[1;91;40m'
YELLOW='\033[1;93;40m'
GREEN='\033[1;92;40m'
NORMAL='\033[0m'
#start
label="${WHITE}║        LVM STEP 4           ║${NORMAL}"
echo -e "${WHITE}╔═════════════════════════════╗${NORMAL}\n${WHITE}$label${NORMAL}\n${WHITE}╚═════════════════════════════╝${NORMAL}"
echo -e "${WHITE}════════ Recovering Files From Snapshot${NORMAL}"
#echo "Before"
#ls -X /home/vagrant/
#echo "Recovering"
sudo lvconvert --merge /dev/vg_home/s_shot_lv_home
echo "Reboot BOX"
sudo reboot
