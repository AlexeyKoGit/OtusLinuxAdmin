### Занятие 03 «Файловые системы и LVM»
### Оглавление
[Задание (*)](#zadanie)  
[Инвентарь](#inv)  
[Порядок выполнения задания](#pvz)  
1\. [Устанавливаем необходимое ПО](#unpo)  
2\. [Шаги выполнения задания](#steps)  
&nbsp;&nbsp;&nbsp;&nbsp;[Step 1.](#step1)  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[S1.1 Установим ZFS](#s11)  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[S1.2 Результат](#s12)  
&nbsp;&nbsp;&nbsp;&nbsp;[Step 2.](#step2)  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[S2.1 Добавляем диски в ZFS](#s21)  
***  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[S2.2 Создаем файловую систему XFS](#s22)  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[S2.3 Переносим данные на созданный 8G раздел](#s23)  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[S2.4 Меняем fstab](#s24)  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[S2.5 Перезапишем GRUB](#s25)  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[S2.6 Выходим и перезагружаем BOX](#s26)  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[S2.7 Результат](#s27)  
&nbsp;&nbsp;&nbsp;&nbsp;[Step 3.](#step3)  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[S3.1 Генерируем файлы](#s31)  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[S3.2 Создаем snapshot](#s32)  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[S3.3 Восстанавливаем данные из snapshot-а](#s33)  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[S3.4 перезагружаем BOX](#s34)  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[S3.5 Результат](#s35)


### <a name="zadanie"></a> Задание (*)
\* на нашей куче дисков попробовать поставить btrfs/zfs - с кешем, снэпшотами - разметить здесь каталог /opt
### <a name="inv"></a> Инвентарь

ПО:
- **VirtualBox** - среда виртуализации, позволяет создавать и выполнять виртуальные машины;
- **Vagrant** - ПО для создания и конфигурирования виртуальной среды. В данном случае в качестве среды виртуализации используется *VirtualBox*;
- **Git** - система контроля версий

Аккаунты:
- **GitHub** - https://github.com/

Материалы к заданию из личного кабинета:

URLs:  
[Vagrantfile с дисками](https://gitlab.com/otus_linux/stands-03-lvm "Vagrantfile")
### <a name="pvz"></a> Порядок выполнения задания
### 1. <a name="unpo"></a> Устанавливаем необходимое ПО
* **GIT**
* **VirtualBox**
* **Vagrant  2.2.6**  

### 2. <a name="steps"> Шаги выполнения задания 
Разобьём выполнение задания на логические этапы – шаги (**steps**)
### <a name="step1"> Step 1.
### <a name="s11"> S1.1 Установим ZFS
Установим репозиторий с ZFS.
```bash
$ sudo yum -y install http://download.zfsonlinux.org/epel/zfs-release.el7_5.noarch.rpm
```
Правим файл репозитория /etc/yum.repos.d/zfs.repo  
Отключаем **[zfs]** и включаем **[zfs-kmod]**  
Меняем значение **enabled**  
Было:
```bash
$ cat /etc/yum.repos.d/zfs.repo
[zfs]
name=ZFS on Linux for EL7 - dkms
baseurl=http://download.zfsonlinux.org/epel/7.5/$basearch/
enabled=1
metadata_expire=7d
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-zfsonlinux

[zfs-kmod]
name=ZFS on Linux for EL7 - kmod
baseurl=http://download.zfsonlinux.org/epel/7.5/kmod/$basearch/
enabled=0
metadata_expire=7d
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-zfsonlinux
***
```
Должно стать:
```bash
$ cat /etc/yum.repos.d/zfs.repo
[zfs]
name = ZFS on Linux for EL7 - dkms
baseurl = http://download.zfsonlinux.org/epel/7.5/$basearch/
enabled = 0
metadata_expire = 7d
gpgcheck = 1
gpgkey = file:///etc/pki/rpm-gpg/RPM-GPG-KEY-zfsonlinux

[zfs-kmod]
name = ZFS on Linux for EL7 - kmod
baseurl = http://download.zfsonlinux.org/epel/7.5/kmod/$basearch/
enabled = 1
metadata_expire = 7d
gpgcheck = 1
gpgkey = file:///etc/pki/rpm-gpg/RPM-GPG-KEY-zfsonlinux
```
Устанавливаем **ZFS** установка занимает **продолжительное** время, так как в процессе установки будут собраны необходимые модули.
```bash
$ sudo yum -y install zfs
```
Проверяем установленный **ZFC**.
```bash
$ sudo yum list installed | grep zfs
kmod-spl.x86_64                 0.7.12-1.el7_5                  @zfs-kmod
kmod-zfs.x86_64                 0.7.12-1.el7_5                  @zfs-kmod
libnvpair1.x86_64               0.7.12-1.el7_5                  @zfs-kmod
libuutil1.x86_64                0.7.12-1.el7_5                  @zfs-kmod
libzfs2.x86_64                  0.7.12-1.el7_5                  @zfs-kmod
libzpool2.x86_64                0.7.12-1.el7_5                  @zfs-kmod
spl.x86_64                      0.7.12-1.el7_5                  @zfs-kmod
zfs.x86_64                      0.7.12-1.el7_5                  @zfs-kmod
zfs-release.noarch              1-5.el7.centos                  installed
```
Проверяем загруженные модули **ZFS**.
```bash
$ sudo lsmod | grep 'zfs'
$ sudo modprobe zfs
$ sudo lsmod | grep 'zfs'
zfs                  3564468  0
zunicode              331170  1 zfs
zavl                   15236  1 zfs
icp                   270148  1 zfs
zcommon                73440  1 zfs
znvpair                89131  2 zfs,zcommon
spl                   102412  4 icp,zfs,zcommon,znvpair
```
### <a name="s12"> S1.2 Результат
**ZFS** успешно установлен и модули успешно загружаются.
### <a name="step2"> Step 2.
### <a name="s21"> S2.1 Добавляем диски в ZFS
Определяем на каких дисках будем создавать файловую систему **ZFS**.
```bash
$ sudo lsblk
NAME                    MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda                       8:0    0   40G  0 disk
├─sda1                    8:1    0    1M  0 part
├─sda2                    8:2    0    1G  0 part /boot
└─sda3                    8:3    0   39G  0 part
  ├─VolGroup00-LogVol00 253:0    0 37.5G  0 lvm  /
  └─VolGroup00-LogVol01 253:1    0  1.5G  0 lvm  [SWAP]
sdb                       8:16   0   10G  0 disk
sdc                       8:32   0    2G  0 disk
sdd                       8:48   0    1G  0 disk
sde                       8:64   0    1G  0 disk
```
**sdb 10G** – основной **ZFS** диск.   
**sdc 2G** – выделим под **cache**.  
Создаем **ZFS Pool** на основе диска **sdb**
```bash
$ sudo zpool create tank sdb
$ zpool list
NAME   SIZE  ALLOC   FREE  EXPANDSZ   FRAG    CAP  DEDUP  HEALTH  ALTROOT
tank  9.94G   272K  9.94G         -     0%     0%  1.00x  ONLINE  -
```
Добавим в **ZFS pool** диск для **cache**.
```bash
$ sudo zpool add -f tank cache sdc
$ zpool status
  pool: tank
 state: ONLINE
  scan: none requested
config:

        NAME        STATE     READ WRITE CKSUM
        tank        ONLINE       0     0     0
          sdb       ONLINE       0     0     0
        cache
          sdc       ONLINE       0     0     0

errors: No known data errors

```










### <a name="s23"> S2.3 Переносим данные на созданный 8G раздел
Монтируем раздел
```bash
$ sudo mount /dev/VolGroup00/LogVol00/ /mnt/
```
Копируем данные
```bash
$ sudo cp -dpRxf --preserve=context / /mnt/
```
### <a name="s24"> S2.4 Меняем fstab
Изначальное состояние
```bash
$ sudo cat /mnt/etc/fstab

#
# /etc/fstab
# Created by anaconda on Sat May 12 18:50:26 2018
#
# Accessible filesystems, by reference, are maintained under '/dev/disk'
# See man pages fstab(5), findfs(8), mount(8) and/or blkid(8) for more info
#
/dev/mapper/vg_tmp_root-lv_tmp_root /                       xfs     defaults        0 0
UUID=570897ca-e759-4c81-90cf-389da6eee4cc /boot                   xfs     defaults        0 0
/dev/mapper/VolGroup00-LogVol01 swap                    swap    defaults        0 0
UUID=2801146a-3b78-4976-bfda-a8c051d52cca /home                   ext4     defaults        0 0
UUID=4658fba2-6740-41c6-89a3-636e77507abe /var                   ext4     defaults        0 0
```
Меняем **vg_tmp_root-lv_tmp_root** на **VolGroup00-LogVol00**  
Получиться должно следующее:
```bash
$ sudo cat /mnt/etc/fstab

#
# /etc/fstab
# Created by anaconda on Sat May 12 18:50:26 2018
#
# Accessible filesystems, by reference, are maintained under '/dev/disk'
# See man pages fstab(5), findfs(8), mount(8) and/or blkid(8) for more info
#
/dev/mapper/VolGroup00-LogVol00 /                       xfs     defaults        0 0
UUID=570897ca-e759-4c81-90cf-389da6eee4cc /boot                   xfs     defaults        0 0
/dev/mapper/VolGroup00-LogVol01 swap                    swap    defaults        0 0
UUID=2801146a-3b78-4976-bfda-a8c051d52cca /home                   ext4     defaults        0 0
UUID=4658fba2-6740-41c6-89a3-636e77507abe /var                   ext4     defaults        0 0
```
### <a name="s25"> S2.5 Перезапишем GRUB
Монтируем необходимое окружение
````bash
$ sudo mount --bind /proc /mnt/v_tmp_root/proc
$ sudo mount --bind /dev /mnt/v_tmp_root/dev
$ sudo mount --bind /sys /mnt/v_tmp_root/sys
$ sudo mount --bind /run /mnt/v_tmp_root/run
$ sudo mount --bind /boot /mnt/v_tmp_root/boot
$ sudo mount --bind /var /mnt/v_tmp_root/var
````
Делаем **chroot** и создаем конфигурацию **GRUB**
```bash
$ sudo chroot /mnt
```
Правим **/etc/default/grub**, меняем **vg_tmp_root/lv_tmp_root** на **VolGroup00/LogVol00**  
Должно получиться:
```bash
# cat /etc/default/grub
GRUB_TIMEOUT=1
GRUB_DISTRIBUTOR="$(sed 's, release .*$,,g' /etc/system-release)"
GRUB_DEFAULT=saved
GRUB_DISABLE_SUBMENU=true
GRUB_TERMINAL_OUTPUT="console"
GRUB_CMDLINE_LINUX="no_timer_check console=tty0 console=ttyS0,115200n8 net.ifnames=0 biosdevname=0 elevator=noop crashkernel=auto rd.lvm.lv=VolGroup00/LogVol00 rd.lvm.lv=VolGroup00/LogVol01 rhgb quiet"
GRUB_DISABLE_RECOVERY="true"
```
### <a name="s26"> S2.6 Выходим и перезагружаем BOX
Выходим из **chroot** и перезагружаем **box**
```bash
# exit
exit
$ sudo reboot
```
### <a name="s27"> S2.7 Результат
После перезагрузки можно убедится, что мы фактически уменьшили раздел **VolGroup00/LogVol00** до **8G**
```bash
$ lsblk
NAME                            MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda                               8:0    0   40G  0 disk
├─sda1                            8:1    0    1M  0 part
├─sda2                            8:2    0    1G  0 part /boot
└─sda3                            8:3    0   39G  0 part
  ├─VolGroup00-LogVol01         253:1    0  1.5G  0 lvm  [SWAP]
  └─VolGroup00-LogVol00         253:11   0    8G  0 lvm
sdb                               8:16   0   10G  0 disk
└─vg_tmp_root-lv_tmp_root       253:0    0   10G  0 lvm  /
sdc                               8:32   0    2G  0 disk
├─vg_home-lv_home-real          253:2    0 1020M  0 lvm
│ ├─vg_home-lv_home             253:3    0 1020M  0 lvm  /home
│ └─vg_home-s_shot_lv_home      253:5    0 1020M  0 lvm
└─vg_home-s_shot_lv_home-cow    253:4    0    1G  0 lvm
  └─vg_home-s_shot_lv_home      253:5    0 1020M  0 lvm
sdd                               8:48   0    1G  0 disk
├─vg_var-mirror_lv_var_rmeta_0  253:6    0    4M  0 lvm
│ └─vg_var-mirror_lv_var        253:10   0 1016M  0 lvm  /var
└─vg_var-mirror_lv_var_rimage_0 253:7    0 1016M  0 lvm
  └─vg_var-mirror_lv_var        253:10   0 1016M  0 lvm  /var
sde                               8:64   0    1G  0 disk
├─vg_var-mirror_lv_var_rmeta_1  253:8    0    4M  0 lvm
│ └─vg_var-mirror_lv_var        253:10   0 1016M  0 lvm  /var
└─vg_var-mirror_lv_var_rimage_1 253:9    0 1016M  0 lvm
  └─vg_var-mirror_lv_var        253:10   0 1016M  0 lvm  /var
```
### <a name="step3"> Step 3.
Проверяем работу **snapshot LVM**
### <a name="s31"> S3.1 Генерируем файлы
Генерируем файлы в /home/vagrant
```bash
cd /home/vagrant
for (( i=1; i <= 15; i++ )); do echo "$RANDOM" >> "$i".txt; done
```
Смотрим что получилось
```bash
$ ll
total 60
-rw-rw-r--. 1 vagrant vagrant  6 Mar 14 17:31 10.txt
-rw-rw-r--. 1 vagrant vagrant  6 Mar 14 17:31 11.txt
-rw-rw-r--. 1 vagrant vagrant  4 Mar 14 17:31 12.txt
-rw-rw-r--. 1 vagrant vagrant  5 Mar 14 17:31 13.txt
-rw-rw-r--. 1 vagrant vagrant  6 Mar 14 17:31 14.txt
-rw-rw-r--. 1 vagrant vagrant  5 Mar 14 17:31 15.txt
-rw-rw-r--. 1 vagrant vagrant 12 Mar 14 17:31 1.txt
-rw-rw-r--. 1 vagrant vagrant  6 Mar 14 17:31 2.txt
-rw-rw-r--. 1 vagrant vagrant  5 Mar 14 17:31 3.txt
-rw-rw-r--. 1 vagrant vagrant  6 Mar 14 17:31 4.txt
-rw-rw-r--. 1 vagrant vagrant  6 Mar 14 17:31 5.txt
-rw-rw-r--. 1 vagrant vagrant  5 Mar 14 17:31 6.txt
-rw-rw-r--. 1 vagrant vagrant  6 Mar 14 17:31 7.txt
-rw-rw-r--. 1 vagrant vagrant  6 Mar 14 17:31 8.txt
-rw-rw-r--. 1 vagrant vagrant  6 Mar 14 17:31 9.txt
```
### <a name="s32"> S3.2 Создаем snapshot
Удалим ранее созданный snapshot
```bash
]$ sudo lvremove /dev/mapper/vg_home-s_shot_lv_home
Do you really want to remove active logical volume vg_home/s_shot_lv_home? [y/n]: y
  Logical volume "s_shot_lv_home" successfully removed
```
Создадим новый
```bash
$ sudo lvcreate -s -n s_shot_lv_home -l +100%FREE /dev/vg_home/lv_home
  Logical volume "s_shot_lv_home" created.
```
Удалим часть файлов.
```bash
$ for (( i=5; i <= 10; i++ )); do rm /home/vagrant/"$i".txt; done
```
Смотрим что получилось.
```bash
$ ll
total 36
-rw-rw-r--. 1 vagrant vagrant  6 Mar 14 17:31 11.txt
-rw-rw-r--. 1 vagrant vagrant  4 Mar 14 17:31 12.txt
-rw-rw-r--. 1 vagrant vagrant  5 Mar 14 17:31 13.txt
-rw-rw-r--. 1 vagrant vagrant  6 Mar 14 17:31 14.txt
-rw-rw-r--. 1 vagrant vagrant  5 Mar 14 17:31 15.txt
-rw-rw-r--. 1 vagrant vagrant 12 Mar 14 17:31 1.txt
-rw-rw-r--. 1 vagrant vagrant  6 Mar 14 17:31 2.txt
-rw-rw-r--. 1 vagrant vagrant  5 Mar 14 17:31 3.txt
-rw-rw-r--. 1 vagrant vagrant  6 Mar 14 17:31 4.txt
```
### <a name="s33"> S3.3 Восстанавливаем данные из snapshot-а
```bash
$ sudo lvconvert --merge /dev/vg_home/s_shot_lv_home
  Delaying merge since origin is open.
  Merging of snapshot vg_home/s_shot_lv_home will occur on next activation of vg_home/lv_home.
```
### <a name="s34"> S3.4 перезагружаем BOX
Для вступления изменений в силу необходимо перезагрузить **box**
```bash
$ sudo reboot
```
### <a name="s35"> S3.5 Результат
Проверяем файлы.
```bash
$ cd /home/vagrant
$ ll
total 60
-rw-rw-r--. 1 vagrant vagrant  6 Mar 14 17:31 10.txt
-rw-rw-r--. 1 vagrant vagrant  6 Mar 14 17:31 11.txt
-rw-rw-r--. 1 vagrant vagrant  4 Mar 14 17:31 12.txt
-rw-rw-r--. 1 vagrant vagrant  5 Mar 14 17:31 13.txt
-rw-rw-r--. 1 vagrant vagrant  6 Mar 14 17:31 14.txt
-rw-rw-r--. 1 vagrant vagrant  5 Mar 14 17:31 15.txt
-rw-rw-r--. 1 vagrant vagrant 12 Mar 14 17:31 1.txt
-rw-rw-r--. 1 vagrant vagrant  6 Mar 14 17:31 2.txt
-rw-rw-r--. 1 vagrant vagrant  5 Mar 14 17:31 3.txt
-rw-rw-r--. 1 vagrant vagrant  6 Mar 14 17:31 4.txt
-rw-rw-r--. 1 vagrant vagrant  6 Mar 14 17:31 5.txt
-rw-rw-r--. 1 vagrant vagrant  5 Mar 14 17:31 6.txt
-rw-rw-r--. 1 vagrant vagrant  6 Mar 14 17:31 7.txt
-rw-rw-r--. 1 vagrant vagrant  6 Mar 14 17:31 8.txt
-rw-rw-r--. 1 vagrant vagrant  6 Mar 14 17:31 9.txt
```
Как видим файлы восстановились.
