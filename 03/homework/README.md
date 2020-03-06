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
* **Vagrant**
#### 2. Определяем необходимую структуру LVM
Посмотрим какие диски имеются в системе.
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
Запланируем следующую структуру:
- диск **sdb**, **10G** - отведем под временный корневой каталог "**/**" (tmp_root)
- диск **scd**, **2G** - отведем под "**/home**" (snapshot)
- диски **sdd**, **sde** - отведем под "**/var**" (mirror)
#### 3. Создаем объекты LVM
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
Видим, что snapshot равен 100% диска с которого он снят а mirror 50% реального объема двух дисков, размеры имеют погрешность с учетом рабочих данных которые там хранит VLM.
Мы добились нужной нам структуры LVM.














