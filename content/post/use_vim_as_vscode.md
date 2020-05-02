+++
title = "像VSCode一样使用vim"
author = ["Jerling"]
description = "ThinkVim"
tags = ["vim", "nvim", "vscode"]
categories = ["效率工具"]
date = 2020-05-01T19:18:12+08:00
lastmod = 2020-05-01T19:18:12+08:00
type = "post"
draft = false
author_homepage = "https://github.com/Jerling"
toc = "true"
+++

# 谈谈VSCode
`VScode` 是微软公司开源的一款非常优秀的编辑器，本人也是非常喜欢。
但是早期养成了使用 `spacemacs`的习惯，后因为开启速度问题，转向 `doom emacs`
。但键位还是和 `spacemacs` 差不多。可是作者的更新速度太快，导致自己的私有配置
经常更不上，最后放弃了。

因此，很多时候本人都是使用的 `VSCode`，而且插件非常丰富，几乎可以做任何想做的事。
但由于键位习惯问题，本人将其键位映射为 `spacemacs` 一样的，这里要感谢
：[VSpaceCode](https://github.com/VSpaceCode/VSpaceCode)。

虽然这很大程度上解决了我的键位需求。但是在使用过程中总是不舒服，例如
我需要撤销某些改动的时候，按下 `u` 键后，它却帮我撤销了很多步骤，导致我
不得不恢复，然后手动去删除不必要的内容。

众里寻他千百度，最终终于在强大的[github](https://github/com) 上找到一份 `vim` 配置，或许
可以解决以上问题。

# 聊聊 ThinkVim
虽然前有 [SpaceVim](https://github.com/SpaceVim/SpaceVim)
强大的配置，但是感觉偏离 `VSCode` 有点远。毕竟我还经常需要
使用 `VSCode` 呢。

## coc-nvim
2018年的一匹黑马，地址：
[https://github.com/neoclide/coc.nvim](https://github.com/neoclide/coc.nvim)
这个插件更像是一种胶水，可以很将 `VSCode` 上的插件应用到 `vim` 中。并且和
`VSCode` 一样，插件使用 `typescript` 语言。本人之前没用过这个插件，没想到它
这么强大 :)。感谢 `ThinkVim` 让我认识它。


## ThinkVim
ThinkVim 以 `coc-nvim` 插件为中心，提供了一份很强的配置。人生苦短，
本人还是选择这个配置，结合自己的私有配置进行定制。

### 安装
进入
[https://github.com/hardcoreplayers/ThinkVim](https://github.com/hardcoreplayers/ThinkVim)
根据它的安装步骤就可以了

### 配置
这个是最重的，因为每个程序员的开发语言不一样，需求也不一样。
作者也没有整合所有的语言配置，这样会显得臃肿。

本人的主要开发语言是 c/cpp。因此，这里只添加了 `ccls` 补全支持：

打开 `coc-nvim` 配置文件（~/.config/nvim/coc-settings.json）或者在 vim 中使用
`CocConfig` 命令打开。它和 `VSCode`
一样，使用 `json` 格式的配置。在语言服务一块增加 `ccls` 配置：

```json
  // add your languageServer into this list
  "languageserver": {
    "ccls": {
      "command": "ccls",
      "filetypes": [
        "c",
        "cpp",
        "objc",
        "objcpp"
      ],
      "rootPatterns": [
        ".ccls",
        "compile_commands.json",
        ".git/",
        ".hg/"
      ],
      "initializationOptions": {
        "cache": {
          "directory": "/tmp/ccls"
        }
      }
    }
  }
```
需要提前安装 ccls 服务程序。安装方法：
[https://github.com/MaskRay/ccls/wiki/Build](https://github.com/MaskRay/ccls/wiki/Build)

接着就是 `snippets` 了，coc 中提供 `coc-sinppets` 这个扩展，可以解析 `VSCode` 
的 `snippets` 文件。只需要在 `coc-settings` 中指定配置目录即可,并将你在 `VSCode`
上写的 `snippets` 文件复制到该目录即可:
```json
  "snippets.textmateSnippetsRoots": [
    "/home/jer/.config/coc/vssnipts"
  ],
```

# 总结
这份配置将 `VSCode` 的使用方式迁移到 `vim` 中，相比于将 `vim` 键位迁移到
`VSCode` 中，难度应该更大。多亏了 `coc-nvim` 这个平台，让 `vim` 使用 `VSCode`
的插件成为可能。而且可以直接 fork `VSCode` 的插件仓库进行适配，让开发 `vim` 插件
更简单。同时 `coc-nvim` 还提供了一个应用商店，安装插件和 `VSCode` 一样方便。

`VSCode` 和 `vim` 都是好编辑器，各有所长，重点是插件丰富 :)。
