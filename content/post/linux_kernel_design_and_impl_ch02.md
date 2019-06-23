+++
title = "linux 设计与实现 — 进程管理"
author = ["Jerling"]
description = "Short description"
date = 2019-05-19T21:02:15+08:00
lastmod = 2019-05-24T22:29:10+08:00
tags = ["linux内核", "进程管理"]
categories = ["学习笔记"]
type = "post"
draft = false
author_homepage = "https://github.com/Jerling"
toc = true
+++

## 进程 {#进程}

-   进程：处于执行期的程序的实时结果
    -   文件描述符
    -   挂起的信号
    -   内核内部数据
    -   处理器状态
    -   一个或多个内存映射地址
        一个或多个执行线程
-   (执行)线程： 进程中的活动对象
    -   程序计数器
    -   线程栈
    -   寄存器
    -   私有数据


## 进程描述符及任务结构 {#进程描述符及任务结构}

内核把进程的列表存放在任务队列中，队列中的条目为 `task_struct` 类型，称为进程描述
符，定义在 `<linux/sched.h>` 中。


### 分配进程描述符 {#分配进程描述符}

Linux通过 `slab` 分配器分配 `task_struct` 结构，达到对象复用和缓存着色的目的。在
2.6 版本之前，各个进程的 `task_struct` 存放在它们的内核栈的尾部，这样是为了寄存
器少(如X86)的硬件体系结构只需通过栈指针就可以计算出其地址，避免专门的寄存器记录。
现在使用 `slab` 分配器动态生成 `task_struct` ,所以只需在栈低（向下增长）或栈顶
（向上增长）创建一个 `thread_info` 即可，该结构放在 `<asm/thread_info.h>` 中。

{{< figure src="/images/Snipaste_2019-05-20_22-03-50.png" >}}


### 进程描述符的存放 {#进程描述符的存放}

内核通过 PID 标识每个进程，在 `<linux/threads.h>` 中定义 PID 的最大值。

访问任务通常需要访问其 `task_struct` 指针，为了加快找到当前进程的 `task_struct`,
使用 current 宏保存。对于不同的硬件体系结构，实现方式不一样。

-   寄存器多：使用专门的寄存器存放
-   寄存器少：在内核栈尾创建 `thread_info`,通过计算偏移量查找


### 进程状态 {#进程状态}

`task_struct` 中的 `state` 描述进程当前的状态。

-   TASK\_RUNNING: 可执行的；正在执行或运行队列中等待
-   TASK\_INTERRUPTIBLE: 可中断睡眠
-   TASK\_UNINTERRUPTIBLE: 不可中断
-   \_\_TASK\_TRACED: 被跟踪
-   \_\_TASK\_STOPPED: 停止，收到 SIGSTOP,SIGSTP,SIGINT,SIGTOU 等信号时

{{< figure src="/images/Snipaste_2019-05-20_22-24-50.png" >}}


### 设置当前进程状态 {#设置当前进程状态}

```cpp
// 调整状态
set_task_state(task, state);

// set_current_state(state) = set_task_state(current, state);

// 指定状态
task->state = state;
```


### 进程上下文 {#进程上下文}

进程切换恢复到某进程所需要的所有信息。


### 进程家族树 {#进程家族树}

系统中每个进程都有一个父进程，也可以拥有零个或多个子进程。指向父进程的指针为
`parent` 指针。还有一个 `children` 的子进程列表。

init 进程的进程描述符是作为 `init_task` 静态分配的。

```cpp
// 访问父进程
struct task_struct *my_parent = current->parent;

// 依次访问子进程
struct task_struct *task;
struct list_head *list;
list_for_each(list, &current->children){
  task = list_entry(list, struct task_struct, sibling);
  /* task 指向当前的某个子进程 */
}

// 访问所有进程
struct task_struct *task;
for(task=current; task != &init_task; task = task->parent){
  list_entry(task->tasks.next, struct task_struct, tasks);
  list_entry(task->tasks.prev, struct task_struct, tasks);
}

// 访问整个任务队列
struct task_struct *task;
for_each_process(task){
  ...
}
```


## 进程创建 {#进程创建}

-   其它系统： spawn 机制，在新的地址空间里创建进程，读入可执行文件，最后开始执行
-   Unix系统： 分解为两步： `fork` 和 `exec`
    -   fork 拷贝当前进程创建子进程
    -   exec 读取可执行文件并载入地址空间运行


### 写时拷贝 {#写时拷贝}

一种推迟甚至免拷贝数据的即技术，内核创建紧进程时并不复制整个进程地址空间，而是让
父子共享同一个拷贝，在需要写入的时候数据在复制，从而各个进程有各自的拷贝。


### fork {#fork}

Linux通过 clone() 实现 fork(). fork(),vfork() 以及 \_\_clone() 库函数通过各自所需
的参数标志调用 clone(), 然后由 clone() 调用 do\_fork().

do\_fork 完成大部分工作，定义在 `kernel/fork.c` , 完成如下工作：

1.  dup\_task\_struct: 创建内核栈， thread\_info 和 task\_struct. 这些和父进程一样。
    描述符也一样。
2.  检查：用户进程数未超分配的资源限制
3.  子进程开始与父进程区分开来，进程描述符中许多值设为0或初始值。 task\_struct 中的
    大多数据未改。
4.  状态设为 TASK\_UNINTERRUPTIBLE, 确保不运行
5.  copy\_process() 调用 copy\_flags() 更新 task\_struct 的 flags 成员。包括用户权限
    标志，还没有调用 exec 的标志等
6.  调用 alloc\_pid() 分配有效 PID
7.  根据 clone() 标志， copy\_process 拷贝或共享打开的文件，文件系统信息，信号处
    理函数，进程地址空间以及命名空间等
8.  copy\_process 扫尾并返回指向子进程的指针

回到 do\_fork(),如果 copy\_process() 函数返回成功，子进程被唤醒并运行。内核有意先
运行子进程，因为子进程很可能执行 exec, 这样可以避免 COW 开销。


### vfork {#vfork}

vfork() 现在几乎不用了，因为有了 COW, 它的作用就是将子进程作为一个单独的线程在它
的地址空间运行，父进程被阻塞，直到子进程推出。主要用于马上调用 exec 的情况，用来
避免拷贝。

1.  调用 copy\_process 时， task\_struct 的 vfor\_done 置为 NULL
2.  执行 do\_fork 时，如果给定标志， vfork\_done 会指向特定地址
3.  子进程执行，父进程等待
4.  调用 mm\_release() , 子进程退出地址空间
5.  回到 do\_fork, 父进程唤醒


### 线程实现 {#线程实现}


#### 创建线程 {#创建线程}

和创建普通进程一样，只是参数标志不一样。

```cpp
clone(CLONE_VM|CLONE_FS|CLONE_FILES|CLONE_SIGHAND, 0);
```

{{< figure src="/images/Snipaste_2019-05-24_00-01-55.png" >}}


#### 内核线程 {#内核线程}

内核线程通过 kthreadd 内核进程调用 kthread\_create 创建。定义在 `<linux/kthread.h>`
中。

```cpp
struct task_struct *kthread_create(int (*threadfn)(void *data),
                                   void *data,
                                   const char namefmt[],
                                   ...);
```

新创建的线程处于不可运行状态，需调用 `wake_up_process()` 唤醒。

创建新线程并运行：

```cpp
struct task_struct *kthread_run(int (*threadfn)(void *data),
                                void *data,
                                const char namefmt[],
                                ...);
```

该例程通过宏实现的，只是简单的调用 kthread\_create 和 wake\_up\_process 函数.

内核线程启动后会一直运行，直到调用 do\_exit() 退出，或者内核其他部分调用 kthread\_stop() 退出。

```cpp
int kthread_stop(struct task_struct *k);
```


### 进程终止 {#进程终止}

进程终结的大部分任务由 do\_exit() 完成，定义在 `<kernel/exit.c>`

1.  将 task\_struct 中的标志设置为 PF\_EXITING.
2.  del\_timer\_sync 删除任一内核定时器，确保没有定时器在排队，也没有定时器处理程序正在运行
3.  acct\_update\_integrals() 输出统计信息
4.  exit\_mm() 释放占用的 mm\_struct. 没有进程占用就释放
5.  sem\_exit() , 如果进程排队等候 IPC 信号则离开队列
6.  exit\_files()、exit\_fs() 递减文件描述符和文件系统的引用计数
7.  将 task\_struct 中的 exit\_code 设为 exit() 中的退出码
8.  exit\_notify() 向父进程发送信号，給子进程找父进程，一般为线程组其他线程或 init 进程，并设置状态为 EXIT\_ZOMBIE
9.  schedule() 切换到新的进程
