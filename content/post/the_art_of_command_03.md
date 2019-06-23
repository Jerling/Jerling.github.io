---
title: "命令行艺术(3) ~~ 文件及数据处理篇"
date: 2019-03-10T09:32:42+08:00
draft: false
type: "post"
author : ["Jerling"]
author_homepage : "https://github.com/Jerling"
categories: ["命令行艺术"]
tags: ["terminal", "shell", "command"]
---

- [查找](#%E6%9F%A5%E6%89%BE)
  - [文件查找](#%E6%96%87%E4%BB%B6%E6%9F%A5%E6%89%BE)
  - [内容查找](#%E5%86%85%E5%AE%B9%E6%9F%A5%E6%89%BE)
- [数据处理](#%E6%95%B0%E6%8D%AE%E5%A4%84%E7%90%86)
  - [文件处理](#%E6%96%87%E4%BB%B6%E5%A4%84%E7%90%86)
  - [内容处理](#%E5%86%85%E5%AE%B9%E5%A4%84%E7%90%86)
  - [数据统计](#%E6%95%B0%E6%8D%AE%E7%BB%9F%E8%AE%A1)
- [文件拷贝](#%E6%96%87%E4%BB%B6%E6%8B%B7%E8%B4%9D)
- [杂项](#%E6%9D%82%E9%A1%B9)

# 查找

## 文件查找

- 在当前目录下通过文件名查找一个文件，使用类似于这样的命令：`find . -iname '*something*'`
  - name : 文件名
  - type : 文件类型
  - regex : 正则查找
  - size : 文件大小
  - perm : 权限
  - [a|c|m]time
  - ... 还有很多，只列举了常用的几个选项
- 在所有路径下通过文件名查找文件，使用 `locate something`，它是在数据库中搜索，比 `find` 快；但是可能需要 `update` 更新数据库。
- 程序名搜索，使用 `whereis`
  - -b : 只搜索二进制文件
  - -m : 只搜索 man 说明文件
  - -s : 只搜索源代码文件
- 在 PATH 路径下，`which` 搜索系统命令，并返回第一个搜索结果
- 查看命令是系统自带的，还是外部命令，加上 `-p` 参数相当于 `which` 命令

## 内容查找

- 使用 `ag` 在源代码或数据文件里检索（`grep -r` 同样可以做到，但相比之下 ag 更加先进）。还有其它的替代软件如：`rg`、`pt` 等

# 数据处理

## 文件处理

- 将 HTML 转为文本：`lynx -dump -stdin` 。
- Markdown，HTML，以及所有文档格式之间的转换，试试 `pandoc`。
- 当要处理棘手的 XML 时候，`xmlstarlet` 算是上古时代流传下来的神器。
- 使用 `jq` 处理 JSON。
- 使用 `shyaml` 处理 YAML。
- 要处理 Excel 或 CSV 文件的话，`csvkit` 提供了 `in2csv`，`csvcue`，`csvjoin`，`csvgrep` 等方便易用的工具。
- 当要处理 Amazon S3 相关的工作的时候，`s3cmd` 是一个很方便的工具而 `s4cmd` 的效率更高。Amazon 官方提供的 aws 以及 saws 是其他 AWS 相关工作的基础，值得学习。
- 拆分文件可以使用 `split`（按大小拆分）和 `csplit`（按模式拆分）。
- 使用 `zless`、`zmore`、`zcat` 和 `zgrep` 对压缩过的文件进行操作。

- 文件属性可以通过 `chattr` 进行设置，它比文件权限更加底层。例如，为了保护文件不被意外删除，可以使用不可修改标记：`sudo chattr +i /critical/directory/or/file`

- 使用 `getfacl` 和 `setfacl` 以保存和恢复文件权限。例如：

```bash
getfacl -R /some/path > permissions.txt
setfacl --restore=permissions.txt
```

- 为了高效地创建空文件，请使用 `truncate`（创建稀疏文件），`fallocate`（用于 ext4，xfs，btrf 和 ocfs2 文件系统），`xfs_mkfile`（适用于几乎所有的文件系统，包含在 xfsprogs 包中），`mkfile`（用于类 Unix 操作系统，比如 Solaris 和 Mac OS）。
- 标准的源代码对比及合并工具是 `diff` 和 `patch`。使用 `diffstat` 查看变更总览数据。注意到 `diff -r` 对整个文件夹有效。使用 `diff -r tree1 tree2 | diffstat` 查看变更的统计数据。`vimdiff` 用于比对并编辑文件。
- 对于二进制文件，使用 `hd`，`hexdump` 或者 `xxd` 使其以十六进制显示，使用 `bvi`，`hexedit` 或者 `biew` 来进行二进制编辑。
- 同样对于二进制文件，`strings`（包括 grep 等工具）可以帮助在二进制文件中查找特定比特。
- 制作二进制差分文件（Delta 压缩），使用 `xdelta3`。
- 使用 `iconv` 更改文本编码。需要更高级的功能，可以使用 `uconv`，它支持一些高级的 Unicode 功能。例如，这条命令移除了所有重音符号：

```bash
uconv -f utf-8 -t utf-8 -x '::Any-Lower; ::Any-NFD; [:Nonspacing Mark:] >; ::Any-NFC; ' < input.txt > output.txt
```

- 使用 `repren` 来批量重命名文件，或是在多个文件中搜索替换内容。（有些时候 rename 命令也可以批量重命名，但要注意，它在不同 Linux 发行版中的功能并不完全一样。）

```bash
      # 将文件、目录和内容全部重命名 foo -> bar:
      repren --full --preserve-case --from foo --to bar .
      # 还原所有备份文件 whatever.bak -> whatever:
      repren --renames --from '(.*)\.bak' --to '\1' *.bak
      # 用 rename 实现上述功能（若可用）:
      rename 's/\.bak$//' *.bak
```

## 内容处理

- 了解如何使用 [uniq](http://www.runoob.com/linux/linux-comm-uniq.html)，检查文件中重复出现的行列，一般与 `sort` 结合使用
  - -c或--count 在每列旁边显示该行重复出现的次数
  - -d或--repeated 仅显示重复出现的行列
  - -f<栏位>或--skip-fields=<栏位> 忽略比较指定的栏位
  - -s<字符位置>或--skip-chars=<字符位置> 忽略比较指定的字符
  - -u或--unique 仅显示出一次的行列
  - -w<字符位置>或--check-chars=<字符位置> 指定要比较的字符
- 了解如何使用 [cut](http://www.runoob.com/linux/linux-comm-cut.html), [paste](http://www.runoob.com/linux/linux-comm-paste.html) 和 [join](http://www.runoob.com/linux/linux-comm-join.html) 来更改文件。很多人都会使用 cut，但遗忘了 join。
- 了解如何使用 `awk` 和 `sed` 来进行简单的数据处理。
- 替换一个或多个文件中出现的字符串：

```bash
perl -pi.bak -e 's/old-string/new-string/g' my-files-*.txt
```

## 数据统计

- 了解如何运用 `wc` 去计算新行数（-l），字符数（-m），单词数（-w）以及字节数（-c）。
- 了解如何使用 `tee` 将标准输入复制到文件甚至标准输出，例如 ls -al | tee file.txt。
- 要进行一些复杂的计算，比如分组、逆序和一些其他的统计分析，可以考虑使用 `datamash`。
- 注意到语言设置（中文或英文等）对许多命令行工具有一些微妙的影响，比如排序的顺序和性能。大多数 Linux 的安装过程会将 LANG 或其他有关的变量设置为符合本地的设置。要意识到当你改变语言设置时，排序的结果可能会改变。明白国际化可能会使 sort 或其他命令运行效率下降许多倍。某些情况下（例如集合运算）你可以放心的使用 `export LC_ALL=C` 来忽略掉国际化并按照字节来判断顺序。
- 使用 `shuf` 可以以行为单位来打乱文件的内容或从一个文件中随机选取多行。
- 了解 `sort` 的参数。显示数字时，使用 -n 或者 -h 来显示更易读的数（例如 du -h 的输出）。明白排序时关键字的工作原理（-t 和 -k）。例如，注意到你需要 -k1，1 来仅按第一个域来排序，而 -k1 意味着按整行排序。稳定排序（sort -s）在某些情况下很有用。例如，以第二个域为主关键字，第一个域为次关键字进行排序，你可以使用 `sort -k1，1 | sort -s -k2，2`。

# 文件拷贝

- 根据 man 页面的描述，`rsync` 是一个快速且非常灵活的文件复制工具。它闻名于设备之间的文件同步，但其实它在本地情况下也同样有用。在安全设置允许下，用 `rsync` 代替 `scp` 可以实现文件续传，而不用重新从头开始。它同时也是删除大量文件的最快方法之一：

```bash
mkdir empty && rsync -r --delete empty/ some-dir && rmdir some-dir
```

- 若要在复制文件时获取当前进度，可使用 `pv`，`pycp`，`progress`，`rsync --progress`。若所执行的复制为 block 块拷贝，可以使用 `dd status=progress`。

# 杂项

- 如果想在 Bash 命令行中写 tab 制表符，按下 `ctrl-v [Tab]` 或键入 `$'\t'` （后者可能更好，因为你可以复制粘贴它）。
- 操作日期和时间表达式，可以用 `dateutils` 中的 `dateadd`、`datediff`、`strptime` 等工具。
- 可以单独指定某一条命令的环境，只需在调用时把环境变量设定放在命令的前面，例如 `TZ=Pacific/Fiji date` 可以获取斐济的时间。
