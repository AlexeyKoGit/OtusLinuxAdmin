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
for (( i=1; i <= 15; i++ ))
do
cat > /home/vagrant/$i.html << EOF
$RANDOM
EOF
#$RANDOM > /home/vagrant/$i.txt
done

#sudo vgrename -v vg_tmp_root fs_lab
#sudo lvrename /dev/fs_lab/lv_tmp_root /dev/fs_lab/lv_zfs

#udo lvs
