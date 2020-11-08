+++
title = "kvmtool正式运行kvm"
author = ["Jerling"]
description = ""
date = 2020-11-01
lastmod = 2020-11-01
tags = ["lkvm",  "linux", "kvm"]
categories = ["虚拟化"]
type = "post"
draft = false
author_homepage = "https://github.com/Jerling"
toc = "true"
+++

## 前言
在上一篇文章中介绍了 kvmtool 的 run 命令的初始化流程，其中涉及多个子模块的初始化，包括 cpu、内存已经外设等。这些都是正式启动系统构建的虚拟硬件环境，而这篇文章将介绍基于之前初始化的硬件环境，运行一个虚拟系统。

## run 命令的执行流程
接着上一篇的分析：
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
跟着 `kvm_cmd_run_work` 继续运行：
```c
static int kvm_cmd_run_work(struct kvm *kvm)
{
	int i;

	for (i = 0; i < kvm->nrcpus; i++) {
		if (pthread_create(&kvm->cpus[i]->thread, NULL, kvm_cpu_thread, kvm->cpus[i]) != 0)
			die("unable to create KVM VCPU thread");
	}

	/* Only VCPU #0 is going to exit by itself when shutting down */
	if (pthread_join(kvm->cpus[0]->thread, NULL) != 0)
		die("unable to join with vcpu 0");

	return kvm_cpu__exit(kvm);
}
```
可以看到，kvmtool 基于之前构建的cpu环境，为每一个虚拟 cpu 创建一个 vcpu 线程用于启动虚拟机。

## 启动 vcpu 线程
上面的 `kvm_cpu_thrad` 做的是就一件事，即 `kvm_cpu__start`。
```c
int kvm_cpu__start(struct kvm_cpu *cpu)
{
	sigset_t sigset;

	sigemptyset(&sigset);
	sigaddset(&sigset, SIGALRM);

	pthread_sigmask(SIG_BLOCK, &sigset, NULL);

	signal(SIGKVMEXIT, kvm_cpu_signal_handler);
	signal(SIGKVMPAUSE, kvm_cpu_signal_handler);
	signal(SIGKVMTASK, kvm_cpu_signal_handler);

	kvm_cpu__reset_vcpu(cpu);

	if (cpu->kvm->cfg.single_step)
		kvm_cpu__enable_singlestep(cpu);

	while (cpu->is_running) {
		if (cpu->needs_nmi) {
			kvm_cpu__arch_nmi(cpu);
			cpu->needs_nmi = 0;
		}

		if (cpu->task)
			kvm_cpu__run_task(cpu);

		kvm_cpu__run(cpu);
...
}
```
首先是设置了信号处理函数，接着复位 vcpu 的上下文、设置 nmi 以及运行前置 task, 最后通过 kvm_cpu__run 进入linux 的 kvm 子系统运行虚拟机。

其中复位 vcpu 的上下文主要是设置 vcpu 的段选择子、ip、sp 等寄存器，其中段选择子指向启动扇区的某个地址，而这个地址在初始化的时候就设置为虚拟机的起始地址即可。

## KVM_RUN
通过 kvm 提供的 KVM_RUN 命令运行虚拟机：
```c
void kvm_cpu__run(struct kvm_cpu *vcpu)
{
	int err;

	if (!vcpu->is_running)
		return;

	err = ioctl(vcpu->vcpu_fd, KVM_RUN, 0);
	if (err < 0 && (errno != EINTR && errno != EAGAIN))
		die_perror("KVM_RUN failed");
}
```

## 结束语
可以看到，其实启动虚拟机的步骤并不复杂，复杂的是构建一个虚拟的硬件环境。启动虚拟机之后基本就不用 kvmtool 管了，kvm 子系统会维护虚拟机的运行。只有当
虚拟机出错退出时，才有可能需要 kvmtool 进行处理，这部分内容在之后的文章再聊。

现在我们基本上对 kvmtool 启动一个虚拟机的流程有了大致的了解，接下来的文章将深入到 kvm 子系统的内部吗，看看 kvm 在创建虚拟机的时候做了什么事，在运行虚拟机的时候又做了什么事，虚拟机异常退出时又需要做什么继续让虚拟机继续运行。

## kvm 系列 {#kvm-系列}

00 : [kvmtool 启动 linux 内核](/post/使用kvmtool启动linux/)  
01 : [制作根文件系统](/post/制作根文件系统/)  
02 : [kvmtool 开启网络功能](/post/kvmtool_network/)  
03 : [kvmtool 数据结构](/post/kvmtool_datastruct/)  
04 : [kvmtool 数据结构](/post/lkvm的初始化/)  