+++
title = "Linux 内核设计与实现 — 时间管理"
author = ["Jerling"]
description = "Short description"
date = 2019-06-20T20:52:58+08:00
lastmod = 2019-06-20T23:36:21+08:00
tags = ["linux", "kernel", "时间管理"]
categories = ["学习笔记"]
type = "post"
draft = false
author_homepage = "https://github.com/Jerling"
toc = true
+++

内核中有很多基于时间驱动的函数，如调度程序中运行队列进行平衡调整或对屏幕进行刷新等。时间管理中需注意相对时间和绝对时间的差别以及周期性事件和推迟到某个时间点的区别。系统定时器是一种可编程硬件芯片，能以固定频率产生中断 --- 定时器中断。


## 概念 {#概念}

-   系统定时器：硬件为内核提供计算流逝的时间
-   节拍率：系统时钟自行触发时钟的频率，可通过编程预定
-   节拍：连续两次时钟中断的间隔时间，为节拍率的倒数
-   墙上时间：实际时间
-   系统运行时间：自系统启动后开始所经过的时间


## 节拍率 : HZ {#节拍率-hz}

通过静态预处理定义的。在 `<asm/aparam.h>` 中定义了该值。这个值不是一个固定不变的值。


### 理想的 HZ 值 {#理想的-hz-值}

高频率的好处：

1.  提高时间驱动事件的解析度 (resolution)
2.  提高时间驱动事件的准确度 (accuracy)


#### 优势 {#优势}

1.  内核定时器能以更高的精度和准确度运行
2.  依赖定时器的系统调用(poll,select) 能以更高的精度运行
3.  对诸如资源消耗和系统运行时间等的测量会有更精细的精度
4.  提高进程枪占的准确度


#### 劣势 {#劣势}

系统的负担越重。节拍率越高，中断处理程序占用处理器的时间越多。不仅减少其它工作的时间，而且更频繁地大乱处理器高速缓冲并增加耗电。

> 无节拍OS:根据需要动态调整和重新设置 HZ 的OS. Linux 内核设置 `CONFIG_HZ` 可配置无节拍。


## jiffies {#jiffies}

为全局变量，记录自系统启动以来产生的节拍的总数。

定义在 `linux/jiffies.h` 中：

```c
extern unsigned long volatile jiffies;
```


### 内部表示 {#内部表示}

根据体系结构而定，在特定的体系结构相关的代码中还定义了 `jiffies_64` 这个变量。在
32位机器上 `jiffies` 为 `jiffies_64` 的低32位的值，如果要获取 `jiffies_64` 的值，可通过 `get_jiffies_64()` 获取。在64位机器中， `jiffies` 和 `jiffies_64` 是同一变量。


### 回绕 {#回绕}

当 `jiffies` 增加到最大值后会回到 `0`, 因此在定时事件比较时要防止回绕。

```c
#define time_after(a,b)		\
	(typecheck(unsigned long, a) && \
	 typecheck(unsigned long, b) && \
	 ((long)(b) - (long)(a) < 0))
#define time_before(a,b)	time_after(b,a)

#define time_after_eq(a,b)	\
	(typecheck(unsigned long, a) && \
	 typecheck(unsigned long, b) && \
	 ((long)(a) - (long)(b) >= 0))
#define time_before_eq(a,b)	time_after_eq(b,a)
```


### 用户空间 HZ {#用户空间-hz}

定义为 `USER_HZ` . 这个值不一定等于 `HZ` . 可能需要内核提供一些转换的函数。


## 硬时钟和定时器 {#硬时钟和定时器}

体系结构提供两种设备进行计时 --- 系统定时器和实时时钟。


### 实时时钟 {#实时时钟}

实时时钟 (RTC) 是用来持久存放系统时间的设备。

系统启动时，内核读取 RTC 来初始化墙上时间，存放在 `xtime` 变量中。


### 系统定时器 {#系统定时器}

一种周期性触发中断机制。不同的体系结构实现不一样，如对电子晶振进行分频、衰减测量器。

在 x86 体系中，主要使用可编程中断时钟 (PIT). 内核在启动时对 PIT 进行编程初始化，使其能够以 HZ/秒的频率产生中断。


## 时钟中断处理程序 {#时钟中断处理程序}

分为体系结构相关部分和不相关部分。

相关部分的例程作为系统定时器的中断处理程序而注册到内核中，以便产生时钟中断时能够运行。大部分的处理程序最低限度地执行如下工作：

1.  获得 `xtime_lock` 锁，以便访问 `jiffies_64` 和保护墙上时间 `xtime`
2.  需要时应答或重新设置系统时钟
3.  周期性地使用墙上时间更新实时时钟
4.  调用体系结构无关的时钟例程： `tick_periodic()`
    1.  给 `jiffies_64` 变量加 1
    2.  更新资源消耗的统计值，比如当前进程的系统时间和用户时间
    3.  执行已经到期的动态定时器
    4.  执行 `sheduler_tick()` 函数
    5.  更新墙上时间，放在 `xtime` 中
    6.  计算平均负载值


## 实际时间 {#实际时间}

定义于 `kernel/time/timekeeping.c`

```c
struct timespec xtime;
```

读写 `xtime` 需要使用 `xtime_lock`,该锁为 `seqlock` 锁。

更新首先要申请一个 `seqlock`:

```c
write_seqlock(&xtime_lock);
...
write_sequnlock(&xtime_lock);
```

读取也要使用 `read_seqbegin()` 和 `read_seqretry()` 函数。

从用户空间获取墙上时间的主要接口为 `gettimeofday()` . 设置时间 `settimeofday()`,
需要 `CAP_SYS_TIME` 权能。


## 定时器 {#定时器}

也称动态定时器或内核定时器，管理内核流逝的时间的基础。


### 使用定时器 {#使用定时器}

由 `timer_list` 表示，定义在 `<linux/timer.h>` 中。

```c
struct timer_list {
	/*
	 * All fields that change during normal runtime grouped to the
	 * same cacheline
	 */
	struct list_head entry; /* 定时器入口 */
	unsigned long expires;  /* 以 jffies 为单位的定时值 */
	struct tvec_base *base; /* 定时器内部值 */

	void (*function)(unsigned long); /* 定时器处理函数 */
	unsigned long data;    /* 长整型参数 */
...
};
```

使用过程：定义 -> 初始化 -> 定义时间点，参数，处理函数 -> 激活定时器。

定时器事件在超时后会执行，但也可能推迟到下一次节拍才能运行。所以不能实现硬实时任务。

修改已激活的定时器： `mod_timer()`, 也可以操作未激活的定时器，此时还会激活该定时器。

删除定时器： `del_timer()`, 已超时的不需要调用，会自动删除。在多处理器上，需要等待可能在其它处理器上运行的定时器处理程序都退出，使用： `del_timer_sync()`


## 延迟执行 {#延迟执行}


### 忙等待 {#忙等待}

在想要延迟的时间是节拍的整数倍，或者精确率要求不高时使用。


### 短延迟 {#短延迟}

多发生在和硬件同步时，需要短暂等待某个动作完成。内核提供了处理 `ms`, `ns`, `us`
级别的延迟函数。

```c
void udelay(unsigned long usecs);
void ndelay(unsigned long usecs);
void mdelay(unsigned long usecs);
```


### shedule\_timeout() {#shedule-timeout}

该方法会让需要延迟执行的任务睡眠到指定的延迟时间点，但不能保证睡眠时间正好等于指定的延迟时间，只能尽量使睡眠时间接近指定的延迟时间。
