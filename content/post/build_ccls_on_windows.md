+++
title = "windows 上编译 ccls"
author = ["Jerling"]
description = "在 windows 上编译 ccls 遇到的一些坑"
date = 2020-06-04T21:42:44+08:00
lastmod = 2020-06-05T23:45:37+08:00
tags = ["ccls", "windows", "msys2"]
categories = ["效率工具"]
type = "post"
draft = false
author_homepage = "https://github.com/Jerling"
toc = true
+++

## ccls {#ccls}

ccls 是一个优秀的 c/c++ 语言自动补全服务端程序。虽然之前在 windows 上成功编译过一次，但是由于当时没记录下来，导致本次编译出错一时想不起来了。所以说好记性不如烂笔头是有道理的。


## 编译环境 {#编译环境}

这里还是以 ccls wiki 推荐的 msys2 环境进行编译。


### msy2 安装 {#msy2-安装}


#### 直接安装 {#直接安装}

这个没啥好说的，直接下载安装文件。一步一步走就行了。不过最好将源设置成国内的，可以加速下载相关包


#### Chocolatey 安装 {#chocolatey-安装}

通过软件管理工具安装，这个也本文是推荐方式。假设已安装好 Chocolatey, 那么就可以通过以下命令安装 msys2:

```sh
choco install msys2
```

安装完之后放在 `C:\tools\` 下，因此最好将其下相关的 `bin` 加入环境变量里面去。


## 安装依赖 {#安装依赖}

```sh
pacman -S mingw-w64-x86_64-clang mingw-w64-x86_64-clang-tools-extra mingw64/mingw-w64-x86_64-polly mingw-w64-x86_64-cmake mingw-w64-x86_64-jq mingw-w64-x86_64-ninja mingw-w64-x86_64-ncurses mingw-w64-x86_64-rapidjson
```


## 编译 ccls {#编译-ccls}

```sh
git clone --depth=1 --recursive https://github.com/MaskRay/ccls
cd ccls

cmake -H. -BRelease -G Ninja -DCMAKE_CXX_FLAGS=-D__STDC_FORMAT_MACROS
ninja -C Release
```


## 问题 {#问题}

在最后一步通常会报错，具休就是说 `libz3` 库找不到。


## 解决 {#解决}

将 `Release/build.ninja` 中关于 `libz3` 的两个路径改为绝对路径即可。


## Reference {#reference}

<https://github.com/MaskRay/ccls/wiki/Build>

<https://github.com/MaskRay/ccls/issues/503>
