+++
title = "手把手实现一个 Linux shell"
author = ["Jerling"]
author_homepage = "https://github.com/Jerling"
description = "小项目实战"
date = 2019-01-19T20:17:47+08:00
lastmod = 2019-02-02T19:53:21+08:00
tags = ["linux", "shell", "c++"]
categories = ["项目实战"]
type = "post"
draft = false
+++

## Table of Contens {#table-of-contens}

-   [Linux shell 基本知识](#linux-shell-基本知识)
-   [shell 工作流程](#shell-工作流程)
-   [shell 实现](#shell-实现)
    -   [可执行程序该有的样子](#可执行程序该有的样子)
    -   [一探循环体究竟](#一探循环体究竟)
    -   [解剖循环体](#解剖循环体)
-   [总结](#总结)
-   [参考](#参考)


## Linux shell 基本知识 {#linux-shell-基本知识}

目前市场上主要有三大主流操作系统，除了 windows 系列几乎不需要在终端工作，其它两
大操作系统大部份应该是和终端打交道。当然这和不同系统的定位不一样有很大的关系， W
系主要面向娱乐办公，Linux 系主要是用服务器系统，所以对于程序员来说，或多或少得面
对它。Mac 虽然面向个人用户，但是结合了前两者的优势，娱乐办公和开
发都可以完美应对。在使用 \*nix(linux & Mac) 过程中，我们几乎每天都会对着终端一行
行的执行代码，解释我们的名令的程序就是我们所谓的 shell, 也是本文的所讲的对象。
shell 自从诞生以来，也出现各种版本，虽然实现不同，功能都是一样的。本文写个 shell
只是为了学习，没有其它目的。据本人所知，目前流行的 shell 有： [bash](https://www.baidu.com/link?url=VShkngjSIi0Xi38XgPurgAoSYbjVAKwt5klVe67ygRMpZutxezIY1GRJ%5FXGY94ph&wd=&eqid=b6840bc70000de76000000035c431bf0) , [zsh](https://www.baidu.com/link?url=1nsKjGHAl-3rmCFdOsnThI4GP85TzNEUEIOUHLV9tf%5F&wd=&eqid=9c2480920001045f000000035c431c63) , [fish](https://www.baidu.com/link?url=7xcMSUn2eX%5F0i5fDhdf2749ExX5Tt1fxzEtC4gSgoU5vviiVjTlfuLAcs18eEpQF&wd=&eqid=d3daba310000dbdd000000035c431c80)
, [xosh](https://xonsh.org/) 等，这几种 shell 本人都用过，简单讲奖各自的特点吧， bash 不用说了吧，几乎
所有发行版的默认 shell。 zsh 集装逼与高效于一身的 shell。强烈建议于 [oh-my-zsh](https://www.baidu.com/link?url=HN8GOhj0RoEbjYQNXbH%5FC93cjJUy%5FbwgBqsoJ39l2zW&wd=&eqid=cfc633a40000f12e000000035c431dc1) 一
起使用，省去配置的时间。 fish 小众软件，智能补全，拥有类似 apt 一样的插件管理工
具，但是由于 shell 语法和 bash 不兼容，建议个人使用，不要用于工作中。 xosh 是用
python 实现的，所以终端直接执行 python 语句就可以执行，同时可以执行系统命令。
pythoner 可以尝试一波，随时随地测试 python 语句。


## shell 工作流程 {#shell-工作流程}

介绍完 shell , 下面简单讲讲工作流程：

首先，我们运行一个 shell 程序，它将阻塞等待用户的输入。当用户在标准输入上输入一
行命令文本，这时程序成功读入一行文本，不再阻塞，可以继续执行。接下来将读入的文本
进行切分，将其切分为命令和参数两部分。然后就可以 fork 一个子进程调用 exec 系统调
用运行切分好的命令，父进程 wait 等待子进程的执行结果。最后将执行结果反馈给用户。
等待下一行执行命名的出现。直到用户退出或者信号中断退出。


## shell 实现 {#shell-实现}

上面的工作流程说的比较简单，实现也是比较简单的。下面我们就一步步的来实现这个
shell:

> 本文使用 C++ 实现


### 可执行程序该有的样子 {#可执行程序该有的样子}

我们知道，每个程序都有一个入口函数，在 C++ 中，为 main 函数：

```C++
int main() {
  lsh::lshell lsh;
  lsh.loop();
  return 0;
}
```

本人的代码风格类似 linux 风格――小写加下滑线。其中的意思也是字面意思，先创建一
个 shell 实例，然后循环执行命令。


### 一探循环体究竟 {#一探循环体究竟}

在探索之前，我们先借助点小工具用来表示命令执行返回状态：

```C++
/* 命令返回状态 */
enum status_enum {
  fork_failed = -1,
  success = 0,
  exit_s = 1,  // 和后面的 exit 有冲突，因此在后边加上 _s
};
```

进入正菜：

```C++
inline void lshell::loop() {
  do {
    std::cout << ">>> ";
    read_line__();
    split_line__();
    excute__();
    clear__();
  } while (status_ == status_enum::success);
}
```

em～～～，和我们之前提到的工作流程一致吧。有些细心的读者发现我给的代码中多了
clear\_\_(), 这个和本人的实现有关了，先留个疑问吧。继续探索。。。


### 解剖循环体 {#解剖循环体}

接下来就是将循环体解剖分开实现了。


#### 读文本 {#读文本}

首当其冲的是 read\_line\_\_:

```C++
inline void lshell::read_line__() { getline(std::cin, line_); }
```

em~~~~, 就一句话。虽然可以插入到其它代码块中，为了更好理解工作流程，我还是不省这
句代码了。虽然使用函数实现，不过不用担心性能，因为使用编译器关键字 `inline` 编译
的时候，编译器会用代码替换调用的部分，不会增加调用开销。


#### 拆分文本 {#拆分文本}

C++ 拆分字符串得自己实现，不过实现比较简单。如下：

```C++
void lshell::split_line__() {
  if (line_.empty()) return;
  std::string arg;
  int len = line_.length();
  int i = 0;
  while (i < len) {
    if (std::isblank(line_[i])) {
      args_.push_back(arg);
      arg.clear();
    } else {
      arg += line_[i];
    }
    ++i;
  }
  args_.push_back(arg);
}
```

我的代码写得比较 low , 当然还有其它方法实现，比如可以将 string 转换为 char\*, 然
后配合 C 函数 `strtok` 将字符串分割。仁者见仁。


#### 执行命令 {#执行命令}

shell 的内核所在，前面的都只是铺垫。

```C++
void lshell::excute__() {
  const int arg_len = args_.size();
  if (!arg_len) {
    status_setter(status_enum::success);
    return;
  }
  char **args = new char *[arg_len];
  for (int i = 0; i < arg_len; ++i) {
    args[i] = new char[args_[i].size() + 1];
    strncpy(args[i], args_[i].c_str(), args_[i].size());
  }
  auto is_builtin = builtins_.begin();
  if ((is_builtin = builtins_.find(args_[0])) != builtins_.end()) {
    status_setter(is_builtin->second(args));
  } else {
    status_setter(__launch(args));
  }
  for (auto i = 0; i < arg_len; ++i) delete args[i];
}
```

这里主要分为两部分，一个是内置命令，令一个是系统命令程序。

-    内置命令

    系统中没有实现如 cd, help, exit 等命令，所以需要我们手动实现这些命令，也即内置命
    令。在本文代码中，我使用哈希表存储内置命令处理函数。

    ```C++
    /* 内置命令：如 cd, help, exit... */
    status_enum __cd(char **);
    status_enum __help(char **);
    inline status_enum __exit(char **) { return status_enum::exit_s; };
    /* 内置命令对应的处理函数表，使用哈希表实现 */
    const std::unordered_map<std::string, status_enum (*)(char **)> _builtins{
        {"cd", &__cd}, {"help", &__help}, {"exit", &__exit}};
    ```

    后续添加内置命令也方便，不用修改 execute\_\_ 中的代码。以 cd 命令为例，看看内置命
    令的实现，其实是调用系统调用：

    ```C++
    status_enum __cd(char **args) {
      if (args[1] && int(args[1][0])) {
        if (chdir(args[1])) {
          std::cout << "The dir '" << args[1][0] << "' cannot be found! "
                    << std::endl;
        }
      } else {
        std::cout << "Expected argument to \" cd \" " << std::endl;
      }
      return status_enum::success;
    }
    ```

-    系统命令

    ```C++
    status_enum __launch(char **args) {
      pid_t pid = fork();
      if (pid > 0) {
        pid_t wpid;
        int status;
        do {
          wpid = waitpid(pid, &status, WUNTRACED);
        } while (!WIFEXITED(status) && !WIFSIGNALED(status));
        return status_enum::success;
      } else if (pid == 0) {
        if (execvp(args[0], args) == -1) {
          std::cout << "Connot found '" << args[0] << "' command. Please check!"
                    << std::endl;
          exit(-1);
        }
      } else {
        std::cout << "Fork failed " << std::endl;
        return status_enum::fork_failed;
      }
      return status_enum::success;
    }
    ```

    这个就是一般的创建子进程，然后通过 execvp 系统调用执行环境变量里的程序，当然父进
    程必须等待子进程执行完毕，将结果反馈给用户。


#### 最后是清理 {#最后是清理}

也就是清理上一次执行完的命令文本，本人的实现是将文本存储在私有变量里，避免了传参
过程产生的临时变量。虽然通过C++的一些高级语法避免这些开销，但是鄙人小菜一枚。所
以使用比较容易实现的方式，算是抛砖引玉吧，欢迎各位大佬指教。


## 总结 {#总结}

好了，到目前所有的核心代码几乎展示完毕了，这个是个小项目，主要是学习。 本人的完
整项目代码就不展示了，毕竟都是超级简单的东西。文末会给出项目的链接地址，作者是用
C写的，有兴趣可以参考他的实现。


## 参考 {#参考}

<https://brennan.io/2015/01/16/write-a-shell-in-c/>