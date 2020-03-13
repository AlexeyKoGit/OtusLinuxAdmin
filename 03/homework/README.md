## Занятие 03 «Файловые системы и LVM»
## Задание
Работа с LVM
на имеющемся образе
/dev/mapper/VolGroup00-LogVol00 38G 738M 37G 2% /

уменьшить том под / до 8G  
выделить том под /home  
выделить том под /var  
/var - сделать в mirror  
/home - сделать том для снэпшотов  
прописать монтирование в fstab  
попробовать с разными опциями и разными файловыми системами ( на выбор) 
\- сгенерить файлы в /home/   
\- снять снэпшот  
\- удалить часть файлов  
\- восстановится со снэпшота  
\- залоггировать работу можно с помощью утилиты script  
 
 ## Инвентарь

ПО:
- **VirtualBox** - среда виртуализации, позволяет создавать и выполнять виртуальные машины;
- **Vagrant** - ПО для создания и конфигурирования виртуальной среды. В данном случае в качестве среды виртуализации используется *VirtualBox*;
- **Git** - система контроля версий

Аккаунты:
- **GitHub** - https://github.com/

Материалы к заданию из личного кабинета:

URLs:  
[LVM - начало работы](https://otus.ru/media-private/82/4b/%D0%9F%D1%80%D0%B0%D0%BA%D1%82%D0%B8%D0%BA%D0%B0_LVM-5373-824bd9.pdf?hash=YoHMj5YqhZivzj4yB6nZlw&expires=1583512014 "Методичка")  
[Vagrantfile с дисками](https://gitlab.com/otus_linux/stands-03-lvm "Vagrantfile")
 
## Порядок выполнения задания
#### 1. Устанавливаем необходимое ПО
* **GIT**
* **VirtualBox**
* **Vagrant  2.2.6**
#### 2. Создаем LVM разделы
##### 2.1 Cмотрим какие диски имеются в системе.
```bash
$ lsblk --output NAME,FSTYPE,MAJ:MIN,RM,SIZE,RO,TYPE,UUID,MOUNTPOINT
NAME                    FSTYPE      MAJ:MIN RM  SIZE RO TYPE UUID                                   MOUNTPOINT
sda                                   8:0    0   40G  0 disk
├─sda1                                8:1    0    1M  0 part
├─sda2                  xfs           8:2    0    1G  0 part 570897ca-e759-4c81-90cf-389da6eee4cc   /boot
└─sda3                  LVM2_member   8:3    0   39G  0 part vrrtbx-g480-HcJI-5wLn-4aOf-Olld-rC03AY
  ├─VolGroup00-LogVol00 xfs         253:0    0 37.5G  0 lvm  b60e9498-0baa-4d9f-90aa-069048217fee   /
  └─VolGroup00-LogVol01 swap        253:1    0  1.5G  0 lvm  c39c5bed-f37c-4263-bee8-aeb6a6659d7b   [SWAP]
sdb                                   8:16   0   10G  0 disk
sdc                                   8:32   0    2G  0 disk
sdd                                   8:48   0    1G  0 disk
sde                                   8:64   0    1G  0 disk
                       8:64   0    1G  0 disk
```
Видим что корневой каталог "**root**" "**/**" имеет файловую систему типа **xfs**, данная файловая система не позволят уменьшить размер до **8G**, как необходимо по условиям задания, для решения задания потребуется пересоздать раздел, а данные временно перенести на другой раздел. 
##### 2.2 Определяем необходимую структуру LVM
- диск **sdb**, **10G** - отведем под временный корневой каталог "**/**" (tmp_root)
- диск **scd**, **2G** - отведем под "**/home**" (snapshot)
- диски **sdd**, **sde** - отведем под "**/var**" (mirror)
##### 2.3 Создаем объекты LVM
Добавляем диски.
```bash
$ sudo pvcreate /dev/sd[bcde]
  Physical volume "/dev/sdb" successfully created.
  Physical volume "/dev/sdc" successfully created.
  Physical volume "/dev/sdd" successfully created.
  Physical volume "/dev/sde" successfully created.
```
Смотрим что получилось.
```bash
$ sudo pvs
  PV         VG         Fmt  Attr PSize   PFree
  /dev/sda3  VolGroup00 lvm2 a--  <38.97g     0
  /dev/sdb              lvm2 ---   10.00g 10.00g
  /dev/sdc              lvm2 ---    2.00g  2.00g
  /dev/sdd              lvm2 ---    1.00g  1.00g
  /dev/sde              lvm2 ---    1.00g  1.00g
```
Создаем группы LVM с Physical volume разделами.
```bash
$ sudo vgcreate vg_tmp_root /dev/sdb
  Volume group "vg_tmp_root" successfully created
$ sudo vgcreate vg_home /dev/sdc
  Volume group "vg_home" successfully created
$ sudo vgcreate vg_var /dev/sd[de]
  Volume group "vg_var" successfully created
```
Смотрим что получилось.
```bash
$ sudo vgs
  VG          #PV #LV #SN Attr   VSize   VFree
  VolGroup00    1   2   0 wz--n- <38.97g      0
  vg_home       1   0   0 wz--n-  <2.00g  <2.00g
  vg_tmp_root   1   0   0 wz--n- <10.00g <10.00g
  vg_var        2   0   0 wz--n-   1.99g   1.99g
$ sudo pvs
  PV         VG          Fmt  Attr PSize    PFree
  /dev/sda3  VolGroup00  lvm2 a--   <38.97g       0
  /dev/sdb   vg_tmp_root lvm2 a--   <10.00g  <10.00g
  /dev/sdc   vg_home     lvm2 a--    <2.00g   <2.00g
  /dev/sdd   vg_var      lvm2 a--  1020.00m 1020.00m
  /dev/sde   vg_var      lvm2 a--  1020.00m 1020.00m
```
Создаем LVM Logical Volumes.
Раздел для временного корневого каталога "**/**" (tmp_root).
```bash
$ sudo lvcreate -n lv_tmp_root -l +100%FREE /dev/vg_tmp_root
  Logical volume "lv_tmp_root" created.
```
Раздел для директории "**/home**" (snapshot), выделим **50%**, так-как остальные **50%** будем использовать под **snapshot**.
```bash
$ sudo lvcreate -n lv_home -l +50%FREE /dev/vg_home
  Logical volume "lv_home" created.
```
Попробуем создать **snapshot**.
```bash
$ sudo lvcreate -s -n s_shot_lv_home -l +100%FREE /dev/vg_home/lv_home
  Logical volume "s_shot_lv_home" created.
```
Раздел для "**/var**" (mirror)
```bash
$ sudo lvcreate -m1 -n mirror_lv_var -l +100%FREE /dev/vg_var
  Logical volume "mirror_lv_var" created.
```
Смотрим что получилось.
```bash
sudo lvs
  LV             VG          Attr       LSize    Pool Origin  Data%  Meta%  Move Log Cpy%Sync Convert
  LogVol00       VolGroup00  -wi-ao----  <37.47g
  LogVol01       VolGroup00  -wi-ao----    1.50g
  lv_home        vg_home     owi-a-s--- 1020.00m
  s_shot_lv_home vg_home     swi-a-s---    1.00g      lv_home 0.00
  lv_tmp_root    vg_tmp_root -wi-a-----  <10.00g
  mirror_lv_var  vg_var      rwi-a-r--- 1016.00m                                     100.00
```
Видим, что **snapshot** равен 100% диска с которого он снят а mirror 50% реального объема двух дисков, размеры имеют погрешность с учетом рабочих данных которые там хранит **LVM**.  
Мы добились нужной нам структуры **LVM**.  
##### 2.4 Создадим файловую систему на полученных разделах.
```bash
$ sudo mkfs.xfs /dev/vg_tmp_root/lv_tmp_root
meta-data=/dev/vg_tmp_root/lv_tmp_root isize=512    agcount=4, agsize=655104 blks
         =                       sectsz=512   attr=2, projid32bit=1
         =                       crc=1        finobt=0, sparse=0
data     =                       bsize=4096   blocks=2620416, imaxpct=25
         =                       sunit=0      swidth=0 blks
naming   =version 2              bsize=4096   ascii-ci=0 ftype=1
log      =internal log           bsize=4096   blocks=2560, version=2
         =                       sectsz=512   sunit=0 blks, lazy-count=1
realtime =none                   extsz=4096   blocks=0, rtextents=0


$ sudo mkfs.ext4 /dev/vg_home/lv_home
mke2fs 1.42.9 (28-Dec-2013)
Filesystem label=
OS type: Linux
Block size=4096 (log=2)
Fragment size=4096 (log=2)
Stride=0 blocks, Stripe width=0 blocks
65280 inodes, 261120 blocks
13056 blocks (5.00%) reserved for the super user
First data block=0
Maximum filesystem blocks=268435456
8 block groups
32768 blocks per group, 32768 fragments per group
8160 inodes per group
Superblock backups stored on blocks:
        32768, 98304, 163840, 229376

Allocating group tables: done
Writing inode tables: done
Creating journal (4096 blocks): done
Writing superblocks and filesystem accounting information: done


$ sudo mkfs.ext4 /dev/vg_home/s_shot_lv_home
mke2fs 1.42.9 (28-Dec-2013)
Filesystem label=
OS type: Linux
Block size=4096 (log=2)
Fragment size=4096 (log=2)
Stride=0 blocks, Stripe width=0 blocks
65280 inodes, 261120 blocks
13056 blocks (5.00%) reserved for the super user
First data block=0
Maximum filesystem blocks=268435456
8 block groups
32768 blocks per group, 32768 fragments per group
8160 inodes per group
Superblock backups stored on blocks:
        32768, 98304, 163840, 229376

Allocating group tables: done
Writing inode tables: done
Creating journal (4096 blocks): done
Writing superblocks and filesystem accounting information: done


$ sudo mkfs.ext4 /dev/vg_var/mirror_lv_var
mke2fs 1.42.9 (28-Dec-2013)
Filesystem label=
OS type: Linux
Block size=4096 (log=2)
Fragment size=4096 (log=2)
Stride=0 blocks, Stripe width=0 blocks
65024 inodes, 260096 blocks
13004 blocks (5.00%) reserved for the super user
First data block=0
Maximum filesystem blocks=266338304
8 block groups
32768 blocks per group, 32768 fragments per group
8128 inodes per group
Superblock backups stored on blocks:
        32768, 98304, 163840, 229376

Allocating group tables: done
Writing inode tables: done
Creating journal (4096 blocks): done
Writing superblocks and filesystem accounting information: done
```
Проверим что получилось.
```bash
$ sudo blkid | grep -P '(xfs|ext4)' | grep '/vg_'
/dev/mapper/vg_home-lv_home: UUID="2801146a-3b78-4976-bfda-a8c051d52cca" TYPE="ext4"
/dev/mapper/vg_home-s_shot_lv_home: UUID="6594e62c-6b20-4346-9d78-d09f594140a7" TYPE="ext4"
/dev/mapper/vg_tmp_root-lv_tmp_root: UUID="aff483ef-602c-421e-b063-1b0fb34e65fd" TYPE="xfs"
/dev/mapper/vg_var-mirror_lv_var_rimage_0: UUID="4658fba2-6740-41c6-89a3-636e77507abe" TYPE="ext4"
/dev/mapper/vg_var-mirror_lv_var_rimage_1: UUID="4658fba2-6740-41c6-89a3-636e77507abe" TYPE="ext4"
/dev/mapper/vg_var-mirror_lv_var: UUID="4658fba2-6740-41c6-89a3-636e77507abe" TYPE="ext4"
```
#### 3 Переносим данные на новые LVM разделы.
##### 3.1 Создаем директории для монтирования
```bash
$ sudo mkdir /mnt/v_tmp_root
$ sudo mkdir /mnt/v_home
$ sudo mkdir /mnt/v_var
$ ls -l /mnt/
total 0
drwxr-xr-x. 2 root root 6 Mar 10 23:53 v_home
drwxr-xr-x. 2 root root 6 Mar 10 23:53 v_tmp_root
drwxr-xr-x. 2 root root 6 Mar 10 23:53 v_var
```
##### 3.2 Монтируем разделы
```bash
$ sudo mount /dev/vg_tmp_root/lv_tmp_root/ /mnt/v_tmp_root
$ sudo mount /dev/vg_home/lv_home/ /mnt/v_home
$ sudo mount /dev/vg_var/mirror_lv_var/ /mnt/v_var
$ mount | grep '/vg_'
/dev/mapper/vg_tmp_root-lv_tmp_root on /mnt/v_tmp_root type xfs (rw,relatime,seclabel,attr2,inode64,noquota)
/dev/mapper/vg_home-lv_home on /mnt/v_home type ext4 (rw,relatime,seclabel,data=ordered)
/dev/mapper/vg_var-mirror_lv_var on /mnt/v_var type ext4 (rw,relatime,seclabel,data=ordered)
```
##### 3.3 Переносим данные
```bash
$ sudo cp -dpRxf --preserve=context / /mnt/v_tmp_root/
$ sudo rm -r /mnt/v_tmp_root/home/*
$ sudo rm -r /mnt/v_tmp_root/var/*
$ sudo cp -dpRxf --preserve=context /home/* /mnt/v_home/
$ sudo cp -dpRxf --preserve=context /var/* /mnt/v_var/
```
#### 4 Меняем корневой раздел загрузки и монтирование разделов.
##### 4.1 Вносим изменения в fstab
Изначальное состояние
```bash
]$ cat /mnt/v_tmp_root/etc/fstab

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
```





