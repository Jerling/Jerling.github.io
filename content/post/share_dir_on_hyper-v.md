+++
title = "在win10上使用hyper-v共享文件夹给linux系统"
author = ["Jerling"]
description = "文件夹共享"
date = 2020-05-14T7:36:20+08:00
lastmod = 2020-05-14T7:36:20+08:00
tags = ["share", "hyper-v", "cifs"]
categories = ["使用技巧"]
type = "post"
draft = false
author_homepage = "https://github.com/Jerling"
toc = "true"
+++

## windows 文件夹共享
这里只需要简单的几步就可以实现 windows 目录的共享功能。具体过程如下：

1. 在你需要共享的目录右键，选择属性
2. 选择共享按钮，点击中间的高级共享
3. 勾选 `共享此文件夹` 。点击下面的权限，合理分配读写权限
4. 点击确定，在 2 步会显示共享的网络路径，记下

## 安装工具
安装 `cifs` 工具，例如在 `Arch Linux` 下：
```shell
sudo pacman -S cifs-utils
```

## 创建保存 windows 用户和密码的文件
```shell
vim ~/.credentials
username=username
password=password
```

## 将挂载信息写入 fstab
```shell
sudo echo >> "//Desktop-suji1sd/d /home/jer/data cifs credentials=/home/jer/.credentials,ip=192.168.137.1,file_mode=0777,dir_mode=0777,noperm,_netdev,rw,iocharset=utf8,soft,uid=1000,gid=10000 0" >> /etc/fstab
```

## 正式挂载
```shell
sudo mount //Desktop-suji1sd/d
```

## 密码文件权限
最后记得修改密码文件读写权限，防止密码泄露
```shell
chmod 600 ~/.credentials
```

## 参考
1. [https://www.jianshu.com/p/b3c55a4224f3](https://www.jianshu.com/p/b3c55a4224f3)
