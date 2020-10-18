+++
title = "Linux Arm64 下的早期打印"
author = ["Jerling"]
description = "Description"
date = 2020-10-18
lastmod = 2020-10-18
tags = ["arm64", "linux", "earycon"]
categories = ["内核调试"]
type = "post"
draft = false
author_homepage = "https://github.com/Jerling"
toc = "true"
+++

## 前言

最近遇到一个 Linux 无法启动的问题，没有任何输出信息。为了摸清到底是
卡在哪儿了，需要查看 Linux 的启动消息。正常情况下，Linux 的 `printk`
函数是基于 console 的，但是在 linux 的启动过程中总有个初始化顺序。
因此在 console 初始化之前，所有的 printk 函数的数据都存在内核缓冲区
里，当 console 初始化之后，这些消息可能就会显示到控制台中。

为了显示早期的 Linux 启动流程，打开 linux 的 earycon 功能即可。

本篇文章不会探讨 earycon 的实现原理，只讲如何使用。因为原理网上已经
有很多博客写过了。

## 打开 earycon 宏控

```cpp
CONFIG_SERIAL_EARLYCON
CONFIG_OF_EARLY_FLATTREE
```
## 使用 earycon 

earycon 的使用也是非常简单，在串口对应的 dts 文件的 chosen 节点中的 bootargs
中加入 "earycon" 开启，之后的 printk 函数将直接使用 earycon 直接写入控制台中。

这里本文使用 qemu 进行实验，在 cmdline 参数中加入 "earycon" 也是可行的。

## 实验结果

### 问题定位

通过使用正常的镜像进行定位，使用一个死循环模拟卡住现象。实验发现控制台能打印小是在
_`head.S ->start_kernel->arch_call_rest_init->rest_init` 的_ `schedule_preempt_disabled`
函数前后。也就是说，如果卡在这个函数之后，是会正常打印信息的。而在这个函数之前卡住
，控制台信息依旧会存在缓冲区里，而不会打印在控制台上。

### 实验结果

![](/images/Snipaste_2020-10-18_14-15-13.png)

![](/images/Snipaste_2020-10-18_14-16-02.png)

## 结束语

虽然 earycon 可以解决早期打印问题，但是 printk 函数无法使用在 head.S 中，如果
如要使用汇编级的早期打印，可能需要自己适配一个汇编级的打印函数。不过好在 Head.S
的工作不复杂，所以代码也比较少。Linux 的启动问题一般都会在 C 语言层面，所以
对于定位问题已经足够。

## 参考

[1] [http://www.lujun.org.cn/?p=3511](http://www.lujun.org.cn/?p=3511)  
[2] [https://blog.csdn.net/ooonebook/article/details/52654191](https://blog.csdn.net/ooonebook/article/details/52654191)
