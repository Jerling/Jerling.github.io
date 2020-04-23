+++
title = "Linux内核学习 ———— 系统引导"
author = ["Jerling"]
description = "系统启动"
date = 2020-04-23
lastmod = 2020-04-23
tags = ["bootsect", "setup", ""]
categories = ["内核实验"]
type = "post"
draft = false
author_homepage = "https://github.com/Jerling"
toc = "true"
+++

## 实验目的
了解操作系统的加载过程
## 实验内容
1. 修改bootsect.s程序：实现打印一个字符串
2. 修改setup.s 程序：实现打印字符串并打印至少一个硬件参数
3. linux-0.11中bootsect程序加载了系统镜像，这里不再加载

## bootsect程序
如果只考虑引导扇区程序的话，bootsect 可以做得非常简单，而且也必须非常简单，因为 BIOS只加载一个扇区，也就是说bootsect必须控制在512B以内：
1. BIOS将 bootsect程序加载进内存特定地址(0x07c0)，这是固定的
2. 跳转到bootsect程序的开始地址开始执行

下面以打印"Welcome to BootSet"字符串为例写一个最简单的bootsect程序

```asm
.globl begtext, begdata, begbss, endtext, enddata, endbss
.text
begtext:
.data
begdata:
.bss
begbss:
.text

BOOTSEG = 0x07c0                        !BIOS将启动扇区加载在这个位置

entry _start
_start:
        jmpi    main, BOOTSEG   !指定段基地址，表示跳转到BOOTSEG处的 main 标记处
!bootsect 程序入口
main:
    !设置ds=es=ss=cs
    mov ax,cs
    mov     ds,ax
    mov     es,ax
    mov     ss,ax
    mov     sp,#0xFF00              ! 栈顶位置，必须远大于bootsect和setup程序的总大小

    !下面三行通过BIOS中断获取光标的位置
    mov     ah,#0x03
    xor     bh,bh
    int     0x10

    !通过BIOS中断打印字符串
    mov     cx,#28
    mov     bx,#0x0007              ! 正常的白色字体
    mov     bp,#msg
    mov     ax,#0x1301              ! 打印字符串，并移动光标
    int     0x10

!死循环，等待结束
death_loop:
    j death_loop

msg:
        .byte 13,10
        .ascii "Welcome to BootSect..."
        .byte 13,10,13,10

.org 510
boot_flag:                          !必须要有的
        .word 0xAA55

.text
endtext:
.data
enddata:
.bss
endbss:
                                     !最后的空行必须存在，否则编译出错
```

编译和链接：
```shell
as86 -0 -a -o bootsect.o bootsect.s
ld86 -0 -s -o bootsect bootsect.o
```
其中-0（注意：这是数字0，不是字母O）表示生成8086的16位目标程序，-a表示生成与GNU as和ld部分兼容的代码，-s告诉链接器ld86去除最后生成的可执行文件中的符号信息。

这样生成的代码实际大小是544B，因为ld86生成的是Minix可执行程序，里面包含头信息，刚好是32B。因此只需要将头部的32B字节删除即可。这里使用`dd`程序实现,并将镜像拷贝到linux-0.11根目录：
```shell
dd bs=1 if=bootsect of=Image skip=32
```

实验结果：

![](图片/Snipaste_2020-04-22_23-08-09.png)

## setup程序
setup在linux启动过程中的作用如下：
1. 负责检测硬件及配置参数，并将这些数据存在内存特定位置；
2. 接着拷贝linux内核到内存起始处覆盖BIOS中断向量表；
3. 加载设置好的GDT至GDTR寄存器、IDT至IDTR寄存器；
4. 开启A20地址线，重新设置中断芯片控制器；
5. 设置CPU的机器状态字CR0，进入32位实模式，并跳转到linux内核起始出正式启动linux内核


setup程序需要bootsect程序加载到内存中。在linux内核中，bootsect还负责将linux内核镜像加载进内存。这里只为学习引导程序，因此没有加载内核。

### bootsect加载setup
加载的时候需要指定内存位置，这里设置和linux中的设置保持一致。主要过程为：
1. bootsect将自己拷贝到新地址，并将控制权转移到新地址
2. 加载setup程序到bootsect后面
3. 跳转到setup程序执行setup操作

关键代码如下：
```asm
BOOTSEG = 0x07c0			!BIOS将启动扇区加载在这个位置
SETUPLEN = 4				! setup 程序所占扇区数
INITSEG  = 0x9000			! 将bootsect程序复制到此处
SETUPSEG = 0x9020			! 将setup程序复制到此处

entry _start
_start:
!移动bootsect程序到 INITSEG 处
    mov ax,#BOOTSEG
    mov ds,ax
    mov ax,#INITSEG
    mov es,ax
    mov cx,#256
    sub si,si
    sub di,di
    rep
    movw
	jmpi    main, INITSEG   !指定段基地址，表示跳转到BOOTSEG处的 main 标记处
!bootsect 程序入口
main:
...
! 加载 setup 程序
load_setup:
	mov	dx,#0x0000		    ! drive 0, head 0
	mov	cx,#0x0002		    ! sector 2, track 0
	mov	bx,#0x0200		    ! address = 512, in INITSEG
	mov	ax,#0x0200+SETUPLEN	! service 2, nr of sectors
	int	0x13			    ! read it
	jnc	ok_load_setup		! ok - continue
	mov	dx,#0x0000
	mov	ax,#0x0000		    ! reset the diskette
	int	0x13
	j	load_setup

ok_load_setup:
! 获取磁盘参数
	mov	dl,#0x00
	mov	ax,#0x0800		! AH=8 is get drive parameters
	int	0x13
	mov	ch,#0x00
	seg cs
	mov	sectors,cx
	mov	ax,#INITSEG
	mov	es,ax
    
!跳转到setup程序
    jmpi	0,SETUPSEG
```

### setup关键代码

```asm
INITSEG  = 0x9000	! bootsec 移动的位置
SETUPSEG = 0x9020	! setup 在内存中的位置

entry start
start:
! 重新设置段寄存器
	mov ax, #INITSEG
	mov ss, ax
	mov sp, #0xFF00

	mov ax, #SETUPSEG
	mov es, ax

!获取当前光标
	call get_cursor
	mov	[0],dx		! it from 0x90000

!打印 in setup 字符串
	mov cx, #22
	mov bx, #0x0007		! page 0, attribute 10(bright green)
	mov bp, #msg
	mov ax, #0x1301		! write string, move cursor
	int 0x10

! 获取扩展内存(extended mem, kB)
	mov	ah,#0x88
	int	0x15
	mov	[2],ax

! 获取视频卡数据:
	mov	ah,#0x0f
	int	0x10
	mov	[4],bx		! bh = display page
	mov	[6],ax		! al = video mode, ah = window width

! 检查VGA及配置参数
	mov	ah,#0x12
	mov	bl,#0x10
	int	0x10
	mov	[8],ax
	mov	[10],bx
	mov	[12],cx

!打印光标位置
	call get_cursor
	mov bp,#position
	mov cx,#10
	mov ax,#0x1301
	int 0x10

	call get_cursor
	mov bp,#0x0000
	call print_hex
	call print_nl

!打印内存信息
	call get_cursor
	mov bp,#memory_size
	mov cx,#13
	mov ax,#0x1301
	int 0x10

	call get_cursor
	mov bp,#0x0002
	call print_hex
	call print_nl

!打印显卡参数
	call get_cursor
	mov bp,#video_card
	mov cx,#12
	mov ax,#0x1301
	int 0x10

	call get_cursor
	mov bp,#0x0004
	call print_hex

	call print_backspace

	call get_cursor
	mov bp,#0x0006
	call print_hex
	call print_nl

!打印VGA参数
	call get_cursor
	mov bp,#VGA
	mov cx,#5
	mov ax,#0x1301
	int 0x10

	call get_cursor
	mov bp,#0x0008
	call print_hex

	call print_backspace

	call get_cursor
	mov bp,#0x0010
	call print_hex

	call print_backspace

	call get_cursor
	mov bp,#0x0012
	call print_hex
	call print_nl

	call death_loop

get_cursor:
    push ax
    push bx
	push cx

    !下面三行通过BIOS中断获取光标的位置
	mov	ah,#0x03		
	xor	bh,bh
	int	0x10

	pop cx
    pop bx
    pop ax
    ret

!以16进制方式打印栈顶的16位数
print_hex:
	mov    cx,#4         ! 4个十六进制数字
	mov    dx,(bp)     ! 将(bp)所指的值放入dx中，如果bp是指向栈顶的话
print_digit:
	rol    dx,#4        ! 循环以使低4比特用上 !! 取dx的高4比特移到低4比特处。
	mov    ax,#0xe0f     ! ah = 请求的功能值，al = 半字节(4个比特)掩码。
	and    al,dl         ! 取dl的低4比特值。
	add    al,#0x30     ! 给al数字加上十六进制0x30
	cmp    al,#0x3a
	jl    outp          !是一个不大于十的数字
	add    al,#0x07      !是a～f，要多加7
outp: 
	int    0x10
	loop    print_digit
	ret

!打印回车换行
print_nl:
	push ax
	push bx
	mov ax, #0x0e0d		! CR
	int 0x10
	mov ax, #0x0e0A		! LR
	int 0x10
	pop bx
	pop ax
	ret

!打印空格
print_backspace:
	push ax
	push bx
	push cx
	call get_cursor
	mov ax,#0x1301
	mov bp,#back_space
	mov cx,#1
	int 0x10
	pop cx
	pop bx
	pop ax
	ret

!死循环，等待关机
death_loop:
    j death_loop

msg:
    .byte 13,10
    .ascii "Now, in Setup..."
    .byte 13,10,13,10

position:
	.ascii "Position: "

memory_size:
	.ascii "Memory Size: "

video_card:
	.ascii "Video-card: "

VGA:
	.ascii "VGA: "

back_space:
	.ascii " "
```

### 编译和链接

将两个程序编译并合并为一个镜像，单个操作比较麻烦。因此可以借助make自动化工具，Makefile文件可以之间使用linux-0.11自带的，使用其中的 BootImage 目标即可。

不过linux-0.11的build工具在不指定内核镜像时无法之间构建，因此对build.c稍作修改，就可以了。
```c
if(strcmp(argv[3], "none")){
		fprintf(stderr, "Will Write System\n");
		if ((id=open(argv[3],O_RDONLY,0))<0)
			die("Unable to open 'system'");
		for (i=0 ; (c=read(id,buf,sizeof buf))>0 ; i+=c )
			if (write(1,buf,c)!=c)
				die("Write call failed");
		close(id);
		fprintf(stderr,"System is %d bytes.\n",i);
		if (i > SYS_SIZE*16)
			die("System is too big");
	}else{
		fprintf(stderr, "No write System\n");
	}
```

接着直接使用make进行构建：
```shell
make BootImage
tools/build boot/bootsect boot/setup none  > Image
Root device is (3, 1)
Boot sector 512 bytes.
Setup is 356 bytes.
No write System
sync
```
不出错，构建成功。

### 实验结果
![](图片/Snipaste_2020-04-22_23-47-35.png)

## 实验总结
这里只给出了最简单的bootsec程序过程，setup只实现了读取内存、video card和VGA等参数及配置。这里会涉及系统启动的很多理论知识，包括BIOS、读盘、磁盘构成等，具体详情见[1]。

实验过程大部分参考了[2]，这里给出了完整的实验过程，尤其是给出了16进制打印参数的函数。

最后经过多次调试，了解了bootsect程序和 setup程序的基本功能，尤其是bootsect必须尽量简单，完成加载setup并设置栈等即可，其它能省就省，比如打印字符串。

## 参考
[1] [https://github.com/Wangzhike/HIT-Linux-0.11/blob/master/1-boot/OS-booting.md](https://github.com/Wangzhike/HIT-Linux-0.11/blob/master/1-boot/OS-booting.md)

[2] [https://hoverwinter.gitbooks.io/hit-oslab-manual/sy1_boot.html](https://hoverwinter.gitbooks.io/hit-oslab-manual/sy1_boot.html)