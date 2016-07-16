>

## 介绍
block，即代码块、闭包，将同一逻辑的代码放在一个块中，使代码更紧凑，开发者可将代码像**对象**一样传递，令其在不同上下文下运行。这项技术并非 Objective-C 一门语言独有，其他编程语言也有类似的实现，叫法可能不同而已。10.4版及以后的 Mac OS X 系统与4.0版及以后的 iOS 系统中才能正常执行 block 代码。

## 基础

## 内存

## 事例

### 如何简化 block 的书写
鉴于 block 语法非常难记，也非常难读，可以参考这个网址（[http://fuckingblocksyntax.com]()）来帮助记忆。看这名字也知道开发者对 block 语法有多么深恶痛绝。

虽说难写，但是我们可以用 C 语言中`typedef`关键字来给类型起个易读的别名。程序猿总是懒人。如下图:

```objc
// 使用 typedef 前的事例代码取自上述网站

// 使用 typedef 前
returnType (^blockName)(parameterTypes) = ^returnType(parameters) {...}; // 赋值
@property (nonatomic, copy, nullability) returnType (^blockName)(parameterTypes); // 属性定义
- (void)someMethodThatTakesABlock:(returnType (^nullability)(parameterTypes))blockName; // 方法声明
[someObject someMethodThatTakesABlock:^returnType (parameters) {...}]; // 方法调用

// 使用 typedef 后
typedef returnType (^TypeName)(parameterTypes); // 起别名
TypeName blockName = ^returnType(parameters) {...}; // 赋值
@property (nonatomic, copy, nullability) TypeName blockName; // 属性定义
- (void)someMethodThatTakesABlock:(TypeName)blockName; // 方法声明
[someObject someMethodThatTakesABlock:blockName]; // 方法调用
```

这样做有几个好处：
1. 使用 block 就像变量一样方便，变量类型在左，变量名在右，比较符合平时的编码习惯。
2. 重构 block 会很方便。修改签名之后，凡是使用了这个类型定义的地方，都会无法编译，逐一修改即可。若不用类型定义，直接写类型，那就得逐一搜索，这样很容易忘掉其中一两处，带来难查的 bug。
3. 如果 block 签名相同，但是如果用在不同的地方，可以通过类型定义给出不同的命名，帮助使用者明白该 block 的用途。当然了，命名不能相同。关于 iOS 中如何正确命名，可以参考另一篇文章



### 如何更好的自定义 block

### 如何避免循环引用

#### 原理
循环引用（retain cycle）是两个或多个对象相互引用，造成这些对象都无法释放的后果。block 会引用代码段中所使用的对象，如果该对象也引用了该 block，就会造成循环引用。

#### 解决办法
要么使对象不再引用 block，要么使 block 不再引用对象。




## @strongify & @weakify
1. 如何使用
2. 多层如何调用？

## 如何使用 block 传递不同个数的参数

# 参考
- [《Effective Objective-C 2.0》](https://book.douban.com/subject/25829244/)
- [《iOS 与 OS X 多线程和内存管理》](https://book.douban.com/subject/24720270/)
