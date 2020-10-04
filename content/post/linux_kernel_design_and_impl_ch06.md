+++
title = "Linux 内核设计与实现 — 内核数据结构"
author = ["Jerling"]
description = "Short description"
date = 2019-06-07T22:09:18+08:00
lastmod = 2019-06-08T11:21:20+08:00
tags = ["linux", "数据结构"]
categories = ["学习笔记"]
type = "post"
draft = false
toc = true
+++

本章节的内容是一些数据结构，没甚么可说的。随便记记笔记吧。内容包括链表、队列、映
射、二叉树。


## 链表 {#链表}

这是 linux 中最简单的数据结构，是一种存放客可变数量元素的数据结构。具体的就是用
指针将元素连接起来。具体的定义就看数据结构书吧，这里主要讲 linux 下的实现。


## Linux 链表的实现 {#linux-链表的实现}


### 链表的数据结构 {#链表的数据结构}

```c
struct list_head {
  struct list_head *next;
  struct list_head *prev;
};
```

通过这种结构，就可以将操作和数据分离开来，只要将该链表作为某种数据的成员，那么就
可以获得一个该数据为链表元素的一个链表。使用如下：

```c
struct fox {
  unsigned long tail_legth;
  unsigned long weight;
  bool is_fantastic;
  struct list_head list;
};
```

这样我们便历元素时，就可以通过移动 `list` 的指针就可以了。


### 访问链表元素 {#访问链表元素}

我们每次获得的是指针，它的地址在元素中间的位置，我们并不知道元素起始地址，所以不
不能直接访问。

在 C 语言中，一个给定结构中的变量的偏移编译时就固定了。因此使用将当前的指针成员
的地址减去它在链表元素中的偏移地址就可以获得元素首地址。这里需要用到 `typeof`
关键字和 `offsetof` 宏，前者是获得参数的类型，后者是获得成员在结构这中的偏移。为
了方便， C 库将这些操作定义为宏了。如：

```c
#define offsetof(type, member) (size_t)&(((type*)0)->member)

#define container_of(ptr, type, member) ({                   \
        const typeof( ((type *)0 )->member ) *__mptr = (ptr);\
        (type*)( (char*)__mptr - offsetof(type, member) );})
```

Linux 内核使用 `list_entry` 可以获得数据结构的起始地址。

```c
#define list_entry(ptr, type, member) \
	container_of(ptr, type, member)
```


### 静态创建链表的最简方式 {#静态创建链表的最简方式}

```c
struct fox red_fox = {
  .tail_legth = 40,
  .weight = 6,
  .list = LIST_HEAD_INIT(red_fox.list),
};
```


### 链表头 {#链表头}

内核链表实现的最杰出的特性是：所有节点都是无差别的包含 `list_head` 指针，所以可
以从任一节点起遍历整个链表。

```c
static LIST_HEAD(fox_list);
```

该函数定义并初始化了一个名为 `fox_list` 的链表例程。


### 操作链表 {#操作链表}

1.  增加
    -   `list_add(struct list_head *new, struct list_head *head)` : head 后插入 new
    -   `list_add_tail(struct list_head *new, struct list_head *head)` : head 前插入 new
2.  删除
    -   `list_del(struct list_head *entry)` : 只改了指针，没有销毁，需手动销毁包含
        `entry` 的数据结构以及 `entry` 项
    -   `list_del_init(struct list_head *entry)` : 删除后初始化 `entry`,这样做是因
        为链表不需要 `entry` 项，但是可以继续使用包含 `entry` 的数据结构。
3.  移动
    -   `list_move(struct list_head *list, struct list_head *head)`
    -   `list_move_tail(struct list_head *list, struct list_head *head)`
4.  判空
    -   `list_empty(struct list_head *head)`
5.  合并
    -   `list_splice(struct list_head *list, struct list_head *head)`
    -   `list_splice_init(struct list_head *list, struct list_head *head)` : `list`
        指向的链表要初始化


### 遍历 {#遍历}

`include/linux/list.h` 中预定了很多遍历的宏，几个比较典型的例子如下：

> 在所有的宏定义中都有 `prefetch` 函数，是内核中一个预热内存函数，这样下次遍历时就
> 能高效命中内存cache，从而提升程序性能。


#### 最简单方法 {#最简单方法}

`list_for_each()` 宏：

```c
#define list_for_each(pos, head) \
	for (pos = (head)->next; prefetch(pos->next), pos != (head); \
        	pos = pos->next)
```


#### 可用的方法 {#可用的方法}

`list_for_each_entry()` 宏：

```c
#define list_for_each_entry(pos, head, member)				\
	for (pos = list_entry((head)->next, typeof(*pos), member);	\
	     prefetch(pos->member.next), &pos->member != (head); 	\
	     pos = list_entry(pos->member.next, typeof(*pos), member))
```


#### 反向遍历 {#反向遍历}

```c
#define list_for_each_entry_reverse(pos, head, member)			\
	for (pos = list_entry((head)->prev, typeof(*pos), member);	\
	     prefetch(pos->member.prev), &pos->member != (head); 	\
	     pos = list_entry(pos->member.prev, typeof(*pos), member))
```


#### 同时删除 {#同时删除}

```c
/**
 * list_for_each_safe - iterate over a list safe against removal of list entry
 * @pos:	the &struct list_head to use as a loop cursor.
 * @n:		another &struct list_head to use as temporary storage
 * @head:	the head for your list.
 */
#define list_for_each_safe(pos, n, head) \
	for (pos = (head)->next, n = pos->next; pos != (head); \
		pos = n, n = pos->next)
```


## 队列 {#队列}

内核中队列使用 `kfifo` , 核心结构为 `__kfifo`. 都定义在 `include/linux/kfifo.h`
中

```c
struct __kfifo {
	unsigned int	in;
	unsigned int	out;
	unsigned int	mask;
	unsigned int	esize;
	void		*data;
};

#define __STRUCT_KFIFO_COMMON(datatype, recsize, ptrtype) \
	union { \
		struct __kfifo	kfifo; \
		datatype	*type; \
		char		(*rectype)[recsize]; \
		ptrtype		*ptr; \
		const ptrtype	*ptr_const; \
	}

#define __STRUCT_KFIFO_PTR(type, recsize, ptrtype) \
{ \
	__STRUCT_KFIFO_COMMON(type, recsize, ptrtype); \
	type		buf[0]; \
}
/*
 * define compatibility "struct kfifo" for dynamic allocated fifos
 */
struct kfifo __STRUCT_KFIFO_PTR(unsigned char, 0, void);
```


### 创建队列 {#创建队列}

使用 `fifo` 之前必须定义并初始化。


#### 动态创建 {#动态创建}

```c
  #define kfifo_alloc(fifo, size, gfp_mask) \
__kfifo_int_must_check_helper( \
({ \
	typeof((fifo) + 1) __tmp = (fifo); \
	struct __kfifo *__kfifo = &__tmp->kfifo; \
	__is_kfifo_ptr(__tmp) ? \
	__kfifo_alloc(__kfifo, size, sizeof(*__tmp->type), gfp_mask) : \
	-EINVAL; \
}) \
)

int __kfifo_alloc(struct __kfifo *fifo, unsigned int size,
		size_t esize, gfp_t gfp_mask)
{
	/*
	 * round down to the next power of 2, since our 'let the indices
	 * wrap' technique works only in this case.
	 */
	if (!is_power_of_2(size))
		size = rounddown_pow_of_two(size);

	fifo->in = 0;
	fifo->out = 0;
	fifo->esize = esize;

	if (size < 2) {
		fifo->data = NULL;
		fifo->mask = 0;
		return -EINVAL;
	}

	fifo->data = kmalloc(size * esize, gfp_mask);

	if (!fifo->data) {
		fifo->mask = 0;
		return -ENOMEM;
	}
	fifo->mask = size - 1;

	return 0;
}
```


#### 静态创建 {#静态创建}

```c
#define __STRUCT_KFIFO(type, size, recsize, ptrtype) \
{ \
	__STRUCT_KFIFO_COMMON(type, recsize, ptrtype); \
	type		buf[((size < 2) || (size & (size - 1))) ? -1 : size]; \
}

#define STRUCT_KFIFO(type, size) \
	struct __STRUCT_KFIFO(type, size, 0, type)

#define DECLARE_KFIFO(fifo, type, size)	STRUCT_KFIFO(type, size) fifo

/**
 * INIT_KFIFO - Initialize a fifo declared by DECLARE_KFIFO
 * @fifo: name of the declared fifo datatype
 */
#define INIT_KFIFO(fifo) \
(void)({ \
	typeof(&(fifo)) __tmp = &(fifo); \
	struct __kfifo *__kfifo = &__tmp->kfifo; \
	__kfifo->in = 0; \
	__kfifo->out = 0; \
	__kfifo->mask = __is_kfifo_ptr(__tmp) ? 0 : ARRAY_SIZE(__tmp->buf) - 1;\
	__kfifo->esize = sizeof(*__tmp->buf); \
	__kfifo->data = __is_kfifo_ptr(__tmp) ?  NULL : __tmp->buf; \
})
```

通过 `DECLARE_KFIFO` 定义一个名为 `fifo` 的队列对象。 `INIT_KFIFO` 对队列进行初
始化。

> 不管动态还是静态， size 都必须为 2 的幂


### 入列 {#入列}

```c
#define	kfifo_in(fifo, buf, n) \
({ \
	typeof((fifo) + 1) __tmp = (fifo); \
	typeof((buf) + 1) __buf = (buf); \
	unsigned long __n = (n); \
	const size_t __recsize = sizeof(*__tmp->rectype); \
	struct __kfifo *__kfifo = &__tmp->kfifo; \
	if (0) { \
		typeof(__tmp->ptr_const) __dummy __attribute__ ((unused)); \
		__dummy = (typeof(__buf))NULL; \
	} \
	(__recsize) ?\
	__kfifo_in_r(__kfifo, __buf, __n, __recsize) : \
	__kfifo_in(__kfifo, __buf, __n); \
})
```

将 `from` 指针的 `len` 字节数据拷贝到 `fifo` 所指的队列中。成功返回 `len`,如果空
闲字节小于 `len`, 则进行截断拷贝，返回实际拷贝的字节数。


### 出列 {#出列}

```c
#define	kfifo_out(fifo, buf, n) \
__kfifo_uint_must_check_helper( \
({ \
	typeof((fifo) + 1) __tmp = (fifo); \
	typeof((buf) + 1) __buf = (buf); \
	unsigned long __n = (n); \
	const size_t __recsize = sizeof(*__tmp->rectype); \
	struct __kfifo *__kfifo = &__tmp->kfifo; \
	if (0) { \
		typeof(__tmp->ptr) __dummy = NULL; \
		__buf = __dummy; \
	} \
	(__recsize) ?\
	__kfifo_out_r(__kfifo, __buf, __n, __recsize) : \
	__kfifo_out(__kfifo, __buf, __n); \
}) \
)
```

从 `fifo` 所指向的队列中拷贝出 `len` 字节数据到 `to` 所指的队列中。

上面的函数会删除队列中的数据，不删除只查看，则用 `k_fifo_peek` 即可。


### 长度 {#长度}

```c
#define kfifo_size(fifo)	((fifo)->kfifo.mask + 1)

#define	kfifo_avail(fifo) \
__kfifo_uint_must_check_helper( \
({ \
	typeof((fifo) + 1) __tmpq = (fifo); \
	const size_t __recsize = sizeof(*__tmpq->rectype); \
	unsigned int __avail = kfifo_size(__tmpq) - kfifo_len(__tmpq); \
	(__recsize) ? ((__avail <= __recsize) ? 0 : \
	__kfifo_max_r(__avail - __recsize, __recsize)) : \
	__avail; \
}) \
)
```


### 重置和撤销 {#重置和撤销}

```c
#define kfifo_reset(fifo) \
(void)({ \
	typeof((fifo) + 1) __tmp = (fifo); \
	__tmp->kfifo.in = __tmp->kfifo.out = 0; \
})

#define kfifo_free(fifo) \
({ \
	typeof((fifo) + 1) __tmp = (fifo); \
	struct __kfifo *__kfifo = &__tmp->kfifo; \
	if (__is_kfifo_ptr(__tmp)) \
		__kfifo_free(__kfifo); \
})
```


## 映射 {#映射}

关联数组，至少支持三个操作：

1.  Add(key, value)
2.  Remove(key)
3.  value = Lookup(Key)

实现可以使用散列表，也可以使用自平衡二叉树。前者提供更好的平均复杂度，后者在最坏
情况下有更好的表现，且保证有序。

在 Linux 内核中实现了红黑树。红黑树的具体实现比较复杂，这里就不讲了，但是原理得
懂，具体可以参考前面一篇关于树的一些总结 <https://jerling.github.io/post/data%5Fstruct%5Ftrees%5Fconclusion/>


## 总结 {#总结}

这一章节主要是对内核的主要数据结构进行总结，大部分的实现都采用宏来实现的，看起来
比较费力。不过相对于函数，宏实现的简单替换可以提升运行速度。