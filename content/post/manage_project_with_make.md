+++
title = "使用 make 管理工程项目"
author = ["Jerling"]
description = "C工程项目Makefile实践"
date = 2020-04-30T19:58:52+08:00
lastmod = 2020-04-30T19:58:52+08:00
tags = ["make", "Makefile", "project"]
categories = ["最佳实践"]
type = "post"
draft = false
author_homepage = "https://github.com/Jerling"
toc = "true"
+++

# 谈谈 make
首先简单讲讲 `make` 吧，但感觉又没必要讲，几乎所有的程序都知道，尤其是在linux环境下工作过的程序员。`make` 就是一个自动化构建工具，用于有条不紊地构建整个工程项目。通常在构建之前，会定义一个配置文件，`make` 命令会根据配置文件定义的规则按部就班地执行构建过程。因此，我们最关注的应该是这个配置文件，因为它是工程构建的指南，一般命名为 `Makefile`。

# 简单了解 Makefile
**Makefile** 文件是 `make` 程序构建工程的指南。简单来说， `Makefile` 是一系列规则的组合，一般一个 `Makefile` 有一个最终的目标，而最终的目标它有依赖项，以及如何组织这些依赖项的命令组合。如下：
```plain
目标：依赖项
    命令
```
而依赖项又可以是依赖于其它项的目标，因此 `Makefile` 是一种倒推的工作模式，从最终目标，依次寻找它之前的依赖。
## 简单例子
以编译一个简单的 hello 程序为例，为了模拟复杂的工程，这里将编译的步骤分开做，分为编译、汇编、链接三个步骤：
{{< figure src="/images/Snipaste_2020-04-30_20-44-47.png" >}}
使用 Makefile 如下：
```plain
hello: hello.o
    gcc -o hello hello.o

hello.o: hello.s
    gcc -c -o hello.o hello.s

hello.s: hello.c
    gcc -S -o hello.s hello.c

```
{{< figure src="/images/Snipaste_2020-04-30_20-50-54.png" >}}

值得注意的是：这里的命令前面必须是 **tab** 键，因为 `make` 会将以 `tab` 键开头的视为命令，供 `shell` 执行。因此，如果不是命令，不能以 `tab` 开头，语句中间可以。

## 聊聊变量
通常一个项目的 `Makefile` 会比较复杂，而如果测试不同编译程序的版本，就需要大量修改引用编译程序的地方。因此，为了减小修改量，可以使用变量。例如使用 `CC := gcc` 代替上述的 `gcc` 程序，那么就只需要改一个地方就行了。
```plain
CC := gcc
hello: hello.o
    $(CC) -o hello hello.o

hello.o: hello.s
    $(CC) -c -o hello.o hello.s

hello.s: hello.c
    $(CC) -S -o hello.s hello.c

```

# 进入正题
前面主要是对 `make` 程序做了简单的介绍，本文主要目的是提供一份最佳实践，而不是讨论 `Makefile` 的全部，毕竟它有很多内容，感兴趣可以直接看参考手册。

## 工程组织
一般工程项目最基本的构成有头文件、源文件、库文件、测试文件以及实例文件，因此这里定义了基本的目录组织形式：

```
include
    -- 工程的头文件
src
    -- 工程源文件
lib
    -- 工程库文件
share
    -- 共享库文件
tests
    -- 测试文件
samples
    -- 样本文件
```
其中 `lib` 和 `share` 可以只要一个。

因此，我们需要为除`include` 和 `src` 目录外的所有目录建立一份 `Makefile` 文件，让 `make` 程序递归地处理每一个文件夹。其次，需要在根目录建立一个管理整个项目的 `Makefile`。

听起来有点麻烦，但是实践中，根据最终目标用途可以分为四类，根目录的管理文件、lib 静态库文件、share 共享库文件以及可执行文件。只要建立相应地模板，适当修改相关变量，就可以管理简单的工程，如果有特殊需求，只需要添加即可。

### 根目录管理模板
```Makefile
######################################
# Author: Jerling Li
# Email : linjieli001@qq.com
# Description: build project 
######################################

# 包好定义颜色的文件
include color/color.make

# 定义相关目录名称
LIB_DIR		:= lib
SHARE_DIR	:= share
SAMPLE_DIR	:= samples
TEST_DIR	:= tests

# 定义 make 的目标列表，默认为第一项
.PHONY : build build_test build_sample build_all run_test run_sample run all clean dist-clean

build :
	(cd lib; make)
	@echo $(LIGHT_GREEN)"Static library building finish !!!"$(NONE)
	(cd share; make)
	@echo $(LIGHT_GREEN)"Share library building finish !!!"$(NONE)

build_test:
	(cd tests; make)
	@echo $(LIGHT_GREEN)"Tests building finish !!!"$(NONE)

build_samples:
	(cd samples; make)
	@echo $(LIGHT_GREEN)"Tests building finish !!!"$(NONE)

build_all : build build_test build_sample
	@echo $(LIGHT_GREEN)"Build all Finish !!!"$(NONE)

run_test: build build_test
	$(TEST_DIR)/test_log
	@echo $(LIGHT_GREEN)"Test Finish !!!"$(NONE)

run_sample: build build_sample
	$(SAMPLE_DIR)/test_log
	@echo $(LIGHT_GREEN)"Test Finish !!!"$(NONE)
    
run_all: run_test run_sample

clean:
	(cd lib; make clean)
	@echo $(YELLOW)"Only clean library OBJS"$(NONE)
	(cd share; make clean)
	@echo $(YELLOW)"Only clean share OBJS"$(NONE)
	(cd tests; make clean)
	@echo $(YELLOW)"Only clean test OBJS"$(NONE)
	(cd samples; make clean)
	@echo $(YELLOW)"Only clean test OBJS"$(NONE)

dist-clean: clean
	(cd lib; make dist-clean)
	@echo $(RED)"Clean library all things"$(NONE)
	(cd share; make dist-clean)
	@echo $(RED)"Clean share all things"$(NONE)
	(cd tests; make dist-clean)
	@echo $(RED)"Clean test all things"$(NONE)
	(cd samples; make dist-clean)
	@echo $(RED)"Clean test all things"$(NONE)
```

### 静态库文件
```Makefile
######################################
# Author: Jerling Li
# Email : linjieli001@qq.com
# Description: build log static library
######################################

include ../color/color.make

TARGET		:= liblog.a
#compile and lib parameter
CC			:= gcc
AR			:= ar
RANLIB		:= ranlib
LIBS		:=
LDFLAGS		:=
DEFINES 	:=
SRC_DIR		:= ../src
INCLUDE 	:= -I../include
CFLAGS		:= -g -Wall -O3 $(DEFINES) $(INCLUDE)

#source file
SOURCE		:= $(wildcard $(SRC_DIR)/*.c)
OBJS    	:= $(patsubst %.c,%.o,$(SOURCE))

.PHONY : all objs clean dist-clean rebuild

all : $(TARGET)

objs : $(OBJS)

rebuild: dist-clean all

clean :
	rm -fr $(OBJS)

dist-clean : clean
	rm -fr $(TARGET)

$(TARGET) : $(OBJS)
	$(AR) cru $(TARGET) $(OBJS)
	$(RANLIB) $(TARGET)
```

### 共享库文件
```Makefile
######################################
# Author: Jerling Li
# Email : linjieli001@qq.com
# Description: build log share library
######################################

include ../color/color.make

#target you can change test to what you want
TARGET  := liblog.so
#compile and lib parameter
CC	:= gcc
AR	:= ar
RANLIB		:= ranlib
LIBS		:=
LDFLAGS		:=
DEFINES 	:=
SRC_DIR		:= ../src
INCLUDE 	:= -I../inlude
CFLAGS		:= -g -Wall -O3 $(DEFINES) $(INCLUDE)
SHARE		:= -fPIC -shared -o
SHARE_PATH	:=/usr/lib

#i think you should do anything here

#source file
SOURCE  := $(wildcard $(SRC_DIR)/*.c)
OBJS    := $(patsubst %.c,%.o,$(SOURCE))

.PHONY : all objs clean dist-clean rebuild

all : $(TARGET)

objs : $(OBJS)

rebuild: dist-clean all

clean :
	rm -fr $(OBJS)

dist-clean : clean
	rm -fr $(TARGET)

$(TARGET) : $(OBJS)
	$(CC) $(CXXFLAGS) $(SHARE) $@ $(OBJS) $(LDFLAGS) $(LIBS)
	@echo $(RED)"Copy share library to" $(SHARE_PATH)$(NONE)
	sudo cp $(TARGET) $(SHARE_PATH)
```

### 可执行文件
包括 samples 和 tests 目录
```Makefile
######################################
# Author: Jerling Li
# Email : linjieli001@qq.com
# Description: build all execute obj
######################################

include ../color/color.make

#source file
SOURCE  := $(wildcard *.c)
OBJS    := $(patsubst %.c,%.o,$(SOURCE))
EXES    := $(patsubst %.o,%,$(OBJS))

#target you can change test to what you want

TARGET  := all
#compile and lib parameter
CC      := gcc
LDFLAGS :=
DEFINES :=
INCLUDE := -I../include
LIBS    := -L../lib -llog
CFLAGS  := -g -Wall -O3 $(DEFINES) $(INCLUDE)

# 定义生成可执行的隐式规则
%:%.o
	$(CC) -o $@ $^ $(CFLAGS) $(LIBS)

.PHONY : all objs clean dist-clean rebuild

all : $(EXES)

objs : $(OBJS)

rebuild: dist-clean all

clean :
	rm -fr $(OBJS)

dist-clean : clean
	rm -fr $(EXES)
```

以一个简单的日志打印为例进行验证：
{{< figure src="/images/Snipaste_2020-04-30_22-34-15.png" >}}

# VS code snippets
最后为了方便，将代码段写入 vscode 的 snippets 中
```json
{
	// Place your snippets for makefile here. Each snippet is defined under a snippet name and has a prefix, body and 
	// description. The prefix is what is used to trigger the snippet and the body will be expanded and inserted. Possible variables are:
	// $1, $2 for tab stops, $0 for the final cursor position, and ${1:label}, ${2:another} for placeholders. Placeholders with the 
	// same ids are connected.
	// Example:
	// "Print to console": {
	// 	"prefix": "log",
	// 	"body": [
	// 		"console.log('$1');",
	// 		"$2"
	// 	],
	// 	"description": "Log output to console"
	// }
	"project template" :{
		"prefix": "project_makefile",
		"body": [
			"######################################",
			"# Author: ${1:Jerling Li}",
			"# Email : ${2:linjieli001@qq.com}",
			"# Description: build project ",
			"######################################\n\n",
			"include color/color.make",
			"",
			"LIB_DIR\t\t:= lib",
			"SHARE_DIR\t:= share",
			"SAMPLE_DIR\t:= samples",
			"TEST_DIR\t:= tests",
			"",
			".PHONY : build build_sample build_test build_all run_sample run_test run_all clean dist-clean",
			"",
			"build :",
			"\t(cd $(LIB_DIR); make)",
			"\t(cd $(SHARE_DIR); make)",
			"",
			"build_sample:",
			"\t(cd $(SAMPLE_DIR); make)",
			"",
			"build_test:",
			"\t(cd $(TEST_DIR); make)",
			"",
			"run_test: build_all",
			"\t$(TEST_DIR)/test_$4",
			"",
			"build_all : build build_sample build_test",
			"",
			"clean:",
			"\t(cd $(LIB_DIR); make clean)",
			"\t(cd $(SHARE_DIR); make clean)",
			"\t(cd $(SAMPLE_DIR); make clean)",
			"\t(cd $(TEST_DIR); make clean)",
			"",
			"dist-clean: clean",
			"\t(cd $(LIB_DIR); make dist-clean)",
			"\t(cd $(SHARE_DIR); make dist-clean)",
			"\t(cd $(SAMPLE_DIR); make dist-clean)",
			"\t(cd $(TEST_DIR); make dist-clean)",
			""
		]
	},
	"execute template" :{
		"prefix": "execute_makefile",
		"body" :[
			"######################################",
			"# Author: ${1:Jerling Li}",
			"# Email : ${2:linjieli001@qq.com}",
			"# Description: build ${3:all} execute obj",
			"######################################\n\n",
			"include ../color/color.make",
			"",
			"#source file",
			"SOURCE  := $(wildcard *.c)",
			"OBJS    := $(patsubst %.c,%.o,$(SOURCE))",
			"EXES    := $(patsubst %.o,%,$(OBJS))",
			"",	
			"#target you can change test to what you want",
			"",
			"TARGET  := $3",
			"",
			"#compile and lib parameter",
			"CC      := gcc",
			"LDFLAGS :=",
			"DEFINES :=",
			"INCLUDE := -I${4:../}include",
			"LIBS    := -L$4lib -l$6",
			"CFLAGS  := -g -Wall -O3 $(DEFINES) $(INCLUDE)",
			"",	
			"%:%.o",
			"\t$(CC) -o $@ $^ $(CFLAGS) $(LIBS)",
			"",
			".PHONY : all objs clean dist-clean rebuild",
			"",
			"all : $(EXES)",
			"",	
			"objs : $(OBJS)",
			"",	
			"clean :",
			"\trm -fr $(OBJS)",
			"",
			"dist-clean : clean",
			"\trm -fr $(EXES)",
			"",
			"rebuild: veryclean everything",
			"",
		]
	},
	"static template" :{
		"prefix": "static_makefile",
		"body": [
			"######################################",
			"# Author: ${1:Jerling Li}",
			"# Email : ${2:linjieli001@qq.com}",
			"# Description: build $3 static library",
			"######################################\n\n",
			"include ../color/color.make",
			"",
			"TARGET\t\t:= lib$3.a",
			"#compile and lib parameter",
			"CC\t\t\t:= gcc",
			"AR\t\t\t:= ar",
			"RANLIB\t\t:= ranlib",
			"LIBS\t\t:=",
			"LDFLAGS\t\t:=",
			"DEFINES \t:=",
			"SRC_DIR\t\t:= ${4:../}src",
			"INCLUDE \t:= -I$4include",
			"CFLAGS\t\t:= -g -Wall -O3 $(DEFINES) $(INCLUDE)",
			"",
			"#source file",
			"SOURCE\t\t:= $(wildcard $(SRC_DIR)/*.c)",
			"OBJS    \t:= $(patsubst %.c,%.o,$(SOURCE))",
			"",
			".PHONY : all objs clean dist-clean rebuild\n",
			"all : $(TARGET)\n",
			"objs : $(OBJS)\n",
			"clean :",
			"\trm -fr $(OBJS)\n",
			"dist-clean : clean",
			"\trm -fr $(TARGET)",
			"",
			"$(TARGET) : $(OBJS)",
			"\t$(AR) cru $(TARGET) $(OBJS)",
			"\t$(RANLIB) $(TARGET)",
			"",
			"rebuild: dist-clean all\n",
			"",
		]
	},
	"share library": {
		"prefix": "share_library",
		"body": [
			"######################################",
			"# Author: ${1:Jerling Li}",
			"# Email : ${2:linjieli001@qq.com}",
			"# Description: build $3 share library",
			"######################################\n\n",
			"include ../color/color.make",
			"",
			"#target you can change test to what you want",
			"TARGET  := lib$3.so",
			
			"#compile and lib parameter",
			"CC\t\t\t:= gcc",
			"AR\t\t\t:= ar",
			"RANLIB\t\t:= ranlib",
			"LIBS\t\t:=",
			"LDFLAGS\t\t:=",
			"DEFINES \t:=",
			"SRC_DIR\t\t:= ${4:../}src",
			"INCLUDE \t:= -I$4include",
			"CFLAGS\t\t:= -g -Wall -O3 $(DEFINES) $(INCLUDE)",
			"SHARE\t\t:= -fPIC -shared -o",
			"SHARE_PATH\t:=/usr/lib",
			"",	
			"#i think you should do anything here",
			"",	
			"#source file",
			"SOURCE  := $(wildcard $(SRC_DIR)/*.c)",
			"OBJS    := $(patsubst %.c,%.o,$(SOURCE))",
			"",
			".PHONY : all objs clean dist-clean rebuild",
			"",
			"all : $(TARGET)",
			"",
			"objs : $(OBJS)",
			"",
			"clean :",
			"\trm -fr $(OBJS)",
			"",
			"dist-clean : clean",
			"\trm -fr $(TARGET)",
			"",
			"$(TARGET) : $(OBJS)",
			"\t$(CC) $(CXXFLAGS) $(SHARE) $@ $(OBJS) $(LDFLAGS) $(LIBS)",
			"\tsudo cp $(TARGET) $(SHARE_PATH)",
			"",
			"rebuild: dist-clean all",
			"",
		]
	},
	"define color": {
		"prefix": "color_makefile",
		"body": [
			"NONE\t\t:= \"\\033[m\"",
			"RED\t\t\t:= \"\\033[0;32;31m\"",
			"LIGHT_RED\t:= \"\\033[1;31m\"",
			"GREEN\t\t:= \"\\033[0;32;32m\"",
			"LIGHT_GREEN\t:= \"\\033[1;32m\"",
			"BLUE\t\t:= \"\\033[0;32;34m\"",
			"LIGHT_BLUE\t:= \"\\033[1;34m\"",
			"DARY_GRAY\t:= \"\\033[1;30m\"",
			"CYAN\t\t:= \"\\033[0;36m\"",
			"LIGHT_CYAN\t:= \"\\033[1;36m\"",
			"PURPLE\t\t:= \"\\033[0;35m\"",
			"LIGHT_PURPLE:= \"\\033[1;35m\"",
			"BROWN\t\t:= \"\\033[0;33m\"",
			"YELLOW\t\t:= \"\\033[1;33m\"",
			"LIGHT_GRAY\t:= \"\\033[0;37m\"",
			"WHITE\t\t:= \"\\033[1;37m\"",
		]
	},
	"test colcr": {
		"prefix": "test_color",
		"body": [
			"test_color:",
			"\t@echo $(NONE)\"NONE\"$(NONE)",
			"\t@echo $(RED)\"RED\"$(NONE)",
			"\t@echo $(LIGHT_RED)\"LIGHT_RED\"$(NONE)",
			"\t@echo $(GREEN)\"GREEN\"$(NONE)",
			"\t@echo $(LIGHT_GREEN)\"LIGHT_GREEN\"$(NONE)",
			"\t@echo $(BLUE)\"BLUE\"$(NONE)",
			"\t@echo $(LIGHT_BLUE)\"LIGHT_BLUE\"$(NONE)",
			"\t@echo $(DARY_GRAY)\"DARY_GRAY\"$(NONE)",
			"\t@echo $(CYAN)\"CYAN\"$(NONE)",
			"\t@echo $(LIGHT_CYAN)\"LIGHT_GRAY\"$(NONE)",
			"\t@echo $(PURPLE)\"PURPLE\"$(NONE)",
			"\t@echo $(LIGHT_PURPLE)\"LIGHT_PURPLE\"$(NONE)",
			"\t@echo $(BROWN)\"BROWN\"$(NONE)",
			"\t@echo $(YELLOW)\"YELLOW\"$(NONE)",
			"\t@echo $(LIGHT_GRAY)\"LIGHT_GRAY\"$(NONE)",
			"\t@echo $(WHITE)\"WHITE\"$(NONE)",
		]
	}
}
```
