+++
title = "Linux 内核设计与实现 — 内存管理"
author = ["Jerling"]
description = "Short description"
date = 2019-06-23T13:23:07+08:00
lastmod = 2019-06-23T22:53:30+08:00
tags = ["linux", "kernel", "内存管理"]
categories = ["学习笔记"]
type = "post"
draft = false
author_homepage = "https://github.com/Jerling"
toc = true
+++

内核的内存分配相比用户空间来说相对较为困难，主要是因为内核本身不能奢侈的使用内存，而且一般不能睡眠，处理内存分配错误也比较棘手。


## 页 {#页}

内核将物理页作为内存管理的基本单位。一般来说，32 位体系结构支持 4KB 的页，64 位支持
8KB 的页。

数据结构： `struct page` , 定义于 `<linux/mm_types.h>`

```c
/*
 * Each physical page in the system has a struct page associated with
 * it to keep track of whatever it is we are using the page for at the
 * moment. Note that we have no way to track which tasks are using
 * a page, though if it is a pagecache page, rmap structures can tell us
 * who is mapping it.
 */
struct page {
	unsigned long flags;		/* Atomic flags, some possibly
					 * updated asynchronously */
	atomic_t _count;		/* Usage count, see below. */
	union {
		atomic_t _mapcount;	/* Count of ptes mapped in mms,
					 * to show when page is mapped
					 * & limit reverse map searches.
					 */
		struct {		/* SLUB */
			u16 inuse;
			u16 objects;
		};
	};
	union {
	    struct {
		unsigned long private;		/* Mapping-private opaque data:
					 	 * usually used for buffer_heads
						 * if PagePrivate set; used for
						 * swp_entry_t if PageSwapCache;
						 * indicates order in the buddy
						 * system if PG_buddy is set.
						 */
		struct address_space *mapping;	/* If low bit clear, points to
						 * inode address_space, or NULL.
						 * If page mapped as anonymous
						 * memory, low bit is set, and
						 * it points to anon_vma object:
						 * see PAGE_MAPPING_ANON below.
						 */
	    };
#if USE_SPLIT_PTLOCKS
	    spinlock_t ptl;
#endif
	    struct kmem_cache *slab;	/* SLUB: Pointer to slab */
	    struct page *first_page;	/* Compound tail pages */
	};
	union {
		pgoff_t index;		/* Our offset within mapping. */
		void *freelist;		/* SLUB: freelist req. slab lock */
	};
	struct list_head lru;		/* Pageout list, eg. active_list
					 * protected by zone->lru_lock !
					 */
	/*
	 * On machines where all RAM is mapped into kernel address space,
	 * we can simply calculate the virtual address. On machines with
	 * highmem some memory is mapped into kernel virtual memory
	 * dynamically, so we need a place to store that address.
	 * Note that this field could be 16 bits on x86 ... ;)
	 *
	 * Architectures with slow multiplication can define
	 * WANT_PAGE_VIRTUAL in asm/page.h
	 */
#if defined(WANT_PAGE_VIRTUAL)
	void *virtual;			/* Kernel virtual address (NULL if
					   not kmapped, ie. highmem) */
#endif /* WANT_PAGE_VIRTUAL */
#ifdef CONFIG_WANT_PAGE_DEBUG_FLAGS
	unsigned long debug_flags;	/* Use atomic bitops on this */
#endif

#ifdef CONFIG_KMEMCHECK
	/*
	 * kmemcheck wants to track the status of each byte in a page; this
	 * is a pointer to such a status block. NULL if not tracked.
	 */
	void *shadow;
#endif
};
```

-   `flag` : 状态
-   `_count` :引用计数，值为 -1 表示内核没有引用，内核代码不应直接检查，而是通过
    `page_count()` 检查。
-   `mapping` : 当由页缓存使用时，指向和这个页相关联的 `address_space` 对象，或者作为私有数据 (由 `private` 指向),或者作为页表中的映射。
-   `virtual` : 虚拟地址，有些高地址内存不会总是映射到内存空间，此时为 `NULL` ,当要使用时重新映射。


## 区 {#区}

位于某些特定位置的物理地址上不能用于一些特殊任务，因此内核将页化为不同的区。

Linux 必须处理两种有硬件存在缺陷引起的内存寻址问题：

1.  一些硬件只能用某些特定的内存地址来执行 DMA
2.  一些体系结构的内存的物理寻址范围比虚拟寻址大得多

Linux 主要存在四种区：

1.  ZONE\_DMA : 执行 DMA 操作
2.  ZONE\_DMA32 : 功能同 ZONE\_DMA, 不同在它只能被 32 位设备访问
3.  ZONE\_NORMAL : 正常映射的页
4.  ZONE\_HIGHEM : "高端内存", 其中的页不能永久映射到内核地址空间

数据结构： `struct zone` 定义在 `<linux/mmzone.h>`

```c
struct zone {
	/* Fields commonly accessed by the page allocator */

	/* zone watermarks, access with *_wmark_pages(zone) macros */
	unsigned long watermark[NR_WMARK];

	/*
	 * When free pages are below this point, additional steps are taken
	 * when reading the number of free pages to avoid per-cpu counter
	 * drift allowing watermarks to be breached
	 */
	unsigned long percpu_drift_mark;

	/*
	 * We don't know if the memory that we're going to allocate will be freeable
	 * or/and it will be released eventually, so to avoid totally wasting several
	 * GB of ram we must reserve some of the lower zone memory (otherwise we risk
	 * to run OOM on the lower zones despite there's tons of freeable ram
	 * on the higher zones). This array is recalculated at runtime if the
	 * sysctl_lowmem_reserve_ratio sysctl changes.
	 */
	unsigned long		lowmem_reserve[MAX_NR_ZONES];

#ifdef CONFIG_NUMA
	int node;
	/*
	 * zone reclaim becomes active if more unmapped pages exist.
	 */
	unsigned long		min_unmapped_pages;
	unsigned long		min_slab_pages;
#endif
	struct per_cpu_pageset __percpu *pageset;
	/*
	 * free areas of different sizes
	 */
	spinlock_t		lock;
	int                     all_unreclaimable; /* All pages pinned */
#ifdef CONFIG_MEMORY_HOTPLUG
	/* see spanned/present_pages for more description */
	seqlock_t		span_seqlock;
#endif
	struct free_area	free_area[MAX_ORDER];

#ifndef CONFIG_SPARSEMEM
	/*
	 * Flags for a pageblock_nr_pages block. See pageblock-flags.h.
	 * In SPARSEMEM, this map is stored in struct mem_section
	 */
	unsigned long		*pageblock_flags;
#endif /* CONFIG_SPARSEMEM */

#ifdef CONFIG_COMPACTION
	/*
	 * On compaction failure, 1<<compact_defer_shift compactions
	 * are skipped before trying again. The number attempted since
	 * last failure is tracked with compact_considered.
	 */
	unsigned int		compact_considered;
	unsigned int		compact_defer_shift;
#endif

	ZONE_PADDING(_pad1_)

	/* Fields commonly accessed by the page reclaim scanner */
	spinlock_t		lru_lock;
	struct zone_lru {
		struct list_head list;
	} lru[NR_LRU_LISTS];

	struct zone_reclaim_stat reclaim_stat;

	unsigned long		pages_scanned;	   /* since last reclaim */
	unsigned long		flags;		   /* zone flags, see below */

	/* Zone statistics */
	atomic_long_t		vm_stat[NR_VM_ZONE_STAT_ITEMS];

	/*
	 * The target ratio of ACTIVE_ANON to INACTIVE_ANON pages on
	 * this zone's LRU.  Maintained by the pageout code.
	 */
	unsigned int inactive_ratio;


	ZONE_PADDING(_pad2_)
	/* Rarely used or read-mostly fields */

	/*
	 * wait_table		-- the array holding the hash table
	 * wait_table_hash_nr_entries	-- the size of the hash table array
	 * wait_table_bits	-- wait_table_size == (1 << wait_table_bits)
	 *
	 * The purpose of all these is to keep track of the people
	 * waiting for a page to become available and make them
	 * runnable again when possible. The trouble is that this
	 * consumes a lot of space, especially when so few things
	 * wait on pages at a given time. So instead of using
	 * per-page waitqueues, we use a waitqueue hash table.
	 *
	 * The bucket discipline is to sleep on the same queue when
	 * colliding and wake all in that wait queue when removing.
	 * When something wakes, it must check to be sure its page is
	 * truly available, a la thundering herd. The cost of a
	 * collision is great, but given the expected load of the
	 * table, they should be so rare as to be outweighed by the
	 * benefits from the saved space.
	 *
	 * __wait_on_page_locked() and unlock_page() in mm/filemap.c, are the
	 * primary users of these fields, and in mm/page_alloc.c
	 * free_area_init_core() performs the initialization of them.
	 */
	wait_queue_head_t	* wait_table;
	unsigned long		wait_table_hash_nr_entries;
	unsigned long		wait_table_bits;

	/*
	 * Discontig memory support fields.
	 */
	struct pglist_data	*zone_pgdat;
	/* zone_start_pfn == zone_start_paddr >> PAGE_SHIFT */
	unsigned long		zone_start_pfn;

	/*
	 * zone_start_pfn, spanned_pages and present_pages are all
	 * protected by span_seqlock.  It is a seqlock because it has
	 * to be read outside of zone->lock, and it is done in the main
	 * allocator path.  But, it is written quite infrequently.
	 *
	 * The lock is declared along with zone->lock because it is
	 * frequently read in proximity to zone->lock.  It's good to
	 * give them a chance of being in the same cacheline.
	 */
	unsigned long		spanned_pages;	/* total size, including holes */
	unsigned long		present_pages;	/* amount of memory (excluding holes) */

	/*
	 * rarely used fields:
	 */
	const char		*name;
} ____cacheline_internodealigned_in_smp;
```

-   `lock` : 自旋锁，防止结构被并发访问
-   `watermark` : 持有最小值，最低和最高水位值
-   `name` : 以 `NULL` 结尾的字符串表示该区的名字。内核启动时初始化这个值


## 获得页 {#获得页}

内核获取和释放内存的接口都以页为单位

```c
struct page *alloc_pages(gfp_t gfp_mask, unsigned int order);
```

分配 2<sup>order</sup> 个连续物理页。

```c
void *page_address(struct page *page);
```

返回指向物理页的逻辑地址。

```c
unsigned long __get_free_pages(gfp_t gfp_mask, unsigned int order);
```

取得连续逻辑地址


### 取得全部为 0 的页 {#取得全部为-0-的页}

```c
unsigned long get_zeroed_page(gfp_t gfp_mask);
```

这种一般对用户空间的内存分配，防止内存中的敏感信息分配出去，保障系统安全

{{< figure src="/images/截图_2019-06-23_15-59-35.png" >}}


### 释放页 {#释放页}

```c
void __free_pages(struct page *page, unsigned int order);
void free_pages(unsigned long addr, unsigned int order);
void free_page(unsigned long addr);
```


### kmalloc() {#kmalloc}

功能与用户空间的 `malloc()` 非常相似。可以获得字节为单位的内核内存。和 `kfree()` 成对使用。


#### gfp\_mask {#gfp-mask}

该标志分为三类：

1.  行为修饰符：表示内核如何分配所需的内存
2.  区修饰符：表示从哪里分
3.  类型修饰符：组合了行为和区修饰符，将各种可能用到的组合归纳为不同类型，简化修饰符的使用

-    行为修饰符

    ![](/images/截图_2019-06-23_16-15-28.png)
    ![](/images/截图_2019-06-23_16-16-34.png)

-    区修饰符

    {{< figure src="/images/截图_2019-06-23_16-17-33.png" >}}

-    类型修饰符

    </images/截图_2019-06-23_16-19-02.png >![](/images/截图_2019-06-23_16-19-30.png)

    {{< figure src="/images/截图_2019-06-23_16-20-49.png" >}}


#### vmalloc() {#vmalloc}

工作方式和 `kmalloc` 类似，只是分配的虚拟地址是连续的，而物理地址无须连续。用户空间的 `malloc` 也是如此。和 `vfree()` 成对使用。


## slab 分配器 {#slab-分配器}

通用数据结构的缓存层。

基本原则：

1.  频繁使用的数据结构也会频繁分配和释放
2.  频繁分配和回收必然会导致内存碎片
3.  回收对象可以立即投入下一次分配
4.  如果分配器知道对象大小、页大小和总的高速缓存的大小这样的概念，它会做出更明智的决策
5.  如果让部分缓存专属于单个处理器，那么分配和释放就可以不加 SMP 锁的情况下进行
6.  如果分配器是与 NUMA 相关的，就可以从相同的内存节点为请求者进行分配
7.  对存放的对象进行着色，以防止多个对象映射到相同的高速缓存行


### slab 设计 {#slab-设计}

把不同的对象化分为高速缓存组用来放不同类型的对象。

{{< figure src="/images/截图_2019-06-23_19-41-38.png" >}}

高速缓存数据结构： `kmem_cache` 包含三个链表： `slabs_full`, `slabs_partial`,
`slabs_empty`. 都放在 `kmem_list3` 结构中。

slab 数据结构： `struck slab`

```c
/*
 * struct slab
 *
 * Manages the objs in a slab. Placed either at the beginning of mem allocated
 * for a slab, or allocated from an general cache.
 * Slabs are chained into three list: fully used, partial, fully free slabs.
 */
struct slab {
	union {
		struct {
			struct list_head list;     /* 满、部分或空链表 */
			unsigned long colouroff;   /* slab 着色偏移量 **/
			void *s_mem;		/* including colour offset */
			unsigned int inuse;	/* num of objs active in slab */
			kmem_bufctl_t free;
			unsigned short nodeid;
		};
		struct slab_rcu __slab_cover_slab_rcu;
	};
};
```

slab 分配器可以创建新的 slab, 通过 `__get_free_pages()` 低级内核页分配器进行：

```c
static void *kmem_getpages(struct kmem_cache *cachep, gfp_t flags, int nodeid)
{
	struct page *page;
	int nr_pages;
	int i;

#ifndef CONFIG_MMU
	/*
	 * Nommu uses slab's for process anonymous memory allocations, and thus
	 * requires __GFP_COMP to properly refcount higher order allocations
	 */
	flags |= __GFP_COMP;
#endif

	flags |= cachep->gfpflags;
	if (cachep->flags & SLAB_RECLAIM_ACCOUNT)
		flags |= __GFP_RECLAIMABLE;

	page = alloc_pages_exact_node(nodeid, flags | __GFP_NOTRACK, cachep->gfporder);
	if (!page)
		return NULL;

	nr_pages = (1 << cachep->gfporder);
	if (cachep->flags & SLAB_RECLAIM_ACCOUNT)
		add_zone_page_state(page_zone(page),
			NR_SLAB_RECLAIMABLE, nr_pages);
	else
		add_zone_page_state(page_zone(page),
			NR_SLAB_UNRECLAIMABLE, nr_pages);
	for (i = 0; i < nr_pages; i++)
		__SetPageSlab(page + i);

	if (kmemcheck_enabled && !(cachep->flags & SLAB_NOTRACK)) {
		kmemcheck_alloc_shadow(page, cachep->gfporder, flags, nodeid);

		if (cachep->ctor)
			kmemcheck_mark_uninitialized_pages(page, nr_pages);
		else
			kmemcheck_mark_unallocated_pages(page, nr_pages);
	}

	return page_address(page);
}
```

slab 层关键是要避免频繁分配和释放，只有在没有满也没有空的 slab 时才会调用页分配函数；当内存变得紧缺时才释放。

slab 层的管理是在每个高速缓存的基础上，通过提供给整个内核一个简单的接口来完成。


### 接口 {#接口}

高速缓存通过以下接口创建：

```c
struct kmem_cache *kmem_cache_create(const char *name, size_t size, size_t align,
			unsigned long flags,
			void (*ctor)(void *));
```

-   name : 高速缓存的名字
-   size : 每个元素的大小
-   align : 第一对象的偏移
-   flags : 控制告诉缓存的行为
    -   SLAB\_HWCACHE\_ALIGN : 所有对象按高速行对齐
    -   SLAB\_POISON : 用已知值填充
    -   SLAB\_RED\_ZONE : 在已分配的内存周围插入 "红色警戒区" 以探测缓冲边界
    -   SLAB\_PANIC : 分配失败时提醒 slab 层
    -   SLAB\_CACHE\_DMA : 使用可以执行 DMA 的内存给每个 slab 分配空间。
-   ctor : 高速缓存构造函数， 实际上不需要，可以直接赋值为空

撤销一个高速缓存：

```c
int kmem_cache_destory(struct kmem_cache *cachep);
```

调用条件：

1.  所有的 slab 为空
2.  调用过程中不访问这个高速缓存


#### 分配内存 {#分配内存}

```c
void *kmem_cache_alloc(struct kmem_cache *cachep, gfp_t flags);
```


#### 释放内存 {#释放内存}

```c
void kmem_cache_free(struct kmem_cache *cachep, void *objp);
```


## 静态分配 {#静态分配}

每个进程的内核栈大小既依赖体系结构，也依赖编译选项。一般为两个页面大小。


### 单页内核栈 {#单页内核栈}

2.6 系列早期可以通过设置单页编译选项。原因：

1.  让每个进程减少内存消耗
2.  随着机器的运行时间增加，找两个未分配的连续页比较困难

当使用单页内核栈时，中断处理程序将拥有自己的中断栈，否则和中断进程共享内核栈。


## 高端内存的映射 {#高端内存的映射}


### 永久映射 {#永久映射}

映射一个给定的 `page` 结构到内核地址空间，可以使用 `<linux/highmem>` 中的函数：

```c
void *kmap(struct page *page);
```

在高端个低端的内存都可用。如果是低端内存，返回该页的虚拟地址。位于高端，则会建立永久映射，再返回地址。该函数能睡眠，所以只能用于进程上下文。

永久映射数量有限，不用的时候应该解除：

```c
void kunmap(struct page *page);
```


### 临时映射 {#临时映射}

当前上下文不能睡眠时，内核提供了临时映射。内核可以原子地把高端内存中的一个页映射到某个保留的映射中。比如中断处理程序可以使用临时映射防止进入睡眠。

```c
void *kmap_atomic(struct page *page, enum km_type type);
```

取消映射：

```c
void kunmap_atomic(void *kvaddr, enum km_type type);
```


## cpu 上的数据 {#cpu-上的数据}

每个 cpu 上数据是唯一的，一般存放在一个数组中。按当前的处理器号确定当前的元素。

访问的过程中不需要加锁，因为这份数据对于当前的处理器来说是唯一的。

但要注意的是内核抢占：

1.  当前代码被其它处理器枪占并占用并重新调度， CPU 变量将会无效，因为它指向错误的处理器
2.  另一个任务枪占了当前代码，那么有可能在同一个处理器上发生并发访问数据的情况，这时会出现竞争

不过在 `get_cpu()` 时已经禁止内核抢占了，必须通过 `put_cpu()` 恢复。


## 新的 percpu 接口 {#新的-percpu-接口}

2.6 为了方便创建和操作每个 CPU 数据，引进 percpu 操作接口。


### 编译时的每个 CPU 数据 {#编译时的每个-cpu-数据}

```c
// 定义和声明
DEFINE_PER_CPU(type, name);
DECLARE_PER_CPU(type, name);

// 操作接口
get_cpu_var(name);
put_cpu_var(name);
```

> 编译时每个 CPU 数据不能在模块中使用，因为链接程序实际上将它们放在一个唯一的可执行段中 (.data.percpu)


### 运行时创建 {#运行时创建}

类似于 `kmalloc()`, 定义于 `<linux/percpu.h>` :

```c
void *alloc_percpu(type);
void *__alloc_percpu(size_t size, size_t align );
void free_percpu(const void *);
```


## 使用 percpu 的好处 {#使用-percpu-的好处}

1.  减少数据加锁，唯一安全要求是禁止内核枪占
2.  使用每个 cpu 数据可以大大减少缓存失效


## 总结 {#总结}

1.  需要连续的页，选择某个低级页分配器或 `kmalloc()`
2.  从高端内存分配，使用 `alloc_pages()`
3.  不需要连续， 使用 `vmalloc()` , 不过相对于 `kmalloc()` 有一定性能损失
4.  如果需要创建和撤销很多大的数据结构，可以考虑建立 slab 高速缓存
