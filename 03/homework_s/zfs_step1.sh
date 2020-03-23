#!/bin/sh
v_tmp=`sudo yum -y install mc 2>/dev/null`
#ini
WHITE='\033[1;97;40m'
RED='\033[1;91;40m'
YELLOW='\033[1;93;40m'
GREEN='\033[1;92;40m'
NORMAL='\033[0m'
#start
label="${WHITE}║        ZFX STEP 1           ║${NORMAL}"
echo -e "${WHITE}╔═════════════════════════════╗${NORMAL}\n${WHITE}$label${NORMAL}\n${WHITE}╚═════════════════════════════╝${NORMAL}"
lsblk
echo -e "${WHITE}════════ Install ZFS${NORMAL}"
v_tmp=`sudo yum -y install http://download.zfsonlinux.org/epel/zfs-release.el7_5.noarch.rpm`
echo -e "zfs      ${YELLOW}disabled${NORMAL} repo"
echo -e "zfs-kmod ${GREEN}enabled${NORMAL}  repo"

sudo python -c "import ConfigParser;
config = ConfigParser.RawConfigParser();
config.read('/etc/yum.repos.d/zfs.repo');
config.set('zfs', 'enabled', 0);
config.set('zfs-kmod', 'enabled', 1);
with open('/etc/yum.repos.d/zfs.repo', 'wb') as configfile: config.write(configfile)"
echo " Please wait for the installation ZFS-KMOD"	
sudo yum -y install zfs | grep -Poz '((?s)([=]{80}).+[=]{80}.(?-s)Install.+$)|(^Running transaction$)|(Installing.+$)'
echo -e "${WHITE}════════ Modules Test${NORMAL}"
sudo modprobe zfs
sudo lsmod | grep 'zfs'
echo -e "\n${WHITE}please run next sh file zfs_step2.sh${NORMAL}"