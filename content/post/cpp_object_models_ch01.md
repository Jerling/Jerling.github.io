+++
title = "C++ 对象模型 — 关于对象"
author = ["Jerling"]
description = "C++ 对象内存模型"
date = 2019-05-07T23:36:30+08:00
lastmod = 2019-05-09T23:15:32+08:00
tags = ["c++", "对象模型", "编程语言"]
categories = ["学习笔记"]
type = "post"
draft = false
toc = true
author_homepage = "https://github.com/Jerling"
+++

## 关于对象 {#关于对象}


### 面向过程 {#面向过程}

在 C 语言中, 我们通常将 ****数据**** 和 ****处理数据的操作(函数)**** 分开声明, 也就是说语言本身没有支持 ****数据和函数**** 之间的关联性.
这种程序为典型的面向过程的程序.

```c
// data declare
typedef struct point3d
{
    float x;
    float y;
    float z;
} Point3d;

// print a pint, function declare
void Point3dPrint(const Point3d *pd)
{
    printf("(%g, %g, %g)", pd->x, pd->y, pd->z);
}

// or define a macro
#define Point3dPrint(pd)  printf("(%g, %g, %g)", pd->x, pd->y, pd->z);
```


### 抽象数据类型 {#抽象数据类型}

在 C++ 语言中, 可以用独立的 ****抽象数据类型**** 实现.

```cpp
class Point3d
{
public:
    Point3d() = default;
    Point3d(float x, float y, float z):_x(x), _y(y), _z(z) {}
    Point3d(Point3d &&) = default;
    Point3d(const Point3d &) = default;
    Point3d &operator=(Point3d &&) = default;
    Point3d &operator=(const Point3d &) = default;
    ~Point3d() = default;
    float x() const {return _x;}
    float y() const {return _y;}
    float z() const {return _z;}
    void Point3dPrint()const{
        printf("(%g, %g, %g)", _x, _y, _z);
    }

private:
    float _x;
    float _y;
    float _z;
};
```

从上面的例子可以看出, 相对于面向过程而言, ADT 将数据和对数据的操作封装在一起了. 这样比面向过程的全局数据要好.


### 封装成本 {#封装成本}

直观上看,感觉 C++ 的会占用更多的内存成本. 但事实上并没有增加成本. 在上例中, Point3d 对象的大小只和数据成员大小相关,
成员函数虽然在类内声明,但是不出现在对象中, 每一个飞内联成员函数只会产生一个函数体.

当然如果说 C++ 的类对象和 C 中的结构体大小总是相同, 也是不对的. 这里主要是用于实现运行时多态的 virtual 技术带来的
额外开销:

-   虚函数机制: 用来支持有效的执行期绑定
-   虚基类: 菱形继承体系中被多次继承的基类只保存一个共享实体


## C++ 对象模型 {#c-plus-plus-对象模型}

在 C++ 中, 有两种数据成员: 静态和非静态, 以及三种成员函数: 静态, 非静态和虚函数. 如下例子:

```cpp
class Point{
public:
    Point(float x);
    virtual ~Point();
    float x() const;
    static int PointCount();

protected:
    virtual ostream&
    print(ostream &os)const;

protected:
    float _x;
    static int _point_count
};
```

\`\`\`


### 简单对象模型 {#简单对象模型}

对象由一系列 slots 组成, 每一个 slot 指向一个成员, 成员按其声明次序被制定一个 slot.

{{< figure src="/images/simple_model.png" >}}

成员本身并不防止对象中, 而是将指向成员的指针防止 slots 中, 这样可以避免成员有不同的类型需要不同
的内存空间带来的问题.

\### 表格驱动模型

为了对所有的对象都有一致的表达方式,将成员相关的信息抽取出来, 放在数据成员表和成员方法表中. 类对象
本身则汗指向这两个表格的指针.

{{< figure src="/images/tables_model.png" >}}

成员函数表的观念为 C++ 对象模型支持虚函数提供有效的方案


### C++对象模型 {#c-plus-plus-对象模型}

1.  每个 class 产生出指向虚函数的指针, 放在表格之中. 称为虚函数表 vbtl
2.  每个类对象添加一个指针指向相关的虚函数表, 这个指针称为 vptr. vptr 的设定和重置由构造函数,析构函数和赋值函数自动完成; 每个 class 所关联的 type\_info 也由虚函数表指出, 通常为第一个 slot

{{< figure src="/images/c++_model.png" >}}

-   优点: 空间和时间存取的效率
-   缺点: 非静态数据成员的修改需重新编译


### 继承 {#继承}


#### 单一继承 {#单一继承}

```cpp
class Library_materials {};
class Book : public Library_materials {};
class Rental_book : public Book {};
```


#### 多继承 {#多继承}

```cpp
class iostream : public istream, public ostream{};
```


#### 虚继承 {#虚继承}

```cpp
class istream : virtual public ios {};
class ostream : virtual public ios {};
```

在虚继承中,不管基类在继承链中被派生多少次,都只会保存一个实体.


### 对象模型对程序的影响 {#对象模型对程序的影响}

1.  现有程序代码必须修改
2.  必须加入新的程序代码


### 关键字带来的差异 {#关键字带来的差异}

主要原因还是为了维护与 C 之间的兼容性。如 c++ 中本可以不用 struct, 但为了兼容 C
还是保留了 struct 关键字。


## 对象的差异 {#对象的差异}

C++ 支持三种编程范式。


### 程序模型 {#程序模型}

主要是为了兼容 C.


### 抽象数据类型模型 {#抽象数据类型模型}

抽象是和一组比表达一起提供，而其运算定义仍然不知道。


### 面向对象模型 {#面向对象模型}

一些彼此相关的类型通过一个抽象的基类被封装起来。

多态方法：

1.  隐式转换
2.  虚函数机制
3.  dynamic\_cast 和 typeid
4.  模板
