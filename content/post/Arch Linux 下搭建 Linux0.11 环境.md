+++
title = "Arch Linux 下搭建 Linux0.11 环境"
author = ["Jerling"]
description = "Short description"
date = 2020-06-11T16:33:09+08:00
lastmod = 2020-06-11T17:44:00+08:00
tags = ["ArchLinux", "bochs", "linux0.11"]
categories = ["内核实验"]
type = "post"
draft = false
author_homepage = "https://github.com/Jerling"
toc = true
+++

## Bochs 模拟器 {#bochs-模拟器}

Bochs 是一个轻量级的硬件模拟器，相对于 Vmware, VirtualBox 这些软件，它显得轻巧得多。更重要的是，它有着强大的调试系统，因此成为广大操作系统编程人员的好工具。

之前在相关实验中使用过，但是是基于一键脚本完成安装的，并不是了解其中过程。而且是基于 Ubuntu 的，而本人使用 Arch Linux 较多，因此尝试将环境搭建到 Arch Linux 系统中。


## 下载 Linux0.11 开发工具包 {#下载-linux0-dot-11-开发工具包}

地址： `http://oldlinux.org/Linux.old/bochs/linux-0.11-devel-060625.zip`

最新版的开发包中的 Bochs 是 `2.2.1` 版本。


## Bochs 编译 {#bochs-编译}

正常情况下，Arch Linux 可以使用 pacman 进行安装。但是，安装的 Bochs 是最新版，对老版的配置文件不太支持。因此需要手动编译
`bochs2.2.1` 版。


### 源码下载 {#源码下载}

地址： `https://master.dl.sourceforge.net/project/bochs/bochs/2.2.1/bochs-2.2.1.tar.gz`


### 编译 {#编译}

在解压之后，运行里面的 `configure` 文件生成 `Makefile` 配置文件：

```sh
./configure
make
```

这里会出现问题：

```text
../iodev/harddrv.h:290:8: 错误：有多余的限定‘sparse_image_t::’在成员‘get_physical_offset’上 [-fpermissive]
  290 |        sparse_image_t::
      |        ^~~~~~~~~~~~~~
../iodev/harddrv.h:295:8: 错误：有多余的限定‘sparse_image_t::’在成员‘set_virtual_page’上 [-fpermissive]
  295 |        sparse_image_t::
```

可能是编译器语法的不兼容导致的问题，查看对应的文件的行号：

```text
#ifndef PARANOID
       sparse_image_t::
#endif
                       get_physical_offset();
 void
#ifndef PARANOID
       sparse_image_t::
#endif
                       set_virtual_page(uint32 new_virtual_page);
```

可以看到，当定义 `PARANOID` 宏时会加上多余的限定，导致出错。直接删除这里的限定即可。


### Debugger 模式 {#debugger-模式}

如果在 `configure` 的时候启用了 `debugger` 模式，那么需要 `hash_map` 的支持。这个应该是 STL 中的扩展，或许还不是校准的一部分。又或者以前是，而现在不是了。总之，在我的机器上的 std 命名空间中找不到了。但是，经过测试，发现 `hash_map` 在 `__gnu_cxx` 命名空间中，也就是说成了 GNU CXX 拓展的一部分了。

暂时不管这些，能找到 `hash_map` 就行。 在 `bx_debug/dbg_main.cc` 文件前面引用 `__gnu_cxx` 即可：

```c++
using namespace __gnu_cxx;
```


## 安装 {#安装}

```sh
sudo make install
```


## 测试 {#测试}

进入 linux-0.11 开发工具包的根目录，执行以下命令：

```sh
bochs -q -f bochsrc-hd.bxrc
```

{{< figure src="/images/2020-06-11-171530_1312x865_scrot.png" >}}

> 如果在编译的时候启用了 `deugger` ,那么启动的时候是 debug 模式，需要在命令调试窗口执行 c 命令，否则只能看到一个空白窗口。
