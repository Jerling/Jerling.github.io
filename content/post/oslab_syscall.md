+++
title = "Linux 内核学习 ——— 系统调用"
author = ["Jerling"]
description = "系统调用"
date = 2020-04-23T09:54:13+08:00
lastmod = 2020-04-23T17:36:13+08:00
tags = ["syscall"]
type = "post"
draft = false
author_homepage = "https://github.com/Jerling"
toc = "true"
+++

# 系统调用
## 实验内容
在linux0.11上添加两个系统调用`iam()`和`whoami`，分别用于向内核空间存字符串和取字符串。
## 添加步骤
1. 在 `include/unistd.h` 中添加系统调用号，并声明系统调用函数
```c
#define __NR_iam	72
#define __NR_whoami	73
...
int iam(const char*name);
int whoami(char *name, unsigned int size);
```
2. 在 `kernel/system_call.s` 中修改系统调用总个数，让系统感知到
```c
nr_system_calls = 72 --> 74
```
3. 在 `include/sys.h` 中添加到系统调用表
```c
extern int sys_iam();
extern int sys_whoami();
...
fn_ptr sys_call_table[] = { sys_setup, ..., sys_iam, sys_whoami};
```
4. 在 `kernel`  文件夹中新建文件 `who.c` 实现系统调用
```c
#include <string.h>
#include <errno.h>
#include <asm/segment.h>

#define MSGLEN 23
char msg[MSGLEN+1];

int sys_iam(const char * name){
	int i=0;
	char tmp[MSGLEN+1]={0};
	for(;i<MSGLEN & ((tmp[i]=get_fs_byte(name+i))!='\0');i++);
	printk("Get a string : %s and size is %d\n", tmp, i);
	if(i>MSGLEN){
        printk("String lenght over %d\n", MSGLEN);
        return -(EINVAL);
    }
	strcpy(msg,tmp);
	printk("Store %s to Kernel space\n");
	return i;
}

int sys_whoami(char* name, unsigned int size){ 	
	int len = 0, i=0;
	for(;msg[len]!='\0' & len<size;len++);
	for(; i<size; put_fs_byte(msg[i], name+i), i++);
    printk("Copy %s from kernel over!!!\n", msg);
	return len;
}
```
### 测试系统调用
iam.c
```c
#define __LIBRARY__
#include <unistd.h>
#include <stdio.h>

_syscall1(int, iam, const char*, name);

int main(int argc,char ** argv)
{
        int len=0;
        if(argc != 2){
                printf("Usage: ./iam \"str\"\n");
                return 0;
        }
        len = iam(argv[1]);
        printf("store %d chars to kernel space\n", len);
        return 0;
}
```
whoami.c 
```c
#define __LIBRARY__
#include <unistd.h>
#include <stdio.h>

_syscall2(int, whoami,char*,name,unsigned int,size);

int main(void){
        char msg[1024]={0};
        int len=0;
        len=whoami(msg,1024);
        printf("recive %d size str is %s",len, msg);
        return 0;

}
```
### 实验结果
{{< figure src="/images/Snipaste_2020-04-23_17-22-42.png" >}}


# 参考
[1] [https://hoverwinter.gitbooks.io/hit-oslab-manual/sy2_syscall.html](https://hoverwinter.gitbooks.io/hit-oslab-manual/sy2_syscall.html)

[2] [https://github.com/Wangzhike/HIT-Linux-0.11/blob/master/2-syscall/2-syscall.md](https://github.com/Wangzhike/HIT-Linux-0.11/blob/master/2-syscall/2-syscall.md)