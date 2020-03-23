### Занятие 03 «Файловые системы и LVM»
### Оглавление
[Задание (*)](#zadanie)  
[Инвентарь](#inv)  
[Порядок выполнения задания](#pvz)  
1\. [Устанавливаем необходимое ПО](#unpo)  
2\. [Шаги выполнения задания](#steps)  
&nbsp;&nbsp;&nbsp;&nbsp;[Step 1 Установим ZFS](#step1)  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[S1.1 ПО для ZFS](#s11)  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[S1.2 Результат](#s12)  
&nbsp;&nbsp;&nbsp;&nbsp;[Step 2 Создаем файловую систему](#step2)  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[S2.1 Добавляем диски в ZFS](#s21)  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[S2.2 Размещаем каталог /opt на ZFS разделе](#s22)  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[S2.3 Результат](#s23)  
&nbsp;&nbsp;&nbsp;&nbsp;[Step 3 Проверим работу snapshot.](#step3)  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[S3.1 Генерируем файлы](#s31)  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[S3.2 Snapshot, создаем и восстанавливаемся](#s32)  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[S3.3 Результат](#s33)  
&nbsp;&nbsp;&nbsp;&nbsp;[Step 4 Практическая проверка задания](#step4)

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
### <a name="step1"> Step 1 Установим ZFS
### <a name="s11"> S1.1 ПО для ZFS
Установим репозиторий с **ZFS**
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
Проверяем установленный **ZFS**.
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
### <a name="step2"> Step 2 Создаем файловую систему
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
### <a name="s22"> S2.2 Размещаем каталог /opt на ZFS файловой системе
Создадим файловую систему
```bash
$ sudo zfs create tank/opt_
```
Смотрим что получилось
```bash
zfs list
NAME        USED  AVAIL  REFER  MOUNTPOINT
tank        162K  9.63G  25.5K  /tank
tank/opt_    24K  9.63G    24K  /tank/opt_
```
Если при создании файловой системе не указывать точку монтирования, файловая система будет смонтирована по умолчанию **pool/filesystem**
```bash
$ zfs get mountpoint tank/opt_
NAME       PROPERTY    VALUE       SOURCE
tank/opt_  mountpoint  /tank/opt_  default
```
Зададим нужную нам точку монтирования **/opt**
```bash
$ sudo zfs set mountpoint=/opt tank/opt_
```
Смотрим что получилось, разными командами:  
**zfs list**
```bash
$ zfs list
NAME        USED  AVAIL  REFER  MOUNTPOINT
tank        134K  9.63G    24K  /tank
tank/opt_    24K  9.63G    24K  /opt
```
**zfs get mountpoint tank/opt_**
```bash
$ zfs get mountpoint tank/opt_
NAME       PROPERTY    VALUE       SOURCE
tank/opt_  mountpoint  /opt        local
```
**mount | grep '/opt'**
```bash
$ mount | grep '/opt'
tank/opt_ on /opt type zfs (rw,seclabel,xattr,noacl)

```
### <a name="s23"> S2.3 Результат
На базе диска **dsb** создан "**pool**" tank.  
Создана файловая система "**opt_**", смонтирована в каталог **/opt**.  
Диск **sdc** используется в качестве кэша.  
### <a name="step3"> Step 3 Проверим работу snapshot
### <a name="s31"> S3.1 Генерируем файлы
Создадим файлы в каталоге **/opt**
```bash
cd /opt
for (( i=1; i <= 15; i++ )); do sudo python -c "with open('"$i".txt', 'w') as file_: file_.write('"$RANDOM"\n')"; done
```
Смотрим что получилось
```bash
$ ll
total 15
-rw-r--r--. 1 root root 5 Mar 17 19:45 10.txt
-rw-r--r--. 1 root root 5 Mar 17 19:45 11.txt
-rw-r--r--. 1 root root 5 Mar 17 19:45 12.txt
-rw-r--r--. 1 root root 5 Mar 17 19:45 13.txt
-rw-r--r--. 1 root root 5 Mar 17 19:45 14.txt
-rw-r--r--. 1 root root 5 Mar 17 19:45 15.txt
-rw-r--r--. 1 root root 4 Mar 17 19:45 1.txt
-rw-r--r--. 1 root root 4 Mar 17 19:45 2.txt
-rw-r--r--. 1 root root 4 Mar 17 19:45 3.txt
-rw-r--r--. 1 root root 5 Mar 17 19:45 4.txt
-rw-r--r--. 1 root root 5 Mar 17 19:45 5.txt
-rw-r--r--. 1 root root 5 Mar 17 19:45 6.txt
-rw-r--r--. 1 root root 5 Mar 17 19:45 7.txt
-rw-r--r--. 1 root root 5 Mar 17 19:45 8.txt
-rw-r--r--. 1 root root 4 Mar 17 19:45 9.txt
```
### <a name="s32"> S3.2 Snapshot, создаем и восстанавливаемся
Создадим **snapshot**
```bash
$ sudo zfs snapshot -r tank/opt_@snp_1
```
Проверяем что получилось
```bash
$ zfs list -t snapshot
NAME              USED  AVAIL  REFER  MOUNTPOINT
tank/opt_@snp_1     0B      -    47K  -
```
Удаляем часть файлов
```bash
$ for (( i=5; i <= 10; i++ )); do sudo rm /opt/$i.txt; done
```
Результат
```bash
$ ll
total 9
-rw-r--r--. 1 root root 6 Mar 17 19:50 11.txt
-rw-r--r--. 1 root root 6 Mar 17 19:50 12.txt
-rw-r--r--. 1 root root 6 Mar 17 19:50 13.txt
-rw-r--r--. 1 root root 6 Mar 17 19:50 14.txt
-rw-r--r--. 1 root root 6 Mar 17 19:50 15.txt
-rw-r--r--. 1 root root 6 Mar 17 19:50 1.txt
-rw-r--r--. 1 root root 6 Mar 17 19:50 2.txt
-rw-r--r--. 1 root root 6 Mar 17 19:50 3.txt
-rw-r--r--. 1 root root 6 Mar 17 19:50 4.txt
```
Полученный **snapshot** при необходимости можно смонтировать
```bash
$ sudo mount -t zfs tank/opt_@snp_1 /mnt
```
```bash
$ ll /mnt/
total 15
-rw-r--r--. 1 root root 5 Mar 17 19:50 10.txt
-rw-r--r--. 1 root root 6 Mar 17 19:50 11.txt
-rw-r--r--. 1 root root 6 Mar 17 19:50 12.txt
-rw-r--r--. 1 root root 6 Mar 17 19:50 13.txt
-rw-r--r--. 1 root root 6 Mar 17 19:50 14.txt
-rw-r--r--. 1 root root 6 Mar 17 19:50 15.txt
-rw-r--r--. 1 root root 6 Mar 17 19:50 1.txt
-rw-r--r--. 1 root root 6 Mar 17 19:50 2.txt
-rw-r--r--. 1 root root 6 Mar 17 19:50 3.txt
-rw-r--r--. 1 root root 6 Mar 17 19:50 4.txt
-rw-r--r--. 1 root root 6 Mar 17 19:50 5.txt
-rw-r--r--. 1 root root 5 Mar 17 19:50 6.txt
-rw-r--r--. 1 root root 5 Mar 17 19:50 7.txt
-rw-r--r--. 1 root root 6 Mar 17 19:50 8.txt
-rw-r--r--. 1 root root 4 Mar 17 19:50 9.txt
```
Восстанавливаем данные с **snapshot**
```bash
$ sudo zfs rollback tank/opt_@snp_1
```
Проверяем
```bash
$ ll /opt/
total 15
-rw-r--r--. 1 root root 5 Mar 17 19:50 10.txt
-rw-r--r--. 1 root root 6 Mar 17 19:50 11.txt
-rw-r--r--. 1 root root 6 Mar 17 19:50 12.txt
-rw-r--r--. 1 root root 6 Mar 17 19:50 13.txt
-rw-r--r--. 1 root root 6 Mar 17 19:50 14.txt
-rw-r--r--. 1 root root 6 Mar 17 19:50 15.txt
-rw-r--r--. 1 root root 6 Mar 17 19:50 1.txt
-rw-r--r--. 1 root root 6 Mar 17 19:50 2.txt
-rw-r--r--. 1 root root 6 Mar 17 19:50 3.txt
-rw-r--r--. 1 root root 6 Mar 17 19:50 4.txt
-rw-r--r--. 1 root root 6 Mar 17 19:50 5.txt
-rw-r--r--. 1 root root 5 Mar 17 19:50 6.txt
-rw-r--r--. 1 root root 5 Mar 17 19:50 7.txt
-rw-r--r--. 1 root root 6 Mar 17 19:50 8.txt
-rw-r--r--. 1 root root 4 Mar 17 19:50 9.txt
```
### <a name="s33"> S3.3 Результат 
Проверили работу **snapshot**. Сгенерировали файлы, удалили часть и восстановились из созданного **snapshot**.
### <a name="step4"> Step 4 Практическая проверка задания
Для возможности практической проверки задания подготовлены файлы:  
**Vagrantfile** с дисками.  
Bash сценарий **zfs_step1.sh**, установка **ZFS**.  
Bash сценарий **zfs_step2.sh**, создаёт файловую систему **ZFS**.

