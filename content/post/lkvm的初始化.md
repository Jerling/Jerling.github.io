+++
title = "kvmtool 的初始化"
author = ["Jerling"]
description = ""
date = 2020-11-01
lastmod = 2020-11-01
tags = ["kvm", "linux", "lkvm"]
categories = ["虚拟化"]
type = "post"
draft = false
author_homepage = "https://github.com/Jerling"
toc = "true"
+++

## 前言
在 kvm 学习的前一篇文章 [kvmtool 中的数据结构](/post/kvmtool_datastruct) 介绍了 kvmtool 中常用的数据结构。接下来这篇文章介绍在 kvmtool 是如何初始化这些数据结构，并搭建一个基本的虚拟化硬件环境，这也是进入虚拟世界的准备工作。

## kvmtool 命令介绍
在进入讲解初始化之前，先简单地介绍一下 lkvm 提供的内置命令。

回想一下，在本系列第一篇文章的时候，我们是不是参考文档里的命令启动了一个简单的虚拟机。类似这样的：
```sh
lkvm run --kernel ../x86/bzImage --disk ../initrd.img
```
上面只是个例子，不一定和之前的一模一样。但是我们可以很明显的看到，这里使用了 kvmtool 的 run 命令。但是实际上， kvmtool 提供了好几个命令，
几乎满足我们控制虚拟机的所有操作。下面通过万能的 `--help` 来看都有哪些命令吧。
```sh
$ lkvm --help

 To start a simple non-privileged shell run 'lkvm run'

usage: lkvm COMMAND [ARGS]

 The most commonly used lkvm commands are:
   run       Start the virtual machine
   setup     Setup a new virtual machine
   pause     Pause the virtual machine
   resume    Resume the virtual machine
   version   Print the version of the kernel tree kvm tools
   list      Print a list of running instances on the host.
   debug     Print debug information from a running instance
   balloon   Inflate or deflate the virtio balloon
   stop      Stop a running instance
   stat      Print statistics about a running instance
   sandbox   Run a command in a sandboxed guest

 See 'lkvm help COMMAND' for more information on a specific command.
```
每个命令都有基本的使用介绍，比如 `run` 就是启动一个虚拟机。

## run 命令之前发生了什么
现在我们先看看 `run` 的基本流程，那么其他命令的流程也就可以类推了。

首先在使用    `run` 的时候，`run` 是通过参数传递给 lkvm 的，看看 lkvm 解析 `run` 的过程：
```c
static int handle_kvm_command(int argc, char **argv)
{
	return handle_command(kvm_commands, argc, (const char **) &argv[0]);
}

int main(int argc, char *argv[])
{
	kvm__set_dir("%s/%s", HOME_DIR, KVM_PID_FILE_PATH);

	return handle_kvm_command(argc - 1, &argv[1]);
}
...
int handle_command(struct cmd_struct *command, int argc, const char **argv)
{
	struct cmd_struct *p;
	const char *prefix = NULL;
	int ret = 0;
...
	ret = p->fn(argc - 1, &argv[1], prefix);
	if (ret < 0) {
		if (errno == EPERM)
			die("Permission error - are you root?");
	}

	return ret;
}
...
struct cmd_struct *kvm_get_command(struct cmd_struct *command,
		const char *cmd)
{
	struct cmd_struct *p = command;

	while (p->cmd) {
		if (!strcmp(p->cmd, cmd))
			return p;
		p++;
	}
	return NULL;
}
...
struct cmd_struct kvm_commands[] = {
	{ "pause",	kvm_cmd_pause,		kvm_pause_help,		0 },
	{ "resume",	kvm_cmd_resume,		kvm_resume_help,	0 },
	{ "debug",	kvm_cmd_debug,		kvm_debug_help,		0 },
	{ "balloon",	kvm_cmd_balloon,	kvm_balloon_help,	0 },
	{ "list",	kvm_cmd_list,		kvm_list_help,		0 },
	{ "version",	kvm_cmd_version,	NULL,			0 },
	{ "--version",	kvm_cmd_version,	NULL,			0 },
	{ "stop",	kvm_cmd_stop,		kvm_stop_help,		0 },
	{ "stat",	kvm_cmd_stat,		kvm_stat_help,		0 },
	{ "help",	kvm_cmd_help,		NULL,			0 },
	{ "setup",	kvm_cmd_setup,		kvm_setup_help,		0 },
	{ "run",	kvm_cmd_run,		kvm_run_help,		0 },
	{ "sandbox",	kvm_cmd_sandbox,	kvm_run_help,		0 },
	{ NULL,		NULL,			NULL,			0 },
};
```
可以看到，在解析的时候，它是从全局变量 `kvm_commands` 里取得的，通常如果取不到上述的命令，默认会打印 help 信息。

接下来通过字符判断，会执行 `run` 对应的函数 `kvm_cmd_run`。

## 正式的 run 命令
通过上一章节的追溯，我们知道 `run` 命令的入口函数是 `kvm_cmd_run`。看看这个函数是如何实现的：
```c
int kvm_cmd_run(int argc, const char **argv, const char *prefix)
{
	int ret = -EFAULT;
	struct kvm *kvm;

	kvm = kvm_cmd_run_init(argc, argv);
	if (IS_ERR(kvm))
		return PTR_ERR(kvm);

	ret = kvm_cmd_run_work(kvm);
	kvm_cmd_run_exit(kvm, ret);

	return ret;
}
```
可以看到，run 命令主要由三部分组成， 分别是 `init` `run` 和 `exit` 。其中 `init` 就是本篇文章要介绍的。

## 初始化流程
该函数的代码比较多，就不在这里贴了。直接分析里面的主要结构的初始化机制。

### 构建配置
kvmtool 提供了一个配置结构体，内容可以参考上篇文章。在正式进行初始化之前，需要构建一个完整的配置，大部分使用默认配置即可。

#### kvm 初始化
由于配置需要保存在 kvm 结构体中传递给各个初始化模块。因此需要先构建一个 kvm ：
```c
struct kvm *kvm__new(void)
{
	struct kvm *kvm = calloc(1, sizeof(*kvm));
	if (!kvm)
		return ERR_PTR(-ENOMEM);

	mutex_init(&kvm->mem_banks_lock);
	kvm->sys_fd = -1;
	kvm->vm_fd = -1;
...
}
```
首先分配动态内存用于存贮 kvm 结构体，这里只需要将 sys_fd 和 vm_fd 初始化为 -1 即可。这两个 fd 是控制虚拟机的接口，必须初始化为无效值。

接下来就是根据命令行参数，逐个的修改配置的值。

#### 内核镜像
默认情况下，会在搜索以下几个文件：
```c
static const char *default_kernels[] = {
	"./bzImage",
	"arch/" BUILD_ARCH "/boot/bzImage",
	"../../arch/" BUILD_ARCH "/boot/bzImage",
	NULL
};
```
#### CPU 数量
默认情况下内存的值等于当前系统可用的 cpu 数。

#### 内存大小
默认等于 `mem = 64 * (cpus + 3) MB`。当然最后还是要和物理内存进行比较，取两者的较小者。

#### 外设
接下来就是外设的初始值，包括串口、网络配置、显示方式等。

#### 内核启动参数
当然还需要构建 内核的启动参数，用于告诉内核需要启动哪些东西，如根文件系统等。

### 正式初始化
在上述配置初构建好之后，开始进入一系列的模块初始化。

#### kvm 初始化
1. 首先判断主机 CPU 是否支持硬件虚拟化
2. 打开 kvm 子系统提供的系统接口 `/dev/kvm`
3. 根据系统接口获取 kvm 的版本号，和 kvmtool 支持的版本进行比较，看是否匹配
4. 接着调用 KVM_CREATE_VM 命令创建一个虚拟机
5. 检查主机系统是否支持kvm扩展
6. 接着进行架构初始化，包括申请虚拟机需要的内存和终端芯片
7. 初始化虚拟机的内存

#### IPC初始化
1. 首先在自己的本地创建一个Unix 域 socket 进行监听，并用 epoll 进行管理
2. 注册一系列用于处理来自其它进程的消息，如暂停、重启等。

#### IOEVENT 初始化
1. 检查 kvm 是否支持  ioeventfd 扩展
2. 同理使用 epoll 监控 ioevntfd 请求

#### cpu 初始化
1. 根据配置和 kvm 能提供的vcpu资源设置最大 cpus 数量
2. 接着分别初始化每一个 cpu

#### 其它模块初始化
1. 对虚拟机的中断芯片进行初始化
2. pci 设备初始化
3. io 端口初始化
4. 对键盘进行初始化
5. 终端初始化
6. 串口初始化
7. 实时时钟初始化
8. p9协议网络初始化
9. 虚拟网络设备初始化
10. 虚拟控制台初始化
11. 虚拟 scsi 设备初始化
12. 虚拟块设备初始化
13. 多处理器规范表初始化
14. 帧率初始化

## 结束语
这篇文章初步梳理了在正式开启虚拟机之前，kvmtool 所做的一些准备工作。可以看到，整个初始化流程的的步骤是比较多。由于篇幅原因，这里也不细分析各个子模块的初始化流程。后续如果有时间，再继续探索各个子模块。

## kvm 系列 {#kvm-系列}

00 : [kvmtool 启动 linux 内核](/post/使用kvmtool启动linux/)  
01 : [制作根文件系统](/post/制作根文件系统/)  
02 : [kvmtool 开启网络功能](/post/kvmtool_network/)  
03 : [kvmtool 数据结构](/post/kvmtool_datastruct/)  