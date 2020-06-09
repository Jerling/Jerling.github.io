+++
title = "终端下的emacs问题"
author = ["Jerling"]
description = "Short description"
date = 2020-06-09T16:25:16+08:00
lastmod = 2020-06-09T16:49:35+08:00
tags = ["emacs", "tmux"]
categories = ["查漏补缺"]
type = "post"
draft = false
author_homepage = "https://github.com/Jerling"
toc = true
+++

## 终端下 Emacs 复制问题 {#终端下-emacs-复制问题}

正常情况下，使用图形界面进行编码的时候是可以和 GUI 其它程序进行复制粘贴的，但是到了终端下就不行了，甚至是鼠标都没法用。


## 解决办法 {#解决办法}

在网上查询一番，主要有两种方法：

1.  使用第三方软件，如 xsel 。将 Emacs 中的内容复制到里面去。缺点是需要配置 Emacs。
2.  使用终端复用软件，如 Tmux。好处是不用配置，不过复制得按照 tmux 的方式进行。


## 使用体验 {#使用体验}

对我来说， Tmux 是远程必装软件。因此选用 Tmux 比较合理。确实是可以进行复制的。但是存在一点遗憾，Tmux 中的 Emacs 的水平线太
显眼了，导致看着不舒服。

不过这个问题通过修改 Tmux 的主题可以解决。这里为了省事直接安装了 [oh-my-tumx](https://github.com/gpakosz/.tmux) .

好了，最终勉强解决了这个问题。
