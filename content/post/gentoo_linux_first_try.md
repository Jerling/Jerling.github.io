+++
title = "Gentoo 系统初探"
author = ["Jerling"]
author_homepage = "https://github.com/Jerling"
date = 2018-12-22
lastmod = 2019-02-02T19:53:51+08:00
tags = ["linux", "gentoo", "funny"]
categories = ["操作系统"]
type = "post"
draft = false
+++

## Table of Contens {#table-of-contens}

-   [安装准备](#安装准备)
    -   [系统镜像](#系统镜像)
    -   [虚拟软件](#虚拟软件)
    -   [启动系统](#启动系统)
-   [配置网络](#配置网络)
-   [准备磁盘](#准备磁盘)
    -   [创建分区](#创建分区)
    -   [创建文件系统](#创建文件系统)
    -   [挂载根分区](#挂载根分区)
-   [安装 stage3](#安装-stage3)
    -   [配置编译选项](#配置编译选项)
-   [基本系统](#基本系统)
    -   [镜像站点](#镜像站点)
    -   [复制 DNS 信息](#复制-dns-信息)
    -   [挂载必要的文件系统](#挂载必要的文件系统)
    -   [进入新环境](#进入新环境)
    -   [挂载 boot 分区](#挂载-boot-分区)
    -   [选择配置文件](#选择配置文件)
    -   [更新 @world 集合](#更新-world-集合)
    -   [设置时区](#设置时区)
    -   [配置地区](#配置地区)
-   [编译内核](#编译内核)
    -   [安装源码](#安装源码)
    -   [配置内核](#配置内核)
    -   [编译和安装内核](#编译和安装内核)
-   [配置系统](#配置系统)
    -   [配置 fstab 文件](#配置-fstab-文件)
    -   [网络信息](#网络信息)
-   [系统工具](#系统工具)
    -   [日志工具](#日志工具)
    -   [文件索引](#文件索引)
    -   [远程访问](#远程访问)
    -   [文件系统工具](#文件系统工具)
    -   [网络工具](#网络工具)
-   [安装引导](#安装引导)
    -   [重启系统](#重启系统)
-   [后记](#后记)
    -   [添加用户](#添加用户)
    -   [清理垃圾](#清理垃圾)
-   [总结](#总结)
    -   [系统安装](#系统安装)
    -   [安装软件](#安装软件)
-   [参考链接](#参考链接)


## 安装准备 {#安装准备}

  [Gentoo](https://www.gentoo.org/) 一直是一个特别的存在，号称极客系统。网上对其推(装)崇(逼)备(必)至(备)。作为一个爱装逼的骚年，自然是想一探究尽。关于它的介绍，这里就不说了，
因为想挑战它的 Geeker 肯定都知道，如果没听过，还是选择隔壁 [manjaro](https://www.manjaro.cn/) 。manjaro 是基于另一个优秀的发行版 [Arch Linux](https://www.archlinux.org/)，就是很贴心的省去了痛苦的
安装过程。想体验 Geeker 的成就感， Gentoo 和 Arch Linux 选择其中一个即可。这两者的区别是前者安装软件默认从源代码编译，而后者人性化一点，使用二进制安装包。
安装速度不知快了多少倍。也不知这些极客怎么忍受的，不过 Gentoo 的滚动更新没有 Arch 哪么快，所以安装完必要的软件之后就不须要频繁的更新，而 Arch 三天两头就可以
滚一滚了。


### 系统镜像 {#系统镜像}

   安装系统，镜像是必须的(废话)。去 [Gentoo官方镜像站](https://www.gentoo.org/downloads/mirrors/) 下载的时候根据自己的硬件和地区选择合适的镜像，我这边使用的amd64的架构，
因此使用的是 releases/amd64/autobuilds/install-amd64-minimal-20181220T214503Z.iso。


### 虚拟软件 {#虚拟软件}

   这里以 VirtualBox 为例，VMware 应该是一样的。用VirtualBox的理由是便于端口转发，然后使用 putty 连接 LiveCD 系统，这样就没必要一个个的敲命令了。
当然这是最快体验大 Gentoo 的方法，如果要安装到物理机，除非另一个系统或电脑，否则只能一个个敲了。


### 启动系统 {#启动系统}

   这里参考网上创建虚拟机即可，启动的时候可以选择可用内核，本文用的是默认的4.14.83内核，快捷键： `F1` 显示可用内核； `F2` 显示可用的启动项。需要
详细参数的可以参考[官方文档](https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Media/zh-cn) 。
启动后，先设置 root 密码，便于ssh远程连接，然后开启 ssh 服务即可使用 ssh 客户端连接。

```bash
root # passwd
New password: (Enter the new password)
Re-enter password: (Re-enter the password)

root # rc-service sshd start
```

如果是只有一台电脑安装，那么可以借助终端浏览器 `links2` 来实现查阅在线文档：

```bash
root # links https://wiki.gentoo.org/wiki/Handbook:AMD64
```


## 配置网络 {#配置网络}

这里我使用的 NAT 网络模式，内部系统默认使用的是 dhcp。反正是用来装系统的，所以能够联网就行，管它是不是静态ip呢。


## 准备磁盘 {#准备磁盘}


### 创建分区 {#创建分区}

  分区表有 GPT 和 MBR 两种，前者是新的的分区格式，后者为比较老的。但是 GPT 要求主板支持 UEFI 启动，稍微有点麻烦。这个
麻烦主要体现在安装引导的地方，如果硬件不支持 UEFI ，那么引导是装不上去的。所以为了简单，本例以 MBR 为例。分区工具使用
fdisk，因为它是交互式的，命令也很简单。本例的最后的目标分区如下：

| 分区      | 描述     |
|---------|--------|
| /dev/sda1 | BIOS启动分区 |
| /dev/sda2 | 系统boot分区 |
| /dev/sda3 | 交换分区 |
| /dev/sda4 | 根分区   |

```bash
root # fdisk /dev/sda
  命令(输入 m 获取帮助)：m

  帮助：

    DOS (MBR)
     a   开关 可启动 标志
     b   编辑嵌套的 BSD 磁盘标签
     c   开关 dos 兼容性标志

    常规
     d   删除分区
     F   列出未分区的空闲区
     l   列出已知分区类型
     n   添加新分区
     p   打印分区表
     t   更改分区类型
     v   检查分区表
     i   打印某个分区的相关信息

    杂项
     m   打印此菜单
     u   更改 显示/记录 单位
     x   更多功能(仅限专业人员)

    脚本
     I   从 sfdisk 脚本文件加载磁盘布局
     O   将磁盘布局转储为 sfdisk 脚本文件

    保存并退出
     w   将分区表写入磁盘并退出
     q   退出而不保存更改

    新建空磁盘标签
     g   新建一份 GPT 分区表
     G   新建一份空 GPT (IRIX) 分区表
     o   新建一份的空 DOS 分区表
     s   新建一份空 Sun 分区表


  命令(输入 m 获取帮助)：
```

根据上面的提示就可以轻松的创建自己的分区，如果是新硬盘，须要先新建分区表。如果要创建
GPT 分区表，使用 `g` 命令， MBR 则使用 `o` 命令，然后就是创建分区了， `p` 可以显示分区
信息， `n` 用于添加新分区，按照提示给定分区大小。这里值得一提的是 MBR 只能有 `4` 个主分区。
如果想多于 `4` 个，应将其中一个设置为扩展分区。本例最后的分区结果如下：

```bash
命令(输入 m 获取帮助)：p
Disk /dev/sda：59.1 GiB，63433342976 字节，123893248 个扇区
单元：扇区 / 1 * 512 = 512 字节
扇区大小(逻辑/物理)：512 字节 / 512 字节
I/O 大小(最小/最佳)：512 字节 / 512 字节
磁盘标签类型：dos
磁盘标识符：0x158b7a45

设备       启动    起点      末尾      扇区  大小 Id 类型
/dev/sda1          2048      6143      4096    2M 83 Linux
/dev/sda2          6144    268287    262144  128M 83 Linux
/dev/sda3        268288   1316863   1048576  512M 83 Linux
/dev/sda4       1316864 123893247 122576384 58.5G 83 Linux

命令(输入 m 获取帮助)：
```


### 创建文件系统 {#创建文件系统}

BIOS分区可以不用管，只要创建其分区的文件系统即可：

```bash
root # mkfs.ext2 /dev/sda2
root # mkfs.ext4 /dev/sda4
root # mkswap /dev/sda3
root # swapon /dev/sda3
```


### 挂载根分区 {#挂载根分区}

现在把根区挂载到 liveCD 上，这样才能使用该分区来安装系统。

```bash
root # mount /dev/sda4 /mnt/gentoo
```


## 安装 stage3 {#安装-stage3}

在下载系统镜像的地址有对应的 stage3 的镜像，把它下载下来并解压到 /mnt/gentoo 目录。
在下载之前先确定一下系统的时间, 如果不对则设置时间，否则安下载 stage3 会报错：

```bash
root # date
2018年 12月 25日 星期二 20:36:02 CST
root # date 122520362018  # 如果不是就设置
```

```bash
root # cd /mnt/gentoo
root # wget https://mirrors.tuna.tsinghua.edu.cn/gentoo/releases/amd64/autobuilds/current-stage3-amd64/stage3-x32-20181220T214503Z.tar.xz
root # tar xvJf stage3-x32-20181220T214503Z.tar.xz
```


### 配置编译选项 {#配置编译选项}

   这里基本是用的默认选项，只增加了 make 的编译线程，据说线程数为 CPU 核心数的 2 倍的时候
编译效果最佳。吐嘈一下，镜像里竟然不带vi。

```bash
root #nano -w /mnt/gentoo/etc/portage/make.conf
MAKEOPTS="-j2"
```


## 基本系统 {#基本系统}

  现在就需要配置需要编译的模块了，各取所需了，想想这应该是极客比较喜欢
它的理由吧，小而强悍，没必要添加不需要的模块。


### 镜像站点 {#镜像站点}

   虽然是可选操作，但是为了速度，选择国内站点是个明智的选择，选完站点后，需要配置 Gentoo ebuild
软件仓库。

```bash
root #mirrorselect -i -o >> /mnt/gentoo/etc/portage/make.conf
root #mkdir --parents /mnt/gentoo/etc/portage/repos.conf
root #cp /mnt/gentoo/usr/share/portage/config/repos.conf /mnt/gentoo/etc/portage/repos.conf/gentoo.conf
```


### 复制 DNS 信息 {#复制-dns-信息}

便于进入到里面的系统联网，需要复制 DNS 信息。

```bash
cp --dereference /etc/resolv.conf /mnt/gentoo/etc/
```


### 挂载必要的文件系统 {#挂载必要的文件系统}

等会儿Linux的根将变更到新的位置。为了确保新环境正常工作，需要确保一些文件系统可以正常使用。

需要提供的文件系统是：

-   /proc : 一个pseudo文件系统（看起来像是常规文件，事实上却是实时生成的），由Linux内核暴露的一些环境信息
-   _sys :  一个pseudo文件系统，像要被取代的/proc_一样，比_proc_更加有结构
-   /dev : 是一个包含全部设备文件的常规文件系统，一部分由Linux设备管理器（通常是udev）管理

_proc_位置将要挂载到_mnt/gentoo/proc_，而其它的两个都是绑定挂载。字面上的意思是，例如_mnt/gentoo/sys_事实上就是_sys_（它只是同一个文件系统的第二个条目点），而_mnt/gentoo/proc_是（可以说是）文件系统的一个新的挂载。

```bash
root #mount --types proc /proc /mnt/gentoo/proc
root #mount --rbind /sys /mnt/gentoo/sys
root #mount --make-rslave /mnt/gentoo/sys
root #mount --rbind /dev /mnt/gentoo/dev
root #mount --make-rslave /mnt/gentoo/dev
```


### 进入新环境 {#进入新环境}

   只需使用 chroot 命令即可进入新系统，当然还有一些必要的环境切换，如加载新环境的环境变量以及
修改提示符用来区分系统。

```bash
root #chroot /mnt/gentoo /bin/bash
root #source /etc/profile
root #export PS1="(chroot) ${PS1}"
```


### 挂载 boot 分区 {#挂载-boot-分区}

这一步很重要，当编译内核并安装引导加载程序时会放在 boot 里。

```bash
root #mount /dev/sda2 /boot
```


### 选择配置文件 {#选择配置文件}

   配置文件会决定你想要安装什么软件，所以这个也会决定编译时间的长短，为了快速体验 Gentoo，本例
使用了默认的选项，没有桌面环境以及 systemd 等。

```bash
root #eselect profile list

Available profile symlink targets:
  [1]   default/linux/amd64/13.0 *
  [2]   default/linux/amd64/13.0/desktop
  [3]   default/linux/amd64/13.0/desktop/gnome
  [4]   default/linux/amd64/13.0/desktop/kde
  [5]   default/linux/amd64/13.0/desktop/gnome/systemd (stable)
  [6]   default/linux/amd64/13.0/desktop/plasma (stable)
  [7]   default/linux/amd64/13.0/desktop/plasma/systemd (stable)
  [8]   default/linux/amd64/13.0/developer (stable)
  [9]   default/linux/amd64/13.0/no-multilib (stable)
  [10]  default/linux/amd64/13.0/systemd (stable)
  [11]  default/linux/amd64/13.0/x32 (dev)
  [12]  default/linux/amd64/17.0 (stable) *
  [13]  default/linux/amd64/17.0/selinux (stable)
  [14]  default/linux/amd64/17.0/hardened (stable)
  [15]  default/linux/amd64/17.0/hardened/selinux (stable)
  [16]  default/linux/amd64/17.0/desktop (stable)
  [17]  default/linux/amd64/17.0/desktop/gnome (stable)
  [18]  default/linux/amd64/17.0/desktop/gnome/systemd (stable)
  [19]  default/linux/amd64/17.0/desktop/plasma (stable)
  [20]  default/linux/amd64/17.0/desktop/plasma/systemd (stable)
  [21]  default/linux/amd64/17.0/developer (stable)
  [22]  default/linux/amd64/17.0/no-multilib (stable)
  [23]  default/linux/amd64/17.0/no-multilib/hardened (stable)
  [24]  default/linux/amd64/17.0/no-multilib/hardened/selinux (stable)
  [25]  default/linux/amd64/17.0/systemd (stable)
  [26]  default/linux/amd64/17.0/x32 (dev)
```

如果想选择其他的配置，比如想使用17.0版本的 gnome 桌面，则使用如下命令选择即可：

```bash
root # eselect profile set 17
```


### 更新 @world 集合 {#更新-world-集合}

   当系统应用了任何的升级，或从任何 profile 构建了 stage3 后，应用了变化的 use 标记时，
都需要更新一下 `@world` :

```bash
root #emerge --ask --verbose --update --deep --newuse @world
```


### 设置时区 {#设置时区}

为系统选择时区。在_usr/share/zoneinfo_中查找可用的时区，然后写进/etc/timezone文件。

```bash
root # ls /usr/share/zoneinfo
root #echo "Asia/Shanghai" > /etc/timezone
```

安装 [sys-libs/timezone-data](https://packages.gentoo.org/packages/sys-libs/timezone-data) 自动更新 `/etc/localtime` 文件。该文件用于让系统的 C 类库知道
系统在什么时区。

```bash
root #emerge --config sys-libs/timezone-data
```


### 配置地区 {#配置地区}

```bash
root #nano -w /etc/locale.gen

# 将下面的文本加入文件中
en_US ISO-8859-1
en_US.UTF-8 UTF-8
zh_CN GBK
zh_CN.UTF-8 UTF-8
```

使设置生效，运行命令： `locale-gen` 。最后选择默认字体:

```bash
root #eselect locale list

Available targets for the LANG variable:
  [1]   C
  [2]   en_US
  [3]   en_US.iso88591
  [4]   en_US.utf8
  [5]   POSIX
  [6]   zh_CN
  [7]   zh_CN.gbk
  [8]   zh_CN.utf8
  [ ]   (free form)
root #eselect locale set 8
```

重新加载环境：

```bash
root #env-update && source /etc/profile && export PS1="(chroot) $PS1"
```


## 编译内核 {#编译内核}

前期的准备基本已经完成，终于要上主菜了。


### 安装源码 {#安装源码}

这里使用 gentoo-source 包来安装内核。安装完就可以在 `/usr/src/linux` 找到对应的源码了。

```bash
root #emerge --ask sys-kernel/gentoo-sources
root #ls -l /usr/src/linux

lrwxrwxrwx    1 root   root    12 Oct 13 11:04 /usr/src/linux -> linux-3.16.5-gentoo
```


### 配置内核 {#配置内核}

   首先要知道自己的硬件配置，这样才能配置对应的内核，查看硬件信息需要借助 `lspci` 命令。
因此需要先安装对应的工具：

```bash
root #emerge --ask sys-apps/pciutils
```

在了解了自己的硬件配置之后，就可以进行配置了，官网提供了两种方法，第二种是自动化，本来想偷个
懒使用 genkernel 软件省去自己手动配置的烦恼。可惜事与愿违，这个软件死活装不上去，只能手动配置了。
还好大部分的配置都选好了，这里只增加了32位的软件支持：

```bash
Executable file formats / Emulations  --->
   [*] IA32 Emulation
```

当然如果是 UEFI ，就需要增加一些配置，不然没法驱动。传送门：<https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Kernel/zh-cn>

记得保存配置。。。


### 编译和安装内核 {#编译和安装内核}

这个步骤就比较慢了，估计半个多小时吧，可以泡杯咖啡慢慢等了。

```bash
root # make && make modules_install && make install
```


## 配置系统 {#配置系统}

如果上面的步骤没有报错，那么恭喜你，你离成功只有一步之遥了。


### 配置 fstab 文件 {#配置-fstab-文件}

这是系统所有分区挂载的文件。引用官网的一段介绍：

> /etc/fstab文件使用一种特殊语法格式。每行都包含六个字段。这些字段之间由空白键（空格键，
> tab键，或者两者混合使用）分隔。每个字段都有自己的含意：
>
> 1.  `＃` 第一个字段显示要挂载的特殊 block 设备或远程文件系统。 有几种设备标识符可用于特殊块设备节点，
>
> 包括设备文件路径，文件系统标签，UUID，分区标签以及UUID。
>
> 1.  第二个字段是分区挂载点，也就是分区应该挂载到的地方
> 2.  第三个字段给出分区所用的文件系统
> 3.  第四个字段给出的是挂载分区时mount命令所用的挂载选项。由于每个文件系统都有自己的挂载选项。
> 4.  第五个字段是给dump使用的，用以决定这个分区是否需要dump。一般情况下，你可以把该字段设为0（零）。
> 5.  第六个字段是给fsck使用的，用以决定系统非正常关机之后文件系统的检查顺序。
>
> 根文件系统应该为1，而其它的应该为2（如果不需要文件系统自检的话可以设为0）

```bash
root # nano -w /etc/fstab

# 将下面的内容拷贝到 fstab 中
/dev/sda2   /boot        ext2    defaults,noatime     0 2
/dev/sda3   none         swap    sw                   0 0
/dev/sda4   /            ext4    noatime              0 1

/dev/cdrom  /mnt/cdrom   auto    noauto,user          0 0
```


### 网络信息 {#网络信息}


#### 主机名 {#主机名}

```bash
root # echo 'hostname="Gentoo"' > /etc/conf.d/hostname
```


#### 配置网络 {#配置网络}

这里使用的 DHCP 自动获取 IP:

```bash
root # echo 'config_enp0s3="dhcp"' > /etc/conf.d/net
```

当然也可以使用静态 ip :

```bash
# /etc/conf.d/net静态IP定义
config_enp0s3="192.168.0.2 netmask 255.255.255.0 brd 192.168.0.255"
routes_enp0s3="default via 192.168.0.1"
```

设置开机启动网络：

```bash
root #cd /etc/init.d
root #ln -s net.lo net.enp0s3
root #rc-update add net.enp0s3 default
```


#### Root 密码 {#root-密码}

这个前面已经介绍过了，千万别忘记。


## 系统工具 {#系统工具}

现在只需要安装必要的系统软件即可。


### 日志工具 {#日志工具}

```bash
root #emerge --ask app-admin/sysklogd
root #rc-update add sysklogd default
```


### 文件索引 {#文件索引}

```bash
root #emerge --ask sys-apps/mlocate
```


### 远程访问 {#远程访问}

```bash
rc-update add sshd default
```


### 文件系统工具 {#文件系统工具}

系统已经自带了 ext 文件系统的工具，需要其它文件系统需要自行安装。

| Filesystem        | Package              |
|-------------------|----------------------|
| Ext2, 3, and 4    | sys-fs/e2fsprogs     |
| XFS               | sys-fs/xfsprogs      |
| ReiserFS          | sys-fs/reiserfsprogs |
| JFS               | sys-fs/jfsutils      |
| VFAT (FAT32, ...) | sys-fs/dosfstools    |
| Btrfs             | sys-fs/btrfs-progs   |


### 网络工具 {#网络工具}

因为系统不带 dhcp 客户端，需要自己安装，Gentoo 为了保持干净也是拼了。

```bash
root #emerge --ask net-misc/dhcpcd
```


## 安装引导 {#安装引导}

  最后一关到了，成功与否就看它了。不过如果使用 MBR 分区表就没必要担心了。
这一步主要难在要支持 UEFI 启动，这个是比较麻烦的，也许是我搭的虚拟机的硬件不
支持 UEFI，所以第一次配置到这里的时候以失败告终。所以换了 MBR 后，一步成功。

```bash
root # emerge --ask --verbose sys-boot/grub:2
root # grub-install /dev/sda
root # grub-mkconfig -o /boot/grub/grub.cfg
```


### 重启系统 {#重启系统}

OK，彻底结束了，重启之后就可以享(折)受(腾) Gentoo 了。

```bash
root #exit
livecd ~# cd
livecd ~# umount -l /mnt/gentoo/dev{/shm,/pts,}
livecd ~# umount -R /mnt/gentoo
livecd ~# reboot
```


## 后记 {#后记}

  如果启动成功，那么就可以开心的使用它了，首先要建立一个普通用户，避免权限过大
损坏系统。


### 添加用户 {#添加用户}

| Group   | Description      |
|---------|------------------|
| audio   | 允许使用声音设备 |
| cdrom   | 允许直接使用光驱设备 |
| floppy  | 允许直接使用软驱 |
| games   | 允许运行游戏     |
| portage | 能够访问portage受限资源。 |
| usb     | 允许使用USB设备  |
| video   | 允许使用视频采集设备和硬件加速 |
| wheel   | 可以使用su.      |

```bash
root #useradd -m -G users,wheel,audio -s /bin/bash jer
root #passwd jer
```


### 清理垃圾 {#清理垃圾}

```bash
root #rm /stage3-*.tar.bz2*
```


## 总结 {#总结}


### 系统安装 {#系统安装}

  很早就听说 Gentoo 系统，只是怕麻烦，懒得去安装。昨天突然心血来潮，就装了一下试试。
总的来说和 Arch 安装过程差不多，不过这编译速度太感人了， Arch 下载基本系统也就十来分钟
吧，源比较快可能几分钟就搞定了，而 Gentoo 光是编译内核就需要半个小时以上。


### 安装软件 {#安装软件}

   常用的软件使用以及建议，vim 和 emacs 这两大编译器最好自己去安防网下载源码自行编译，
因为emerge安装的是腌割版。至于 nodejs (hexo) 需要，因为依赖的软件太多了，所以要一个个
安装完再安装 nodejs，而且如果有提示版本不一致的，需要卸载再装。目前还在探索中。。。
如果要使用 emerge 安装软件，而又记不得软件名使用 `-s` 参数查询软件，然后选择合适的版本进行安装。
这里提一最好用正则表达式搜索，不然可能会搜到好多软件。

给出vim 和 emacs 的编译选项，免得再找：

-   vim : ./configure  --enable-pythoninterp=yes --with-python-config-dir=/usr/lib64/python3.6/config --enable-cscope

-   emacs: ./configure --with-pop --with-mailutils

-   nodejs:

    ```bash
      sudo emerge net-libs/http-parser
      sudo emerge dev-util/boost-build
      sudo emerge  dev-libs/boost
      sudo emerge  dev-libs/libuv
      sudo emerge --unmerge dev-libs/openssl
      sudo emerge dev-libs/openssl
      sudo emerge net-libs/nghttp2
      sudo emerge net-libs/nodejs
    ```


## 参考链接 {#参考链接}

<https://wiki.gentoo.org/wiki/Handbook:AMD64/Full/Installation/zh-cn>