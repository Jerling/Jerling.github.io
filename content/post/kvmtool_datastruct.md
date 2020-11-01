+++
title = "kvmtool 中的数据结构"
author = ["Jerling"]
description = "kvmtool"
date = 2020-10-12
lastmod = 2020-10-12
tags = ["kvm", "kvmtool"]
categories = ["虚拟化"]
type = "post"
draft = false
author_homepage = "https://github.com/Jerling"
toc = "true"
+++

## 前言

本文是 kvm 虚拟化系列的第 4 篇，前三篇介绍了 kvmtool 的基本使用以及linux 根文件系统的制作。
接下来我们将正式进入副主题，也就是 kvm 的用户态管理程序，即本系列第一篇的 kvmtool。
最后才是 kvm 子系统。kvmtool 中涉及的数据结构主要有 kvm/kvm_arch/kvm_config 等。

## kvm

定义：
```cpp
struct kvm {
    struct kvm_arch        arch;               /* 和 cpu 架构相关的结构体 */
    struct kvm_config      cfg;                /* kvm 配置结构体 */
    int                    sys_fd;             /* 用于系统 ioctls(), i.e. /dev/kvm */
    int                    vm_fd;              /* 用于虚拟机 ioctls() */
    timer_t                timerid;            /* Posix 定时器，用于中断 */

    int                    nrcpus;             /* 运行的 cpu 数量 */
    struct kvm_cpu        **cpus;

    u32                    mem_slots;          /* 内存槽， 用于 KVM_SET_USER_MEMORY_REGION */
    u64                    ram_size;           /* 内存大小 */
    void                   *ram_start;         /* 内存起始地址 */
    u64                    ram_pagesize;       /* 内存页大小 */
    struct mutex           mem_banks_lock;     /* 内存互斥锁 */
    struct list_head       mem_banks;          /* 内存链表 */

    bool                   nmi_disabled;       /* 是否禁用 NMI */
    bool                   msix_needs_devid;   /* 是否需要 devid */

    const char             *vmlinux;           /* 内核镜像 */
    struct disk_image      **disks;            /* 磁盘镜像指针数组 */
    int                    nr_disks;           /* 磁盘个数 */

    int                    vm_state;           /* 虚拟机状态 */

#ifdef KVM_BRLOCK_DEBUG
    pthread_rwlock_t       brlock_sem;         /* 读写信号量 */
#endif
};
```
kvm 是 kvmtool 中最重要的数据结构之一，它描述了虚拟机所需要的所有硬件、配置以及虚拟机的状态等。
接下来以 kvm 为中心，介绍其相关的结构体。

## kvm_arch

kvm_arch 结构体用于描述CPU特定架构的信息，以 x86 为例：

定义：
```cpp
struct kvm_arch {
    u16                       boot_selector;    /* 启动扇区 */
    u16                       boot_ip;          /* ip 地址 */
    u16                       boot_sp;          /* sp 地址 */

    struct interrupt_table    interrupt_table;  /* 中断向量表 */
};
```

## kvm_config

定义：
```cpp
struct kvm_config {
    struct kvm_config_arch arch;                            /* 特定架构的配置 */
    struct disk_image_params disk_image[MAX_DISK_IMAGES];   /* 磁盘参数配置 */
    struct vfio_device_params *vfio_devices;                /* vfio 参数配置 */
    u64 ram_size;                                           /* 内存大小 */
    u8  image_count;                                        /* 镜像数量 */
    u8 num_net_devices;                                     /* 网络设备数量 */
    u8 num_vfio_devices;                                    /* vfio 设备数量 */
    bool virtio_rng;                                        /* virtio 是否随机 */
    int active_console;                                     /* 活动控制台 */
    int debug_iodelay;                                      /* 调试 io 配置 */
    int nrcpus;                                             /* cpu 数量 */
    const char *kernel_cmdline;                             /* 内核启动参数 */
    const char *kernel_filename;                            /* 内核文件 */
    const char *vmlinux_filename;                           /* 解压内核文件 */
    const char *initrd_filename;                            /* initrd 文件 */
    const char *firmware_filename;                          /* fireware 文件 */
    const char *flash_filename;                             /* flash 文件 */
    const char *console;                                    /* console 文件 */
    const char *dev;                                        /* dev 子系统 */
    const char *network;                                    /* 网络子系统 */
    const char *host_ip;                                    /* 主机 ip */
    const char *guest_ip;                                   /* 客户 ip */
    const char *guest_mac;                                  /* 客户 mac */
    const char *host_mac;                                   /* 主机 mac */
    const char *script;                                     /* 脚本 ? */
    const char *guest_name;                                 /* 客户机名字 */
    const char *sandbox;                                    /* 沙盒 */
    const char *hugetlbfs_path;                             /* 大页路径 */
    const char *custom_rootfs_name;                         /* 自定义 rootfs */
    const char *real_cmdline;                               /* 实际 cmdline */
    struct virtio_net_params *net_params;                   /* virtio 网络参数 */
    bool single_step;                                       /* 单步调试 */
    bool vnc;                                               /* 显示方式： vnc/gtk/sdl */
    bool gtk;
    bool sdl;
    bool balloon;                                           /* ? */
    bool using_rootfs;                                      /* 正在使用的 rootfs */
    bool custom_rootfs;                                     /* 是否自定义 rootfs */
    bool no_net;                                            /* 是否不需要网络 */
    bool no_dhcp;                                           /* 是否不使用 dhcp */
    bool ioport_debug;                                      /* io 端口调试 */
    bool mmio_debug;                                        /* mmio 调试 */
};
```

从配置结构体的定义可以看出，包含了虚拟机的所需要的所有配置信息，如架构、调试、外设参数等。

## cpu

用于描述 vcpu 的上下文信息。

定义：
```cpp
struct kvm_cpu {
    pthread_t                           thread;        /* VCPU 线程 */

    unsigned long                       cpu_id;        /* cpu id */

    struct kvm                          *kvm;          /* 指向 KVM */
    int                                 vcpu_fd;       /* 用于 VCPU ioctls() */
    struct kvm_run                      *kvm_run;      /* 运行时上下文 */
    struct kvm_cpu_task                 *task;         /* 任务 */

    struct kvm_regs                     regs;          /* kvm 通用寄存器 */
    struct kvm_sregs                    sregs;         /* kvm 系统寄存器 */
    struct kvm_fpu                      fpu;           /* kvm 浮点处理器 */

    struct kvm_msrs                     *msrs;         /* ? */

    u8                                  is_running;    /* 是否正在运行 */
    u8                                  paused;        /* 暂停 */
    u8                                  needs_nmi;     /* 是否有 NMI */

    struct kvm_coalesced_mmio_ring      *ring;         /* 模拟环形io总线 */
};
```
kvm_run 结构体是 kvm 子系统的数据结构之一，后续文章再详细讲解。
kvm_regs/kvm_sregs/kvm_fpu/kvm_msrs 都是用于保存从内核态获取的 kvm 子系统中的上下文。
kvm_coalesced_mmio_ring 这个结构体用于分配环形 io 内存地址。

### kvm_cpu_task

定义：
```cpp
struct kvm_cpu_task {
    void (*func)(struct kvm_cpu *vcpu, void *data);  /* 任务函数指针 */
    void *data;                                      /* 任务参数 */
};
```

这个结构的作用在后续章节详细分析。

## disk_image

磁盘镜像文件数据结构。

定义：
```cpp
struct disk_image {
    int                             fd;                                      /* 描述符 */
    u64                             size;                                    /* 大小 */
    struct disk_image_operations    *ops;                                    /* 操作函数 */
    void                            *priv;                                   /* 优先级 */
    void                            *disk_req_cb_param;                      /* 请求回调函数参数 */
    void                            (*disk_req_cb)(void *param, long len);   /* 请求回调函数  */
    bool                            readonly;                                /* 只读 */
    bool                            async;                                   /* 支持异步 */
#ifdef CONFIG_HAS_AIO
    io_context_t                    ctx;                                     /* 上下文 */
    int                             evt;                                     /* 异步事件 */
    pthread_t                       thread;                                  /* 线程 */
    u64                             aio_inflight;                            /* ? */
#endif /* CONFIG_HAS_AIO */
    const char                      *wwpn;                                   /* ? */
    const char                      *tpgt;                                   /* ? */
    int                             debug_iodelay;                           /* 调试 io */
};
```

## 结束语
这篇文章以基础数据结构 kvm 为中心，介绍了相关的数据结构。

## kvm 系列 {#kvm-系列}

00 : [kvmtool 启动 linux 内核](/post/使用kvmtool启动linux/)  
01 : [制作根文件系统](/post/制作根文件系统/)  
02 : [kvmtool 开启网络功能](/post/kvmtool_network/)