>

## 介绍
block，即代码块、闭包，将同一逻辑的代码放在一个块中，使代码更紧凑，开发者可将代码像**对象**一样传递，令其在不同上下文下运行。这项技术并非 Objective-C 一门语言独有，其他编程语言也有类似的实现，叫法可能不同而已。10.4版及以后的 Mac OS X 系统与4.0版及以后的 iOS 系统中才能正常执行 block 代码。


## 基础
block 用一句话概括就是：带有自动变量值的匿名函数。

匿名函数：这个比较好理解，就是可以直接使用不带名称的函数，这个在其他语言中也有相应的实现。

带有自动变量：在调用 block 的时候，函数体使用的自动变量值是 block 赋值前自动变量的瞬间值。（这个好像没有讲清楚）

block 的基本写法是`returnType (^blockName)(parameterTypes) = ^returnType(parameters) {...};`

> 源码面前，了无秘密。

通过`clang`将含有 block 的源代码转换为可读的 C++ 代码。输入如下命令：

```
clang -rewrite-objc 源代码文件名（包含后缀）
```

先从最简单的代码开始：

```
#include <stdio.h>
int main() {
  void (^blk)() = ^{printf("Block\n");};
  blk();
  return 0;
}
```

转换后的代码有515行，所以就不完全贴出，只附上最核心的部分。具体的转换代码在[block.cpp](https://github.com/parallelWorld/Blog/blob/master/iOS/Source/block.cpp);

```
// 以下代码在 L62-67

struct __block_impl {
  void *isa;
  int Flags;
  int Reserved;
  void *FuncPtr;
};

// 以下代码在 L493-515
// block 定义
struct __main_block_impl_0 {
  struct __block_impl impl;
  struct __main_block_desc_0* Desc;
  __main_block_impl_0(void *fp, struct __main_block_desc_0 *desc, int flags=0) {
    impl.isa = &_NSConcreteStackBlock; // _NSConcreteStackBlock 相当于 class_t 结构体实例，而结构体拥有的是`isa`指针。也就是说 block 从本质上讲，是 OC 对于闭包的对象实现，是 OC 对象，原因可参见[这篇文章](https://github.com/parallelWorld/Blog/blob/master/iOS/Base/Memory-management.md)。
    impl.Flags = flags;
    impl.FuncPtr = fp;
    Desc = desc;
  }
};

// 匿名函数实际上转换成了 C 语言函数，命名方式是该 block 定义时所处的函数名和该 block 出现的顺序共同构成。如果是在全局定义 block ，则命名是定义时的变量名和该 block 出现的顺序共同构成。比如:`__blk_block_func_0`。
// 这里的`__cself`是一个结构体指针，相当于 C++ 中的`this`或 Objective-C 中的 `self`。
static void __main_block_func_0(struct __main_block_impl_0 *__cself) {
	printf("Block\n");
}

static struct __main_block_desc_0 {
  size_t reserved;
  size_t Block_size;
} __main_block_desc_0_DATA = { 0, sizeof(struct __main_block_impl_0)};

int main() {
  // 对应的源代码：`void (^blk)() = ^{printf("Block\n");};`
  // 简化成：`struct __main_block_impl_0 *blk = &__main_block_impl_0(__main_block_func_0, &__main_block_desc_0_DATA);`
  // 调用`__main_block_impl_0`构造函数生成结构体，并把地址赋给指针 blk
  void (*blk)() = ((void (*)())&__main_block_impl_0((void *)__main_block_func_0, &__main_block_desc_0_DATA));

  // 对应的源代码：`blk();`
  // 简化成：`(*blk->impl.FuncPtr)(blk);`
  // 取出 blk 中 impl 成员变量，调用 impl 的 函数指针 FuncPtr，参数是 blk
  ((void (*)(__block_impl *))((__block_impl *)blk)->FuncPtr)((__block_impl *)blk);
  return 0;
}
```





## 内存

### 5道 block 内存管理的测试题

具体问题不在这里贴出，请查看[Objective-C Blocks Quiz](http://blog.parse.com/learn/engineering/objective-c-blocks-quiz/)

如果这些题都能答对，而且明白原因，那么 block 在 ARC 和 MRC 下的 copy 和 release 你已经明白了所有。

直接上结论：ARC下，block 总是能在合适的时机，从 stack 上 copy 到 heap 上。MRC下，需要自己手动 copy 和 autorelease，即总是需要这样写`[[block copy] autorelease]`。ARC 下，编译器总是帮助你解决内存管理问题，除了循环引用；MRC则需要自己手动管理。

## 多线程

# 渔
---
### 如何简化 block 的书写
鉴于 block 语法非常难记，也非常难读，可以参考这个网址（[fuckingblocksyntax](http://fuckingblocksyntax.com)）来帮助记忆。看这名字也知道开发者对 block 语法有多么深恶痛绝。

虽说难写，但是我们可以用 C 语言中`typedef`关键字来给类型起个易读的别名。程序猿总是懒人。如下图:

```
// 使用 typedef 前的事例代码取自上述网站

// 使用 typedef 前
returnType (^blockName)(parameterTypes) = ^returnType(parameters) {...}; // 赋值
@property (nonatomic, copy, nullability) returnType (^blockName)(parameterTypes); // 属性定义
- (void)someMethodThatTakesABlock:(returnType (^nullability)(parameterTypes))blockName; // 方法声明
[someObject someMethodThatTakesABlock:^returnType (parameters) {...}]; // 方法调用，Xcode会自动展开

// 使用 typedef 后
typedef returnType (^TypeName)(parameterTypes); // 起别名
TypeName blockName = ^returnType(parameters) {...}; // 赋值
@property (nonatomic, copy, nullability) TypeName blockName; // 属性定义
- (void)someMethodThatTakesABlock:(TypeName)blockName; // 方法声明
[someObject someMethodThatTakesABlock:blockName]; // 方法调用，Xcode会自动展开
```

这样做有几个好处：
1. 使用 block 就像变量一样方便，变量类型在左，变量名在右，比较符合平时的编码习惯。
2. 重构 block 会很方便。修改签名之后，凡是使用了这个类型定义的地方，都会无法编译，逐一修改即可。若不用类型定义，直接写类型，那就得逐一搜索，这样很容易忘掉其中一两处，带来难查的 bug。
3. 如果 block 签名相同，但是用在不同的地方，可以通过类型定义给出不同的命名，帮助使用者明白该 block 的用途。当然了，命名不能相同。关于 iOS 中如何合理地命名，可以参考[这篇文章](https://github.com/parallelWorld/Blog/blob/master/iOS/Base/Code-style.md)。

---
### 如何合理地定义网络回调 block
网络请求中，一般使用 block 进行回调，至于为什么不用 delegate，请参考[这篇文章](https://github.com/parallelWorld/Blog/blob/master/iOS/Base/Notification.md)。回调有成功和失败的情况，设计 block 时，也有两种方式，如下：

```
// 成功和失败代码分开
typedef void (^HWNetworkFetcherCompletionHandler) (NSData *data);
typedef void (^HWNetworkFetcherErrorHandler) (NSError *error);
- (void)startWithCompletionHandler:(HWNetworkFetcherCompletionHandler)completion
                    failureHandler:(HWNetworkFetcherErrorHandler)failure;
// 成功和失败代码在一个 block 里
typedef void (^HWNetworkFetcherCompletionHandler) (NSData *data, NSError *error);
- (void)startWithCompletionHandler:(HWNetworkFetcherCompletionHandler)completion;
```

前者将成功和失败的处理分开，代码更易懂，而且还可以把成功或失败的代码省略掉，直接传 nil 即可，后者在实现时需要多一步对 error 的判断。但是网络请求有时候需要对数据和 error 进行一起处理，此时用前者就只能重新写个方法让两个 block 同时调用，还不如直接用后者。比如请求的数据是回来了，但是包含了业务上的错误，那么需要将此错误跟网络上的错误共同处理。采用后者可以共享同一份错误处理代码。MapKit 中的 `MKLocalSearch`类可供参考。

---
### 如何避免循环引用
循环引用（retain cycle）是两个或多个对象相互引用，造成这些对象都无法释放的后果。block 会引用代码段中所使用的对象，如果该对象也引用了该 block，就会造成循环引用。

解决办法是：**要么使对象不再引用 block，要么使 block 不再引用对象**。举例说明：

```
@implementation HWClass {
  HWNetworkFetcher *_networkFetcher;
  NSData *_fetcherData;
}
- (void)downloadData {
  [_networkFetcher startWithCompletionHandler:^(NSData *data) {
    _fetcherData = data;
  }];
}
```

假设 HWNetworkFetcher 中有个属性是持有 completionHandler 的，因为网络请求的回调需要调用该 block。这段代码的引用关系是 `self->_networkFetcher->_fetcherData(self)`。使用实例变量`_fetcherData`其实调用的是`self->_fetcherData`，所以此处形成了循环引用。

按照上面的解决办法，可以将`_networkFetcher`或者`completionHandler`置为`nil`。比如：

```
[_networkFetcher startWithCompletionHandler:^(NSData *data) {
  _fetcherData = data;
  _networkFetcher = nil;
}];

// 网络下载器中使用 block 回调
- (void)p_requestCompleted {
  if (_completionHandler) {
    _completionHandler(_downloadedData);
  }
  self.completionHandler = nil;
}
```

前者的问题是网络下载方法的调用者需要自己对内存进行管理，这显然不是很好的做法。所以在引用 block 的内部进行处理比较好，选择合适的时机将其置为`nil`。

综上，解除循环引用的关键在于分析清楚 block 和 block 中对象的引用关系，然后在合适的时机将其中一个置为`nil`。


### @strongify & @weakify
1. 如何使用

2. 多层如何调用？


## 如何使用 block 传递不同个数的参数

---
# 参考
- [《Effective Objective-C 2.0》](https://book.douban.com/subject/25829244/)
- [《iOS 与 OS X 多线程和内存管理》](https://book.douban.com/subject/24720270/)
- [Objective-C Blocks Quiz](http://blog.parse.com/learn/engineering/objective-c-blocks-quiz/)
- [Blocks Programming Topics](https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/Blocks/Articles/00_Introduction.html#//apple_ref/doc/uid/TP40007502-CH1-SW1)
