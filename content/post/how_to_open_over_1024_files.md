+++
title = "Too many open files 解决办法"
author = ["Jerling"]
description = "Short description"
date = 2019-09-15T18:50:19+08:00
lastmod = 2019-09-15T19:21:59+08:00
tags = ["文件描述符", "套接字"]
categories = ["网络编程"]
type = "post"
draft = false
author_homepage = "https://github.com/Jerling"
toc = true
+++

## 问题来源 {#问题来源}

Linux 系统默认能打开的文件个数上限是 1024 个，可通过  `limits -n` 查看，但实际上系统可打开的文件个数远超过这个限制，通过 `cat /proc/sys/fs/file-max` 可以看到，在我的 64 位机器上这个数为 `9223372036854775807` 。


## 解决办法 {#解决办法}

针对这种问题，有两种解决办法，一种是临时解决方案，另一种是永久性的解决方案。


### 临时方案 {#临时方案}

临时方案是通过修改当前终端的限制来解决，这种方案仅限于当前终端，退出之后恢复系统默认，不推荐此方案：

```bash
ulimits -n 2048
```


### 永久方案 {#永久方案}

永久方案通过修改配置文件，使得系统启动时读取配置文件来设置默认的描述符个数。

1.  在 `/etc/security/limits.conf` 文件末添加以下两行：

    ```bash
    ​   * soft nofile 655360
    　 * hard nofile 655360
    ```

    命令格式可以参考文件中例子，第一个字段表示域（如特定用户、用户组等），第二个字段表示类型（soft 为软限制，hard 为硬限制），第三个字段为要操作的资源，第四个字段表示资源值。
2.  在 `/etc/pam.d/login` 文件中添加以下内容：

    ```bash
       session required /lib/security/pam_limits.so
    ```

    因为在系统启动的时候需要用 `pam_limits.so` 是配置生效。
3.  重启系统


## 总结 {#总结}

第二种方案操作复杂，但相对与第一种方案有不可替代的好处，如果只是需要一次性修改，可以采用第一种方案，快捷有效。但还是推荐第二种方案。
