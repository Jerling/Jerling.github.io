+++
title = "动手写编辑器(一) ~ 文本模式"
author = ["Jerling"]
author_homepage = "https://github.com/Jerling"
description = "一步步实现终端编辑器"
date = 2019-01-20T18:31:32+08:00
lastmod = 2019-02-02T19:54:12+08:00
tags = ["text_editor", "c++", "terminal"]
categories = ["项目实战"]
type = "post"
draft = false
+++

## Table of Contens {#table-of-contens}

-   [写作动机](#写作动机)
-   [规范模式](#规范模式)
-   [文本模式](#文本模式)
-   [设置属性](#设置属性)
    -   [本地模式标志 ~~ `c_lflag`](#本地模式标志-c-lflag)
    -   [输入模式标志 ~~ `c_iflag`](#输入模式标志-c-iflag)
    -   [输出模式标志 ~~ `c_oflag`](#输出模式标志-c-oflag)
    -   [杂项标志](#杂项标志)
-   [开启和关闭文本模式](#开启和关闭文本模式)
-   [总结](#总结)
-   [参考](#参考)


## 写作动机 {#写作动机}

因为是该项目的第一篇文章，在这里简单介绍实现该项目的动机。作为程序员，动手能力是
第一位的，不管看了多少经典书籍、亦或浏览过多少源码。如果没有自己动手去实现，这些
东西都不是自己的。本人可以说是一个编辑器爱好者吧，前前后后折腾过 N 多编辑器：
如编辑器之神 Vim, 神的编辑器 Emacs, 性感无比 Sublime text 以及宇宙最强 VSCode.
最终本人留下了 emacs 和 VSCode , 前者用于编程和写作，后者用于调试程序。
用了这么多的编辑器，是时候自己实现一个了。当然并不打算参与竞争，单纯为了学习。再
说了，目前我的 emacs+doom 已经能处理各种写作任务，而且我很享受在上面码字，就想
弹钢琴一样，无须鼠标干扰，安心写作。Ok~ 让我们开始一段奇妙的旅行吧～～～


## 规范模式 {#规范模式}

我们平常使用的交互式命令终端就是所谓的 `canonical mode`。简单来说就是，它每次接收一行文本，
允许通过退格键进行删除输入的内容，以 `enter` 作为发送触发键发送给程序，然后程序
对其进行响应。这种模式大多用于交互命令处理中。但是用在文本编辑器(如 nano)中
显然是不合适，因为它要处理的是每一个按键(包括 enter)。


## 文本模式 {#文本模式}

文本模式(raw mode)可以不处理 `enter` 触发的发送功能，而是把其作为键值进行处理。这个才
接近文本编辑器的要求。但是呢，终端默认都是规范模式，而且这两个模式之间的差别不仅
仅是这一个，而且要完全切换会涉及很多的标志位的设置。下面我们就一步步来让终端来实
现期望的文本模式。


## 设置属性 {#设置属性}

上一章节提到文本模式和规范模式中间隔了很多 `flag` ，这些 `flag` 其实就是一些属性，我们通
过修改这些属性的值来实现我们的目标。终端的属性是通过 `struct termios` 类型来描述
的，我们先看看它的基本组成：

```C
// /usr/include/bits/termios.h
struct termios
  {
    tcflag_t c_iflag;		/* input mode flags */
    tcflag_t c_oflag;		/* output mode flags */
    tcflag_t c_cflag;		/* control mode flags */
    tcflag_t c_lflag;		/* local mode flags */
    cc_t c_line;			/* line discipline */
    cc_t c_cc[NCCS];		/* control characters */
    speed_t c_ispeed;		/* input speed */
    speed_t c_ospeed;		/* output speed */
}
```

从注释中容易看出， `termios` 是一些 `flag` 的集合，其中和文本模式相关的主要有
`c_lflag`, `c_iflag` , `c_oflag` 。下面我们将分别从这三个标志集合中提取出和文本
模式相关的 `flag` 。

在终端启动的时候，系统会为其初始化 `termios` , 我们需要通过 `tcgetattr` 获取这些
初始化值，切记不能自己初始化一个新实例，然后设置相关标志，最后用这个新实例去替换
原始的初始值。这可能会引发许多问题，一些标志的可能并不是我们提供的值，因此会修改
很多我们未知的属性。正确的做法是先获取属性值，然后修改我们需要改的属性，再来通过
`tcsetattr` 替换系统的 `termios` 。这不是源码分析博客，这两个函数就不介绍了。


### 本地模式标志 ~~ `c_lflag` {#本地模式标志-c-lflag}

从名字可以推断这是和本地（local）相关的 flag 集合。 先看看它的定义以及拥有的属性标志吧。

```C
typedef unsigned int	tcflag_t;

...

/* c_lflag bits */
#define ISIG	0000001
#define ICANON	0000002
#if defined __USE_MISC || (defined __USE_XOPEN && !defined __USE_XOPEN2K)
# define XCASE	0000004
#endif
#define ECHO	0000010
#define ECHOE	0000020
#define ECHOK	0000040
#define ECHONL	0000100
#define NOFLSH	0000200
#define TOSTOP	0000400
#ifdef __USE_MISC
# define ECHOCTL 0001000
# define ECHOPRT 0002000
# define ECHOKE	 0004000
# define FLUSHO	 0010000
# define PENDIN	 0040000
#endif
#define IEXTEN	0100000
#ifdef __USE_MISC
# define EXTPROC 0200000
#endif
```

c\_lflag 被定义为 `unsigned int` 类型，也就是 32 位，那么它就可以表示 32 个
`flag` 。下面就一个个来关闭相关的标志位。


#### 关闭规范模式 {#关闭规范模式}

规范的英文为 `canonical` , 从上面的标志中， `ICANON` 是规范模式标志，默认
是开启的规范模式， 所以我们只要将该 flag 取反后与 `termios` 相与就可以将该
属性去掉。即：

```C
termios.c_lflag &= ~ICANON;
```


#### 关闭回显 {#关闭回显}

我们有时候可能不需要将输入文字打印到显示器，比如密码。这就要求我们把回显关闭：

```C
termios.c_cflag &= ~ECHO;
```


#### 关闭信号 {#关闭信号}

我们知道再终端要终止正在运行的程序，直接 `C+c` (C表示 ctrl 键)就可以退出。
这个过程其实是向运行进程发了一个 `SIGINT` 信号。类似的还有暂停信号 `C+z`,

```C
termios.c_cflag &= ~ISIG;
```


#### 关闭 C+v {#关闭-c-v}

下该快捷键可以实现后面的输入字符逐字符的发送，例如输入处理 `C+v` 再输入 `C+c`
会被识别为三个字符，而不会发送信号)。由 IEXTEN 标志。

```C
termios.c_cflag &= ~IEXTEN;
```


### 输入模式标志 ~~ `c_iflag` {#输入模式标志-c-iflag}

和本地模式一样定义为 `unsigned int` 类型。我们主要看它提供哪些标志。

```C
/* c_iflag bits */
#define IGNBRK	0000001
#define BRKINT	0000002
#define IGNPAR	0000004
#define PARMRK	0000010
#define INPCK	0000020
#define ISTRIP	0000040
#define INLCR	0000100
#define IGNCR	0000200
#define ICRNL	0000400
#define IUCLC	0001000
#define IXON	0002000
#define IXANY	0004000
#define IXOFF	0010000
#define IMAXBEL	0020000
#define IUTF8	0040000
```


#### 禁用流控制 {#禁用流控制}

`C+s` 和 `C+q` 是用来控制流的快捷键，比如说，我们运行某个程序一直有输出流，而此
时你不想看这些输出流。那么使用 `C+s` 就可以关闭输出流，相反 `C+q` 可以让输出流再次打印
到终端显示器。由 `IXON` 标志。

```C
termios.c_iflag &= ~IXON;
```


#### 固定 {#固定}

`C-m` 组合会发送 '\n' 字符，也就是 `enter` 键。通过 `ICRNL` 标志。

```C
termios.c_iflag &= ~ICRNL;
```


### 输出模式标志 ~~ `c_oflag` {#输出模式标志-c-oflag}

同样的，先看看提供哪些标志位。

```C
/* c_oflag bits */
#define OPOST	0000001
#define OLCUC	0000002
#define ONLCR	0000004
#define OCRNL	0000010
#define ONOCR	0000020
#define ONLRET	0000040
#define OFILL	0000100
#define OFDEL	0000200
#if defined __USE_MISC || defined __USE_XOPEN
# define NLDLY	0000400
# define   NL0	0000000
# define   NL1	0000400
# define CRDLY	0003000
# define   CR0	0000000
# define   CR1	0001000
# define   CR2	0002000
# define   CR3	0003000
# define TABDLY	0014000
# define   TAB0	0000000
# define   TAB1	0004000
# define   TAB2	0010000
# define   TAB3	0014000
# define BSDLY	0020000
# define   BS0	0000000
# define   BS1	0020000
# define FFDLY	0100000
# define   FF0	0000000
# define   FF1	0100000
#endif

#define VTDLY	0040000
#define   VT0	0000000
#define   VT1	0040000

#ifdef __USE_MISC
# define XTABS	0014000
#endif
```

再终端的所有的输出中，它都会将 '\n' 转换为 '\r\n' 。因此我们每次输入一行文本，按
下 `enter` 键后，它总是出现在下一行的最前面，这里其实涉及两个动作：回车和换行。
但在编辑器中我们要避开这种转换。通过关闭 `OPOST` 标志关闭。

```C
termios.c_oflag &= ~OPOST;
```


### 杂项标志 {#杂项标志}

这主要是根据不同的系统以及版本历史的差异导致的不一致，可能有的系统初始话已经关闭
了，为了保险起见，这里统一重新关闭，也为了兼容差异吧。具体细节就不解释了。

```C
termios.c_cflag |= (CS8);
termios.c_iflag &= ~(BRKINT | INPCK | ISTRIP);
```


## 开启和关闭文本模式 {#开启和关闭文本模式}

上面我们提到要开启文本模式，只需要设置相应的标志即可，我们一个一个去设置或者每次
去设置，这是不可取的，因次我们把它放在一个函数里一起处理。

```C++
void enable_raw_mode() {
  if (tcgetattr(STDIN_FILENO, &_orig_termios) != 0) {
    SPDLOG_ERROR("tcgetattr");
  }
  atexit(disable_raw_mode);

  struct termios raw = _orig_termios;
  raw.c_lflag &= ~(ECHO | ICANON | ISIG | IEXTEN);
  raw.c_iflag &= ~(IXON | ICRNL | BRKINT | INPCK | ISTRIP);
  raw.c_oflag &= ~(OPOST);
  raw.c_cflag &= ~(CS8);
  raw.c_cc[VMIN] = 0;
  raw.c_cc[VTIME] = 1;

  if (tcsetattr(STDIN_FILENO, TCSAFLUSH, &raw) != 0) {
    SPDLOG_ERROR("tcsetattr");
  };
}
```

当然从我们编辑中退出后，那么必须关闭文本模式，使终端回到规范模式。

```C++
inline void disable_raw_mode() {
  if (tcsetattr(STDIN_FILENO, TCSAFLUSH, &_orig_termios) != 0) {
    SPDLOG_ERROR("tcgetattr");
  }
}
```


## 总结 {#总结}

这篇博客只是开篇，总结了终端编辑器应该有的模式以及如何设置，同时在写作的过程中可
能会涉及错误的处理，由于本项目重点不是错误处理，因此使用 [spdlog](https://github.com/gabime/spdlog/) 库来处理相关的错
误信息。好了，开篇写完了～～～


## 参考 {#参考}

<https://viewsourcecode.org/snaptoken/kilo/02.enteringRawMode.html>