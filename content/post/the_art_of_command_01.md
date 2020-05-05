+++
title = "命令行艺术 (1) ~~ 基础篇"
author = ["Jerling"]
author_homepage = "https://github.com/Jerling"
description = "常用命令及使用技巧介绍"
date = 2019-02-24T09:54:13+08:00
lastmod = 2019-03-02T09:42:48+08:00
tags = ["linux", "shell", "command"]
categories = ["命令行艺术"]
type = "post"
draft = false
+++

## Table of Contens {#table-of-contens}

-   [什么命令行](#什么命令行)
    -   [让命令行人性化](#让命令行人性化)
-   [基础命令](#基础命令)
    -   [私人神器zsh](#私人神器zsh)
    -   [熟悉环境](#熟悉环境)
    -   [帮助命令](#帮助命令)
    -   [编辑命令](#编辑命令)
    -   [重定向](#重定向)
    -   [通配符](#通配符)
    -   [任务管理工具](#任务管理工具)
    -   [远程登录](#远程登录)
    -   [文件管理工具](#文件管理工具)
    -   [网络管理工具](#网络管理工具)
    -   [版本控制](#版本控制)
    -   [正则表达式](#正则表达式)
    -   [软件包管理工具](#软件包管理工具)
-   [总结](#总结)


## 什么命令行 {#什么命令行}

每个学习计算机的人都应该知道命令行，因为它是计算机相关从事人员比不可少的一项技能。
通常所说的命令行就是在 `linux` 下使用 `shell` 或者 `windows` 下的 `powershell`
输入的命令进行工作的过程，这些可以是系统程序或者用户程序，也可以为指向可执行文件
的链接文件。


### 让命令行人性化 {#让命令行人性化}

这里主要说的汉化，可以通过发行版对应的软件包管理工具(apt-get, yum, pacman等)安装对应的汉化包，然后将系统
语言设置为中文即可。


## 基础命令 {#基础命令}


### 私人神器zsh {#私人神器zsh}

在本人之前的 [动手写 手把手实现一个 LINUX SHELL](https://jerling.github.io/blog/writh%5Fshell%5Fwith%5Fcpp/) 中介绍到常用的 `shell` . 这一系列
的命令将会在 `zsh` 下完成，几乎所有的基础教程都用的 `bash`。但是 `zsh` 配合
`oh-my-zsh` 可以让效率提升数倍。这对于私人工作环境是不错的选择，但是如果在
公用服务器工作的还是使用 `bash` 吧。

> 声明：这里没有上下之分，只是本人用 zsh 用习惯了，而且有现成提升效率的配置 oh-my-zsh。节省
> 打造得心称手 `shell` 工具的时间。
>
> 工欲善其事，必先利其器。在 linux 下的大部分常用的工具没有配置功能会很简陋，但是强大的可配置性使其可以用
> 起来很效率。
>
> 这份学习单中将会给出一些好的配置，免得新手把时间浪费在配置上。学习到一定程度后可
> 以自己阅读一些配置文件，根据需求配置自己的配置。

一般系统不会自带 `zsh` , 因此需要自己安装。

如使用 `pacman` :

```bash
# zsh
sudo pacman -S --noconfirm zsh
# oh-my-zsh
sh -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
```

> 注：在安装 oh-my-zsh 的时候会提示切换默认的 shell, 这时需要输入密码。如果不需要
> 设置默认直接 Ctrl+c 结束即可，在 bash 中运行 zsh 即可进入 zsh 环境。
>
> 之后如果需要设置默认 shell : `chsh -s /usr/bin/zsh` 即可。


### 熟悉环境 {#熟悉环境}

我们要想在 `zsh` 中愉快的工作，那么先的熟悉它。在我们能够驾驭 `zsh` 之后，那么学习
命令行将是一个非常轻松愉快的事情。下面从最基础的开始。


### 帮助命令 {#帮助命令}

-   `man`: 如我们想知道 `zsh` 是什么， `man zsh`.
-   `apropos` : 根据关键字在系统帮助文档里查找， `apropos man`. 注：它会显示所有结果，所以最
    好使用正则匹配最想要的关键字。
-   `type` : 判断是否为可执行程序或是命令的别名， `type apropos`。
-   **tldr** : 获取命名的常见用法， `tldr type`.

> 说明 : 等宽表示系统自带的命令， 粗体表示需要自己安装的软件。后面不再解释。


### 编辑命令 {#编辑命令}

`vi(m)`, `emacs` 至少熟悉一个。刚开始的时候可以使用 `nano` 进行过渡，因为这俩
都有一定的学习曲线，但是学会之后可以起到事半功倍的效果。大部分人会学习 `vim` ，
配合 [SpaceVim](https://github.com/search?q=spacevim) 是个不错的选择。这里推荐新的 vimer 可以尝试一下 `emacs` + `vim` 模
器， 如配合 [spacemacs](https://github.com/search?q=spacemacs) 就不错，顺便说一下， SpaceVim 借鉴了 spacemacs 的快捷键布
局。emacser 有一定基础的可以尝试 [doom-emacs](https://github.com/search?q=doom-emacs) ，这个启动速度很快。定制性和前者一样
很方便，本人也在其基础上定制了私人配置，主要面向 C++ 开发 --- [doom](https://github.com/Jerling/doom) 。


### 重定向 {#重定向}

-   `>` : 输出重定向， `tldr type > out.txt`
-   `>>` : 追加方式重定向，不会覆盖原有的内容
-   `<` : 输入重定向， `tldr < in.txt`
-   `|` : 重定向管道
-   了解标准输入 `stdin` , 标准输出 `stdout`, 标准出错 `stderr` 。在每个进程中对应
    的描述符分别为 `0, 1, 2` 。


### 通配符 {#通配符}

了解常用的通配符，如 `*` ， `?` ， `[...]` 。还有引用以及引用中的 `'` 和 `"` 。


### 任务管理工具 {#任务管理工具}

-   `&` : 在当前会话后台运行，退出会话会被杀死
-   `nohup` : 在系统后台运行，会话退出不会被杀死
-   `ctrl+z` : 挂起运行的进程
-   `bg` : 和 `ctrl+z` 功能一样
-   `fg` : 恢复挂起的进程
-   `jobs` : 查看当前会话的后台任务
-   `kill` : 杀死运行的进程


### 远程登录 {#远程登录}

使用 `ssh` 进行远程管理服务器，最好使用 `ssh-agent` , `ssh-add` 实现免密码登录。

常见的基本用法如下：

```bash
➜  ~ tldr ssh
# ssh

  Secure Shell is a protocol used to securely log onto remote systems.
  It can be used for logging or executing commands on a remote server.

- Connect to a remote server:

  ssh username@remote_host

- Connect to a remote server with a specific identity (private key):

  ssh -i path/to/key_file username@remote_host

- Connect to a remote server using a specific port:

  ssh username@remote_host -p 2222

- Run a command on a remote server:

  ssh remote_host command -with -flags

- SSH tunneling: Dynamic port forwarding (SOCKS proxy on localhost:9999):

  ssh -D 9999 -C username@remote_host

- SSH tunneling: Forward a specific port (localhost:9999 to slashdot.org:80) along with disabling pseudo-[t]ty allocation and executio[n] of remote commands:

  ssh -L 9999:slashdot.org:80 -N -T username@remote_host

- SSH jumping: Connect through a jumphost to a remote server (Multiple jump hops may be specified separated by comma characters):

  ssh -J username@jump_host username@remote_host

- Agent forwarding: Forward the authentication information to the remote machine (see `man ssh_config` for available options):

  ssh -A username@remote_host
```


### 文件管理工具 {#文件管理工具}

-   列出文件命令，如 `ls`, `ll` or `ls -l`
-   查看文件命令，如 `more`, `less` , `head` , `tail` 。前两者的区别是 `more` 不支
    持回退，后者可以。
-   软链接 `ln` , 硬链接 `ln -s` 的区别：前者共享文件的 `inode` , 即还是同一文件；
    后者是新建了一个文件用来保存指向文件的路径，和 windows 的快捷方式一样，不共享 `inode` 。
-   权限管理， 改变属主 `chown` , 改变权限 `chmod` 。
-   磁盘管理， 如查看文件磁盘占用： `du -hs *`
-   文件系统管理，如查看所有文件系统和利用率： `df` , 挂载文件系统 `mount` , 格式
    文件系统 `mkfs` , 列出磁盘分区的树形结构 `lsblk` 。


### 网络管理工具 {#网络管理工具}

-   `ifconfig` : 最基本的查看 ip 地址, 这是早期的管理工具，比较新的系统基本改用
    `iproute2` 了，需要使用的话要安装 `net-tools` 。
-   `ip` : 功能更强的网络管理工具。
-   `dig` : DNS 服务查看工具。


### 版本控制 {#版本控制}

软件版本更迭怎么能少了版本控制软件呢，就目前来说 `git` 再适合不过了。还有其它小
众的如 `svn` 等。


### 正则表达式 {#正则表达式}

使用 `grep/egrep` 结和正则表达式搜索文件内容。下面为常用的参数：

-   `i` : 忽略大小写
-   `o` : 只显示被模式匹配到的字符串
-   `v` : 显示不匹配的
-   `A NUM` : 示匹配到的字符串所在的行及其后NUM行
-   `B NUM` : 显示匹配到的字符串所在的行及其前NUM行
-   `C NUM` :  显示匹配到的字符串所在的行及其前后各NUM行


### 软件包管理工具 {#软件包管理工具}

| debian/ubuntu/mint/deepin | redhat/centos/fedora | arch/manjaro  | gentoo |
|---------------------------|----------------------|---------------|--------|
| apt/apt-get               | yum/dnf              | pacman/yaourt | emerge |


## 总结 {#总结}

好了，今天的基础部份就学完了，有了这些基础，基本上管理方面已经绰绰有余。但是要想
真正的使用，光只有管理是不够的，这会很无聊。之后会继续给出日常使用的命令和软件，
打造比较舒适的学习工作环境。