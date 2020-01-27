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
Для того чтобы изменить директорию расположения файлов-дисков (.vdi), пропишем переменную **home**, которая позволит сохранять диски не в директории с файлом **Vagrant**, это связано с параметром **synced_folder** из Вагрант файла, в случае использования которого, созданные диски **(.vdi)** могут быть проброшены на гостевую **OS**, что может привести к сбою в связи с переполнением диска гостевой **OS**.
```ruby 
Vagrantfile
***
home = ENV['HOME'] 
***
```
Для добавления новых дисков в необходимом количестве пропишем в  **Vagrantfile** конфигурацию следующего вида:
```ruby
Vagrantfile
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
#### 3. Создаем RAID
После того как сконфигурировали **Vagrantfile** с дополнительными **4-мя дисками**, поднимет **box**, заходим на него и проверяем диски командой **lsblk**.
```bash
$ lsblk
```
Вывод команды будет выглядеть следующим образом:
```bash
NAME   MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda      8:0    0   40G  0 disk
`-sda1   8:1    0   40G  0 part /
sdb      8:16   0  250M  0 disk
sdc      8:32   0  250M  0 disk
sdd      8:48   0  250M  0 disk
sde      8:64   0  250M  0 disk
```
Видим, что по мимо раздела с **OS**, в системе появилось еще 4-ре дополнительных диска (**sdb,sdc,sdd,sde**).  
Создадим **RAID 10** используя утилиту **mdadm** для управления программными RAID-массивами в Linux.
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
Теперь диски выглядят так

```bash
$ lsblk
NAME   MAJ:MIN RM  SIZE RO TYPE   MOUNTPOINT
sda      8:0    0   40G  0 disk
`-sda1   8:1    0   40G  0 part   /
sdb      8:16   0  250M  0 disk
`-md0    9:0    0  496M  0 raid10
sdc      8:32   0  250M  0 disk
`-md0    9:0    0  496M  0 raid10
sdd      8:48   0  250M  0 disk
`-md0    9:0    0  496M  0 raid10
sde      8:64   0  250M  0 disk
`-md0    9:0    0  496M  0 raid10
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
$ sudo mdadm -D /dev/md0

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
#### 4. Ломаем/Чиним RAID
Для динамического отслеживания изменений, используем команду
```bash
$ watch cat /proc/mdstat
```
Используя мультиплексор сессий такой как tmux или подключившись параллельно по ssh выполним команду
```bash
$ sudo mdadm /dev/md0 --fail /dev/sdd

mdadm: set /dev/sdd faulty in /dev/md0
```
Этим мы вызовем искусственный отказ диска.  
Смотрим какие изменения произойдут в запущенной команде **watch cat**
```bash
$ watch cat /proc/mdstat

Personalities : [raid10]
md0 : active raid10 sdd[4](F) sde[3] sdc[1] sdb[0]
      507904 blocks super 1.2 512K chunks 2 near-copies [4/3] [UU_U]

unused devices: <none>
```
Видим, что:  
- диск **sdd** получил флаг **F**.
- **3** диска из **4**-х работают.
- на месте **U**-unit, теперь прочерк **_**  

Посмотрим подробную информацию
```bash
$ sudo mdadm -D /dev/md0

/dev/md0:
           Version : 1.2
     Creation Time : Tue Jan 14 22:38:52 2020
        Raid Level : raid10
        Array Size : 507904 (496.00 MiB 520.09 MB)
     Used Dev Size : 253952 (248.00 MiB 260.05 MB)
      Raid Devices : 4
     Total Devices : 4
       Persistence : Superblock is persistent

       Update Time : Wed Jan 15 01:06:15 2020
             State : clean, degraded
    Active Devices : 3
   Working Devices : 3
    Failed Devices : 1
     Spare Devices : 0

            Layout : near=2
        Chunk Size : 512K

Consistency Policy : resync

              Name : auto-raid-10:0  (local to host auto-raid-10)
              UUID : 7e0c179d:abdd902b:24b2b3a3:48feb093
            Events : 41

    Number   Major   Minor   RaidDevice State
       0       8       16        0      active sync set-A   /dev/sdb
       1       8       32        1      active sync set-B   /dev/sdc
       -       0        0        2      removed
       3       8       64        3      active sync set-B   /dev/sde

       4       8       48        -      faulty   /dev/sdd

```

Здесь также видим что диск **sdd** отсутствует в **RAID**-е помечен как **removed** и что он неисправен **faulty**  
Извлекаем данный диск **sdd** из **RAID** массива
```bash
$ sudo mdadm /dev/md0 --remove /dev/sdd

mdadm: hot removed /dev/sdd from /dev/md0
```
Снова смотрим какие изменения произойдут в запущенной команде **watch cat**
```bash
$ watch cat /proc/mdstat                                                                                      

Personalities : [raid10]
md0 : active raid10 sde[3] sdc[1] sdb[0]
      507904 blocks super 1.2 512K chunks 2 near-copies [4/3] [UU_U]

unused devices: <none>
```
Видим, что диск **sdd** отсутствует  
При выводе подробной информации диск sdd также отсутствует
```bash
$ sudo mdadm -D /dev/md0
/dev/md0:
           Version : 1.2
     Creation Time : Tue Jan 14 22:38:52 2020
        Raid Level : raid10
        Array Size : 507904 (496.00 MiB 520.09 MB)
     Used Dev Size : 253952 (248.00 MiB 260.05 MB)
      Raid Devices : 4
     Total Devices : 3
       Persistence : Superblock is persistent

       Update Time : Wed Jan 15 01:40:04 2020
             State : clean, degraded
    Active Devices : 3
   Working Devices : 3
    Failed Devices : 0
     Spare Devices : 0

            Layout : near=2
        Chunk Size : 512K

Consistency Policy : resync

              Name : auto-raid-10:0  (local to host auto-raid-10)
              UUID : 7e0c179d:abdd902b:24b2b3a3:48feb093
            Events : 42

    Number   Major   Minor   RaidDevice State
       0       8       16        0      active sync set-A   /dev/sdb
       1       8       32        1      active sync set-B   /dev/sdc
       -       0        0        2      removed
       3       8       64        3      active sync set-B   /dev/sde
```
Для восстановления **RAID** массива необходимо установить в массив новый рабочий диск, мы же установим ранее удаленный **sdd** и посмотрим, как соберется **RAID**.
```bash
$ sudo mdadm /dev/md0 --add /dev/sdd
mdadm: added /dev/sdd
```
Был виден процесс сборки массива 
```bash
watch cat /proc/mdstat 

Personalities : [raid10]
md0 : active raid10 sdd[4] sde[3] sdc[1] sdb[0]
      507904 blocks super 1.2 512K chunks 2 near-copies [4/3] [UU_U]
      [============>........]  recovery = 60.9% (155136/253952) finish=0.0min speed=155136K/sec

unused devices: <none>
```
Массив собран 
```bash
watch cat /proc/mdstat 

Personalities : [raid10]
md0 : active raid10 sdd[4] sde[3] sdc[1] sdb[0]
      507904 blocks super 1.2 512K chunks 2 near-copies [4/4] [UUUU]

unused devices: <none>

```
#### 5. Создадим GPT раздел и 5 партиций
У нового **RAID** тип разметки разделов еще не задан, это можно посмотреть:
```bash
$ sudo parted /dev/md0
GNU Parted 3.1
Using /dev/md0
Welcome to GNU Parted! Type 'help' to view a list of commands.
```
Вводим **p** или **print**

```bash
(parted) p
Error: /dev/md0: unrecognised disk label
Model: Linux Software RAID Array (md)
Disk /dev/md0: 520MB
Sector size (logical/physical): 512B/512B
Partition Table: unknown
Disk Flags:

Number  Start  End  Size  File system  Name  Flags
```
Видим **Partition Table: unknown **
Зададим разметку **GPT**
```bash
(parted) mklabel gpt
Warning: The existing disk label on /dev/md0 will be destroyed and all data on this disk will be lost. Do you want to continue?
Yes/No? Yes
```
Проверяем
```bash
(parted) p
Model: Linux Software RAID Array (md)
Disk /dev/md0: 520MB
Sector size (logical/physical): 512B/512B
Partition Table: gpt
Disk Flags:

Number  Start  End  Size  File system  Name  Flags
```
Видим **Partition Table: gpt**
```bash
(parted) print free
Model: Linux Software RAID Array (md)
Disk /dev/md0: 520MB
Sector size (logical/physical): 512B/512B
Partition Table: gpt
Disk Flags:

Number  Start   End    Size   File system  Name  Flags
        17.4kB  520MB  520MB  Free Space
```
Создадим **5** разделов типа **primary**, размером по **104Mb**
```bash
mkpart primary ext4 0 104
mkpart primary ext4 104 208
```
Утилита **parted** предложит выровнять раздел согласно используемому размеру сектора, соглашаемся **Yes**.  
Ввести данную команду потребуется **5** раз смещая начало и конец на **104Mb**.  
В результате получиться:
```bash
(parted) p free
Model: Linux Software RAID Array (md)
Disk /dev/md0: 520MB
Sector size (logical/physical): 512B/512B
Partition Table: gpt
Disk Flags:

Number  Start   End    Size    File system  Name     Flags
 1      17.4kB  104MB  104MB                primary
 2      104MB   208MB  104MB                primary
 3      208MB   311MB  104MB                primary
 4      311MB   415MB  104MB                primary
 5      415MB   519MB  104MB                primary
        519MB   520MB  1032kB  Free Space
```
Также новые разделы видно будет и командой **lsblk**
```bash
$ lsblk
NAME      MAJ:MIN RM  SIZE RO TYPE   MOUNTPOINT
sda         8:0    0   40G  0 disk
`-sda1      8:1    0   40G  0 part   /
sdb         8:16   0  250M  0 disk
`-md0       9:0    0  496M  0 raid10
  |-md0p1 259:0    0   99M  0 md
  |-md0p2 259:1    0   99M  0 md
  |-md0p3 259:2    0   99M  0 md
  |-md0p4 259:3    0   99M  0 md
  `-md0p5 259:4    0   99M  0 md
sdc         8:32   0  250M  0 disk
`-md0       9:0    0  496M  0 raid10
  |-md0p1 259:0    0   99M  0 md
  |-md0p2 259:1    0   99M  0 md
  |-md0p3 259:2    0   99M  0 md
  |-md0p4 259:3    0   99M  0 md
  `-md0p5 259:4    0   99M  0 md
sdd         8:48   0  250M  0 disk
`-md0       9:0    0  496M  0 raid10
  |-md0p1 259:0    0   99M  0 md
  |-md0p2 259:1    0   99M  0 md
  |-md0p3 259:2    0   99M  0 md
  |-md0p4 259:3    0   99M  0 md
  `-md0p5 259:4    0   99M  0 md
sde         8:64   0  250M  0 disk
`-md0       9:0    0  496M  0 raid10
  |-md0p1 259:0    0   99M  0 md
  |-md0p2 259:1    0   99M  0 md
  |-md0p3 259:2    0   99M  0 md
  |-md0p4 259:3    0   99M  0 md
  `-md0p5 259:4    0   99M  0 md
```
Как и требовалось в результате мы получили **5** разделов **primary** с использованием **GPT**
#### 6. Автоматическая сборка RAID
Для задания (**\*\***) автоматической сборки **RAID**,   массива необходимо
:
- внести изменения в **Vagrantfile**;  
- разрешить синхронизацию директории **хостовой** и **гостевой ОС**;  
- настроить **provision** секцию для выполнения команд на **гостевой ОС**.   Вынесем команды по созданию **RAID** в отдельный **bash файл**, который будет синхронизирован в **гостевую ОС**, а в секции **provision** пропишем только его запуск.

В **bash** скрипте определим следующие шаги:  
**#1** проверяем наличие **mdadm**, при необходимости устанавливаем;  
**#2** проверяем наличие **4-х** дисков для **RAID**;  
**#3** проверка ранее собранных **RAID** массивов, в случае наличия завершаем выполнение, иначе собираем диски в **RAID**;
**#4** 


