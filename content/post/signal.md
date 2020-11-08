+++
title = "Linux 中的信号处理流程"
author = ["Jerling"]
description = "信号处理"
date = 2020-11-08
lastmod = 2020-11-08
tags = ["linux", "signal", "sigreturn"]
categories = ["信号处理"]
type = "post"
draft = false
author_homepage = "https://github.com/Jerling"
toc = "true"
+++

## 前言
信号处理是操作系统很重要的工作之一，信号是一种异步软中断，在进程间通信中有着很大的应用。
例如，你在运行一个程序，它陷入了死循环，无法对其进行操作时，就可以通过 kill 命令向该进程
发送一个信号杀死该进程，从而结束死循环。

## 小试牛刀
首先我们以一个简单的例子来说明信号的捕获以及处理，对应代码如下：
```c
#include <stdio.h>
#include <signal.h>

void test_hander(int scno) {
	(void)printf("Get a signal, scno=%d\n", scno);
}

int main(int argc, char const* argv[])
{
	(void)signal(SIGIO, test_hander);
	(void)raise(SIGIO);
	(void)printf("Test end\n");
	return 0;
}
```
结果如下：
![](/images/Snipaste_2020-11-08_20-31-21.png)

接着，使用 strace 跟踪一下系统调用：
```sh
rt_sigaction(SIGIO, {sa_handler=0x56112336d169, sa_mask=[IO], sa_flags=SA_RESTORER|SA_RESTART, sa_restorer=0x7f9f17cb36a0}, {sa_handler=SIG_DFL, sa_mask=[], sa_flags=0}, 8) = 0
rt_sigprocmask(SIG_BLOCK, ~[RTMIN RT_1], [], 8) = 0
getpid()                                = 11913
gettid()                                = 11913
tgkill(11913, 11913, SIGIO)             = 0
rt_sigprocmask(SIG_SETMASK, [], NULL, 8) = 0
--- SIGIO {si_signo=SIGIO, si_code=SI_TKILL, si_pid=11913, si_uid=1000} ---
fstat(1, {st_mode=S_IFCHR|0620, st_rdev=makedev(0x88, 0x1), ...}) = 0
brk(NULL)                               = 0x561124bdc000
brk(0x561124bfd000)                     = 0x561124bfd000
write(1, "Get a signal, scno=29\n", 22Get a signal, scno=29
		) = 22
rt_sigreturn({mask=[]})                 = 0
write(1, "Test end\n", 9Test end
		)               = 9
exit_group(0)                           = ?
+++ exited with 0 +++
```
这里只截取主要的部分，其它的不用关注。

可以看到，信号处理的大致流程是这样的：注册处理函数(rt_sigaction)->发送信号(tgkill)
->信号处理(sa_handler)->信号返回(rt_sigreturn)。

## 注册信号处理函数
信号处理函数的的参数为信号数值，返回值为 void，因此简单实现一下对应的处理函数即可。
如上述的 `test_hander`。

通过库函数 `signal` 将处理函数注册到内核的对应信号处理上，具体通过 `rt_sigaction`
系统调用实现。

```c
/**
 *  sys_rt_sigaction - alter an action taken by a process
 *  @sig: signal to be sent
 *  @act: new sigaction
 *  @oact: used to save the previous sigaction
 *  @sigsetsize: size of sigset_t type
 */
SYSCALL_DEFINE4(rt_sigaction, int, sig,
    const struct sigaction __user *, act,
    struct sigaction __user *, oact,
    size_t, sigsetsize)
{
  struct k_sigaction new_sa, old_sa;
  int ret;

  /* XXX: Don't preclude handling different sized sigset_t's.  */
  if (sigsetsize != sizeof(sigset_t))
    return -EINVAL;

  if (act && copy_from_user(&new_sa.sa, act, sizeof(new_sa.sa)))
    return -EFAULT;

  ret = do_sigaction(sig, act ? &new_sa : NULL, oact ? &old_sa : NULL);
  if (ret)
    return ret;

  if (oact && copy_to_user(oact, &old_sa.sa, sizeof(old_sa.sa)))
    return -EFAULT;

  return 0;
}
```

可以看到，该函数的实现实际上是交给了 `do_sigaction` 函数：
```c
int do_sigaction(int sig, struct k_sigaction *act, struct k_sigaction *oact)
{
  struct task_struct *p = current, *t;
  struct k_sigaction *k;
  sigset_t mask;

  if (!valid_signal(sig) || sig < 1 || (act && sig_kernel_only(sig)))
    return -EINVAL;

  k = &p->sighand->action[sig-1];

  spin_lock_irq(&p->sighand->siglock);
  if (oact)
    *oact = *k;

  sigaction_compat_abi(act, oact);

  if (act) {
    sigdelsetmask(&act->sa.sa_mask,
      ┊ ┊ ┊ sigmask(SIGKILL) | sigmask(SIGSTOP));
    *k = *act;
    /*
    ┊* POSIX 3.3.1.3:
    ┊*  "Setting a signal action to SIG_IGN for a signal that is
    ┊*   pending shall cause the pending signal to be discarded,
    ┊*   whether or not it is blocked."
    ┊*
    ┊*  "Setting a signal action to SIG_DFL for a signal that is
    ┊*   pending and whose default action is to ignore the signal
    ┊*   (for example, SIGCHLD), shall cause the pending signal to
    ┊*   be discarded, whether or not it is blocked"
    ┊*/
    if (sig_handler_ignored(sig_handler(p, sig), sig)) {
      sigemptyset(&mask);                                                                   
      sigaddset(&mask, sig);
      flush_sigqueue_mask(&mask, &p->signal->shared_pending);
      for_each_thread(p, t)
        flush_sigqueue_mask(&mask, &t->pending);
    }
  }

  spin_unlock_irq(&p->sighand->siglock);
  return 0;
}
```
这个函数直接将信号处理函数赋值给 `sighand` 对应位置。接着会判断设置的 handler 
是不是 ignore 类函数, 是的话需要做进一步处理。

## 发送信号
对于信号机制来说，发送信号是第一步。在 Linux 下通常使用 kill 命令向某个进行发送信号。
在本例中，直接使用库函数 raise 进行发送信号。通过 man 手册查看 raise 
的作用，可以知道，在单线程中，raise 等价于 kill(gettid(), scno),而在多线程中，则等价于
kill(pthread_self(), scno)。其本质就是向当前线程发送一个信号。

根据 strace 结果，可以看到，内核最终通过 tgkill 系统调用实现发送信号的动作。而该函数
直接调用了 `do_tkill` 函数：
```c
static int do_tkill(pid_t tgid, pid_t pid, int sig)                                         
{
  struct kernel_siginfo info;

  clear_siginfo(&info);
  info.si_signo = sig;
  info.si_errno = 0;
  info.si_code = SI_TKILL;
  info.si_pid = task_tgid_vnr(current);
  info.si_uid = from_kuid_munged(current_user_ns(), current_uid());

  return do_send_specific(tgid, pid, sig, &info);
}
```

`do_tkill` 先是给对应的信号构建了了一个 kernel_siginfo 的结构体，接着调用 `do_send_specific`
发送信号。
```c
static int
do_send_specific(pid_t tgid, pid_t pid, int sig, struct kernel_siginfo *info)
{
  struct task_struct *p;
  int error = -ESRCH;                                                                       

  rcu_read_lock();
  p = find_task_by_vpid(pid);
  if (p && (tgid <= 0 || task_tgid_vnr(p) == tgid)) {
    error = check_kill_permission(sig, info, p);
    /*
    ┊* The null signal is a permissions and process existence
    ┊* probe.  No signal is actually delivered.
    ┊*/
    if (!error && sig) {
      error = do_send_sig_info(sig, info, p, PIDTYPE_PID);
      /*
      ┊* If lock_task_sighand() failed we pretend the task
      ┊* dies after receiving the signal. The window is tiny,
      ┊* and the signal is private anyway.
      ┊*/
      if (unlikely(error == -ESRCH))
        error = 0;
    }
  }
  rcu_read_unlock();

  return error;
}
```
根据 pid 获取对应的 `task_struct` 结构体，接着是一些判断，如 tgid、权限等。
之后调用 `do_send_sig_info`

```c
int do_send_sig_info(int sig, struct kernel_siginfo *info, struct task_struct *p,           
      enum pid_type type)
{
  unsigned long flags;
  int ret = -ESRCH;

  if (lock_task_sighand(p, &flags)) {
    ret = send_signal(sig, info, p, type);
    unlock_task_sighand(p, &flags);
  }

  return ret;
}
```
接着调用 `send_signal`, 而`send_signal`最终调用 `__send_signal` 实现真正的发送信号。
```c
static int __send_signal(int sig, struct kernel_siginfo *info, struct task_struct *t,
			enum pid_type type, bool force)
{
	struct sigpending *pending;
	struct sigqueue *q;
	int override_rlimit;
	int ret = 0, result;

	assert_spin_locked(&t->sighand->siglock);

	result = TRACE_SIGNAL_IGNORED;
	if (!prepare_signal(sig, t, force))
		goto ret;

	pending = (type != PIDTYPE_PID) ? &t->signal->shared_pending : &t->pending;
	/*
	 * Short-circuit ignored signals and support queuing
	 * exactly one non-rt signal, so that we can get more
	 * detailed information about the cause of the signal.
	 */
	result = TRACE_SIGNAL_ALREADY_PENDING;
	if (legacy_queue(pending, sig))
		goto ret;

	result = TRACE_SIGNAL_DELIVERED;
	/*
	 * Skip useless siginfo allocation for SIGKILL and kernel threads.
	 */
	if ((sig == SIGKILL) || (t->flags & PF_KTHREAD))
		goto out_set;

	/*
	 * Real-time signals must be queued if sent by sigqueue, or
	 * some other real-time mechanism.  It is implementation
	 * defined whether kill() does so.  We attempt to do so, on
	 * the principle of least surprise, but since kill is not
	 * allowed to fail with EAGAIN when low on memory we just
	 * make sure at least one signal gets delivered and don't
	 * pass on the info struct.
	 */
	if (sig < SIGRTMIN)
		override_rlimit = (is_si_special(info) || info->si_code >= 0);
	else
		override_rlimit = 0;

	q = __sigqueue_alloc(sig, t, GFP_ATOMIC, override_rlimit);
	if (q) {
		list_add_tail(&q->list, &pending->list);
		switch ((unsigned long) info) {
		case (unsigned long) SEND_SIG_NOINFO:
			clear_siginfo(&q->info);
			q->info.si_signo = sig;
			q->info.si_errno = 0;
			q->info.si_code = SI_USER;
			q->info.si_pid = task_tgid_nr_ns(current,
							task_active_pid_ns(t));
			rcu_read_lock();
			q->info.si_uid =
				from_kuid_munged(task_cred_xxx(t, user_ns),
						 current_uid());
			rcu_read_unlock();
			break;
		case (unsigned long) SEND_SIG_PRIV:
			clear_siginfo(&q->info);
			q->info.si_signo = sig;
			q->info.si_errno = 0;
			q->info.si_code = SI_KERNEL;
			q->info.si_pid = 0;
			q->info.si_uid = 0;
			break;
		default:
			copy_siginfo(&q->info, info);
			break;
		}
	} else if (!is_si_special(info) &&
		   sig >= SIGRTMIN && info->si_code != SI_USER) {
		/*
		 * Queue overflow, abort.  We may abort if the
		 * signal was rt and sent by user using something
		 * other than kill().
		 */
		result = TRACE_SIGNAL_OVERFLOW_FAIL;
		ret = -EAGAIN;
		goto ret;
	} else {
		/*
		 * This is a silent loss of information.  We still
		 * send the signal, but the *info bits are lost.
		 */
		result = TRACE_SIGNAL_LOSE_INFO;
	}

out_set:
	signalfd_notify(t, sig);
	sigaddset(&pending->signal, sig);

	/* Let multiprocess signals appear after on-going forks */
	if (type > PIDTYPE_TGID) {
		struct multiprocess_signals *delayed;
		hlist_for_each_entry(delayed, &t->signal->multiprocess, node) {
			sigset_t *signal = &delayed->signal;
			/* Can't queue both a stop and a continue signal */
			if (sig == SIGCONT)
				sigdelsetmask(signal, SIG_KERNEL_STOP_MASK);
			else if (sig_kernel_stop(sig))
				sigdelset(signal, SIGCONT);
			sigaddset(signal, sig);
		}
	}

	complete_signal(sig, t, type);
ret:
	trace_signal_generate(sig, info, t, type != PIDTYPE_PID, result);
	return ret;
}
```

这个函数虽然长，但是对于普通的信号来说，它就做了三件事：1、申请并设置对应的
信号队列，并将其插入到 pending 队列中；2、将 sigset_t 对应的信号位置位;3、通过
发送 ipi 中断唤醒对应的进程。

自此就完成了信号的发送。

在发送信号的前先阻塞了该信号，处理完之后才重新打开。至于为什么要这么做，笔者还没弄懂。

## 信号处理函数 
内核进行信号处理的时机是从内核返回用户态的时候，因此和什么时候收到信号无关，也即异步的。
上述。在执行 `rt_sigprocmask` 系统调用返回到用户态之前，线程收到了刚刚发送给自己的
信号，转而进入信号处理流程。

内核在信号处理流程时主要工作是开栈，用于信号处理。接着返回到用户态定义的信号处理函数中
执行相应的处理。

## 信号处理的返回 
从 strace 的结果中，可以看到。执行完用户态的处理函数之后，内核并不是直接回到系统调用的
地方，而是进入 `rt_sigreturn` 做进一步的处理。
```c
SYSCALL_DEFINE0(rt_sigreturn)
{
	struct rt_sigframe __user *sf;
	unsigned int magic;
	struct pt_regs *regs = current_pt_regs();

	/* Always make any pending restarted system calls return -EINTR */
	current->restart_block.fn = do_no_restart_syscall;

	/* Since we stacked the signal on a word boundary,
	 * then 'sp' should be word aligned here.  If it's
	 * not, then the user is trying to mess with us.
	 */
	if (regs->sp & 3)
		goto badframe;

	sf = (struct rt_sigframe __force __user *)(regs->sp);

	if (!access_ok(sf, sizeof(*sf)))
		goto badframe;

	if (__get_user(magic, &sf->sigret_magic))
		goto badframe;

	if (unlikely(is_do_ss_needed(magic)))
		if (restore_altstack(&sf->uc.uc_stack))
			goto badframe;

	if (restore_usr_regs(regs, sf))
		goto badframe;

	/* Don't restart from sigreturn */
	syscall_wont_restart(regs);

	/*
	 * Ensure that sigreturn always returns to user mode (in case the
	 * regs saved on user stack got fudged between save and sigreturn)
	 * Otherwise it is easy to panic the kernel with a custom
	 * signal handler and/or restorer which clobberes the status32/ret
	 * to return to a bogus location in kernel mode.
	 */
	regs->status32 |= STATUS_U_MASK;

	return regs->r0;

badframe:
	force_sig(SIGSEGV);
	return 0;
}
```
做的工作就是清栈并恢复用户态上下文。

## 结束语
本篇文章以 strace 提供的系统调用信息，简单的跟踪了信号处理的基本流程。
