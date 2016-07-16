>

## 介绍
block，即代码块、闭包，将同一逻辑的代码放在一个块中，使代码更紧凑，开发者可将代码像**对象**一样传递，令其在不同上下文下运行。这项技术并非 Objective-C 一门语言独有，其他编程语言也有类似的实现，叫法可能不同而已。10.4版及以后的 Mac OS X 系统与4.0版及以后的 iOS 系统中才能正常执行 block 代码。

## 基础

## 内存

## 事例

### 如何避免循环引用

#### 原理
循环引用（retain cycle）是两个或多个对象相互引用，造成这些对象都无法释放的后果。
block 会引用代码段中所使用的对象，如果该对象也引用了该 block，就会造成循环引用。

#### 解决办法
要么使对象不再引用 block，要么使 block 不再引用对象。




## @strongify & @weakify
1. 如何使用
2. 多层如何调用？

## 如何使用 block 传递不同个数的参数

# 参考
- [《Effective Objective-C 2.0》](https://book.douban.com/subject/25829244/)
- [《iOS 与 OS X 多线程和内存管理》](https://book.douban.com/subject/24720270/)
