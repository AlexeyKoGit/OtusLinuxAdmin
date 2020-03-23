#!/bin/sh
#ini
WHITE='\033[1;97;40m'
RED='\033[1;91;40m'
YELLOW='\033[1;93;40m'
GREEN='\033[1;92;40m'
NORMAL='\033[0m'
#start
label="${WHITE}║        ZFS STEP 3           ║${NORMAL}"
echo -e "${WHITE}╔═════════════════════════════╗${NORMAL}\n${WHITE}$label${NORMAL}\n${WHITE}╚═════════════════════════════╝${NORMAL}"
echo -e "${WHITE}════════ Creating Files In /opt${NORMAL}"
for (( i=1; i <= 15; i++ )); do sudo python -c "with open('/opt/"$i".txt', 'w') as file_: file_.write('"$RANDOM"\n')"; done
cd /opt
pwd
ls -l /opt
echo -e "${WHITE}════════ Creating Snapshot${NORMAL}"
sudo zfs snapshot -r tank/opt_@snp_1
zfs list -t snapshot
echo -e "${WHITE}════════ Delete Part Of Files${NORMAL}"
for (( i=5; i <= 10; i++ )); do sudo rm /opt/$i.txt; done
ls -l /opt
echo -e "${WHITE}════════ Recover Files From Snapshot${NORMAL}"
sudo zfs rollback tank/opt_@snp_1
ls -l /opt