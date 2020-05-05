+++
title = "命令行艺术 (2) ~~ 日常使用篇"
author = ["Jerling"]
author_homepage = "https://github.com/Jerling"
description = "常用命令及使用技巧介绍"
date = 2019-03-02T09:43:05+08:00
lastmod = 2019-03-03T16:50:22+08:00
tags = ["linux", "shell", "command"]
categories = ["命令行艺术"]
type = "post"
draft = false
+++

## Table of Contens {#table-of-contens}

-   [常用快健键](#常用快健键)
    -   [一般快捷键](#一般快捷键)
    -   [编辑器相关](#编辑器相关)
    -   [历史命令](#历史命令)
    -   [路径相关](#路径相关)
-   [少用但非常有用的命令](#少用但非常有用的命令)
    -   [管理相关](#管理相关)
    -   [使用别名](#使用别名)
    -   [同步配置](#同步配置)
    -   [脚本相关](#脚本相关)
    -   [善用文档](#善用文档)
    -   [分屏管理](#分屏管理)
    -   [远程登录](#远程登录)
    -   [杂项](#杂项)


## 常用快健键 {#常用快健键}


### 一般快捷键 {#一般快捷键}


#### 通过按 `Tab` 键实现自动补全参数，使用 `ctrl-r` 搜索命令行历史 {#通过按-tab-键实现自动补全参数-使用-ctrl-r-搜索命令行历史}

记录（按下按键之后，输入关键字便可以搜索，重复按下 `ctrl-r` 会向后查找匹配项，
按下 `Enter` 键会执行当前匹配的命令，而按下右方向键会将匹配项放入当前行中，不
会直接执行，以便做出修改）。


#### 可以按下 `ctrl-w` 删除键入的最后一个单词， `ctrl-u` 可以删除行内光标所在位置 {#可以按下-ctrl-w-删除键入的最后一个单词-ctrl-u-可以删除行内光标所在位置}

之前的内容， `alt-b` 和 `alt-f` 可以以单词为单位移动光标， `ctrl-a` 可以将光标
移至行首， `ctrl-e` 可以将光标移至行尾， `ctrl-k` 可以删除光标至行尾的所有内容，
`ctrl-l` 可以清屏。键入 `man readline` 可以查看 Bash 中的默认快捷键。内容有很
多，例如 `alt-.` 循环地移向前一个参数，而 `alt-*` 可以展开通配符


### 编辑器相关 {#编辑器相关}


#### 可以执行 `set -o vi` 来使用 `vi` 风格的快捷键，而执行 `set -o emacs` 可以把它改回来。 {#可以执行-set-o-vi-来使用-vi-风格的快捷键-而执行-set-o-emacs-可以把它改回来}


#### 为了便于编辑长命令，在设置默认编辑器后（例如 `export EDITOR=vim`）， {#为了便于编辑长命令-在设置默认编辑器后-例如-export-editor-vim}

`ctrl-x ctrl-e` 会打开一个编辑器来编辑当前输入的命令。在 `vi` 风格下快捷键则是
`escape-v` 。


### 历史命令 {#历史命令}


#### 使用 `history` 查看命令行历史记录，再用 `!n` （n 是命令编号）就可以再次执行。 {#使用-history-查看命令行历史记录-再用-n-n-是命令编号-就可以再次执行}

其中有许多缩写，最有用的大概就是 `!$` ， 用于指代上次键入的参数，而 !! 可以指
代上次键入的命令了（参考 man 页面中的“HISTORY EXPANSION”）。不过这些功能，
也可以通过快捷键 `ctrl-r` 和 `alt-.` 来实现。


### 路径相关 {#路径相关}


#### `cd` 命令可以切换工作路径，输入 `cd ~` 可以进入 home 目录。要访问 home 目录中 {#cd-命令可以切换工作路径-输入-cd-可以进入-home-目录-要访问-home-目录中}

的文件，可以使用前缀 ~（例如 ~/.bashrc）。在 sh 脚本里则用环境变量 $HOME 指代 home 目录的路径。


#### 回到前一个工作路径： `cd -` 。 {#回到前一个工作路径-cd}


#### 如果输入命令的时候中途改了主意，按下 `alt-#` 在行首添加 # 把它当做注释再按下回 {#如果输入命令的时候中途改了主意-按下-alt-在行首添加-把它当做注释再按下回}

车执行（或者依次按下 `ctrl-a` ， #， `enter`）。这样做的话，之后借助命令行历史
记录，可以很方便恢复刚才输入到一半的命令。


## 少用但非常有用的命令 {#少用但非常有用的命令}


#### 有些命令不支持管道传递参数，那么这时候可以使用 `xargs` （ 或 `parallel` ）。 {#有些命令不支持管道传递参数-那么这时候可以使用-xargs-或-parallel}

可以控制每行参数个数（-L）和最大并行数（-P）如果不确定它们是否会按想的那样工作，先使用 xargs echo 查看一下。此外，使用
  -I{} 会很方便， 它会使 {} 替换一行。例如：

```bash
  find . -name '*.py' | xargs grep some_function
  cat hosts | xargs -I{} ssh root@{} hostname
```


### 管理相关 {#管理相关}


#### `pstree -p` 以一种优雅的方式展示进程树。 {#pstree-p-以一种优雅的方式展示进程树}


#### 使用 `pgrep` 和 `pkill` 根据名字查找进程或发送信号， `-l` 可以列出进程名。 {#使用-pgrep-和-pkill-根据名字查找进程或发送信号-l-可以列出进程名}


#### 了解可以发往进程的信号的种类。比如，使用 `kill -STOP [pid]` 停止一个进程。使用 `man 7 signal` 查看详细列表。 {#了解可以发往进程的信号的种类-比如-使用-kill-stop-pid-停止一个进程-使用-man-7-signal-查看详细列表}


#### 使用 `nohup` 或 `disown` 使一个后台进程持续运行。 {#使用-nohup-或-disown-使一个后台进程持续运行}


#### 使用 `netstat -lntp` 或 `ss -plat` 检查哪些进程在监听端口（默认是检查 `TCP` 端口; 添加参数 -u 则检查 UDP 端口）或者 lsof -iTCP -sTCP:LISTEN -P -n (这也可以在 OS X 上运行)。 {#使用-netstat-lntp-或-ss-plat-检查哪些进程在监听端口-默认是检查-tcp-端口-添加参数-u-则检查-udp-端口-或者-lsof-itcp-stcp-listen-p-n--这也可以在-os-x-上运行}


#### `lsof` 来查看开启的套接字和文件。 {#lsof-来查看开启的套接字和文件}


#### 使用 `uptime` 或 `w` 来查看系统已经运行多长时间。 {#使用-uptime-或-w-来查看系统已经运行多长时间}


### 使用别名 {#使用别名}


#### 使用 `alias` 来创建常用命令的快捷形式。例如：alias ll='ls -latr' 创建了一个新的命令别名 ll。 {#使用-alias-来创建常用命令的快捷形式-例如-alias-ll-ls-latr-创建了一个新的命令别名-ll}


#### 可以把别名、shell 选项和常用函数保存在 ~/.bashrc，具体看下这篇文章。这样做的话 {#可以把别名-shell-选项和常用函数保存在-dot-bashrc-具体看下这篇文章-这样做的话}

就可以在所有 shell 会话中使用该配置。


### 同步配置 {#同步配置}


#### 把环境变量的设定以及登陆时要执行的命令保存在 `~/.bash_profile` 。而对于从图形 {#把环境变量的设定以及登陆时要执行的命令保存在-dot-bash-profile-而对于从图形}

界面启动的 `shell` 和 `cron` 启动的 `shell`，则需要单独配置文件。


#### 要想在几台电脑中同步配置文件（例如 .bashrc 和 .bash\_profile），可以借助 Git。 {#要想在几台电脑中同步配置文件-例如-dot-bashrc-和-dot-bash-profile-可以借助-git}


### 脚本相关 {#脚本相关}


#### 当变量和文件名中包含空格的时候要格外小心。Bash 变量要用引号括起来，比如 "$FOO"。 {#当变量和文件名中包含空格的时候要格外小心-bash-变量要用引号括起来-比如-foo}

尽量使用 -0 或 -print0 选项以便用 NULL 来分隔文件名，例如 `locate -0 pattern |
  xargs -0 ls -al` 或 `find / -print0 -type d | xargs -0 ls -al`。如果 `for`
循环中循环访问的文件名含有空字符（空格、tab 等字符），只需用 `IFS=$'\n'` 把内部字段分隔符设为换行符。


#### 在 Bash 脚本中，使用 `set -x` 去调试输出（或者使用它的变体 `set -v`，它会记录 {#在-bash-脚本中-使用-set-x-去调试输出-或者使用它的变体-set-v-它会记录}

原始输入，包括多余的参数和注释）。尽可能地使用严格模式：使用 set -e 令脚本在发
生错误时退出而不是继续运行；使用 `set -u` 来检查是否使用了未赋值的变量；试试
`set -o pipefail`，它可以监测管道中的错误。当牵扯到很多脚本时，使用 `trap` 来
检测 `ERR 和 EXIT`。一个好的习惯是在脚本文件开头这样写，这会使它能够检测一些
错误，并在错误发生时中断程序并输出信息：

```bash
  set -euo pipefail
  trap "echo 'error: Script failed: see failed command above'" ERR
```


#### 在 Bash 脚本中，子 shell（使用括号 (...)）是一种组织参数的便捷方式。一个常见的 {#在-bash-脚本中-子-shell-使用括号--dot-dot-dot--是一种组织参数的便捷方式-一个常见的}

例子是临时地移动工作路径，代码如下：

```bash
  # do something in current dir
  (cd /some/other/dir && other-command)
  # continue in original dir
```


#### 在 Bash 中，变量有许多的扩展方式。 `${name:?error message}` 用于检查变量是否存 {#在-bash-中-变量有许多的扩展方式-name-error-message-用于检查变量是否存}

在。此外，当 Bash 脚本只需要一个参数时，可以使用这样的代码
`input_file=${1:?usage: $0 input_file}` 。在变量为空时使用默认值：
`${name:-default}` 。如果要在之前的例子中再加一个（可选的）参数，可以使用类
似这样的代码 `output_file=${2:-logfile}` ，如果省略了 `$2` ，它的值就为空，
于是 `output_file` 就会被设为 `logfile` 。数学表达式： `i=$(( (i + 1) % 5 ))` 。
序列：{1..10} 。截断字符串： `${var%suffix}` 和 `${var#prefix}`。例如，假设
var=foo.pdf，那么 echo ${var%.pdf}.txt 将输出 foo.txt。


#### 使用括号扩展（{...}）来减少输入相似文本，并自动化文本组合。这在某些情况下会很 {#使用括号扩展-dot-dot-dot-来减少输入相似文本-并自动化文本组合-这在某些情况下会很}

有用，例如 `mv foo.{txt,pdf} some-dir` （同时移动两个文件）， `cp
  somefile{,.bak}` （会被扩展成 cp somefile somefile.bak）或者 `mkdir -p
  test-{a,b,c}/subtest-{1,2,3}` （会被扩展成所有可能的组合，并创建一个目录树）。


#### 通过使用 `< (some command)` 可以将输出视为文件。例如，对比本地文件 /etc/hosts 和一个远程文件： {#通过使用--some-command--可以将输出视为文件-例如-对比本地文件-etc-hosts-和一个远程文件}

```bash
  diff /etc/hosts <(ssh somehost cat /etc/hosts)
```


#### 编写脚本时，可能会想要把代码都放在大括号里。缺少右括号的话，代码就会因为语法 {#编写脚本时-可能会想要把代码都放在大括号里-缺少右括号的话-代码就会因为语法}

错误而无法执行。如果的脚本是要放在网上分享供他人使用的，这样的写法就体现出它
的好处了，因为这样可以防止下载不完全代码被执行。

```bash
  {
      # 在这里写代码
  }
```


### 善用文档 {#善用文档}


#### 了解 Bash 中的“here documents”，例如 cat <<EOF ...。 {#了解-bash-中的-here-documents-例如-cat-eof-dot-dot-dot}


#### 在 Bash 中，同时重定向标准输出和标准错误： `some-command >logfile 2>&1` 或者 {#在-bash-中-同时重定向标准输出和标准错误-some-command-logfile-2-and-1-或者}

`some-command &>logfile` 。通常，为了保证命令不会在标准输入里残留一个未关闭的
文件句柄捆绑在当前所在的终端上，在命令后添加 `</dev/null` 是一个好习惯。


#### 使用 `man ascii` 查看具有十六进制和十进制值的 `ASCII` 表。 `man unicode` ， {#使用-man-ascii-查看具有十六进制和十进制值的-ascii-表-man-unicode}

`man utf-8` ，以及 `man latin1` 有助于了解通用的编码信息。


### 分屏管理 {#分屏管理}


#### 使用 `screen` 或 `tmux` 来使用多份屏幕，当在使用 `ssh` 时（保存 `session` 信息） {#使用-screen-或-tmux-来使用多份屏幕-当在使用-ssh-时-保存-session-信息}

将尤为有用。而 `ubyobu` 可以为它们提供更多的信息和易用的管理工具。另一个轻量级
的 session 持久化解决方案是 `dtach` 。


### 远程登录 {#远程登录}


#### `ssh` 中，了解如何使用 `-L` 或 `-D`（偶尔需要用 `-R` ）开启隧道是非常有用的， {#ssh-中-了解如何使用-l-或-d-偶尔需要用-r-开启隧道是非常有用的}

比如需要从一台远程服务器上访问 web 页面。


#### 对 `ssh` 设置做一些小优化可能是很有用的，例如这个 `~/.ssh/config` 文件包含了防 {#对-ssh-设置做一些小优化可能是很有用的-例如这个-dot-ssh-config-文件包含了防}

止特定网络环境下连接断开、压缩数据、多通道等选项：

```bash
  TCPKeepAlive=yes
  ServerAliveInterval=15
  ServerAliveCountMax=6
  Compression=yes
  ControlMaster auto
  ControlPath /tmp/%r@%h:%p
  ControlPersist yes
```


#### 一些其他的关于 `ssh` 的选项是与安全相关的，应当小心翼翼的使用。例如应当只能 {#一些其他的关于-ssh-的选项是与安全相关的-应当小心翼翼的使用-例如应当只能}

在可信任的网络中启用 `StrictHostKeyChecking=no，ForwardAgent=yes` 。


#### 考虑使用 `mosh` 作为 ssh 的替代品，它使用 UDP 协议。它可以避免连接被中断并且 {#考虑使用-mosh-作为-ssh-的替代品-它使用-udp-协议-它可以避免连接被中断并且}

对带宽需求更小，但它需要在服务端做相应的配置。


#### 获取八进制形式的文件访问权限（修改系统设置时通常需要，但 `ls` 的功能不那么好用 {#获取八进制形式的文件访问权限-修改系统设置时通常需要-但-ls-的功能不那么好用}

并且通常会搞砸），可以使用类似如下的代码：

```bash
  stat -c '%A %a %n' /etc/timezone
```


### 杂项 {#杂项}


#### 使用 `percol` 或者 `fzf` 可以交互式地从另一个命令输出中选取值。 {#使用-percol-或者-fzf-可以交互式地从另一个命令输出中选取值}


#### 使用 `fpp（PathPicker）` 可以与基于另一个命令(例如 git）输出的文件交互。 {#使用-fpp-pathpicker-可以与基于另一个命令例如-git-输出的文件交互}


#### 将 web 服务器上当前目录下所有的文件（以及子目录）暴露给所处网络的所有用户， {#将-web-服务器上当前目录下所有的文件-以及子目录-暴露给所处网络的所有用户}

使用： `python -m SimpleHTTPServer 7777` （使用端口 7777 和 Python 2）或
`python -m http.server 7777` （使用端口 7777 和 Python 3）。


#### 以其他用户的身份执行命令，使用 `sudo` 。默认以 `root` 用户的身份执行；使用 {#以其他用户的身份执行命令-使用-sudo-默认以-root-用户的身份执行-使用}

`-u` 来指定其他用户。使用 `-i` 来以该用户登录（需要输入\_自己的\_密码）。


#### 将 shell 切换为其他用户，使用 `su username` 或者 `sudo - username` 。加入 `-` {#将-shell-切换为其他用户-使用-su-username-或者-sudo-username-加入}

 会使得切换后的环境与使用该用户登录后的环境相同。省略用户名则默认为 root。切换
到哪个用户，就需要输入\_哪个用户的\_密码。


#### 了解命令行的 `128K` 限制。使用通配符匹配大量文件名时，常会遇到“Argument list {#了解命令行的-128k-限制-使用通配符匹配大量文件名时-常会遇到-argument-list}

too long”的错误信息。 （这种情况下换用 `find` 或 `xargs` 通常可以解决。）


#### 当需要一个基本的计算器时，可以使用 `python` 解释器（当然要用 python 的时候也是这样）。例如： {#当需要一个基本的计算器时-可以使用-python-解释器-当然要用-python-的时候也是这样-例如}

```python
>>> 2+3
5
```
