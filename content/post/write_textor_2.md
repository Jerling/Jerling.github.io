+++
title = "动手写编辑器（二） ~ 输入和输出"
author = ["Jerling"]
author_homepage = "https://github.com/Jerling"
description = "一步步实现终端编辑器"
date = 2019-01-30T11:06:21+08:00
lastmod = 2019-02-02T19:54:32+08:00
tags = ["textor", "c++", "terminal"]
categories = ["项目实战"]
type = "post"
draft = false
+++

## Table of Contens {#table-of-contens}

-   [窗口](#窗口)
    -   [Buffer](#buffer)
    -   [窗口 size](#窗口-size)
    -   [波浪线](#波浪线)
    -   [欢迎界面](#欢迎界面)
-   [输入](#输入)
    -   [Ctrl+q 退出](#ctrl-q-退出)
    -   [移动光标](#移动光标)
    -   [文本内容](#文本内容)
-   [输出](#输出)
    -   [显示 buffer](#显示-buffer)
    -   [刷新屏幕](#刷新屏幕)
-   [总结](#总结)
-   [参考](#参考)


## 窗口 {#窗口}

说到终端编辑器， vim 应该是用的最多的吧。在所有有关 Linux 基础的书本都会介绍
vi/vim 编辑器。因此在这里我将模仿 vim 编辑界面。话不多说，先看一下 vim 的启动界
面吧。

{{< figure src="https://jerling.github.io/images/20190131%5F122218.png" >}}

左边的波浪号表示没有内容的行，中间显示打开编辑器时的欢迎界面以及基本命令信息。现
在就模仿 vim 的界面，实现一个简单的编辑器。下面我们来将这个界面画出来。


### Buffer {#buffer}

Buffer 是编辑器的主体部分，所有的信息都只能通过 buffer 显示。 buffer 里面是一串
很长的字符串，其中有些是转义序列表示终端的一些命令，在后续需要用到的时候再讲解。
说起字符串处理，应该是最常见的操作了，用 C 写的话可能需要自己管理字符串，比如申
请内存，释放内存等，不需要多线程，因此不需要考虑线程安全。我们直接使用
C++ 的 `string` 数据类型即可。

```C++
struct editor{
...
  /* buffer */
  std::string abuf_;
...
}
```

数据结构选定之后，我们需要将各个不同的内容都追加到 abuf\_ 中。

```C++
inline void editor::append_buf__(const std::string &s) { abuf_ += s; }
```


### 窗口 size {#窗口-size}

在将内容追加到 buffer 之前，我们必须知道需要显示多少行，以及中间位置坐标是多少。这
些都需要通过编辑器的窗口大小得出，因此先获取窗口的 size 。获取的方式呢有两种方式。


#### 简单的方式： {#简单的方式}

1.  先定义一个 `winsize` 的临时变量 `ws`
2.  通过 `ioctl` 将窗口的 size 提取到 `ws`
3.  将 `size` 的属性存起来

```C++
inline int editor::get_window_size__() {
  struct winsize ws;
  if (ioctl(STDOUT_FILENO, TIOCGWINSZ, &ws) == -1 || ws.ws_col == 0) {
     /* 复杂方式，后续讲解 */
    if (write(STDOUT_FILENO, "\x1b[999C\x1b[999B", 12) != 12) return -1;
    return get_cursor_position__();
  } else {
    cols_ = ws.ws_col;
    rows_ = ws.ws_row;
    return 0;
  }
}
```

下面看看 `winsize` 和 `ioctl` 的作用。

-    winsize

    ```C
    // /usr/include/bits/ioctl-types.h
    struct winsize
      {
        unsigned short int ws_row;
        unsigned short int ws_col;
        unsigned short int ws_xpixel;
        unsigned short int ws_ypixel;
      };
    ```

    我们只需要前两个属性，也就是窗口的行数和列数。后面的暂时不需要。

-    ioctl

    ```C
    /* Perform the I/O control operation specified by REQUEST on FD.
       One argument may follow; its presence and type depend on REQUEST.
       Return value depends on REQUEST.  Usually -1 indicates error.  */
    extern int ioctl (int __fd, unsigned long int __request, ...) __THROW;
    ```

    从注释中可以看到，这个函数是 I/O 操作的相关函数，根据请求的操作码实现不同的操作，
    比如本项目需要获取窗口大小，因此需要请求获取 `winsize` 。操作码为 `TIOCGWINSZ`
    ，全称为 `Terminal I/O Control Get WINdow SiZe` 。操作结果呢就是将操作相关属性存
    入 `winsize` 实例中。最后存入到私有变量中保存起来。


#### 复杂方式获取窗口 size {#复杂方式获取窗口-size}

这种方式的主要思想是通过移动光标到右下角来求得窗口得大小。这种方式是 ioctl 函数
对终端窗口大小获取失败才使用得复杂方法。

```C++
inline int editor::get_window_size__(){
...
  if (write(STDOUT_FILENO, "\x1b[999C\x1b[999B", 12) != 12) return -1;
  return get_cursor_position__();
...
}

int editor::get_cursor_position__() {
  char buf[32];
  int i;

  if (write(STDOUT_FILENO, "\x1b[6n", 4) != 4) return -1;

  for (i = 0; i < sizeof buf - 1; ++i) {
    if (read(STDIN_FILENO, &buf[i], 1) != 1) break;
    if (buf[i] == 'R') break;
  }

  buf[i] = '\0';

  if (buf[0] != '\x1b' || buf[1] != '[') return -1;
  if (sscanf(&buf[2], "%d;%d", rows_, cols_) != 2) return -1;
  return 0;
}
```

代码中的 `"\x1b[999C[999B"` 是一段转义序列，格式为 `"\x1b"` + `"["` + `("参数
")` + command; 其中 `\x1b` 为 27 的 16 进制，且表示一个字符， `C` 为光标向前移动的命令， `B` 为
向下移动的命令， `999` 为参数。这些只有在 `STDOUT_FILENO` 中才能生效。因此写入
`STDOUT_FILENO` 即可。

在 `get_cursor_position__` 中，通过 `n` 命令获取设备状态报告，参数 `6` 表示请求
光标位置。

现在我们从标准输入 `STDIN_FILENO` 中读取回复信息并存到临时变量 buf 中。分析之前的命令，光标首先向前 999, 然
后向下 999 . 光标只能在当前的 buffer 中，也即会在右下角的位置，此时请求获取光标的位
置，返回的字符串以 `R` 结束，如 `"\x1b[24;80R"` 。此时通过 `sscanf` 将 buf[2] 地
址后的字符中的行号和列号存储到 `rows_` 和 `cols_` 中。


### 波浪线 {#波浪线}

现在我们将 `~` 画到 buffer 中。

```C++
  for (int i = 0; i < rows_; i++) {
    append_buf__("~");
    /* 最后一行不用回车换行 */
    if (i < rows_ - 1) append_buf__("\r\n");
  }
```


### 欢迎界面 {#欢迎界面}

现在我们将欢迎界面写入到窗口中间。

```C
  for (int i = 0; i < rows_; i++) {
    if (i == rows_ / 3) {
    std::string welcome("Textor editor -- version ");
    welcome += TEXTOR_VERSION;
    if (welcome.size() > cols_) welcome.resize(cols_);
    int padding = (cols_ - welcome.size()) / 2;
    if (padding) {
        append_buf__("~");               /* 第一列依然用 ~ */
        padding--;
    }
    while (padding--) append_buf__(" "); /* 欢迎前用空格填充 */
    append_buf__(welcome);
    }
  }
```

这段代码表示，在 1/3 行数的中间位置插入欢迎字符串。


## 输入 {#输入}

目前为止，我们已经将编辑窗口画出来了。但是呢，我们还需要完成一些输入的工作，比如
退出，移动光标等。


### Ctrl+q 退出 {#ctrl-q-退出}

Ctrl+ 组合键被映射到 `1~26` 之间。那么要捕获该组合键键值，只需要取键值的后五位（0~31)就可以获
取组合键键值。因此定义一个宏即可： `#define CTRL_KEY(k) ((k)&0x1f)`

```C++
inline void editor::read_key__() {
  int nread;
  while ((nread = read(STDIN_FILENO, &key_, 1)) != 1) {
    if (nread == -1 && errno != EAGAIN) SPDLOG_ERROR("read error");
  }
...
}

void editor::process_key__() {
  read_key__();
  switch (key_) {
    case CTRL_KEY('q'):
      flush__();
      exit(0);
      break;
...
  }
}
```

按下组合键, `read_key__` 从标准输入中读取一个键值，读取的键值存储在 `key_` 中，应该为 `1~26`
中的某个值。 如果 `key_ = CTRL_KEY('q')` ，则满足条件，清除屏幕后退出。


### 移动光标 {#移动光标}

使用 (cx\_, cy\_) 来表示光标的坐标。将键位绑定和 vim 的保持一致，其它的特殊键 home, delete 键就不做绑定了。
如果直接按下 `h, j, k, l` 时会直接移动光标，当按下方向键时，需要通过转义序列来确
定移动方向。

```C++
enum key {
  ARROW_UP = 'k',
  ARROW_DOWN = 'j',
  ARROW_LEFT = 'h',
  ARROW_RIGHT = 'l'
};

inline void editor::read_key__() {
  int nread;
  while ((nread = read(STDIN_FILENO, &key_, 1)) != 1) {
    if (nread == -1 && errno != EAGAIN) SPDLOG_ERROR("read error");
  }

  if (key_ == '\x1b') {
    char seq[3];

    if (read(STDIN_FILENO, &seq[0], 1) != 1) return;
    if (read(STDIN_FILENO, &seq[1], 1) != 1) return;

    if (seq[0] == '[') {
      switch (seq[1]) {
        case 'A':
          key_ = ARROW_UP;
          return;
        case 'B':
          key_ = ARROW_DOWN;
          return;
        case 'C':
          key_ = ARROW_RIGHT;
          return;
        case 'D':
          key_ = ARROW_LEFT;
          return;
      }
    }
  }
}

void editor::process_key__() {
  read_key__();
  switch (key_) {
...
    case ARROW_UP:
    case ARROW_DOWN:
    case ARROW_LEFT:
    case ARROW_RIGHT:
      move_cursor__();
      break;
  }
}

void editor::move_cursor__() {
  switch (key_) {
    case ARROW_UP:
      if (cx_ != 0) cx_--;
      break;
    case ARROW_DOWN:
      if (cy_ == text_[cx_].size())
        cy_ = 0;
      else if (cx_ != rows_ - 1 && cx_ < numrows_ - 1)
        cx_++;
      break;
    case ARROW_LEFT:
      if (cy_ != 0)
        cy_--;
      else if (cx_ != 0) {
        cx_--;
        cy_ = cols_;
      }
      break;
    case ARROW_RIGHT:
      if (cy_ != cols_ - 1 && cy_ < text_[cx_].size())
        cy_++;
      else if (cx_ < numrows_ - 1) {
        cx_++;
        cy_ = 0;
      }
      break;
  }
}
```

值得注意的是一些边界检查，如不要超出窗口的边界；如果文本区没有填满窗口，则在内容
内移动光标；当在最后一列时，下一行自动定位到首列。

目前我们只完成了坐标的计算，但是还没有将光标移动到指定位置，因此需要执行 `H` 命
令来移动光标。

```C
void editor::flush__{
...
  char buf[32];
  snprintf(buf, sizeof buf, "\x1b[%d;%dH", cx_ + 1, cy_ + 1);
  append_buf__(buf);
...
}
```


### 文本内容 {#文本内容}

文本内容需要在 buffer 中才能显示屏幕，因此我们同样使用 `string` 数据结构来表示一
行文本内容。用 `vector` 容器存储多行文本。

```C++
struct textor{
...
  /* 显示的内容和行数 */
  std::vector<std::string> text_;
...
}
```

文本和 buffer 的区别是，文本中不存在转义命令序列，只是要显示的内容，可以来自标准
输入，也可以是打开的文件。

这里以打开一个文件为例。

```C++
void editor::open__(char *fpath) {
  std::ifstream ifs;
  ifs.open(fpath, std::ifstream::in);
  if (ifs.fail()) SPDLOG_ERROR("open file failed");
  while (!ifs.eof()) {
    std::string str;
    getline(ifs, str);
    if (str.size()) text_.push_back(str);
  }
  numrows_ = text_.size();
  ifs.close();
}
```

使用 C++ 的文件流操作来读取文件，其中 `getline` 表示每次读取一行内容。为了显示内容，
我们还需要将其追加到 buffer 中。这个在 `flush__` 中实现。


## 输出 {#输出}


### 显示 buffer {#显示-buffer}

下面给出 buffer 的完整内容，前面零散的给出某些部分的实现。

```C++
void editor::draw_rows__() {
  for (int i = 0; i < rows_; i++) {
    if (i >= numrows_) {
      if (i == rows_ / 3 && !numrows_) {
        std::string welcome("Textor editor -- version ");
        welcome += TEXTOR_VERSION;
        if (welcome.size() > cols_) welcome.resize(cols_);
        int padding = (cols_ - welcome.size()) / 2;
        if (padding) {
          append_buf__("~");
          padding--;
        }
        while (padding--) append_buf__(" ");
        append_buf__(welcome);
      } else {
        append_buf__("~");
      }
    } else {
      if (text_[i].size() > cols_) {
        text_[i].resize(cols_);
      }
      append_buf__(text_[i].c_str());
    }
    append_buf__("\x1b[K");
    if (i < rows_ - 1) append_buf__("\r\n");
  }
}
```


### 刷新屏幕 {#刷新屏幕}

在刷新屏幕之前我们要将光标隐藏起来，不然在刷新期间，光标会继续闪烁。 `l` 命令表
示隐藏， `h` 命令恢复光标。

```C++
inline void editor::flush__() {
  append_buf__("\x1b[?25l");
  append_buf__("\x1b[H");
  draw_rows__();
  char buf[32];
  snprintf(buf, sizeof buf, "\x1b[%d;%dH", cx_ + 1, cy_ + 1);
  append_buf__(buf);
  append_buf__("\x1b[?25h");
  write(STDOUT_FILENO, abuf_.c_str(), abuf_.size());
  abuf_.clear();
}
```


## 总结 {#总结}

到目前为止，已经实现了可以移动光标，查看文件内容的操作，后续继续完善，先看看成果
吧。

欢迎界面：

{{< figure src="https://jerling.github.io/images/write%5Ftextor%5F2%5F20190131%5F110834.png" >}}

显示文件内容：

{{< figure src="https://jerling.github.io/images/write%5Ftextor%5F2%5F20190131%5F111300.png" >}}


## 参考 {#参考}

<https://viewsourcecode.org/snaptoken/kilo/03.rawInputAndOutput.html>