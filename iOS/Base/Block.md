[TOC]

# 基础知识

## 概念

block，即代码块、闭包。从形式上看，是带有自动变量值的匿名函数，从本质上看，是 Objective-C 对象。

说 block 是带有自动变量值的匿名函数，是因为在 block 的函数体内，可以使用函数体之前声明的自动变量，也不用对该函数命名。

说 block 是对象，是因为 block 源代码转换的结构体中一个成员变量是`void *isa`。拥有`isa`指针，意味着该对象是一个 Objective-C 对象。block 对象类型有三种，`_NSConcreteStackBlock`、`_NSConcreteGlobalBlock`和`_NSConcreteMallocBlock`，表征的是该 block 的存储域。如字面意思，存储域分别对应的是栈、数据区域（.data区）和堆。也就是说，不同的存储域对应着 block 不同的生命周期。

## 使用 block 的好处
- 代码紧凑，降低代码碎片
- 链式编程
- 类之间传递值，可替代delegate、notification等。

## 截获自动变量

### case1 block 中使用但不赋值自动变量（基本数据类型）
如果变量是基本类型，block 会将使用的自动变量作为一个参数，通过**值传递**的方式传给转化后的『匿名函数』（注意 block 的匿名函数会转化成 C 函数，是有名字的）。该自动变量不会发生任何变化。

### case2 block 中使用并赋值静态变量、全局变量和静态全局变量（基本数据类型）
block 会将上述三种类型的变量的指针传递给匿名函数，达到使用并修改的目的。变量本身不会发生任何变化。

### case3 block 中赋值自动变量
如果直接赋值，编译器会报错。原因是 block 里的自动变量并不是截获的自动变量，是作为参数值传递的结果。假设允许直接赋值，也不会改变截获的自动变量的值，**跟实际代码的逻辑不符**，所以编译器直接报错。要想在 block 内改变自动变量，要么将该自动变量改成 case2 的任意一种类型，要么在变量声明处加上`__block`关键字。

加上`__block`关键字，自动变量本身会发生变化，被编译器扩展成一个结构体。block 函数传递的参数变成该结构体的指针，自动变量变成该结构体的一个成员变量。结构体结构如下：

```c
struct __Block_byref_intValue_0
{
    void *__isa;                            // 对象指针
    __Block_byref_intValue_0 *__forwarding; // 指向自己的指针
    int __flags;                            // 标志位变量
    int __size;                             // 结构体大小
    int intValue;                           // 自动变量
};
```

赋值自动变量变成对转化后的结构体的成员变量赋值。赋值代码是`(val->__forwarding->val) = 1;`。这里的赋值不符合常理，中间多了一步，通过结构体的`__forwarding`指针调用`val`。这样调用的原因会在下面的 block 内存管理中详述。

### case4 block 中使用对象

若该对象是`strong`类型，block 会持有 block 截获的对象，block 释放时，才会释放该对象。若该对象是`weak`类型，block 不会持有该对象。

因此如果`strong`类型的对象持有 block，同时 block 也使用了该对象，那么会形成循环引用，此时可使用一个`weak`对象指向原对象，block 函数体中使用该`weak`对象。由于是`weak`，block 外部对该对象进行内存管理，所以当 block 函数体执行时，该对象有可能已经被置为 nil。所以为了避免使用时对象为空，可以在函数体中对`weak`对象进行强引用，保证`weak`对象在使用时不会被置为 nil。

如果该对象是类的成员变量，那么除了持有该对象以外，`self`也会被持有。这里有个坑，就是有些人习惯用实例变量，就像这样：

```objc
typedef void(^Blk)(void);
@interface MyObject : NSObject
{
    Blk _blk;
    int a;
}
@end
@implementation MyObject

- (instancetype)init {
    self = [super init];
    _blk = ^{NSLog(@"%d", a);};
    return self;
}
```

此处虽然看起来并没有引用`self`，但是调用变量 a 时其实调用的是`self->a`，所以 block 还是引用了 self。此处的循环引用不是很明显，需要注意。避免方法是要么都写成属性，访问时用`self.XXX`，分析引用关系时看起来明显点；如果实在想用实例变量，可以用`self->XXX`访问。



# 内存管理

- `_NSConcreteGlobalBlock`
  当 block 函数体内不使用自动变量或者 block 定义在全局变量处时，block 类型是`_NSConcreteGlobalBlock`。

- `_NSConcreteStackBlock`
  当 block 定义在栈上，且使用自动变量，block 类型是`_NSConcreteStackBlock`。

- `_NSConcreteMallocBlock`
  当 block 复制到堆上时，block 类型是`_NSConcreteMallocBlock`。

## 内存管理规则

鉴于 block 是 Objective-C 对象，因此 block 的内存管理也遵循引用计数的规则，应该有对应的`copy`和`release`方法。通过源码分析，block 的结构体中确实存在`copy`和`dispose`函数指针。对于 block 本身而言，有如下规则：

| block 类型 | 原 block 存储域 | 复制效果 |
|:-:|:-:|:-:|
| _NSConcreteGlobalBlock | .data | 什么也不做 |
| _NSConcreteStackBlock | 栈 | 从栈复制到堆 |
| _NSConcreteMallocBlock | 堆 | 引用计数增加 |

对于`__block`变量来说，当 block 从栈复制到堆时，`__block`变量也从栈复制到堆，被 block 持有，其`isa`指针值变为`_NSConcreteMallocBlock`，`__forwarding`指针指向自己。注意，此时栈上的`__block`变量也会发生变化，其`__forwarding`指针值变成堆上的`__block`变量地址。当 block 从堆复制到堆，`__block`变量什么也不做。下面解释下为什么栈上的`__block`变量的`__forwarding`指针会指向堆上的`__block`变量。

假设有如下代码：

```objc
__block int val = 0;
void (^blk)(void) = [^{++val;} copy];
++val;
blk();
NSLog(@"%d", val);
```

最后输出的结果是2。首先观察代码逻辑，我们对变量做了`__block`修饰，就是希望无论在 block 中还是在后面的代码段中，都能对 val 这个变量进行修改，希望修改的是同一个变量。block 复制后，假设栈上的 block 的`__forwarding`指针并没有变。那么我们在修改 block 中的 val时，修改的是堆上的结构体中的 val 值。修改栈中的 val 时，修改的是栈的结构体的 val 值，跟我们的预期并不相同。所以`__forwarding`指针可以保证，`__block`变量无论配置在栈上还是堆上，都能正确访问`__block`变量。

## ARC 情况下

ARC 情况下，普通的 Objective-C 对象并不需要手动管理引用计数。对于 block 而言，编译器会通过适当地判断，将栈上的 block copy 到堆上。

编译器不会自动 copy 的情况：

- block 作为方法或函数的参数传递时，除了一些特殊情况，下面会有说明。

编译器自动 copy 的情况：

- block 作为函数返回值返回时
- 调用 block 的 copy 方法
- block 赋值给 `__strong`修饰的 id 类型的变量或者 block 类型成员变量
- 在方法名中含有 usingBlock 的 cocoa 框架方法或 GCD 的 API 中传递 block


## MRC 情况下

- MRC 情况下，都需要自己手动复制和释放 block。
- 避免循环引用的方式不是使用`__weak`关键字，而是`__block`。两者在 MRC 情况下效果等同。


## 5道 block 内存管理的测试题

具体问题不在这里贴出，请查看[Objective-C Blocks Quiz](http://blog.parse.com/learn/engineering/objective-c-blocks-quiz/)

如果这些题都能答对，而且明白原因，那么 block 在 ARC 和 MRC 下的 copy 和 release 你已经明白了所有。

直接上结论：ARC下，block 总是能在合适的时机，从 stack 上 copy 到 heap 上。MRC下，需要自己手动 copy 和 autorelease，即总是需要这样写`[[block copy] autorelease]`。ARC 下，编译器总是帮助你解决内存管理问题，除了循环引用；MRC则需要自己手动管理。

# 使用技巧

## 如何简化 block 的书写
鉴于 block 语法非常难记，也非常难读，可以参考这个网址[fuckingblocksyntax](http://fuckingblocksyntax.com)来帮助记忆。看这名字也知道开发者对 block 语法有多么深恶痛绝。

虽说难写，但是我们可以用 C 语言中`typedef`关键字来给类型起个易读的别名。程序猿总是懒人。如下代码:

```objc
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



## 如何合理地定义网络回调 block
网络请求中，一般使用 block 进行回调，至于为什么不用 delegate，请参考[这篇文章](https://github.com/parallelWorld/Blog/blob/master/iOS/Base/Notification.md)。回调有成功和失败的情况，设计 block 时，也有两种方式，如下：

```objc
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



## 如何避免循环引用

循环引用（retain cycle）是两个或多个对象相互引用，造成这些对象都无法释放的后果。block 会引用代码段中所使用的对象，如果该对象也引用了该 block，就会造成循环引用。

解决办法是：**要么使对象不再引用 block，要么使 block 不再引用对象**。举例说明：

```objc
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

```objc
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


## `@strongify` & `@weakify`

用过 RAC 框架，对这两个宏应该比较熟悉。这两个宏作用分别是对`self`强引用和弱引用。示例代码如下：

```objc
@weakify(self);
    [self doBlock:^{
        @strongify(self);
        self.XXX = YYY;
    }];
```

这两个宏非常方便地定义强弱引用的对象，也不用给指针命名，实现在[这里](https://github.com/jspahrsummers/libextobjc/blob/8942c6bca6a06717ee9edc0bf02b24b9d8ac4d77/extobjc/EXTScope.h)。

block 函数体内使用强引用的原因前面已经讲述，再说一遍，就是避免 block 函数体使用该对象时，该对象已经释放，需要使用强引用保持对象的存活。

上述说明，在有一个 block 的时候，两个宏是成对出现的。但我们在用 RAC 或者 使用 LeanCloud SDK 的时候，往往会出现多层调用 block 的情况，此时依然是成对使用这两个宏。原因参见[iOS Proper Use of @weakify(self) and @strongify(self)](http://stackoverflow.com/questions/28305356/ios-proper-use-of-weakifyself-and-strongifyself)。

## 不会引起循环引用的情况

- Foundation 框架中的集合遍历方法`- (void)enumerateObjectsUsingBlock:`
- GCD block
- [Masonry](https://github.com/SnapKit/Masonry)
- ...



## 如何使用 block 传递不同个数的参数
一个block像下面一样声明：

```objc
void(^block1)(void);
void(^block2)(int a);
void(^block3)(NSNumber *a, NSString *b);
```
如果block的参数列表为空的话，相当于可变参数（不是void）

```objc
void(^block)(); // 返回值为void，参数可变的block
block = block1; // 正常
block = block2; // 正常
block = block3; // 正常
block(@1, @"string");  // 对应上面的block3
block(@1); // block3的第一个参数为@1，第二个为nil
```
这样，block的主调和回调之间可以通过约定来决定block回传回来的参数是什么，有几个。如一个对网络层的调用：

```objc
- (void)requestDataWithApi:(NSInteger)api block:(void(^)())block {
    if (api == 0) {
        block(1, 2);
    }
    else if (api == 1) {
        block(@"1", @2, @[@"3", @"4", @"5"]);
    }
}
```

主调者知道自己请求的是哪个Api，那么根据约定，他就知道block里面应该接受哪几个参数：

```objc
[server requestDataWithApi:0 block:^(NSInteger a, NSInteger b){
    // ...
}];
[server requestDataWithApi:1 block:^(NSString *s, NSNumber *n, NSArray *a){
    // ...
}];
```

这个特性在Reactive Cocoa的-combineLatest:reduce:等类似方法中已经使用的相当好了。

```objc
+ (RACSignal *)combineLatest:(id<NSFastEnumeration>)signals reduce:(id (^)())reduceBlock;
```


# 参考链接
- [《Effective Objective-C 2.0》](https://book.douban.com/subject/25829244/)
- [《iOS 与 OS X 多线程和内存管理》](https://book.douban.com/subject/24720270/)
- [Objective-C Blocks Quiz](http://blog.parse.com/learn/engineering/objective-c-blocks-quiz/)
- [Blocks Programming Topics](https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/Blocks/Articles/00_Introduction.html#//apple_ref/doc/uid/TP40007502-CH1-SW1)
- [objc非主流代码技巧](http://blog.sunnyxx.com/2014/08/02/objc-weird-code/)
- [block没那么难（一）：block的实现](https://www.zybuluo.com/MicroCai/note/51116)
- [block没那么难（二）：block和变量的内存管理](https://www.zybuluo.com/MicroCai/note/57603)
- [block没那么难（三）：block和对象的内存管理](https://www.zybuluo.com/MicroCai/note/58470)
- [正确使用Block避免Cycle Retain和Crash](http://tanqisen.github.io/blog/2013/04/19/gcd-block-cycle-retain/)
- [iOS Proper Use of @weakify(self) and @strongify(self)](http://stackoverflow.com/questions/28305356/ios-proper-use-of-weakifyself-and-strongifyself)
