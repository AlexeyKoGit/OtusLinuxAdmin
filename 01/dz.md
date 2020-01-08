## Занятие 01 «С чего начинается Linux»
## Задание
Домашнее задание
Обновить ядро в базовой системе.
Цель: Студент получит навыки работы с Git, Vagrant, Packer и публикацией готовых образов в Vagrant Cloud.
В материалах к занятию есть методичка, в которой описана процедура обновления ядра из репозитория. По данной методичке требуется выполнить необходимые действия. Полученный в ходе выполнения ДЗ Vagrantfile должен быть залит в ваш репозиторий. Для проверки ДЗ необходимо прислать ссылку на него.
Для выполнения ДЗ со * и ** вам потребуется сборка ядра и модулей из исходников.
Критерии оценки: Основное ДЗ - в репозитории есть рабочий Vagrantfile с вашим образом.
ДЗ со звездочкой: Ядро собрано из исходников
ДЗ с **: В вашем образе нормально работают VirtualBox Shared Folders
## Инвентарь

ПО:
- **VirtualBox** - среда виртуализации, позволяет создавать и выполнять виртуальные машины;
- **Vagrant** - ПО для создания и конфигурирования виртуальной среды. В данном случае в качестве среды виртуализации используется *VirtualBox*;
- **Packer** - ПО для создания образов виртуальных машин;
- **Git** - система контроля версий

Аккаунты:
- **GitHub** - https://github.com/
- **Vagrant Cloud** - https://app.vagrantup.com

URLs:
- **Методическое руководство по процедуре обновления ядра** - https://github.com/dmitry-lyutenko/manual_kernel_update/blob/master/manual/manual.md
- **Исходные файлы для задания** - https://github.com/dmitry-lyutenko/manual_kernel_update
## Порядок выполнения задания
### Структурное представление стенда для выполнения задания.
```java
    Windows10 (hardware)
    {
      Oracle VM VirtualBox
            {
                Linux Mint 19.2 Tina
                {
                    Oracle VM VirtualBox|Vagrant
                    {
                        CentOS Linux (Целевая ОС для выполнения задания)
                    }
                }
            }
    }
```
#### 1. Создаем аккаунты
* **GIT** - https://github.com/
* **Vagrant Cloud** - https://app.vagrantup.com
#### 2. Устанавливаем необходимое ПО
* **GIT**
* **VirtualBox**
* **Vagrant**
* **Packer**
#### 3. Получаем необходимые исходные файлы для задания
Получаем необходимое виртуальное окружение с github, делаем **fork** следующего репозитория - https://github.com/dmitry-lyutenko/manual_kernel_update
Далее уже со своего репозитория клонируем данный проект (manual_kernel_update) локально на ПК.
#### 4. Поднимаем стендовый бокс
Переходим в директорию с vagrant файлом и выполняем запуск.

    $ vagrant up
После того как бокс успешно поднят, подключаемся к нему

    $ vagrant ssh
Проверяем текущее используемое ядро.

    $ uname -r
В результате выполнения команды у видим используемое ядро
**3.10.0.-957.12.2.el7.x86_64**
#### 5. Получаем новое ядро для установки в систему
Переходим в директорию kernels
```bash
$ cd /usr/src/kernels
```
Для задания со **"\*"**, скачиваем исходники будущего ядра.
Выбираем архив 5-го ядра на https://www.kernel.org/ 
ссылка для скачивания **stable:  5.4.2** https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.4.2.tar.xz
<details>
  <summary>FYI</summary>
Установка Wget
    
```bash
$ sudo yum install wget
```
</details>

```bash
$ sudo wget https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.4.2.tar.xz
```
Распаковываем архив с исходниками ядра

```bash
$ sudo tar -xvf ./linux-5.4.2.tar.xz -C /usr/src/kernels
```
#### 6. Собираем ядро
Копируем текущую конфигурацию ядра
```bash
$ sudo cp /boot/config* .config
```
Конфигурируем новые настройки, которые появились в новом ядре
<details>
  <summary>FYI</summary>
Понадобиться установить :
    
```bash
$ sudo yum install -y ncurses-devel make gcc bc bison flex elfutils-libelf-devel openssl-devel
```
</details>

```bash
$ sudo make oldconfig 
```
Собираем ядро, N - число потоков
```bash
$ sudo make -jN
```
Устанавливаем модули в **/boot/**
```bash
$ sudo make modules_install
```
Устанавливаем ядро в **/boot/**
```bash
$ sudo make install
```
Настраиваем загрузку нового ядра в Grub
```bash
$ sudo grub2-set-default 0
```
Перезапускаем vagrant box
```bash
$ vagrant reload
```
Подключаемся к vagrant box
```bash
$ vagrant ssh
```
Проверяем ядро
```bash
$ uname -r
```
Видим, что box запустился с новым ядром (5.4.2)
#### 6. Настраиваем VirtualBox Shared Folders
```bash
URLs
<https://superuser.com/questions/1421004/virtualbox-guest-additions-for-linux-guest-with-kernel-5-0-5>
```
Для настройки общей директории между гостевой и хост системой нужно на гостевой ОС установить VirtualBox дополнения.

```bash
$ sudo wget -c https://download.virtualbox.org/virtualbox/6.0.10/VBoxGuestAdditions_6.0.10.iso  -O /opt/VBoxGuestAdditions_6.0.10.iso
$ sudo mount -o loop /opt/VBoxGuestAdditions_6.0.10.iso /mnt/
```



## Ошибки
#### Для проверяющих, данный раздел прошу не брать во внимания, это шпаргалка для меня по возникшим трудностям.
### Включение вложенной виртуализации
### Добавление ключей для github

<https://www.cyberciti.biz/tips/compiling-linux-kernel-26.html>
