+++
title = "Hyper-v 下虚拟机性能问题"
author = ["Jerling"]
description = "Short description"
date = 2020-06-10T23:09:27+08:00
lastmod = 2020-06-10T23:19:08+08:00
tags = ["Hyper-v"]
categories = ["效率工具"]
type = "post"
draft = false
author_homepage = "https://github.com/Jerling"
toc = true
+++

## Hyper-v 性能问题 {#hyper-v-性能问题}

之前一直使用 Hyper 下的 Arch 虚拟机，自从装上 Emacs 之后，总是感觉有点卡。刚开始以为是因为 Hyper-V 的缘故。可是，使用 Hyper 快速创建的 Ubuntu 却是很流畅。仔细观察发现：原来，
Ubuntu 的虚拟 CPU 是 4 个。而自定义安装的默认是 1 个 CPU。没想到 Hyper-v 的 CPU 个数这么影响性能，之前用 Vmware 和 VirtualBox 好像没有这么明显。

遇到这个问题，也是有点奇怪，记录下来，防止忘记。
