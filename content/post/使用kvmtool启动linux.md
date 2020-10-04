+++
title = "使用kvmtool启动linux"
author = ["Jerling"]
description = "Short description"
date = 2020-09-29T10:46:44+08:00
lastmod = 2020-10-04T15:30:32+08:00
tags = ["kvm", "kvmtool", "linux"]
categories = ["虚拟化"]
type = "post"
draft = false
author_homepage = "https://github.com/Jerling"
toc = true
+++

## 前言 {#前言}

所谓学以致用，学习的目的就是为了使用。那么相反的，好用可以反过来督促进一步深入学习。本文是 linux kvm 虚拟化子系统的开篇，主要讲如何搭建一个基础的环境，充分探索
kvm 提供的强大虚拟化功能。目前在 Linux 主线中主要有 kvm 和 xen 虚拟化子系统，本系列只讲 kvm.


## kvmtool {#kvmtool}

通常在引用虚拟化的时候，都会选择 qemu 作为虚拟机管理工具，并且提供除 cpu/mem 之外的虚拟化技术。但 qemu 提供的功能太复杂了，它除了可以使用 kvm , 还可以模拟其它架构进行虚拟化，因此，qemu 是一个比较庞大的项目。而 kvm 只是利用主机架构的硬件虚拟化技术。如果只是应用 kvm , 比如创建虚拟机使用等，完全可以使用 qemu 或类似的虚拟机管理工具。

本系列是为了学习 kvm 虚拟化技术，那么就可以尽量简化用户态管理程序。等学会了 kvm 的基本使用后，再去探究深层次的实现原理。这里就以开源的工具 kvmtool
为例讲讲 kvm 是如何使用的。


## 编译 kvmtools {#编译-kvmtools}

在编译之前，确保有一台 linux 主机，并且运行带有 kvm 子系统的内核。不过常见的 AMD64 架构的发行版一般都会满足，可以使用 `lsmod | grep kvm` 命令检查一下：
![](/images/截图录屏_选择区域_20201004145135.png)

下载 kvmtools 并编译：

```sh
git clone --depth 1 https://github.com/kvmtool/kvmtool.git
cd kvmtool
make
sudo cp lkvm /usr/local/bin
```

这样我们就可以使用 lkvm 程序对虚拟机进行管理，同时也是用来探索 kvm 相关技术的。


## 内核编译 {#内核编译}

首先需要编译一个内核压缩镜像文件，之后我们将用 lkvm 启动这个镜像，由于国外的内核源码下载比较慢，这里推荐使用国内的地址：

```shell
wget https://mirrors.tuna.tsinghua.edu.cn/kernel/v5.x/linux-5.8.9.tar.xz
tar -xvf linux-5.8.9.tar.xz
cd linux-5.8.9
make menuconfig
make -j8
```

> 在 menuconfig 中需要将一些模块编译进内核，而不是模块，比如 VIRTIO 等，这些宏控具体看 kvmtool 的文档。编译完之后在 arch/x86/boot/ 下生成压缩镜像 bzImage.


## 启动内核： {#启动内核}

```nil
lkvm run --kernel ./linux-5.8.9/arch/x86/boot/bzImage
```

效果如图：
![](/images/截图录屏_选择区域_20201004151853.png)

可以看到，内核 正常跑起来了，只是因为没有根文件系统，无法执行 init 程序进入终端。

下一节，我们开始讲如何创建一个根文件系统，并用 kvmtool 启动根文件系统和内核镜像。
