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

Запланируем следующую структуру:
- диск **sdb**, **10G** - отведем под временный "**/**" (**tmp_root**)
- диск **scd**, **2G** - отведем под "**/home**" (**snapshot**)
- диски **sdd**, **sde** - отведем под "**/var**" (**mirror**)
#### 3. Создаем объекты LVM
Добавляем диски.
```bash
$ sudo pvcreate /dev/sdb
  Physical volume "/dev/sdb" successfully created.
$ sudo pvcreate /dev/sdc
  Physical volume "/dev/sdc" successfully created.
$ sudo pvcreate /dev/sdd
  Physical volume "/dev/sdd" successfully created.
$ sudo pvcreate /dev/sde
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


