+++
title = "将Emacs作为邮件处理软件"
author = ["Jerling"]
description = "Short description"
date = 2020-06-13T07:17:43+08:00
lastmod = 2020-06-13T10:54:11+08:00
tags = ["emacs", "mbsync", "mu4e"]
categories = ["效率工具"]
type = "post"
draft = false
author_homepage = "https://github.com/Jerling"
toc = true
+++

## Why {#why}

在 Linux 下也有比较多的邮件客户端软件，而我只用过雷鸟，功能非常完善，常见的日历功能如事件、任务等都有。

但是为什么我还要配置 Emacs 的邮件收发功能呢。

一是喜欢折腾，二是为了方便。毕竟其它软件需要鼠标的配合才能完成工作，而 Emacs 作为编辑器，可以使用快捷键完成所有工作。而且不脱离 Emacs ，处理完邮件就可以继续专注于编码工作了，不必因软件切换导致分心。

好了，废话不多说，撸起袖子就是干！


## 基础软件安装 {#基础软件安装}

Emacs 需要借助其它软件才能完成邮件处理工作，配置也比较简单。


### 邮件下载 {#邮件下载}

邮件下载软件有目前也有好几个，根据接收邮件协议的不同，可以分为两类：

1.  IMAP 协议： offlineimap, mbsync ..
2.  POP 协议： getmail ...

这里使用 IMAP 协议相关软件，两个都可以用。这里以 mbsync 为例。在 Arch Linux 下安装：

```sh
sudo pacman -S isync
```

接着就是配置并下载邮件，这里以 qq 邮箱为例。


#### 生成授权码 {#生成授权码}

处于安全考虑，QQ 邮箱使用授权码来允许第三方软件代收邮件，具体操作可以网上搜一下。其它邮箱系统应该可以直接使用。


#### mbsync 配置文件 {#mbsync-配置文件}

主要是指定账户、密码以及要下载的邮件等。为了安全，这里使用 [unix pass](https://www.passwordstore.org/) 存储授权码。

```sh
########################################
# qq.com
########################################
IMAPAccount qq
Host imap.qq.com
User linjieli001@qq.com
PassCmd "pass Email/qq"
Port 993
AuthMechs LOGIN
SSLType IMAPS
CertificateFile /etc/ssl/certs/ca-certificates.crt
# CertificateFile /usr/local/etc/openssl/cert.pem  # MacOS

##
# Remote
IMAPStore qq-remote
Account qq

# Local
MaildirStore qq-local
Path ~/.mail/qq.com/
Inbox ~/.mail/qq.com/Inbox

## Connections

Channel qq-inbox
Master :qq-remote:"INBOX"
Slave :qq-local:"Inbox"
Create Slave
Expunge Both
SyncState *

Channel qq-drafts
Master :qq-remote:"Drafts"
Slave :qq-local:"Drafts"
Create Slave
Expunge Both
SyncState *

Channel qq-sent
Master :qq-remote:"Sent Messages"
Slave :qq-local:"Sent Mail"
Create Slave
Expunge Both
SyncState *

Channel qq-trash
Master :qq-remote:"Deleted Messages"
Slave :qq-local:"Trash"
Create Slave
Expunge Both
SyncState *

## Groups
Group qq
Channel qq-inbox
Channel qq-drafts
Channel qq-sent
Channel qq-trash
```


#### 下载邮件 {#下载邮件}

只要前面配置正确，这里基本不会出问题了，而且一条命令即可：

```sh
mbsync --all
```


### 建立索引 {#建立索引}

这里使用 mu 软件，Emacs 中可以直接使用 mu4e 进行邮件管理。

在 Arch Linux 的 pacman 源中不存在这个软件。因此，只能从 AUR 中安装。比如以 AUR
包管理工具 pakku 为例：

```sh
pakku -S mu
```

mu 的使用比 mbsync 简单得多。但是要注意版本的差别 (`mu --version`)：

1.  `> 1.4`: `mu init --maildir ~/.mail --my-address email@example.com; mu index`
2.  `< 1.4`: `mu index --maildir ~/.mail`


## 配置 Emacs {#配置-emacs}

这里以 Doom Emacs 配置文件为例。


### 读邮件 {#读邮件}

```elisp
(set-email-account! "qq.com"
  '((mu4e-sent-folder       . "/qq.com/Sent Mail")
    (mu4e-drafts-folder     . "/qq.com/Drafts")
    (mu4e-trash-folder      . "/qq.com/Trash")
    (mu4e-refile-folder     . "/qq.com/All Email")
    (smtpmail-smtp-user     . "linjieli001@qq.com")
    ;; (user-mail-address      . "linjieli001@qq.com")    ;; only needed for mu < 1.4
    (mu4e-compose-signature . "---\nLinjie Li"))
  t)
```

效果：
![](/images/2020-06-13-100442_669x783_scrot.png)


### 发邮件 {#发邮件}

读邮件只需要以上配置即可，但是发邮件就稍微复杂一些。不过这里有部分是因为 Doom Emacs 的原因吧。首先在 Emacs 中配置默认发邮件帐号、发送方式、 smtp 服务地圵以及端口等信息：

```elisp
(setq message-send-mail-function 'smtpmail-send-it)
(setq smtpmail-debug-info t)
(setq smtpmail-debug-verb t)


(setq user-mail-address "linjieli001@qq.com")
(setq user-full-name "linjieli001")

(setq smtpmail-smtp-user "linjieli001@qq.com"
      smtpmail-smtp-server "smtp.qq.com"
      smtpmail-smtp-service 465
      smtpmail-stream-type 'ssl)
```

到这里还不算完，因为 mu4e 是基于 gnus 的，因此需要在主目录下新建一个文件， 命名为 `.authinfo` 。否则会出现以下错误：

```text
Sending via mail...
smtpmail-send-it: Sending failed: 503 Error: need EHLO and AUTH first !
```

`~/.authinfo` 内容具体如下：

```sh
machine smtp.qq.com  login linjieli001@qq.com password  授权码
```

然而，走到这里。对于 Emacs 来说，其实配置已经完了，但 Doom Emacs 用户还是会报同样的错误。Doom emacs 出于安全考虑，默认使用 PGP 加密文件进行密码的传输。因此， 首先得将 `~/.authinfo` 文件通过 `gpg2` 命令加密为 `~/.authinfo.gpg` 文件。这里就不再说明了，具体操作可以网上搜一下。

写邮件效果如下：
![](/images/2020-06-13-101007_592x215_scrot.png)

编辑完邮件之后，按 `C-c C-s` 即可发送。因为是测试，发给自己的，因此，在 mu4e 中按 `C-c C-u` 更新邮件，就可以看到刚刚发送的邮件：
![](/images/2020-06-13-101407_555x173_scrot.png)
![](/images/2020-06-13-101808_816x91_scrot.png)


## 总结 {#总结}

总的来说，效果还可以，但是毕竟不是专用于邮件处理的，所有说功能可能不及其它客户端软件。但是自用的话绰绰有余了。

在配置的过程中，需要了解一些基本软件的使用，比如 mbsync,mu,gpg,pass 等，虽然过程有点坎坷，但收获也蛮大的。

mu4e 模式中提供了丰富的快捷键，具体可以参考：<http://wenshanren.org/?p=111>


## 参考 {#参考}

<https://github.com/hlissner/doom-emacs/tree/develop/modules/email/mu4e>

<https://emacs-china.org/t/sending-mail-from-qq-com/11661/5>

<https://blog.csdn.net/sheismylife/article/details/41411429>

<https://linuxtoy.org/archives/pass.html>

<https://ruanyifeng.com/blog/2013/07/gpg.html>

<http://wenshanren.org/?p=111>
