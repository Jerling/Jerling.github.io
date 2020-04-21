+++
title = "动手写编辑器（四） ~ 文本编辑器"
author = ["Jerling"]
author_homepage = "https://github.com/Jerling"
description = "一步步实现终端编辑器"
date = 2019-02-17T16:51:33+08:00
lastmod = 2019-02-18T19:15:36+08:00
tags = ["terminal", "c++", "textor"]
categories = ["项目实战"]
type = "post"
draft = false
+++

## Table of Contens {#table-of-contens}

-   [文本编辑器](#文本编辑器)
-   [插入字符](#插入字符)
    -   [重新映射方向键](#重新映射方向键)
    -   [按键处理](#按键处理)
    -   [插入字符](#插入字符)
-   [删除字符](#删除字符)
    -   [删除字符](#删除字符)
-   [添加行](#添加行)
    -   [换行](#换行)
-   [修改提示](#修改提示)
-   [保存文件](#保存文件)
-   [退出提示](#退出提示)
-   [另存为](#另存为)
-   [效果](#效果)
-   [总结](#总结)
-   [参考](#参考)


## 文本编辑器 {#文本编辑器}

在之前的三篇博客中，编辑器实现了文件的查看功能。这篇博客的工作主要是在前面的基础上修改
和添加一些内容，使得程序可以真正的实现编辑的功能。


## 插入字符 {#插入字符}

首先，要实现编辑功能，从小功能出发。我们使用编辑器的时候都是进行交互的操作，将键
盘的字符一个个的输入到编辑器中。因此需要实现从键盘读入字符然后正确的显示到编辑区
的对应位置。这意味着我们必须处理每一个可打印字符。在之前实现的功能中，我们使用
h, j, k, l 作为方向键来定位光标的位置，但是它们是可打印字符。所以在这里必须重新
映射方向键的返回值。


### 重新映射方向键 {#重新映射方向键}

键盘上的每一个键都有一个 ASCII 码，不能将方向键映射到该范围。我们知道 ASCII 的范
围是 0~127。因此只需要将方向键映射到 128, 127, 129, 130 即可。 之前定义保存
ASCII 码的 `key_` 为 `char` 类型，最大值为 127。为保险起见，修改为 `usigned int`
。修改代码如下：

```C++
enum key { ARROW_UP=128, ARROW_DOWN, ARROW_LEFT, ARROW_RIGHT };

struct textor{
...
  /* 按键 */
  unsigned char key_;
...
}
```


### 按键处理 {#按键处理}

现在已经移出了方向键的影响，那么默认我们按下任何可打印字符都应该显示在编辑器中。
因此需要处理每一个按键，在 `process_key__` 中添加以下按键处理：

```C++
void process_key__(){
  switch(key_){
    ...
    default:
      insert_char__();
      break;
  }
}
```


### 插入字符 {#插入字符}

现在就只需要实现上面的 `insert_char__` 函数即可，过程也比较简单，直接追加到
`text_` 变量的对应位置并移动光标到下一个位置即可。

```C++
void editor::insert_char__() {
  if (cx_ == numrows_) {
    text_.push_back("");
    numrows_++;
  }
  if (cy_ < 0 || cy_ > text_[cx_].size()) cy_ = text_[cx_].size();
  text_[cx_].insert(cy_, 1, key_);
  cy_++;
}
```


## 删除字符 {#删除字符}

除了添加内容，也需要实现修改或者删除文件内容。因此需要实现删除字符的功能，并将次
功能绑定到退格键上。

```c++
void process_key__(){
  switch(key_){
    ...
    case BACKSPACE:
    case CTRL('h'):
      delete_char__();
    ...
    }
}
```


### 删除字符 {#删除字符}

该功能是将光标的前面的字符删除。在这部分需要注意的是边界条件的检查。

```C++
void editor::delete_char__() {
  if (cy_ < 0 || cy_ > text_[cx_].size()) return;
  if (cy_ == 0) {                  // 行首
    if (cx_ == 0) return;
    while (text_.empty() && cx_) { // 删除空行
      cx_--;
      numrows_--;
    }
    cx_--;
    cy_ = text_[cx_].size();
    text_[cx_] += text_[cx_ + 1];   // 合并两行
    text_.erase(text_.begin() + cx_ + 1);
  } else                            // 不在行首
    text_[cx_].erase(--cy_, 1);
}
```


## 添加行 {#添加行}

有时候我们有将长的一行拆分成两行的需求，因此需要实现拆分行的功能。这个功能由
`Enter` 键触发。

```C++
void editor::process_key__() {
  read_key__();
  switch (key_) {
    case '\r':
      insert_row__();
      break;
   ...
    }
}
```


### 换行 {#换行}

将光标的后一部分保存起来，然后将其删除。即可得到两个字符串。将保存的字符串插入到
光标后一行。

```C++
void editor::insert_row__() {
  if (cy_ < 0 || cy_ >= text_[cx_].size()) return;
  std::string tail(text_[cx_].begin() + cy_, text_[cx_].end());
  text_[cx_].erase(text_[cx_].begin() + cy_ + 1, text_[cx_].end());
  text_[cx_].resize(cy_);
  cx_++;
  text_.insert(text_.begin() + cx_, tail);
  numrows_++;
  cy_ = 0;
}
```


## 修改提示 {#修改提示}

如果修改了文件，那么我们实现一个小小的功能来提示文件已经修改过。只需要一个
`bool` 值即可，如果要获取修改的字节数，可以使用 `int` 类型。

```C++
struct textor{
  /* 是否修改 */
  bool dirty_;
}
```

然后我们需要在修改文件的每个的最后添加修改检查。

```C++
  if (!dirty_) dirty_ = true;
```


## 保存文件 {#保存文件}

编辑器的编辑功能到这里已经完成了，但是目前的修改只是修改了内存缓冲区。要实现长久
的修改，需要将其写入到硬盘中。

```C++
void editor::save__() {
  if (filename_.empty()) return;
  std::ofstream ofs;
  ofs.open(filename_.c_str(), std::ifstream::out);
  if (ofs.fail()) SPDLOG_ERROR("open file failed");
  for (auto row : text_) ofs << row + "\n";
  ofs.close();
  status_msg__("Save to %s successful!", filename_.c_str());
  dirty_ = false;
  quit_times_ = 2;
}
```


## 退出提示 {#退出提示}

如果修改了文件，我们却还没有保存，此时如果直接退出，那么修改的内容将不会写入磁盘。
因此在文件修改了的情况下，退出时给出善意的提示是必要的。定义一个退出次数，初始化
为两次，即连续两次退出即可不保存保存文件。

```C++
struct textor{
  int quit_times_;
}

void process_key__(){
...
    case CTRL_KEY('q'):
      if (dirty_ && quit_times_) {
        status_msg__(
            "WARNING!!! Files had modifed. Please press Ctrl+S to save or "
            "Ctrl+Q to quit without save!");
        quit_times_--;
        return;
      }
      write(STDOUT_FILENO, "\x1b[2J", 4);
      write(STDOUT_FILENO, "\x1b[H", 3);
      exit(0);
      break;
...
}
```


## 另存为 {#另存为}

当我们打开空白文件时，保存文件必须交互的给出文件的名字。也可以实现另存为的功能。
因此先定义一个在消息框中获得文件名的函数。并将交互过程中的文件名存储在
`filename_` 中。

```C++
void editor::prompt__(const std::string &prompt) {
  while (1) {
    status_msg__(prompt.c_str(), filename_.c_str());
    flush__();

    read_key__();
    if (key_ == BACKSPACE && !filename_.empty()) {
      filename_.pop_back();
    } else if (key_ == '\x1b') {  // Esc 退出
      filename_.clear();
      return;
    } else if (key_ == '\r') {
      if (!filename_.empty()) return; // 文件为空持续等待，除非使用 Esc 退出
    } else if (!iscntrl(key_) && key_ < 128) { // 可打印字符
      filename_ += key_;
    }
  }
}
```

同在保存的时候，如果 `filename_` 为空，则需要给出文件名进行保存。

```C++
void editor::save__() {
  if (filename_.empty()) prompt__("Save as : %s (Esc to cancel)");
  if (filename_.empty()) {
    status_msg__("Save aborted");
    return;
  }
...
}
```


## 效果 {#效果}

修改并保存现有文件：

{{< figure src="https://jerling.github.io/images/深度录屏%5F选择区域%5F20190217194328.gif" >}}

保存新建文件：

{{< figure src="https://jerling.github.io/images/深度录屏%5F选择区域%5F20190217194921.gif" >}}


## 总结 {#总结}

目前已经实现了简单查看和编辑功能，麻雀虽小，五脏俱全。由于马上要找实习，该项目在
过年期间利用空闲时间完成，可能还有很多 bug 以及没有考虑周全的地方。也算告一段落了吧。诸如高亮、丰富的快捷键这些功能以后有
机会在实现吧。代码不多，先上传到 `github` 吧。

<https://github.com/Jerling/Textor>


## 参考 {#参考}

<https://viewsourcecode.org/snaptoken/kilo/05.aTextEditor.html>