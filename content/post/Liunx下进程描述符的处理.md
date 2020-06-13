+++
title = "Liunx下进程描述符的处理"
author = ["Jerling"]
description = "Short description"
date = 2020-06-13T19:07:33+08:00
lastmod = 2020-06-13T22:45:02+08:00
tags = ["linux", "thread_info", "内核栈"]
categories = ["学习笔记"]
type = "post"
draft = false
author_homepage = "https://github.com/Jerling"
toc = true
+++

## Thread\_info {#thread-info}

在 Linux 中的任务结构体 `task_struct` 中包含特定于体系结构的信息以及通用的信息， `thread_info` 结构体则是描述进程特定于体系结构的信息字段。而在 `thread_info` 中也包含指向 `task_struct` 的指针，这样方便相互访问。


## 内核栈 {#内核栈}

内核栈是供内核例程使用的栈，每个进程都拥有一个独立的内核栈，并且进入时，内核栈都是空的。


## 共用体 {#共用体}

Linux 将 `thread_info` 和内核栈放在了同一个内存区域，通常是两个页框大小，即 8196 字节。其中 `thread_info` 驻于起始位置，而栈从末端开始向下增长。因此只要保证足够大小的栈，那么
`thread_info` 将一直不会被覆盖。具体结构如下：

```C
union thread_union{
    struct thread_info thread_info;
    unsigned long stack[2048];
} ;
```


## Why {#why}

那么 Linux 为何这样设计呢？

内核很容易从 `esp` 寄存器中的值获得当前在 CPU 上运行进程的 `thread_info` 结构的地址。去掉 `esp` 的低 13 位，即 8K 大小，余下的就是 `thread_union` 的起始地址，也即 `thread_info` 的起始地址。


## 获取当前进程描述符 {#获取当前进程描述符}

进程中最常用的并不是 `thread_info` 结构，而是 `task_struct` 结构。 在早期，Linux 没有将进程结构和内核栈设置在一起，因此内核强制引入全局变量 `current` 来标识正在运行进程的描述符。

将 `thread_info` 和内核栈设置成共用体的数据结构，就可以使用内核栈的栈顶地址 `esp`
来获取当前运行进程的描述符，即： `current_thread_info()->task` 。而 `current_thread_info` 其实就是将 `esp` 屏蔽低 13 位得到的地址，也即 `thread_info` 的地址。


## 总结 {#总结}

Linux 将 `thread_info` 信息结构和内核栈通过一个共用体进行管理，主要存两点好处：

1.  时间效率 : 通过 `esp` 的简单操作即可确定当前进程的 `task_struct` 地址
2.  空间利用 : 将 `thread_info` 放在内核栈的起始位置，而栈是从末端增长的，可以很好地利用内核栈的空间,就像栈和堆一样，朝相向的方向增长，可以提升内存的空间利用率。不过就 `thread_union` 来说，最主要还是效率，毕竟 `thread_info` 比较小，而且大小固定。
