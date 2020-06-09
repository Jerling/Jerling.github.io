+++
title = "Linux 内核设计与实现 — 系统调用"
author = ["Jerling"]
description = "Short description"
date = 2019-06-01T22:21:06+08:00
lastmod = 2019-06-02T00:11:54+08:00
tags = ["linux", "kernel", "系统调用"]
categories = ["学习笔记"]
type = "post"
draft = false
author_homepage = "https://github.com/Jerling"
toc = true
+++

## 三个作用 {#三个作用}

1.  为用户空间提供硬件抽象接口
2.  保证系统稳定和安全
3.  使每个用户程序运行在虚拟系统中


## 系统调用 {#系统调用}

定义一个系统调用(以 `getpid()` 为例)：

```c
SYSCALL_DEFINE0(getpid)
{
  return task_tgid_vnr(current); // return current->tgid
}
```

`SYSCALL_DEFINE0` 是一个宏， `0` 表示参数个数。展开为：

```c
asmlinkage long sys_getpid(void)
```

1.  `asmlinkage` 是编译器指令。通知编译器仅从栈中提取参数，所有的系统调用都需要这个限定词
2.  为了保证 32 位和 64 位的兼容，用户空间返回为 `int`, 内核返回 `long`
3.  系统调用 `get_pid()` 在内核中定义为 `sys_getpid`,这是所有系统调用的命名规则


### 系统调用号 {#系统调用号}

每个系统调用都有一个系统调用号，用户空间的进程执行系统调用时通过系统调用号而不是
名称。

系统调用一旦分配不能改变，也不能复用。系统调用删除需用 "未实现" 系统调用
`sys_ni_syscall()` 进行 "填补".

内核在 `sys_call_table` 记录所有注册过的系统调用，它为每个有效系统调用指定唯一的系统
调用号；这个表是跟体系结构相关的。


## 系统调用处理程序 {#系统调用处理程序}

通过软中断实现：引发一个异常促使系统切换到内核态执行系统调用处理程序 `system_call()`。


### 指定恰当的系统调用 {#指定恰当的系统调用}

在 x86 上，系统调用号通过 `eax` 传递到内核。 `system_call()` 通过将系统调用号与
`NR_syscalls` 比较，如果低于或超出该范围，返回 `-ENOSYS` 。否则执行相应的系统调
用：

```c
call *sys_call_table(, %rax, 8)
```

表项是 `64` 位，所以内核将系统调用号乘 `8`, 32 位系统乘 `4` 。


### 参数传递 {#参数传递}

参数少于五个时，通过寄存器传递；否则用 `eax` 传递一个指向用户空间的指针。


## 实现 {#实现}

添加系统调用比较容易，难在设计和实现。


### 实现系统调用 {#实现系统调用}

1.  用途：不提倡多用途的系统调用（通过传递不同的参数）
2.  参数、返回值和错误码：接口力求简洁，参数尽可能少；力求稳定，不做改动。
3.  设计接口时尽量考虑未来：通用性，移植性，健壮性，考虑字节长度和字节序


### 参数验证 {#参数验证}

1.  指针是否有效
    -   指向的内存区域为用户空间，不能指向内核空间
    -   在该进程的地址空间，不能是其它进程
    -   是读标记为可读，是写标记为可写，是执行标记为可执行，不能饶过内存访问限制
2.  内核不能轻率接受用户空间的指针，必须进行拷贝
    1.  `copy_to_user()` : 向用户空间写入数据
    2.  `copy_from_user` : 从用户空间读如数据
3.  检查权限
    -   老版本使用 `suser` 检查是否为超级用户
    -   现在用细粒度的 "权能" 机制替代， `capable()`


## 上下文 {#上下文}

系统调用为可重入的，当系统调用返回时，控制权在 `system_call()` 中，它负责切换到
用户空间继续运行用户进程


### 绑定系统调用的最后步骤 {#绑定系统调用的最后步骤}

注册过程：

1.  在系统调用表 `sys_call_table` 最后加入一个表项
2.  对于所支持的各种体系结构，系统调用号都必须定义于 `<asm/unistd.h>` 中
3.  必须编译进内核映像（不能是模块）


### 从用户空间访问系统调用 {#从用户空间访问系统调用}

1.  通过库函数（如 `glibc`）
2.  `_syscaln()` 宏： n 为参数个数，以 `open()` 为例：

    ```c
        // 系统调用定义
        long open(const char *filename, int flags, int mode)

        // 系统调用的宏
        #define NR_open 5
        _syscall3(long, open, const char*, filename, int, flags, int, mode)
    ```

每个宏的参数个数为 `2 + 2 * n` 个

该宏会被扩展为内嵌汇编的 C 函数。


### 为什么不通过系统调用的方式实现 {#为什么不通过系统调用的方式实现}

好处：

1.  创建容易，使用方便
2.  高性能

问题：

1.  需要一个系统调用号
2.  加入稳定内核后就固化了
3.  需分别注册到需支持的体系结构中
4.  脚本不易使用，也不能从文件系统直接访问
5.  因为需要系统调用号，在主内核之外很难维护和使用
6.  简单的信息交换，大材小用

替代方法：实现一个设备节点，对此实现 `read()` 和 `write()` 。使用 `ioctl()` 对特
定的设置进行操作或者特定信息进行检索。

1.  像信号量这样的接口，可用文件描述符表示，因此可用上述方式操作
2.  把增加的信息作为文件放在 `sysfs` 的合适文件