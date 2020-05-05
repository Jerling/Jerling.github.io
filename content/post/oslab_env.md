+++
title = "Linux 内核学习 — 实验环境"
author = ["Jerling"]
description = "Short description"
date = 2020-04-20T22:21:06+08:00
lastmod = 2020-04-21T00:11:54+08:00
tags = ["linux", "kernel", "bochs"]
categories = ["内核实验"]
type = "post"
draft = false
author_homepage = "https://github.com/Jerling"
toc = true
+++

## 编译环境
这里选择轻量级的 Lubuntu，版本为19.10。

## oslab环境搭建

感谢 [Wangzhike](https://github.com/Wangzhike/HIT-Linux-0.11)提供开源的一键配置环境。

### 安装包下载
```shell
git clone https://github.com/Wangzhike/HIT-Linux-0.11.git
```

### 环境适配
按照 README中的环境搭建指南，实际测试不行。需要添加32位架构支持，然后再执行 setup.sh脚本。
```shell
sudo dpkg --add-architecture i386
```

### 环境安装
```shell
.cd HIT-Linux-0.11/prepEnv/hit-oslab-qiuyu/ 
./setup.sh
```

### 编译内核
```shell
cd ~/oslab/linux-0.11
make
```

### 运行 Linux
```shell
cd ~/oslab && ./run
```
结果如图：
{{< figure src="/images/Snipaste_2020-04-19_23-54-08.png" >}}

### gdb调试
联调分两个部分：
1. `dbg-asm`和`dbg-c`脚本启动调试，等待gdb连接
2. `rungdb`脚本进行连接并调试

这里直接使用 `./rungdb` 命令，如果报错：
```shell
./gdb: error while loading shared libraries: libncurses.so.5: cannot open shared object file: No such file or directory
```
那么需要安装对应的32位库
```shell
sudo apt install libncurses5:i386
```

如果继续出错：
```
/gdb: error while loading shared libraries: libexpat.so.1: cannot open shared object file: No such file or directory
```
同样安装对应的32位库即可
```shell
sudo apt install libexpat1-dev:i386
```

调试成功截图：
{{< figure src="/images/Snipaste_2020-04-20_00-06-25.png" >}}

## 参考
[https://www.cnblogs.com/tradoff/p/5693710.html](https://www.cnblogs.com/tradoff/p/5693710.html)