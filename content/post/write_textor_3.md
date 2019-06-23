+++
title = "动手写编辑器 (三) ~ 文件查看器"
author = ["Jerling"]
author_homepage = "https://github.com/Jerling"
description = "Linux 下实现的文本编辑器"
date = 2019-02-02T13:27:35+08:00
lastmod = 2019-02-02T19:54:51+08:00
tags = ["textor", "terminal", "c++"]
categories = ["项目实战"]
type = "post"
draft = false
toc = true
+++

## Table of Contens {#table-of-contens}

-   [状态栏](#状态栏)
    -   [腾出空间](#腾出空间)
    -   [写入 buffer](#写入-buffer)
-   [消息框](#消息框)
    -   [腾出空间](#腾出空间)
    -   [滞留时间](#滞留时间)
    -   [写入消息](#写入消息)
    -   [写入 buffer](#写入-buffer)
-   [滚动](#滚动)
    -   [垂直滚动](#垂直滚动)
    -   [水平滚动](#水平滚动)
    -   [修改边界检查](#修改边界检查)
    -   [写入 buffer](#写入-buffer)
-   [总结](#总结)
-   [参考](#参考)


## 状态栏 {#状态栏}

熟悉 vim 的朋友都知道, vim 有一个状态栏，位于下边。状态栏的功能主要时显示一些基
本的信息，如文件名、光标位置等。


### 腾出空间 {#腾出空间}

在之前的操作中，我们把整个窗口都用来显示文件内容了。所以我们必须将 `rows_` 减去
一行用来显示状态信息。

```C++
inline int editor::get_window_size__() {
  ...
    rows_ = ws.ws_row - 1; /* 腾出状态栏 */
  ...
}
```


### 写入 buffer {#写入-buffer}

现在将我们要显示的信息写入 buffer 的最后一行，也就是状态栏。为了区分状态栏和文本
区的不同，因此将颜色反转。

```C++
void editor::status_bar__() {
  append_buf__("\x1b[7m"); /* 颜色反转 */
  std::string stats((filename_.empty() ? "[New File]" : filename_) +
                    " - total: " + std::to_string(numrows_) +
                    " lines current: (" + std::to_string(cx_) + ", " +
                    std::to_string(cy_) + ")");
  append_buf__(stats);
  for (int i = 0; i < cols_ - stats.size(); ++i) append_buf__(" ");
  append_buf__("\x1b[m"); /* 恢复颜色 */
  append_buf__("\r\n");
}
```


## 消息框 {#消息框}

消息栏也是必须的，在和编辑的交互过程中，有个消息栏是比较方便的，如命令运行结果反
馈等。信息框的处理和状态栏一样。先空出空间，然后将消息写入 buffer 。


### 腾出空间 {#腾出空间}

```C++
inline int editor::get_window_size__() {
  ...
    rows_ = ws.ws_row - 2; /* 腾出状态栏和消息框 */
  ...
}
```


### 滞留时间 {#滞留时间}

一般来说，消息最好不要一直显示，因为没什么用，还可能会影响视觉焦点。因此以时间戳为准，超过一段时
间（如5s）就不再显示消息即可。实现起来也比较简单，因为每次显示一个消息，所以每次有消息时
只需要记住消息出现的当前时间点，然后和当前的时间点比较即可。

```C++
struct textor{
  /* 消息 */
  std::string status_msg_;
  std::time_t msg_time_;
...
}
```


### 写入消息 {#写入消息}

将消息存入 `status_msg_` 变量中，同时更新最新消息的时间。

```C++
void editor::status_msg__(const char *fmt, ...) {
  va_list ap;
  va_start(ap, fmt);
  char msg[80];
  vsnprintf(msg, sizeof msg, fmt, ap);
  va_end(ap);
  status_msg_ = msg;
  msg_time_ = time(nullptr);
}
```


### 写入 buffer {#写入-buffer}

将消息写入 buffer 中便于显示。 `K` 命令是清除内容，因为每次刷新的时候先清空，然
后如果时间在规定时间内，则重新写入。

```C++
void editor::draw_msg__() {
  append_buf__("\x1b[K"); /* 清除消息框 */
  if (status_msg_.size() > cols_) status_msg_.resize(cols_);
  if (!status_msg_.empty() && time(nullptr) - msg_time_ < 5)  /* 5s 后不再显示 */
    append_buf__(status_msg_);
}
```


## 滚动 {#滚动}

在上一篇博客中，虽然实现了基本的查看文件内容的功能。但这明显是不够的，当我们打开的
文件比较大的时候，那么一个窗口是无法把所有的内容显示在上面。因此我们必须将文件存
入 buffer 中，然后根据相对文件中的坐标来显示窗口大小的内容。因此上一篇中的坐标
(cx\_, cy\_) 不再是相对窗口的坐标，而是相对文件的坐标。


### 垂直滚动 {#垂直滚动}

要实现垂直滚动，首先在全局配置中记录当前的窗口起始位置在文件中的偏移 `rowoff_` 。

```C++
struct textor{
  int rowoff;
  ...
}
```

在初始化时值为 0, 也就是文件的第一行。

在窗口最上面和最下面的时候，我们继续向上或向下移动光标的时，需要更新文件的相对偏移位置。

```C++
void editor::scroll__() {
  if (cx_ < rowoff_)
    rowoff_ = cx_;
  else if (cx_ >= rowoff_ + rows_)
    rowoff_ = cx_ - rows_ + 1;
...
}
```


### 水平滚动 {#水平滚动}

说了垂直滚动，那么水平滚动相对来说也会比较统一了，和垂直一样，定义一个水平的相对
起始位置 `coloff_` ，同样初始化为第一列。

```C++
struct textor{
  int coloff_;
}
```

当光标位于第一列并向左移动和最后一列向右移动时，光标就会移到屏幕之外。因此就需要
更新相关的列号。

```C++
void editor::scroll__() {
...
  if (cy_ < coloff_)
    coloff_ = cy_;
  else if (cy_ >= coloff_ + cols_)
    coloff_ = cy_ - cols_ + 1;
}
```

然后将这些更新放在 `flush__` 即可，每次刷新屏幕就会更新文件内容。


### 修改边界检查 {#修改边界检查}

在之前的实现中，我们都是以窗口为单位。所以判断是否越界也是以窗口的 `size` 为基准。
但是现在以文件作为基准，因此需要做点修改。

```C++
void editor::move_cursor__() {
  switch (key_) {
    case ARROW_UP:
      if (cx_ != 0) cx_--;
      break;
    case ARROW_DOWN:
      if (cx_ < numrows_ - 1) cx_++;
      if (!text_.empty() && cy_ > text_[cx_].size()) cy_ = text_[cx_].size();
      break;
    case ARROW_LEFT:
      if (cy_ > 0)
        cy_--;
      else if (cx_ != 0) {
        cx_--;
        cy_ = text_[cx_].size();
      }
      break;
    case ARROW_RIGHT:
      if (!text_.empty() && cy_ < text_[cx_].size())
        cy_++;
      else if (cx_ < numrows_ - 1) {
        cy_ = 0;
        cx_++;
      }
      break;
  }
}
```


### 写入 buffer {#写入-buffer}

我们目前已经知道如何实现滚动和更新滚动的相对起始位置，但是我们还没有将其应用到
buffer 中，所以必须修改 buffer 要显示的内容，才能实现滚动的效果。

下面我们就要修改 `draw_rows__` 函数，使其显示文件中的某个窗口大小的内容。

```C++
void editor::draw_rows__() {
  for (int i = 0; i < rows_; i++) {
    int filerow = i + rowoff_;      /* 修改显示为相对文件的行 */
    if (filerow >= numrows_) {
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
      int len = text_[filerow].size() - coloff_;
      if (len < 0) {
        len += coloff_;    /* 更新文件中的列 */
        /* 更新文件中的行 */
        append_buf__(text_[filerow].substr(len, 0));
        return;
      }
      if (len > cols_) len = cols_;
      append_buf__(text_[filerow].substr(coloff_, len));
    }
    append_buf__("\x1b[K");
    append_buf__("\r\n");
  }
}
```

这里实现也相对比较简单，将之前的相对窗口的坐标改为文件的坐标即可，后面的字符串也
将随着修改。


## 总结 {#总结}

好了，今天的内容就到这结束了，工作不多，只是基本的编辑器的功能。目前仅实现了文件查看
器的功能，和 vim 的正常模式一样，只能查阅，不能修改或写入。后续继续更新。

看看今天的效果吧 :)

{{< figure src="https://jerling.github.io/images/write%5Ftextor%5F3%5F20190202%5F145141.png" >}}


## 参考 {#参考}

<https://viewsourcecode.org/snaptoken/kilo/04.aTextViewer.html>
