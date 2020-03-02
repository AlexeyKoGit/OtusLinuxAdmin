#!/bin/sh
v_tmp=`sudo yum -y install mc 2>/dev/null`
#ini
WHITE='\033[1;97;40m'
RED='\033[1;91;40m'
YELLOW='\033[1;93;40m'
GREEN='\033[1;92;40m'
NORMAL='\033[0m'
#start
label="${WHITE}║        LVM STEP 1           ║${NORMAL}"
echo -e "${WHITE}╔═════════════════════════════╗${NORMAL}\n${WHITE}$label${NORMAL}\n${WHITE}╚═════════════════════════════╝${NORMAL}"
lsblk
sudo yum -y install http://download.zfsonlinux.org/epel/zfs-release.el7_5.noarch.rpm
sudo yum -y upgrade
sudo python -c "import ConfigParser;
config = ConfigParser.RawConfigParser();
config.read('/etc/yum.repos.d/zfs.repo');
config.set('zfs', 'enabled', 0);
config.set('zfs-kmod', 'enabled', 1);
with open('/etc/yum.repos.d/zfs.repo', 'wb') as configfile: config.write(configfile)"

sudo yum -y install zfs

#sudo python -c "import ConfigParser;config = ConfigParser.RawConfigParser();config.read('/etc/yum.repos.d/zfs.repo');print(config.sections())" 
#sudo yum -y install epel-release
#sudo yum -y localinstall http://download.zfsonlinux.org/epel/zfs-release.el7_7.noarch.rpm
#sudo yum -y install --skip-broken zfs


#sudo yum -y install zfs


	
#sudo python - << EOF
#import ConfigParser
#config = ConfigParser.RawConfigParser()
#config.read('/etc/yum.repos.d/zfs.repo')
#config.set('zfs', 'enabled', 0)
#config.set('zfs-kmod', 'enabled', 1)
#with open('example.cfg', 'wb') as configfile:
#	config.write('/etc/yum.repos.d/zfs.repo')
#EOF
#