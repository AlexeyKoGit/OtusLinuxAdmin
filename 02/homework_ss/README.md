## Занятие 02 «Дисковая подсистема»
## Задание
** перенесети работающую систему с одним диском на RAID 1. Даунтайм на загрузку с нового диска предполагается. В качестве проверики принимается вывод команды lsblk до и после и описание хода решения (можно воспользовать утилитой Script).
Критерии оценки: - 4 принято - сдан Vagrantfile и скрипт для сборки, который можно запустить на поднятом образе  
\- 5 сделано доп задание
## Инвентарь

ПО:
- **VirtualBox** - среда виртуализации, позволяет создавать и выполнять виртуальные машины;
- **Vagrant** - ПО для создания и конфигурирования виртуальной среды. В данном случае в качестве среды виртуализации используется *VirtualBox*;
- **Git** - система контроля версий

Аккаунты:
- **GitHub** - https://github.com/

Материалы к заданию из личного кабинета:
- **Методичка_Дисковая подсистема RAID_Linux.pdf**

URLs:  
<https://github.com/erlong15/otus-linux>
 
## Порядок выполнения задания
#### 1. Устанавливаем необходимое ПО
* **GIT**
* **VirtualBox**
* **Vagrant**
#### 2. Перенос действующей системы на RAID1

Для задания со (**\***) **"** перенесети работающую систему с одним диском на **RAID 1****"**, необходимо добавить новый диск в **Vagrantfile**, его размер должен быть достаточным для размещения на него системы.  
Дополнительно добавим переменную для размещения диска вне директории с файлом **Vagrantfile**, так как будем использовать синхронизацию файлов в гостевую **ОС**.
```ruby
***
home = ENV['HOME'] # Используем глобальную переменную $HOME
***
      # disks
      :disks => {
        :sata1 => {
          :dfile => home + '/VirtualBox VMs/sata11.vdi',
          :size => 40960, # Megabytes
          :port => 1
          }
        }
***
config.vm.synced_folder ".", "/vagrant", disabled: false
***
```
#### 2 Переносим ОС
2.1 Установим **mdadm**  
```shell
$ sudo yum -y install mdadm
```
2.2 Смотрим начальную конфигурацию дисков командой **lsblk**
```shell
$ lsblk
NAME   MAJ:MIN RM SIZE RO TYPE MOUNTPOINT
sda      8:0    0  40G  0 disk
`-sda1   8:1    0  40G  0 part /
sdb      8:16   0  40G  0 disk
```

2.3. Для удобства перейдем под пользователя **root**  
```shell
$ sudo -u root -i
```
2.4. Копируем разметку на новый диск
```shell
# sfdisk -d /dev/sda | sfdisk /dev/sdb
Checking that no-one is using this disk right now ...
OK

Disk /dev/sdb: 5221 cylinders, 255 heads, 63 sectors/track
sfdisk:  /dev/sdb: unrecognized partition table type

Old situation:
sfdisk: No partitions found

New situation:
Units: sectors of 512 bytes, counting from 0

   Device Boot    Start       End   #sectors  Id  System
/dev/sdb1   *      2048  83886079   83884032  83  Linux
/dev/sdb2             0         -          0   0  Empty
/dev/sdb3             0         -          0   0  Empty
/dev/sdb4             0         -          0   0  Empty
Warning: partition 1 does not end at a cylinder boundary
Successfully wrote the new partition table

Re-reading the partition table ...

If you created or changed a DOS partition, /dev/foo7, say, then use dd(1)
to zero the first 512 bytes:  dd if=/dev/zero of=/dev/foo7 bs=512 count=1
(See fdisk(8).)
```
2.5. Изменим тип таблицы разделов на втором диске на **Linux raid autodetect**
```shell
# (echo t; echo fd; echo w) | fdisk /dev/sdb
Welcome to fdisk (util-linux 2.23.2).

Changes will remain in memory only, until you decide to write them.
Be careful before using the write command.


Command (m for help): Selected partition 1
Hex code (type L to list all codes): Changed type of partition 'Linux' to 'Linux raid autodetect'

Command (m for help): The partition table has been altered!

Calling ioctl() to re-read partition table.
Syncing disks.
```
2.6  Создадим **RAID1** с одним диском в режиме **degraded**
```shell
# yes y | mdadm --create /dev/md0 --level=1 --raid-disk=2 missing /dev/sdb1
mdadm: Note: this array has metadata at the start and
    may not be suitable as a boot device.  If you plan to
    store '/boot' on this device please ensure that
    your boot-loader understands md/v1.x metadata, or use
    --metadata=0.90
Continue creating array? mdadm: Defaulting to version 1.2 metadata
mdadm: array /dev/md0 started.
```
2.7. Форматируем **RAID** раздел
```shell
# mkfs.xfs /dev/md0
meta-data=/dev/md0               isize=512    agcount=4, agsize=2619264 blks
         =                       sectsz=512   attr=2, projid32bit=1
         =                       crc=1        finobt=0, sparse=0
data     =                       bsize=4096   blocks=10477056, imaxpct=25
         =                       sunit=0      swidth=0 blks
naming   =version 2              bsize=4096   ascii-ci=0 ftype=1
log      =internal log           bsize=4096   blocks=5115, version=2
         =                       sectsz=512   sunit=0 blks, lazy-count=1
realtime =none                   extsz=4096   blocks=0, rtextents=0
```
2.8. Монтируем **RAID** раздел  
```shell
# mount /dev/md0 /mnt/
```
2.9. Копируем файлы системы (*Обязательно нужно копировать с контекстом **SELinux***). Процедура занимает время.
```shell
cp -dpRxf --preserve=context / /mnt/
```
2.10. Монтируем системные каталоги и делаем **chroot**
```shell
[root@raid-1 ~]# mount --bind /proc /mnt/proc && mount --bind /dev /mnt/dev && mount --bind /sys /mnt/sys && mount --bind /run /mnt/run && chroot /mnt/
[root@raid-1 /]#
```
2.11. Заносим информацию о **RAID** массивах в файл конфигурации **mdadm** (*как понял в новых версиях не обязательно*)  
```shell
# mdadm --detail --scan > /etc/mdadm.conf
```
2.12. Правим **/etc/fstab**, меняем **UUID** раздела **sda1** корня, на **UUID** раздела **RAID** массива **md0**  
Чтобы посмотреть **UUID** можно использовать **lsblk** с нужным набором столбцов
```shell
# lsblk --output NAME,FSTYPE,MAJ:MIN,RM,SIZE,RO,TYPE,UUID,MOUNTPOINT
NAME    FSTYPE            MAJ:MIN RM SIZE RO TYPE  UUID                                 MOUNTPOINT
sda                         8:0    0  40G  0 disk
`-sda1  xfs                 8:1    0  40G  0 part  8ac075e3-1124-4bb6-bef7-a6811bf8b870
sdb                         8:16   0  40G  0 disk
`-sdb1  linux_raid_member   8:17   0  40G  0 part  87322e43-5a02-1f34-dc9e-755f0ba5bdd5
  `-md0 xfs                 9:0    0  40G  0 raid1 8d710930-e0fc-4dea-b94e-d5fddcf389ef /
```
2.13. Получаем **/etc/fstab** такой
```shell
#
# /etc/fstab
# Created by anaconda on Sat Jun  1 17:13:31 2019
#
# Accessible filesystems, by reference, are maintained under '/dev/disk'
# See man pages fstab(5), findfs(8), mount(8) and/or blkid(8) for more info
#
UUID=8d710930-e0fc-4dea-b94e-d5fddcf389ef /                       xfs     defaults        0 0
/swapfile none swap defaults 0 0
```
2.14. Делаем бэкап **initramfs** *(не обязательно)*
```shell
# mv /boot/initramfs-3.10.0-957.12.2.el7.x86_64.img /boot/initramfs-3.10.0-957.12.2.el7.x86_64.img.bak
```
2.15. Делаем новый **initramfs**. Процедура занимает время
```shell
# dracut /boot/initramfs-$(uname -r).img $(uname -r)
/sbin/dracut: line 679: warning: setlocale: LC_MESSAGES: cannot change locale (ru_RU.UTF-8): No such file or directory
/sbin/dracut: line 680: warning: setlocale: LC_CTYPE: cannot change locale (ru_RU.UTF-8): No such file or directory
```
2.16. Передаем ядру опцию **«rd.auto=1»** через **«GRUB»**, для этого, добавляем ее в **«GRUB_CMDLINE_LINUX»:** в файл **/etc/default/grub**
```shell
GRUB_TIMEOUT=1
GRUB_DISTRIBUTOR="$(sed 's, release .*$,,g' /etc/system-release)"
GRUB_DEFAULT=saved
GRUB_DISABLE_SUBMENU=true
GRUB_TERMINAL_OUTPUT="console"
GRUB_CMDLINE_LINUX="no_timer_check console=tty0 console=ttyS0,115200n8 net.ifnames=0 biosdevname=0 elevator=noop crashkernel=auto rd.auto=1"
GRUB_DISABLE_RECOVERY="true"
```
2.17. Перепишем конфиг **«GRUB»** и установим его на наш диск **sdb**
```shell
# grub2-mkconfig -o /boot/grub2/grub.cfg && grub2-install /dev/sdb
Generating grub configuration file ...
/usr/sbin/grub2-probe: warning: Couldn't find physical volume `(null)'. Some modules may be missing from core image..
Found linux image: /boot/vmlinuz-3.10.0-957.12.2.el7.x86_64
Found initrd image: /boot/initramfs-3.10.0-957.12.2.el7.x86_64.img
/usr/sbin/grub2-probe: warning: Couldn't find physical volume `(null)'. Some modules may be missing from core image..
/usr/sbin/grub2-probe: warning: Couldn't find physical volume `(null)'. Some modules may be missing from core image..
/usr/sbin/grub2-probe: warning: Couldn't find physical volume `(null)'. Some modules may be missing from core image..
/usr/sbin/grub2-probe: warning: Couldn't find physical volume `(null)'. Some modules may be missing from core image..
done
Installing for i386-pc platform.
grub2-install: warning: Couldn't find physical volume `(null)'. Some modules may be missing from core image..
grub2-install: warning: Couldn't find physical volume `(null)'. Some modules may be missing from core image..
Installation finished. No error reported.
```
2.18. Убеждаемся, что **UUID md0** и опция **«rd.auto=1»** точно записались
```shell
# cat /boot/grub2/grub.cfg
```
<details>
  <summary>FYI</summary>
```shell
# test
```
</details>
