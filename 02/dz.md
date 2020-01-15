## Занятие 02 «Дисковая подсистема»
## Задание
Домашнее задание
работа с mdadm.  
добавить в Vagrantfile еще дисков  
сломать/починить raid  
собрать R0/R5/R10 на выбор  
прописать собранный рейд в конф, чтобы рейд собирался при загрузке  
создать GPT раздел и 5 партиций

в качестве проверки принимаются - измененный Vagrantfile, скрипт для создания рейда, конф для автосборки рейда при загрузке  
"*" доп. задание - Vagrantfile, который сразу собирает систему с подключенным рейдом  
"**" перенесети работающую систему с одним диском на RAID 1. Даунтайм на загрузку с нового диска предполагается. В качестве проверики принимается вывод команды lsblk до и после и описание хода решения (можно воспользовать утилитой Script).
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
#### 2. Конфигурируем vagrantfile
Согласно методичке **"Методичка_Дисковая подсистема RAID_Linux.pdf"**, сконфигурируем **vagrantfile** на основе примера из <https://github.com/erlong15/otus-linux>  
Для того чтобы изменить директорию расположения файлов-дисков (.vdi), пропишем переменную **home**, которая позволит сохранять диски не в директории с файлом **Vagrant**, это связано с параметром **synced_folder** из Вагрант файла, в случае использования которого, созданные диски (.vdi) могут быть проброшены на гостевую OS, что может привести к сбою в связи с переполнением диска гостевой OS.
```ruby
***
home = ENV['HOME'] 
***
```
Для добавления новых дисков в необходимом количестве пропишем в  **Vagrantfile** конфигурацию следующего типа:
```ruby
***
      # disks
        :sata1 => {
          :dfile => home + '/VirtualBox VMs/sata1.vdi',
          :size => 250,
          :port => 1
          },
        :sata2 => {
          :dfile => home + '/VirtualBox VMs/sata2.vdi',
          :size => 250, # Megabytes
          :port => 2
          },
        :sata3 => {
          :dfile => home + '/VirtualBox VMs/sata3.vdi',
          :size => 250,
          :port => 3
          },
        :sata4 => {
          :dfile => home + '/VirtualBox VMs/sata4.vdi',
          :size => 250, # Megabytes
          :port => 3
          }
        }
***
```
Полученной конфигурации достаточно для выполнения задания:  
- собрать R0/R5/R10 на выбор  
- сломать/починить raid  
#### 2. Создаем RAID
После того как сконфигурировали **Vagrantfile** с дополнительными **4-мя дисками**, поднимет **box** и заходим на него и проверяем диски командой **lsblk**.
```bash
$ lsblk
```
Вывод команды будет выглядеть следующим образом
```bash
NAME   MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda      8:0    0   40G  0 disk
`-sda1   8:1    0   40G  0 part /
sdb      8:16   0  250M  0 disk
sdc      8:32   0  250M  0 disk
sdd      8:48   0  250M  0 disk
sde      8:64   0  250M  0 disk
```
Видим, что по мимо раздела с OS, в системе появилось еще 4-ре дополнительных диска (**sdb,sdc,sdd,sde**).  
Создадим **RAID 10** используя утилиту **mdadm** для управления программными RAID-массивами в Linux
<details>
  <summary>FYI</summary>
Установка mdadm
    
```bash
$ sudo yum -y install mdadm
```
</details>

```bash
$ sudo mdadm --create --verbose /dev/md0 --level=10 --raid-devices=4 /dev/sdb /dev/sdc /dev/sdd /dev/sde

mdadm: layout defaults to n2
mdadm: layout defaults to n2
mdadm: chunk size defaults to 512K
mdadm: size set to 253952K
mdadm: Defaulting to version 1.2 metadata
mdadm: array /dev/md0 started.
```
Посмотреть информацию о RAID-ах можно несколькими способами.  
Кратко
```bash
$ cat /proc/mdstat

Personalities : [raid10]
md0 : active raid10 sdd[4] sde[3] sdc[1] sdb[0]
      507904 blocks super 1.2 512K chunks 2 near-copies [4/4] [UUUU]

unused devices: <none>
```
Подробо
```bash
$ $ sudo mdadm -D /dev/md0

/dev/md0:
           Version : 1.2
     Creation Time : Tue Jan 14 22:38:52 2020
        Raid Level : raid10
        Array Size : 507904 (496.00 MiB 520.09 MB)
     Used Dev Size : 253952 (248.00 MiB 260.05 MB)
      Raid Devices : 4
     Total Devices : 4
       Persistence : Superblock is persistent

       Update Time : Tue Jan 14 23:31:17 2020
             State : clean
    Active Devices : 4
   Working Devices : 4
    Failed Devices : 0
     Spare Devices : 0

            Layout : near=2
        Chunk Size : 512K

Consistency Policy : resync

              Name : auto-raid-10:0  (local to host auto-raid-10)
              UUID : 7e0c179d:abdd902b:24b2b3a3:48feb093
            Events : 39

    Number   Major   Minor   RaidDevice State
       0       8       16        0      active sync set-A   /dev/sdb
       1       8       32        1      active sync set-B   /dev/sdc
       4       8       48        2      active sync set-A   /dev/sdd
       3       8       64        3      active sync set-B   /dev/sde

```
#### 3. Ломаем/Чиним RAID
