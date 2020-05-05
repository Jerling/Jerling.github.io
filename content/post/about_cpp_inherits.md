+++
title = "关于对象那些事儿 ~~ 继承"
author = "Jerling" 
author_homepage = "https://github.com/Jerling"
description = "对 C++ 继承的一些理解"
date = 2019-02-22T20:07:56+08:00
lastmod = 2019-02-24T12:02:55+08:00
tags = ["c++", "面向对象", "继承"]
categories = ["温故知新"]
type = "post"
draft = false
+++

## Table of Contens {#table-of-contens}

-   [关于继承](#关于继承)
    -   [何为对象](#何为对象)
    -   [何为继承](#何为继承)
-   [public 继承](#public-继承)
    -   [public 继承权限](#public-继承权限)
    -   [实例](#实例)
-   [protected 继承](#protected-继承)
    -   [protected 继承权限](#protected-继承权限)
    -   [实例](#实例)
-   [private 继承](#private-继承)
    -   [protected 继承权限](#protected-继承权限)
    -   [实例](#实例)
-   [虚继承](#虚继承)
    -   [实例](#实例)
    -   [虚继承与虚函数](#虚继承与虚函数)
-   [总结](#总结)


## 关于继承 {#关于继承}

随着软件功能的日益完善，随之而来的就是软件的也越来越大，变得难以维护。传统的面向
过程的编程范式难以满足日益丰富的用户需求，因此需要一种新的编程范式来应对这种
复杂的需求。面向对象在这个时候出现，很好的解决了这些难题。它是一种软件开发方法，
利用对世界关系的分析方法来分析复杂软件体系关系，实践证明这是可行的。


### 何为对象 {#何为对象}

世界的所有事物都可以抽象为一个对象，一个对象拥有基本的属性以及作用在这些属性上
的功能。举个简单的例子：人为一个对象，有基本属性（身高、体重等），以及功能
（吃饭、说话等）。在面向对象的软件开发方法中，有三大特性：继承、封装及多态。今天
的主角是继承。


### 何为继承 {#何为继承}

每个对象的可以抽象为不同的级别，我们将有某些共同属性或功能抽象成一个基类对象，然
后让派生类来继续延用（继承）公用的属性或功能。同样举个简单例子：父亲是一个基类或
父类，小孩就是派生类或子类，小孩会继承父亲遗传的某些性状（如血型）。

继承是实现代码重用的重要手段，直接使用基类对象的属性和方法，呈现面向对象程序设计
的层次结构，体现由简单到复杂、一般到特殊的认知过程。继承的方式有三种： `public` 继承、
 `protected` 继承、 `private` 继承。编译器通过三种方式对应的限定符进行区分。


## public 继承 {#public-继承}

公有继承是比较常见的继承方式，通过 `public` 关键字来表明。


### public 继承权限 {#public-继承权限}

-   父类的 `public` 成员继承为子类的 `public` 成员，子类可以访问。
-   父类的 `protected` 成员继承为子类的 `protected` 成员，子类成员函数可以访问。
-   父类的 `private` 成员仍为 **父类** 的 `private` 成员，子类不可以访问。


### 实例 {#实例}

```C++
#include <iostream>

class Base {
 public:
  int int_pub = 0;

 protected:
  int int_pro = 0;

 private:
  int int_pri = 0;
};

class Derive : public Base {
 public:
  void print() {
    std::cout << "print:" << int_pub << std::endl;
    std::cout << "print:" << int_pro << std::endl;
    // std::cout << "print:" << int_pri << std::endl;
  }
};

int main() {
  Derive d;
  std::cout << "main:" << d.int_pub << std::endl;
  // std::cout << "main:" << d.int_pro << std::endl;
  d.print();
  return 0;
}
```

在子类的成员函数种访问父类的 `private` 会出错，错误信息也会提示这是 `Base` 的私
有成员。子类直接访问继承的 `protected` 成员也会报错。


## protected 继承 {#protected-继承}

保护继承通过 `protected` 关键字限定表明。


### protected 继承权限 {#protected-继承权限}

-   父类的 `public` 成员继承为子类的 `protected` 成员，可通过成员函数访问。
-   父类的 `protected` 成员继承为子类的 `protected` 成员，可通过成员函数访问。
-   父类的 `private` 成员仍为 **父类** 的 `private` 成员，子类不可以访问。


### 实例 {#实例}

```C++
#include <iostream>

class Base {
 public:
  int int_pub = 0;

 protected:
  int int_pro = 0;

 private:
  int int_pri = 0;
};

class Derive : protected Base {
 public:
  void print() {
    std::cout << "print:" << int_pub << std::endl;
    std::cout << "print:" << int_pro << std::endl;
    // std::cout << "print:" << int_pri << std::endl;
  }
};

int main() {
  Derive d;
  // std::cout << "main:" << d.int_pub << std::endl;
  // std::cout << "main:" << d.int_pro << std::endl;
  d.print();
  return 0;
}
```

通过对象直接访问继承自父类的 `public` 成员会出错。


## private 继承 {#private-继承}

私有继承通过 `private` 关键字限定表明。


### protected 继承权限 {#protected-继承权限}

-   父类的 `public` 成员继承为子类的 `private` 成员，可通过成员函数访问。
-   父类的 `protected` 成员继承为子类的 `private` 成员，可通过成员函数访问。
-   父类的 `private` 成员仍为 **父类** 的 `private` 成员，子类不可以访问。


### 实例 {#实例}

```C++
#include <iostream>

class Base {
 public:
  int int_pub = 0;

 protected:
  int int_pro = 0;

 private:
  int int_pri = 0;
};

class Derive : protected Base {
 public:
  void print() {
    std::cout << "print:" << int_pub << std::endl;
    std::cout << "print:" << int_pro << std::endl;
    // std::cout << "print:" << int_pri << std::endl;
  }
};

int main() {
  Derive d;
  // std::cout << "main:" << d.int_pub << std::endl;
  // std::cout << "main:" << d.int_pro << std::endl;
  d.print();
  return 0;
}
```

访问和 `protected` 是一样。这里说明 `private` 和 `protected` 的异同：继承权限不
一样，前者不可继承后者可以；访问权限是一样的，都必须通过成员函数才能访问。


## 虚继承 {#虚继承}

虚继承的出现是用来解决多继承的对象多次被继承带来的问题。普通继承在不同途径继承来
自同一基类的子孙类中存在多份拷贝。这将存在两个问题：其一，浪费存储空间；第二，存
在二义性问题，通常可以将派生类对象的地址赋值给基类对象，实现的具体方式是，将基类
指针指向继承类（继承类有基类的拷贝）中的基类对象的地址，但是多重继承可能存在一个
基类的多份拷贝，这就出现了二义性。

虚继承可以解决多种继承前面提到的两个问题：

虚继承底层实现原理与编译器相关，一般通过虚基类指针和虚基类表实现，每个虚继承的子
类都有一个虚基类指针（占用一个指针的存储空间，4字节）和虚基类表（不占用类对象的
存储空间）（需要强调的是，虚基类依旧会在子类里面存在拷贝，只是仅仅最多存在一份而
已，并不是不在子类里面了）；当虚继承的子类被当做父类继承时，虚基类指针也会被继承。

实际上，vbptr指的是虚基类表指针（virtual base table pointer），该指针指
向了一个虚基类表（virtual table），虚表中记录了虚基类与本类的偏移地址；通过
偏移地址，这样就找到了虚基类成员，而虚继承也不用像普通多继承那样维持着公共基类
（虚基类）的两份同样的拷贝，节省了存储空间。

在这里我们可以对比虚函数的实现原理：他们有相似之处，都利用了虚指针（均占用类的
存储空间）和虚表（均不占用类的存储空间）。

虚基类依旧存在继承类中，只占用存储空间；虚函数不占用存储空间。

虚基类表存储的是虚基类相对直接继承类的偏移；而虚函数表存储的是虚函数地址。

{{< figure src="/images/virtual_inherit.png" >}}


### 实例 {#实例}

-   普通继承

```C++
#include<iostream>
using namespace std;

class A  //大小为4
{
public:
	int a;
};
class B :public A  //大小为8，变量a,b共8字节
{
public:
	int b;
};
class C :public A //与B一样8
{
public:
	int c;
};
class D :public B, public C //大小为20,变量 2xa + b + c + d = 20
{
public:
	int d;
};

int main()
{
	A a;
	B b;
	C c;
	D d;
	cout << "A " << sizeof(a) << endl;
	cout << "B " << sizeof(b) << endl;
	cout << "C " << sizeof(c) << endl;
	cout << "D " << sizeof(d) << endl;
	return 0;
}

```

-   虚继承

```C++
#include<iostream>
using namespace std;

class A  //大小为4
{
public:
	int a;
};
class B :virtual public A  //大小为16，变量a,b共8字节，虚基类表指针8
{
public:
	int b;
};
class C :virtual public A //与B一样16
{
public:
	int c;
};
class D :public B, public C
         //大小为40,变量a,b,c,d共16，B的虚基类指针8，C的虚基类指针8,D类的虚指针8
         //也可以这样算： B, C 一共 32, d占4字节，D虚指针8,一共44, 减去B,C重复的A，得 40
{
public:
	int d;
};

int main()
{
	A a;
	B b;
	C c;
	D d;
	cout << "A " << sizeof(a) << endl;
	cout << "B " << sizeof(b) << endl;
	cout << "C " << sizeof(c) << endl;
	cout << "D " << sizeof(d) << endl;
	return 0;
}
```

从上面的两个例子中可以看出，在普通继承中的通过不同途径继承自同一继承祖先类的子孙
类中包含多份拷贝，在大型的软件系统中，这很浪费资源。


### 虚继承与虚函数 {#虚继承与虚函数}

这两者是完全不同的概念，虚继承是解决多重继承带来的两个问题；而虚函数是为了实现多
态。


## 总结 {#总结}

这篇是对面向对象三大特性之一进行简单的介绍，重点还是要理解继承权限的关系以及虚继
承和普通继承的内存布局，不要把虚继承和虚函数的弄混淆。
